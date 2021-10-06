/// <summary>
/// PageExtension TWE Rent. Cust. Statistics FB (ID 50003) extends Record Customer Statistics FactBox.
/// </summary>
pageextension 50003 "TWE Rent. Cust. Statistics FB" extends "Customer Statistics FactBox"
{
    layout
    {
        addafter(Sales)
        {
            group("TWE Rental")
            {
                Caption = 'Rental';
                field("TWE Outstanding Contr. (LCY)"; Rec."TWE Outstanding Contr. (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies your expected rental income from the customer in LCY based on ongoing rental contracts.';
                }
                field("TWE Shipped Not Invoiced (LCY)"; Rec."TWE Shipped Not Invoiced (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Shipped Not Invd. (LCY)';
                    ToolTip = 'Specifies your expected rental income from the customer in LCY based on ongoing rental orders where items have been shipped.';
                }
                field("TWE Outstanding Invoices (LCY)"; Rec."TWE Outstanding Invoices (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies your expected rental income from the customer in LCY based on unpaid rental invoices.';
                }
            }
        }
    }
}
