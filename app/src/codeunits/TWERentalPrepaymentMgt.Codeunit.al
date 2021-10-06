codeunit 50037 "TWE Rental Prepayment Mgt."
{

    trigger OnRun()
    begin
    end;

    var
        JobQueueEntryHasStartedTxt: Label 'A job for changing the status from Pending Prepayment to Release has started with the frequency %1.', Comment = '%1 - job queue frequency';
        StatusOfRentalOrderIsChangedTxt: Label 'The status of the sales order %1 is changed from Pending Prepayment to Release.', Comment = '%1 - sales order no.';
        UpdateRentalOrderStatusTxt: Label 'Update sales order status.';
        PrepaymentAmountHigherThanTheOrderErr: Label 'The Prepayment account is assigned to a VAT product posting group where the VAT percentage is not equal to zero. This can cause posting errors when invoices have mixed VAT lines. To avoid errors, set the VAT percentage to zero for the account.';

    procedure AssertPrepmtAmountNotMoreThanDocAmount(DocumentTotalInclVAT: Decimal; PrepmtTotalInclVAT: Decimal; CurrencyCode: Code[10]; InvoiceRoundingSetup: Boolean)
    var
        CurrencyLcl: Record Currency;
    begin
        if InvoiceRoundingSetup then begin
            CurrencyLcl.Initialize(CurrencyCode);
            DocumentTotalInclVAT :=
              Round(DocumentTotalInclVAT, CurrencyLcl."Invoice Rounding Precision", CurrencyLcl.InvoiceRoundingDirection());
        end;
        if Abs(PrepmtTotalInclVAT) > Abs(DocumentTotalInclVAT) then
            Error(PrepaymentAmountHigherThanTheOrderErr);
    end;

    procedure SetRentalPrepaymentPct(var RentalLine: Record "TWE Rental Line"; Date: Date)
    var
        Cust: Record Customer;
        RentalPrepaymentPct: Record "TWE Rental Prepayment %";
    begin
        if (RentalLine.Type <> RentalLine.Type::"Rental Item") or (RentalLine."No." = '') or
           (RentalLine."Document Type" <> RentalLine."Document Type"::Contract)
        then
            exit;
        RentalPrepaymentPct.SetFilter("Starting Date", '..%1', Date);
        RentalPrepaymentPct.SetFilter("Ending Date", '%1|>=%2', 0D, Date);
        RentalPrepaymentPct.SetRange("Item No.", RentalLine."No.");
        for RentalPrepaymentPct."Rental Type" := RentalPrepaymentPct."Rental Type"::Customer to RentalPrepaymentPct."Rental Type"::"All Customers" do begin
            RentalPrepaymentPct.SetRange("Rental Type", RentalPrepaymentPct."Rental Type");
            case RentalPrepaymentPct."Rental Type" of
                RentalPrepaymentPct."Rental Type"::Customer:
                    begin
                        RentalPrepaymentPct.SetRange("Rental Code", RentalLine."Bill-to Customer No.");
                        if ApplyRentalPrepaymentPct(RentalLine, RentalPrepaymentPct) then
                            exit;
                    end;
                RentalPrepaymentPct."Rental Type"::"Customer Price Group":
                    begin
                        Cust.Get(RentalLine."Bill-to Customer No.");
                        if Cust."Customer Price Group" <> '' then
                            RentalPrepaymentPct.SetRange("Rental Code", Cust."Customer Price Group");
                        if ApplyRentalPrepaymentPct(RentalLine, RentalPrepaymentPct) then
                            exit;
                    end;
                RentalPrepaymentPct."Rental Type"::"All Customers":
                    begin
                        RentalPrepaymentPct.SetRange("Rental Code");
                        if ApplyRentalPrepaymentPct(RentalLine, RentalPrepaymentPct) then
                            exit;
                    end;
            end;
        end;
    end;

    local procedure ApplyRentalPrepaymentPct(var RentalLine: Record "TWE Rental Line"; var RentalPrepaymentPct: Record "TWE Rental Prepayment %"): Boolean
    begin
        if RentalPrepaymentPct.FindLast() then begin
            RentalLine."Prepayment %" := RentalPrepaymentPct."Prepayment %";
            exit(true);
        end;
    end;

    procedure TestRentalPrepayment(rentalHeader: Record "TWE Rental Header"): Boolean
    var
        rentalLine: Record "TWE Rental Line";
        IsHandled: Boolean;
        TestResult: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestRentalPrepayment(rentalHeader, TestResult, IsHandled);
        if IsHandled then
            exit(TestResult);

        rentalLine.SetRange("Document Type", rentalHeader."Document Type");
        rentalLine.SetRange("Document No.", rentalHeader."No.");
        if rentalLine.FindSet() then
            repeat
                if rentalLine."Prepmt. Line Amount" <> 0 then
                    if rentalLine."Prepmt. Amt. Inv." <> rentalLine."Prepmt. Line Amount" then
                        exit(true);
            until rentalLine.Next() = 0;
    end;

    procedure TestRentalPayment(rentalHeader: Record "TWE Rental Header") Result: Boolean
    var
        rentalSetup: Record "TWE Rental Setup";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        rentalInvHeader: Record "TWE Rental Invoice Header";
        IsHandled: Boolean;
    begin
        rentalSetup.Get();
        if not rentalSetup."Check Prepmt. when Posting" then
            exit(false);

        IsHandled := false;
        OnBeforeTestRentalPayment(rentalHeader, Result, IsHandled);
        if IsHandled then
            exit(Result);

        rentalInvHeader.SetCurrentKey("Prepayment Order No.", "Prepayment Invoice");
        rentalInvHeader.SetRange("Prepayment Order No.", rentalHeader."No.");
        rentalInvHeader.SetRange("Prepayment Invoice", true);
        if rentalInvHeader.FindSet() then
            repeat
                OnTestRentalPaymentOnBeforeCustLedgerEntrySetFilter(CustLedgerEntry, rentalHeader, rentalInvHeader);
                CustLedgerEntry.SetCurrentKey("Document No.");
                CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
                CustLedgerEntry.SetRange("Document No.", rentalInvHeader."No.");
                CustLedgerEntry.SetFilter("Remaining Amt. (LCY)", '<>%1', 0);
                if not CustLedgerEntry.IsEmpty then
                    exit(true);
            until rentalInvHeader.Next() = 0;

        exit(false);
    end;

    procedure UpdatePendingPrepaymentRental()
    var
        rentalHeader: Record "TWE Rental Header";
        RentalPrepaymentMgt: Codeunit "TWE Rental Prepayment Mgt.";
    begin
        rentalHeader.SetRange("Document Type", rentalHeader."Document Type"::Contract);
        rentalHeader.SetRange(Status, rentalHeader.Status::"Pending Prepayment");
        if rentalHeader.FindSet(true) then
            repeat
                if not RentalPrepaymentMgt.TestRentalPayment(rentalHeader) then begin
                    CODEUNIT.Run(CODEUNIT::"TWE Release Rental Document", rentalHeader);
                    if rentalHeader.Status = rentalHeader.Status::Released then
                        Session.LogMessage('0000254', StrSubstNo(StatusOfRentalOrderIsChangedTxt, Format(rentalHeader."No.")), Verbosity::Normal, DataClassification::CustomerContent, TelemetryScope::ExtensionPublisher, 'Category', UpdateRentalOrderStatusTxt);
                end;
            until rentalHeader.Next() = 0;
    end;

    procedure CreateAndStartJobQueueEntryRental(UpdateFrequency: Option Never,Daily,Weekly)
    begin
        CreateAndStartJobQueueEntry(
          CODEUNIT::"TWE Upd. Pend. Prepmt. Rent.", UpdateFrequency, UpdateRentalOrderStatusTxt);
    end;

    procedure CreateAndStartJobQueueEntry(CodeunitID: Integer; UpdateFrequency: Option Never,Daily,Weekly; Category: Text)
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueManagement: Codeunit "Job Queue Management";
    begin
        JobQueueManagement.DeleteJobQueueEntries(JobQueueEntry."Object Type to Run"::Codeunit, CodeunitID);

        JobQueueEntry."No. of Minutes between Runs" := UpdateFrequencyToNoOfMinutes(UpdateFrequency);
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := CodeunitID;
        JobQueueManagement.CreateJobQueueEntry(JobQueueEntry);

        CODEUNIT.Run(CODEUNIT::"Job Queue - Enqueue", JobQueueEntry);
        Session.LogMessage('0000256', StrSubstNo(JobQueueEntryHasStartedTxt, Format(UpdateFrequency)), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', Category);
    end;

    local procedure UpdateFrequencyToNoOfMinutes(UpdateFrequency: Option Never,Daily,Weekly): Integer
    begin
        case UpdateFrequency of
            UpdateFrequency::Never:
                exit(0);
            UpdateFrequency::Daily:
                exit(60 * 24);
            UpdateFrequency::Weekly:
                exit(60 * 24 * 7);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestRentalPrepayment(rentalHeader: Record "TWE Rental Header"; var TestResult: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestRentalPayment(rentalHeader: Record "TWE Rental Header"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTestRentalPaymentOnBeforeCustLedgerEntrySetFilter(var CustLedgerEntry: Record "Cust. Ledger Entry"; rentalHeader: Record "TWE Rental Header"; rentalInvHeader: Record "TWE Rental Invoice Header")
    begin
    end;
}

