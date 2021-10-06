/// <summary>
/// Codeunit TWE Rental Price Calc Buf Mgt. (ID 70704614).
/// </summary>
codeunit 50040 "TWE Rental Price Calc Buf Mgt."
{
    var
        RentalPriceCalculationBuffer: Record "TWE Rental Price Calc. Buffer";
        RentalPriceListLineFiltered: Record "TWE Rental Price List Line";
        RentalPriceAssetList: Codeunit "TWE Rental Price Asset List";
        RentalPriceSourceList: Codeunit "TWE Rental Price Source List";
        UnitAmountRoundingPrecision: Decimal;
        PricesInclVATErr: Label 'Prices including VAT cannot be calculated because the VAT Calculation Type field contains %1.',
            Comment = '%1 - VAT Calculation Type field value';
        GetPriceOutOfDateErr: Label 'The selected price line is not valid on the document date %1.',
            Comment = '%1 - a date value';
        GetPriceFieldMismatchErr: Label 'The %1 in the selected price line must be %2.',
            Comment = '%1 - a field caption, %2 - a value of the field';

    /// <summary>
    /// AddAsset.
    /// </summary>
    /// <param name="RentalPriceAssetType">Enum "TWE Rental Price Asset Type".</param>
    /// <param name="AssetNo">Code[20].</param>
    procedure AddAsset(RentalPriceAssetType: Enum "TWE Rental Price Asset Type"; AssetNo: Code[20])
    begin
        RentalPriceAssetList.Add(RentalPriceAssetType, AssetNo);
    end;

    /// <summary>
    /// AddSource.
    /// </summary>
    /// <param name="RentalPriceSourceType">Enum "TWE Rental Price Source Type".</param>
    /// <param name="ParentSourceNo">Code[20].</param>
    /// <param name="SourceNo">Code[20].</param>
    procedure AddSource(RentalPriceSourceType: Enum "TWE Rental Price Source Type"; ParentSourceNo: Code[20]; SourceNo: Code[20])
    begin
        RentalPriceSourceList.Add(RentalPriceSourceType, ParentSourceNo, SourceNo);
    end;

    /// <summary>
    /// AddSource.
    /// </summary>
    /// <param name="RentalPriceSourceType">Enum "TWE Rental Price Source Type".</param>
    /// <param name="SourceNo">Code[20].</param>
    procedure AddSource(RentalPriceSourceType: Enum "TWE Rental Price Source Type"; SourceNo: Code[20])
    begin
        RentalPriceSourceList.Add(RentalPriceSourceType, SourceNo);
    end;

    /// <summary>
    /// AddSource.
    /// </summary>
    /// <param name="RentalPriceSourceType">Enum "TWE Rental Price Source Type".</param>
    procedure AddSource(RentalPriceSourceType: Enum "TWE Rental Price Source Type")
    begin
        RentalPriceSourceList.Add(RentalPriceSourceType);
    end;

    /// <summary>
    /// GetAsset.
    /// </summary>
    /// <param name="RentalPriceAsset">VAR Record "TWE Rental Price Asset".</param>
    procedure GetAsset(var RentalPriceAsset: Record "TWE Rental Price Asset")
    begin
        RentalPriceAsset.Init();
        RentalPriceAsset.Validate("Asset Type", RentalPriceCalculationBuffer."Asset Type");
        RentalPriceAsset.Validate("Asset No.", RentalPriceCalculationBuffer."Asset No.");
        RentalPriceAsset."Unit of Measure Code" := RentalPriceCalculationBuffer."Unit of Measure Code";
        RentalPriceAsset."Variant Code" := RentalPriceCalculationBuffer."Variant Code";
    end;

    /// <summary>
    /// GetAssets.
    /// </summary>
    /// <param name="NewRentalPriceAssetList">VAR Codeunit "TWE Rental Price Asset List".</param>
    procedure GetAssets(var NewRentalPriceAssetList: Codeunit "TWE Rental Price Asset List")
    begin
        NewRentalPriceAssetList.Copy(RentalPriceAssetList);
        OnAfterGetAssets(RentalPriceCalculationBuffer, NewRentalPriceAssetList);
    end;

    /// <summary>
    /// GetBuffer.
    /// </summary>
    /// <param name="ResultRentalPriceCalcBuffer">VAR Record "TWE Rental Price Calc. Buffer".</param>
    procedure GetBuffer(var ResultRentalPriceCalcBuffer: Record "TWE Rental Price Calc. Buffer")
    begin
        ResultRentalPriceCalcBuffer := RentalPriceCalculationBuffer;
    end;

    /// <summary>
    /// GetSource.
    /// </summary>
    /// <param name="RentalPriceSourceType">Enum "TWE Rental Price Source Type".</param>
    /// <returns>Return variable SourceNo of type Code[20].</returns>
    procedure GetSource(RentalPriceSourceType: Enum "TWE Rental Price Source Type") SourceNo: Code[20];
    begin
        SourceNo := RentalPriceSourceList.GetValue(RentalPriceSourceType);
    end;

    /// <summary>
    /// GetSources.
    /// </summary>
    /// <param name="TempRentalPriceSource">Temporary VAR Record "TWE Rental Price Source".</param>
    /// <returns>Return variable Found of type Boolean.</returns>
    procedure GetSources(var TempRentalPriceSource: Record "TWE Rental Price Source" temporary) Found: Boolean;
    begin
        Found := RentalPriceSourceList.GetList(TempRentalPriceSource);
        OnAfterGetSources(RentalPriceCalculationBuffer, TempRentalPriceSource, Found);
    end;

    /// <summary>
    /// GetSources.
    /// </summary>
    /// <param name="NewRentalPriceSourceList">VAR Codeunit "TWE Rental Price Source List".</param>
    procedure GetSources(var NewRentalPriceSourceList: Codeunit "TWE Rental Price Source List")
    begin
        NewRentalPriceSourceList.Copy(RentalPriceSourceList);
        OnAfterGetSourcesNewPriceSourceList(RentalPriceCalculationBuffer, NewRentalPriceSourceList);
    end;

    /// <summary>
    /// SetAssets.
    /// </summary>
    /// <param name="NewRentalPriceAssetList">VAR Codeunit "TWE Rental Price Asset List".</param>
    procedure SetAssets(var NewRentalPriceAssetList: Codeunit "TWE Rental Price Asset List")
    begin
        RentalPriceAssetList.Copy(NewRentalPriceAssetList);
    end;

    /// <summary>
    /// SetSources.
    /// </summary>
    /// <param name="NewRentalPriceSourceList">VAR Codeunit "TWE Rental Price Source List".</param>
    procedure SetSources(var NewRentalPriceSourceList: Codeunit "TWE Rental Price Source List")
    begin
        RentalPriceSourceList.Copy(NewRentalPriceSourceList);
    end;

    /// <summary>
    /// Set.
    /// </summary>
    /// <param name="NewRentalPriceCalcBuffer">Record "TWE Rental Price Calc. Buffer".</param>
    /// <param name="RentalPriceSourceList">VAR Codeunit "TWE Rental Price Source List".</param>
    procedure Set(NewRentalPriceCalcBuffer: Record "TWE Rental Price Calc. Buffer"; var RentalPriceSourceList: Codeunit "TWE Rental Price Source List")
    begin
        RentalPriceCalculationBuffer := NewRentalPriceCalcBuffer;
        CalcUnitAmountRoundingPrecision();

        RentalPriceAssetList.Init();
        RentalPriceAssetList.Add(RentalPriceCalculationBuffer);

        SetSources(RentalPriceSourceList);
    end;

    local procedure CalcUnitAmountRoundingPrecision()
    var
        Currency: Record Currency;
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        if RentalPriceCalculationBuffer."Currency Code" <> '' then begin
            Currency.Get(RentalPriceCalculationBuffer."Currency Code");
            Currency.TestField("Unit-Amount Rounding Precision");
            UnitAmountRoundingPrecision := Currency."Unit-Amount Rounding Precision";
        end else begin
            GeneralLedgerSetup.Get();
            GeneralLedgerSetup.TestField("Unit-Amount Rounding Precision");
            UnitAmountRoundingPrecision := GeneralLedgerSetup."Unit-Amount Rounding Precision";
        end;
        OnAfterCalcUnitAmountRoundingPrecision(RentalPriceCalculationBuffer, UnitAmountRoundingPrecision);
    end;

    /// <summary>
    /// RoundPrice.
    /// </summary>
    /// <param name="Price">VAR Decimal.</param>
    procedure RoundPrice(var Price: Decimal)
    begin
        Price := Round(Price, UnitAmountRoundingPrecision);
    end;

    /// <summary>
    /// IsInMinQty.
    /// </summary>
    /// <param name="RentalPriceListLine">Record "TWE Rental Price List Line".</param>
    /// <returns>Return value of type Boolean.</returns>
    procedure IsInMinQty(RentalPriceListLine: Record "TWE Rental Price List Line"): Boolean
    begin
        if RentalPriceListLine."Unit of Measure Code" = '' then
            exit(RentalPriceListLine."Minimum Quantity" <= RentalPriceCalculationBuffer."Qty. per Unit of Measure" * RentalPriceCalculationBuffer.Quantity);
        exit(RentalPriceListLine."Minimum Quantity" <= RentalPriceCalculationBuffer.Quantity);
    end;

    /// <summary>
    /// ConvertAmount.
    /// </summary>
    /// <param name="AmountType">Enum "Price Amount Type".</param>
    /// <param name="RentalPriceListLine">VAR Record "TWE Rental Price List Line".</param>
    procedure ConvertAmount(AmountType: Enum "Price Amount Type"; var RentalPriceListLine: Record "TWE Rental Price List Line")
    var
        IsHandled: Boolean;
    begin
        OnBeforeConvertAmount(AmountType, RentalPriceListLine, RentalPriceCalculationBuffer, IsHandled);
        if not IsHandled then
            if AmountType <> AmountType::Discount then begin
                ConvertAmount(RentalPriceListLine, RentalPriceListLine."Unit Price");
                ConvertAmount(RentalPriceListLine, RentalPriceListLine."Unit Cost");
                ConvertAmount(RentalPriceListLine, RentalPriceListLine."Direct Unit Cost");
            end;
    end;

    local procedure ConvertAmount(var RentalPriceListLine: Record "TWE Rental Price List Line"; var Amount: Decimal)
    begin
        if Amount = 0 then
            exit;

        ConvertAmountByTax(RentalPriceListLine, Amount);
        ConvertAmountByUnitOfMeasure(RentalPriceListLine, Amount);
        ConvertAmountByCurrency(RentalPriceListLine, Amount);
        RoundPrice(Amount);

        SetLineDiscountPctForPickBestLine(RentalPriceListLine);
    end;

    /// <summary>
    /// ConvertAmountByTax.
    /// </summary>
    /// <param name="RentalPriceListLine">VAR Record "TWE Rental Price List Line".</param>
    /// <param name="Amount">VAR Decimal.</param>
    procedure ConvertAmountByTax(var RentalPriceListLine: Record "TWE Rental Price List Line"; var Amount: Decimal)
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        if RentalPriceListLine."Price Includes VAT" then begin
            VATPostingSetup.Get(RentalPriceListLine."VAT Bus. Posting Gr. (Price)", RentalPriceCalculationBuffer."VAT Prod. Posting Group");
            OnConvertAmountByTaxOnAfterVATPostingSetupGet(VATPostingSetup);
            if VATPostingSetup."VAT Calculation Type" = VATPostingSetup."VAT Calculation Type"::"Sales Tax" then
                Error(PricesInclVATErr, VATPostingSetup."VAT Calculation Type");

            case RentalPriceCalculationBuffer."VAT Calculation Type" of
                VATPostingSetup."VAT Calculation Type"::"Normal VAT".AsInteger(),
                VATPostingSetup."VAT Calculation Type"::"Full VAT".AsInteger():
                    if RentalPriceCalculationBuffer."Prices Including Tax" then begin
                        if RentalPriceCalculationBuffer."VAT Bus. Posting Group" <> RentalPriceListLine."VAT Bus. Posting Gr. (Price)" then
                            Amount := Amount * (100 + RentalPriceCalculationBuffer."Tax %") / (100 + VATPostingSetup."VAT %");
                    end else
                        Amount := Amount / (1 + VATPostingSetup."VAT %" / 100);
            end;
        end else
            if RentalPriceCalculationBuffer."Prices Including Tax" then
                Amount := Amount * (1 + RentalPriceCalculationBuffer."Tax %" / 100);
    end;

    /// <summary>
    /// ConvertAmountByUnitOfMeasure.
    /// </summary>
    /// <param name="RentalPriceListLine">VAR Record "TWE Rental Price List Line".</param>
    /// <param name="Amount">VAR Decimal.</param>
    procedure ConvertAmountByUnitOfMeasure(var RentalPriceListLine: Record "TWE Rental Price List Line"; var Amount: Decimal)
    begin
        if RentalPriceListLine."Unit of Measure Code" = '' then
            Amount := Amount * RentalPriceCalculationBuffer."Qty. per Unit of Measure";
    end;

    /// <summary>
    /// ConvertAmountByCurrency.
    /// </summary>
    /// <param name="RentalPriceListLine">VAR Record "TWE Rental Price List Line".</param>
    /// <param name="Amount">VAR Decimal.</param>
    procedure ConvertAmountByCurrency(var RentalPriceListLine: Record "TWE Rental Price List Line"; var Amount: Decimal)
    var
        CurrExchRate: Record "Currency Exchange Rate";
    begin
        if (RentalPriceCalculationBuffer."Currency Code" <> '') and (RentalPriceListLine."Currency Code" = '') then
            Amount :=
                CurrExchRate.ExchangeAmtLCYToFCY(
                    RentalPriceCalculationBuffer."Document Date", RentalPriceCalculationBuffer."Currency Code",
                    Amount, RentalPriceCalculationBuffer."Currency Factor");
    end;

    /// <summary>
    /// SetLineDiscountPctForPickBestLine.
    /// </summary>
    /// <param name="RentalPriceListLine">VAR Record "TWE Rental Price List Line".</param>
    procedure SetLineDiscountPctForPickBestLine(var RentalPriceListLine: Record "TWE Rental Price List Line")
    begin
        if RentalPriceCalculationBuffer."Allow Line Disc." and RentalPriceListLine."Allow Line Disc." then
            RentalPriceListLine."Line Discount %" := RentalPriceCalculationBuffer."Line Discount %"
        else
            RentalPriceListLine."Line Discount %" := 0;
        OnAfterSetLineDiscountPctForPickBestLine(RentalPriceCalculationBuffer, RentalPriceListLine);
    end;

    /// <summary>
    /// FillBestLine.
    /// </summary>
    /// <param name="AmountType">Enum "Price Amount Type".</param>
    /// <param name="RentalPriceListLine">VAR Record "TWE Rental Price List Line".</param>
    procedure FillBestLine(AmountType: Enum "Price Amount Type"; var RentalPriceListLine: Record "TWE Rental Price List Line")
    var
        PriceAssetInterface: Interface "TWE Rental Price Asset";
    begin
        Clear(RentalPriceListLine);
        PriceAssetInterface := RentalPriceCalculationBuffer."Asset Type";
        PriceAssetInterface.FillBestLine(RentalPriceCalculationBuffer, AmountType, RentalPriceListLine);
        ConvertAmount(AmountType, RentalPriceListLine);
        RentalPriceListLine."Allow Line Disc." := RentalPriceCalculationBuffer."Allow Line Disc.";
        RentalPriceListLine."Allow Invoice Disc." := RentalPriceCalculationBuffer."Allow Invoice Disc.";
    end;

    /// <summary>
    /// SetFiltersOnPriceListLine.
    /// </summary>
    /// <param name="RentalPriceListLine">VAR Record "TWE Rental Price List Line".</param>
    /// <param name="AmountType">Enum "Price Amount Type".</param>
    /// <param name="ShowAll">Boolean.</param>
    procedure SetFiltersOnPriceListLine(var RentalPriceListLine: Record "TWE Rental Price List Line"; AmountType: Enum "Price Amount Type"; ShowAll: Boolean)
    begin
        RentalPriceListLine.SetRange(Status, RentalPriceListLine.Status::Active);
        RentalPriceListLine.SetRange("Price Type", RentalPriceCalculationBuffer."Price Type");
        RentalPriceListLine.SetFilter("Amount Type", '%1|%2', AmountType, RentalPriceListLine."Amount Type"::Any);

        RentalPriceListLine.SetFilter("Ending Date", '%1|>=%2', 0D, RentalPriceCalculationBuffer."Document Date");
        if not ShowAll then begin
            RentalPriceListLine.SetFilter("Currency Code", '%1|%2', RentalPriceCalculationBuffer."Currency Code", '');
            if RentalPriceCalculationBuffer."Unit of Measure Code" <> '' then
                RentalPriceListLine.SetFilter("Unit of Measure Code", '%1|%2', RentalPriceCalculationBuffer."Unit of Measure Code", '');
            RentalPriceListLine.SetRange("Starting Date", 0D, RentalPriceCalculationBuffer."Document Date");
        end;
        OnAfterSetFilters(RentalPriceListLine, AmountType, RentalPriceCalculationBuffer, ShowAll);
        RentalPriceListLineFiltered.CopyFilters(RentalPriceListLine);
    end;

    /// <summary>
    /// RestoreFilters.
    /// </summary>
    /// <param name="RentalPriceListLine">VAR Record "TWE Rental Price List Line".</param>
    procedure RestoreFilters(var RentalPriceListLine: Record "TWE Rental Price List Line")
    begin
        RentalPriceListLine.Reset();
        RentalPriceListLine.CopyFilters(RentalPriceListLineFiltered);
    end;

    /// <summary>
    /// VerifySelectedLine.
    /// </summary>
    /// <param name="RentalPriceListLine">Record "TWE Rental Price List Line".</param>
    procedure VerifySelectedLine(RentalPriceListLine: Record "TWE Rental Price List Line")
    begin
        if not (RentalPriceListLine."Currency Code" in [RentalPriceCalculationBuffer."Currency Code", '']) then
            Error(
                GetPriceFieldMismatchErr,
                RentalPriceListLine.FieldCaption("Currency Code"), RentalPriceCalculationBuffer."Currency Code");

        if not (RentalPriceListLine."Unit of Measure Code" in [RentalPriceCalculationBuffer."Unit of Measure Code", '']) then
            Error(
                GetPriceFieldMismatchErr,
                RentalPriceListLine.FieldCaption("Unit of Measure Code"), RentalPriceCalculationBuffer."Unit of Measure Code");

        if RentalPriceListLine."Starting Date" > RentalPriceCalculationBuffer."Document Date" then
            Error(GetPriceOutOfDateErr, RentalPriceCalculationBuffer."Document Date")
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcUnitAmountRoundingPrecision(PriceCalculationBuffer: Record "TWE Rental Price Calc. Buffer"; var UnitAmountRoundingPrecision: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetAssets(PriceCalculationBuffer: Record "TWE Rental Price Calc. Buffer"; var NewPriceAssetList: Codeunit "TWE Rental Price Asset List")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetSources(PriceCalculationBuffer: Record "TWE Rental Price Calc. Buffer"; var TempPriceSource: Record "TWE Rental Price Source"; var Found: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetSourcesNewPriceSourceList(var PriceCalculationBuffer: Record "TWE Rental Price Calc. Buffer"; var NewPriceSourceList: Codeunit "TWE Rental Price Source List")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetFilters(var PriceListLine: Record "TWE Rental Price List Line"; AmountType: Enum "Price Amount Type"; var PriceCalculationBuffer: Record "TWE Rental Price Calc. Buffer"; ShowAll: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetLineDiscountPctForPickBestLine(PriceCalculationBuffer: Record "TWE Rental Price Calc. Buffer"; var PriceListLine: Record "TWE Rental Price List Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConvertAmount(AmountType: Enum "Price Amount Type"; var PriceListLine: Record "TWE Rental Price List Line"; PriceCalculationBuffer: Record "TWE Rental Price Calc. Buffer"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnConvertAmountByTaxOnAfterVATPostingSetupGet(var VATPostingSetup: Record "VAT Posting Setup")
    begin
    end;
}
