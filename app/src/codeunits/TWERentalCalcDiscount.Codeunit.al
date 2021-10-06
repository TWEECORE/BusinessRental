/// <summary>
/// Codeunit TWE Rental-Calc. Discount (ID 50015).
/// </summary>
codeunit 50015 "TWE Rental-Calc. Discount"
{
    TableNo = "TWE Rental Line";

    trigger OnRun()
    begin
        RentalLine.Copy(Rec);

        RentalHeader2.Get(Rec."Document Type", Rec."Document No.");
        UpdateHeader := true;
        CalculateInvoiceDiscount(RentalHeader2, RentalLine2);

        if Rec.Get(RentalLine."Document Type", RentalLine."Document No.", RentalLine."Line No.") then;
    end;

    var
        RentalHeader2: Record "TWE Rental Header";
        RentalLine: Record "TWE Rental Line";
        RentalLine2: Record "TWE Rental Line";
        CustInvDisc: Record "Cust. Invoice Disc.";
        CustPostingGr: Record "Customer Posting Group";
        Currency: Record Currency;
        InvDiscBase: Decimal;
        ChargeBase: Decimal;
        CurrencyDate: Date;
        UpdateHeader: Boolean;
        Text000Lbl: Label 'Service Charge';

    local procedure CalculateInvoiceDiscount(var RentalHeader: Record "TWE Rental Header"; var RentalLine2: Record "TWE Rental Line")
    var
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        RentalSetup: Record "TWE Rental Setup";
        TempServiceChargeLine: Record "TWE Rental Line" temporary;
        RentalCalcDiscountByType: Codeunit "TWE Rental-Calc Disc. By Type";
        DiscountNotificationMgt: Codeunit "Discount Notification Mgt.";
        IsHandled: Boolean;
    begin
        RentalSetup.Get();
        if UpdateHeader then
            RentalHeader.Find(); // To ensure we have the latest - otherwise update fails.

        IsHandled := false;
        OnBeforeCalcSalesDiscount(RentalHeader, IsHandled, RentalLine2, UpdateHeader);
        if IsHandled then
            exit;

        RentalLine.LockTable();
        RentalHeader.TestField("Customer Posting Group");
        CustPostingGr.Get(RentalHeader."Customer Posting Group");

        RentalLine2.Reset();
        RentalLine2.SetRange("Document Type", RentalLine."Document Type");
        RentalLine2.SetRange("Document No.", RentalLine."Document No.");
        RentalLine2.SetRange("System-Created Entry", true);
        RentalLine2.SetRange(Type, RentalLine2.Type::"G/L Account");
        RentalLine2.SetRange("No.", CustPostingGr."Service Charge Acc.");
        if RentalLine2.FindSet(true, false) then
            repeat
                RentalLine2."Unit Price" := 0;
                RentalLine2.Modify();
                TempServiceChargeLine := RentalLine2;
                TempServiceChargeLine.Insert();
            until RentalLine2.Next() = 0;

        RentalLine2.Reset();
        RentalLine2.SetRange("Document Type", RentalLine."Document Type");
        RentalLine2.SetRange("Document No.", RentalLine."Document No.");
        RentalLine2.SetFilter(Type, '<>0');
        if RentalLine2.FindFirst() then;
        RentalLine2.CalcVATAmountLines(0, RentalHeader, RentalLine2, TempVATAmountLine);
        InvDiscBase :=
          TempVATAmountLine.GetTotalInvDiscBaseAmount(
            RentalHeader."Prices Including VAT", RentalHeader."Currency Code");
        ChargeBase :=
          TempVATAmountLine.GetTotalLineAmount(
            RentalHeader."Prices Including VAT", RentalHeader."Currency Code");

        if UpdateHeader then
            RentalHeader.Modify();

        if RentalHeader."Posting Date" = 0D then
            CurrencyDate := WorkDate()
        else
            CurrencyDate := RentalHeader."Posting Date";

        CustInvDisc.GetRec(
          RentalHeader."Invoice Disc. Code", RentalHeader."Currency Code", CurrencyDate, ChargeBase);

        if CustInvDisc."Service Charge" <> 0 then begin
            OnCalculateInvoiceDiscountOnBeforeCurrencyInitialize(CustPostingGr);
            Currency.Initialize(RentalHeader."Currency Code");
            if not UpdateHeader then
                RentalLine2.SetRentalHeader(RentalHeader);
            if not TempServiceChargeLine.IsEmpty then begin
                TempServiceChargeLine.FindLast();
                RentalLine2.Get(RentalLine."Document Type", RentalLine."Document No.", TempServiceChargeLine."Line No.");
                SetSalesLineServiceCharge(RentalHeader, RentalLine2);
                RentalLine2.Modify();
            end else begin
                RentalLine2.Reset();
                RentalLine2.SetRange("Document Type", RentalLine."Document Type");
                RentalLine2.SetRange("Document No.", RentalLine."Document No.");
                RentalLine2.FindLast();
                RentalLine2.Init();
                if not UpdateHeader then
                    RentalLine2.SetRentalHeader(RentalHeader);
                RentalLine2."Line No." := RentalLine2."Line No." + 10000;
                RentalLine2."System-Created Entry" := true;
                RentalLine2.Type := RentalLine2.Type::"G/L Account";
                RentalLine2.Validate("No.", CustPostingGr.GetServiceChargeAccount());
                RentalLine2.Description := Text000Lbl;
                RentalLine2.Validate(Quantity, 1);

                OnAfterValidateSalesLine2Quantity(RentalHeader, RentalLine2, CustInvDisc);

                /* if RentalLine2."Document Type" in
                   [RentalLine2."Document Type"::"Credit Memo"]
                then
                    RentalLine2.Validate("Return Qty. to Receive", RentalLine2.Quantity)
                else */
                RentalLine2.Validate("Qty. to Ship", RentalLine2.Quantity);
                SetSalesLineServiceCharge(RentalHeader, RentalLine2);
                RentalLine2.Insert();
            end;
            RentalLine2.CalcVATAmountLines(0, RentalHeader, RentalLine2, TempVATAmountLine);
        end else
            if TempServiceChargeLine.FindSet(false, false) then
                repeat
                    if (TempServiceChargeLine."Shipment No." = '') and (TempServiceChargeLine."Qty. Shipped Not Invoiced" = 0) then begin
                        RentalLine2 := TempServiceChargeLine;
                        RentalLine2.Delete(true);
                    end;
                until TempServiceChargeLine.Next() = 0;

        IsHandled := false;
        OnCalculateInvoiceDiscountOnBeforeCustInvDiscRecExists(RentalHeader, RentalLine2, UpdateHeader, InvDiscBase, ChargeBase, TempVATAmountLine, IsHandled);
        If IsHandled then
            exit;

        if CustInvDiscRecExists(RentalHeader."Invoice Disc. Code") then begin
            OnAfterCustInvDiscRecExists(RentalHeader);
            if InvDiscBase <> ChargeBase then
                CustInvDisc.GetRec(
                  RentalHeader."Invoice Disc. Code", RentalHeader."Currency Code", CurrencyDate, InvDiscBase);

            DiscountNotificationMgt.NotifyAboutMissingSetup(
              RentalSetup.RecordId, RentalHeader."Gen. Bus. Posting Group",
              RentalSetup."Discount Posting", RentalSetup."Discount Posting"::"Line Discounts");

            UpdateRentalHeaderInvoiceDiscount(RentalHeader, TempVATAmountLine, RentalSetup."Calc. Inv. Disc. per VAT ID");

            RentalLine2.SetRentalHeader(RentalHeader);
            RentalLine2.UpdateVATOnLines(0, RentalHeader, RentalLine2, TempVATAmountLine);
            UpdatePrepmtLineAmount(RentalHeader);
        end;

        RentalCalcDiscountByType.ResetRecalculateInvoiceDisc(RentalHeader);
        OnAfterCalcSalesDiscount(RentalHeader, TempVATAmountLine, RentalLine2);
    end;

    local procedure UpdateRentalHeaderInvoiceDiscount(var RentalHeader: Record "TWE Rental Header"; var TempVATAmountLine: Record "VAT Amount Line" temporary; CalcInvDiscPerVATID: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateRentalHeaderInvoiceDiscount(CustInvDisc, RentalHeader, TempVATAmountLine, UpdateHeader, IsHandled);
        if IsHandled then
            exit;

        RentalHeader."Invoice Discount Calculation" := RentalHeader."Invoice Discount Calculation"::"%";
        RentalHeader."Invoice Discount Value" := CustInvDisc."Discount %";
        if UpdateHeader then
            RentalHeader.Modify();

        TempVATAmountLine.SetInvoiceDiscountPercent(
          CustInvDisc."Discount %", RentalHeader."Currency Code",
          RentalHeader."Prices Including VAT", CalcInvDiscPerVATID,
          RentalHeader."VAT Base Discount %");
    end;

    local procedure SetSalesLineServiceCharge(RentalHeader: Record "TWE Rental Header"; var RentalLine: Record "TWE Rental Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetRentalLineServiceCharge(RentalHeader, RentalLine, CustInvDisc, IsHandled);
        if IsHandled then
            exit;

        if RentalHeader."Prices Including VAT" then
            RentalLine.Validate(
                "Unit Price",
                Round((1 + RentalLine."VAT %" / 100) * CustInvDisc."Service Charge", Currency."Unit-Amount Rounding Precision"))
        else
            RentalLine.Validate("Unit Price", CustInvDisc."Service Charge");
    end;

    local procedure CustInvDiscRecExists(InvDiscCode: Code[20]): Boolean
    var
        CustInvDiscLocal: Record "Cust. Invoice Disc.";
    begin
        CustInvDiscLocal.SetRange(Code, InvDiscCode);
        exit(not CustInvDiscLocal.IsEmpty());
    end;

    /// <summary>
    /// CalculateWithRentalHeader.
    /// </summary>
    /// <param name="TempRentalHeader">VAR Record "TWE Rental Header".</param>
    /// <param name="TempRentalLine">VAR Record "TWE Rental Line".</param>
    procedure CalculateWithRentalHeader(var TempRentalHeader: Record "TWE Rental Header"; var TempRentalLine: Record "TWE Rental Line")
    var
        FilterRentalLine: Record "TWE Rental Line";
    begin
        FilterRentalLine.Copy(TempRentalLine);
        RentalLine := TempRentalLine;

        UpdateHeader := false;
        CalculateInvoiceDiscount(TempRentalHeader, TempRentalLine);

        TempRentalLine.Copy(FilterRentalLine);
    end;

    /// <summary>
    /// CalculateInvoiceDiscountOnLine.
    /// </summary>
    /// <param name="RentalLineToUpdate">VAR Record "TWE Rental Line".</param>
    procedure CalculateInvoiceDiscountOnLine(var RentalLineToUpdate: Record "TWE Rental Line")
    begin
        RentalLine.Copy(RentalLineToUpdate);

        RentalHeader2.Get(RentalLine."Document Type", RentalLine."Document No.");
        UpdateHeader := false;
        CalculateInvoiceDiscount(RentalHeader2, RentalLine);

        if RentalLineToUpdate.Get(RentalLineToUpdate."Document Type", RentalLineToUpdate."Document No.", RentalLineToUpdate."Line No.") then;
    end;

    /// <summary>
    /// CalculateIncDiscForHeader.
    /// </summary>
    /// <param name="TempRentalHeader">VAR Record "TWE Rental Header".</param>
    procedure CalculateIncDiscForHeader(var TempRentalHeader: Record "TWE Rental Header")
    var
        RentalSetup: Record "TWE Rental Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalculateIncDiscForHeader(TempRentalHeader, IsHandled);
        if IsHandled then
            exit;

        RentalSetup.Get();
        if not RentalSetup."Calc. Inv. Discount" then
            exit;

        RentalLine."Document Type" := TempRentalHeader."Document Type";
        RentalLine."Document No." := TempRentalHeader."No.";
        UpdateHeader := true;
        CalculateInvoiceDiscount(TempRentalHeader, RentalLine2);
    end;

    /// <summary>
    /// UpdatePrepmtLineAmount.
    /// </summary>
    /// <param name="RentalHeader">Record "TWE Rental Header".</param>
    procedure UpdatePrepmtLineAmount(RentalHeader: Record "TWE Rental Header")
    var
        RentalLineLocal: Record "TWE Rental Line";
    begin
        if (RentalHeader."Invoice Discount Calculation" = RentalHeader."Invoice Discount Calculation"::"%") and
           (RentalHeader."Prepayment %" > 0) and (RentalHeader."Invoice Discount Value" > 0) and
           (RentalHeader."Invoice Discount Value" + RentalHeader."Prepayment %" >= 100)
        then
            RentalLineLocal.SetRange("Document Type", RentalHeader."Document Type");
        RentalLineLocal.SetRange("Document No.", RentalHeader."No.");
        if RentalLineLocal.FindSet(true) then
            repeat
                if not RentalLineLocal.ZeroAmountLine(0) and (RentalLineLocal."Prepayment %" = RentalHeader."Prepayment %") then begin
                    RentalLineLocal."Prepmt. Line Amount" := RentalLineLocal.Amount;
                    RentalLineLocal.Modify();
                end;
            until RentalLineLocal.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcSalesDiscount(var RentalHeader: Record "TWE Rental Header"; var IsHandled: Boolean; var RentalLine: Record "TWE Rental Line"; var UpdateHeader: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcSalesDiscount(var RentalHeader: Record "TWE Rental Header"; var TempVATAmountLine: Record "VAT Amount Line" temporary; var RentalLine2: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCustInvDiscRecExists(var RentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateSalesLine2Quantity(RentalHeader: Record "TWE Rental Header"; var RentalLine: Record "TWE Rental Line"; CustInvoiceDisc: Record "Cust. Invoice Disc.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateIncDiscForHeader(var TempRentalHeader: Record "TWE Rental Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetRentalLineServiceCharge(RentalHeader: Record "TWE Rental Header"; var RentalLine: Record "TWE Rental Line"; CustInvoiceDisc: Record "Cust. Invoice Disc."; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateRentalHeaderInvoiceDiscount(var CustInvoiceDisc: Record "Cust. Invoice Disc."; var RentalHeader: Record "TWE Rental Header"; var TempVATAmountLine: Record "VAT Amount Line" temporary; var UpdateHeader: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateInvoiceDiscountOnBeforeCurrencyInitialize(var CustomerPostingGroup: Record "Customer Posting Group")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateInvoiceDiscountOnBeforeCustInvDiscRecExists(var RentalHeader: Record "TWE Rental Header"; var RentalLine2: Record "TWE Rental Line"; var UpdateHeader: Boolean; var InvDiscBase: Decimal; var ChargeBase: Decimal; var TempVATAmountLine: Record "VAT Amount Line" temporary; var IsHandled: Boolean)
    begin
    end;
}

