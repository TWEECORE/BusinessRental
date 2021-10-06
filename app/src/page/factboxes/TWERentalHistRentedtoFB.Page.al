/// <summary>
/// Page TWE Rental Hist. Rented-to FB (ID 50004).
/// </summary>
page 50004 "TWE Rental Hist. Rented-to FB"
{
    Caption = 'Rented-to Customer Rental History';
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
            group(Control23)
            {
                ShowCaption = false;
                Visible = false;
                field("TWE No. of Quotes"; Rec."TWE No. of Quotes")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ongoing Rental Quotes';
                    DrillDownPageID = "TWE Rental Quotes";
                    ToolTip = 'Specifies the number of rental quotes that have been registered for the customer.';
                }
                field("TWE No. of Contracts"; Rec."TWE No. of Contracts")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ongoing Rental Contracts';
                    DrillDownPageID = "TWE Rental Contract List";
                    ToolTip = 'Specifies the number of rental contracts that have been registered for the customer.';
                }
                field("TWE No. of Invoices"; Rec."TWE No. of Invoices")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ongoing Rental Invoices';
                    DrillDownPageID = "TWE Rental Invoice List";
                    ToolTip = 'Specifies the number of unposted rental invoices that have been registered for the customer.';
                }
                field("TWE No. of Return Shipments"; Rec."TWE No. of Return Shipments")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ongoing Rental Return Shipments';
                    DrillDownPageID = "TWE Rental Return Ship. List";
                    ToolTip = 'Specifies the number of rental return shipments that have been registered for the customer.';
                }
                field("TWE No. of Cr. Memos"; Rec."TWE No. of Cr. Memos")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ongoing Rental Credit Memos';
                    DrillDownPageID = "TWE Rental Credit Memos";
                    ToolTip = 'Specifies the number of unposted rental credit memos that have been registered for the customer.';
                }
                field("TWE No. of Post. Shipments"; Rec."TWE No. of Post. Shipments")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posted Rental Shipments';
                    DrillDownPageID = "TWE Posted Rental Shipments";
                    ToolTip = 'Specifies the number of posted rental shipments that have been registered for the customer.';
                }
                field("TWE No. of Post. Invoices"; Rec."TWE No. of Post. Invoices")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posted Rental Invoices';
                    DrillDownPageID = "TWE Posted Rental Invoices";
                    ToolTip = 'Specifies the number of posted rental invoices that have been registered for the customer.';
                }
                field("TWE No. of Post. Return Shipm."; Rec."TWE No. of Post. Return Shipm.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posted Return Return Shipments';
                    DrillDownPageID = "TWE Posted Rental Return Ship.";
                    ToolTip = 'Specifies the number of posted rental return shipments that have been registered for the customer.';
                }
                field("TWE No. of Post. Cr. Memos"; Rec."TWE No. of Post. Cr. Memos")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posted Rental Credit Memos';
                    DrillDownPageID = "TWE Posted Rental Credit Memos";
                    ToolTip = 'Specifies the number of posted rental credit memos that have been registered for the customer.';
                }
            }
            cuegroup(Control2)
            {
                ShowCaption = false;
                field(NoOfQuotesTile; Rec."TWE No. of Quotes")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ongoing Rental Quotes';
                    DrillDownPageID = "TWE Rental Quotes";
                    ToolTip = 'Specifies the number of rental quotes that have been registered for the customer.';
                }
                field(NoOfContractsTile; Rec."TWE No. of Contracts")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ongoing Rental Contracts';
                    DrillDownPageID = "TWE Rental Contract List";
                    ToolTip = 'Specifies the number of rental contracts that have been registered for the customer.';
                }
                field(NoOfInvoicesTile; Rec."TWE No. of Invoices")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ongoing Rental Invoices';
                    DrillDownPageID = "TWE Rental Invoice List";
                    ToolTip = 'Specifies the number of unposted rental invoices that have been registered for the customer.';
                }
                field(NoOfRetShipmentsTile; Rec."TWE No. of Return Shipments")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ongoing Rental Return Shipments';
                    DrillDownPageID = "TWE Rental Return Ship. List";
                    ToolTip = 'Specifies the number of rental return shipments that have been registered for the customer.';
                }
                field(NoOfCrMemosTile; Rec."TWE No. of Cr. Memos")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ongoing Rental Credit Memos';
                    DrillDownPageID = "TWE Rental Credit Memos";
                    ToolTip = 'Specifies the number of unposted rental credit memos that have been registered for the customer.';
                }
                field(NoOfPostShipmentsTile; Rec."TWE No. of Post. Shipments")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posted Rental Shipments';
                    DrillDownPageID = "TWE Posted Rental Shipments";
                    ToolTip = 'Specifies the number of posted rental shipments that have been registered for the customer.';
                }
                field(NoOfPostInvoicesTile; Rec."TWE No. of Post. Invoices")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posted Rental Invoices';
                    DrillDownPageID = "TWE Posted Rental Invoices";
                    ToolTip = 'Specifies the number of posted rental invoices that have been registered for the customer.';
                }
                field(NoOfPostRetShipmentTile; Rec."TWE No. of Post. Return Shipm.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posted Return Return Shipments';
                    DrillDownPageID = "TWE Posted Rental Return Ship.";
                    ToolTip = 'Specifies the number of posted rental return shipments that have been registered for the customer.';
                }
                field(NoOfPostCrMemosTile; Rec."TWE No. of Post. Cr. Memos")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posted Rental Credit Memos';
                    DrillDownPageID = "TWE Posted Rental Credit Memos";
                    ToolTip = 'Specifies the number of posted rental credit memos that have been registered for the customer.';
                }
            }
        }
    }

    var

    local procedure ShowDetails()
    begin
        PAGE.Run(PAGE::"Customer Card", Rec);
    end;
}

