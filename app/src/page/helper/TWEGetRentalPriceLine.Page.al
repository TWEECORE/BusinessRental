/// <summary>
/// Page TWE Get Rental Price Line (ID 70704688).
/// </summary>
page 50000 "TWE Get Rental Price Line"
{
    Caption = 'Get Rental Price Line';
    Editable = false;
    PageType = List;
    SourceTable = "TWE REntal Price List Line";
    SourceTableTemporary = true;
    DataCaptionExpression = DataCaptionExpr;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Unit Price"; Rec."Unit Price")
                {
                    AccessByPermission = tabledata "Sales Price Access" = R;
                    Visible = PriceVisible;
                    ApplicationArea = All;
                    ToolTip = 'Specifies the price of one unit of the selected rental item.';
                }
                field("Line Discount %"; Rec."Line Discount %")
                {
                    AccessByPermission = tabledata "Sales Discount Access" = R;
                    Visible = DiscountVisible;
                    ApplicationArea = All;
                    ToolTip = 'Specifies the line discount percentage for the rental item.';
                }
                field(PurchLineDiscountPct; Rec."Line Discount %")
                {
                    AccessByPermission = tabledata "Purchase Discount Access" = R;
                    Visible = DiscountVisible;
                    ApplicationArea = All;
                    ToolTip = 'Specifies the line discount percentage for the rental item.';
                }
                field("Direct Unit Cost"; Rec."Direct Unit Cost")
                {
                    AccessByPermission = tabledata "Purchase Price Access" = R;
                    Visible = PriceVisible;
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the cost of one unit of the selected rental item.';
                }
                field("Price List Code"; Rec."Price List Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the unique identifier of the price list.';
                }
                field("Amount Type"; Rec."Amount Type")
                {
                    Visible = false;
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether the price list line defines prices, discounts, or both.';
                }
                field("Source Type"; Rec."Source Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the type of the entity that offers the price or the line discount on the rental item.';
                }
                field("Source No."; Rec."Source No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the unique identifier of the source of the price on the price list line.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the currency code of the price.';
                    Visible = false;
                }
                field("Asset Type"; Rec."Asset Type")
                {
                    Visible = not HideProductControls;
                    ApplicationArea = All;
                    ToolTip = 'Specifies the type of the rental item that the price applies to.';
                }
                field("Asset No."; Rec."Asset No.")
                {
                    Visible = not HideProductControls;
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of the rental item that the price applies to.';
                }
                field("Work Type Code"; Rec."Work Type Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the work type code for the resource.';
                    Visible = WorkTypeCodeVisible;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }
                field("Minimum Quantity"; Rec."Minimum Quantity")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the minimum quantity of the item that you must buy or sale in order to get the price.';
                }
                field("Allow Line Disc."; Rec."Allow Line Disc.")
                {
                    Visible = PriceVisible;
                    ApplicationArea = All;
                    ToolTip = 'Specifies if a line discount will be calculated when the price is offered.';
                }
                field("Allow Invoice Disc."; Rec."Allow Invoice Disc.")
                {
                    Visible = PriceVisible;
                    ApplicationArea = All;
                    ToolTip = 'Specifies if an invoice discount will be calculated when the price is offered.';
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the date from which the price or the line discount is valid.';
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the date to which the price or the line discount is valid.';
                }
            }
        }
    }

    var
        DataCaptionExpr: Text;
        DataCaptionExprTok: Label 'Pick %1 for %2 of %3 %4',
            Comment = '%1 - Price or Discount, %2 - Sale or Purchase, %3 - the rental item type, %4 - the rental item no., e.g. Pick price for sale of Item 1000.';
        DataCaptionAssetTok: Label '%1 %2 %3', Locked = true, Comment = '%1 %2 %3 - rental item Type, rental item No, Description';

    protected var
        AmountType: Enum "Price Amount Type";
        DiscountVisible: Boolean;
        HideProductControls: Boolean;
        WorkTypeCodeVisible: Boolean;
        PriceVisible: Boolean;

    /// <summary>
    /// SetDataCaptionExpr.
    /// </summary>
    /// <param name="RentalPriceAssetList">Codeunit "TWE Rental Price Asset List".</param>
    procedure SetDataCaptionExpr(RentalPriceAssetList: Codeunit "TWE Rental Price Asset List")
    var
        TempRentalPriceAsset: Record "TWE Rental Price Asset" temporary;
        FirstEntryNo: Integer;
    begin
        if RentalPriceAssetList.GetList(TempRentalPriceAsset) then begin
            FirstEntryNo := TempRentalPriceAsset."Entry No.";
            if TempRentalPriceAsset.FindLast() then begin
                TempRentalPriceAsset.ValidateAssetNo();
                DataCaptionExpr :=
                    StrSubstNo(DataCaptionAssetTok,
                        TempRentalPriceAsset."Asset Type", TempRentalPriceAsset."Asset No.", TempRentalPriceAsset.Description);
                HideProductControls := FirstEntryNo = TempRentalPriceAsset."Entry No.";
            end;
        end;
    end;

    /// <summary>
    /// SetForLookup.
    /// </summary>
    /// <param name="RentLineWithPrice">Interface "TWE Rent Line With Price".</param>
    /// <param name="NewAmountType">Enum "Price Amount Type".</param>
    /// <param name="TempRentalPriceListLine">Temporary VAR Record "TWE Rental Price List Line".</param>
    procedure SetForLookup(RentLineWithPrice: Interface "TWE Rent Line With Price"; NewAmountType: Enum "Price Amount Type"; var TempRentalPriceListLine: Record "TWE Rental Price List Line" temporary)
    var
        AssetType: Enum "TWE Rental Price Asset Type";
        PriceType: Enum "TWE Rental Price Type";
    begin
        CurrPage.LookupMode(true);
        Rec.Copy(TempRentalPriceListLine, true);
        AmountType := NewAmountType;
        AssetType := RentLineWithPrice.GetAssetType();
        PriceType := RentLineWithPrice.GetPriceType();
        if DataCaptionExpr = '' then
            DataCaptionExpr := StrSubstNo(DataCaptionExprTok, AmountType, PriceType, AssetType, Rec."Asset No.");
        PriceVisible := AmountType in [AmountType::Price, AmountType::Any];
        DiscountVisible := AmountType in [AmountType::Discount, AmountType::Any];
        WorkTypeCodeVisible := AssetType = AssetType::Resource;
    end;
}

