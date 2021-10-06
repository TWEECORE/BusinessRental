/// <summary>
/// Codeunit TWE Price Asset - Rental Item (ID 50009) implements Interface Price Asset.
/// </summary>
codeunit 50009 "TWE Price Asset - Rental Item" implements "TWE Rental Price Asset"
{
    var
        MainRentalItem: Record "TWE Main Rental Item";
        RentalItemUnitofMeasure: Record "TWE Rental Item Unit Of Meas.";

    /// <summary>
    /// GetNo.
    /// </summary>
    /// <param name="PriceAsset">VAR Record "TWE Rental Price Asset".</param>
    procedure GetNo(var PriceAsset: Record "TWE Rental Price Asset")
    begin
        PriceAsset."Table Id" := Database::"TWE Main Rental Item";
        if MainRentalItem.GetBySystemId(PriceAsset."Asset ID") then begin
            PriceAsset."Asset No." := MainRentalItem."No.";
            PriceAsset."Variant Code" := '';
            FillAdditionalFields(PriceAsset);
        end else
            PriceAsset.InitAsset();
    end;

    /// <summary>
    /// GetId.
    /// </summary>
    /// <param name="PriceAsset">VAR Record "TWE Rental Price Asset".</param>
    procedure GetId(var PriceAsset: Record "TWE Rental Price Asset")
    begin
        PriceAsset."Table Id" := Database::Item;
        if PriceAsset."Variant Code" = '' then begin
            if MainRentalItem.Get(PriceAsset."Asset No.") then begin
                PriceAsset."Asset ID" := MainRentalItem.SystemId;
                FillAdditionalFields(PriceAsset);
            end else
                PriceAsset.InitAsset();
        end else
            PriceAsset.InitAsset();
    end;

    /// <summary>
    /// IsLookupOK.
    /// </summary>
    /// <param name="PriceAsset">VAR Record "TWE Rental Price Asset".</param>
    /// <returns>Return value of type Boolean.</returns>
    procedure IsLookupOK(var PriceAsset: Record "TWE Rental Price Asset"): Boolean
    var
        xPriceAsset: Record "TWE Rental Price Asset";
    begin
        xPriceAsset := PriceAsset;
        if MainRentalItem.Get(xPriceAsset."Asset No.") then;
        if Page.RunModal(Page::"TWE Main Rental Item List", MainRentalItem) = ACTION::LookupOK then begin
            xPriceAsset.Validate("Asset No.", MainRentalItem."No.");
            PriceAsset := xPriceAsset;
            exit(true);
        end;
    end;

    /// <summary>
    /// Dummy, cause the interface needs it IsLookupVariantOK.
    /// </summary>
    /// <param name="PriceAsset">VAR Record "TWE Rental Price Asset".</param>
    /// <returns>Return value of type Boolean.</returns>
    procedure IsLookupVariantOK(var PriceAsset: Record "TWE Rental Price Asset"): Boolean
    begin
        exit(true);
    end;

    /// <summary>
    /// ValidateUnitOfMeasure.
    /// </summary>
    /// <param name="PriceAsset">VAR Record "TWE Rental Price Asset".</param>
    /// <returns>Return value of type Boolean.</returns>
    procedure ValidateUnitOfMeasure(var PriceAsset: Record "TWE Rental Price Asset"): Boolean
    begin
        RentalItemUnitofMeasure.Get(PriceAsset."Asset No.", PriceAsset."Unit of Measure Code");
    end;

    /// <summary>
    /// IsLookupUnitOfMeasureOK.
    /// </summary>
    /// <param name="PriceAsset">VAR Record "TWE Rental Price Asset".</param>
    /// <returns>Return value of type Boolean.</returns>
    procedure IsLookupUnitOfMeasureOK(var PriceAsset: Record "TWE Rental Price Asset"): Boolean
    begin
        if RentalItemUnitofMeasure.Get(PriceAsset."Asset No.", PriceAsset."Unit of Measure Code") then;
        RentalItemUnitofMeasure.SetRange("Item No.", PriceAsset."Asset No.");
        if Page.RunModal(Page::"Item Units of Measure", RentalItemUnitofMeasure) = ACTION::LookupOK then begin
            PriceAsset.Validate("Unit of Measure Code", RentalItemUnitofMeasure.Code);
            exit(true);
        end;
    end;

    /// <summary>
    /// IsAssetNoRequired.
    /// </summary>
    /// <returns>Return value of type Boolean.</returns>
    procedure IsAssetNoRequired(): Boolean;
    begin
        exit(true)
    end;

    /// <summary>
    /// FillBestLine.
    /// </summary>
    /// <param name="RentalPriceCalcBuffer">Record "Price Calculation Buffer".</param>
    /// <param name="AmountType">Enum "Price Amount Type".</param>
    /// <param name="PriceListLine">VAR Record "Price List Line".</param>
    procedure FillBestLine(RentalPriceCalcBuffer: Record "TWE Rental Price Calc. Buffer"; AmountType: Enum "Price Amount Type"; var PriceListLine: Record "TWE Rental Price List Line")
    begin
        MainRentalItem.Get(RentalPriceCalcBuffer."Asset No.");
        PriceListLine."VAT Prod. Posting Group" := MainRentalItem."VAT Prod. Posting Group";
        PriceListLine."Unit of Measure Code" := '';
        PriceListLine."Currency Code" := '';
        if AmountType <> AmountType::Discount then
            case RentalPriceCalcBuffer."Price Type" of
                RentalPriceCalcBuffer."Price Type"::Rental:
                    begin
                        PriceListLine."VAT Bus. Posting Gr. (Price)" := MainRentalItem."VAT Bus. Posting Gr. (Price)";
                        PriceListLine."Price Includes VAT" := MainRentalItem."Price Includes VAT";
                        PriceListLine."Unit Price" := MainRentalItem."Unit Price";
                    end;
            end;
        OnAfterFillBestLine(RentalPriceCalcBuffer, AmountType, PriceListLine);
    end;


    /// <summary>
    /// FilterPriceLines.
    /// </summary>
    /// <param name="RentalPriceAsset">Record "TWE Rental Price Asset".</param>
    /// <param name="PriceListLine">VAR Record "TWE Rental Price List Line".</param>
    /// <returns>Return variable Result of type Boolean.</returns>
    procedure FilterPriceLines(RentalPriceAsset: Record "TWE Rental Price Asset"; var PriceListLine: Record "TWE Rental Price List Line") Result: Boolean;
    begin
        PriceListLine.SetRange("Asset Type", RentalPriceAsset."Asset Type");
        PriceListLine.SetRange("Asset No.", RentalPriceAsset."Asset No.");
    end;

    /// <summary>
    /// PutRelatedAssetsToList.
    /// </summary>
    /// <param name="PriceAsset">Record "TWE Rental Price Asset".</param>
    /// <param name="PriceAssetList">VAR Codeunit "Price Asset List".</param>
    procedure PutRelatedAssetsToList(PriceAsset: Record "TWE Rental Price Asset"; var PriceAssetList: Codeunit "TWE Rental Price Asset List")
    begin
        MainRentalItem.Get(PriceAsset."Asset No.");
        if MainRentalItem."Rental Item Disc. Group" <> '' then begin
            PriceAssetList.SetLevel(PriceAsset.Level);
            PriceAssetList.Add(PriceAsset."Asset Type"::"Rental Item Discount Group", MainRentalItem."Rental Item Disc. Group");
        end;
        OnAfterPutRelatedAssetsToList(PriceAsset, PriceAssetList);
    end;

    /// <summary>
    /// FillFromBuffer.
    /// </summary>
    /// <param name="PriceAsset">VAR Record "TWE Rental Price Asset".</param>
    /// <param name="PriceCalculationBuffer">Record "Price Calculation Buffer".</param>
    procedure FillFromBuffer(var PriceAsset: Record "TWE Rental Price Asset"; PriceCalculationBuffer: Record "TWE Rental Price Calc. Buffer")
    begin
        PriceAsset.NewEntry(PriceCalculationBuffer."Asset Type", PriceAsset.Level);
        PriceAsset.Validate("Asset No.", PriceCalculationBuffer."Asset No.");
        PriceAsset.Validate("Variant Code", PriceCalculationBuffer."Variant Code");
        PriceAsset."Unit of Measure Code" := PriceCalculationBuffer."Unit of Measure Code";
    end;

    local procedure FillAdditionalFields(var PriceAsset: Record "TWE Rental Price Asset")
    begin
        PriceAsset."Unit of Measure Code" := GetUnitOfMeasure(PriceAsset."Rental Price Type");
        PriceAsset.Description := MainRentalItem.Description;

        case PriceAsset."Rental Price Type" of
            PriceAsset."Rental Price Type"::Sale:
                begin
                    PriceAsset."Allow Invoice Disc." := MainRentalItem."Allow Invoice Disc.";
                    PriceAsset."Price Includes VAT" := MainRentalItem."Price Includes VAT";
                    PriceAsset."VAT Bus. Posting Gr. (Price)" := MainRentalItem."VAT Bus. Posting Gr. (Price)";

                    PriceAsset."Unit Price" := MainRentalItem."Unit Price";
                end;
            PriceAsset."Rental Price Type"::Purchase:
                PriceAsset."Unit Price" := MainRentalItem."Last Direct Cost";

            PriceAsset."Rental Price Type"::Rental:
                begin
                    PriceAsset."Allow Invoice Disc." := MainRentalItem."Allow Invoice Disc.";
                    PriceAsset."Price Includes VAT" := MainRentalItem."Price Includes VAT";
                    PriceAsset."VAT Bus. Posting Gr. (Price)" := MainRentalItem."VAT Bus. Posting Gr. (Price)";

                    PriceAsset."Unit Price" := MainRentalItem."Unit Price";
                end;
        end;
    end;

    local procedure GetUnitOfMeasure(RentalPriceType: Enum "TWE Rental Price Type"): Code[10]
    begin
        case RentalPriceType of
            RentalPriceType::Any:
                exit(MainRentalItem."Base Unit of Measure");
            RentalPriceType::Purchase:
                exit(MainRentalItem."Purch. Unit of Measure");
            RentalPriceType::Sale:
                exit(MainRentalItem."Sales Unit of Measure");
            RentalPriceType::Rental:
                exit(MainRentalItem."Base Unit of Measure")
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFillBestLine(RentalPriceCalcBuffer: Record "TWE Rental Price Calc. Buffer"; AmountType: Enum "Price Amount Type"; var RentalPriceListLine: Record "TWE Rental Price List Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPutRelatedAssetsToList(PriceAsset: Record "TWE Rental Price Asset"; var PriceAssetList: Codeunit "TWE Rental Price Asset List")
    begin
    end;
}
