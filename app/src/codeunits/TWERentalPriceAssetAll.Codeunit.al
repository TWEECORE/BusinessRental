/// <summary>
/// Codeunit TWE Rental Price Asset - All (ID 50038) implements Interface TWE Rental Price Asset.
/// </summary>
codeunit 50038 "TWE Rental Price Asset - All" implements "TWE Rental Price Asset"
{
    /// <summary>
    /// GetNo.
    /// </summary>
    /// <param name="RentalPriceAsset">VAR Record "TWE Rental Price Asset".</param>
    procedure GetNo(var RentalPriceAsset: Record "TWE Rental Price Asset")
    begin
        RentalPriceAsset.InitAsset();
    end;

    /// <summary>
    /// GetId.
    /// </summary>
    /// <param name="RentalPriceAsset">VAR Record "TWE Rental Price Asset".</param>
    procedure GetId(var RentalPriceAsset: Record "TWE Rental Price Asset")
    begin
        RentalPriceAsset.InitAsset();
    end;

    /// <summary>
    /// IsLookupOK.
    /// </summary>
    /// <param name="RentalPriceAsset">VAR Record "TWE Rental Price Asset".</param>
    /// <returns>Return value of type Boolean.</returns>
    procedure IsLookupOK(var RentalPriceAsset: Record "TWE Rental Price Asset"): Boolean
    begin
        exit(false)
    end;

    /// <summary>
    /// IsLookupUnitOfMeasureOK.
    /// </summary>
    /// <param name="PriceAsset">VAR Record "TWE Rental Price Asset".</param>
    /// <returns>Return value of type Boolean.</returns>
    procedure IsLookupUnitOfMeasureOK(var PriceAsset: Record "TWE Rental Price Asset"): Boolean
    begin
        exit(false)
    end;

    /// <summary>
    /// IsLookupVariantOK.
    /// </summary>
    /// <param name="RentalPriceAsset">VAR Record "TWE Rental Price Asset".</param>
    /// <returns>Return value of type Boolean.</returns>
    procedure IsLookupVariantOK(var RentalPriceAsset: Record "TWE Rental Price Asset"): Boolean
    begin
        exit(false)
    end;

    /// <summary>
    /// ValidateUnitOfMeasure.
    /// </summary>
    /// <param name="RentalPriceAsset">VAR Record "TWE Rental Price Asset".</param>
    /// <returns>Return value of type Boolean.</returns>
    procedure ValidateUnitOfMeasure(var RentalPriceAsset: Record "TWE Rental Price Asset"): Boolean
    begin
        exit(false)
    end;

    /// <summary>
    /// IsAssetNoRequired.
    /// </summary>
    /// <returns>Return value of type Boolean.</returns>
    procedure IsAssetNoRequired(): Boolean;
    begin
        exit(false)
    end;

    /// <summary>
    /// FillBestLine.
    /// </summary>
    /// <param name="RentPriceCalcBuffer">Record "TWE Rental Price Calc. Buffer".</param>
    /// <param name="AmountType">Enum "Price Amount Type".</param>
    /// <param name="RentalPriceListLine">VAR Record "TWE Rental Price List Line".</param>
    procedure FillBestLine(RentPriceCalcBuffer: Record "TWE Rental Price Calc. Buffer"; AmountType: Enum "Price Amount Type"; var RentalPriceListLine: Record "TWE Rental Price List Line")
    begin
    end;

    /// <summary>
    /// FilterPriceLines.
    /// </summary>
    /// <param name="RentalPriceAsset">Record "TWE Rental Price Asset".</param>
    /// <param name="RentalPriceListLine">VAR Record "TWE Rental Price List Line".</param>
    /// <returns>Return variable Result of type Boolean.</returns>
    procedure FilterPriceLines(RentalPriceAsset: Record "TWE Rental Price Asset"; var RentalPriceListLine: Record "TWE Rental Price List Line") Result: Boolean;
    begin
        RentalPriceListLine.SetRange("Asset Type", RentalPriceAsset."Asset Type");
        RentalPriceListLine.SetRange("Asset No.", '');
    end;


    /// <summary>
    /// PutRelatedAssetsToList.
    /// </summary>
    /// <param name="RentalPriceAsset">Record "TWE Rental Price Asset".</param>
    /// <param name="RentalPriceAssetList">VAR Codeunit ".</param>
    procedure PutRelatedAssetsToList(RentalPriceAsset: Record "TWE Rental Price Asset"; var "; var RentalPriceAssetList: Codeunit ": Codeunit "TWE Rental Price Asset List")
    begin
    end;

    /// <summary>
    /// FillFromBuffer.
    /// </summary>
    /// <param name="RentalPriceAsset">VAR Record "TWE Rental Price Asset".</param>
    /// <param name="RentalPriceCalculationBuffer">Record "TWE Rental Price Calc. Buffer".</param>
    procedure FillFromBuffer(var RentalPriceAsset: Record "TWE Rental Price Asset"; RentalPriceCalculationBuffer: Record "TWE Rental Price Calc. Buffer")
    begin
        RentalPriceAsset.NewEntry(RentalPriceCalculationBuffer."Asset Type", RentalPriceAsset.Level);
    end;
}
