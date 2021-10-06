/// <summary>
/// Table TWE Rent Dtld.PriceCalc Setup (ID 50034).
/// </summary>
table 50034 "TWE Rent Dtld.PriceCalc Setup"
{
    Caption = 'Rental Detailed Price Calculation Setup';
    DrillDownPageID = "TWE Rent Dtld.PriceCalc. Setup";
    LookupPageID = "TWE Rent Dtld.PriceCalc. Setup";

    fields
    {
        field(1; "Line No."; Integer)
        {
            AutoIncrement = true;
            Caption = 'Line No.';
            DataClassification = CustomerContent;
        }
        field(2; "Setup Code"; Code[100])
        {
            TableRelation = "TWE Rental Price Calc. Setup".Code where(Enabled = const(true));
            Caption = 'Setup Code';
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                PriceCalculationSetup: Record "TWE Rental Price Calc. Setup";
            begin
                PriceCalculationSetup.Get("Setup Code");
                Type := PriceCalculationSetup.Type;
                Method := PriceCalculationSetup.Method;
                Implementation := PriceCalculationSetup.Implementation;
                "Group Id" := PriceCalculationSetup."Group Id";
                Validate("Asset Type", PriceCalculationSetup."Asset Type");
                Enabled := true;
            end;
        }
        field(3; Method; Enum "Price Calculation Method")
        {
            Editable = false;
            Caption = 'Method';
            DataClassification = CustomerContent;
        }
        field(4; Type; Enum "TWE Rental Price Type")
        {
            Editable = false;
            Caption = 'Type';
            DataClassification = CustomerContent;
        }
        field(5; "Asset Type"; Enum "TWE Rental Price Asset Type")
        {
            Caption = 'Product Type';
            DataClassification = CustomerContent;
            Editable = false;

            trigger OnValidate()
            begin
                if "Asset Type" <> xRec."Asset Type" then
                    "Asset No." := '';
            end;
        }
        field(6; "Asset No."; Code[20])
        {
            Caption = 'Product No.';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                xRec.CopyTo(RentalPriceAsset);
                RentalPriceAsset.Validate("Asset No.", "Asset No.");
                CopyFrom(RentalPriceAsset);
            end;

            trigger OnLookup()
            begin
                CopyTo(RentalPriceAsset);
                if RentalPriceAsset.LookupNo() then
                    CopyFrom(RentalPriceAsset);
            end;
        }
        field(7; "Source Group"; Enum "TWE Rental Price Source Group")
        {
            Caption = 'Applies-to Group';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if "Source Group" <> xRec."Source Group" then begin
                    Validate("Source Type", "Source Group".AsInteger());
                    "Source No." := '';
                end;
            end;
        }

        field(8; "Source Type"; Enum "TWE Rental Price Source Type")
        {
            DataClassification = CustomerContent;
            Caption = 'Applies-to Type';
            Editable = false;
            trigger OnValidate()
            begin
                VerifySourceType();
                xRec.CopyTo(RentalPriceSource);
                RentalPriceSource.Validate("Source Type", "Source Type");
                CopyFrom(RentalPriceSource);
            end;
        }
        field(9; "Source No."; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Applies-to No.';
            trigger OnValidate()
            begin
                xRec.CopyTo(RentalPriceSource);
                RentalPriceSource.Validate("Source No.", "Source No.");
                CopyFrom(RentalPriceSource);
            end;

            trigger OnLookup()
            begin
                CopyTo(RentalPriceSource);
                RentalPriceSource.LookupNo();
                CopyFrom(RentalPriceSource);
            end;
        }
        field(10; Implementation; Enum "TWE Rent Price Calc Handler")
        {
            Editable = false;
            Caption = 'Implementation';
            DataClassification = CustomerContent;
        }
        field(11; "Group Id"; Code[100])
        {
            DataClassification = SystemMetadata;
        }
        field(12; Enabled; Boolean)
        {
            Caption = 'Enabled';
            DataClassification = CustomerContent;
        }
    }
    keys
    {
        key(PK; "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Group Id", Enabled)
        {
        }
    }

    trigger OnInsert()
    begin
        Enabled := true;
    end;

    protected var
        RentalPriceAsset: Record "TWE Rental Price Asset";
        RentalPriceSource: Record "TWE Rental Price Source";

    var
        NotSupportedSourceTypeErr: label 'Not supported source type %1 for the source group %2.',
            Comment = '%1 - source type value, %2 - source group value';

    local procedure CopyFrom(PriceAsset: Record "TWE Rental Price Asset")
    begin
        "Asset Type" := PriceAsset."Asset Type";
        "Asset No." := PriceAsset."Asset No.";
    end;

    local procedure CopyFrom(PriceSource: Record "TWE Rental Price Source")
    begin
        "Source Type" := PriceSource."Source Type";
        "Source No." := PriceSource."Source No.";
    end;

    /// <summary>
    /// CopyTo.
    /// </summary>
    /// <param name="PriceAsset">VAR Record "TWE Rental Price Asset".</param>
    procedure CopyTo(var PriceAsset: Record "TWE Rental Price Asset")
    begin
        PriceAsset."Asset Type" := "Asset Type";
        PriceAsset."Asset No." := "Asset No.";
    end;

    /// <summary>
    /// CopyTo.
    /// </summary>
    /// <param name="PriceSource">VAR Record "TWE Rental Price Source".</param>
    procedure CopyTo(var PriceSource: Record "TWE Rental Price Source")
    begin
        PriceSource."Source Type" := "Source Type";
        PriceSource."Source No." := "Source No.";
    end;

    local procedure VerifySourceType()
    var
        PriceSourceGroup: Interface "TWE Rental Price Source Group";
    begin
        PriceSourceGroup := "Source Group";
        if not PriceSourceGroup.IsSourceTypeSupported("Source Type") then
            Error(NotSupportedSourceTypeErr, "Source Type", "Source Group");
    end;
}

