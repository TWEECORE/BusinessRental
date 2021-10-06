/// <summary>
/// Interface 50000 Rental Price Asset."
/// </summary>
interface 50000 Rental Price Asset"
{
    /// <summary>
    /// 
    /// </summary>
    /// <param name="PriceAsset">....</param>
    /// <returns>  .</returns>
    procedure GetNo(var PriceAsset: Record 50000 Rental Price Asset")

    /// <summary>
    /// 
    /// </summary>
    /// <param name="PriceAsset">....</param>
    /// <returns>  .</returns>
    procedure GetId(var PriceAsset: Record 50000 Rental Price Asset")

    /// <summary>
    /// 
    /// </summary>
    /// <param name="PriceAsset">....</param>
    /// <returns>  .</returns>
    procedure IsLookupOK(var PriceAsset: Record 50000 Rental Price Asset"): Boolean

    /// <summary>
    /// 
    /// </summary>
    /// <param name="PriceAsset">....</param>
    /// <returns>  .</returns>
    procedure ValidateUnitOfMeasure(var PriceAsset: Record 50000 Rental Price Asset"): Boolean

    /// <summary>
    /// 
    /// </summary>
    /// <param name="PriceAsset">....</param>
    /// <returns>  .</returns>
    procedure IsLookupUnitOfMeasureOK(var PriceAsset: Record 50000 Rental Price Asset"): Boolean

    /// <summary>
    /// 
    /// </summary>
    /// <param name="PriceAsset">....</param>
    /// <returns>  .</returns>
    procedure IsLookupVariantOK(var PriceAsset: Record 50000 Rental Price Asset"): Boolean

    /// <summary>
    /// 
    /// </summary>
    /// <returns>  .</returns>
    procedure IsAssetNoRequired(): Boolean;

    /// <summary>
    /// FillBestLine.
    /// </summary>
    /// <param name="RentalPriceCalculationBuffer">Record 50000 Rental Price Calc. Buffer".</param>
    /// <param name="AmountType">Enum "Price Amount Type".</param>
    /// <param name="PriceListLine">VAR Record 50000 Rental Price List Line".</param>
    procedure FillBestLine(RentalPriceCalculationBuffer: Record 50000 Rental Price Calc. Buffer"; AmountType: Enum "Price Amount Type"; var PriceListLine: Record 50000 Rental Price List Line")

    /// <summary>
    /// 
    /// </summary>
    /// <param name="PriceAsset">....</param>
    /// <param name="PriceListLine">....</param>
    /// <returns>  .</returns>
    procedure FilterPriceLines(PriceAsset: Record 50000 Rental Price Asset"; var PriceListLine: Record 50000 Rental Price List Line") Result: Boolean;

    /// <summary>
    /// 
    /// </summary>
    /// <param name="PriceAsset">....</param>
    /// <param name="PriceAssetList">....</param>
    /// <returns>The list of assets in the TempPriceAsset buffer.</returns>
    procedure PutRelatedAssetsToList(PriceAsset: Record 50000 Rental Price Asset"; var PriceAssetList: Codeunit 50000 Rental Price Asset List")

    /// <summary>
    /// 
    /// </summary>
    /// <param name="PriceAsset">....</param>
    /// <param name="RentalPriceCalculationBuffer">Record 50000 Rental Price Calc. Buffer".</param>
    /// <returns>The list of assets in the TempPriceAsset buffer.</returns>
    procedure FillFromBuffer(var PriceAsset: Record 50000 Rental Price Asset"; RentalPriceCalculationBuffer: Record 50000 Rental Price Calc. Buffer")
}
