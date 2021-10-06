/// <summary>
/// Enum TWE Rental Price Type (ID 50009).
/// </summary>
enum 50009 "TWE Rental Price Type"
{
    Extensible = true;
    value(0; Any)
    {
        Caption = 'Any';
    }
    value(1; Sale)
    {
        Caption = 'Sale';
    }
    value(2; Purchase)
    {
        Caption = 'Purchase';
    }
    value(3; Rental)
    {
        Caption = 'Rental';
    }
}
