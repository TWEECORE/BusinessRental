/// <summary>
/// Enum TWE Rental Document Type From (ID 50002).
/// </summary>
enum 50002 "TWE Rental Document Type From"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Quote") { Caption = 'Quote'; }
    value(1; "Contract") { Caption = 'Contract'; }
    value(2; "Invoice") { Caption = 'Invoice'; }
    value(3; "Return Shipment") { Caption = 'Return Shipment'; }
    value(4; "Credit Memo") { Caption = 'Credit Memo'; }
    value(5; "Posted Shipment") { Caption = 'Posted Shipment'; }
    value(6; "Posted Invoice") { Caption = 'Posted Invoice'; }
    value(7; "Posted Credit Memo") { Caption = 'Posted Credit Memo'; }

    value(8; "Posted Return Shipment") { Caption = 'Posted Return Shipment'; }
    value(9; "Arch. Quote") { Caption = 'Arch. Quote'; }
    value(10; "Arch. Contract") { Caption = 'Arch. Contract'; }
}
