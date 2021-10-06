/// <summary>
/// Enum TWE Rental Comment Document Type (ID 50000).
/// </summary>
enum 50000 "TWE Rental Comment Document Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Quote") { Caption = 'Quote'; }
    value(1; "Order") { Caption = 'Order'; }
    value(2; "Invoice") { Caption = 'Invoice'; }
    value(3; "Credit Memo") { Caption = 'Credit Memo'; }
    value(5; "Shipment") { Caption = 'Shipment'; }
    value(6; "Return Shipment") { Caption = 'Return Shipment'; }
    value(7; "Posted Invoice") { Caption = 'Posted Invoice'; }
    value(8; "Posted Credit Memo") { Caption = 'Posted Credit Memo'; }
    value(9; "Posted Shipment") { Caption = 'Posted Shipment'; }
    value(10; "Posted Return Shipment") { Caption = 'Posted Return Shipment'; }
    value(20; "Item") { Caption = 'Item'; }
}
