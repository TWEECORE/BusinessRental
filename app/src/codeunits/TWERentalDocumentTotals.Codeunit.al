/// <summary>
/// Codeunit TWE Rental Document Totals (ID 50020).
/// </summary>
codeunit 50020 "TWE Rental Document Totals"
{

    trigger OnRun()
    begin
    end;

    var
        RentalSetup: Record "TWE Rental Setup";
        PreviousTotalRentalHeader: Record "TWE Rental Header";
        ForceTotalsRecalculation: Boolean;
        PreviousTotalRentalVATDifference: Decimal;
        RentalLinesExist: Boolean;
        TotalsUpToDate: Boolean;
        NeedRefreshRentalLine: Boolean;
        TotalVATLbl: Label 'Total VAT';
        TotalAmountInclVatLbl: Label 'Total Incl. VAT';
        TotalAmountExclVATLbl: Label 'Total Excl. VAT';
        InvoiceDiscountAmountLbl: Label 'Invoice Discount Amount';
        RefreshMsgTxt: Label 'Totals or discounts may not be up-to-date. Choose the link to update.';
        TotalLineAmountLbl: Label 'Subtotal';

    /// <summary>
    /// CalculateSalesPageTotals.
    /// </summary>
    /// <param name="TotalRentalLine">VAR Record "TWE Rental Line".</param>
    /// <param name="VATAmount">VAR Decimal.</param>
    /// <param name="RentalLine">VAR Record "TWE Rental Line".</param>
    procedure CalculateRentalPageTotals(var TotalRentalLine: Record "TWE Rental Line"; var VATAmount: Decimal; var RentalLine: Record "TWE Rental Line")
    var
        TotalRentalLine2: Record "TWE Rental Line";
    begin
        TotalRentalLine2 := TotalRentalLine;
        TotalRentalLine2.SetRange("Document Type", RentalLine."Document Type");
        TotalRentalLine2.SetRange("Document No.", RentalLine."Document No.");
        OnAfterRentalLineSetFilters(TotalRentalLine2, RentalLine);
        TotalRentalLine2.CalcSums("Line Amount", Amount, "Amount Including VAT", "Inv. Discount Amount");
        VATAmount := TotalRentalLine2."Amount Including VAT" - TotalRentalLine2.Amount;
        TotalRentalLine := TotalRentalLine2;
    end;

    /// <summary>
    /// CalculateRentalTotals.
    /// </summary>
    /// <param name="TotalRentalLine">VAR Record "TWE Rental Line".</param>
    /// <param name="VATAmount">VAR Decimal.</param>
    /// <param name="RentalLine">VAR Record "TWE Rental Line".</param>
    procedure CalculateRentalTotals(var TotalRentalLine: Record "TWE Rental Line"; var VATAmount: Decimal; var RentalLine: Record "TWE Rental Line")
    begin
        CalculateRentalPageTotals(TotalRentalLine, VATAmount, RentalLine);
    end;

    /// <summary>
    /// CalculateRentalSubPageTotals.
    /// </summary>
    /// <param name="TotalRentalHeader">VAR Record "TWE Rental Header".</param>
    /// <param name="TotalRentalLine">VAR Record "TWE Rental Line".</param>
    /// <param name="VATAmount">VAR Decimal.</param>
    /// <param name="InvoiceDiscountAmount">VAR Decimal.</param>
    /// <param name="InvoiceDiscountPct">VAR Decimal.</param>
    procedure CalculateRentalSubPageTotals(var TotalRentalHeader: Record "TWE Rental Header"; var TotalRentalLine: Record "TWE Rental Line"; var VATAmount: Decimal; var InvoiceDiscountAmount: Decimal; var InvoiceDiscountPct: Decimal)
    var
        RentalLine2: Record "TWE Rental Line";
        TotalRentalLine2: Record "TWE Rental Line";
        RentalCalcDiscount: Codeunit "TWE Rental-Calc. Discount";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalculateRentalSubPageTotals(TotalRentalHeader, TotalRentalLine, VATAmount, InvoiceDiscountAmount, InvoiceDiscountPct, IsHandled);
        if IsHandled then
            exit;

        if TotalsUpToDate then
            exit;
        TotalsUpToDate := true;
        NeedRefreshRentalLine := false;

        RentalSetup.Get();
        TotalRentalLine2.Copy(TotalRentalLine);
        TotalRentalLine2.Reset();
        TotalRentalLine2.SetRange("Document Type", TotalRentalHeader."Document Type");
        TotalRentalLine2.SetRange("Document No.", TotalRentalHeader."No.");
        OnCalculateRentalSubPageTotalsOnAfterSetFilters(TotalRentalLine2, TotalRentalHeader);

        if RentalSetup."Calc. Inv. Discount" and (TotalRentalHeader."No." <> '') and
           (TotalRentalHeader."Customer Posting Group" <> '')
        then begin
            TotalRentalHeader.CalcFields("Recalculate Invoice Disc.");
            if TotalRentalHeader."Recalculate Invoice Disc." then
                if TotalRentalLine2.FindFirst() then begin
                    RentalCalcDiscount.CalculateInvoiceDiscountOnLine(TotalRentalLine2);
                    NeedRefreshRentalLine := true;
                end;
        end;

        TotalRentalLine2.CalcSums(Amount, "Amount Including VAT", "Line Amount", "Inv. Discount Amount");
        VATAmount := TotalRentalLine2."Amount Including VAT" - TotalRentalLine2.Amount;
        InvoiceDiscountAmount := TotalRentalLine2."Inv. Discount Amount";

        if (InvoiceDiscountAmount = 0) or (TotalRentalLine2."Line Amount" = 0) then
            InvoiceDiscountPct := 0
        else
            case TotalRentalHeader."Invoice Discount Calculation" of
                TotalRentalHeader."Invoice Discount Calculation"::"%":
                    InvoiceDiscountPct := TotalRentalHeader."Invoice Discount Value";
                TotalRentalHeader."Invoice Discount Calculation"::None,
                TotalRentalHeader."Invoice Discount Calculation"::Amount:
                    begin
                        RentalLine2.CopyFilters(TotalRentalLine2);
                        RentalLine2.SetRange("Allow Invoice Disc.", true);
                        RentalLine2.CalcSums("Line Amount");
                        InvoiceDiscountPct := Round(InvoiceDiscountAmount / RentalLine2."Line Amount" * 100, 0.00001);
                    end;
            end;

        OnAfterCalculateRentalSubPageTotals(
          TotalRentalHeader, TotalRentalLine, VATAmount, InvoiceDiscountAmount, InvoiceDiscountPct, TotalRentalLine2);

        TotalRentalLine := TotalRentalLine2;
    end;

    /// <summary>
    /// CalculatePostedRentalInvoiceTotals.
    /// </summary>
    /// <param name="RentalInvoiceHeader">VAR Record "TWE Rental Invoice Header".</param>
    /// <param name="VATAmount">VAR Decimal.</param>
    /// <param name="RentalInvoiceLine">Record "TWE Rental Invoice Line".</param>
    procedure CalculatePostedRentalInvoiceTotals(var RentalInvoiceHeader: Record "TWE Rental Invoice Header"; var VATAmount: Decimal; RentalInvoiceLine: Record "TWE Rental Invoice Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalculatePostedRentalInvoiceTotals(RentalInvoiceHeader, VATAmount, RentalInvoiceLine, IsHandled);
        If IsHandled then
            exit;

        if RentalInvoiceHeader.Get(RentalInvoiceLine."Document No.") then begin
            RentalInvoiceHeader.CalcFields(Amount, "Amount Including VAT", "Invoice Discount Amount");
            VATAmount := RentalInvoiceHeader."Amount Including VAT" - RentalInvoiceHeader.Amount;
        end;

        OnAfterCalculatePostedRentalInvoiceTotals(RentalInvoiceHeader, RentalInvoiceLine, VATAmount);
    end;

    /// <summary>
    /// CalculatePostedRentalCreditMemoTotals.
    /// </summary>
    /// <param name="RentalCrMemoHeader">VAR Record "TWE Rental Cr.Memo Header".</param>
    /// <param name="VATAmount">VAR Decimal.</param>
    /// <param name="RentalCrMemoLine">Record "TWE Rental Cr.Memo Line".</param>
    procedure CalculatePostedRentalCreditMemoTotals(var RentalCrMemoHeader: Record "TWE Rental Cr.Memo Header"; var VATAmount: Decimal; RentalCrMemoLine: Record "TWE Rental Cr.Memo Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalculatePostedRentalCreditMemoTotals(RentalCrMemoHeader, VATAmount, RentalCrMemoLine, IsHandled);
        If IsHandled then
            exit;

        if RentalCrMemoHeader.Get(RentalCrMemoLine."Document No.") then begin
            RentalCrMemoHeader.CalcFields(Amount, "Amount Including VAT", "Invoice Discount Amount");
            VATAmount := RentalCrMemoHeader."Amount Including VAT" - RentalCrMemoHeader.Amount;
        end;

        OnAfterCalculatePostedRentalCreditMemoTotals(RentalCrMemoHeader, RentalCrMemoLine, VATAmount);
    end;

    /// <summary>
    /// CalcTotalRentalAmountOnlyDiscountAllowed.
    /// </summary>
    /// <param name="RentalLine">Record "TWE Rental Line".</param>
    /// <returns>Return value of type Decimal.</returns>
    procedure CalcTotalRentalAmountOnlyDiscountAllowed(RentalLine: Record "TWE Rental Line"): Decimal
    var
        TotalRentalLine: Record "TWE Rental Line";
    begin
        TotalRentalLine.SetRange("Document Type", RentalLine."Document Type");
        TotalRentalLine.SetRange("Document No.", RentalLine."Document No.");
        TotalRentalLine.SetRange("Allow Invoice Disc.", true);
        TotalRentalLine.CalcSums("Line Amount");
        exit(TotalRentalLine."Line Amount");
    end;

    local procedure CalcTotalRentalVATDifference(RentalHeader: Record "TWE Rental Header"): Decimal
    var
        RentalLine: Record "TWE Rental Line";
    begin
        RentalLine.SetRange("Document Type", RentalHeader."Document Type");
        RentalLine.SetRange("Document No.", RentalHeader."No.");
        RentalLine.CalcSums("VAT Difference");
        exit(RentalLine."VAT Difference");
    end;

    local procedure CalculateTotalRentalLineAndVATAmount(RentalHeader: Record "TWE Rental Header"; var VATAmount: Decimal; var TempTotalRentalLine: Record "TWE Rental Line" temporary)
    var
        TempRentalLine: Record "TWE Rental Line" temporary;
        TempTotalRentalLineLCY: Record "TWE Rental Line" temporary;
        RentalPost: Codeunit "TWE Rental-Post";
        VATAmountText: Text[30];
        ProfitLCY: Decimal;
        ProfitPct: Decimal;
        TotalAdjCostLCY: Decimal;
    begin
        RentalPost.GetRentalLines(RentalHeader, TempRentalLine, 0);
        Clear(RentalPost);
        RentalPost.SumSalesLinesTemp(
          RentalHeader, TempRentalLine, 0, TempTotalRentalLine, TempTotalRentalLineLCY,
          VATAmount, VATAmountText, ProfitLCY, ProfitPct, TotalAdjCostLCY);
    end;

    /// <summary>
    /// RefreshRentalLine.
    /// </summary>
    /// <param name="RentalLine">VAR Record "TWE Rental Line".</param>
    procedure RefreshRentalLine(var RentalLine: Record "TWE Rental Line")
    begin
        if NeedRefreshRentalLine and (RentalLine."Line No." <> 0) then
            if RentalLine.Find() then;
    end;

    /// <summary>
    /// RentalUpdateTotalsControls.
    /// </summary>
    /// <param name="CurrentRentalLine">Record "TWE Rental Line".</param>
    /// <param name="TotalRentalHeader">VAR Record "TWE Rental Header".</param>
    /// <param name="TotalRentalLine">VAR Record "TWE Rental Line".</param>
    /// <param name="RefreshMessageEnabled">VAR Boolean.</param>
    /// <param name="ControlStyle">VAR Text.</param>
    /// <param name="RefreshMessageText">VAR Text.</param>
    /// <param name="InvDiscAmountEditable">VAR Boolean.</param>
    /// <param name="CurrPageEditable">Boolean.</param>
    /// <param name="VATAmount">VAR Decimal.</param>
    procedure RentalUpdateTotalsControls(CurrentRentalLine: Record "TWE Rental Line"; var TotalRentalHeader: Record "TWE Rental Header"; var TotalRentalLine: Record "TWE Rental Line"; var RefreshMessageEnabled: Boolean; var ControlStyle: Text; var RefreshMessageText: Text; var InvDiscAmountEditable: Boolean; CurrPageEditable: Boolean; var VATAmount: Decimal)
    var
        RentalLine: Record "TWE Rental Line";
        RentalCalcDiscountByType: Codeunit "TWE Rental-Calc Disc. By Type";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnRentalUpdateTotalsControlsOnBeforeCheckDocumentNo(CurrentRentalLine, TotalRentalHeader, TotalRentalLine, RefreshMessageEnabled, ControlStyle, RefreshMessageText, InvDiscAmountEditable, CurrPageEditable, VATAmount, IsHandled);
        If IsHandled then
            exit;

        if CurrentRentalLine."Document No." = '' then
            exit;

        TotalRentalLine.Get(CurrentRentalLine."Document Type", CurrentRentalLine."Document No.");
        IsHandled := false;
        OnBeforeRentalUpdateTotalsControls(TotalRentalHeader, InvDiscAmountEditable, IsHandled);
        RefreshMessageEnabled := RentalCalcDiscountByType.ShouldRedistributeInvoiceDiscountAmount(TotalRentalHeader);

        if not RefreshMessageEnabled then
            RefreshMessageEnabled := not RentalUpdateTotals(TotalRentalHeader, CurrentRentalLine, TotalRentalLine, VATAmount);

        RentalLine.SetRange("Document Type", CurrentRentalLine."Document Type");
        RentalLine.SetRange("Document No.", CurrentRentalLine."Document No.");
        if not IsHandled then
            InvDiscAmountEditable := not RentalLine.IsEmpty() and
              RentalCalcDiscountByType.InvoiceDiscIsAllowed(TotalRentalHeader."Invoice Disc. Code") and
              (not RefreshMessageEnabled) and CurrPageEditable;

        TotalControlsUpdateStyle(RefreshMessageEnabled, ControlStyle, RefreshMessageText);

        if RefreshMessageEnabled then
            ClearRentalAmounts(TotalRentalLine, VATAmount);
    end;

    local procedure RentalUpdateTotals(var RentalHeader: Record "TWE Rental Header"; CurrentRentalLine: Record "TWE Rental Line"; var TotalRentalLine: Record "TWE Rental Line"; var VATAmount: Decimal): Boolean
    begin
        RentalHeader.CalcFields(Amount, "Amount Including VAT", "Invoice Discount Amount");

        if RentalHeader."No." <> PreviousTotalRentalHeader."No." then
            ForceTotalsRecalculation := true;

        if (not ForceTotalsRecalculation) and
           (PreviousTotalRentalHeader.Amount = RentalHeader.Amount) and
           (PreviousTotalRentalHeader."Amount Including VAT" = RentalHeader."Amount Including VAT") and
           (PreviousTotalRentalVATDifference = CalcTotalRentalVATDifference(RentalHeader))
        then
            exit(true);

        ForceTotalsRecalculation := false;

        if not RentalCheckNumberOfLinesLimit(RentalHeader) then
            exit(false);

        RentalCalculateTotalsWithInvoiceRounding(CurrentRentalLine, VATAmount, TotalRentalLine);
        exit(true);
    end;

    local procedure RentalCalculateTotalsWithInvoiceRounding(var TempCurrentRentalLine: Record "TWE Rental Line" temporary; var VATAmount: Decimal; var TempTotalRentalLine: Record "TWE Rental Line" temporary)
    var
        RentalHeader: Record "TWE Rental Header";
    begin
        Clear(TempTotalRentalLine);
        if RentalHeader.Get(TempCurrentRentalLine."Document Type", TempCurrentRentalLine."Document No.") then begin
            CalculateTotalRentalLineAndVATAmount(RentalHeader, VATAmount, TempTotalRentalLine);

            if PreviousTotalRentalHeader."No." <> TempCurrentRentalLine."Document No." then begin
                PreviousTotalRentalHeader.Get(TempCurrentRentalLine."Document Type", TempCurrentRentalLine."Document No.");
                ForceTotalsRecalculation := true;
            end;
            PreviousTotalRentalHeader.CalcFields(Amount, "Amount Including VAT");
            PreviousTotalRentalVATDifference := CalcTotalRentalVATDifference(PreviousTotalRentalHeader);
        end;
    end;

    /// <summary>
    /// RentalRedistributeInvoiceDiscountAmounts.
    /// </summary>
    /// <param name="TempRentalLine">Temporary VAR Record "TWE Rental Line".</param>
    /// <param name="VATAmount">VAR Decimal.</param>
    /// <param name="TempTotalRentalLine">Temporary VAR Record "TWE Rental Line".</param>
    procedure RentalRedistributeInvoiceDiscountAmounts(var TempRentalLine: Record "TWE Rental Line" temporary; var VATAmount: Decimal; var TempTotalRentalLine: Record "TWE Rental Line" temporary)
    var
        RentalHeader: Record "TWE Rental Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRentalRedistributeInvoiceDiscountAmounts(TempRentalLine, VATAmount, TempTotalRentalLine, IsHandled);
        if IsHandled then
            exit;

        if RentalHeader.Get(TempRentalLine."Document Type", TempRentalLine."Document No.") then begin
            RentalHeader.CalcFields("Recalculate Invoice Disc.");
            if RentalHeader."Recalculate Invoice Disc." then
                CODEUNIT.Run(CODEUNIT::"Sales - Calc Discount By Type", TempRentalLine);

            RentalCalculateTotalsWithInvoiceRounding(TempRentalLine, VATAmount, TempTotalRentalLine);
        end;
        OnAfterRentalRedistributeInvoiceDiscountAmounts(TempRentalLine, TempTotalRentalLine, VATAmount);
    end;

    /// <summary>
    /// RentalRedistributeInvoiceDiscountAmountsOnDocument.
    /// </summary>
    /// <param name="RentalHeader">Record "TWE Rental Header".</param>
    procedure RentalRedistributeInvoiceDiscountAmountsOnDocument(RentalHeader: Record "TWE Rental Header")
    var
        TempRentalLine: Record "TWE Rental Line" temporary;
        TempRentalLineTotal: Record "TWE Rental Line" temporary;
        VATAmount: Decimal;
    begin
        TempRentalLine."Document Type" := RentalHeader."Document Type";
        TempRentalLine."Document No." := RentalHeader."No.";
        RentalRedistributeInvoiceDiscountAmounts(TempRentalLine, VATAmount, TempRentalLineTotal);
    end;

    /// <summary>
    /// RentalDocTotalsNotUpToDate.
    /// </summary>
    procedure RentalDocTotalsNotUpToDate()
    begin
        TotalsUpToDate := false;
    end;

    /// <summary>
    /// RentalCheckIfDocumentChanged.
    /// </summary>
    /// <param name="RentalLine">VAR Record "TWE Rental Line".</param>
    /// <param name="xRentalLine">VAR Record "TWE Rental Line".</param>
    procedure RentalCheckIfDocumentChanged(var RentalLine: Record "TWE Rental Line"; var xRentalLine: Record "TWE Rental Line")
    begin
        if (RentalLine."Document No." <> xRentalLine."Document No.") or
           (RentalLine."Rented-to Customer No." <> xRentalLine."Rented-to Customer No.") or
           (RentalLine."Bill-to Customer No." <> xRentalLine."Bill-to Customer No.") or
           (RentalLine.Amount <> xRentalLine.Amount) or
           (RentalLine."Amount Including VAT" <> xRentalLine."Amount Including VAT") or
           (RentalLine."Inv. Discount Amount" <> xRentalLine."Inv. Discount Amount") or
           (RentalLine."Currency Code" <> xRentalLine."Currency Code")
        then
            TotalsUpToDate := false;

        OnAfterRentalCheckIfDocumentChanged(RentalLine, xRentalLine, TotalsUpToDate);
    end;

    /// <summary>
    /// RentalCheckAndClearTotals.
    /// </summary>
    /// <param name="RentalLine">VAR Record "TWE Rental Line".</param>
    /// <param name="xRentalLine">VAR Record "TWE Rental Line".</param>
    /// <param name="TotalRentalLine">VAR Record "TWE Rental Line".</param>
    /// <param name="VATAmount">VAR Decimal.</param>
    /// <param name="InvoiceDiscountAmount">VAR Decimal.</param>
    /// <param name="InvoiceDiscountPct">VAR Decimal.</param>
    procedure RentalCheckAndClearTotals(var RentalLine: Record "TWE Rental Line"; var xRentalLine: Record "TWE Rental Line"; var TotalRentalLine: Record "TWE Rental Line"; var VATAmount: Decimal; var InvoiceDiscountAmount: Decimal; var InvoiceDiscountPct: Decimal)
    begin
        RentalLine.FilterGroup(4);
        if RentalLine.GetFilter("Document No.") <> '' then
            if RentalLine.GetRangeMin("Document No.") <> xRentalLine."Document No." then begin
                TotalsUpToDate := false;
                Clear(TotalRentalLine);
                VATAmount := 0;
                InvoiceDiscountAmount := 0;
                InvoiceDiscountPct := 0;
            end;
        RentalLine.FilterGroup(0);
    end;

    /// <summary>
    /// RentalDeltaUpdateTotals.
    /// </summary>
    /// <param name="RentalLine">VAR Record "TWE Rental Line".</param>
    /// <param name="xRentalLine">VAR Record "TWE Rental Line".</param>
    /// <param name="TotalRentalLine">VAR Record "TWE Rental Line".</param>
    /// <param name="VATAmount">VAR Decimal.</param>
    /// <param name="InvoiceDiscountAmount">VAR Decimal.</param>
    /// <param name="InvoiceDiscountPct">VAR Decimal.</param>
    procedure RentalDeltaUpdateTotals(var RentalLine: Record "TWE Rental Line"; var xRentalLine: Record "TWE Rental Line"; var TotalRentalLine: Record "TWE Rental Line"; var VATAmount: Decimal; var InvoiceDiscountAmount: Decimal; var InvoiceDiscountPct: Decimal)
    var
        InvDiscountBaseAmount: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRentalDeltaUpdateTotals(RentalLine, xRentalLine, TotalRentalLine, VATAmount, InvoiceDiscountAmount, InvoiceDiscountPct, IsHandled);
        if IsHandled then
            exit;

        TotalRentalLine."Line Amount" += RentalLine."Line Amount" - xRentalLine."Line Amount";
        TotalRentalLine."Amount Including VAT" += RentalLine."Amount Including VAT" - xRentalLine."Amount Including VAT";
        TotalRentalLine.Amount += RentalLine.Amount - xRentalLine.Amount;
        VATAmount := TotalRentalLine."Amount Including VAT" - TotalRentalLine.Amount;
        if RentalLine."Inv. Discount Amount" <> xRentalLine."Inv. Discount Amount" then begin
            if (InvoiceDiscountPct > -0.01) and (InvoiceDiscountPct < 0.01) then // To avoid decimal overflow later
                InvDiscountBaseAmount := 0
            else
                InvDiscountBaseAmount := InvoiceDiscountAmount / InvoiceDiscountPct * 100;
            InvoiceDiscountAmount += RentalLine."Inv. Discount Amount" - xRentalLine."Inv. Discount Amount";
            if (InvoiceDiscountAmount = 0) or (InvDiscountBaseAmount = 0) then
                InvoiceDiscountPct := 0
            else
                InvoiceDiscountPct := Round(100 * InvoiceDiscountAmount / InvDiscountBaseAmount, 0.00001);
        end;

        OnAfterRentalDeltaUpdateTotals(RentalLine, xRentalLine, TotalRentalLine, VATAmount, InvoiceDiscountAmount, InvoiceDiscountPct);
    end;

    local procedure ClearRentalAmounts(var TotalRentalLine: Record "TWE Rental Line"; var VATAmount: Decimal)
    begin
        TotalRentalLine.Amount := 0;
        TotalRentalLine."Amount Including VAT" := 0;
        VATAmount := 0;
        Clear(PreviousTotalRentalHeader);
    end;

    local procedure TotalControlsUpdateStyle(RefreshMessageEnabled: Boolean; var ControlStyle: Text; var RefreshMessageText: Text)
    begin
        if RefreshMessageEnabled then begin
            ControlStyle := 'Subordinate';
            RefreshMessageText := RefreshMsgTxt;
        end else begin
            ControlStyle := 'Strong';
            RefreshMessageText := '';
        end;
    end;

    /// <summary>
    /// GetTotalVATCaption.
    /// </summary>
    /// <param name="CurrencyCode">Code[10].</param>
    /// <returns>Return value of type Text.</returns>
    procedure GetTotalVATCaption(CurrencyCode: Code[10]): Text
    begin
        exit(GetCaptionClassWithCurrencyCode(TotalVATLbl, CurrencyCode));
    end;

    /// <summary>
    /// GetTotalInclVATCaption.
    /// </summary>
    /// <param name="CurrencyCode">Code[10].</param>
    /// <returns>Return value of type Text.</returns>
    procedure GetTotalInclVATCaption(CurrencyCode: Code[10]): Text
    begin
        exit(GetCaptionClassWithCurrencyCode(TotalAmountInclVatLbl, CurrencyCode));
    end;

    /// <summary>
    /// GetTotalExclVATCaption.
    /// </summary>
    /// <param name="CurrencyCode">Code[10].</param>
    /// <returns>Return value of type Text.</returns>
    procedure GetTotalExclVATCaption(CurrencyCode: Code[10]): Text
    begin
        exit(GetCaptionClassWithCurrencyCode(TotalAmountExclVATLbl, CurrencyCode));
    end;

    local procedure GetCaptionClassWithCurrencyCode(CaptionWithoutCurrencyCode: Text; CurrencyCode: Code[10]): Text
    begin
        exit('3,' + GetCaptionWithCurrencyCode(CaptionWithoutCurrencyCode, CurrencyCode));
    end;

    local procedure GetCaptionWithCurrencyCode(CaptionWithoutCurrencyCode: Text; CurrencyCode: Code[10]): Text
    var
        GLSetup: Record "General Ledger Setup";
        Placeholder001Lbl: Label ' (%1)', Comment = '%1 = Currency Code';
    begin
        if CurrencyCode = '' then begin
            GLSetup.Get();
            CurrencyCode := GLSetup.GetCurrencyCode(CurrencyCode);
        end;

        if CurrencyCode <> '' then
            exit(CaptionWithoutCurrencyCode + StrSubstNo(Placeholder001Lbl, CurrencyCode));

        exit(CaptionWithoutCurrencyCode);
    end;

    local procedure GetCaptionWithVATInfo(CaptionWithoutVATInfo: Text; IncludesVAT: Boolean): Text
    begin
        if IncludesVAT then
            exit('2,1,' + CaptionWithoutVATInfo);

        exit('2,0,' + CaptionWithoutVATInfo);
    end;

    /// <summary>
    /// GetTotalRentalHeaderAndCurrency.
    /// </summary>
    /// <param name="RentalLine">VAR Record "TWE Rental Line".</param>
    /// <param name="TotalRentalHeader">VAR Record "TWE Rental Header".</param>
    /// <param name="Currency">VAR Record Currency.</param>
    procedure GetTotalRentalHeaderAndCurrency(var RentalLine: Record "TWE Rental Line"; var TotalRentalHeader: Record "TWE Rental Header"; var Currency: Record Currency)
    begin
        if not RentalLinesExist then
            RentalLinesExist := not RentalLine.IsEmpty;
        if not RentalLinesExist or
           (TotalRentalHeader."Document Type" <> RentalLine."Document Type") or (TotalRentalHeader."No." <> RentalLine."Document No.") or
           (TotalRentalHeader."Rented-to Customer No." <> RentalLine."Rented-to Customer No.") or
           (TotalRentalHeader."Currency Code" <> RentalLine."Currency Code")
        then begin
            Clear(TotalRentalHeader);
            if RentalLine."Document No." <> '' then
                if TotalRentalHeader.Get(RentalLine."Document Type", RentalLine."Document No.") then;
        end;
        if Currency.Code <> TotalRentalHeader."Currency Code" then begin
            Clear(Currency);
            Currency.Initialize(TotalRentalHeader."Currency Code");
        end;
    end;

    /// <summary>
    /// GetInvoiceDiscAmountWithVATCaption.
    /// </summary>
    /// <param name="IncludesVAT">Boolean.</param>
    /// <returns>Return value of type Text.</returns>
    procedure GetInvoiceDiscAmountWithVATCaption(IncludesVAT: Boolean): Text
    begin
        exit(GetCaptionWithVATInfo(InvoiceDiscountAmountLbl, IncludesVAT));
    end;

    /// <summary>
    /// GetInvoiceDiscAmountWithVATAndCurrencyCaption.
    /// </summary>
    /// <param name="InvDiscAmountCaptionClassWithVAT">Text.</param>
    /// <param name="CurrencyCode">Code[10].</param>
    /// <returns>Return value of type Text.</returns>
    procedure GetInvoiceDiscAmountWithVATAndCurrencyCaption(InvDiscAmountCaptionClassWithVAT: Text; CurrencyCode: Code[10]): Text
    begin
        exit(GetCaptionWithCurrencyCode(InvDiscAmountCaptionClassWithVAT, CurrencyCode));
    end;

    /// <summary>
    /// GetTotalLineAmountWithVATAndCurrencyCaption.
    /// </summary>
    /// <param name="CurrencyCode">Code[10].</param>
    /// <param name="IncludesVAT">Boolean.</param>
    /// <returns>Return value of type Text.</returns>
    procedure GetTotalLineAmountWithVATAndCurrencyCaption(CurrencyCode: Code[10]; IncludesVAT: Boolean): Text
    begin
        exit(GetCaptionWithCurrencyCode(CaptionClassTranslate(GetCaptionWithVATInfo(TotalLineAmountLbl, IncludesVAT)), CurrencyCode));
    end;

    /// <summary>
    /// RentalCheckNumberOfLinesLimit.
    /// </summary>
    /// <param name="RentalHeader">Record "TWE Rental Header".</param>
    /// <returns>Return value of type Boolean.</returns>
    procedure RentalCheckNumberOfLinesLimit(RentalHeader: Record "TWE Rental Header"): Boolean
    var
        RentalLine: Record "TWE Rental Line";
    begin
        RentalLine.SetRange("Document No.", RentalHeader."No.");
        RentalLine.SetRange("Document Type", RentalHeader."Document Type");
        RentalLine.SetFilter(Type, '<>%1', RentalLine.Type::" ");
        RentalLine.SetFilter("No.", '<>%1', '');

        if RentalHeader."Document Type" = RentalHeader."Document Type"::Contract then
            exit(RentalLine.Count <= 10);

        exit(RentalLine.Count <= 100);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalculatePostedRentalInvoiceTotals(var RentalInvoiceHeader: Record "TWE Rental Invoice Header"; RentalInvoiceLine: Record "TWE Rental Invoice Line"; var VATAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalculatePostedRentalCreditMemoTotals(var RentalCrMemoHeader: Record "TWE Rental Cr.Memo Header"; RentalCrMemoLine: Record "TWE Rental Cr.Memo Line"; var VATAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalculateRentalSubPageTotals(var TotalRentalHeader: Record "TWE Rental Header"; var TotalRentalLine: Record "TWE Rental Line"; var VATAmount: Decimal; var InvoiceDiscountAmount: Decimal; var InvoiceDiscountPct: Decimal; var TotalRentalLine2: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRentalCheckIfDocumentChanged(RentalLine: Record "TWE Rental Line"; xRentalLine: Record "TWE Rental Line"; var TotalsUpToDate: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRentalLineSetFilters(var TotalRentalLine: Record "TWE Rental Line"; RentalLine: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRentalRedistributeInvoiceDiscountAmounts(var TempRentalLine: Record "TWE Rental Line" temporary; var TempTotalRentalLine: Record "TWE Rental Line" temporary; var VATAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRentalDeltaUpdateTotals(var RentalLine: Record "TWE Rental Line"; var xRentalLine: Record "TWE Rental Line"; var TotalRentalLine: Record "TWE Rental Line"; var VATAmount: Decimal; var InvoiceDiscountAmount: Decimal; var InvoiceDiscountPct: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRentalDeltaUpdateTotals(var RentalLine: Record "TWE Rental Line"; var xRentalLine: Record "TWE Rental Line"; var TotalRentalLine: Record "TWE Rental Line"; var VATAmount: Decimal; var InvoiceDiscountAmount: Decimal; var InvoiceDiscountPct: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculatePostedRentalCreditMemoTotals(var RentalCrMemoHeader: Record "TWE Rental Cr.Memo Header"; var VATAmount: Decimal; RentalCrMemoLine: Record "TWE Rental Cr.Memo Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculatePostedRentalInvoiceTotals(var RentalInvoiceHeader: Record "TWE Rental Invoice Header"; var VATAmount: Decimal; RentalInvoiceLine: Record "TWE Rental Invoice Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateRentalSubPageTotals(var TotalRentalHeader: Record "TWE Rental Header"; var TotalRentalLine: Record "TWE Rental Line"; var VATAmount: Decimal; var InvoiceDiscountAmount: Decimal; var InvoiceDiscountPct: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRentalRedistributeInvoiceDiscountAmounts(var TempRentalLine: Record "TWE Rental Line" temporary; var VATAmount: Decimal; var TempTotalRentalLine: Record "TWE Rental Line" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRentalUpdateTotalsControls(var RentalHeader: Record "TWE Rental Header"; var InvDiscAmountEditable: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateRentalSubPageTotalsOnAfterSetFilters(var RentalLine: Record "TWE Rental Line"; RentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRentalUpdateTotalsControlsOnBeforeCheckDocumentNo(CurrentRentalLine: Record "TWE Rental Line"; var TotalRentalHeader: Record "TWE Rental Header"; var TotalsRentalLine: Record "TWE Rental Line"; var RefreshMessageEnabled: Boolean; var ControlStyle: Text; var RefreshMessageText: Text; var InvDiscAmountEditable: Boolean; CurrPageEditable: Boolean; var VATAmount: Decimal; var IsHandled: Boolean)
    begin
    end;
}

