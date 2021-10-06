/// <summary>
/// Enum TWE Rent. Report Sel. Usage (ID 50013).
/// </summary>
enum 50013 "TWE Rent. Report Sel. Usage"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "R.Quote") { Caption = 'R.Quote'; }
    value(1; "R.Contract") { Caption = 'R.Contract'; }
    value(2; "R.Invoice") { Caption = 'R.Invoice'; }
    value(3; "R.Cr.Memo") { Caption = 'R.Cr.Memo'; }
    value(4; "R.Ret.Shpt.") { Caption = 'R.Ret.Shpt.'; }
    value(5; "R.Shipment") { Caption = 'R.Shipment'; }
    value(6; "R.Arch.Quote") { Caption = 'R.Arch.Quote'; }
    value(7; "R.Arch.Contract") { Caption = 'R.Arch.Contract'; }

    value(20; "Pro Forma R. Invoice") { Caption = 'Pro Forma R. Invoice'; }
    value(21; "Draft R. Invoice") { Caption = 'Draft R. Invoice'; }

    value(50; "R.Test Prepmt.") { Caption = 'R.Test Prepmt.'; }

    value(51; "R.Test") { Caption = 'R.Test'; }
}
