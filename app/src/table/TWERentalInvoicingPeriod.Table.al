/// <summary>
/// Table TWE Rental Invoicing Period (ID 50012).
/// </summary>
table 50012 "TWE Rental Invoicing Period"
{
    DataClassification = CustomerContent;
    LookupPageId = "TWE Rental Invoicing Period";
    DrillDownPageId = "TWE Rental Invoicing Period";

    fields
    {
        field(1; "Invoicing Period Code"; Code[20])
        {
            Caption = 'Invoicing Period Code';
            DataClassification = CustomerContent;
        }
        field(2; Description; Text[50])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
        }
        field(12; DateFormular; DateFormula)
        {
            Caption = 'DateFormular';
            DataClassification = CustomerContent;
        }
        field(20; "Period Delimitation"; Enum "TWE Rental Invoicing Period Type")
        {
            Caption = 'Delimit the Period';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Invoicing Period Code")
        {
            Clustered = true;
        }
    }

}
