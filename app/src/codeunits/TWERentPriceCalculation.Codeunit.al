/// <summary>
/// Codeunit TWE Rent Price Calculation (ID 50066) implements Interface Price Calculation.
/// </summary>
codeunit 50066 "TWE Rent Price Calculation" implements "TWE Rent Price Calculation"
{
    trigger OnRun()
    var
        RentalPriceCalcSetup: Record "TWE Rental Price Calc. Setup";
    begin
        RentalPriceCalcSetup.SetRange(Implementation, RentalPriceCalcSetup.Implementation::Rent);
        RentalPriceCalcSetup.DeleteAll();
        AddSupportedSetup(RentalPriceCalcSetup);
        RentalPriceCalcSetup.ModifyAll(Default, true);
    end;

    var
        CurrRentalPriceCalculationSetup: Record "TWE Rental Price Calc. Setup";
        CurrLineWithPrice: Interface "TWE Rent Line With Price";
        TempTableErr: Label 'The table passed as a parameter must be temporary.';
        PickedWrongMinQtyErr: Label 'The quantity in the line is below the minimum quantity of the picked price list line.';

    /// <summary>
    /// GetLine.
    /// </summary>
    /// <param name="Line">VAR Variant.</param>
    procedure GetLine(var Line: Variant)
    begin
        CurrLineWithPrice.GetLine(Line);
    end;

    /// <summary>
    /// Init.
    /// </summary>
    /// <param name="NewLineWithPrice">Interface "Line With Price".</param>
    /// <param name="PriceCalculationSetup">Record "TWE Rental Price Calc. Setup".</param>
    procedure Init(NewLineWithPrice: Interface "TWE Rent Line With Price"; PriceCalculationSetup: Record "TWE Rental Price Calc. Setup")
    begin
        CurrLineWithPrice := NewLineWithPrice;
        CurrRentalPriceCalculationSetup := PriceCalculationSetup;
    end;

    /// <summary>
    /// ApplyDiscount.
    /// </summary>
    procedure ApplyDiscount()
    var
        TempPriceListLine: Record "TWE Rental Price List Line" temporary;
        RentalPriceCalcBufferMgt: Codeunit "TWE Rental Price Calc Buf Mgt.";
        AmountType: Enum "Price Amount Type";
        FoundPrice: Boolean;
    begin
        if not HasAccess(CurrLineWithPrice.GetPriceType(), AmountType::Discount) then
            exit;
        if not CurrLineWithPrice.IsDiscountAllowed() then
            exit;
        CurrLineWithPrice.Verify();
        if not CurrLineWithPrice.CopyToBuffer(RentalPriceCalcBufferMgt) then
            exit;
        if FindLines(AmountType::Discount, TempPriceListLine, RentalPriceCalcBufferMgt, false) then
            FoundPrice := CalcBestAmount(AmountType::Discount, RentalPriceCalcBufferMgt, TempPriceListLine);
        if not FoundPrice then
            RentalPriceCalcBufferMgt.FillBestLine(AmountType::Discount, TempPriceListLine);
        CurrLineWithPrice.SetPrice(AmountType::Discount, TempPriceListLine);
    end;

    /// <summary>
    /// ApplyPrice.
    /// </summary>
    /// <param name="CalledByFieldNo">Integer.</param>
    procedure ApplyPrice(CalledByFieldNo: Integer)
    var
        TempPriceListLine: Record "TWE Rental Price List Line" temporary;
        PriceCalculationBufferMgt: Codeunit "TWE Rental Price Calc Buf Mgt.";
        AmountType: Enum "Price Amount Type";
        FoundLines: Boolean;
        FoundPrice: Boolean;
    begin
        if not HasAccess(CurrLineWithPrice.GetPriceType(), AmountType::Price) then
            exit;
        CurrLineWithPrice.Verify();
        if not CurrLineWithPrice.CopyToBuffer(PriceCalculationBufferMgt) then
            exit;
        FoundLines := FindLines(AmountType::Price, TempPriceListLine, PriceCalculationBufferMgt, false);
        if FoundLines then
            FoundPrice := CalcBestAmount(AmountType::Price, PriceCalculationBufferMgt, TempPriceListLine);
        if not FoundPrice then
            PriceCalculationBufferMgt.FillBestLine(AmountType::Price, TempPriceListLine);
        if CurrLineWithPrice.IsPriceUpdateNeeded(AmountType::Price, FoundLines, CalledByFieldNo) then
            CurrLineWithPrice.SetPrice(AmountType::Price, TempPriceListLine);
        CurrLineWithPrice.Update(AmountType::Price);
    end;

    /// <summary>
    /// CountDiscount.
    /// </summary>
    /// <param name="ShowAll">Boolean.</param>
    /// <returns>Return variable Result of type Integer.</returns>
    procedure CountDiscount(ShowAll: Boolean) Result: Integer;
    var
        TempPriceListLine: Record "TWE Rental Price List Line" temporary;
        AmountType: Enum "Price Amount Type";
    begin
        if FindPriceLines(AmountType::Discount, ShowAll, TempPriceListLine) then
            Result := TempPriceListLine.Count()
    end;

    /// <summary>
    /// CountPrice.
    /// </summary>
    /// <param name="ShowAll">Boolean.</param>
    /// <returns>Return variable Result of type Integer.</returns>
    procedure CountPrice(ShowAll: Boolean) Result: Integer;
    var
        TempPriceListLine: Record "TWE Rental Price List Line" temporary;
        AmountType: Enum "Price Amount Type";
    begin
        if FindPriceLines(AmountType::Price, ShowAll, TempPriceListLine) then
            Result := TempPriceListLine.Count()
    end;

    local procedure FindPriceLines(AmountType: Enum "Price Amount Type"; ShowAll: Boolean; var TempPriceListLine: Record "TWE Rental Price List Line" temporary): Boolean;
    var
        PriceCalculationBufferMgt: Codeunit "TWE Rental Price Calc Buf Mgt.";
    begin
        if CurrLineWithPrice.CopyToBuffer(PriceCalculationBufferMgt) then
            exit(FindLines(AmountType, TempPriceListLine, PriceCalculationBufferMgt, ShowAll));
    end;

    /// <summary>
    /// FindDiscount.
    /// </summary>
    /// <param name="TempPriceListLine">VAR Record "TWE Rental Price List Line".</param>
    /// <param name="ShowAll">Boolean.</param>
    /// <returns>Return variable Found of type Boolean.</returns>
    procedure FindDiscount(var TempPriceListLine: Record "TWE Rental Price List Line"; ShowAll: Boolean) Found: Boolean;
    var
        AmountType: Enum "Price Amount Type";
    begin
        Found := FindPriceLines(AmountType::Discount, ShowAll, TempPriceListLine);
    end;

    /// <summary>
    /// FindPrice.
    /// </summary>
    /// <param name="TempPriceListLine">VAR Record "TWE Rental Price List Line".</param>
    /// <param name="ShowAll">Boolean.</param>
    /// <returns>Return variable Found of type Boolean.</returns>
    procedure FindPrice(var TempPriceListLine: Record "TWE Rental Price List Line"; ShowAll: Boolean) Found: Boolean;
    var
        AmountType: Enum "Price Amount Type";
    begin
        Found := FindPriceLines(AmountType::Price, ShowAll, TempPriceListLine);
    end;

    local procedure HasAccess(PriceType: Enum "TWE Rental Price Type"; AmountType: Enum "Price Amount Type"): Boolean;
    var
        SalesDiscountAccess: Record "Sales Discount Access";
        SalesPriceAccess: Record "Sales Price Access";
    begin
        case PriceType of
            "TWE Rental Price Type"::Rental:
                case AmountType of
                    "Price Amount Type"::Discount:
                        exit(SalesDiscountAccess.ReadPermission());
                    "Price Amount Type"::Price:
                        exit(SalesPriceAccess.ReadPermission());
                end;
        end;
        exit(true);
    end;

    /// <summary>
    /// IsDiscountExists.
    /// </summary>
    /// <param name="ShowAll">Boolean.</param>
    /// <returns>Return variable Result of type Boolean.</returns>
    procedure IsDiscountExists(ShowAll: Boolean) Result: Boolean;
    var
        TempPriceListLine: Record "TWE Rental Price List Line" temporary;
    begin
        Result := FindDiscount(TempPriceListLine, ShowAll);
    end;

    /// <summary>
    /// IsPriceExists.
    /// </summary>
    /// <param name="ShowAll">Boolean.</param>
    /// <returns>Return variable Result of type Boolean.</returns>
    procedure IsPriceExists(ShowAll: Boolean) Result: Boolean;
    var
        TempPriceListLine: Record "TWE Rental Price List Line" temporary;
    begin
        Result := FindPrice(TempPriceListLine, ShowAll);
    end;

    /// <summary>
    /// PickDiscount.
    /// </summary>
    procedure PickDiscount()
    var
        AmountType: enum "Price Amount Type";
    begin
        Pick(AmountType::Discount, true);
    end;

    /// <summary>
    /// PickPrice.
    /// </summary>
    procedure PickPrice()
    var
        AmountType: enum "Price Amount Type";
    begin
        Pick(AmountType::Price, true);
    end;

    local procedure Pick(AmountType: enum "Price Amount Type"; ShowAll: Boolean)
    var
        TempPriceListLine: Record "TWE Rental Price List Line" temporary;
        PriceCalcBufferMgt: Codeunit "TWE Rental Price Calc Buf Mgt.";
        RentalPriceAssetList: Codeunit "TWE Rental Price Asset List";
        GetRentalPriceLine: Page "TWE Get Rental Price Line";
    begin
        if not HasAccess(CurrLineWithPrice.GetPriceType(), AmountType) then
            exit;
        CurrLineWithPrice.Verify();
        if not CurrLineWithPrice.CopyToBuffer(PriceCalcBufferMgt) then
            exit;
        if FindLines(AmountType, TempPriceListLine, PriceCalcBufferMgt, ShowAll) then begin
            PriceCalcBufferMgt.GetAssets(RentalPriceAssetList);
            GetRentalPriceLine.SetDataCaptionExpr(RentalPriceAssetList);
            GetRentalPriceLine.SetForLookup(CurrLineWithPrice, AmountType, TempPriceListLine);
            if GetRentalPriceLine.RunModal() = ACTION::LookupOK then begin
                GetRentalPriceLine.GetRecord(TempPriceListLine);
                if not PriceCalcBufferMgt.IsInMinQty(TempPriceListLine) then
                    Error(PickedWrongMinQtyErr);
                PriceCalcBufferMgt.VerifySelectedLine(TempPriceListLine);
                PriceCalcBufferMgt.ConvertAmount(AmountType, TempPriceListLine);
                CurrLineWithPrice.SetPrice(AmountType, TempPriceListLine);
                CurrLineWithPrice.Update(AmountType);
                CurrLineWithPrice.ValidatePrice(AmountType);
            end;
        end;
    end;

    procedure ShowPrices(var TempPriceListLine: Record "TWE Rental Price List Line")
    var
        GetRentalPriceLine: Page "TWE Get Rental Price Line";
        AmountType: Enum "Price Amount Type";
    begin
        if not TempPriceListLine.IsEmpty() then begin
            GetRentalPriceLine.SetForLookup(CurrLineWithPrice, AmountType::Price, TempPriceListLine);
            GetRentalPriceLine.RunModal();
        end;
    end;

    local procedure AddSupportedSetup(var TempRentalPriceCalculationSetup: Record "TWE Rental Price Calc. Setup" temporary)
    begin
        TempRentalPriceCalculationSetup.Init();
        TempRentalPriceCalculationSetup.Validate(Implementation, TempRentalPriceCalculationSetup.Implementation::Rent);
        TempRentalPriceCalculationSetup.Method := TempRentalPriceCalculationSetup.Method::"Lowest Price";
        TempRentalPriceCalculationSetup.Enabled := not IsDisabled();
        TempRentalPriceCalculationSetup.Default := true;
        TempRentalPriceCalculationSetup.Type := TempRentalPriceCalculationSetup.Type::Rental;
        TempRentalPriceCalculationSetup.Insert(true);
    end;

    local procedure IsDisabled() Result: Boolean;
    begin
        OnIsDisabled(Result);
    end;

    local procedure PickBestLine(AmountType: Enum "Price Amount Type"; RentalPriceListLine: Record "TWE Rental Price List Line"; var BestPriceListLine: Record "TWE Rental Price List Line"; var FoundBestLine: Boolean)
    begin
        if IsImprovedLine(RentalPriceListLine, BestPriceListLine) or not IsDegradedLine(RentalPriceListLine, BestPriceListLine) then begin
            if IsImprovedLine(RentalPriceListLine, BestPriceListLine) and not IsDegradedLine(RentalPriceListLine, BestPriceListLine) then
                Clear(BestPriceListLine);
            if IsBetterLine(RentalPriceListLine, AmountType, BestPriceListLine) then begin
                BestPriceListLine := RentalPriceListLine;
                FoundBestLine := true;
            end;
        end;
        OnAfterPickBestLine(AmountType, RentalPriceListLine, BestPriceListLine, FoundBestLine);
    end;

    local procedure IsDegradedLine(RentalPriceListLine: Record "TWE Rental Price List Line"; BestPriceListLine: Record "TWE Rental Price List Line") Result: Boolean
    begin
        Result :=
            IsBlankedValue(RentalPriceListLine."Currency Code", BestPriceListLine."Currency Code") or
            IsBlankedValue(RentalPriceListLine."Variant Code", BestPriceListLine."Variant Code");
    end;

    local procedure IsBlankedValue(LineValue: Text; BestLineValue: Text): Boolean
    begin
        exit((BestLineValue <> '') and (LineValue = ''));
    end;

    local procedure IsImprovedLine(RentalPriceListLine: Record "TWE Rental Price List Line"; BestPriceListLine: Record "TWE Rental Price List Line") Result: Boolean
    begin
        Result :=
            IsSetValue(RentalPriceListLine."Currency Code", BestPriceListLine."Currency Code") or
            IsSetValue(RentalPriceListLine."Variant Code", BestPriceListLine."Variant Code");
    end;

    local procedure IsSetValue(LineValue: Text; BestLineValue: Text): Boolean
    begin
        exit((BestLineValue = '') and (LineValue <> ''));
    end;

    /// <summary>
    /// IsBetterLine.
    /// </summary>
    /// <param name="RentalPriceListLine">VAR Record "TWE Rental Price List Line".</param>
    /// <param name="AmountType">Enum "Price Amount Type".</param>
    /// <param name="BestRentalPriceListLine">Record "TWE Rental Price List Line".</param>
    /// <returns>Return variable Result of type Boolean.</returns>
    procedure IsBetterLine(var RentalPriceListLine: Record "TWE Rental Price List Line"; AmountType: Enum "Price Amount Type"; BestRentalPriceListLine: Record "TWE Rental Price List Line") Result: Boolean;
    begin
        if AmountType = AmountType::Discount then
            Result := RentalPriceListLine."Line Discount %" > BestRentalPriceListLine."Line Discount %"
        else
            case RentalPriceListLine."Price Type" of
                RentalPriceListLine."Price Type"::Rental:
                    Result := IsBetterPrice(RentalPriceListLine, RentalPriceListLine."Unit Price", BestRentalPriceListLine);
            end;
        OnAfterIsBetterLine(RentalPriceListLine, AmountType, BestRentalPriceListLine, Result);
    end;

    local procedure IsBetterPrice(var RentalPriceListLine: Record "TWE Rental Price List Line"; Price: Decimal; BestRentalPriceListLine: Record "TWE Rental Price List Line"): Boolean;
    begin
        RentalPriceListLine."Line Amount" := Price * (1 - RentalPriceListLine."Line Discount %" / 100);
        if not BestRentalPriceListLine.IsRealLine() then
            exit(true);
        exit(RentalPriceListLine."Line Amount" < BestRentalPriceListLine."Line Amount");
    end;

    /// <summary>
    /// FindLines.
    /// </summary>
    /// <param name="AmountType">Enum "Price Amount Type".</param>
    /// <param name="TempRentalPriceListLine">Temporary VAR Record "TWE Rental Price List Line".</param>
    /// <param name="RentalPriceCalcBufferMgt">VAR Codeunit "TWE Rental Price Calc Buf Mgt.".</param>
    /// <param name="ShowAll">Boolean.</param>
    /// <returns>Return variable FoundLines of type Boolean.</returns>
    procedure FindLines(
        AmountType: Enum "Price Amount Type";
        var TempRentalPriceListLine: Record "TWE Rental Price List Line" temporary;
        var RentalPriceCalcBufferMgt: Codeunit "TWE Rental Price Calc Buf Mgt.";
        ShowAll: Boolean) FoundLines: Boolean;
    var
        RentalPriceListLine: Record "TWE Rental Price List Line";
        RentalPriceSource: Record "TWE Rental Price Source";
        RentalPriceAssetList: Codeunit "TWE Rental Price Asset List";
        RentalPriceSourceList: Codeunit "TWE Rental Price Source List";
        Level: array[2] of Integer;
        CurrLevel: Integer;
    begin
        if not TempRentalPriceListLine.IsTemporary() then
            Error(TempTableErr);

        TempRentalPriceListLine.Reset();
        TempRentalPriceListLine.DeleteAll();

        RentalPriceCalcBufferMgt.SetFiltersOnPriceListLine(RentalPriceListLine, AmountType, ShowAll);
        RentalPriceCalcBufferMgt.GetAssets(RentalPriceAssetList);
        RentalPriceCalcBufferMgt.GetSources(RentalPriceSourceList);
        RentalPriceSourceList.GetMinMaxLevel(Level);
        for CurrLevel := Level[2] downto Level[1] do
            if not FoundLines then
                if RentalPriceSourceList.First(RentalPriceSource, CurrLevel) then
                    repeat
                        if RentalPriceSource.IsForAmountType(AmountType) then begin
                            FoundLines :=
                                FoundLines or CopyLinesBySource(RentalPriceListLine, RentalPriceSource, RentalPriceAssetList, TempRentalPriceListLine);
                            RentalPriceCalcBufferMgt.RestoreFilters(RentalPriceListLine);
                        end;
                    until not RentalPriceSourceList.Next(RentalPriceSource);

        exit(not TempRentalPriceListLine.IsEmpty());
    end;

    /// <summary>
    /// CopyLinesBySource.
    /// </summary>
    /// <param name="RentalPriceListLine">VAR Record "TWE Rental Price List Line".</param>
    /// <param name="RentalPriceSource">Record "TWE Rental Price Source".</param>
    /// <param name="RentalPriceAssetList">VAR Codeunit "TWE Rental Price Asset List".</param>
    /// <param name="TempRentalPriceListLine">Temporary VAR Record "TWE Rental Price List Line".</param>
    /// <returns>Return variable FoundLines of type Boolean.</returns>
    procedure CopyLinesBySource(
        var RentalPriceListLine: Record "TWE Rental Price List Line";
        RentalPriceSource: Record "TWE Rental Price Source";
        var RentalPriceAssetList: Codeunit "TWE Rental Price Asset List";
        var TempRentalPriceListLine: Record "TWE Rental Price List Line" temporary) FoundLines: Boolean;
    var
        RentalPriceAsset: Record "TWE Rental Price Asset";
        Level: array[2] of Integer;
        CurrLevel: Integer;
    begin
        RentalPriceAssetList.GetMinMaxLevel(Level);
        for CurrLevel := Level[2] downto Level[1] do
            if not FoundLines then
                if RentalPriceAssetList.First(RentalPriceAsset, CurrLevel) then
                    repeat
                        FoundLines :=
                            FoundLines or CopyLinesBySource(RentalPriceListLine, RentalPriceSource, RentalPriceAsset, TempRentalPriceListLine);
                    until not RentalPriceAssetList.Next(RentalPriceAsset);
    end;

    /// <summary>
    /// CopyLinesBySource.
    /// </summary>
    /// <param name="RentalPriceListLine">VAR Record "TWE Rental Price List Line".</param>
    /// <param name="RentalPriceSource">Record "TWE Rental Price Source".</param>
    /// <param name="RentalPriceAsset">Record "TWE Rental Price Asset".</param>
    /// <param name="TempRentalPriceListLine">Temporary VAR Record "TWE Rental Price List Line".</param>
    /// <returns>Return value of type Boolean.</returns>
    procedure CopyLinesBySource(
        var RentalPriceListLine: Record "TWE Rental Price List Line";
        RentalPriceSource: Record "TWE Rental Price Source";
        RentalPriceAsset: Record "TWE Rental Price Asset";
        var TempRentalPriceListLine: Record "TWE Rental Price List Line" temporary): Boolean;
    begin
        RentalPriceSource.FilterPriceLines(RentalPriceListLine);
        RentalPriceAsset.FilterPriceLines(RentalPriceListLine);
        exit(RentalPriceListLine.CopyFilteredLinesToTemporaryBuffer(TempRentalPriceListLine));
    end;

    /// <summary>
    /// CalcBestAmount.
    /// </summary>
    /// <param name="AmountType">Enum "Price Amount Type".</param>
    /// <param name="PriceCalculationBufferMgt">VAR Codeunit "TWE Rental Price Calc Buf Mgt.".</param>
    /// <param name="RentalPriceListLine">VAR Record "TWE Rental Price List Line".</param>
    /// <returns>Return variable FoundBestPrice of type Boolean.</returns>
    procedure CalcBestAmount(AmountType: Enum "Price Amount Type"; var RentalPriceCalcBufferMgt: Codeunit "TWE Rental Price Calc Buf Mgt."; var RentalPriceListLine: Record "TWE Rental Price List Line") FoundBestPrice: Boolean;
    var
        BestRentalPriceListLine: Record "TWE Rental Price List Line";
    begin
        OnBeforeCalcBestAmount(AmountType, RentalPriceCalcBufferMgt, RentalPriceListLine);
        RentalPriceListLine.SetRange(Status, RentalPriceListLine.Status::Active);
        if RentalPriceListLine.FindSet() then
            repeat
                if RentalPriceCalcBufferMgt.IsInMinQty(RentalPriceListLine) then begin
                    RentalPriceCalcBufferMgt.ConvertAmount(AmountType, RentalPriceListLine);
                    PickBestLine(AmountType, RentalPriceListLine, BestRentalPriceListLine, FoundBestPrice);
                end;
            until RentalPriceListLine.Next() = 0;
        if FoundBestPrice then
            RentalPriceListLine := BestRentalPriceListLine;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TWE Rental Price Calc Mgt.", 'OnFindSupportedSetup', '', false, false)]
    local procedure OnFindImplementationHandler(var TempRentalPriceCalcSetup: Record "TWE Rental Price Calc. Setup" temporary)
    begin
        AddSupportedSetup(TempRentalPriceCalcSetup);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company-Initialize", 'OnCompanyInitialize', '', false, false)]
    local procedure OnCompanyInitializeHandler()
    var
        TempRentalPriceCalcSetup: Record "TWE Rental Price Calc. Setup" temporary;
        RentalPriceCalcSetup: Record "TWE Rental Price Calc. Setup";
        RentalPriceCalculationMgt: Codeunit "TWE Rental Price Calc Mgt.";
    begin

        AddSupportedSetup(TempRentalPriceCalcSetup);
        RentalPriceCalcSetup.DeleteAll();
        if TempRentalPriceCalcSetup.FindSet() then
            repeat
                RentalPriceCalcSetup := TempRentalPriceCalcSetup;
                RentalPriceCalcSetup.Default := true;
                RentalPriceCalcSetup.Insert();
            until TempRentalPriceCalcSetup.Next() = 0;
        RentalPriceCalculationMgt.Run();
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterIsBetterLine(RentalPriceListLine: Record "TWE Rental Price List Line"; AmountType: Enum "Price Amount Type"; BestRentalPriceListLine: Record "TWE Rental Price List Line"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPickBestLine(AmountType: Enum "Price Amount Type"; RentalPriceListLine: Record "TWE Rental Price List Line"; var BestPriceListLine: Record "TWE Rental Price List Line"; var FoundBestLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcBestAmount(AmountType: Enum "Price Amount Type"; var PriceCalculationBufferMgt: Codeunit "TWE Rental Price Calc Buf Mgt."; var RentalPriceListLine: Record "TWE Rental Price List Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnIsDisabled(var Disabled: Boolean)
    begin
    end;
}
