/// <summary>
/// Enum TWE Rental Rate Type (ID 50010).
/// </summary>
enum 50010 "TWE Rental Rate Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { Caption = ' '; }
    value(1; "Flat Rate") { Caption = 'Flat Rate'; }
    value(2; "Daily Basis") { Caption = 'Daily Basis'; }
    value(3; "By Hour") { Caption = 'By Hour'; }
}
