codeunit 50013 "TWE Rental Batch Post Mgt."
{
    EventSubscriberInstance = Manual;
    Permissions = TableData "Batch Processing Parameter" = rimd,
                  TableData "Batch Processing Session Map" = rimd;
    TableNo = "TWE Rental Header";

    trigger OnRun()
    var
        RentalHeader: Record "TWE Rental Header";
        RentalBatchPostMgt: Codeunit "TWE Rental Batch Post Mgt.";
    begin
        RentalHeader.Copy(Rec);

        BindSubscription(RentalBatchPostMgt);
        RentalBatchPostMgt.SetPostingCodeunitId(PostingCodeunitId);
        RentalBatchPostMgt.SetBatchProcessor(BatchProcessingMgt);
        RentalBatchPostMgt.Code(RentalHeader);

        Rec := RentalHeader;
    end;

    var
        BatchProcessingMgt: Codeunit "Batch Processing Mgt.";
        PostingCodeunitId: Integer;
        PostingDateIsNotSetErr: Label 'Enter the posting date.';
        BatchPostingMsg: Label 'Bacth posting of sales documents.';
        ApprovalPendingErr: Label 'Cannot post sales document no. %1 of type %2 because it is pending approval.', Comment = '%1 = Document No.; %2 = Document Type';
        ApprovalWorkflowErr: Label 'Cannot post sales document no. %1 of type %2 due to the approval workflow.', Comment = '%1 = Document No.; %2 = Document Type';
        ProcessBarMsg: Label 'Processing: @1@@@@@@@', Comment = '1 - overall progress';

    procedure RunBatch(var RentalHeader: Record "TWE Rental Header"; ReplacePostingDate: Boolean; PostingDate: Date; ReplaceDocumentDate: Boolean; CalcInvoiceDiscount: Boolean; Ship: Boolean; Invoice: Boolean)
    var
        TempErrorMessage: Record "Error Message" temporary;
        RentalBatchPostMgt: Codeunit "TWE Rental Batch Post Mgt.";
        ErrorMessages: Page "Error Messages";
    begin
        if ReplacePostingDate and (PostingDate = 0D) then
            Error(PostingDateIsNotSetErr);

        BatchProcessingMgt.SetParameter("Batch Posting Parameter Type"::Invoice, Invoice);
        BatchProcessingMgt.SetParameter("Batch Posting Parameter Type"::Ship, Ship);
        BatchProcessingMgt.SetParameter("Batch Posting Parameter Type"::"Calculate Invoice Discount", CalcInvoiceDiscount);
        BatchProcessingMgt.SetParameter("Batch Posting Parameter Type"::"Posting Date", PostingDate);
        BatchProcessingMgt.SetParameter("Batch Posting Parameter Type"::"Replace Posting Date", ReplacePostingDate);
        BatchProcessingMgt.SetParameter("Batch Posting Parameter Type"::"Replace Document Date", ReplaceDocumentDate);
        OnRunBatchOnAfterAddParameters(BatchProcessingMgt);

        RentalBatchPostMgt.SetBatchProcessor(BatchProcessingMgt);
        Commit();
        if RentalBatchPostMgt.Run(RentalHeader) then;
        BatchProcessingMgt.ResetBatchID();
        if GuiAllowed then begin
            BatchProcessingMgt.GetErrorMessages(TempErrorMessage);

            if TempErrorMessage.FindFirst() then begin
                ErrorMessages.SetRecords(TempErrorMessage);
                ErrorMessages.Run();
            end;
        end;
    end;

    procedure RunWithUI(var RentalHeader: Record "TWE Rental Header"; TotalCount: Integer; Question: Text)
    var
        ErrorContextElement: Codeunit "Error Context Element";
        ErrorMessageMgt: Codeunit "Error Message Management";
        ErrorMessageHandler: Codeunit "Error Message Handler";
        RentalBatchPostMgt: Codeunit "TWE Rental Batch Post Mgt.";
    begin
        if not Confirm(StrSubstNo(Question, RentalHeader.Count, TotalCount), true) then
            exit;

        ErrorMessageMgt.Activate(ErrorMessageHandler);
        ErrorMessageMgt.PushContext(ErrorContextElement, DATABASE::"TWE Rental Header", 0, BatchPostingMsg);
        RentalBatchPostMgt.SetBatchProcessor(BatchProcessingMgt);
        Commit();
        if RentalBatchPostMgt.Run(RentalHeader) then;
        BatchProcessingMgt.ResetBatchID();

        if ErrorMessageMgt.GetLastErrorID() > 0 then
            ErrorMessageHandler.ShowErrors();
    end;

    procedure GetBatchProcessor(var ResultBatchProcessingMgt: Codeunit "Batch Processing Mgt.")
    begin
        ResultBatchProcessingMgt := BatchProcessingMgt;
    end;

    procedure SetBatchProcessor(NewBatchProcessingMgt: Codeunit "Batch Processing Mgt.")
    begin
        BatchProcessingMgt := NewBatchProcessingMgt;
    end;

    procedure "Code"(var RentalHeader: Record "TWE Rental Header")
    var
        RecRef: RecordRef;
    begin
        if PostingCodeunitId = 0 then
            PostingCodeunitId := CODEUNIT::"TWE Rental-Post";

        RecRef.GetTable(RentalHeader);

        BatchProcessingMgt.SetProcessingCodeunit(PostingCodeunitId);
        BatchProcessingMgt.BatchProcess(RecRef);

        RecRef.SetTable(RentalHeader);
    end;

    local procedure PrepareRentalHeader(var RentalHeader: Record "TWE Rental Header"; var BatchConfirm: Option)
    var
        CalcInvoiceDiscont: Boolean;
        ReplacePostingDate: Boolean;
        PostingDate: Date;
    begin
        BatchProcessingMgt.GetBooleanParameter(RentalHeader.RecordId, "Batch Posting Parameter Type"::"Calculate Invoice Discount", CalcInvoiceDiscont);
        BatchProcessingMgt.GetBooleanParameter(RentalHeader.RecordId, "Batch Posting Parameter Type"::"Replace Posting Date", ReplacePostingDate);
        BatchProcessingMgt.GetDateParameter(RentalHeader.RecordId, "Batch Posting Parameter Type"::"Posting Date", PostingDate);

        if CalcInvoiceDiscont then
            CalculateInvoiceDiscount(RentalHeader);

        RentalHeader.BatchConfirmUpdateDeferralDate(BatchConfirm, ReplacePostingDate, PostingDate);

        BatchProcessingMgt.GetBooleanParameter(RentalHeader.RecordId, "Batch Posting Parameter Type"::Ship, RentalHeader.Ship);
        BatchProcessingMgt.GetBooleanParameter(RentalHeader.RecordId, "Batch Posting Parameter Type"::Invoice, RentalHeader.Invoice);
        BatchProcessingMgt.GetBooleanParameter(RentalHeader.RecordId, "Batch Posting Parameter Type"::Receive, RentalHeader.Receive);
        BatchProcessingMgt.GetBooleanParameter(RentalHeader.RecordId, "Batch Posting Parameter Type"::Print, RentalHeader."Print Posted Documents");

        OnAfterPrepareRentalHeader(RentalHeader);
    end;

    procedure SetPostingCodeunitId(NewPostingCodeunitId: Integer)
    begin
        PostingCodeunitId := NewPostingCodeunitId;
    end;

    local procedure CalculateInvoiceDiscount(var RentalHeader: Record "TWE Rental Header")
    var
        RentalLine: Record "TWE Rental Line";
    begin
        RentalLine.Reset();
        RentalLine.SetRange("Document Type", RentalHeader."Document Type");
        RentalLine.SetRange("Document No.", RentalHeader."No.");
        if RentalLine.FindFirst() then begin
            CODEUNIT.Run(CODEUNIT::"TWE Rental-Calc. Discount", RentalLine);
            Commit();
            RentalHeader.Get(RentalHeader."Document Type", RentalHeader."No.");
        end;
    end;

    local procedure CanPostDocument(var RentalHeader: Record "TWE Rental Header"): Boolean
    begin
        if not CheckApprovalWorkflow(RentalHeader) then
            exit(false);

        if not RentalHeader.IsApprovedForPostingBatch() then
            exit(false);

        exit(true);
    end;

    [TryFunction]
    local procedure CheckApprovalWorkflow(var RentalHeader: Record "TWE Rental Header")
    var
        RentalApprovalsMgmt: Codeunit "TWE Rental Approvals Mgmt.";
    begin
        if RentalApprovalsMgmt.IsRentalApprovalsWorkflowEnabled(RentalHeader) then
            Error(ApprovalWorkflowErr, RentalHeader."No.", RentalHeader."Document Type");

        if RentalHeader.Status = RentalHeader.Status::"Pending Approval" then
            Error(ApprovalPendingErr, RentalHeader."No.", RentalHeader."Document Type");
    end;

    procedure SetParameter(ParameterId: Enum "Batch Posting Parameter Type"; ParameterValue: Variant)
    var
        ResultBatchProcessingMgt: Codeunit "Batch Processing Mgt.";
    begin
        GetBatchProcessor(ResultBatchProcessingMgt);
        ResultBatchProcessingMgt.SetParameter(ParameterId, ParameterValue);
    end;

    local procedure ProcessBatchInBackground(var RentalHeader: Record "TWE Rental Header"; var SkippedRecordExists: Boolean)
    var
        JobQueueEntry: Record "Job Queue Entry";
        RentalPostBatchviaJobQueue: Codeunit "TWE Rental Post Batch VJQ";
    begin
        PrepareBatch(RentalHeader, JobQueueEntry, SkippedRecordExists);
        RentalPostBatchviaJobQueue.EnqueueRentalBatch(RentalHeader, JobQueueEntry);
    end;

    local procedure PrepareBatch(var RentalHeader: Record "TWE Rental Header"; var JobQueueEntry: Record "Job Queue Entry"; var SkippedRecordExists: Boolean)
    var
        ErrorMessageManagement: Codeunit "Error Message Management";
        Window: Dialog;
        BatchConfirm: Option;
        DocCounter: array[2] of Integer;
    begin
        if RentalHeader.FindSet() then begin
            if GuiAllowed then begin
                DocCounter[1] := RentalHeader.Count;
                Window.Open(ProcessBarMsg);
            end;

            repeat
                if GuiAllowed then begin
                    DocCounter[2] += 1;
                    Window.Update(1, Round(DocCounter[2] / DocCounter[1] * 10000, 1));
                end;

                if CanProcessRentalHeader(RentalHeader) then begin
                    PrepareRentalHeader(RentalHeader, BatchConfirm);
                    PrepareJobQueueEntry(JobQueueEntry);
                    RentalHeader."Job Queue Entry ID" := JobQueueEntry.ID;
                    RentalHeader."Job Queue Status" := RentalHeader."Job Queue Status"::"Scheduled for Posting";
                    RentalHeader.Modify();
                    Commit();
                end else begin
                    SkippedRecordExists := true;
                    if GetLastErrorText <> '' then begin
                        ErrorMessageManagement.LogError(RentalHeader.RecordId, GetLastErrorText, '');
                        ClearLastError();
                    end;
                end;
            until RentalHeader.Next() = 0;

            if GuiAllowed then
                Window.Close();
        end;
    end;

    local procedure CanProcessRentalHeader(var RentalHeader: Record "TWE Rental Header"): Boolean
    begin
        if not CheckRentalHeaderJobQueueStatus(RentalHeader) then
            exit(false);

        if not CanPostDocument(RentalHeader) then
            exit(false);

        if not ReleaseRentalHeader(RentalHeader) then
            exit(false);

        exit(true);
    end;

    [TryFunction]
    local procedure CheckRentalHeaderJobQueueStatus(var RentalHeader: Record "TWE Rental Header")
    begin
        if not (RentalHeader."Job Queue Status" in [RentalHeader."Job Queue Status"::" ", RentalHeader."Job Queue Status"::Error]) then
            RentalHeader.FieldError("Job Queue Status");
    end;

    local procedure ReleaseRentalHeader(var RentalHeader: Record "TWE Rental Header"): Boolean
    begin
        if RentalHeader.Status = RentalHeader.Status::Open then
            if not Codeunit.Run(Codeunit::"TWE Release Rental Document", RentalHeader) then
                exit(false);
        exit(true);
    end;

    local procedure PrepareJobQueueEntry(var JobQueueEntry: Record "Job Queue Entry")
    begin
        if not IsNullGuid(JobQueueEntry.ID) then
            exit;

        Clear(JobQueueEntry);
        JobQueueEntry.ID := CreateGuid();
        JobQueueEntry.Insert(true);
    end;

    [EventSubscriber(ObjectType::Codeunit, 1380, 'OnBeforeBatchProcessing', '', false, false)]
    local procedure PrepareRentalHeaderOnBeforeBatchProcessing(var RecRef: RecordRef; var BatchConfirm: Option)
    var
        RentalHeader: Record "TWE Rental Header";
    begin
        RecRef.SetTable(RentalHeader);
        PrepareRentalHeader(RentalHeader, BatchConfirm);
        RecRef.GetTable(RentalHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, 1380, 'OnVerifyRecord', '', false, false)]
    local procedure CheckRentalHeaderOnVerifyRecord(var RecRef: RecordRef; var Result: Boolean)
    var
        RentalHeader: Record "TWE Rental Header";
    begin
        RecRef.SetTable(RentalHeader);
        Result := CanPostDocument(RentalHeader);
        RecRef.GetTable(RentalHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, 1380, 'OnCustomProcessing', '', false, false)]
    local procedure HandleOnCustomProcessing(var RecRef: RecordRef; var Handled: Boolean; var KeepParameters: Boolean)
    var
        RentalHeader: Record "TWE Rental Header";
        RentalSetup: Record "TWE Rental Setup";
        RentalPostViaJobQueue: Codeunit "TWE Rental Post via Job Queue";
    begin
        RecRef.SetTable(RentalHeader);

        RentalSetup.Get();
        if RentalSetup."Post with Job Queue" then begin
            RentalHeader."Print Posted Documents" :=
              RentalHeader."Print Posted Documents" and RentalSetup."Post & Print with Job Queue";
            RentalPostViaJobQueue.EnqueueRentalDocWithUI(RentalHeader, false);
            if not IsNullGuid(RentalHeader."Job Queue Entry ID") then begin
                Commit();
                KeepParameters := true;
            end;
            RentalHeader."Print Posted Documents" := false;
            RecRef.GetTable(RentalHeader);
            Handled := true;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPrepareRentalHeader(var RentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunBatchOnAfterAddParameters(var BatchProcessingMgt: Codeunit "Batch Processing Mgt.")
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Batch Processing Mgt.", 'OnIsPostWithJobQueueEnabled', '', false, false)]
    local procedure OnIsPostWithJobQueueEnabledHandler(var Result: Boolean)
    var
        RentalSetup: Record "TWE Rental Setup";
    begin
        RentalSetup.Get();
        Result := RentalSetup."Post with Job Queue";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Batch Processing Mgt.", 'OnProcessBatchInBackground', '', false, false)]
    local procedure OnProcessBatchInBackgroundHandler(var RecRef: RecordRef; var SkippedRecordExists: Boolean)
    var
        RentalHeader: Record "TWE Rental Header";
    begin
        RecRef.SetTable(RentalHeader);
        ProcessBatchInBackground(RentalHeader, SkippedRecordExists);
        RecRef.GetTable(RentalHeader);
    end;
}

