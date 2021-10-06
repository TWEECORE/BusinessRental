/// <summary>
/// Page TWE Rental Invoice Statistics (ID 50007).
/// </summary>
page 50007 "TWE Rental Invoice Statistics"
{
    Caption = 'Rental Invoice Statistics';
    Editable = false;
    LinksAllowed = false;
    PageType = ListPlus;
    SourceTable = "TWE Rental Invoice Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("CustAmount + InvDiscAmount"; CustAmount + InvDiscAmount)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Amount';
                    ToolTip = 'Specifies the net amount of all the lines in the rental document.';
                }
                field(InvDiscAmount; InvDiscAmount)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Inv. Discount Amount';
                    ToolTip = 'Specifies the invoice discount amount for the rental document.';
                }
                field(CustAmount; CustAmount)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Total';
                    ToolTip = 'Specifies the total amount, less any invoice discount amount, and excluding VAT for the rental document.';
                }
                field(VATAmount; VATAmount)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = '3,' + Format(VATAmountText);
                    Caption = 'VAT Amount';
                    ToolTip = 'Specifies the total VAT amount that has been calculated for all the lines in the rental document.';
                }
                field(AmountInclVAT; AmountInclVAT)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Total Incl. VAT';
                    ToolTip = 'Specifies the total amount, including VAT, that will be posted to the customer''s account for all the lines in the rental document.';
                }
                field(AmountLCY; AmountLCY)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Rental (LCY)';
                    ToolTip = 'Specifies your total rental turnover in the fiscal year.';
                }
                field(ProfitLCY; ProfitLCY)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Original Profit (LCY)';
                    ToolTip = 'Specifies the original profit that was associated with the rental when they were originally posted.';
                }
                field(AdjustedProfitLCY; AdjProfitLCY)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Adjusted Profit (LCY)';
                    ToolTip = 'Specifies the profit, taking into consideration changes in the purchase prices of the goods.';
                }
                field(ProfitPct; ProfitPct)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Original Profit %';
                    DecimalPlaces = 1 : 1;
                    ToolTip = 'Specifies the original percentage of profit that was associated with the rental when they were originally posted.';
                }
                field(AdjProfitPct; AdjProfitPct)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Adjusted Profit %';
                    DecimalPlaces = 1 : 1;
                    ToolTip = 'Specifies the percentage of profit for all rental, including changes that occurred in the purchase prices of the goods.';
                }
                field(LineQty; LineQty)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Quantity';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the total quantity of G/L account entries, items and/or resources in the rental document.';
                }
                field(TotalParcels; TotalParcels)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Parcels';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the total number of parcels in the rental document.';
                }
                field(TotalNetWeight; TotalNetWeight)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Net Weight';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the total net weight of the items in the rental document.';
                }
                field(TotalGrossWeight; TotalGrossWeight)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Gross Weight';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the total gross weight of the items in the rental document.';
                }
                field(TotalVolume; TotalVolume)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Volume';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the total volume of the items in the rental document.';
                }
                field(CostLCY; CostLCY)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Original Cost (LCY)';
                    ToolTip = 'Specifies the total cost, in LCY, of the G/L account entries, items and/or resources in the rental document.';
                }
                field(AdjustedCostLCY; TotalAdjCostLCY)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Adjusted Cost (LCY)';
                    ToolTip = 'Specifies the total cost, in LCY, of the items in the posted rental invoice, adjusted for any changes in the original costs of these items.';
                }
                field("TotalAdjCostLCY - CostLCY"; TotalAdjCostLCY - CostLCY)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Cost Adjmt. Amount (LCY)';
                    ToolTip = 'Specifies the difference between the original cost and the total adjusted cost of the items in the posted rental invoice.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        Rec.LookupAdjmtValueEntries();
                    end;
                }
            }
            part(Subform; "VAT Specification Subform")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
            }
            group(Customer)
            {
                Caption = 'Customer';
                field("Cust. Balance (LCY)"; Cust."Balance (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Balance (LCY)';
                    ToolTip = 'Specifies the balance in LCY on the customer''s account.';
                }
                field("Cust. Credit Limit (LCY)"; Cust."Credit Limit (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Credit Limit (LCY)';
                    ToolTip = 'Specifies information about the credit limit in LCY, for the customer who you created and posted this rental invoice for. ';
                }
                field(CreditLimitLCYExpendedPct; CreditLimitLCYExpendedPct)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Expended % of Credit Limit (LCY)';
                    ExtendedDatatype = Ratio;
                    ToolTip = 'Specifies the expended percentage of the credit limit in (LCY).';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        ClearAll();

        Currency.Initialize(Rec."Currency Code");

        CalculateTotals();

        VATAmount := AmountInclVAT - CustAmount;
        InvDiscAmount := Round(InvDiscAmount, Currency."Amount Rounding Precision");

        if VATPercentage <= 0 then
            VATAmountText := Text000Lbl
        else
            VATAmountText := StrSubstNo(Text001Lbl, VATPercentage);

        if Rec."Currency Code" = '' then
            AmountLCY := CustAmount
        else
            AmountLCY :=
              CurrExchRate.ExchangeAmtFCYToLCY(
              WorkDate(), Rec."Currency Code", CustAmount, Rec."Currency Factor");

        CustLedgEntry.SetCurrentKey("Document No.");
        CustLedgEntry.SetRange("Document No.", Rec."No.");
        CustLedgEntry.SetRange("Document Type", CustLedgEntry."Document Type"::Invoice);
        CustLedgEntry.SetRange("Customer No.", Rec."Bill-to Customer No.");
        if CustLedgEntry.FindFirst() then
            AmountLCY := CustLedgEntry."Sales (LCY)";

        ProfitLCY := AmountLCY - CostLCY;
        if AmountLCY <> 0 then
            ProfitPct := Round(100 * ProfitLCY / AmountLCY, 0.1);

        AdjProfitLCY := AmountLCY - TotalAdjCostLCY;

        OnAfterGetRecordOnAfterCalculateAdjProfitLCY(Rec, AdjProfitLCY);

        if AmountLCY <> 0 then
            AdjProfitPct := Round(100 * AdjProfitLCY / AmountLCY, 0.1);

        if Cust.Get(Rec."Bill-to Customer No.") then
            Cust.CalcFields("Balance (LCY)")
        else
            Clear(Cust);

        case true of
            Cust."Credit Limit (LCY)" = 0:
                CreditLimitLCYExpendedPct := 0;
            Cust."Balance (LCY)" / Cust."Credit Limit (LCY)" < 0:
                CreditLimitLCYExpendedPct := 0;
            Cust."Balance (LCY)" / Cust."Credit Limit (LCY)" > 1:
                CreditLimitLCYExpendedPct := 10000;
            else
                CreditLimitLCYExpendedPct := Round(Cust."Balance (LCY)" / Cust."Credit Limit (LCY)" * 10000, 1);
        end;

        RentalInvLine.CalcVATAmountLines(Rec, TempVATAmountLine);
        CurrPage.Subform.PAGE.SetTempVATAmountLine(TempVATAmountLine);
        CurrPage.Subform.PAGE.InitGlobals(Rec."Currency Code", false, false, false, false, Rec."VAT Base Discount %");
    end;

    var
        CurrExchRate: Record "Currency Exchange Rate";
        RentalInvLine: Record "TWE Rental Invoice Line";
        Cust: Record Customer;
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        Currency: Record Currency;
        TotalAdjCostLCY: Decimal;
        CustAmount: Decimal;
        AmountInclVAT: Decimal;
        InvDiscAmount: Decimal;
        VATAmount: Decimal;
        ProfitLCY: Decimal;
        ProfitPct: Decimal;
        AdjProfitLCY: Decimal;
        AdjProfitPct: Decimal;
        LineQty: Decimal;
        TotalNetWeight: Decimal;
        TotalGrossWeight: Decimal;
        TotalVolume: Decimal;
        TotalParcels: Decimal;
        CreditLimitLCYExpendedPct: Decimal;
        VATPercentage: Decimal;
        VATAmountText: Text[30];
        Text000Lbl: Label 'VAT Amount';
        Text001Lbl: Label '%1% VAT', Comment = '%1 = VAT Percentage';

    protected var
        AmountLCY: Decimal;
        CostLCY: Decimal;

    local procedure CalculateTotals()
    var
        RentalCostCalcMgt: Codeunit "TWE Rental Cost Calc. Mgt.";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalculateTotals(
            Rec, CustAmount, AmountInclVAT, InvDiscAmount, CostLCY, TotalAdjCostLCY,
            LineQty, TotalNetWeight, TotalGrossWeight, TotalVolume, TotalParcels, IsHandled, VATpercentage);
        if IsHandled then
            exit;

        RentalInvLine.SetRange("Document No.", Rec."No.");
        if RentalInvLine.Find('-') then
            repeat
                CustAmount += RentalInvLine.Amount;
                AmountInclVAT += RentalInvLine."Amount Including VAT";
                if Rec."Prices Including VAT" then
                    InvDiscAmount += RentalInvLine."Inv. Discount Amount" / (1 + RentalInvLine."VAT %" / 100)
                else
                    InvDiscAmount += RentalInvLine."Inv. Discount Amount";
                CostLCY += RentalInvLine.Quantity * RentalInvLine."Unit Cost (LCY)";
                LineQty += RentalInvLine.Quantity;
                TotalNetWeight += RentalInvLine.Quantity * RentalInvLine."Net Weight";
                TotalGrossWeight += RentalInvLine.Quantity * RentalInvLine."Gross Weight";
                TotalVolume += RentalInvLine.Quantity * RentalInvLine."Unit Volume";
                if RentalInvLine."Units per Parcel" > 0 then
                    TotalParcels += Round(RentalInvLine.Quantity / RentalInvLine."Units per Parcel", 1, '>');
                if RentalInvLine."VAT %" <> VATPercentage then
                    if VATPercentage = 0 then
                        VATPercentage := RentalInvLine."VAT %"
                    else
                        VATPercentage := -1;
                TotalAdjCostLCY +=
                 RentalCostCalcMgt.CalcRentalInvLineCostLCY(RentalInvLine) + RentalCostCalcMgt.CalcRentalInvLineNonInvtblCostAmt(RentalInvLine);

                OnCalculateTotalsOnAfterAddLineTotals(
                    RentalInvLine, CustAmount, AmountInclVAT, InvDiscAmount, CostLCY, TotalAdjCostLCY,
                    LineQty, TotalNetWeight, TotalGrossWeight, TotalVolume, TotalParcels)
            until RentalInvLine.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRecordOnAfterCalculateAdjProfitLCY(RentalInvoiceHeader: Record "TWE Rental Invoice Header"; var AdjProfitLCY: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateTotals(RentalInvoiceHeader: Record "TWE Rental Invoice Header"; var CustAmount: Decimal; var AmountInclVAT: Decimal; var InvDiscAmount: Decimal; var CostLCY: Decimal; var TotalAdjCostLCY: Decimal; var LineQty: Decimal; var TotalNetWeight: Decimal; var TotalGrossWeight: Decimal; var TotalVolume: Decimal; var TotalParcels: Decimal; var IsHandled: Boolean; var VATPercentage: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateTotalsOnAfterAddLineTotals(var RentalInvLine: Record "TWE Rental Invoice Line"; var CustAmount: Decimal; var AmountInclVAT: Decimal; var InvDiscAmount: Decimal; var CostLCY: Decimal; var TotalAdjCostLCY: Decimal; var LineQty: Decimal; var TotalNetWeight: Decimal; var TotalGrossWeight: Decimal; var TotalVolume: Decimal; var TotalParcels: Decimal)
    begin
    end;
}

