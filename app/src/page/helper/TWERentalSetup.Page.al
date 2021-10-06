/// <summary>
/// Page TWE Rental Setup (ID 50100).
/// </summary>
page 50016 "TWE Rental Setup"
{
    Caption = 'Rental Setup';
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "TWE Rental Setup";

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field("Credit Warnings"; Rec."Credit Warnings")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether to warn about the customer''s status when you create a sales order or invoice.';
                }
                field("Shipment on Invoice"; Rec."Shipment on Invoice")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies if a posted shipment and a posted invoice are automatically created when you post an invoice.';
                }
                field("Invoice Rounding"; Rec."Invoice Rounding")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if amounts are rounded for sales invoices. Rounding is applied as specified in the Inv. Rounding Precision (LCY) field in the General Ledger Setup window. ';
                }
                field("Default Posting Date"; Rec."Default Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how to use the Posting Date field on sales documents.';
                }
                field("Allow VAT Difference"; Rec."Allow VAT Difference")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether to allow the manual adjustment of VAT amounts in sales documents.';
                }
                field("Create an unbooked Invoice"; Rec."Create an unbooked Invoice")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if an unbooked invoice or a posted invoice are created when you post an contract.';
                }
                field("Logo Position on Documents"; Rec."Logo Position on Documents")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the position of your company logo on business letters and documents.';
                }
                field("Display of the address line"; Rec."Display of the address line")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies whether an address line should be displayed in documents.';
                }
                field("Base Unit for new Rental Item"; Rec."Base Unit for new Rental Item")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the base unit of measure for new Rental Items.';
                }
                field("Standard Item Template Name"; Rec."Standard Jnl. Template Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the standard item template name for convert.';
                }
                field("Standard Item Jnl. Name"; Rec."Standard Item Jnl. Batch Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the standard item name for convert.';
                }
                field("Delete Contract after completion"; Rec."Delete Contract")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if a rental contract will be deleted after completion or set to completed.';
                }
                field("Stand. Gen. Bus. Posting Group"; Rec."Stand. Gen. Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the standard gen. business posting group for convert.';
                }
            }
            group(NoSeries)
            {
                Caption = 'No. Series';
                field("Main Rental Item Nos."; Rec."Main Rental Item Nos.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number series that will be used to assign numbers to main rental items.';
                }
                field("Rental Item Nos."; Rec."Rental Item Nos.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number series that will be used to assign numbers to rental items.';
                }
                field("Rental Quote Nos."; Rec."Rental Quote Nos.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number series that will be used to assign numbers to rental quotes.';
                }
                field("Rental Contract Nos."; Rec."Rental Contract Nos.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number series that will be used to assign numbers to rental contracts.';
                }
                field("Rental Invoice Nos."; Rec."Rental Invoice Nos.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number series that will be used to assign numbers to rental invoices.';
                }

                field("Posted Rental Invoice Nos."; Rec."Posted Rental Invoice Nos.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number series that will be used to assign numbers to posted rental invoices.';
                }
                field("Rental Credit Memo Nos."; Rec."Rental Credit Memo Nos.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number series that will be used to assign numbers to rental credit memos.';
                }
                field("Posted Rental Credit Memo Nos."; Rec."Posted Rental Credit Memo Nos.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number series that will be used to assign numbers to posted rental credit memos.';
                }
                field("Rental Shipment Nos."; Rec."Rental Shipment Nos.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number series that will be used to assign numbers to rental shipment nos.';
                }
                field("Posted Rental Shipment Nos."; Rec."Posted Rental Shipment Nos.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number series that will be used to assign numbers to posted rental shipment nos.';
                }
                field("Rental Return Shipment Nos."; Rec."Rental Return Shipment Nos.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number series that will be used to assign numbers to rental return shipment nos.';
                }
                field("Post. Rent. Return Shipm. Nos."; Rec."Post. Rent. Return Shipm. Nos.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number series that will be used to assign numbers to posted rental return shipment nos.';
                }

            }
            group(Archiving)
            {
                Caption = 'Archiving';
                field("Archive Quotes"; Rec."Archive Quotes")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if you want to archive rental quotes when they are deleted.';
                }
                field("Archive Orders"; Rec."Archive Contracts")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if you want to archive rental contracts when they are deleted.';
                }
            }
            group("Asset Mgt.")
            {
                Caption = 'Asset Mgt.';

                field("Auto. Creation of Assets"; Rec."Auto. Creation of Assets")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Defines whether you want to activate the automatic asset creation.';
                }
                field("Stand. Asset Class Code"; Rec."Stand. Asset Class Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Defines the standard class code for the asset.';
                }
                field("Stand. Asset Subclass Code"; Rec."Stand. Asset Subclass Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Defines the standard subclass code for the asset.';
                }
                field("Standard Asset Posting Group"; Rec."Standard Asset Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Defines the standard posting group for the asset.';
                }
                field("Stand. Asset Location Code"; Rec."Stand. Asset Location Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Defines the standard location code for the asset.';
                }
            }
        }
    }
}
