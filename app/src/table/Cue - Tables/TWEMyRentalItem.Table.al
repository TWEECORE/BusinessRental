/// <summary>
/// Table TWE My Rental Item (ID 70704711).
/// </summary>
table 50001 "TWE My Rental Item"
{
    Caption = 'My Rental Item';

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
        field(2; "Rental Item No."; Code[20])
        {
            Caption = 'Rental Item No.';
            DataClassification = CustomerContent;
            NotBlank = true;
            TableRelation = "Service Item" where("TWE Main Rental Item" = FILTER(<> ''));

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
        key(Key1; "User ID", "Rental Item No.")
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
        ServiceItem: Record "Service Item";
    begin
        if ServiceItem.Get("Rental Item No.") then begin
            Description := ServiceItem.Description;
            "Unit Price" := ServiceItem."Sales Unit Price";
        end;
    end;
}

