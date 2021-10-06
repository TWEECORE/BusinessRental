/// <summary>
/// Table TWE Rental Rates (ID 50026).
/// </summary>
table 50026 "TWE Rental Rates"
{
    DataClassification = CustomerContent;
    LookupPageId = "TWE Rental Rates";
    DrillDownPageId = "TWE Rental Rates";

    fields
    {
        field(1; "Rate Code"; Code[20])
        {
            Caption = 'Rate Code';
            DataClassification = CustomerContent;
        }
        field(2; Description; Text[50])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
        }
        field(3; "Rental Calendar"; Code[10])
        {
            Caption = 'Rental Calendar';
            DataClassification = CustomerContent;
            TableRelation = "Base Calendar";
        }

        field(4; "Rental Rate Type"; Enum "TWE Rental Rate Type")
        {
            Caption = 'Rental Rate Type';
            DataClassification = CustomerContent;
        }
        field(10; "Qty. in Days"; Decimal)
        {
            Caption = 'Qty. in days';
            DataClassification = CustomerContent;
        }
        field(11; "One-time Rental"; Boolean)
        {
            Caption = 'One-time Rental';
            DataClassification = CustomerContent;
        }
        field(12; "DateFormular for Flat Rate"; DateFormula)
        {
            Caption = 'DateFormular for Flat Rate';
            DataClassification = CustomerContent;
        }
        field(20; "Print Text for Documents"; Text[50])
        {
            Caption = 'Print Text for Documents';
            DataClassification = CustomerContent;
        }

    }

    keys
    {
        key(PK; "Rate Code")
        {
            Clustered = true;
        }
    }

}
