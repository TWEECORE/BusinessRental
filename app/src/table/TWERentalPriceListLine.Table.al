/// <summary>
/// Table TWE Rental Price List Line (ID 50024).
/// </summary>
table 50024 "TWE Rental Price List Line"
{
    fields
    {
        field(1; "Price List Code"; Code[20])
        {
            DataClassification = CustomerContent;
            TableRelation = "TWE Rental Price List Header";
        }
        field(2; "Line No."; Integer)
        {
            DataClassification = CustomerContent;
            AutoIncrement = true;
        }
        field(3; "Source Type"; Enum "TWE Rental Price Source Type")
        {
            Caption = 'Applies-to Type';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                TestHeadersValue(FieldNo("Source Type"));
                CopyRecTo(PriceSource);
                PriceSource.Validate("Source Type", "Source Type");
                CopyFrom(PriceSource);
                if "Asset No." <> '' then begin
                    CopyTo(PriceAsset);
                    PriceAsset.ValidateAssetNo();
                    CopyFrom(PriceAsset);
                end;
            end;
        }
        field(4; "Source No."; Code[20])
        {
            Caption = 'Applies-to No.';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                TestHeadersValue(FieldNo("Source No."));
                CopyRecTo(PriceSource);
                PriceSource.Validate("Source No.", "Source No.");
                CopyFrom(PriceSource);
            end;

            trigger OnLookup()
            begin
                CopyTo(PriceSource);
                if PriceSource.LookupNo() then begin
                    TestHeadersValue(FieldNo("Source No."));
                    CopyFrom(PriceSource);
                end;
            end;
        }
        field(5; "Parent Source No."; Code[20])
        {
            Caption = 'Applies-to Parent No.';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                TestHeadersValue(FieldNo("Parent Source No."));
                CopyRecTo(PriceSource);
                PriceSource.Validate("Parent Source No.", "Parent Source No.");
                CopyFrom(PriceSource);
            end;

            trigger OnLookup()
            var
                JobPriceSource: Record "Price Source";
            begin
                if "Source Type" <> "Source Type"::"Job Task" then
                    exit;

                JobPriceSource."Source Group" := JobPriceSource."Source Group"::Job;
                JobPriceSource."Source Type" := "Price Source Type"::Job;
                if JobPriceSource.LookupNo() then begin
                    "Parent Source No." := JobPriceSource."Source No.";
                    "Source No." := '';
                    TestHeadersValue(FieldNo("Parent Source No."));
                end;
            end;
        }
        field(6; "Source ID"; Guid)
        {
            Caption = 'Applies-to ID';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                TestHeadersValue(FieldNo("Source ID"));
                CopyRecTo(PriceSource);
                PriceSource.Validate("Source ID", "Source ID");
                CopyFrom(PriceSource);
            end;
        }
        field(7; "Asset Type"; Enum "TWE Rental Price Asset Type")
        {
            Caption = 'Product Type';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                CopyRecTo(PriceAsset);
                PriceAsset.Validate("Asset Type", "Asset Type");
                CopyFrom(PriceAsset);

                InitHeaderDefaults();
                TestStatusDraft();

                if "Asset Type" = "Asset Type"::"Rental Item Discount Group" then
                    Validate("Amount Type", "Amount Type"::Discount);
            end;
        }
        field(8; "Asset No."; Code[20])
        {
            Caption = 'Product No.';
            DataClassification = CustomerContent;
            NotBlank = true;

            trigger OnValidate()
            begin
                TestStatusDraft();
                CopyRecTo(PriceAsset);
                PriceAsset.Validate("Asset No.", "Asset No.");
                CopyFrom(PriceAsset);
            end;

            trigger OnLookup()
            begin
                CopyTo(PriceAsset);
                if PriceAsset.LookupNo() then begin
                    TestStatusDraft();
                    CopyFrom(PriceAsset);
                end;
            end;
        }
        field(9; "Variant Code"; Code[10])
        {
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                TestStatusDraft();
                CopyRecTo(PriceAsset);
                PriceAsset.Validate("Variant Code", "Variant Code");
                CopyFrom(PriceAsset);
            end;

            trigger OnLookup()
            begin
                CopyTo(PriceAsset);
                if PriceAsset.LookupVariantCode() then begin
                    TestStatusDraft();
                    CopyFrom(PriceAsset);
                end;
            end;
        }
        field(10; "Currency Code"; Code[10])
        {
            DataClassification = CustomerContent;
            TableRelation = Currency;

            trigger OnValidate()
            begin
                if "Currency Code" = xRec."Currency Code" then
                    exit;
                TestHeadersValue(FieldNo("Currency Code"));
            end;
        }
        field(11; "Work Type Code"; Code[10])
        {
            DataClassification = CustomerContent;
            TableRelation = "Work Type";
            trigger OnValidate()
            begin
                TestStatusDraft();
                CopyRecTo(PriceAsset);
                PriceAsset.Validate("Work Type Code", "Work Type Code");
                CopyFrom(PriceAsset);
            end;
        }
        field(12; "Starting Date"; Date)
        {
            DataClassification = CustomerContent;
            trigger OnValidate()
            begin
                TestHeadersValue(FieldNo("Starting Date"));
                CopyRecTo(PriceSource);
                PriceSource.Validate("Starting Date", "Starting Date");
                CopyFrom(PriceSource);
            end;
        }
        field(13; "Ending Date"; Date)
        {
            DataClassification = CustomerContent;
            trigger OnValidate()
            begin
                TestHeadersValue(FieldNo("Ending Date"));
                CopyRecTo(PriceSource);
                PriceSource.Validate("Ending Date", "Ending Date");
                CopyFrom(PriceSource);
            end;
        }
        field(14; "Minimum Quantity"; Decimal)
        {
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                TestStatusDraft();
            end;
        }
        field(15; "Unit of Measure Code"; Code[10])
        {
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                TestStatusDraft();
                CopyRecTo(PriceAsset);
                PriceAsset.Validate("Unit of Measure Code", "Unit of Measure Code");
                CopyFrom(PriceAsset);
            end;

            trigger OnLookup()
            begin
                CopyTo(PriceAsset);
                if PriceAsset.LookupUnitofMeasure() then begin
                    TestStatusDraft();
                    "Unit of Measure Code" := PriceAsset."Unit of Measure Code";
                end;
            end;
        }
        field(16; "Amount Type"; Enum "Price Amount Type")
        {
            Caption = 'Defines';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if "Amount Type" = xRec."Amount Type" then
                    exit;

                TestStatusDraft();
                if "Asset Type" = "Asset Type"::"Rental Item Discount Group" then
                    TestField("Amount Type", "Amount Type"::Discount);

                case "Amount Type" of
                    "Amount Type"::Price:
                        begin
                            "Line Discount %" := 0;
                            GetValueFromHeader(FieldNo("Allow Invoice Disc."));
                            GetValueFromHeader(FieldNo("Allow Line Disc."));
                        end;
                    "Amount Type"::Discount:
                        begin
                            "Unit Price" := 0;
                            "Cost Factor" := 0;
                            "Allow Invoice Disc." := false;
                            "Allow Line Disc." := false;
                        end;
                end;
            end;
        }
        field(17; "Unit Price"; Decimal)
        {
            AccessByPermission = tabledata "Sales Price Access" = R;
            DataClassification = CustomerContent;
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 2;
            Caption = 'Unit Price';
            MinValue = 0;

            trigger OnValidate()
            begin
                TestStatusDraft();
                CheckAmountType(FieldCaption("Unit Price"), "Amount Type"::Discount);
                if "Unit Price" <> 0 then
                    "Cost Factor" := 0;
            end;
        }
        field(18; "Cost Factor"; Decimal)
        {
            AccessByPermission = tabledata "Sales Price Access" = R;
            DataClassification = CustomerContent;
            Caption = 'Cost Factor';

            trigger OnValidate()
            begin
                TestStatusDraft();
                CheckAmountType(FieldCaption("Cost Factor"), "Amount Type"::Discount);
                if "Cost Factor" <> 0 then
                    "Unit Price" := 0;
            end;
        }
        field(19; "Unit Cost"; Decimal)
        {
            AccessByPermission = tabledata "Purchase Price Access" = R;
            DataClassification = CustomerContent;
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 2;
            Caption = 'Unit Cost';
            MinValue = 0;
        }
        field(20; "Line Discount %"; Decimal)
        {
            DataClassification = CustomerContent;
            AutoFormatType = 2;
            Caption = 'Line Discount %';
            MaxValue = 100;
            MinValue = 0;

            trigger OnValidate()
            begin
                TestStatusDraft();
                CheckAmountType(FieldCaption("Line Discount %"), "Amount Type"::Price);
            end;
        }
        field(21; "Allow Line Disc."; Boolean)
        {
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                TestStatusDraft();
                CheckAmountType(FieldCaption("Allow Line Disc."), "Amount Type"::Discount);
            end;
        }
        field(22; "Allow Invoice Disc."; Boolean)
        {
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                TestStatusDraft();
                CheckAmountType(FieldCaption("Allow Invoice Disc."), "Amount Type"::Discount);
            end;
        }
        field(23; "Price Includes VAT"; Boolean)
        {
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                TestHeadersValue(FieldNo("Price Includes VAT"));
            end;
        }
        field(24; "VAT Bus. Posting Gr. (Price)"; Code[20])
        {
            DataClassification = CustomerContent;
            TableRelation = "VAT Business Posting Group";

            trigger OnValidate()
            begin
                TestHeadersValue(FieldNo("VAT Bus. Posting Gr. (Price)"));
            end;
        }
        field(25; "VAT Prod. Posting Group"; Code[20])
        {
            DataClassification = CustomerContent;
            TableRelation = "VAT Product Posting Group";

            trigger OnValidate()
            begin
                TestStatusDraft();
            end;
        }
        field(26; "Asset ID"; Guid)
        {
            DataClassification = CustomerContent;
            trigger OnValidate()
            begin
                TestStatusDraft();
                CopyRecTo(PriceAsset);
                PriceAsset.Validate("Asset ID", "Asset ID");
                CopyFrom(PriceAsset);
            end;
        }
        field(27; "Line Amount"; Decimal)
        {
            DataClassification = CustomerContent;
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 2;
            Caption = 'Line Amount';
            MinValue = 0;
            Editable = false;
        }
        field(28; "Price Type"; Enum "TWE Rental Price Type")
        {
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                TestHeadersValue(FieldNo("Price Type"));
            end;
        }
        field(29; Description; Text[100])
        {
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                TestStatusDraft();
            end;
        }
        field(30; Status; Enum "Price Status")
        {
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                TestHeadersValue(FieldNo(Status));
            end;
        }
        field(31; "Direct Unit Cost"; Decimal)
        {
            AccessByPermission = tabledata "Purchase Price Access" = R;
            DataClassification = CustomerContent;
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 2;
            Caption = 'Direct Unit Cost';
            MinValue = 0;
        }
    }

    keys
    {
        key(PK; "Price List Code", "Line No.")
        {
            Clustered = true;
        }
        key(Key1; "Asset Type", "Asset No.", "Source Type", "Source No.", "Starting Date", "Currency Code", "Variant Code", "Unit of Measure Code", "Minimum Quantity")
        {
        }
        key(Key2; "Source Type", "Source No.", "Asset Type", "Asset No.", "Starting Date", "Currency Code", "Variant Code", "Unit of Measure Code", "Minimum Quantity")
        {
        }
        key(Key3; Status, "Price Type", "Amount Type", "Currency Code", "Unit of Measure Code", "Source Type", "Source No.", "Asset Type", "Asset No.", "Variant Code", "Starting Date", "Ending Date", "Minimum Quantity")
        {
        }
        key(Key4; Status, "Price Type", "Amount Type", "Currency Code", "Unit of Measure Code", "Source Type", "Parent Source No.", "Source No.", "Asset Type", "Asset No.", "Work Type Code", "Starting Date", "Ending Date", "Minimum Quantity")
        {
        }
    }

    trigger OnDelete()
    begin
        if Status = Status::Active then
            Error(CannotDeleteActivePriceListLineErr, "Price List Code", "Line No.");
    end;

    protected var
        RentalPriceListHeader: Record "TWE Rental Price List Header";
        PriceAsset: Record "TWE Rental Price Asset";
        PriceSource: Record "TWE Rental Price Source";

    var
        IsNewRecord: Boolean;
        FieldNotAllowedForAmountTypeErr: Label 'Field %1 is not allowed in the price list line where %2 is %3.',
            Comment = '%1 - the field caption; %2 - Amount Type field caption; %3 - amount type value: Discount or Price';
        LineSourceTypeErr: Label 'cannot be set to %1 if the header''s source type is %2.', Comment = '%1 and %2 - the source type value.';
        CannotDeleteActivePriceListLineErr: Label 'You cannot delete the active price list line %1 %2.', Comment = '%1 - the price list code, %2 - line no';

    /// <summary>
    /// IsAssetItem.
    /// </summary>
    /// <returns>Return value of type Boolean.</returns>
    procedure IsAssetItem(): Boolean;
    begin
        exit("Asset Type" = "Asset Type"::"Rental Item");
    end;

    /// <summary>
    /// IsAssetResource.
    /// </summary>
    /// <returns>Return value of type Boolean.</returns>
    procedure IsAssetResource(): Boolean;
    begin
        exit("Asset Type" = "TWE Rental Price Asset Type"::Resource);
    end;

    /// <summary>
    /// IsEditable.
    /// </summary>
    /// <returns>Return variable Result of type Boolean.</returns>
    procedure IsEditable() Result: Boolean;
    begin
        Result := Status = Status::Draft;
    end;

    /// <summary>
    /// IsUOMSupported.
    /// </summary>
    /// <returns>Return value of type Boolean.</returns>
    procedure IsUOMSupported(): Boolean;
    begin
        exit(IsAssetItem() or IsAssetResource());
    end;

    /// <summary>
    /// IsAmountMandatory.
    /// </summary>
    /// <param name="AmountType">enum "Price Amount Type".</param>
    /// <returns>Return value of type Boolean.</returns>
    procedure IsAmountMandatory(AmountType: enum "Price Amount Type"): Boolean;
    begin
        case "Amount Type" of
            "Amount Type"::Any:
                exit(true)
            else
                exit(AmountType = "Amount Type");
        end;
    end;

    /// <summary>
    /// IsAmountSupported.
    /// </summary>
    /// <returns>Return value of type Boolean.</returns>
    procedure IsAmountSupported(): Boolean;
    begin
        exit("Asset Type" <> "Asset Type"::"Rental Item Discount Group");
    end;

    procedure IsRealLine(): Boolean;
    begin
        exit("Line No." <> 0);
    end;

    /// <summary>
    /// IsSourceNoAllowed.
    /// </summary>
    /// <returns>Return value of type Boolean.</returns>
    procedure IsSourceNoAllowed(): Boolean;
    var
        PriceSourceInterface: Interface "TWE Rental Price Source";
    begin
        PriceSourceInterface := "Source Type";
        exit(PriceSourceInterface.IsSourceNoAllowed());
    end;

    local procedure CheckAmountType(FldCaption: Text; AmountType: Enum "Price Amount Type")
    begin
        if "Amount Type" = AmountType then
            Error(FieldNotAllowedForAmountTypeErr, FldCaption, FieldCaption("Amount Type"), Format("Amount Type"));
    end;

    /// <summary>
    /// CopySourceFrom.
    /// </summary>
    /// <param name="RentalPriceListHeader">Record "TWE Rental Price List Header".</param>
    procedure CopySourceFrom(RentalPriceListHeader: Record "TWE Rental Price List Header")
    begin
        "Source Type" := RentalPriceListHeader."Rental Source Type";
        "Parent Source No." := RentalPriceListHeader."Parent Source No.";
        "Source No." := RentalPriceListHeader."Source No.";
        "Source ID" := RentalPriceListHeader."Source ID";
    end;

    /// <summary>
    /// CopyFrom.
    /// </summary>
    /// <param name="RentalPriceListHeader">Record "TWE Rental Price List Header".</param>
    procedure CopyFrom(RentalPriceListHeader: Record "TWE Rental Price List Header")
    begin
        "Price Type" := RentalPriceListHeader."Rental Price Type";
        Status := RentalPriceListHeader.Status;
        if not RentalPriceListHeader."Allow Updating Defaults" then begin
            CopySourceFrom(RentalPriceListHeader);
            "Starting Date" := RentalPriceListHeader."Starting Date";
            "Ending Date" := RentalPriceListHeader."Ending Date";
            "Currency Code" := RentalPriceListHeader."Currency Code";
        end;
        if RentalPriceListHeader."Amount Type" <> "Price Amount Type"::Any then
            Validate("Amount Type", RentalPriceListHeader."Amount Type");

        "Price Includes VAT" := RentalPriceListHeader."Price Includes VAT";
        "VAT Bus. Posting Gr. (Price)" := RentalPriceListHeader."VAT Bus. Posting Gr. (Price)";
        "Allow Invoice Disc." := RentalPriceListHeader."Allow Invoice Disc.";
        "Allow Line Disc." := RentalPriceListHeader."Allow Line Disc.";
        OnAfterCopyFromPriceListHeader(RentalPriceListHeader);
    end;

    local procedure CopyFrom(RentalPriceSource: Record "TWE Rental Price Source")
    begin
        "Price Type" := RentalPriceSource."Price Type";
        "Source Type" := RentalPriceSource."Source Type";
        "Source No." := RentalPriceSource."Source No.";
        "Parent Source No." := RentalPriceSource."Parent Source No.";
        "Source ID" := RentalPriceSource."Source ID";

        "Currency Code" := RentalPriceSource."Currency Code";
        "Price Includes VAT" := RentalPriceSource."Price Includes VAT";
        "Allow Invoice Disc." := RentalPriceSource."Allow Invoice Disc.";
        "Allow Line Disc." := RentalPriceSource."Allow Line Disc.";
        "VAT Bus. Posting Gr. (Price)" := RentalPriceSource."VAT Bus. Posting Gr. (Price)";
        "Starting Date" := RentalPriceSource."Starting Date";
        "Ending Date" := RentalPriceSource."Ending Date";
        OnAfterCopyFromPriceSource(RentalPriceSource);
    end;

    /// <summary>
    /// CopyFrom.
    /// </summary>
    /// <param name="PriceAsset">Record "TWE Rental Price Asset".</param>
    procedure CopyFrom(PriceAsset: Record "TWE Rental Price Asset")
    begin
        "Price Type" := PriceAsset."Rental Price Type";
        "Asset Type" := PriceAsset."Asset Type";
        "Asset No." := PriceAsset."Asset No.";
        "Asset ID" := PriceAsset."Asset ID";
        Description := PriceAsset.Description;
        "Unit of Measure Code" := PriceAsset."Unit of Measure Code";
        "Variant Code" := PriceAsset."Variant Code";
        "Work Type Code" := PriceAsset."Work Type Code";

        "Allow Invoice Disc." := PriceAsset."Allow Invoice Disc.";
        if "VAT Bus. Posting Gr. (Price)" = '' then begin
            "Price Includes VAT" := PriceAsset."Price Includes VAT";
            "VAT Bus. Posting Gr. (Price)" := PriceAsset."VAT Bus. Posting Gr. (Price)";
        end;
        OnAfterCopyFromPriceAsset(PriceAsset);
    end;

    procedure SetNewRecord(NewRecord: Boolean)
    begin
        IsNewRecord := NewRecord;
    end;

    local procedure CopyRecTo(var PriceAsset: Record "TWE Rental Price Asset")
    begin
        if IsNewRecord then
            CopyTo(PriceAsset)
        else
            xRec.CopyTo(PriceAsset);
    end;

    local procedure CopyRecTo(var PriceSource: Record "TWE Rental Price Source")
    begin
        if IsNewRecord then
            CopyTo(PriceSource)
        else
            xRec.CopyTo(PriceSource);
    end;

    /// <summary>
    /// CopyTo.
    /// </summary>
    /// <param name="PriceAsset">VAR Record "Price Asset".</param>
    procedure CopyTo(var PriceAsset: Record "TWE Rental Price Asset")
    begin
        PriceAsset."Rental Price Type" := "Price Type";
        PriceAsset."Asset Type" := "Asset Type";
        PriceAsset."Asset No." := "Asset No.";
        PriceAsset.Description := Description;
        PriceAsset."Asset ID" := "Asset ID";
        PriceAsset."Unit of Measure Code" := "Unit of Measure Code";
        PriceAsset."Variant Code" := "Variant Code";
        PriceAsset."Work Type Code" := "Work Type Code";

        PriceAsset."Allow Invoice Disc." := "Allow Invoice Disc.";
        PriceAsset."Price Includes VAT" := "Price Includes VAT";
        PriceAsset."VAT Bus. Posting Gr. (Price)" := "VAT Bus. Posting Gr. (Price)";
        OnAfterCopyToPriceAsset(PriceAsset);
    end;

    /// <summary>
    /// CopyTo.
    /// </summary>
    /// <param name="PriceSource">VAR Record "Price Source".</param>
    procedure CopyTo(var PriceSource: Record "TWE Rental Price Source")
    begin
        PriceSource."Price Type" := "Price Type";
        PriceSource.Validate("Source Type", "Source Type");
        PriceSource."Parent Source No." := "Parent Source No.";
        PriceSource."Source No." := "Source No.";
        PriceSource."Source ID" := "Source ID";

        PriceSource."Currency Code" := "Currency Code";
        PriceSource."Price Includes VAT" := "Price Includes VAT";
        PriceSource."Allow Invoice Disc." := "Allow Invoice Disc.";
        PriceSource."Allow Line Disc." := "Allow Line Disc.";
        PriceSource."VAT Bus. Posting Gr. (Price)" := "VAT Bus. Posting Gr. (Price)";
        PriceSource."Starting Date" := "Starting Date";
        PriceSource."Ending Date" := "Ending Date";
        OnAfterCopyToPriceSource(PriceSource);
    end;

    /// <summary>
    /// CopyFilteredLinesToTemporaryBuffer.
    /// </summary>
    /// <param name="TempPriceListLine">Temporary VAR Record "Price List Line".</param>
    /// <returns>Return variable Copied of type Boolean.</returns>
    procedure CopyFilteredLinesToTemporaryBuffer(var TempPriceListLine: Record "TWE Rental Price List Line" temporary) Copied: Boolean;
    begin
        if FindSet() then
            repeat
                TempPriceListLine := Rec;
                if TempPriceListLine.Insert() then
                    Copied := true;
            until Next() = 0;
    end;

    local procedure GetHeader(): Boolean;
    begin
        if "Price List Code" <> '' then begin
            if RentalPriceListHeader.Code <> "Price List Code" then
                exit(RentalPriceListHeader.Get("Price List Code"));
            exit(true);
        end;

        Clear(RentalPriceListHeader);
    end;

    local procedure GetValueFromHeader(FieldId: Integer)
    begin
        if not GetHeader() then
            exit;
        case FieldId of
            FieldNo("Allow Invoice Disc."):
                "Allow Invoice Disc." := RentalPriceListHeader."Allow Invoice Disc.";
            FieldNo("Allow Line Disc."):
                "Allow Line Disc." := RentalPriceListHeader."Allow Line Disc.";
        end;
    end;

    local procedure InitHeaderDefaults()
    begin
        if GetHeader() then
            CopyFrom(RentalPriceListHeader);

        OnAfterInitHeaderDefaults(RentalPriceListHeader);
    end;

    local procedure IsSourceTypeSupported(): Boolean;
    var
        RentalPriceSourceGroup: Interface "TWE Rental Price Source Group";
    begin
        RentalPriceSourceGroup := RentalPriceListHeader."Rental Source Group";
        exit(RentalPriceSourceGroup.IsSourceTypeSupported("Source Type"));
    end;

    local procedure TestHeadersValue(FieldId: Integer)
    var
        LineSourceTypeError: Text;
    begin
        if not GetHeader() then
            exit;

        TestStatusDraft();
        case FieldId of
            FieldNo(Status):
                TestField(Status, RentalPriceListHeader.Status);
            FieldNo("Price Includes VAT"):
                TestField("Price Includes VAT", RentalPriceListHeader."Price Includes VAT");
            FieldNo("VAT Bus. Posting Gr. (Price)"):
                TestField("VAT Bus. Posting Gr. (Price)", RentalPriceListHeader."VAT Bus. Posting Gr. (Price)");
        end;
        if not RentalPriceListHeader."Allow Updating Defaults" then
            case FieldId of
                FieldNo("Currency Code"):
                    TestField("Currency Code", RentalPriceListHeader."Currency Code");
                FieldNo("Starting Date"):
                    TestField("Starting Date", RentalPriceListHeader."Starting Date");
                FieldNo("Ending Date"):
                    TestField("Ending Date", RentalPriceListHeader."Ending Date");
                FieldNo("Source Type"):
                    if RentalPriceListHeader."Source No." <> '' then
                        TestField("Source Type", RentalPriceListHeader."Rental Source Type")
                    else begin
                        LineSourceTypeError :=
                            StrSubstNo(LineSourceTypeErr, "Source Type", RentalPriceListHeader."Rental Source Type");
                        if "Source Type".AsInteger() < RentalPriceListHeader."Rental Source Type".AsInteger() then
                            FieldError("Source Type", LineSourceTypeError);
                        if not IsSourceTypeSupported() then
                            FieldError("Source Type", LineSourceTypeError);
                    end;
                FieldNo("Source No."):
                    if RentalPriceListHeader."Source No." <> '' then
                        TestField("Source No.", RentalPriceListHeader."Source No.");
                FieldNo("Source Id"):
                    if RentalPriceListHeader."Source No." <> '' then
                        TestField("Source Id", RentalPriceListHeader."Source Id");
                FieldNo("Parent Source No."):
                    if RentalPriceListHeader."Parent Source No." <> '' then
                        TestField("Parent Source No.", RentalPriceListHeader."Parent Source No.");
            end;
    end;

    local procedure TestStatusDraft()
    begin
        TestField(Status, Status::Draft);
    end;

    /// <summary>
    /// VerifySource.
    /// </summary>
    procedure VerifySource()
    begin
        if "Source Type" = "Price Source Type"::"Job Task" then
            TestField("Parent Source No.")
        else
            TestField("Parent Source No.", '');

        if "Source Type" in
            ["TWE Rental Price Source Type"::All,
            "TWE Rental Price Source Type"::"All Customers",
            "TWE Rental Price Source Type"::"All Jobs"]
        then
            TestField("Source No.", '')
        else
            TestField("Source No.");
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCopyFromPriceAsset(RentalPriceAsset: Record "TWE Rental Price Asset")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCopyFromPriceListHeader(RentalPriceListHeader: Record "TWE Rental Price List Header")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCopyFromPriceSource(RentalPriceSource: Record "TWE Rental Price Source")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCopyToPriceAsset(var RentalPriceAsset: Record "TWE Rental Price Asset")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCopyToPriceSource(var RentalPriceSource: Record "TWE Rental Price Source")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterInitHeaderDefaults(PriceListHeader: Record "TWE Rental Price List Header")
    begin
    end;
}
