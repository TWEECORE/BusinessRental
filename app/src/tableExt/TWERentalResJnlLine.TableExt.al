/// <summary>
/// TableExtension TWE Rental Res. Jnl. Line (ID 50009) extends Record Res. Journal Line.
/// </summary>
tableextension 50009 "TWE Rental Res. Jnl. Line" extends "Res. Journal Line"
{
    /// <summary>
    /// CopyFromRentalHeader.
    /// </summary>
    /// <param name="RentalHeader">Record "TWE Rental Header".</param>
    procedure CopyFromRentalHeader(RentalHeader: Record "TWE Rental Header")
    begin
        "Posting Date" := RentalHeader."Posting Date";
        "Document Date" := RentalHeader."Document Date";
        "Reason Code" := RentalHeader."Reason Code";

        OnAfterCopyResJnlLineFromRentalHeader(RentalHeader, Rec);
    end;

    /// <summary>
    /// CopyFromRentalLine.
    /// </summary>
    /// <param name="RentalLine">Record "TWE Rental Line".</param>
    procedure CopyFromRentalLine(RentalLine: Record "TWE Rental Line")
    begin
        "Resource No." := RentalLine."No.";
        Description := RentalLine.Description;
        "Source Type" := "Source Type"::Customer;
        "Source No." := RentalLine."Rented-to Customer No.";
        "Work Type Code" := RentalLine."Work Type Code";
        "Unit of Measure Code" := RentalLine."Unit of Measure Code";
        "Shortcut Dimension 1 Code" := RentalLine."Shortcut Dimension 1 Code";
        "Shortcut Dimension 2 Code" := RentalLine."Shortcut Dimension 2 Code";
        "Dimension Set ID" := RentalLine."Dimension Set ID";
        "Gen. Bus. Posting Group" := RentalLine."Gen. Bus. Posting Group";
        "Gen. Prod. Posting Group" := RentalLine."Gen. Prod. Posting Group";
        "Entry Type" := "Entry Type"::Sale;
        "Qty. per Unit of Measure" := RentalLine."Qty. per Unit of Measure";
        Quantity := -RentalLine."Qty. to Invoice";
        "Unit Cost" := RentalLine."Unit Cost (LCY)";
        "Total Cost" := RentalLine."Unit Cost (LCY)" * Quantity;
        "Unit Price" := RentalLine."Unit Price";
        "Total Price" := -RentalLine.Amount;

        OnAfterCopyResJnlLineFromRentalLine(RentalLine, Rec);
    end;


    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyResJnlLineFromRentalHeader(var RentalHeader: Record "TWE Rental Header"; var ResJournalLine: Record "Res. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyResJnlLineFromRentalLine(var RentalLine: Record "TWE Rental Line"; var ResJnlLine: Record "Res. Journal Line")
    begin
    end;

}
