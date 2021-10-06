/// <summary>
/// Enum TWE Rental Invoicing Period Type (ID 50003).
/// </summary>
enum 50003 "TWE Rental Invoicing Period Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { Caption = ' '; }
    value(1; "First Day of Period") { Caption = 'First Day of Period'; }
    value(2; "Fixed Day") { Caption = 'Fixed Day'; }
    value(3; "Last Day of Period") { Caption = 'Last Day of Period'; }
}
