/// <summary>
/// Page TWE Rental Order Statistics (ID 50009).
/// </summary>
page 50009 "TWE Rental Order Statistics"
{
    Caption = 'Rental Order Statistics';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = Card;
    SourceTable = "TWE Rental Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(LineAmountGeneral; TotalRentalLine[1]."Line Amount")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = GetCaptionClass(Text002Lbl, false);
                    Editable = false;
                    ToolTip = 'Specifies the line amount for the rental document';
                }
                field(InvDiscountAmount_General; TotalRentalLine[1]."Inv. Discount Amount")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Inv. Discount Amount';
                    Editable = DynamicEditable;
                    ToolTip = 'Specifies the invoice discount amount for the rental document.';

                    trigger OnValidate()
                    begin
                        ActiveTab := ActiveTab::General;
                        UpdateInvDiscAmount(1);
                    end;
                }
                field("TotalAmount1[1]"; TotalAmount1[1])
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = GetCaptionClass(Text001Lbl, false);
                    Editable = DynamicEditable;
                    ToolTip = 'Specifies the total amount for the rental document.';

                    trigger OnValidate()
                    begin
                        ActiveTab := ActiveTab::General;
                        UpdateTotalAmount(1);
                    end;
                }
                field(VATAmount; VATAmount[1])
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = Format(VATAmountText[1]);
                    Caption = 'VAT Amount';
                    Editable = false;
                    ToolTip = 'Specifies the total VAT amount that has been calculated for all the lines in the rental document.';
                }
                field("TotalAmount2[1]"; TotalAmount2[1])
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = GetCaptionClass(Text001Lbl, true);
                    Editable = false;
                    ToolTip = 'Specifies the total amount 2 for the rental document.';


                    trigger OnValidate()
                    begin
                        TotalAmount21OnAfterValidate();
                    end;
                }
                field("TotalRentalLineLCY[1].Amount"; TotalRentalLineLCY[1].Amount)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Rental (LCY)';
                    Editable = false;
                    ToolTip = 'Specifies your total rental turnover in the fiscal year. It is calculated from amounts excluding VAT on all completed and open rental invoices and credit memos.';
                }
                field("ProfitLCY[1]"; ProfitLCY[1])
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Original Profit (LCY)';
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the original profit that was associated with the rental when they were originally posted.';
                }
                field("AdjProfitLCY[1]"; AdjProfitLCY[1])
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Adjusted Profit (LCY)';
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the profit, taking into consideration changes in the purchase prices of the goods.';
                }
                field("ProfitPct[1]"; ProfitPct[1])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Original Profit %';
                    DecimalPlaces = 1 : 1;
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the original percentage of profit that was associated with the rental when they were originally posted.';
                }
                field("AdjProfitPct[1]"; AdjProfitPct[1])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Adjusted Profit %';
                    DecimalPlaces = 1 : 1;
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the percentage of profit for all rental, taking into account changes that occurred in the purchase prices of the goods.';
                }
                field("TotalRentalLine[1].Quantity"; TotalRentalLine[1].Quantity)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Quantity';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the total quantity of G/L account entries, items, and/or resources in the rental document. If the amount is rounded, because the Invoice Rounding check box is selected in the Rental Setup window, this field will contain the quantity of items in the rental document plus one.';
                }
                field(TotalRentalLineLCY1UnitCostLCY; TotalRentalLineLCY[1]."Unit Cost (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Original Cost (LCY)';
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the total cost, in LCY, of the G/L account entries, items, and/or resources in the rental document. The cost is calculated as unit cost x quantity of the items or resources.';
                }
                field("TotalAdjCostLCY[1]"; TotalAdjCostLCY[1])
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Adjusted Cost (LCY)';
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the total cost, in LCY, of the items in the rental document, adjusted for any changes in the original costs of these items. If this field contains zero, it means that there were no entries to calculate, possibly because of date compression or because the adjustment batch job has not yet been run.';
                }
                field("TotalAdjCostLCY[1] - TotalRentalLineLCY[1].""Unit Cost (LCY)"""; TotalAdjCostLCY[1] - TotalRentalLineLCY[1]."Unit Cost (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Cost Adjmt. Amount (LCY)';
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the difference between the original cost and the total adjusted cost of the items in the rental document.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        Rec.LookupAdjmtValueEntries(0);
                    end;
                }
                field("NoOfVATLines_General"; TempVATAmountLine1.Count)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'No. of Tax Lines';
                    DrillDown = true;
                    Importance = Additional;
                    ToolTip = 'Specifies the number of lines on the rental contract that have VAT amounts.';

                    trigger OnDrillDown()
                    begin
                        VATLinesDrillDown(TempVATAmountLine1, false);
                        UpdateHeaderInfo(1, TempVATAmountLine1);
                    end;
                }
            }
            group(Invoicing)
            {
                Caption = 'Invoicing';
                field(AmountInclVAT_Invoicing; TotalRentalLine[2]."Line Amount")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = GetCaptionClass(Text002Lbl, false);
                    Editable = false;
                    ToolTip = 'Specifies the amount incl. VAT for the rental document.';

                }
                field(InvDiscountAmount_Invoicing; TotalRentalLine[2]."Inv. Discount Amount")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Inv. Discount Amount';
                    Editable = DynamicEditable;
                    ToolTip = 'Specifies the invoice discount amount for the rental document.';

                    trigger OnValidate()
                    begin
                        ActiveTab := ActiveTab::Invoicing;
                        UpdateInvDiscAmount(2);
                    end;
                }
                field(TotalInclVAT_Invoicing; TotalAmount1[2])
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = GetCaptionClass(Text001Lbl, false);
                    Editable = DynamicEditable;
                    ToolTip = 'Specifies the total amount incl. vats for the rental document.';


                    trigger OnValidate()
                    begin
                        ActiveTab := ActiveTab::Invoicing;
                        UpdateTotalAmount(2);
                    end;
                }
                field(VATAmount_Invoicing; VATAmount[2])
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = Format(VATAmountText[2]);
                    Editable = false;
                    ToolTip = 'Specifies the vat amount for the rental document.';

                }
                field(TotalExclVAT_Invoicing; TotalAmount2[2])
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = GetCaptionClass(Text001Lbl, true);
                    Editable = false;
                    ToolTip = 'Specifies the total amount excl. VAT for the rental document.';

                }
                field("TotalRentalLineLCY[2].Amount"; TotalRentalLineLCY[2].Amount)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Sales (LCY)';
                    Editable = false;
                    ToolTip = 'Specifies your total rental turnover in the fiscal year. It is calculated from amounts excluding VAT on all completed and open rental invoices and credit memos.';
                }
                field("ProfitLCY[2]"; ProfitLCY[2])
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Original Profit (LCY)';
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the original profit that was associated with the rental when they were originally posted.';
                }
                field("AdjProfitLCY[2]"; AdjProfitLCY[2])
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Adjusted Profit (LCY)';
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the profit, taking into consideration changes in the purchase prices of the goods.';
                }
                field("ProfitPct[2]"; ProfitPct[2])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Original Profit %';
                    DecimalPlaces = 1 : 1;
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the original percentage of profit that was associated with the rental when they were originally posted.';
                }
                field("AdjProfitPct[2]"; AdjProfitPct[2])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Adjusted Profit %';
                    DecimalPlaces = 1 : 1;
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the percentage of profit for all rental, taking into account changes that occurred in the purchase prices of the goods.';
                }
                field("TotalRentalLine[2].Quantity"; TotalRentalLine[2].Quantity)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Quantity';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the total quantity of G/L account entries, items, and/or resources in the rental document. If the amount is rounded, because the Invoice Rounding check box is selected in the Sales & Receivables Setup window, this field will contain the quantity of items in the rental document plus one.';
                }
                field(TotalRentalLineLCY2UnitCostLCY; TotalRentalLineLCY[2]."Unit Cost (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Original Cost (LCY)';
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the total cost, in LCY, of the G/L account entries, items, and/or resources in the rental document. The cost is calculated as unit cost x quantity of the items or resources.';
                }
                field("TotalAdjCostLCY[2]"; TotalAdjCostLCY[2])
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Adjusted Cost (LCY)';
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the total cost, in LCY, of the items in the rental document, adjusted for any changes in the original costs of these items. If this field contains zero, it means that there were no entries to calculate, possibly because of date compression or because the adjustment batch job has not yet been run.';
                }
                field("TotalAdjCostLCY[2] - TotalRentalLineLCY[2].""Unit Cost (LCY)"""; TotalAdjCostLCY[2] - TotalRentalLineLCY[2]."Unit Cost (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Cost Adjmt. Amount (LCY)';
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the difference between the original cost and the total adjusted cost of the items in the rental document.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        Rec.LookupAdjmtValueEntries(1);
                    end;
                }
                field("NoOfVATLines_Invoicing"; TempVATAmountLine2.Count)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'No. of Tax Lines';
                    DrillDown = true;
                    Importance = Additional;
                    ToolTip = 'Specifies the number of lines on the rental contract that have VAT amounts.';

                    trigger OnDrillDown()
                    begin
                        ActiveTab := ActiveTab::Invoicing;
                        VATLinesDrillDown(TempVATAmountLine2, true);
                        UpdateHeaderInfo(2, TempVATAmountLine2);

                        if TempVATAmountLine2.GetAnyLineModified() then begin
                            UpdateVATOnRentalLines();
                            RefreshOnAfterGetRecord();
                        end;
                    end;
                }
            }
            group(Shipping)
            {
                Caption = 'Shipping';
                field("TotalRentalLine[3].""Line Amount"""; TotalRentalLine[3]."Line Amount")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = GetCaptionClass(Text002Lbl, false);
                    Editable = false;
                    ToolTip = 'Specifies the line amount for the rental document.';
                }
                field("TotalRentalLine[3].""Inv. Discount Amount"""; TotalRentalLine[3]."Inv. Discount Amount")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Inv. Discount Amount';
                    Editable = false;
                    ToolTip = 'Specifies the invoice discount amount for the rental document.';
                }
                field("TotalAmount1[3]"; TotalAmount1[3])
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = GetCaptionClass(Text001Lbl, false);
                    ToolTip = 'Specifies the total amount for the rental document.';
                    Editable = false;
                }
                field("VATAmount[3]"; VATAmount[3])
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = Format(VATAmountText[3]);
                    Editable = false;
                    ToolTip = 'Specifies the vat amount for the rental document.';

                }
                field("TotalAmount2[3]"; TotalAmount2[3])
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = GetCaptionClass(Text001Lbl, true);
                    Editable = false;
                    ToolTip = 'Specifies the total amount 3 for the rental document.';

                }
                field("TotalRentalLineLCY[3].Amount"; TotalRentalLineLCY[3].Amount)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Rental (LCY)';
                    Editable = false;
                    ToolTip = 'Specifies your total rental turnover in the fiscal year. It is calculated from amounts excluding VAT on all completed and open rental invoices and credit memos.';
                }
                field("TotalRentalLineLCY[3].""Unit Cost (LCY)"""; TotalRentalLineLCY[3]."Unit Cost (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Cost (LCY)';
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the total cost of the rental contract.';
                }
                field("ProfitLCY[3]"; ProfitLCY[3])
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Profit (LCY)';
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the total profit of the rental contract.';
                }
                field("ProfitPct[3]"; ProfitPct[3])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Profit %';
                    DecimalPlaces = 1 : 1;
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the total profit of the rental contract expressed as a percentage of the total amount.';
                }
                field("TotalRentalLine[3].Quantity"; TotalRentalLine[3].Quantity)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Quantity';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the total quantity of G/L account entries, items, and/or resources in the rental document. If the amount is rounded, because the Invoice Rounding check box is selected in the Sales & Receivables Setup window, this field will contain the quantity of items in the rental document plus one.';
                }
                field("TempVATAmountLine3.COUNT"; TempVATAmountLine3.Count)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'No. of Tax Lines';
                    DrillDown = true;
                    Importance = Additional;
                    ToolTip = 'Specifies the number of lines on the rental contract that have VAT amounts.';

                    trigger OnDrillDown()
                    begin
                        VATLinesDrillDown(TempVATAmountLine3, false);
                    end;
                }
            }
            group(Prepayment)
            {
                Caption = 'Prepayment';
                field(PrepmtTotalAmount; PrepmtTotalAmount)
                {
                    ApplicationArea = Prepayments;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = GetCaptionClass(Text006Lbl, false);
                    Editable = DynamicEditable;
                    ToolTip = 'Specifies the total prepayment amount for the rental document.';


                    trigger OnValidate()
                    begin
                        ActiveTab := ActiveTab::Prepayment;
                        UpdatePrepmtAmount();
                    end;
                }
                field(PrepmtVATAmount; PrepmtVATAmount)
                {
                    ApplicationArea = Prepayments;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = Format(PrepmtVATAmountText);
                    Caption = 'Prepayment Amount Invoiced';
                    Editable = false;
                    ToolTip = 'Specifies how much has been invoiced as prepayment.';
                }
                field(PrepmtTotalAmount2; PrepmtTotalAmount2)
                {
                    ApplicationArea = Prepayments;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = GetCaptionClass(Text006Lbl, true);
                    Editable = false;
                    ToolTip = 'Specifies the total prepayment amount for the rental document.';


                    trigger OnValidate()
                    begin
                        OnBeforeValidatePrepmtTotalAmount2(Rec, PrepmtTotalAmount, PrepmtTotalAmount2);
                        UpdatePrepmtAmount();
                    end;
                }
                field(TotalRentalLine1PrepmtAmtInv; TotalRentalLine[1]."Prepmt. Amt. Inv.")
                {
                    ApplicationArea = Prepayments;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = GetCaptionClass(Text007Lbl, false);
                    Editable = false;
                    ToolTip = 'Specifies the prepayment amount invoice for the rental document.';
                }
                field(PrepmtInvPct; PrepmtInvPct)
                {
                    ApplicationArea = Prepayments;
                    Caption = 'Invoiced % of Prepayment Amt.';
                    ExtendedDatatype = Ratio;
                    ToolTip = 'Specifies Invoiced Percentage of Prepayment Amt.';
                }
                field(TotalRentalLine1PrepmtAmtDeducted; TotalRentalLine[1]."Prepmt Amt Deducted")
                {
                    ApplicationArea = Prepayments;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = GetCaptionClass(Text008Lbl, false);
                    Editable = false;
                    ToolTip = 'Specifies the prepayment amount deducted for the rental document.';

                }
                field(PrepmtDeductedPct; PrepmtDeductedPct)
                {
                    ApplicationArea = Prepayments;
                    Caption = 'Deducted % of Prepayment Amt. to Deduct';
                    ExtendedDatatype = Ratio;
                    ToolTip = 'Specifies the deducted percentage of the prepayment amount to deduct.';
                }
                field(TotalRentalLine1PrepmtAmttoDeduct; TotalRentalLine[1]."Prepmt Amt to Deduct")
                {
                    ApplicationArea = Prepayments;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = GetCaptionClass(Text009Lbl, false);
                    Editable = false;
                    ToolTip = 'Specifies the prepayment amount to deducted for the rental document.';
                }
                field("TempVATAmountLine4.COUNT"; TempVATAmountLine4.Count)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'No. of Tax Lines';
                    DrillDown = true;
                    ToolTip = 'Specifies the number of lines on the rental contract that have VAT amounts.';

                    trigger OnDrillDown()
                    begin
                        VATLinesDrillDown(TempVATAmountLine4, true);
                    end;
                }
            }
            group(Customer)
            {
                Caption = 'Customer';
                field("Cust.""Balance (LCY)"""; Cust."Balance (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Balance (LCY)';
                    Editable = false;
                    ToolTip = 'Specifies the balance on the customer''s account.';
                }
                field("Cust.""Credit Limit (LCY)"""; Cust."Credit Limit (LCY)")
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

    trigger OnAfterGetCurrRecord()
    begin
        DynamicEditable := CurrPage.Editable;
    end;

    trigger OnAfterGetRecord()
    begin
        RefreshOnAfterGetRecord();
    end;

    trigger OnOpenPage()
    begin
        RentalSetup.GetSetup();
        AllowInvDisc := not (RentalSetup."Calc. Inv. Discount" and CustInvDiscRecExists(Rec."Invoice Disc. Code"));
        AllowVATDifference :=
          RentalSetup."Allow VAT Difference" and
          not (Rec."Document Type" in [Rec."Document Type"::Quote]);
        OnOpenPageOnBeforeSetEditable(AllowInvDisc, AllowVATDifference, Rec);
        VATLinesFormIsEditable := AllowVATDifference or AllowInvDisc;
        CurrPage.Editable := VATLinesFormIsEditable;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        RentalLine: Record "TWE Rental Line";
        ReleaseRentalDocument: Codeunit "TWE Release Rental Document";
    begin
        GetVATSpecification(PrevTab);
        ReleaseRentalDocument.CalcAndUpdateVATOnLines(Rec, RentalLine);
        exit(true);
    end;

    var
        TotalRentalLine: array[3] of Record "TWE Rental Line";
        TotalRentalLineLCY: array[3] of Record "TWE Rental Line";
        Cust: Record Customer;
        TempVATAmountLine1: Record "VAT Amount Line" temporary;
        TempVATAmountLine2: Record "VAT Amount Line" temporary;
        TempVATAmountLine3: Record "VAT Amount Line" temporary;
        TempVATAmountLine4: Record "VAT Amount Line" temporary;
        RentalSetup: Record "TWE Rental Setup";
        RentalPost: Codeunit "TWE Rental-Post";
        VATLinesForm: Page "VAT Amount Lines";
        TotalAmount1: array[3] of Decimal;
        TotalAmount2: array[3] of Decimal;
        VATAmount: array[3] of Decimal;
        PrepmtTotalAmount: Decimal;
        PrepmtVATAmount: Decimal;
        PrepmtTotalAmount2: Decimal;
        VATAmountText: array[3] of Text[30];
        PrepmtVATAmountText: Text[30];
        ProfitLCY: array[3] of Decimal;
        ProfitPct: array[3] of Decimal;
        AdjProfitLCY: array[3] of Decimal;
        AdjProfitPct: array[3] of Decimal;
        TotalAdjCostLCY: array[3] of Decimal;
        CreditLimitLCYExpendedPct: Decimal;
        PrepmtInvPct: Decimal;
        PrepmtDeductedPct: Decimal;
        i: Integer;
        PrevNo: Code[20];
        ActiveTab: Option General,Invoicing,Shipping,Prepayment;
        PrevTab: Option General,Invoicing,Shipping,Prepayment;
        VATLinesFormIsEditable: Boolean;
        AllowInvDisc: Boolean;
        AllowVATDifference: Boolean;
        DynamicEditable: Boolean;
        Text006Lbl: Label 'Prepmt. Amount';
        Text007Lbl: Label 'Prepmt. Amt. Invoiced';
        Text008Lbl: Label 'Prepmt. Amt. Deducted';
        Text009Lbl: Label 'Prepmt. Amt. to Deduct';
        UpdateInvDiscountQst: Label 'One or more lines have been invoiced. The discount distributed to invoiced lines will not be taken into account.\\Do you want to update the invoice discount?';
        Text000Lbl: Label 'Rental %1 Statistics', Comment = '%1 = Document Type';
        Text001Lbl: Label 'Total';
        Text002Lbl: Label 'Amount';
        Text003Lbl: Label '%1 must not be 0.', Comment = '%1 = FieldCaption "Inv. Disc. Base Amount"';
        Text004Lbl: Label '%1 must not be greater than %2.', Comment = '%1 = FieldCaption "Inv. Discount Amount",%2 = FieldCaption "Inv. Disc. Base Amount"';
        Text005Lbl: Label 'You cannot change the invoice discount because a customer invoice discount with the code %1 exists.', Comment = '%1 Invoice Disc. Code';

    local procedure RefreshOnAfterGetRecord()
    var
        RentalLine: Record "TWE Rental Line";
        TempRentalLine: Record "TWE Rental Line" temporary;
        RentalPostPrepayments: Codeunit "TWE Rental-Post Prepayments";
        OptionValueOutOfRange: Integer;
    begin
        CurrPage.Caption(StrSubstNo(Text000Lbl, Rec."Document Type"));

        if PrevNo = Rec."No." then
            exit;
        PrevNo := Rec."No.";
        Rec.FilterGroup(2);
        Rec.SetRange("No.", PrevNo);
        Rec.FilterGroup(0);

        Clear(RentalLine);
        Clear(TotalRentalLine);
        Clear(TotalRentalLineLCY);
        Clear(TotalAmount1);
        Clear(TotalAmount2);
        Clear(VATAmount);
        Clear(ProfitLCY);
        Clear(ProfitPct);
        Clear(AdjProfitLCY);
        Clear(AdjProfitPct);
        Clear(TotalAdjCostLCY);
        Clear(TempVATAmountLine1);
        Clear(TempVATAmountLine2);
        Clear(TempVATAmountLine3);
        Clear(TempVATAmountLine4);
        Clear(PrepmtTotalAmount);
        Clear(PrepmtVATAmount);
        Clear(PrepmtTotalAmount2);
        Clear(VATAmountText);
        Clear(PrepmtVATAmountText);
        Clear(CreditLimitLCYExpendedPct);
        Clear(PrepmtInvPct);
        Clear(PrepmtDeductedPct);

        // 1 to 3, so that it does calculations for all 3 tabs, General,Invoicing,Shipping
        for i := 1 to 3 do begin
            TempRentalLine.DeleteAll();
            Clear(TempRentalLine);
            Clear(RentalSetup);
            RentalPost.GetRentalLines(Rec, TempRentalLine, i - 1, false);
            OnRefreshOnAfterGetRecordOnAfterGetRentalLines(Rec, TempRentalLine);
            Clear(RentalPost);
            case i of
                1:
                    RentalLine.CalcVATAmountLines(0, Rec, TempRentalLine, TempVATAmountLine1);
                2:
                    RentalLine.CalcVATAmountLines(0, Rec, TempRentalLine, TempVATAmountLine2);
                3:
                    RentalLine.CalcVATAmountLines(0, Rec, TempRentalLine, TempVATAmountLine3);
            end;

            RentalPost.SumSalesLinesTemp(
              Rec, TempRentalLine, i - 1, TotalRentalLine[i], TotalRentalLineLCY[i],
              VATAmount[i], VATAmountText[i], ProfitLCY[i], ProfitPct[i], TotalAdjCostLCY[i], false);

            if i = 3 then
                TotalAdjCostLCY[i] := TotalRentalLineLCY[i]."Unit Cost (LCY)";

            AdjProfitLCY[i] := TotalRentalLineLCY[i].Amount - TotalAdjCostLCY[i];
            if TotalRentalLineLCY[i].Amount <> 0 then
                AdjProfitPct[i] := Round(AdjProfitLCY[i] / TotalRentalLineLCY[i].Amount * 100, 0.1);

            if Rec."Prices Including VAT" then begin
                TotalAmount2[i] := TotalRentalLine[i].Amount;
                TotalAmount1[i] := TotalAmount2[i] + VATAmount[i];
                TotalRentalLine[i]."Line Amount" := TotalAmount1[i] + TotalRentalLine[i]."Inv. Discount Amount";
            end else begin
                TotalAmount1[i] := TotalRentalLine[i].Amount;
                TotalAmount2[i] := TotalRentalLine[i]."Amount Including VAT";
            end;
        end;

        OnAfterCalculateTotalAmounts();

        TempRentalLine.DeleteAll();
        Clear(TempRentalLine);
        RentalPostPrepayments.GetRentalLines(Rec, 0, TempRentalLine);
        RentalPostPrepayments.SumPrepmt(
          Rec, TempRentalLine, TempVATAmountLine4, PrepmtTotalAmount, PrepmtVATAmount, PrepmtVATAmountText);
        PrepmtInvPct :=
          Pct(TotalRentalLine[1]."Prepmt. Amt. Inv.", PrepmtTotalAmount);
        PrepmtDeductedPct :=
          Pct(TotalRentalLine[1]."Prepmt Amt Deducted", TotalRentalLine[1]."Prepmt. Amt. Inv.");
        if Rec."Prices Including VAT" then begin
            PrepmtTotalAmount2 := PrepmtTotalAmount;
            PrepmtTotalAmount := PrepmtTotalAmount + PrepmtVATAmount;
        end else
            PrepmtTotalAmount2 := PrepmtTotalAmount + PrepmtVATAmount;

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

        TempVATAmountLine1.ModifyAll(Modified, false);
        TempVATAmountLine2.ModifyAll(Modified, false);
        TempVATAmountLine3.ModifyAll(Modified, false);
        TempVATAmountLine4.ModifyAll(Modified, false);

        OptionValueOutOfRange := -1;
        PrevTab := OptionValueOutOfRange;

        UpdateHeaderInfo(2, TempVATAmountLine2);
    end;

    local procedure UpdateHeaderInfo(IndexNo: Integer; var VATAmountLine: Record "VAT Amount Line")
    var
        CurrExchRate: Record "Currency Exchange Rate";
        UseDate: Date;
    begin
        TotalRentalLine[IndexNo]."Inv. Discount Amount" := VATAmountLine.GetTotalInvDiscAmount();
        TotalAmount1[IndexNo] :=
          TotalRentalLine[IndexNo]."Line Amount" - TotalRentalLine[IndexNo]."Inv. Discount Amount";
        VATAmount[IndexNo] := VATAmountLine.GetTotalVATAmount();
        if Rec."Prices Including VAT" then begin
            TotalAmount1[IndexNo] := VATAmountLine.GetTotalAmountInclVAT();
            TotalAmount2[IndexNo] := TotalAmount1[IndexNo] - VATAmount[IndexNo];
            TotalRentalLine[IndexNo]."Line Amount" :=
              TotalAmount1[IndexNo] + TotalRentalLine[IndexNo]."Inv. Discount Amount";
        end else
            TotalAmount2[IndexNo] := TotalAmount1[IndexNo] + VATAmount[IndexNo];

        if Rec."Prices Including VAT" then
            TotalRentalLineLCY[IndexNo].Amount := TotalAmount2[IndexNo]
        else
            TotalRentalLineLCY[IndexNo].Amount := TotalAmount1[IndexNo];
        if Rec."Currency Code" <> '' then
            if Rec."Posting Date" = 0D then
                UseDate := WorkDate()
            else
                UseDate := Rec."Posting Date";

        TotalRentalLineLCY[IndexNo].Amount :=
          CurrExchRate.ExchangeAmtFCYToLCY(
            UseDate, Rec."Currency Code", TotalRentalLineLCY[IndexNo].Amount, Rec."Currency Factor");

        ProfitLCY[IndexNo] := TotalRentalLineLCY[IndexNo].Amount - TotalRentalLineLCY[IndexNo]."Unit Cost (LCY)";
        if TotalRentalLineLCY[IndexNo].Amount = 0 then
            ProfitPct[IndexNo] := 0
        else
            ProfitPct[IndexNo] := Round(100 * ProfitLCY[IndexNo] / TotalRentalLineLCY[IndexNo].Amount, 0.01);

        AdjProfitLCY[IndexNo] := TotalRentalLineLCY[IndexNo].Amount - TotalAdjCostLCY[IndexNo];
        if TotalRentalLineLCY[IndexNo].Amount = 0 then
            AdjProfitPct[IndexNo] := 0
        else
            AdjProfitPct[IndexNo] := Round(100 * AdjProfitLCY[IndexNo] / TotalRentalLineLCY[IndexNo].Amount, 0.01);

        OnAfterUpdateHeaderInfo(TotalRentalLineLCY, IndexNo);
    end;

    local procedure GetVATSpecification(QtyType: Option General,Invoicing,Shipping)
    begin
        case QtyType of
            QtyType::General:
                begin
                    VATLinesForm.GetTempVATAmountLine(TempVATAmountLine1);
                    UpdateHeaderInfo(1, TempVATAmountLine1);
                end;
            QtyType::Invoicing:
                begin
                    VATLinesForm.GetTempVATAmountLine(TempVATAmountLine2);
                    UpdateHeaderInfo(2, TempVATAmountLine2);
                end;
            QtyType::Shipping:
                VATLinesForm.GetTempVATAmountLine(TempVATAmountLine3);
        end;
    end;

    local procedure UpdateTotalAmount(IndexNo: Integer)
    var
        SaveTotalAmount: Decimal;
    begin
        CheckAllowInvDisc();
        if Rec."Prices Including VAT" then begin
            SaveTotalAmount := TotalAmount1[IndexNo];
            UpdateInvDiscAmount(IndexNo);
            TotalAmount1[IndexNo] := SaveTotalAmount;
        end;

        TotalRentalLine[IndexNo]."Inv. Discount Amount" := TotalRentalLine[IndexNo]."Line Amount" - TotalAmount1[IndexNo];

        UpdateInvDiscAmount(IndexNo);
    end;

    local procedure UpdateInvDiscAmount(ModifiedIndexNo: Integer)
    var
        ConfirmManagement: Codeunit "Confirm Management";
        PartialInvoicing: Boolean;
        MaxIndexNo: Integer;
        IndexNo: array[2] of Integer;
        i: Integer;
        InvDiscBaseAmount: Decimal;
    begin
        CheckAllowInvDisc();
        if not (ModifiedIndexNo in [1, 2]) then
            exit;

        if Rec.InvoicedLineExists() then
            if not ConfirmManagement.GetResponseOrDefault(UpdateInvDiscountQst, true) then
                Error('');

        if ModifiedIndexNo = 1 then
            InvDiscBaseAmount := TempVATAmountLine1.GetTotalInvDiscBaseAmount(false, Rec."Currency Code")
        else
            InvDiscBaseAmount := TempVATAmountLine2.GetTotalInvDiscBaseAmount(false, Rec."Currency Code");

        if InvDiscBaseAmount = 0 then
            Error(Text003Lbl, TempVATAmountLine2.FieldCaption("Inv. Disc. Base Amount"));

        if TotalRentalLine[ModifiedIndexNo]."Inv. Discount Amount" / InvDiscBaseAmount > 1 then
            Error(
              Text004Lbl,
              TotalRentalLine[ModifiedIndexNo].FieldCaption("Inv. Discount Amount"),
              TempVATAmountLine2.FieldCaption("Inv. Disc. Base Amount"));

        PartialInvoicing := (TotalRentalLine[1]."Line Amount" <> TotalRentalLine[2]."Line Amount");

        IndexNo[1] := ModifiedIndexNo;
        IndexNo[2] := 3 - ModifiedIndexNo;
        if (ModifiedIndexNo = 2) and PartialInvoicing then
            MaxIndexNo := 1
        else
            MaxIndexNo := 2;

        if not PartialInvoicing then
            if ModifiedIndexNo = 1 then
                TotalRentalLine[2]."Inv. Discount Amount" := TotalRentalLine[1]."Inv. Discount Amount"
            else
                TotalRentalLine[1]."Inv. Discount Amount" := TotalRentalLine[2]."Inv. Discount Amount";

        for i := 1 to MaxIndexNo do
            with TotalRentalLine[IndexNo[i]] do begin
                if (i = 1) or not PartialInvoicing then
                    if IndexNo[i] = 1 then
                        TempVATAmountLine1.SetInvoiceDiscountAmount(
                          "Inv. Discount Amount", "Currency Code", Rec."Prices Including VAT", Rec."VAT Base Discount %")
                    else
                        TempVATAmountLine2.SetInvoiceDiscountAmount(
                          "Inv. Discount Amount", "Currency Code", Rec."Prices Including VAT", Rec."VAT Base Discount %");

                if (i = 2) and PartialInvoicing then
                    if IndexNo[i] = 1 then begin
                        InvDiscBaseAmount := TempVATAmountLine2.GetTotalInvDiscBaseAmount(false, "Currency Code");
                        if InvDiscBaseAmount = 0 then
                            TempVATAmountLine1.SetInvoiceDiscountPercent(
                              0, "Currency Code", Rec."Prices Including VAT", false, Rec."VAT Base Discount %")
                        else
                            TempVATAmountLine1.SetInvoiceDiscountPercent(
                              100 * TempVATAmountLine2.GetTotalInvDiscAmount() / InvDiscBaseAmount,
                              "Currency Code", Rec."Prices Including VAT", false, Rec."VAT Base Discount %");
                    end else begin
                        InvDiscBaseAmount := TempVATAmountLine1.GetTotalInvDiscBaseAmount(false, "Currency Code");
                        if InvDiscBaseAmount = 0 then
                            TempVATAmountLine2.SetInvoiceDiscountPercent(
                              0, "Currency Code", Rec."Prices Including VAT", false, Rec."VAT Base Discount %")
                        else
                            TempVATAmountLine2.SetInvoiceDiscountPercent(
                              100 * TempVATAmountLine1.GetTotalInvDiscAmount() / InvDiscBaseAmount,
                              "Currency Code", Rec."Prices Including VAT", false, Rec."VAT Base Discount %");
                    end;
            end;

        UpdateHeaderInfo(1, TempVATAmountLine1);
        UpdateHeaderInfo(2, TempVATAmountLine2);

        if ModifiedIndexNo = 1 then
            VATLinesForm.SetTempVATAmountLine(TempVATAmountLine1)
        else
            VATLinesForm.SetTempVATAmountLine(TempVATAmountLine2);

        Rec."Invoice Discount Calculation" := Rec."Invoice Discount Calculation"::Amount;
        Rec."Invoice Discount Value" := TotalRentalLine[1]."Inv. Discount Amount";
        Rec.Modify();

        UpdateVATOnRentalLines();
    end;

    local procedure UpdatePrepmtAmount()
    var
        TempRentalLine: Record "TWE Rental Line" temporary;
        SalesPostPrepmt: Codeunit "Sales-Post Prepayments";
    begin
        /* SalesPostPrepmt.UpdatePrepmtAmountOnSaleslines(Rec, PrepmtTotalAmount);
        SalesPostPrepmt.GetSalesLines(Rec, 0, TempRentalLine);
        SalesPostPrepmt.SumPrepmt(
          Rec, TempRentalLine, TempVATAmountLine4, PrepmtTotalAmount, PrepmtVATAmount, PrepmtVATAmountText); */
        PrepmtInvPct :=
          Pct(TotalRentalLine[1]."Prepmt. Amt. Inv.", PrepmtTotalAmount);
        PrepmtDeductedPct :=
          Pct(TotalRentalLine[1]."Prepmt Amt Deducted", TotalRentalLine[1]."Prepmt. Amt. Inv.");
        if Rec."Prices Including VAT" then begin
            PrepmtTotalAmount2 := PrepmtTotalAmount;
            PrepmtTotalAmount := PrepmtTotalAmount + PrepmtVATAmount;
        end else
            PrepmtTotalAmount2 := PrepmtTotalAmount + PrepmtVATAmount;
        Rec.Modify();
    end;

    local procedure GetCaptionClass(FieldCaption: Text[100]; ReverseCaption: Boolean): Text[80]
    begin
        if Rec."Prices Including VAT" xor ReverseCaption then
            exit(CopyStr('2,1,' + FieldCaption, 1, 80));
        exit(CopyStr('2,0,' + FieldCaption, 1, 80));
    end;

    local procedure UpdateVATOnRentalLines()
    var
        RentalLine: Record "TWE Rental Line";
    begin
        GetVATSpecification(ActiveTab);
        if (TempVATAmountLine1.GetAnyLineModified()) then
            RentalLine.UpdateVATOnLines(0, Rec, RentalLine, TempVATAmountLine1);
        if TempVATAmountLine2.GetAnyLineModified() then
            RentalLine.UpdateVATOnLines(1, Rec, RentalLine, TempVATAmountLine2);
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
    begin
        if not AllowInvDisc then
            Error(Text005Lbl, Rec."Invoice Disc. Code");

        OnAfterCheckAllowInvDisc(Rec);
    end;

    local procedure Pct(Numerator: Decimal; Denominator: Decimal): Decimal
    begin
        if Denominator = 0 then
            exit(0);
        exit(Round(Numerator / Denominator * 10000, 1));
    end;

    local procedure VATLinesDrillDown(var VATLinesToDrillDown: Record "VAT Amount Line"; ThisTabAllowsVATEditing: Boolean)
    begin
        Clear(VATLinesForm);
        VATLinesForm.SetTempVATAmountLine(VATLinesToDrillDown);
        VATLinesForm.InitGlobals(
          Rec."Currency Code", AllowVATDifference, AllowVATDifference and ThisTabAllowsVATEditing,
          Rec."Prices Including VAT", AllowInvDisc, Rec."VAT Base Discount %");
        VATLinesForm.RunModal();
        VATLinesForm.GetTempVATAmountLine(VATLinesToDrillDown);
    end;

    local procedure TotalAmount21OnAfterValidate()
    begin
        if Rec."Prices Including VAT" then
            TotalRentalLine[1]."Inv. Discount Amount" := TotalRentalLine[1]."Line Amount" - TotalRentalLine[1]."Amount Including VAT"
        else
            TotalRentalLine[1]."Inv. Discount Amount" := TotalRentalLine[1]."Line Amount" - TotalRentalLine[1].Amount;

        UpdateInvDiscAmount(1);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOpenPageOnBeforeSetEditable(var AllowInvDisc: Boolean; var AllowVATDifference: Boolean; RentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCalculateTotalAmounts()
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterUpdateHeaderInfo(var TotalRentalLineLCY: array[3] of Record "TWE Rental Line"; var IndexNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidatePrepmtTotalAmount2(RentalHeader: Record "TWE Rental Header"; var PrepmtTotalAmount: Decimal; var PrepmtTotalAmount2: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckAllowInvDisc(RentalHeader: Record "TWE Rental Header");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRefreshOnAfterGetRecordOnAfterGetRentalLines(RentalHeader: Record "TWE Rental Header"; var TempRentalLine: Record "TWE Rental Line" temporary)
    begin
    end;
}

