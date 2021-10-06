/// <summary>
/// Enum TWE Rental Document Type (ID 50001).
/// </summary>
enum 50001 "TWE Rental Document Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Quote") { Caption = 'Quote'; }
    value(1; "Contract") { Caption = 'Contract'; }
    value(2; "Invoice") { Caption = 'Invoice'; }
    value(3; "Credit Memo") { Caption = 'Credit Memo'; }
    value(4; "Shipment") { Caption = 'Shipment'; }
    value(5; "Return Shipment") { Caption = 'Return Shipment'; }
}
