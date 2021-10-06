table 50023 "TWE Rental Price List Header"
{
    Caption = 'Rental Price List';

    fields
    {
        field(1; "Code"; Code[20])
        {
            DataClassification = CustomerContent;
            trigger OnValidate()
            begin
                if Code <> xRec.Code then begin
                    NoSeriesMgt.TestManual(GetNoSeries());
                    "No. Series" := '';
                end;
            end;
        }
        field(2; Description; Text[250])
        {
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                TestStatusDraft();
            end;
        }
        field(3; "Rental Source Group"; Enum "TWE Rental Price Source Group")
        {
            DataClassification = CustomerContent;
            Caption = 'Applies-to Group';
        }
        field(4; "Rental Source Type"; Enum "TWE Rental Price Source Type")
        {
            DataClassification = CustomerContent;
            Caption = 'Applies-to Type';
            trigger OnValidate()
            begin
                if xRec."Rental Source Type" = "Rental Source Type" then
                    exit;

                CheckIfLinesExist(FieldCaption("Rental Source Type"));
                xRec.CopyTo(RentalPriceSource);
                RentalPriceSource.Validate("Source Type", "Rental Source Type");
                CopyFrom(RentalPriceSource);
            end;
        }
        field(5; "Source No."; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Applies-to No.';
            trigger OnValidate()
            begin
                if xRec."Source No." = "Source No." then
                    exit;

                CheckIfLinesExist(FieldCaption("Source No."));
                xRec.CopyTo(RentalPriceSource);
                RentalPriceSource.Validate("Source No.", "Source No.");
                CopyFrom(RentalPriceSource);
            end;

            trigger OnLookup()
            begin
                CopyTo(RentalPriceSource);
                if RentalPriceSource.LookupNo() then begin
                    CheckIfLinesExist(FieldCaption("Source No."));
                    CopyFrom(RentalPriceSource);
                end;
            end;
        }
        field(6; "Parent Source No."; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Applies-to Parent No.';
            trigger OnValidate()
            begin
                if xRec."Parent Source No." = "Parent Source No." then
                    exit;

                TestStatusDraft();
                xRec.CopyTo(RentalPriceSource);
                RentalPriceSource.Validate("Parent Source No.", "Parent Source No.");
                CopyFrom(RentalPriceSource);
            end;
        }
        field(7; "Source ID"; Guid)
        {
            DataClassification = CustomerContent;
            Caption = 'Applies-to ID';
            trigger OnValidate()
            begin
                if xRec."Source ID" = "Source ID" then
                    exit;

                TestStatusDraft();
                xRec.CopyTo(RentalPriceSource);
                RentalPriceSource.Validate("Source ID", "Source ID");
                CopyFrom(RentalPriceSource);
            end;
        }
        field(8; "Rental Price Type"; Enum "TWE Rental Price Type")
        {
            DataClassification = CustomerContent;
            Caption = 'Price Type';
        }
        field(9; "Amount Type"; Enum "Price Amount Type")
        {
            DataClassification = CustomerContent;
            Caption = 'Defines';
            Editable = false;
        }
        field(10; "Currency Code"; Code[10])
        {
            DataClassification = CustomerContent;
            Caption = 'Currency Code';
            TableRelation = Currency;

            trigger OnValidate()
            begin
                if "Currency Code" <> xRec."Currency Code" then
                    CheckIfLinesExist(FieldCaption("Currency Code"));
            end;
        }
        field(11; "Starting Date"; Date)
        {
            DataClassification = CustomerContent;
            Caption = 'Starting Date';
            trigger OnValidate()
            begin
                if "Starting Date" = xRec."Starting Date" then
                    exit;

                TestStatusDraft();
                xRec.CopyTo(RentalPriceSource);
                RentalPriceSource.Validate("Starting Date", "Starting Date");
                CopyFrom(RentalPriceSource);

                if not UpdateLines(FieldNo("Starting Date"), FieldCaption("Starting Date")) then
                    "Starting Date" := xRec."Starting Date";
            end;
        }
        field(12; "Ending Date"; Date)
        {
            DataClassification = CustomerContent;
            Caption = 'Ending Date';
            trigger OnValidate()
            begin
                if "Ending Date" = xRec."Ending Date" then
                    exit;

                TestStatusDraft();
                xRec.CopyTo(RentalPriceSource);
                RentalPriceSource.Validate("Ending Date", "Ending Date");
                CopyFrom(RentalPriceSource);

                if not UpdateLines(FieldNo("Ending Date"), FieldCaption("Ending Date")) then
                    "Ending Date" := xRec."Ending Date";
            end;
        }
        field(13; "Price Includes VAT"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Price Includes VAT';

            trigger OnValidate()
            begin
                if "Price Includes VAT" <> xRec."Price Includes VAT" then
                    CheckIfLinesExist(FieldCaption("Price Includes VAT"));
            end;
        }
        field(14; "VAT Bus. Posting Gr. (Price)"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'VAT Bus. Posting Gr. (Price)';
            TableRelation = "VAT Business Posting Group";

            trigger OnValidate()
            begin
                if "VAT Bus. Posting Gr. (Price)" <> xRec."VAT Bus. Posting Gr. (Price)" then
                    CheckIfLinesExist(FieldCaption("VAT Bus. Posting Gr. (Price)"));
            end;
        }
        field(15; "Allow Line Disc."; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Allow Line Disc.';
            InitValue = true;

            trigger OnValidate()
            begin
                TestStatusDraft();
            end;
        }
        field(16; "Allow Invoice Disc."; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Allow Invoice Disc.';
            InitValue = true;

            trigger OnValidate()
            begin
                TestStatusDraft();
            end;
        }
        field(17; "No. Series"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
        field(18; Status; Enum "Price Status")
        {
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if Status <> xRec.Status then
                    if not UpdateStatus() then
                        Status := xRec.Status;
            end;
        }
        field(19; "Filter Source No."; Code[20])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(20; "Allow Updating Defaults"; Boolean)
        {
            DataClassification = SystemMetadata;
            trigger OnValidate()
            begin
                if xRec."Allow Updating Defaults" and not Rec."Allow Updating Defaults" then
                    CheckIfLinesExist(Rec.FieldCaption("Allow Updating Defaults"));
            end;
        }
    }

    keys
    {
        key(PK; Code)
        {
        }
        key(Key1; "Rental Source Type", "Source No.", "Starting Date", "Currency Code")
        {
        }
        key(Key2; Status, "Rental Price Type", "Rental Source Group", "Rental Source Type", "Source No.", "Currency Code", "Starting Date", "Ending Date")
        {
        }
    }

    trigger OnInsert()
    begin
        if "Rental Source Group" = "Rental Source Group"::All then
            TestField(Code);
        if Code = '' then
            NoSeriesMgt.InitSeries(GetNoSeries(), xRec."No. Series", 0D, Code, "No. Series");
    end;

    trigger OnDelete()
    var
        RentalPriceListLine: Record "TWE Rental Price List Line";
    begin
        if Status = Status::Active then
            Error(CannotDeleteActivePriceListErr, Code);

        RentalPriceListLine.SetRange("Price List Code", Code);
        RentalPriceListLine.DeleteAll();
    end;

    var
        RentalPriceSource: Record "TWE Rental Price Source";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        ConfirmUpdateQst: Label 'Do you want to update %1 in the price list lines?', Comment = '%1 - the field caption';
        LinesExistErr: Label 'You cannot change %1 because one or more lines exist.', Comment = '%1 - the field caption';
        StatusUpdateQst: Label 'Do you want to update status to %1?', Comment = '%1 - status value: Draft, Active, or Inactive';
        CannotDeleteActivePriceListErr: Label 'You cannot delete the active price list %1.', Comment = '%1 - the price list code.';

    /// <summary>
    /// IsEditable.
    /// </summary>
    /// <returns>Return variable Result of type Boolean.</returns>
    procedure IsEditable() Result: Boolean;
    begin
        Result := Status = Status::Draft;
    end;

    /// <summary>
    /// AssistEditCode.
    /// </summary>
    /// <param name="xPriceListHeader">Record "Price List Header".</param>
    /// <returns>Return value of type Boolean.</returns>
    procedure AssistEditCode(xPriceListHeader: Record "TWE Rental Price List Header"): Boolean
    var
        RentalPriceListHeader: Record "TWE Rental Price List Header";
    begin
        if "Rental Source Group" = "Rental Source Group"::All then
            exit(false);

        RentalPriceListHeader := Rec;
        if NoSeriesMgt.SelectSeries(GetNoSeries(), xPriceListHeader."No. Series", RentalPriceListHeader."No. Series") then begin
            NoSeriesMgt.SetSeries(RentalPriceListHeader.Code);
            Rec := RentalPriceListHeader;
            exit(true);
        end;
    end;

    /// <summary>
    /// BlankDefaults.
    /// </summary>
    procedure BlankDefaults()
    begin
        if Rec."Allow Updating Defaults" then begin
            Rec."Rental Source Type" := Rec."Rental Source Type"::All;
            Rec."Parent Source No." := '';
            Rec."Source No." := '';
            Rec."Currency Code" := '';
            Rec."Starting Date" := 0D;
            Rec."Ending Date" := 0D;
        end;
    end;

    local procedure GetNoSeries(): Code[20];
    var
        JobsSetup: Record "Jobs Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        case "Rental Source Group" of
            "Rental Source Group"::Customer:
                begin
                    SalesReceivablesSetup.Get();
                    SalesReceivablesSetup.TestField("Price List Nos.");
                    exit(SalesReceivablesSetup."Price List Nos.");
                end;
            "Rental Source Group"::Job:
                begin
                    JobsSetup.Get();
                    JobsSetup.TestField("Price List Nos.");
                    exit(JobsSetup."Price List Nos.");
                end;
        end;
    end;

    local procedure CheckIfLinesExist(Caption: Text)
    var
        RentalPriceListLine: Record "TWE Rental Price List Line";
        ErrorMsg: Text;
    begin
        TestStatusDraft();
        RentalPriceListLine.SetRange("Price List Code", Code);
        if not RentalPriceListLine.IsEmpty then begin
            ErrorMsg := StrSubstNo(LinesExistErr, Caption);
            Error(ErrorMsg);
        end;
    end;

    /// <summary>
    /// CopyFrom.
    /// </summary>
    /// <param name="RentalPriceSource">Record "TWE Rental Price Source".</param>
    procedure CopyFrom(RentalPriceSource: Record "TWE Rental Price Source")
    begin
        "Rental Price Type" := RentalPriceSource."Price Type";
        "Rental Source Group" := RentalPriceSource."Source Group";
        if "Rental Source Group" = "Rental Source Group"::All then
            case "Rental Price Type" of
                "Rental Price Type"::Sale:
                    "Rental Source Group" := "Rental Source Group"::Customer;
                "Rental Price Type"::Rental:
                    "Rental Source Group" := "Rental Source Group"::Customer;
            end;
        "Rental Source Type" := RentalPriceSource."Source Type";
        "Source No." := RentalPriceSource."Source No.";
        "Parent Source No." := RentalPriceSource."Parent Source No.";
        "Source ID" := RentalPriceSource."Source ID";
        "Filter Source No." := RentalPriceSource."Filter Source No.";

        "Currency Code" := RentalPriceSource."Currency Code";
        "Starting Date" := RentalPriceSource."Starting Date";
        "Ending Date" := RentalPriceSource."Ending Date";
        "Price Includes VAT" := RentalPriceSource."Price Includes VAT";
        "Allow Invoice Disc." := RentalPriceSource."Allow Invoice Disc.";
        "Allow Line Disc." := RentalPriceSource."Allow Line Disc.";
        "VAT Bus. Posting Gr. (Price)" := RentalPriceSource."VAT Bus. Posting Gr. (Price)";

        OnAfterCopyFromPriceSource(RentalPriceSource);
    end;

    /// <summary>
    /// CopyTo.
    /// </summary>
    /// <param name="RentalPriceSource">VAR Record "TWE Rental Price Source".</param>
    procedure CopyTo(var RentalPriceSource: Record "TWE Rental Price Source")
    begin
        RentalPriceSource."Source Group" := "Rental Source Group";
        RentalPriceSource."Source Type" := "Rental Source Type";
        RentalPriceSource."Source No." := "Source No.";
        RentalPriceSource."Parent Source No." := "Parent Source No.";
        RentalPriceSource."Source ID" := "Source ID";

        RentalPriceSource."Price Type" := "Rental Price Type";
        RentalPriceSource."Currency Code" := "Currency Code";
        RentalPriceSource."Starting Date" := "Starting Date";
        RentalPriceSource."Ending Date" := "Ending Date";
        RentalPriceSource."Price Includes VAT" := "Price Includes VAT";
        RentalPriceSource."Allow Invoice Disc." := "Allow Invoice Disc.";
        RentalPriceSource."Allow Line Disc." := "Allow Line Disc.";
        RentalPriceSource."VAT Bus. Posting Gr. (Price)" := "VAT Bus. Posting Gr. (Price)";

        OnAfterCopyToPriceSource(RentalPriceSource);
    end;

    /// <summary>
    /// IsSourceNoAllowed.
    /// </summary>
    /// <returns>Return value of type Boolean.</returns>
    procedure IsSourceNoAllowed(): Boolean;
    var
        RentalPriceSourceInterface: Interface "TWE Rental Price Source";
    begin
        RentalPriceSourceInterface := "Rental Source Type";
        exit(RentalPriceSourceInterface.IsSourceNoAllowed());
    end;

    /// <summary>
    /// UpdateAmountType.
    /// </summary>
    procedure UpdateAmountType()
    var
        xAmountType: Enum "Price Amount Type";
    begin
        xAmountType := "Amount Type";
        "Amount Type" := CalcAmountType();
        if "Amount Type" <> xAmountType then
            Modify()
    end;

    local procedure CalcAmountType(): Enum "Price Amount Type";
    var
        RentalPriceListLine: Record "TWE Rental Price List Line";
    begin
        RentalPriceListLine.SetRange("Price List Code", Code);
        if RentalPriceListLine.IsEmpty() then
            exit("Amount Type"::Any);

        RentalPriceListLine.SetRange("Amount Type", "Amount Type"::Any);
        if not RentalPriceListLine.IsEmpty() then
            exit("Amount Type"::Any);

        RentalPriceListLine.SetRange("Amount Type", "Amount Type"::Price);
        if RentalPriceListLine.IsEmpty() then
            exit("Amount Type"::Discount);

        RentalPriceListLine.SetRange("Amount Type", "Amount Type"::Discount);
        if RentalPriceListLine.IsEmpty() then
            exit("Amount Type"::Price);

        exit("Amount Type"::Any);
    end;

    local procedure UpdateLines(FieldId: Integer; Caption: Text) Updated: Boolean;
    var
        RentalPriceListLine: Record "TWE Rental Price List Line";
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        Updated := true;
        RentalPriceListLine.SetRange("Price List Code", Code);
        if RentalPriceListLine.IsEmpty() then
            exit;

        if ConfirmManagement.GetResponse(StrSubstNo(ConfirmUpdateQst, Caption), true) then
            case FieldId of
                FieldNo("Starting Date"):
                    RentalPriceListLine.ModifyAll("Starting Date", "Starting Date");
                FieldNo("Ending Date"):
                    RentalPriceListLine.ModifyAll("Ending Date", "Ending Date");
            end
        else
            Updated := false;
    end;

    local procedure TestStatusDraft()
    begin
        TestField(Status, Status::Draft);
    end;

    local procedure UpdateStatus() Updated: Boolean;
    var
        RentalPriceListLine: Record "TWE Rental Price List Line";
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if Status = Status::Active then
            VerifySource();

        Updated := true;
        RentalPriceListLine.SetRange("Price List Code", Code);
        if RentalPriceListLine.IsEmpty() then
            exit;

        if Status = Status::Active then begin
            VerifyLines();
            if not ResolveDuplicatePrices() then
                exit(false);
        end;

        if ConfirmManagement.GetResponse(StrSubstNo(StatusUpdateQst, Status), true) then
            RentalPriceListLine.ModifyAll(Status, Status)
        else
            Updated := false
    end;

    local procedure ResolveDuplicatePrices(): Boolean
    var
        DuplicatePriceLine: Record "TWE Rental Dup. Price Line";
        RentalPriceListMgt: Codeunit "TWE Rental Price List Mgt.";
    begin
        if RentalPriceListMgt.FindDuplicatePrices(Rec, true, DuplicatePriceLine) then
            if not RentalPriceListMgt.ResolveDuplicatePrices(Rec, DuplicatePriceLine) then
                exit(false);

        if RentalPriceListMgt.FindDuplicatePrices(Rec, false, DuplicatePriceLine) then
            if not RentalPriceListMgt.ResolveDuplicatePrices(Rec, DuplicatePriceLine) then
                exit(false);
        exit(true);
    end;

    local procedure VerifySource()
    begin
        if "Rental Source Type" = "Price Source Type"::"Job Task" then
            TestField("Parent Source No.")
        else
            TestField("Parent Source No.", '');

        if "Rental Source Type" in
            ["TWE Rental Price Source Type"::All,
            "TWE Rental Price Source Type"::"All Customers",
            "TWE Rental Price Source Type"::"All Jobs"]
        then
            TestField("Source No.", '')
        else
            TestField("Source No.");
    end;

    local procedure VerifyLines()
    var
        RentalPriceListLine: Record "TWE Rental Price List Line";
    begin
        RentalPriceListLine.SetRange("Price List Code", Code);
        if RentalPriceListLine.FindSet() then
            repeat
                RentalPriceListLine.VerifySource();
                if RentalPriceListLine."Asset Type" <> RentalPriceListLine."Asset Type"::" " then
                    RentalPriceListLine.TestField("Asset No.");
            until RentalPriceListLine.Next() = 0;
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCopyFromPriceSource(RentalPriceSource: Record "TWE Rental Price Source")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCopyToPriceSource(var RentalPriceSource: Record "TWE Rental Price Source")
    begin
    end;
}
