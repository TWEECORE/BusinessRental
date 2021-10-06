/// <summary>
/// Table TWE My Main Rental Item (ID 50000).
/// </summary>
table 50000 "TWE My Main Rental Item"
{
    Caption = 'My Main Rental Item';

    fields
    {
        field(1; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(2; "Main Rental Item No."; Code[20])
        {
            Caption = 'Main Rental Item No.';
            DataClassification = CustomerContent;
            NotBlank = true;
            TableRelation = "TWE Main Rental Item";

            trigger OnValidate()
            begin
                SetItemFields();
            end;
        }
        field(3; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(4; "Unit Price"; Decimal)
        {
            Caption = 'Unit Price';
            DataClassification = CustomerContent;
            Editable = false;
        }
        /*         field(5; Inventory; Decimal)
                {
                    CalcFormula = Sum("Item Ledger Entry".Quantity WHERE("Main Rental Item No." = FIELD("Main Rental Item No.")));
                    Caption = 'Inventory';
                    DataClassification = CustomerContent;
                    Editable = false;
                    FieldClass = FlowField;
                } */
    }

    keys
    {
        key(Key1; "User ID", "Main Rental Item No.")
        {
            Clustered = true;
        }
        key(Key2; Description)
        {
        }
        key(Key3; "Unit Price")
        {
        }
    }

    fieldgroups
    {
    }

    local procedure SetItemFields()
    var
        MainRentalItem: Record "TWE Main Rental Item";
    begin
        if MainRentalItem.Get("Main Rental Item No.") then begin
            Description := MainRentalItem.Description;
            "Unit Price" := MainRentalItem."Unit Price";
        end;
    end;
}

