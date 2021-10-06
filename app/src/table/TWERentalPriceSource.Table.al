/// <summary>
/// Table TWE Rental Price Source (ID 50025).
/// </summary>
table 50025 "TWE Rental Price Source"
{
#pragma warning disable AS0034
    TableType = Temporary;
#pragma warning restore AS0034

    fields
    {
        field(1; "Source Type"; Enum "TWE Rental Price Source Type")
        {
            DataClassification = SystemMetadata;
            trigger OnValidate()
            begin
                SetGroup();
                InitSource();
            end;
        }
        field(2; "Source ID"; Guid)
        {
            DataClassification = SystemMetadata;
            trigger OnValidate()
            begin
                if IsNullGuid("Source ID") then
                    InitSource()
                else begin
                    TWERentalPriceSourceInterface := "Source Type";
                    TWERentalPriceSourceInterface.GetNo(Rec);
                    SetFilterSourceNo();
                end;
            end;
        }
        field(3; "Source No."; Code[20])
        {
            DataClassification = SystemMetadata;
            trigger OnValidate()
            begin
                if "Source No." = '' then
                    InitSource()
                else begin
                    TWERentalPriceSourceInterface := "Source Type";
                    TWERentalPriceSourceInterface.GetId(Rec);
                    SetFilterSourceNo();
                end;
            end;
        }
        field(4; "Parent Source No."; Code[20])
        {
            DataClassification = SystemMetadata;
            trigger OnValidate()
            begin
                TWERentalPriceSourceInterface := "Source Type";
                TWERentalPriceSourceInterface.VerifyParent(Rec);
                "Source No." := '';
                Clear("Source ID");
                "Filter Source No." := "Parent Source No.";
            end;
        }
        field(5; "Entry No."; Integer)
        {
            DataClassification = SystemMetadata;
        }
        field(6; Level; Integer)
        {
            DataClassification = SystemMetadata;
        }
        field(7; "Source Group"; Enum "TWE Rental Price Source Group")
        {
            DataClassification = SystemMetadata;
        }
        field(8; "Price Type"; Enum "TWE Rental Price Type")
        {
            DataClassification = SystemMetadata;
        }
        field(10; "Currency Code"; Code[10])
        {
            DataClassification = SystemMetadata;
            TableRelation = Currency;
        }
        field(12; "Starting Date"; Date)
        {
            DataClassification = SystemMetadata;
            trigger OnValidate()
            begin
                VerifyDates();
            end;
        }
        field(13; "Ending Date"; Date)
        {
            DataClassification = SystemMetadata;
            trigger OnValidate()
            begin
                VerifyDates();
            end;
        }
        field(19; "Filter Source No."; Code[20])
        {
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(21; "Allow Line Disc."; Boolean)
        {
            DataClassification = SystemMetadata;
        }
        field(22; "Allow Invoice Disc."; Boolean)
        {
            DataClassification = SystemMetadata;
        }
        field(23; "Price Includes VAT"; Boolean)
        {
            DataClassification = SystemMetadata;
        }
        field(24; "VAT Bus. Posting Gr. (Price)"; Code[20])
        {
            DataClassification = SystemMetadata;
            TableRelation = "VAT Business Posting Group";
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
        }
        key(Level; Level)
        {
        }
    }

    var
        TWERentalPriceSourceInterface: Interface "TWE Rental Price Source";
        StartingDateErr: Label 'Starting Date cannot be after Ending Date.';
        CampaignDateErr: Label 'If Source Type is Campaign, then you can only change Starting Date and Ending Date from the Campaign Card.';

    trigger OnInsert()
    begin
        "Entry No." := GetLastEntryNo() + 1;
    end;

    /// <summary>
    /// NewEntry.
    /// </summary>
    /// <param name="SourceType">Enum "TWE Rental Price Source Type".</param>
    /// <param name="NewLevel">Integer.</param>
    procedure NewEntry(SourceType: Enum "TWE Rental Price Source Type"; NewLevel: Integer)
    begin
        Init();
        Level := NewLevel;
        Validate("Source Type", SourceType);
    end;

    local procedure GetLastEntryNo(): Integer;
    var
        TempRentalPriceSource: Record "TWE Rental Price Source" temporary;
    begin
        TempRentalPriceSource.Copy(Rec, true);
        TempRentalPriceSource.Reset();
        if TempRentalPriceSource.FindLast() then
            exit(TempRentalPriceSource."Entry No.");
    end;

    /// <summary>
    /// InitSource.
    /// </summary>
    procedure InitSource()
    begin
        Clear("Source ID");
        "Parent Source No." := '';
        "Source No." := '';
        "Filter Source No." := '';
        "Currency Code" := '';
        GetPriceType();
    end;

    local procedure GetPriceType()
    begin
        case "Source Group" of
            "Source Group"::Customer:
                "Price Type" := "Price Type"::Rental;
        end;
    end;

    local procedure SetGroup()
    var
        SourceGroupInterface: Interface "TWE Rental Price Source Group";
    begin
        SourceGroupInterface := "Source Type";
        "Source Group" := SourceGroupInterface.GetGroup();
    end;

    procedure GetGroupNo(): Code[20]
    begin
        TWERentalPriceSourceInterface := "Source Type";
        exit(TWERentalPriceSourceInterface.GetGroupNo(Rec));
    end;

    procedure IsForAmountType(AmountType: Enum "Price Amount Type"): Boolean
    begin
        TWERentalPriceSourceInterface := "Source Type";
        exit(TWERentalPriceSourceInterface.IsForAmountType(AmountType))
    end;

    procedure IsSourceNoAllowed(): Boolean;
    begin
        TWERentalPriceSourceInterface := "Source Type";
        exit(TWERentalPriceSourceInterface.IsSourceNoAllowed());
    end;

    /// <summary>
    /// LookupNo.
    /// </summary>
    /// <returns>Return variable Result of type Boolean.</returns>
    procedure LookupNo() Result: Boolean;
    begin
        TWERentalPriceSourceInterface := "Source Type";
        Result := TWERentalPriceSourceInterface.IsLookupOK(Rec);
    end;

    /// <summary>
    /// FilterPriceLines.
    /// </summary>
    /// <param name="PriceListLine">VAR Record "TWE Rental Price List Line".</param>
    /// <returns>Return variable Result of type Boolean.</returns>
    procedure FilterPriceLines(var PriceListLine: Record "TWE Rental Price List Line") Result: Boolean;
    begin
        PriceListLine.SetRange("Source Type", "Source Type");
        if IsSourceNoAllowed() then begin
            if "Source No." = '' then
                exit;

            PriceListLine.SetRange("Source No.", "Source No.");
            if "Parent Source No." <> '' then
                PriceListLine.SetRange("Parent Source No.", "Parent Source No.");
        end else
            PriceListLine.SetRange("Source No.");
    end;

    local procedure VerifyDates()
    begin
        PriceSourceInterfaceVerifyDate();
        if ("Ending Date" <> 0D) and ("Starting Date" <> 0D) and ("Ending Date" < "Starting Date") then
            Error(StartingDateErr);
    end;

    // Should be a method in Price Source Interface
    local procedure PriceSourceInterfaceVerifyDate()
    begin
        if "Source Type" = "Source Type"::Campaign then
            Error(CampaignDateErr);
    end;

    local procedure SetFilterSourceNo()
    begin
        if "Parent Source No." <> '' then
            "Filter Source No." := "Parent Source No."
        else
            "Filter Source No." := "Source No."
    end;
}
