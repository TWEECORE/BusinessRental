/// <summary>
/// Codeunit TWE Rental - Calc Discount By Type (ID 50014).
/// </summary>
codeunit 50014 "TWE Rental-Calc Disc. By Type"
{
    TableNo = "TWE Rental Line";

    trigger OnRun()
    var
        RentalLine: Record "TWE Rental Line";
        RentalHeader: Record "TWE Rental Header";
    begin
        RentalLine.Copy(Rec);

        if RentalHeader.Get(Rec."Document Type", Rec."Document No.") then begin
            ApplyDefaultInvoiceDiscount(RentalHeader."Invoice Discount Value", RentalHeader);
            // on new order might be no line
            if Rec.Get(RentalLine."Document Type", RentalLine."Document No.", RentalLine."Line No.") then;
        end;
    end;

    var
        InvDiscBaseAmountIsZeroErr: Label 'There is no amount that you can apply an invoice discount to.';
        CalcInvoiceDiscountOnRentalLine: Boolean;

    /// <summary>
    /// ApplyDefaultInvoiceDiscount.
    /// </summary>
    /// <param name="InvoiceDiscountAmount">Decimal.</param>
    /// <param name="RentalHeader">VAR Record "TWE Rental Header".</param>
    procedure ApplyDefaultInvoiceDiscount(InvoiceDiscountAmount: Decimal; var RentalHeader: Record "TWE Rental Header")
    var
        IsHandled: Boolean;
    begin
        if not ShouldRedistributeInvoiceDiscountAmount(RentalHeader) then
            exit;

        IsHandled := false;
        OnBeforeApplyDefaultInvoiceDiscount(RentalHeader, IsHandled, InvoiceDiscountAmount);
        if not IsHandled then
            if RentalHeader."Invoice Discount Calculation" = RentalHeader."Invoice Discount Calculation"::Amount then
                ApplyInvDiscBasedOnAmt(InvoiceDiscountAmount, RentalHeader)
            else
                ApplyInvDiscBasedOnPct(RentalHeader);

        ResetRecalculateInvoiceDisc(RentalHeader);
    end;

    /// <summary>
    /// ApplyInvDiscBasedOnAmt.
    /// </summary>
    /// <param name="InvoiceDiscountAmount">Decimal.</param>
    /// <param name="RentalHeader">VAR Record "TWE Rental Header".</param>
    procedure ApplyInvDiscBasedOnAmt(InvoiceDiscountAmount: Decimal; var RentalHeader: Record "TWE Rental Header")
    var
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        RentalLine: Record "TWE Rental Line";
        RentalSetup: Record "TWE Rental Setup";
        DiscountNotificationMgt: Codeunit "Discount Notification Mgt.";
        InvDiscBaseAmount: Decimal;
    begin
        RentalSetup.Get();
        DiscountNotificationMgt.NotifyAboutMissingSetup(
           RentalSetup.RecordId, RentalLine."Gen. Bus. Posting Group",
           RentalSetup."Discount Posting", RentalSetup."Discount Posting"::"Line Discounts");

        RentalLine.SetRange("Document No.", RentalHeader."No.");
        RentalLine.SetRange("Document Type", RentalHeader."Document Type");

        RentalLine.CalcVATAmountLines(0, RentalHeader, RentalLine, TempVATAmountLine);

        InvDiscBaseAmount := TempVATAmountLine.GetTotalInvDiscBaseAmount(false, RentalHeader."Currency Code");

        if (InvDiscBaseAmount = 0) and (InvoiceDiscountAmount > 0) then
            Error(InvDiscBaseAmountIsZeroErr);

        TempVATAmountLine.SetInvoiceDiscountAmount(InvoiceDiscountAmount, RentalHeader."Currency Code",
          RentalHeader."Prices Including VAT", RentalHeader."VAT Base Discount %");

        RentalLine.UpdateVATOnLines(0, RentalHeader, RentalLine, TempVATAmountLine);

        RentalHeader."Invoice Discount Calculation" := RentalHeader."Invoice Discount Calculation"::Amount;
        RentalHeader."Invoice Discount Value" := InvoiceDiscountAmount;

        ResetRecalculateInvoiceDisc(RentalHeader);

        RentalHeader.Modify();
    end;

    local procedure ApplyInvDiscBasedOnPct(var RentalHeader: Record "TWE Rental Header")
    var
        RentalLine: Record "TWE Rental Line";
        RentalCalcDiscount: Codeunit "TWE Rental-Calc. Discount";
    begin

        RentalLine.SetRange("Document No.", RentalHeader."No.");
        RentalLine.SetRange("Document Type", RentalHeader."Document Type");
        if RentalLine.FindFirst() then begin
            if CalcInvoiceDiscountOnRentalLine then
                RentalCalcDiscount.CalculateInvoiceDiscountOnLine(RentalLine)
            else
                CODEUNIT.Run(CODEUNIT::"TWE Rental-Calc. Discount", RentalLine);

            RentalHeader.Get(RentalLine."Document Type", RentalLine."No.");
        end;
    end;

    /// <summary>
    /// GetCustInvoiceDiscountPct.
    /// </summary>
    /// <param name="RentalLine">Record "TWE Rental Line".</param>
    /// <returns>Return value of type Decimal.</returns>
    procedure GetCustInvoiceDiscountPct(RentalLine: Record "TWE Rental Line"): Decimal
    var
        RentalHeader: Record "TWE Rental Header";
        InvoiceDiscountValue: Decimal;
        AmountIncludingVATDiscountAllowed: Decimal;
        AmountDiscountAllowed: Decimal;
    begin
        if not RentalHeader.Get(RentalLine."Document Type", RentalLine."Document No.") then
            exit(0);

        RentalHeader.CalcFields("Invoice Discount Amount");
        if RentalHeader."Invoice Discount Amount" = 0 then
            exit(0);

        case RentalHeader."Invoice Discount Calculation" of
            RentalHeader."Invoice Discount Calculation"::"%":
                begin
                    // Only if CustInvDisc table is empty header is not updated
                    if not CustInvDiscRecExists(RentalHeader."Invoice Disc. Code") then
                        exit(0);

                    exit(RentalHeader."Invoice Discount Value");
                end;
            RentalHeader."Invoice Discount Calculation"::None,
            RentalHeader."Invoice Discount Calculation"::Amount:
                begin
                    InvoiceDiscountValue := RentalHeader."Invoice Discount Amount";

                    CalcAmountWithDiscountAllowed(RentalHeader, AmountIncludingVATDiscountAllowed, AmountDiscountAllowed);

                    if AmountDiscountAllowed + InvoiceDiscountValue = 0 then
                        exit(0);

                    if RentalHeader."Prices Including VAT" then
                        exit(Round(InvoiceDiscountValue / (AmountIncludingVATDiscountAllowed + InvoiceDiscountValue) * 100, 0.01));

                    exit(Round(InvoiceDiscountValue / AmountDiscountAllowed * 100, 0.01));
                end;
        end;
        exit(0);
    end;

    /// <summary>
    /// ShouldRedistributeInvoiceDiscountAmount.
    /// </summary>
    /// <param name="RentalHeader">VAR Record "TWE Rental Header".</param>
    /// <returns>Return value of type Boolean.</returns>
    procedure ShouldRedistributeInvoiceDiscountAmount(var RentalHeader: Record "TWE Rental Header"): Boolean
    var
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShouldRedistributeInvoiceDiscountAmount(RentalHeader, IsHandled);
        if IsHandled then
            exit(true);

        RentalHeader.CalcFields("Recalculate Invoice Disc.");
        if not RentalHeader."Recalculate Invoice Disc." then
            exit(false);

        case RentalHeader."Invoice Discount Calculation" of
            RentalHeader."Invoice Discount Calculation"::Amount:
                exit(RentalHeader."Invoice Discount Value" <> 0);
            RentalHeader."Invoice Discount Calculation"::"%":
                exit(true);
            RentalHeader."Invoice Discount Calculation"::None:
                begin
                    if ApplicationAreaMgmtFacade.IsFoundationEnabled() then
                        exit(true);

                    exit(not InvoiceDiscIsAllowed(RentalHeader."Invoice Disc. Code"));
                end;
            else
                exit(true);
        end;
    end;

    /// <summary>
    /// ResetRecalculateInvoiceDisc.
    /// </summary>
    /// <param name="RentalHeader">Record "TWE Rental Header".</param>
    procedure ResetRecalculateInvoiceDisc(RentalHeader: Record "TWE Rental Header")
    var
        RentalLine: Record "TWE Rental Line";

    begin
        RentalLine.SetRange("Document Type", RentalHeader."Document Type");
        RentalLine.SetRange("Document No.", RentalHeader."No.");
        RentalLine.SetRange("Recalculate Invoice Disc.", true);
        RentalLine.ModifyAll("Recalculate Invoice Disc.", false);

        OnAfterResetRecalculateInvoiceDisc(RentalHeader);
    end;

    local procedure CustInvDiscRecExists(InvDiscCode: Code[20]): Boolean
    var
        CustInvDisc: Record "Cust. Invoice Disc.";
    begin
        CustInvDisc.SetRange(Code, InvDiscCode);
        exit(not CustInvDisc.IsEmpty);
    end;

    /// <summary>
    /// InvoiceDiscIsAllowed.
    /// </summary>
    /// <param name="InvDiscCode">Code[20].</param>
    /// <returns>Return value of type Boolean.</returns>
    procedure InvoiceDiscIsAllowed(InvDiscCode: Code[20]): Boolean
    var
        RentalSetup: Record "TWE Rental Setup";
    begin
        RentalSetup.Get();
        if not RentalSetup."Calc. Inv. Discount" then
            exit(true);

        exit(not CustInvDiscRecExists(InvDiscCode));
    end;

    local procedure CalcAmountWithDiscountAllowed(RentalHeader: Record "TWE Rental Header"; var AmountIncludingVATDiscountAllowed: Decimal; var AmountDiscountAllowed: Decimal)
    var
        RentalLine: Record "TWE Rental Line";
    begin
        RentalLine.SetRange("Document Type", RentalHeader."Document Type");
        RentalLine.SetRange("Document No.", RentalHeader."No.");
        RentalLine.SetRange("Allow Invoice Disc.", true);
        RentalLine.CalcSums(Amount, "Amount Including VAT", "Inv. Discount Amount");
        AmountIncludingVATDiscountAllowed := RentalLine."Amount Including VAT";
        AmountDiscountAllowed := RentalLine.Amount + RentalLine."Inv. Discount Amount";
    end;

    /// <summary>
    /// CalcInvoiceDiscOnLine.
    /// </summary>
    /// <param name="CalcInvoiceDiscountOnLine">Boolean.</param>
    procedure CalcInvoiceDiscOnLine(CalcInvoiceDiscountOnLine: Boolean)
    begin
        CalcInvoiceDiscountOnRentalLine := CalcInvoiceDiscountOnLine;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterResetRecalculateInvoiceDisc(var RentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeApplyDefaultInvoiceDiscount(var RentalHeader: Record "TWE Rental Header"; var IsHandled: Boolean; InvoiceDiscountAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShouldRedistributeInvoiceDiscountAmount(var RentalHeader: Record "TWE Rental Header"; var IsHandled: Boolean)
    begin
    end;
}

