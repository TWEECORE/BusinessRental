/// <summary>
/// Enum TWE Rental Line Type (ID 50005).
/// </summary>
enum 50005 "TWE Rental Line Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { Caption = ' '; }
    value(1; "G/L Account") { Caption = 'G/L Account'; }
    value(2; "Rental Item") { Caption = 'Rental Item'; }
    value(3; "Resource") { Caption = 'Resource'; }
}
