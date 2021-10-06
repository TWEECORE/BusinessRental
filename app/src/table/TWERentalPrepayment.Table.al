table 50018 "TWE Rental Prepayment %"
{
    Caption = 'Rental Prepayment %';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            DataClassification = CustomerContent;
            NotBlank = true;
            TableRelation = Item;
        }
        field(2; "Rental Type"; Option)
        {
            Caption = 'Rental Type';
            DataClassification = CustomerContent;
            OptionCaption = 'Customer,Customer Price Group,All Customers';
            OptionMembers = Customer,"Customer Price Group","All Customers";

            trigger OnValidate()
            begin
                if "Rental Type" <> xRec."Rental Type" then
                    Validate("Rental Code", '');
            end;
        }
        field(3; "Rental Code"; Code[20])
        {
            Caption = 'Rental Code';
            DataClassification = CustomerContent;
            TableRelation = IF ("Rental Type" = CONST(Customer)) Customer
            ELSE
            IF ("Rental Type" = CONST("Customer Price Group")) "Customer Price Group";

            trigger OnValidate()
            begin
                if "Rental Code" = '' then
                    exit;

                if "Rental Type" = "Rental Type"::"All Customers" then
                    Error(Text001Lbl, FieldCaption("Rental Code"));
            end;
        }
        field(4; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                CheckDate();
            end;
        }
        field(5; "Ending Date"; Date)
        {
            Caption = 'Ending Date';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                CheckDate();
            end;
        }
        field(6; "Prepayment %"; Decimal)
        {
            Caption = 'Prepayment %';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
        }
    }

    keys
    {
        key(Key1; "Item No.", "Rental Type", "Rental Code", "Starting Date")
        {
            Clustered = true;
        }
        key(Key2; "Rental Type", "Rental Code")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        if "Rental Type" = "Rental Type"::"All Customers" then
            "Rental Code" := ''
        else
            TestField("Rental Code");
        TestField("Item No.");
    end;

    var
        Text000Lbl: Label '%1 cannot be after %2.', Comment = '%1= FieldCaption "Starting Date",%2= FieldCaption "Ending Date"';
        Text001Lbl: Label '%1 must be blank.', Comment = '%1= FieldCaption "Rental Code"';

    local procedure CheckDate()
    begin
        if ("Starting Date" > "Ending Date") and ("Ending Date" <> 0D) then
            Error(Text000Lbl, FieldCaption("Starting Date"), FieldCaption("Ending Date"));
    end;
}

