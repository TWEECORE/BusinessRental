/// <summary>
/// TableExtension TWE Rental Gen. Jnl. Line (ID 50005) extends Record Gen. Journal Line.
/// </summary>
tableextension 50005 "TWE Rental Gen. Jnl. Line" extends "Gen. Journal Line"
{

    /// <summary>
    /// CopyFromRentalHeader.
    /// </summary>
    /// <param name="RentalHeader">Record "TWE Rental Header".</param>
    procedure CopyFromRentalHeader(RentalHeader: Record "TWE Rental Header")
    begin
        "Source Currency Code" := RentalHeader."Currency Code";
        "Currency Factor" := RentalHeader."Currency Factor";
        "VAT Base Discount %" := RentalHeader."VAT Base Discount %";
        Correction := RentalHeader.Correction;
        "EU 3-Party Trade" := RentalHeader."EU 3-Party Trade";
        "Sell-to/Buy-from No." := RentalHeader."Rented-to Customer No.";
        "Bill-to/Pay-to No." := RentalHeader."Bill-to Customer No.";
        "Country/Region Code" := RentalHeader."VAT Country/Region Code";
        "VAT Registration No." := RentalHeader."VAT Registration No.";
        "Source Type" := "Source Type"::Customer;
        "Source No." := RentalHeader."Bill-to Customer No.";
        "Posting No. Series" := RentalHeader."Posting No. Series";
        "Ship-to/Order Address Code" := RentalHeader."Ship-to Code";
        "IC Partner Code" := RentalHeader."Bill-to IC Partner Code";
        "Salespers./Purch. Code" := RentalHeader."Salesperson Code";
        "On Hold" := RentalHeader."On Hold";
        if "Account Type" = "Account Type"::Customer then
            "Posting Group" := RentalHeader."Customer Posting Group";

        OnAfterCopyGenJnlLineFromRentalHeader(RentalHeader, Rec);
    end;

    /// <summary>
    /// CopyFromRentalHeaderApplyTo.
    /// </summary>
    /// <param name="RentalHeader">Record "TWE Rental Header".</param>
    procedure CopyFromRentalHeaderApplyTo(RentalHeader: Record "TWE Rental Header")
    begin
        "Applies-to Doc. Type" := RentalHeader."Applies-to Doc. Type";
        "Applies-to Doc. No." := RentalHeader."Applies-to Doc. No.";
        "Applies-to ID" := RentalHeader."Applies-to ID";
        "Allow Application" := RentalHeader."Bal. Account No." = '';

        OnAfterCopyGenJnlLineFromRentalHeaderApplyTo(RentalHeader, Rec);
    end;

    /// <summary>
    /// CopyFromRentalHeaderPayment.
    /// </summary>
    /// <param name="RentalHeader">Record "TWE Rental Header".</param>
    procedure CopyFromRentalHeaderPayment(RentalHeader: Record "TWE Rental Header")
    begin
        "Due Date" := RentalHeader."Due Date";
        "Payment Terms Code" := RentalHeader."Payment Terms Code";
        "Payment Method Code" := RentalHeader."Payment Method Code";
        "Pmt. Discount Date" := RentalHeader."Pmt. Discount Date";
        "Payment Discount %" := RentalHeader."Payment Discount %";
        "Direct Debit Mandate ID" := RentalHeader."Direct Debit Mandate ID";

        OnAfterCopyGenJnlLineFromRentalHeaderPayment(RentalHeader, Rec);
    end;

    procedure CopyFromRentalHeaderPrepmtPost(RentalHeader: Record "TWE Rental Header"; UsePmtDisc: Boolean)
    begin
        "Account Type" := "Account Type"::Customer;
        "Account No." := RentalHeader."Bill-to Customer No.";
        SetCurrencyFactor(RentalHeader."Currency Code", RentalHeader."Currency Factor");
        "Source Currency Code" := RentalHeader."Currency Code";
        "Sell-to/Buy-from No." := RentalHeader."Rented-to Customer No.";
        "Bill-to/Pay-to No." := RentalHeader."Bill-to Customer No.";
        "Salespers./Purch. Code" := RentalHeader."Salesperson Code";
        "Source Type" := "Source Type"::Customer;
        "Source No." := RentalHeader."Bill-to Customer No.";
        "IC Partner Code" := RentalHeader."Rented-to IC Partner Code";
        "System-Created Entry" := true;
        Prepayment := true;
        "Due Date" := RentalHeader."Prepayment Due Date";
        "Payment Terms Code" := RentalHeader."Prepmt. Payment Terms Code";
        if UsePmtDisc then begin
            "Pmt. Discount Date" := RentalHeader."Prepmt. Pmt. Discount Date";
            "Payment Discount %" := RentalHeader."Prepmt. Payment Discount %";
        end;

        OnAfterCopyGenJnlLineFromRentalHeaderPrepmtPost(RentalHeader, Rec, UsePmtDisc);
    end;

    procedure CopyFromRentalHeaderPrepmt(RentalHeader: Record "TWE Rental Header")
    begin
        "Source Currency Code" := RentalHeader."Currency Code";
        "VAT Base Discount %" := RentalHeader."VAT Base Discount %";
        "EU 3-Party Trade" := RentalHeader."EU 3-Party Trade";
        "Bill-to/Pay-to No." := RentalHeader."Bill-to Customer No.";
        "Country/Region Code" := RentalHeader."VAT Country/Region Code";
        "VAT Registration No." := RentalHeader."VAT Registration No.";
        "Source Type" := "Source Type"::Customer;
        "Source No." := RentalHeader."Bill-to Customer No.";
        "IC Partner Code" := RentalHeader."Rented-to IC Partner Code";
        "VAT Posting" := "VAT Posting"::"Manual VAT Entry";
        "System-Created Entry" := true;
        Prepayment := true;

        OnAfterCopyGenJnlLineFromRentalHeaderPrepmt(RentalHeader, Rec);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyGenJnlLineFromRentalHeader(RentalHeader: Record "TWE Rental Header"; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyGenJnlLineFromRentalHeaderApplyTo(RentalHeader: Record "TWE Rental Header"; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyGenJnlLineFromRentalHeaderPayment(RentalHeader: Record "TWE Rental Header"; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyGenJnlLineFromRentalHeaderPrepmtPost(RentalHeader: Record "TWE Rental Header"; var GenJournalLine: Record "Gen. Journal Line"; UsePmtDisc: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyGenJnlLineFromRentalHeaderPrepmt(RentalHeader: Record "TWE Rental Header"; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;
}
