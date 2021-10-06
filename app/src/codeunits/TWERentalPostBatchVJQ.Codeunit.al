codeunit 50031 "TWE Rental Post Batch VJQ"
{
    TableNo = "Job Queue Entry";

    trigger OnRun()
    begin
        PostRentalBatch(Rec);
    end;

    var
        UnpostedDocumentsErr: Label '%1 rental documents out of %2 have errors during posting.', Comment = '%1 - number of documents with errors, %2 - total number of documents';
        UnprintedDocumentsErr: Label '%1 rental documents out of %2 have errors during printing.', Comment = '%1 - number of documents with errors, %2 - total number of documents';
        DefaultCategoryCodeLbl: Label 'SALESBCKGR', Locked = true;
        DefaultCategoryDescLbl: Label 'Def. Background Rental Posting', Locked = true;
        PostingDescriptionTxt: Label 'Post rental documents batch.';
        PostAndPrintDescriptionTxt: Label 'Post and print rental documents batch.';
        PrintingDescriptionTxt: Label 'Print Rental %1 No. %2', Comment = '%1 - document type, %2 - document no.';

    local procedure PostRentalBatch(var JobQueueEntry: Record "Job Queue Entry")
    var
        RentalSetup: Record "TWE Rental Setup";
        RentalHeader: Record "TWE Rental Header";
        ErrorMessageManagement: Codeunit "Error Message Management";
        SavedLockTimeout: Boolean;
        TotalDocumentsCount: Integer;
        ErrorPostDocumentsCount: Integer;
        ErrorPrinttDocumentsCount: Integer;
    begin
        RentalSetup.Get();
        SavedLockTimeout := LockTimeout;
        RentalHeader.SetRange("Job Queue Entry ID", JobQueueEntry.ID);
        RentalHeader.SetRange("Job Queue Status", RentalHeader."Job Queue Status"::"Scheduled for Posting");
        if RentalHeader.FindSet() then
            repeat
                TotalDocumentsCount += 1;
                SetJobQueueStatus(RentalHeader, RentalHeader."Job Queue Status"::Posting);
                if not Codeunit.Run(Codeunit::"TWE Rental-Post", RentalHeader) then begin
                    SetJobQueueStatus(RentalHeader, RentalHeader."Job Queue Status"::Error);
                    ErrorMessageManagement.LogLastError();
                    ErrorPostDocumentsCount += 1;
                end else begin
                    SetJobQueueStatus(RentalHeader, RentalHeader."Job Queue Status"::" ");
                    if RentalSetup."Post & Print with Job Queue" then
                        if RentalHeader."Print Posted Documents" then
                            if not PrintRentalDocument(RentalHeader, JobQueueEntry) then
                                ErrorPrinttDocumentsCount += 1;
                end;
            until RentalHeader.Next() = 0;
        LockTimeout(SavedLockTimeout);

        if (ErrorPostDocumentsCount <> 0) or (ErrorPrinttDocumentsCount <> 0) then
            ThrowErrorMessage(TotalDocumentsCount, ErrorPostDocumentsCount, ErrorPrinttDocumentsCount);
    end;

    procedure EnqueueRentalBatch(var RentalHeader: Record "TWE Rental Header"; var JobQueueEntry: Record "Job Queue Entry")
    begin
        EnqueueJobQueueEntry(JobQueueEntry);
    end;

    local procedure EnqueueJobQueueEntry(var JobQueueEntry: Record "Job Queue Entry")
    var
        RentalSetup: Record "TWE Rental Setup";
    begin
        RentalSetup.Get();

        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := Codeunit::"TWE Rental Post Batch VJQ";
        JobQueueEntry."Notify On Success" := RentalSetup."Notify On Success";
        JobQueueEntry."Job Queue Category Code" := GetJobQueueCategoryCode();
        JobQueueEntry.Description := GetDescription();
        JobQueueEntry."User Session ID" := SessionId();
        Codeunit.Run(Codeunit::"Job Queue - Enqueue", JobQueueEntry);
    end;

    local procedure SetJobQueueStatus(var RentalHeader: Record "TWE Rental Header"; NewStatus: Option)
    begin
        RentalHeader.LockTable();
        if RentalHeader.Get(RentalHeader."Document Type", RentalHeader."No.") then begin
            RentalHeader."Job Queue Status" := NewStatus;
            RentalHeader.Modify();
            Commit();
        end;
    end;

    local procedure GetJobQueueCategoryCode(): Code[10]
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

    local procedure GetDescription(): Text[250]
    var
        RentalSetup: Record "TWE Rental Setup";
    begin
        RentalSetup.Get();
        if RentalSetup."Post & Print with Job Queue" then
            exit(PostAndPrintDescriptionTxt);
        exit(PostingDescriptionTxt);
    end;

    local procedure PrintRentalDocument(RentalHeader: Record "TWE Rental Header"; JobQueueEntry: Record "Job Queue Entry") Result: Boolean
    begin
        case RentalHeader."Document Type" of
            RentalHeader."Document Type"::Contract:
                begin
                    if RentalHeader.Ship then
                        Result := PrintShipmentDocument(RentalHeader, JobQueueEntry);
                    if RentalHeader.Invoice then
                        Result := Result or PrintInvoiceDocument(RentalHeader, JobQueueEntry);
                end;
            RentalHeader."Document Type"::Invoice:
                Result := PrintInvoiceDocument(RentalHeader, JobQueueEntry);
            RentalHeader."Document Type"::"Credit Memo":
                Result := PrintCrMemoDocument(RentalHeader, JobQueueEntry);
        end;
    end;

    local procedure PrintShipmentDocument(RentalHeader: Record "TWE Rental Header"; JobQueueEntry: Record "Job Queue Entry") Result: Boolean
    var
        RentalShipmentHeader: Record "TWE Rental Shipment Header";
        RecRef: RecordRef;
    begin
        RentalShipmentHeader."No." := RentalHeader."Last Shipping No.";
        RentalShipmentHeader.SetRecFilter();
        RecRef.GetTable(RentalShipmentHeader);
        Result := PrintDocument("TWE Rent. Report Sel. Usage"::"R.Shipment", RecRef, RentalHeader, JobQueueEntry);
    end;

    local procedure PrintInvoiceDocument(RentalHeader: Record "TWE Rental Header"; JobQueueEntry: Record "Job Queue Entry") Result: Boolean
    var
        RentalInvoiceHeader: Record "TWE Rental Invoice Header";
        RecRef: RecordRef;
    begin
        if RentalHeader."Last Posting No." = '' then
            RentalInvoiceHeader."No." := RentalHeader."No."
        else
            RentalInvoiceHeader."No." := RentalHeader."Last Posting No.";
        RentalInvoiceHeader.SetRecFilter();
        RecRef.GetTable(RentalInvoiceHeader);
        Result := PrintDocument("TWE Rent. Report Sel. Usage"::"R.Invoice", RecRef, RentalHeader, JobQueueEntry);
    end;

    local procedure PrintCrMemoDocument(RentalHeader: Record "TWE Rental Header"; JobQueueEntry: Record "Job Queue Entry") Result: Boolean
    var
        RentalCrMemoHeader: Record "TWE Rental Cr.Memo Header";
        RecRef: RecordRef;
    begin
        if RentalHeader."Last Posting No." = '' then
            RentalCrMemoHeader."No." := RentalHeader."No."
        else
            RentalCrMemoHeader."No." := RentalHeader."Last Posting No.";
        RentalCrMemoHeader.SetRecFilter();
        RecRef.GetTable(RentalCrMemoHeader);
        Result := PrintDocument("TWE Rent. Report Sel. Usage"::"R.Cr.Memo", RecRef, RentalHeader, JobQueueEntry);
    end;

    local procedure PrintDocument(ReportUsage: Enum "TWE Rent. Report Sel. Usage"; RecRef: RecordRef; RentalHeader: Record "TWE Rental Header"; JobQueueEntry: Record "Job Queue Entry") Result: Boolean
    var
        RentalReportSelections: Record "TWE Rental Report Selections";
        ErrorMessageManagement: Codeunit "Error Message Management";
        PrintingErrorExists: Boolean;
    begin
        RentalReportSelections.Reset();
        RentalReportSelections.SetRange(Usage, ReportUsage);
        RentalReportSelections.FindSet();
        repeat
            if CheckReportId(RentalReportSelections) then begin
                if not PrintToPDF(RentalReportSelections."Report ID", RecRef, RentalHeader, JobQueueEntry) then begin
                    ErrorMessageManagement.LogLastError();
                    PrintingErrorExists := true;
                end;
            end else begin
                ErrorMessageManagement.LogLastError();
                PrintingErrorExists := true;
            end;
        until RentalReportSelections.Next() = 0;

        Result := not PrintingErrorExists;
    end;

    local procedure PrintToPDF(ReportId: Integer; RecRef: RecordRef; RentalHeader: Record "TWE Rental Header"; JobQueueEntry: Record "Job Queue Entry"): Boolean
    var
        ReportInbox: Record "Report Inbox";
        OStream: OutStream;
    begin
        ReportInbox.Init();
        ReportInbox."User ID" := JobQueueEntry."User ID";
        ReportInbox."Job Queue Log Entry ID" := JobQueueEntry.ID;
        ReportInbox."Report ID" := ReportID;
        ReportInbox.Description := CopyStr(StrSubstNo(PrintingDescriptionTxt, RentalHeader."Document Type", RentalHeader."No."), 1, MaxStrLen(ReportInbox.Description));
        ReportInbox."Report Output".CreateOutStream(OStream);
        if not Report.SaveAs(ReportId, '', ReportFormat::Pdf, OStream, RecRef) then
            exit(false);
        ReportInbox."Created Date-Time" := RoundDateTime(CurrentDateTime, 60000);
        ReportInbox.Insert(true);

        exit(true);
    end;

    [TryFunction]
    local procedure CheckReportId(ReportSelections: Record "TWE Rental Report Selections")
    begin
        ReportSelections.TestField("Report ID");
    end;

    local procedure ThrowErrorMessage(TotalDocumentsCount: Integer; ErrorPostDocumentsCount: Integer; ErrorPrinttDocumentsCount: Integer)
    var
        ErrorMessage: Text;
    begin
        Commit();
        if ErrorPostDocumentsCount <> 0 then
            ErrorMessage := StrSubstNo(UnpostedDocumentsErr, ErrorPostDocumentsCount, TotalDocumentsCount) + ' ';
        if ErrorPrinttDocumentsCount <> 0 then
            ErrorMessage += StrSubstNo(UnprintedDocumentsErr, ErrorPrinttDocumentsCount, TotalDocumentsCount);
        ErrorMessage := DelChr(ErrorMessage, '>', ' ');
        Error(ErrorMessage);
    end;
}
