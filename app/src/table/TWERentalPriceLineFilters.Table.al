/// <summary>
/// Table TWE Rental Price Line Filters (ID 50022).
/// </summary>
table 50022 "TWE Rental Price Line Filters"
{
#pragma warning disable AS0034
    TableType = Temporary;
#pragma warning restore AS0034

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            DataClassification = SystemMetadata;
        }
        field(2; "Asset Type"; Enum "TWE Rental Price Asset Type")
        {
            Caption = 'Product Type';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            var
                RentalPriceAsset: Record "TWE Rental Price Asset";
            begin
                if not "Copy Lines" then begin
                    if "Asset Type" = "Asset Type"::" " then
                        "Asset Type" := "Asset Type"::"Rental Item";
                    RentalPriceAsset.Validate("Asset Type", "Asset Type");
                    "Table Id" := RentalPriceAsset."Table Id";
                end;
                "Asset Filter" := '';
            end;
        }
        field(3; "Asset Filter"; Text[2048])
        {
            Caption = 'Product Filter';
            DataClassification = SystemMetadata;
        }
        field(4; "Table Id"; Integer)
        {
            Caption = 'Table Id';
            DataClassification = SystemMetadata;
        }
        field(5; "Minimum Quantity"; Decimal)
        {
            Caption = 'Minimum Quantity';
            DataClassification = SystemMetadata;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(6; "Adjustment Factor"; Decimal)
        {
            Caption = 'Adjustment Factor';
            DataClassification = SystemMetadata;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            InitValue = 1;
        }
        field(7; "Rounding Method Code"; Code[10])
        {
            Caption = 'Rounding Method Code';
            DataClassification = SystemMetadata;
            TableRelation = "Rounding Method";
        }
        field(8; "From Price List Code"; Code[20])
        {
            Caption = 'From Price List Code';
            DataClassification = SystemMetadata;
            TableRelation = "Price List Header";

            trigger OnValidate()
            begin
                if "From Price List Code" = "To Price List Code" then
                    Error(SameFromListCodeErr, FieldCaption("From Price List Code"), FieldCaption("To Price List Code"));

                "From Currency Code" := GetCurrencyCode("From Price List Code");
                "Different Currencies" := "To Currency Code" <> "From Currency Code";
            end;
        }
        field(9; "To Price List Code"; Code[20])
        {
            Caption = 'To Price List Code';
            DataClassification = SystemMetadata;
            TableRelation = "Price List Header";
        }
        field(10; "Rental Price Type"; Enum "TWE Rental Price Type")
        {
            Caption = 'Rental Price Type';
            DataClassification = SystemMetadata;
        }
        field(11; "Rental Source Group"; Enum "TWE Rental Price Source Group")
        {
            Caption = 'Applies-to Group';
            DataClassification = SystemMetadata;
        }
        field(12; "Rental Price Line Filter"; Text[2048])
        {
            Caption = 'Price Line Filter';
            DataClassification = SystemMetadata;
        }
        field(13; "From Currency Code"; Code[10])
        {
            Caption = 'From Currency Code';
            DataClassification = SystemMetadata;
        }
        field(14; "To Currency Code"; Code[10])
        {
            Caption = 'To Currency Code';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                InitRoundingPrecision("To Currency Code");
            end;
        }
        field(15; "Amount Rounding Precision"; Decimal)
        {
            Caption = 'Amount Rounding Precision';
            DataClassification = SystemMetadata;
        }
        field(16; "Exchange Rate Date"; Date)
        {
            Caption = 'Exchange Rate Date';
            DataClassification = SystemMetadata;
        }
        field(17; "Different Currencies"; Boolean)
        {
            Caption = 'Different Currencies';
            DataClassification = SystemMetadata;
        }
        field(18; "Copy Lines"; Boolean)
        {
            Caption = 'Copy Price List';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                Validate("Asset Type", "Asset Type"::" ");
                if not "Copy Lines" then
                    "From Price List Code" := '';
                Validate("From Price List Code");
            end;
        }
    }

    keys
    {
        key(PK; "Primary Key")
        { }
    }

    var
        SameFromListCodeErr: Label '%1 must not be the same as %2.', Comment = '%1 and %2 - captions of the fields From Price List Code and To Price List Code';

    /// <summary>
    /// Initialize.
    /// </summary>
    /// <param name="RentalPriceListHeader">Record "TWE Rental Price List Header".</param>
    /// <param name="CopyLines">Boolean.</param>
    procedure Initialize(RentalPriceListHeader: Record "TWE Rental Price List Header"; CopyLines: Boolean)
    var
    begin
        "Rental Price Type" := RentalPriceListHeader."Rental Price Type";
        "Rental Source Group" := RentalPriceListHeader."Rental Source Group";
        "To Price List Code" := RentalPriceListHeader.Code;
        Validate("To Currency Code", RentalPriceListHeader."Currency Code");
        "Exchange Rate Date" := WorkDate();

        Validate("Copy Lines", CopyLines);
    end;

    /// <summary>
    /// EditAssetFilter.
    /// </summary>
    procedure EditAssetFilter()
    var
        ObjectTranslation: Record "Object Translation";
        PrimaryKeyField: Record "Field";
        FilterPageBuilder: FilterPageBuilder;
        TableCaptionValue: Text;
    begin
        TableCaptionValue :=
            ObjectTranslation.TranslateObject(ObjectTranslation."Object Type"::Table, "Table ID");
        FilterPageBuilder.AddTable(TableCaptionValue, "Table ID");
        if GetPrimaryKeyFields("Table Id", PrimaryKeyField) then
            repeat
                FilterPageBuilder.AddFieldNo(TableCaptionValue, PrimaryKeyField."No.")
            until PrimaryKeyField.Next() = 0;
        if "Asset Filter" <> '' then
            FilterPageBuilder.SetView(TableCaptionValue, "Asset Filter");
        if FilterPageBuilder.RunModal() then
            "Asset Filter" :=
                CopyStr(FilterPageBuilder.GetView(TableCaptionValue, false), 1, MaxStrLen("Asset Filter"));
    end;

    /// <summary>
    /// EditPriceLineFilter.
    /// </summary>
    procedure EditPriceLineFilter()
    var
        PriceListLine: Record "Price List Line";
        FilterPageBuilder: FilterPageBuilder;
        TableCaptionValue: Text;
    begin
        TableCaptionValue := PriceListLine.TableCaption();
        FilterPageBuilder.AddTable(TableCaptionValue, Database::"TWE Rental Price List Line");
        FilterPageBuilder.AddFieldNo(TableCaptionValue, PriceListLine.FieldNo("Asset Type"));
        FilterPageBuilder.AddFieldNo(TableCaptionValue, PriceListLine.FieldNo("Asset No."));
        FilterPageBuilder.AddFieldNo(TableCaptionValue, PriceListLine.FieldNo("Amount Type"));
        if "Rental Price Line Filter" <> '' then
            FilterPageBuilder.SetView(TableCaptionValue, "Rental Price Line Filter");
        if FilterPageBuilder.RunModal() then
            "Rental Price Line Filter" :=
                CopyStr(FilterPageBuilder.GetView(TableCaptionValue, false), 1, MaxStrLen("Rental Price Line Filter"));
    end;


    local procedure GetCurrencyCode(PriceListCode: Code[20]): Code[10];
    var
        PriceListHeader: Record "Price List Header";
    begin
        if PriceListCode = '' then
            exit('');
        PriceListHeader.Get(PriceListCode);
        exit(PriceListHeader."Currency Code");
    end;

    local procedure GetPrimaryKeyFields(TableId: Integer; var PrimaryKeyField: Record "Field"): Boolean;
    begin
        PrimaryKeyField.Reset();
        PrimaryKeyField.SetRange(TableNo, TableId);
        PrimaryKeyField.Setrange(IsPartOfPrimaryKey, true);
        exit(PrimaryKeyField.FindSet());
    end;

    local procedure InitRoundingPrecision(CurrencyCode: Code[10])
    var
        Currency: Record Currency;
    begin
        if CurrencyCode = '' then begin
            Currency.Code := '';
            Currency.InitRoundingPrecision();
        end else begin
            Currency.Get(CurrencyCode);
            Currency.TestField("Unit-Amount Rounding Precision");
        end;
        "Amount Rounding Precision" := Currency."Unit-Amount Rounding Precision";
    end;
}
