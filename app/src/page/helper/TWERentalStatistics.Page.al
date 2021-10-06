/// <summary>
/// Page TWE Rental Statistics (ID 50018).
/// </summary>
page 50018 "TWE Rental Statistics"
{
    Caption = 'Rental Statistics';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = ListPlus;
    SourceTable = "TWE Rental Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(Amount; TotalRentalLine."Line Amount")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = GetCaptionClass(Text002Lbl, false);
                    Caption = 'Amount';
                    Editable = false;
                    ToolTip = 'Specifies the net amount of all the lines in the rental document.';
                }
                field(InvDiscountAmount; TotalRentalLine."Inv. Discount Amount")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Inv. Discount Amount';
                    ToolTip = 'Specifies the invoice discount amount for the rental document.';

                    trigger OnValidate()
                    begin
                        UpdateInvDiscAmount();
                    end;
                }
                field(TotalAmount1; TotalAmount1)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = GetCaptionClass(Text001Lbl, false);
                    Caption = 'Total';
                    ToolTip = 'Specifies the total amount less any invoice discount amount and excluding VAT for the rental document.';

                    trigger OnValidate()
                    begin
                        UpdateTotalAmount();
                    end;
                }
                field(VATAmount; VATAmount)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = '3,' + Format(VATAmountText);
                    Caption = 'VAT Amount';
                    Editable = false;
                    ToolTip = 'Specifies the total VAT amount that has been calculated for all the lines in the rental document.';
                }
                field(TotalAmount2; TotalAmount2)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = GetCaptionClass(Text001Lbl, true);
                    Caption = 'Total Incl. VAT';
                    Editable = false;
                    ToolTip = 'Specifies the total amount including VAT that will be posted to the customer''s account for all the lines in the rental document. This is the amount that the customer owes based on this rental document. If the document is a credit memo, it is the amount that you owe to the customer.';
                }
                field("TotalRentalLineLCY.Amount"; TotalRentalLineLCY.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Rental (LCY)';
                    Editable = false;
                    ToolTip = 'Specifies your total rental turnover in the fiscal year. It is calculated from amounts excluding VAT on all completed and open rental invoices and credit memos.';
                }
                field(ProfitLCY; ProfitLCY)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Original Profit (LCY)';
                    Editable = false;
                    ToolTip = 'Specifies the original profit that was associated with the rental when they were originally posted.';
                }
                field(AdjProfitLCY; AdjProfitLCY)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Adjusted Profit (LCY)';
                    Editable = false;
                    ToolTip = 'Specifies the profit, taking into consideration changes in the purchase prices of the goods.';
                }
                field(ProfitPct; ProfitPct)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Original Profit %';
                    DecimalPlaces = 1 : 1;
                    Editable = false;
                    ToolTip = 'Specifies the original percentage of profit that was associated with the rental when they were originally posted.';
                }
                field(AdjProfitPct; AdjProfitPct)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Adjusted Profit %';
                    DecimalPlaces = 1 : 1;
                    Editable = false;
                    ToolTip = 'Specifies the percentage of profit for all rental, taking into account changes that occurred in the purchase prices of the goods.';
                }
                field("TotalRentalLine.Quantity"; TotalRentalLine.Quantity)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Quantity';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the total quantity of G/L account entries, items, and/or resources in the rental document. If the amount is rounded, because the Invoice Rounding check box is selected in the Rental Setup window, this field will contain the quantity of items in the rental document plus one.';
                }
                field(TotalRentalLineLCYUnitCostLCY; TotalRentalLineLCY."Unit Cost (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Original Cost (LCY)';
                    Editable = false;
                    ToolTip = 'Specifies the total cost, in LCY, of the G/L account entries, items, and/or resources in the rental document. The cost is calculated as unit cost x quantity of the items or resources.';
                }
                field(TotalAdjCostLCY; TotalAdjCostLCY)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Adjusted Cost (LCY)';
                    Editable = false;
                    ToolTip = 'Specifies the total cost, in LCY, of the items in the rental document, adjusted for any changes in the original costs of these items. If this field contains zero, it means that there were no entries to calculate, possibly because of date compression or because the adjustment batch job has not yet been run.';
                }
                field(TotalAdjCostLCYTotalRentalLineLCYUnitCostLCY; TotalAdjCostLCY - TotalRentalLineLCY."Unit Cost (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Cost Adjmt. Amount (LCY)';
                    Editable = false;
                    ToolTip = 'Specifies the difference between the original cost and the total adjusted cost of the items in the rental document.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        Rec.LookupAdjmtValueEntries(0);
                    end;
                }
            }
            part(SubForm; "VAT Specification Subform")
            {
                ApplicationArea = Basic, Suite;
            }
            group(Customer)
            {
                Caption = 'Customer';
                field(CustBalanceLCY; Cust."Balance (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Balance (LCY)';
                    Editable = false;
                    ToolTip = 'Specifies the balance on the customer''s account.';
                }
                field(CustCreditLimitLCY; Cust."Credit Limit (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Credit Limit (LCY)';
                    Editable = false;
                    ToolTip = 'Specifies the credit limit of the customer that you created the rental document for.';
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
    begin
        CurrPage.Caption(StrSubstNo(Text000Lbl, Rec."Document Type"));
        if PrevNo = Rec."No." then begin
            GetVATSpecification();
            exit;
        end;

        PrevNo := Rec."No.";
        Rec.FilterGroup(2);
        Rec.SetRange("No.", PrevNo);
        Rec.FilterGroup(0);

        CalculateTotals();
    end;

    trigger OnOpenPage()
    begin
        RentalSetup.Get();
        AllowInvDisc := CustInvDiscRecExists(Rec."Invoice Disc. Code") and not (RentalSetup."Calc. Inv. Discount");
        AllowVATDifference :=
          RentalSetup."Allow VAT Difference" and
          not (Rec."Document Type" in [Rec."Document Type"::Quote]);
        OnOpenPageOnBeforeSetEditable(AllowInvDisc, AllowVATDifference, Rec);
        CurrPage.Editable := AllowVATDifference or AllowInvDisc;
        SetVATSpecification();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        GetVATSpecification();
        if TempVATAmountLine.GetAnyLineModified() then
            UpdateVATOnRentalLines();
        exit(true);
    end;

    var
        Cust: Record Customer;
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        RentalSetup: Record "TWE Rental Setup";
        RentalPost: Codeunit "TWE Rental-Post";
        TotalAmount1: Decimal;
        TotalAmount2: Decimal;
        VATAmountText: Text[30];
        ProfitLCY: Decimal;
        ProfitPct: Decimal;
        AdjProfitLCY: Decimal;
        AdjProfitPct: Decimal;
        TotalAdjCostLCY: Decimal;
        CreditLimitLCYExpendedPct: Decimal;
        PrevNo: Code[20];
        AllowInvDisc: Boolean;
        AllowVATDifference: Boolean;
        Text000Lbl: Label 'Rental %1 Statistics', Comment = '%1 = Document Type';
        Text001Lbl: Label 'Total';
        Text002Lbl: Label 'Amount';
        Text003Lbl: Label '%1 must not be 0.', Comment = '%1 = FieldCaption "Inv. Disc. Base Amount"';
        Text004Lbl: Label '%1 must not be greater than %2.', Comment = '%1 = FieldCaption "Inv. Discount Amount",%2 =  FieldCaption "Inv. Disc. Base Amount"';
        Text005Lbl: Label 'You cannot change the invoice discount because there is a %1 record for %2 %3.', Comment = 'You cannot change the invoice discount because there is a Cust. Invoice Disc. record for Invoice Disc. Code 30000. %1 = CustInvDisc TableCaption,%2 = FieldCaption "Invoice Disc. Code",%3 = ."Invoice Disc. Code"';

    protected var
        TotalRentalLine: Record "TWE Rental Line";
        TotalRentalLineLCY: Record "TWE Rental Line";
        VATAmount: Decimal;

    local procedure UpdateHeaderInfo()
    var
        CurrExchRate: Record "Currency Exchange Rate";
        UseDate: Date;
    begin
        TotalRentalLine."Inv. Discount Amount" := TempVATAmountLine.GetTotalInvDiscAmount();
        TotalAmount1 :=
          TotalRentalLine."Line Amount" - TotalRentalLine."Inv. Discount Amount";
        VATAmount := TempVATAmountLine.GetTotalVATAmount();
        if Rec."Prices Including VAT" then begin
            TotalAmount1 := TempVATAmountLine.GetTotalAmountInclVAT();
            TotalAmount2 := TotalAmount1 - VATAmount;
            TotalRentalLine."Line Amount" := TotalAmount1 + TotalRentalLine."Inv. Discount Amount";
        end else
            TotalAmount2 := TotalAmount1 + VATAmount;

        if Rec."Prices Including VAT" then
            TotalRentalLineLCY.Amount := TotalAmount2
        else
            TotalRentalLineLCY.Amount := TotalAmount1;
        if Rec."Currency Code" <> '' then begin
            if (Rec."Document Type" in [Rec."Document Type"::Quote]) and
               (Rec."Posting Date" = 0D)
            then
                UseDate := WorkDate()
            else
                UseDate := Rec."Posting Date";

            TotalRentalLineLCY.Amount :=
              CurrExchRate.ExchangeAmtFCYToLCY(
                UseDate, Rec."Currency Code", TotalRentalLineLCY.Amount, Rec."Currency Factor");
        end;
        ProfitLCY := TotalRentalLineLCY.Amount - TotalRentalLineLCY."Unit Cost (LCY)";
        if TotalRentalLineLCY.Amount = 0 then
            ProfitPct := 0
        else
            ProfitPct := Round(100 * ProfitLCY / TotalRentalLineLCY.Amount, 0.01);

        AdjProfitLCY := TotalRentalLineLCY.Amount - TotalAdjCostLCY;
        if TotalRentalLineLCY.Amount = 0 then
            AdjProfitPct := 0
        else
            AdjProfitPct := Round(100 * AdjProfitLCY / TotalRentalLineLCY.Amount, 0.01);

        OnAfterUpdateHeaderInfo(TotalRentalLineLCY);
    end;

    local procedure GetVATSpecification()
    begin
        CurrPage.SubForm.PAGE.GetTempVATAmountLine(TempVATAmountLine);
        if TempVATAmountLine.GetAnyLineModified() then
            UpdateHeaderInfo();
    end;

    local procedure SetVATSpecification()
    begin
        CurrPage.SubForm.PAGE.SetTempVATAmountLine(TempVATAmountLine);
        CurrPage.SubForm.PAGE.InitGlobals(
          Rec."Currency Code", AllowVATDifference, AllowVATDifference,
          Rec."Prices Including VAT", AllowInvDisc, Rec."VAT Base Discount %");
    end;

    local procedure UpdateTotalAmount()
    var
        SaveTotalAmount: Decimal;
    begin
        CheckAllowInvDisc();
        if Rec."Prices Including VAT" then begin
            SaveTotalAmount := TotalAmount1;
            UpdateInvDiscAmount();
            TotalAmount1 := SaveTotalAmount;
        end;

        TotalRentalLine."Inv. Discount Amount" := TotalRentalLine."Line Amount" - TotalAmount1;
        UpdateInvDiscAmount();
    end;

    local procedure UpdateInvDiscAmount()
    var
        InvDiscBaseAmount: Decimal;
    begin
        CheckAllowInvDisc();
        InvDiscBaseAmount := TempVATAmountLine.GetTotalInvDiscBaseAmount(false, Rec."Currency Code");
        if InvDiscBaseAmount = 0 then
            Error(Text003Lbl, TempVATAmountLine.FieldCaption("Inv. Disc. Base Amount"));

        if TotalRentalLine."Inv. Discount Amount" / InvDiscBaseAmount > 1 then
            Error(
              Text004Lbl,
              TotalRentalLine.FieldCaption("Inv. Discount Amount"),
              TempVATAmountLine.FieldCaption("Inv. Disc. Base Amount"));

        TempVATAmountLine.SetInvoiceDiscountAmount(
          TotalRentalLine."Inv. Discount Amount", Rec."Currency Code", Rec."Prices Including VAT", Rec."VAT Base Discount %");
        CurrPage.SubForm.PAGE.SetTempVATAmountLine(TempVATAmountLine);
        UpdateHeaderInfo();

        Rec."Invoice Discount Calculation" := Rec."Invoice Discount Calculation"::Amount;
        Rec."Invoice Discount Value" := TotalRentalLine."Inv. Discount Amount";
        Rec.Modify();
        UpdateVATOnRentalLines();
    end;

    local procedure GetCaptionClass(FieldCaption: Text[100]; ReverseCaption: Boolean): Text[80]
    begin
        if Rec."Prices Including VAT" xor ReverseCaption then
            exit(CopyStr('2,1,' + FieldCaption, 1, 80));

        exit(CopyStr('2,0,' + FieldCaption, 1, 80));
    end;

    /// <summary>
    /// UpdateVATOnRentalLines.
    /// </summary>
    procedure UpdateVATOnRentalLines()
    var
        RentalLine: Record "TWE Rental Line";
    begin
        GetVATSpecification();
        if TempVATAmountLine.GetAnyLineModified() then begin
            RentalLine.UpdateVATOnLines(0, Rec, RentalLine, TempVATAmountLine);
            RentalLine.UpdateVATOnLines(1, Rec, RentalLine, TempVATAmountLine);
        end;
        PrevNo := '';
    end;

    local procedure CustInvDiscRecExists(InvDiscCode: Code[20]): Boolean
    var
        CustInvDisc: Record "Cust. Invoice Disc.";
    begin
        CustInvDisc.SetRange(Code, InvDiscCode);
        exit(not CustInvDisc.IsEmpty());
    end;

    local procedure CheckAllowInvDisc()
    var
        CustInvDisc: Record "Cust. Invoice Disc.";
    begin
        if not AllowInvDisc then
            Error(
              Text005Lbl,
              CustInvDisc.TableCaption, Rec.FieldCaption("Invoice Disc. Code"), Rec."Invoice Disc. Code");
    end;

    local procedure CalculateTotals()
    var
        RentalLine: Record "TWE Rental Line";
        TempRentalLine: Record "TWE Rental Line" temporary;
    begin
        Clear(RentalLine);
        Clear(TotalRentalLine);
        Clear(TotalRentalLineLCY);
        Clear(RentalPost);

        RentalPost.GetRentalLines(Rec, TempRentalLine, 0);
        OnCalculateTotalsOnAfterGetRentalLines(Rec, TempRentalLine);
        Clear(RentalPost);
        RentalPost.SumSalesLinesTemp(
          Rec, TempRentalLine, 0, TotalRentalLine, TotalRentalLineLCY,
          VATAmount, VATAmountText, ProfitLCY, ProfitPct, TotalAdjCostLCY);

        AdjProfitLCY := TotalRentalLineLCY.Amount - TotalAdjCostLCY;
        if TotalRentalLineLCY.Amount <> 0 then
            AdjProfitPct := Round(AdjProfitLCY / TotalRentalLineLCY.Amount * 100, 0.1);

        if Rec."Prices Including VAT" then begin
            TotalAmount2 := TotalRentalLine.Amount;
            TotalAmount1 := TotalAmount2 + VATAmount;
            TotalRentalLine."Line Amount" := TotalAmount1 + TotalRentalLine."Inv. Discount Amount";
        end else begin
            TotalAmount1 := TotalRentalLine.Amount;
            TotalAmount2 := TotalRentalLine."Amount Including VAT";
        end;

        if Cust.Get(Rec."Bill-to Customer No.") then
            Cust.CalcFields("Balance (LCY)")
        else
            Clear(Cust);
        if Cust."Credit Limit (LCY)" = 0 then
            CreditLimitLCYExpendedPct := 0
        else
            if Cust."Balance (LCY)" / Cust."Credit Limit (LCY)" < 0 then
                CreditLimitLCYExpendedPct := 0
            else
                if Cust."Balance (LCY)" / Cust."Credit Limit (LCY)" > 1 then
                    CreditLimitLCYExpendedPct := 10000
                else
                    CreditLimitLCYExpendedPct := Round(Cust."Balance (LCY)" / Cust."Credit Limit (LCY)" * 10000, 1);

        RentalLine.CalcVATAmountLines(0, Rec, TempRentalLine, TempVATAmountLine);
        TempVATAmountLine.ModifyAll(Modified, false);
        SetVATSpecification();

        OnAfterCalculateTotals(Rec, TotalRentalLine, TotalRentalLineLCY, TempVATAmountLine, TotalAmount1, TotalAmount2);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalculateTotals(var RentalHeader: Record "TWE Rental Header"; var TotalRentalLine: Record "TWE Rental Line"; var TotalRentalLineLCY: Record "TWE Rental Line"; var TempVATAmountLine: Record "VAT Amount Line" temporary; var TotalAmt1: Decimal; var TotalAmt2: Decimal)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterUpdateHeaderInfo(TotalRentalLineLCY: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateTotalsOnAfterGetRentalLines(RentalHeader: Record "TWE Rental Header"; var TempRentalLine: Record "TWE Rental Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOpenPageOnBeforeSetEditable(var AllowInvDisc: Boolean; var AllowVATDifference: Boolean; RentalHeader: Record "TWE Rental Header")
    begin
    end;
}

