/// <summary>
/// Page TWE Rental Price List Lines (ID 50013).
/// </summary>
page 50013 "TWE Rental Price List Lines"
{
    AutoSplitKey = true;
    Caption = 'Lines';
    DelayedInsert = true;
    LinksAllowed = false;
    MultipleNewLines = true;
    PageType = ListPart;
    SourceTable = "TWE Rental Price List Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(SourceType; CustomerSourceType)
                {
                    ApplicationArea = All;
                    Caption = 'Applies-to Type';
                    Visible = IsCustomerGroup and AllowUpdatingDefaults;
                    ToolTip = 'Specifies the source of the price on the price list line. For example, the price can come from the customer or customer price group.';

                    trigger OnValidate()
                    begin
                        ValidateSourceType(CustomerSourceType.AsInteger());
                    end;
                }
                field(JobSourceType; JobSourceType)
                {
                    ApplicationArea = All;
                    Caption = 'Applies-to Type';
                    Visible = IsJobGroup and AllowUpdatingDefaults;
                    ToolTip = 'Specifies the source of the price on the price list line. For example, the price can come from the job or job task.';

                    trigger OnValidate()
                    begin
                        ValidateSourceType(JobSourceType.AsInteger());
                    end;
                }
                field(ParentSourceNo; Rec."Parent Source No.")
                {
                    ApplicationArea = All;
                    Caption = 'Applies-to Job No.';
                    Importance = Promoted;
                    Editable = IsJobTask;
                    Visible = AllowUpdatingDefaults and IsJobGroup;
                    ToolTip = 'Specifies the job that is the source of the price on the price list line.';
                }
                field(SourceNo; Rec."Source No.")
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                    Enabled = SourceNoEnabled;
                    Visible = AllowUpdatingDefaults;
                    ToolTip = 'Specifies the unique identifier of the source of the price on the price list line.';
                }
                field(CurrencyCode; Rec."Currency Code")
                {
                    ApplicationArea = All;
                    Visible = AllowUpdatingDefaults;
                    ToolTip = 'Specifies the currency that is used for the prices on the price list. The currency can be the same for all prices on the price list, or you can specify a currency for individual lines.';
                }
                field(StartingDate; Rec."Starting Date")
                {
                    ApplicationArea = All;
                    Visible = AllowUpdatingDefaults;
                    ToolTip = 'Specifies the date from which the price is valid.';
                }
                field(EndingDate; Rec."Ending Date")
                {
                    ApplicationArea = All;
                    Visible = AllowUpdatingDefaults;
                    ToolTip = 'Specifies the last date that the price is valid.';
                }
                field("Asset Type"; Rec."Asset Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the type of the product.';
                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
                field("Asset No."; Rec."Asset No.")
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the number of the product.';
                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description of the product.';
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = All;
                    Enabled = ItemAsset;
                    Editable = ItemAsset;
                    ToolTip = 'Specifies the item variant.';
                }
                field("Work Type Code"; Rec."Work Type Code")
                {
                    ApplicationArea = All;
                    Enabled = ResourceAsset;
                    Editable = ResourceAsset;
                    ToolTip = 'Specifies the work type code for the resource.';
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = All;
                    Enabled = UOMEditable;
                    Editable = UOMEditable;
                    ToolTip = 'Specifies the unit of measure for the product.';
                }
                field("Minimum Quantity"; Rec."Minimum Quantity")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the minimum quantity of the product.';
                }
                field("Amount Type"; Rec."Amount Type")
                {
                    ApplicationArea = All;
                    Importance = Standard;
                    Visible = AmountTypeIsVisible;
                    Editable = AmountTypeIsEditable;
                    ToolTip = 'Specifies whether the price list line defines prices, discounts, or both.';
                    trigger OnValidate()
                    begin
                        SetMandatoryAmount();
                    end;
                }
                field("Unit Price"; Rec."Unit Price")
                {
                    AccessByPermission = tabledata "Sales Price Access" = R;
                    ApplicationArea = All;
                    Editable = AmountEditable;
                    Enabled = PriceMandatory;
                    Visible = PriceVisible;
                    Style = Subordinate;
                    StyleExpr = not PriceMandatory;
                    ToolTip = 'Specifies the unit price of the product.';
                }
                field("Cost Factor"; Rec."Cost Factor")
                {
                    AccessByPermission = tabledata "Sales Price Access" = R;
                    ApplicationArea = All;
                    Editable = AmountEditable;
                    Enabled = PriceMandatory;
                    Visible = PriceVisible;
                    Style = Subordinate;
                    StyleExpr = not PriceMandatory;
                    ToolTip = 'Specifies the unit cost factor, if you have agreed with your customer that he should pay certain item usage by cost value plus a certain percent value to cover your overhead expenses.';
                }

                field("Allow Line Disc."; Rec."Allow Line Disc.")
                {
                    ApplicationArea = All;
                    Visible = PriceVisible;
                    Enabled = PriceMandatory;
                    Editable = PriceMandatory;
                    Style = Subordinate;
                    StyleExpr = not PriceMandatory;
                    ToolTip = 'Specifies if a line discount will be calculated when the price is offered.';
                }
                field("Line Discount %"; Rec."Line Discount %")
                {
                    AccessByPermission = tabledata "Sales Discount Access" = R;
                    ApplicationArea = All;
                    Visible = DiscountVisible;
                    Enabled = DiscountMandatory;
                    Editable = DiscountMandatory;
                    Style = Subordinate;
                    StyleExpr = not DiscountMandatory;
                    ToolTip = 'Specifies the line discount percentage for the product.';
                }
                field("Allow Invoice Disc."; Rec."Allow Invoice Disc.")
                {
                    ApplicationArea = All;
                    Visible = PriceVisible;
                    Enabled = PriceMandatory;
                    Editable = PriceMandatory;
                    Style = Subordinate;
                    StyleExpr = not PriceMandatory;
                    ToolTip = 'Specifies if an invoice discount will be calculated when the price is offered.';
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        UpdateSourceType();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        UpdateSourceType();
        SetEditable();
        SetMandatoryAmount();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        if RentalPriceListHeader."Allow Updating Defaults" then begin
            Rec.CopySourceFrom(RentalPriceListHeader);
            if Rec."Starting Date" = 0D then
                Rec."Starting Date" := RentalPriceListHeader."Starting Date";
            if Rec."Ending Date" = 0D then
                Rec."Ending Date" := RentalPriceListHeader."Ending Date";
            if Rec."Currency Code" = '' then
                Rec."Currency Code" := RentalPriceListHeader."Currency Code";
        end;
        UpdateSourceType();
        Rec."Amount Type" := ViewAmountType;
    end;

    var
        AmountEditable: Boolean;
        UOMEditable: Boolean;
        ItemAsset: Boolean;
        ResourceAsset: Boolean;
        DiscountMandatory: Boolean;
        DiscountVisible: Boolean;
        PriceMandatory: Boolean;
        PriceVisible: Boolean;
        AmountTypeIsVisible: Boolean;
        AmountTypeIsEditable: Boolean;
        JobSourceType: Enum "Job Price Source Type";
        CustomerSourceType: Enum "TWE Rental Price Source Type";
        IsCustomerGroup: Boolean;
        IsJobGroup: Boolean;
        IsJobTask: Boolean;
        SourceNoEnabled: Boolean;
        AllowUpdatingDefaults: Boolean;

    protected var
        RentalPriceListHeader: Record "TWE Rental Price List Header";
        RentalPriceType: Enum "TWE Rental Price Type";
        ViewAmountType: Enum "Price Amount Type";

    local procedure SetEditable()
    begin
        AmountTypeIsEditable := Rec."Asset Type" <> Rec."Asset Type"::"Rental Item Discount Group";
        AmountEditable := Rec.IsAmountSupported();
        UOMEditable := Rec.IsUOMSupported();
        ItemAsset := Rec.IsAssetItem();
        ResourceAsset := Rec.IsAssetResource();
    end;

    local procedure SetMandatoryAmount()
    begin
        DiscountMandatory := Rec.IsAmountMandatory(Rec."Amount Type"::Discount);
        PriceMandatory := Rec.IsAmountMandatory(Rec."Amount Type"::Price);
    end;

    local procedure UpdateColumnVisibility()
    begin
        AllowUpdatingDefaults := RentalPriceListHeader."Allow Updating Defaults";
        AmountTypeIsVisible := ViewAmountType = ViewAmountType::Any;
        DiscountVisible := ViewAmountType in [ViewAmountType::Any, ViewAmountType::Discount];
        PriceVisible := ViewAmountType in [ViewAmountType::Any, ViewAmountType::Price];
    end;

    /// <summary>
    /// SetHeader.
    /// </summary>
    /// <param name="Header">Record "TWE Rental Price List Header".</param>
    procedure SetHeader(Header: Record "TWE Rental Price List Header")
    begin
        RentalPriceListHeader := Header;

        SetSubFormLinkFilter(RentalPriceListHeader."Amount Type");
    end;

    /// <summary>
    /// SetPriceType.
    /// </summary>
    /// <param name="NewPriceType">Enum "TWE Rental Price Type".</param>
    procedure SetPriceType(NewPriceType: Enum "TWE Rental Price Type")
    begin
        RentalPriceType := NewPriceType;
        RentalPriceListHeader."Rental Price Type" := NewPriceType;
    end;

    /// <summary>
    /// SetSubFormLinkFilter.
    /// </summary>
    /// <param name="NewViewAmountType">Enum "Price Amount Type".</param>
    procedure SetSubFormLinkFilter(NewViewAmountType: Enum "Price Amount Type")
    var
        RentalPriceListLine: Record "TWE Rental Price List Line";
        SkipActivate: Boolean;
    begin
        ViewAmountType := NewViewAmountType;
        if ViewAmountType = ViewAmountType::Any then
            RentalPriceListLine.SetRange("Amount Type")
        else
            RentalPriceListLine.SetFilter("Amount Type", '%1|%2', ViewAmountType, ViewAmountType::Any);
        CurrPage.SetTableView(RentalPriceListLine);
        UpdateColumnVisibility();
        CurrPage.Update(false);
        OnAfterSetSubFormLinkFilter(SkipActivate);
        if not SkipActivate then
            CurrPage.Activate(true);
    end;

    local procedure UpdateSourceType()
    begin
        case RentalPriceListHeader."Rental Source Group" of
            "TWE Rental Price Source Group"::Customer:
                begin
                    IsCustomerGroup := true;
                    CustomerSourceType := "TWE Rental Price Source Type".FromInteger(Rec."Source Type".AsInteger());
                end;
        end;
    end;

    local procedure SetSourceNoEnabled()
    begin
        SourceNoEnabled := Rec.IsSourceNoAllowed();
    end;

    local procedure ValidateSourceType(SourceType: Integer)
    begin
        Rec.Validate("Source Type", SourceType);
        SetSourceNoEnabled();
        CurrPage.Update(true);
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterSetSubFormLinkFilter(var SkipActivate: Boolean)
    begin
    end;
}
