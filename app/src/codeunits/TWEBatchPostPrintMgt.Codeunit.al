codeunit 50000 "TWE Batch Post. Print Mgt."
{
    trigger OnRun()
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, 1380, 'OnAfterBatchProcessing', '', false, false)]
    local procedure PrintDocumentOnAfterBatchPosting(var RecRef: RecordRef; PostingResult: Boolean)
    var
        BatchProcessingMgt: Codeunit "Batch Processing Mgt.";
        Print: Boolean;
    begin
        if not PostingResult then
            exit;

        if not BatchProcessingMgt.GetBooleanParameter(RecRef.RecordId, "Batch Posting Parameter Type"::Print, Print) or not Print then
            exit;

        PrintRentalDocument(RecRef);
    end;

    procedure PrintRentalDocument(RecRef: RecordRef)
    var
        RentalHeader: Record "TWE Rental Header";
        RentalReportSelections: Record "TWE Rental Report Selections";
        RentalInvoiceHeader: Record "TWE Rental Invoice Header";
        RentalShipmentHeader: Record "TWE Rental Shipment Header";
        RentalCrMemoHeader: Record "TWE Rental Cr.Memo Header";
        RentalSetup: Record "TWE Rental Setup";
    begin
        if RecRef.Number <> DATABASE::"TWE Rental Header" then
            exit;

        RecRef.SetTable(RentalHeader);
        if not RentalHeader."Print Posted Documents" then
            exit;

        RentalSetup.Get();
        case RentalHeader."Document Type" of
            RentalHeader."Document Type"::Contract:
                begin
                    if RentalHeader.Ship then begin
                        RentalShipmentHeader."No." := RentalHeader."Last Shipping No.";
                        RentalShipmentHeader.SetRecFilter();
                        PrintDocument(
                            RentalReportSelections.Usage::"R.Shipment", RentalShipmentHeader,
                            RentalSetup."Post & Print with Job Queue",
                            RentalSetup."Report Output Type");
                    end;
                    if RentalHeader.Invoice then begin
                        RentalInvoiceHeader."No." := RentalHeader."Last Posting No.";
                        RentalInvoiceHeader.SetRecFilter();
                        PrintDocument(
                            RentalReportSelections.Usage::"R.Invoice", RentalInvoiceHeader,
                            RentalSetup."Post & Print with Job Queue",
                            RentalSetup."Report Output Type");
                    end;
                end;
            RentalHeader."Document Type"::Invoice:
                begin
                    if RentalHeader."Last Posting No." = '' then
                        RentalInvoiceHeader."No." := RentalHeader."No."
                    else
                        RentalInvoiceHeader."No." := RentalHeader."Last Posting No.";
                    RentalInvoiceHeader.SetRecFilter();
                    PrintDocument(
                        RentalReportSelections.Usage::"R.Invoice", RentalInvoiceHeader,
                        RentalSetup."Post & Print with Job Queue",
                        RentalSetup."Report Output Type");
                end;
            RentalHeader."Document Type"::"Credit Memo":
                begin
                    if RentalHeader."Last Posting No." = '' then
                        RentalCrMemoHeader."No." := RentalHeader."No."
                    else
                        RentalCrMemoHeader."No." := RentalHeader."Last Posting No.";
                    RentalCrMemoHeader.SetRecFilter();
                    PrintDocument(
                        RentalReportSelections.Usage::"R.Cr.Memo", RentalCrMemoHeader,
                        RentalSetup."Post & Print with Job Queue",
                        RentalSetup."Report Output Type");
                end;
        end;

        OnAfterPrintSalesDocument(RecRef);
    end;

    local procedure PrintDocument(RentalReportUsage: Enum "TWE Rent. Report Sel. Usage"; RecVar: Variant; PrintViaJobQueue: Boolean; ReportOutputType: Option)
    var
        RentalReportSelections: Record "TWE Rental Report Selections";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePrintDocument(RentalReportUsage.AsInteger(), RecVar, IsHandled);
        if IsHandled then
            exit;

        RentalReportSelections.Reset();
        RentalReportSelections.SetRange(Usage, RentalReportUsage);
        RentalReportSelections.FindSet();
        repeat
            RentalReportSelections.TestField("Report ID");
            if PrintViaJobQueue then
                SchedulePrintJobQueueEntry(RecVar, RentalReportSelections."Report ID", ReportOutputType)
            else
                REPORT.Run(RentalReportSelections."Report ID", false, false, RecVar);
        until RentalReportSelections.Next() = 0;
    end;

    local procedure SchedulePrintJobQueueEntry(RecVar: Variant; ReportId: Integer; ReportOutputType: Option)
    var
        JobQueueEntry: Record "Job Queue Entry";
        RecRefToPrint: RecordRef;
    begin
        RecRefToPrint.GetTable(RecVar);
        Clear(JobQueueEntry.ID);
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Report;
        JobQueueEntry."Object ID to Run" := ReportId;
        JobQueueEntry."Report Output Type" := ReportOutputType;
        JobQueueEntry."Record ID to Process" := RecRefToPrint.RecordId;
        JobQueueEntry.Description := Format(JobQueueEntry."Report Output Type");
        CODEUNIT.Run(CODEUNIT::"Job Queue - Enqueue", JobQueueEntry);
        Commit();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPrintSalesDocument(RecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintDocument(ReportUsage: Option; RecVar: Variant; var IsHandled: Boolean)
    begin
    end;
}

