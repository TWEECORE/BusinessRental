/// <summary>
/// Query TWE Count Rental Contracts (ID 50000).
/// </summary>
query 50000 "TWE Count Rental Contracts"
{
    Caption = 'Count Rental Contracts';

    elements
    {
        dataitem(Rental_Header; "TWE Rental Header")
        {
            DataItemTableFilter = "Document Type" = CONST(Contract);
            filter(Status; Status)
            {
            }
            filter(Shipped; Shipped)
            {
            }
            filter(Completely_Shipped; "Completely Shipped")
            {
            }
            filter(Responsibility_Center; "Responsibility Center")
            {
            }
            filter(Shipped_Not_Invoiced; "Shipped Not Invoiced")
            {
            }
            filter(Ship; Ship)
            {
            }
            filter(Date_Filter; "Date Filter")
            {
            }
            filter(Late_Order_Shipping; "Late Order Shipping")
            {
            }
            filter(Shipment_Date; "Shipment Date")
            {
            }
            column(Count_Contracts)
            {
                Method = Count;
            }
        }
    }
}

