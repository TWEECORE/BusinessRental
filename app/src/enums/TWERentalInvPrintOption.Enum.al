/// <summary>
/// Enum TWE Rental Inv. Print Option (ID 50004).
/// </summary>
enum 50004 "TWE Rental Inv. Print Option"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(1; "Draft Invoice")
    {
        Caption = 'Draft Invoice';
    }
    value(2; "Pro Forma Invoice")
    {
        Caption = 'Pro Forma Invoice';
    }
}
