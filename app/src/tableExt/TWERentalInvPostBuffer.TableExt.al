/// <summary>
/// TableExtension TWE Rental Inv. Post. Buffer (ID 50006) extends Record Invoice Post. Buffer.
/// </summary>
tableextension 50006 "TWE Rental Inv. Post. Buffer" extends "Invoice Post. Buffer"
{
    /// <summary>
    /// PrepareRental.
    /// </summary>
    /// <param name="RentalLine">VAR Record "TWE Rental Line".</param>
    procedure PrepareRental(var RentalLine: Record "TWE Rental Line")
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        OnBeforePrepareRental(Rec, RentalLine);

        Clear(Rec);
        Type := RentalLine.Type;
        "System-Created Entry" := true;
        "Gen. Bus. Posting Group" := RentalLine."Gen. Bus. Posting Group";
        "Gen. Prod. Posting Group" := RentalLine."Gen. Prod. Posting Group";
        "VAT Bus. Posting Group" := RentalLine."VAT Bus. Posting Group";
        "VAT Prod. Posting Group" := RentalLine."VAT Prod. Posting Group";
        "VAT Calculation Type" := RentalLine."VAT Calculation Type";
        "Global Dimension 1 Code" := RentalLine."Shortcut Dimension 1 Code";
        "Global Dimension 2 Code" := RentalLine."Shortcut Dimension 2 Code";
        "Dimension Set ID" := RentalLine."Dimension Set ID";
        "VAT %" := RentalLine."VAT %";
        "VAT Difference" := RentalLine."VAT Difference";
        if Type = Type::"Fixed Asset" then
            "FA Posting Date" := RentalLine."FA Posting Date";

        UpdateEntryDescriptionFromRentalLine(RentalLine);

        if "VAT Calculation Type" = "VAT Calculation Type"::"Sales Tax" then
            SetRentalTaxForRentalLine(RentalLine);

        DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Global Dimension 1 Code", "Global Dimension 2 Code");

        if RentalLine."Line Discount %" = 100 then begin
            "VAT Base Amount" := 0;
            "VAT Base Amount (ACY)" := 0;
            "VAT Amount" := 0;
            "VAT Amount (ACY)" := 0;
        end;

        OnAfterInvPostBufferPrepareRental(RentalLine, Rec);
    end;

    /// <summary>
    /// SetRentalTaxForRentalLine.
    /// </summary>
    /// <param name="RentalLine">Record "TWE Rental Line".</param>
    procedure SetRentalTaxForRentalLine(RentalLine: Record "TWE Rental Line")
    begin
        "Tax Area Code" := RentalLine."Tax Area Code";
        "Tax Liable" := RentalLine."Tax Liable";
        "Tax Group Code" := RentalLine."Tax Group Code";
        "Use Tax" := false;
        Quantity := RentalLine."Qty. to Invoice (Base)";
    end;


    local procedure UpdateEntryDescriptionFromRentalLine(RentalLine: Record "TWE Rental Line")
    var
        RentalHeader: Record "TWE Rental Header";
        SalesSetup: record "Sales & Receivables Setup";
    begin
        SalesSetup.Get();
        RentalHeader.get(RentalLine."Document Type", RentalLine."Document No.");
        UpdateEntryDescription(
            SalesSetup."Copy Line Descr. to G/L Entry",
            RentalLine."Line No.",
            RentalLine.Description,
            RentalHeader."Posting Description");
    end;

    local procedure UpdateEntryDescription(CopyLineDescrToGLEntry: Boolean; LineNo: Integer; LineDescription: text[100]; HeaderDescription: Text[100])
    begin
        if CopyLineDescrToGLEntry and (Type = type::"G/L Account") then begin
            "Entry Description" := LineDescription;
            "Fixed Asset Line No." := LineNo;
        end else
            "Entry Description" := HeaderDescription;
    end;


    [IntegrationEvent(false, false)]
    local procedure OnAfterInvPostBufferPrepareRental(var RentalLine: Record "TWE Rental Line"; var InvoicePostBuffer: Record "Invoice Post. Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrepareRental(var InvoicePostBuffer: Record "Invoice Post. Buffer"; var RentalLine: Record "TWE Rental Line")
    begin
    end;

}
