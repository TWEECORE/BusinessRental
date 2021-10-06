/// <summary>
/// Codeunit TWE Rental Test Report-Print (ID 50059).
/// </summary>
codeunit 50059 "TWE Rental Test Report-Print"
{

    trigger OnRun()
    begin
    end;

    var
        RentalReportSelection: Record "TWE Rental Report Selections";
        ItemJnlTemplate: Record "Item Journal Template";


    /// <summary>
    /// PrintRentalHeader.
    /// </summary>
    /// <param name="NewRentalHeader">Record "TWE Rental Header".</param>
    procedure PrintRentalHeader(NewRentalHeader: Record "TWE Rental Header")
    var
        RentalHeader: Record "TWE Rental Header";
    begin
        RentalHeader := NewRentalHeader;
        RentalHeader.SetRecFilter();
        CalcRentalDiscount(RentalHeader);
        RentalReportSelection.PrintWithCheckForCust(
            RentalReportSelection.Usage::"R.Test", RentalHeader, RentalHeader.FieldNo("Bill-to Customer No."));
    end;

    /// <summary>
    /// PrintRentalHeaderPrepmt.
    /// </summary>
    /// <param name="NewRentalHeader">Record "TWE Rental Header".</param>
    procedure PrintRentalHeaderPrepmt(NewRentalHeader: Record "TWE Rental Header")
    var
        RentalHeader: Record "TWE Rental Header";
    begin
        RentalHeader := NewRentalHeader;
        RentalHeader.SetRecFilter();
        RentalReportSelection.PrintWithCheckForCust(
            RentalReportSelection.Usage::"R.Test Prepmt.", RentalHeader, RentalHeader.FieldNo("Bill-to Customer No."));
    end;

    local procedure CalcRentalDiscount(var RentalHeader: Record "TWE Rental Header")
    var
        RentalLine: Record "TWE Rental Line";
        RentalSetup: Record "TWE Rental Setup";
    begin
        RentalSetup.Get();
        if RentalSetup."Calc. Inv. Discount" then begin
            RentalLine.Reset();
            RentalLine.SetRange("Document Type", RentalHeader."Document Type");
            RentalLine.SetRange("Document No.", RentalHeader."No.");
            OnCalcRentalDiscOnAfterSetFilters(RentalLine, RentalHeader);
            RentalLine.FindFirst();
            OnCalcRentalDiscOnBeforeRun(RentalHeader, RentalLine);
            CODEUNIT.Run(CODEUNIT::"TWE Rental-Calc. Discount", RentalLine);
            RentalHeader.Get(RentalHeader."Document Type", RentalHeader."No.");
            Commit();
        end;

        OnAfterCalcRentalDiscount(RentalHeader, RentalLine);
    end;

    /// <summary>
    /// PrintItemJnlBatch.
    /// </summary>
    /// <param name="RentalItemJnlBatch">Record "TWE Rental Item Journal Batch".</param>
    procedure PrintItemJnlBatch(RentalItemJnlBatch: Record "TWE Rental Item Journal Batch")
    begin
        RentalItemJnlBatch.SetRecFilter();
        ItemJnlTemplate.Get(RentalItemJnlBatch."Journal Template Name");
        ItemJnlTemplate.TestField("Test Report ID");
        REPORT.Run(ItemJnlTemplate."Test Report ID", true, false, RentalItemJnlBatch);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcRentalDiscount(var RentalHeader: Record "TWE Rental Header"; var RentalLine: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcRentalDiscOnAfterSetFilters(var RentalLine: Record "TWE Rental Line"; RentalHeader: Record "TWE Rental Header");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcRentalDiscOnBeforeRun(RentalHeader: Record "TWE Rental Header"; var RentalLine: Record "TWE Rental Line")
    begin
    end;
}

