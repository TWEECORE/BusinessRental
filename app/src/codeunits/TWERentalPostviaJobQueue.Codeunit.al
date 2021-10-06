codeunit 50035 "TWE Rental Post via Job Queue"
{
    TableNo = "Job Queue Entry";

    trigger OnRun()
    var
        RentalHeader: Record "TWE Rental Header";
        BatchProcessingMgt: Codeunit "Batch Processing Mgt.";
        RentalBatchPostingPrintMgt: Codeunit "TWE Batch Post. Print Mgt.";
        RecRef: RecordRef;
        RecRefToPrint: RecordRef;
        SavedLockTimeout: Boolean;
    begin
        Rec.TestField("Record ID to Process");
        RecRef.Get(Rec."Record ID to Process");
        RecRef.SetTable(RentalHeader);
        RentalHeader.Find();

        //BatchProcessingMgt.GetBatchFromSession("Record ID to Process", "User Session ID");

        SavedLockTimeout := LockTimeout;
        SetJobQueueStatus(RentalHeader, RentalHeader."Job Queue Status"::Posting);
        OnRunOnBeforeRunRentalPost(RentalHeader);
        if not Codeunit.Run(Codeunit::"TWE Rental-Post", RentalHeader) then begin
            SetJobQueueStatus(RentalHeader, RentalHeader."Job Queue Status"::Error);
            BatchProcessingMgt.ResetBatchID();
            Error(GetLastErrorText);
        end;
        OnRunOnAfterRunRentalPost(RentalHeader);
        if RentalHeader."Print Posted Documents" then begin
            RecRefToPrint.GetTable(RentalHeader);
            RentalBatchPostingPrintMgt.PrintRentalDocument(RecRefToPrint);
        end;
        if not AreOtherJobQueueEntriesScheduled(Rec) then
            BatchProcessingMgt.ResetBatchID();
        BatchProcessingMgt.DeleteBatchProcessingSessionMapForRecordId(RentalHeader.RecordId);
        SetJobQueueStatus(RentalHeader, RentalHeader."Job Queue Status"::" ");
        LockTimeout(SavedLockTimeout);
    end;

    var
        PostDescriptionLbl: Label 'Post Rental %1 %2.', Comment = '%1 = document type, %2 = document number. Example: Post Rental Order 1234.';
        PostAndPrintDescriptionLbl: Label 'Post and Print Rental %1 %2.', Comment = '%1 = document type, %2 = document number. Example: Post Rental Order 1234.';
        ConfirmationLbl: Label '%1 %2 has been scheduled for posting.', Comment = '%1=document type, %2=number, e.g. Order 123  or Invoice 234.';
        WrongJobQueueStatusLbl: Label '%1 %2 cannot be posted because it has already been scheduled for posting. Choose the Remove from Job Queue action to reset the job queue status and then post again.', Comment = '%1 = document type, %2 = document number. Example: Rental Order 1234 or Invoice 1234.';
        DefaultCategoryCodeLbl: Label 'SALESBCKGR', Locked = true;
        DefaultCategoryDescLbl: Label 'Def. Background Rental Posting', Locked = true;

    local procedure SetJobQueueStatus(var RentalHeader: Record "TWE Rental Header"; NewStatus: Option)
    begin
        RentalHeader.LockTable();
        if RentalHeader.Find() then begin
            RentalHeader."Job Queue Status" := NewStatus;
            RentalHeader.Modify();
            Commit();
        end;
    end;

    procedure EnqueueRentalDoc(var RentalHeader: Record "TWE Rental Header")
    begin
        EnqueueRentalDocWithUI(RentalHeader, true);
    end;

    procedure EnqueueRentalDocWithUI(var RentalHeader: Record "TWE Rental Header"; WithUI: Boolean)
    var
        TempInvoice: Boolean;
        TempRcpt: Boolean;
        TempShip: Boolean;
        Handled: Boolean;
    begin
        OnBeforeEnqueueRentalDoc(RentalHeader, Handled);
        if Handled then
            exit;

        if not (RentalHeader."Job Queue Status" in [RentalHeader."Job Queue Status"::" ", RentalHeader."Job Queue Status"::Error]) then
            Error(WrongJobQueueStatusLbl, RentalHeader."Document Type", RentalHeader."No.");
        TempInvoice := RentalHeader.Invoice;
        TempRcpt := RentalHeader.Receive;
        TempShip := RentalHeader.Ship;
        OnBeforeReleaseRentalDoc(RentalHeader);
        if RentalHeader.Status = RentalHeader.Status::Open then
            CODEUNIT.Run(CODEUNIT::"TWE Release Rental Document", RentalHeader);
        RentalHeader.Invoice := TempInvoice;
        RentalHeader.Receive := TempRcpt;
        RentalHeader.Ship := TempShip;
        RentalHeader."Job Queue Status" := RentalHeader."Job Queue Status"::"Scheduled for Posting";
        RentalHeader."Job Queue Entry ID" := EnqueueJobEntry(RentalHeader);
        RentalHeader.Modify();

        if GuiAllowed then
            if WithUI then
                Message(ConfirmationLbl, RentalHeader."Document Type", RentalHeader."No.");
    end;

    local procedure EnqueueJobEntry(RentalHeader: Record "TWE Rental Header"): Guid
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        Clear(JobQueueEntry.ID);
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := CODEUNIT::"TWE Rental Post Batch VJQ";
        JobQueueEntry."Record ID to Process" := RentalHeader.RecordId;
        FillJobEntryFromRentalSetup(JobQueueEntry);
        FillJobEntryRentalDescription(JobQueueEntry, RentalHeader);
        JobQueueEntry."User Session ID" := SessionId();
        CODEUNIT.Run(CODEUNIT::"Job Queue - Enqueue", JobQueueEntry);
        exit(JobQueueEntry.ID)
    end;

    local procedure FillJobEntryFromRentalSetup(var JobQueueEntry: Record "Job Queue Entry")
    var
        RentalSetup: Record "TWE Rental Setup";
    begin
        RentalSetup.Get();
        JobQueueEntry."Notify On Success" := RentalSetup."Notify On Success";
        JobQueueEntry."Job Queue Category Code" := GetJobQueueCategoryCode();
    end;

    local procedure FillJobEntryRentalDescription(var JobQueueEntry: Record "Job Queue Entry"; RentalHeader: Record "TWE Rental Header")
    begin
        if RentalHeader."Print Posted Documents" then
            JobQueueEntry.Description := PostAndPrintDescriptionLbl
        else
            JobQueueEntry.Description := PostDescriptionLbl;
        JobQueueEntry.Description :=
          CopyStr(StrSubstNo(JobQueueEntry.Description, RentalHeader."Document Type", RentalHeader."No."), 1, MaxStrLen(JobQueueEntry.Description));
    end;

    procedure CancelQueueEntry(var RentalHeader: Record "TWE Rental Header")
    begin
        if RentalHeader."Job Queue Status" <> RentalHeader."Job Queue Status"::" " then begin
            DeleteJobs(RentalHeader);
            RentalHeader."Job Queue Status" := RentalHeader."Job Queue Status"::" ";
            RentalHeader.Modify();
        end;
    end;

    local procedure DeleteJobs(RentalHeader: Record "TWE Rental Header")
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        if not IsNullGuid(RentalHeader."Job Queue Entry ID") then
            JobQueueEntry.SetRange(ID, RentalHeader."Job Queue Entry ID");
        JobQueueEntry.SetRange("Record ID to Process", RentalHeader.RecordId);
        if not JobQueueEntry.IsEmpty() then
            JobQueueEntry.DeleteAll(true);
    end;

    local procedure AreOtherJobQueueEntriesScheduled(JobQueueEntry: Record "Job Queue Entry"): Boolean
    var
        RentalSetup: Record "TWE Rental Setup";
        JobQueueEntryFilter: Record "Job Queue Entry";
        result: Boolean;
    begin
        RentalSetup.Get();
        JobQueueEntryFilter.SetFilter("Job Queue Category Code", GetJobQueueCategoryCode());
        JobQueueEntryFilter.SetFilter(ID, '<>%1', JobQueueEntry.ID);
        JobQueueEntryFilter.SetRange("Object ID to Run", JobQueueEntry."Object ID to Run");
        JobQueueEntryFilter.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run");
        JobQueueEntryFilter.SetRange("User Session ID", JobQueueEntry."User Session ID");
        JobQueueEntryFilter.SetFilter(
            Status, '%1|%2|%3|%4',
            JobQueueEntry.Status::"In Process", JobQueueEntry.Status::"On Hold",
            JobQueueEntry.Status::"On Hold with Inactivity Timeout", JobQueueEntry.Status::Ready);
        result := not JobQueueEntryFilter.IsEmpty;

        exit(result);
    end;

    internal procedure GetJobQueueCategoryCode(): Code[10]
    var
        RentalSetup: Record "TWE Rental Setup";
        JobQueueCategory: Record "Job Queue Category";
    begin
        RentalSetup.Get();
        if RentalSetup."Job Queue Category Code" <> '' then
            exit(RentalSetup."Job Queue Category Code");

        JobQueueCategory.InsertRec(
            CopyStr(DefaultCategoryCodeLbl, 1, MaxStrLen(JobQueueCategory.Code)),
            CopyStr(DefaultCategoryDescLbl, 1, MaxStrLen(JobQueueCategory.Description)));
        exit(JobQueueCategory.Code);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeEnqueueRentalDoc(var RentalHeader: Record "TWE Rental Header"; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReleaseRentalDoc(var RentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterRunRentalPost(var RentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeRunRentalPost(var RentalHeader: Record "TWE Rental Header")
    begin
    end;
}

