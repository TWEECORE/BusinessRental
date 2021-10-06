/// <summary>
/// Page TWE Rental Hist. Bill-to FB (ID 70704690).
/// </summary>
page 50003 "TWE Rental Hist. Bill-to FB"
{
    Caption = 'Bill-to Customer Rental History';
    PageType = CardPart;
    SourceTable = Customer;

    layout
    {
        area(content)
        {
            field("No."; Rec."No.")
            {
                ApplicationArea = All;
                Caption = 'Customer No.';
                ToolTip = 'Specifies the number of the customer. The field is either filled automatically from a defined number series, or you enter the number manually because you have enabled manual number entry in the number-series setup.';

                trigger OnDrillDown()
                begin
                    ShowDetails();
                end;
            }
            group(Control2)
            {
                ShowCaption = false;
                Visible = false;
                field("TWE Bill-To No. of Quotes"; Rec."TWE Bill-To No. of Quotes")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Quotes';
                    DrillDownPageID = "TWE Rental Quotes";
                    ToolTip = 'Specifies how many quotes have been registered for the customer when the customer acts as the bill-to customer.';
                }
                field("TWE Bill-To No. of Contracts"; Rec."TWE Bill-To No. of Contracts")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Contracts';
                    DrillDownPageID = "TWE Rental Contract List";
                    ToolTip = 'Specifies how many sales orders have been registered for the customer when the customer acts as the bill-to customer.';
                }
                field("TWE Bill-To No. of Invoices"; Rec."TWE Bill-To No. of Invoices")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Invoices';
                    DrillDownPageID = "TWE Rental Invoice List";
                    ToolTip = 'Specifies how many invoices have been registered for the customer when the customer acts as the bill-to customer.';
                }
                field("TWE Bill-To No. of Ret. Shipm."; Rec."TWE Bill-To No. of Ret. Shipm.")
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Return Shipments';
                    DrillDownPageID = "TWE Rental Return Ship. List";
                    ToolTip = 'Specifies how many return orders have been registered for the customer when the customer acts as the bill-to customer.';
                }
                field("TWE Bill-To No. of Cr. Memos"; Rec."TWE Bill-To No. of Cr. Memos")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Credit Memos';
                    DrillDownPageID = "TWE Rental Credit Memos";
                    ToolTip = 'Specifies how many credit memos have been registered for the customer when the customer acts as the bill-to customer.';
                }
                field("TWE Bill-To No. of Pstd. Ship."; Rec."TWE Bill-To No. of Pstd. Ship.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Pstd. Shipments';
                    DrillDownPageID = "TWE Posted Rental Shipments";
                    ToolTip = 'Specifies how many posted shipments have been registered for the customer when the customer acts as the bill-to customer.';
                }
                field("TWE Bill-To No. of Pstd. Inv."; Rec."TWE Bill-To No. of Pstd. Inv.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Pstd. Invoices';
                    DrillDownPageID = "TWE Posted Rental Invoices";
                    ToolTip = 'Specifies how many posted invoices have been registered for the customer when the customer acts as the bill-to customer.';
                }
                field("TWE Bill-To No. of P. Ret. S."; Rec."TWE Bill-To No. of P. Ret. S.")
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Pstd. Return Shipments';
                    //DrillDownPageID = "TWE Posted Return Shipments";
                    ToolTip = 'Specifies how many posted return receipts have been registered for the customer when the customer acts as the bill-to customer.';
                }
                field("TWE Bill-To No. P. Cr. Memos"; Rec."TWE Bill-To No. P. Cr. Memos")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Pstd. Credit Memos';
                    DrillDownPageID = "TWE Posted Rental Credit Memos";
                    ToolTip = 'Specifies how many posted credit memos have been registered for the customer when the customer acts as the bill-to customer.';
                }
            }
            cuegroup(Control23)
            {
                ShowCaption = false;
                field(NoOfQuotesTile; Rec."TWE Bill-To No. of Quotes")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Quotes';
                    DrillDownPageID = "TWE Rental Quotes";
                    ToolTip = 'Specifies how many quotes have been registered for the customer when the customer acts as the bill-to customer.';
                }
                field(NoOfContractsTile; Rec."TWE Bill-To No. of Contracts")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Contracts';
                    DrillDownPageID = "TWE Rental Contract List";
                    ToolTip = 'Specifies how many sales orders have been registered for the customer when the customer acts as the bill-to customer.';
                }
                field(NoOfInvoicesTile; Rec."TWE Bill-To No. of Invoices")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Invoices';
                    DrillDownPageID = "TWE Rental Invoice List";
                    ToolTip = 'Specifies how many invoices have been registered for the customer when the customer acts as the bill-to customer.';
                }
                field(NoOfRetShipmentsTile; Rec."TWE Bill-To No. of Ret. Shipm.")
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Return Shipments';
                    DrillDownPageID = "TWE Rental Return Ship. List";
                    ToolTip = 'Specifies how many return orders have been registered for the customer when the customer acts as the bill-to customer.';
                }
                field(NoOfCrMemosTile; Rec."TWE Bill-To No. of Cr. Memos")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Credit Memos';
                    DrillDownPageID = "TWE Rental Credit Memos";
                    ToolTip = 'Specifies how many credit memos have been registered for the customer when the customer acts as the bill-to customer.';
                }
                field(NoOfPostShipmentTile; Rec."TWE Bill-To No. of Pstd. Ship.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Pstd. Shipments';
                    DrillDownPageID = "TWE Posted Rental Shipments";
                    ToolTip = 'Specifies how many posted shipments have been registered for the customer when the customer acts as the bill-to customer.';
                }
                field(NoOfPostInvoicesTile; Rec."TWE Bill-To No. of Pstd. Inv.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Pstd. Invoices';
                    DrillDownPageID = "TWE Posted Rental Invoices";
                    ToolTip = 'Specifies how many posted invoices have been registered for the customer when the customer acts as the bill-to customer.';
                }
                field(NoOfPostReturnShipmentsTile; Rec."TWE Bill-To No. of P. Ret. S.")
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Pstd. Return Shipments';
                    //DrillDownPageID = "TWE Posted Return Shipments";
                    ToolTip = 'Specifies how many posted return receipts have been registered for the customer when the customer acts as the bill-to customer.';
                }
                field(NoOfPostedCrMemosTile; Rec."TWE Bill-To No. P. Cr. Memos")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Pstd. Credit Memos';
                    DrillDownPageID = "TWE Posted Rental Credit Memos";
                    ToolTip = 'Specifies how many posted credit memos have been registered for the customer when the customer acts as the bill-to customer.';
                }
            }
        }
    }

    actions
    {
    }

    var

    local procedure ShowDetails()
    begin
        PAGE.Run(PAGE::"Customer Card", Rec);
    end;
}

