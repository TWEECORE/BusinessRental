/// <summary>
/// Page TWE Rental Item Card (ID 50002).
/// </summary>
page 50002 "TWE Rental Item Card"
{
    Caption = 'Rental Item Card';
    PageType = Card;
    PromotedActionCategories = 'New,Process,Report,Navigate,Item';
    SourceTable = "Service Item";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ApplicationArea = Service;
                    Importance = Promoted;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';

                    trigger OnAssistEdit()
                    begin
                        if Rec.AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Service;
                    Importance = Promoted;
                    ToolTip = 'Specifies a description of this item.';
                }
                field("Item No."; Rec."TWE Main Rental Item")
                {
                    ApplicationArea = Service;
                    Importance = Promoted;
                    ToolTip = 'Specifies the item number linked to the service item.';

                    trigger OnValidate()
                    begin
                        Rec.CalcFields("Item Description");
                    end;
                }
                field("Item Description"; Rec."TWE Main Rental Item Desc.")
                {
                    ApplicationArea = Service;
                    DrillDown = false;
                    ToolTip = 'Specifies the description of the item that the service item is linked to.';
                }
                field("Service Item Group Code"; Rec."Service Item Group Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the code of the service item group associated with this item.';
                }
                field("Service Price Group Code"; Rec."Service Price Group Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the code of the Service Price Group associated with this item.';
                }
                field("Serial No."; Rec."TWE Serial No.")
                {
                    ApplicationArea = ItemTracking;
                    AssistEdit = true;
                    ToolTip = 'Specifies the serial number of this item.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Service;
                    Importance = Promoted;
                    ToolTip = 'Specifies the status of the service item.';
                }
                field("Service Item Components"; Rec."Service Item Components")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that there is a component for this service item.';
                }
                field("Search Description"; Rec."Search Description")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies an alternate description to search for the service item.';
                }
                field("Last Service Date"; Rec."Last Service Date")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the date of the last service on this item.';
                }
                field("Warranty Starting Date (Parts)"; Rec."Warranty Starting Date (Parts)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the starting date of the spare parts warranty for this item.';
                    Visible = false;
                }
                field("Warranty Ending Date (Parts)"; Rec."Warranty Ending Date (Parts)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the ending date of the spare parts warranty for this item.';
                    Visible = false;
                }
                field("Warranty % (Parts)"; Rec."Warranty % (Parts)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the percentage of spare parts costs covered by the warranty for the item.';
                    Visible = false;
                }
                field("Warranty Starting Date (Labor)"; Rec."Warranty Starting Date (Labor)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the starting date of the labor warranty for this item.';
                    Visible = false;
                }
                field("Warranty Ending Date (Labor)"; Rec."Warranty Ending Date (Labor)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the ending date of the labor warranty for this item.';
                    Visible = false;
                }
                field("Warranty % (Labor)"; Rec."Warranty % (Labor)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the percentage of labor costs covered by the warranty for this item.';
                    Visible = false;
                }
                field("Preferred Resource"; Rec."Preferred Resource")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the resource that the customer prefers for servicing of the item.';
                    Visible = false;
                }
            }
            group(Detail)
            {
                Caption = 'Detail';
                field("Sales Unit Cost"; Rec."Sales Unit Cost")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the unit cost of this item when it was rental.';
                }
                field("Sales Unit Price"; Rec."Sales Unit Price")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the unit price of this item when it was rental.';
                }
                field("Sales Date"; Rec."Sales Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date when this item was rental.';
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }
                field("Installation Date"; Rec."Installation Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date when this item was installed at the customer''s site.';
                }
                field("TWE Asset No."; Rec."TWE Asset No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Definies the associated asset.';
                }
            }
        }
        area(factboxes)
        {
            part(Control1900316107; "Customer Details FactBox")
            {
                ApplicationArea = Service;
                SubPageLink = "No." = FIELD("Customer No."),
                              "Date Filter" = FIELD("Date Filter");
                Visible = true;
            }
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = true;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Service Item")
            {
                Caption = '&Service Item';
                Image = ServiceItem;
                action("&Components")
                {
                    ApplicationArea = Service;
                    Caption = '&Components';
                    Image = Components;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    RunObject = Page "Service Item Component List";
                    RunPageLink = Active = CONST(true),
                                  "Parent Service Item No." = FIELD("No.");
                    RunPageView = SORTING(Active, "Parent Service Item No.", "Line No.");
                    ToolTip = 'View components that are used in the service item.';
                }
                action("&Dimensions")
                {
                    ApplicationArea = Dimensions;
                    Caption = '&Dimensions';
                    Image = Dimensions;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedIsBig = true;
                    RunObject = Page "Default Dimensions";
                    RunPageLink = "Table ID" = CONST(5940),
                                  "No." = FIELD("No.");
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to journal lines to distribute costs and analyze transaction history.';
                }
                group(Statistics)
                {
                    Caption = 'Statistics';
                    Image = Statistics;
                    action(Action39)
                    {
                        ApplicationArea = Service;
                        Caption = 'Statistics';
                        Image = Statistics;
                        Promoted = true;
                        PromotedCategory = Category5;
                        PromotedIsBig = true;
                        RunObject = Page "Service Item Statistics";
                        RunPageLink = "No." = FIELD("No.");
                        ShortCutKey = 'F7';
                        ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
                    }
                    action("Tr&endscape")
                    {
                        ApplicationArea = Service;
                        Caption = 'Tr&endscape';
                        Image = Trendscape;
                        RunObject = Page "Service Item Trendscape";
                        RunPageLink = "No." = FIELD("No.");
                        ToolTip = 'View a detailed account of service item transactions by time intervals.';
                    }
                }
                action("Co&mments")
                {
                    ApplicationArea = Service;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    Promoted = true;
                    PromotedCategory = Category5;
                    RunObject = Page "Service Comment Sheet";
                    RunPageLink = "Table Name" = CONST("Service Item"),
                                  "Table Subtype" = CONST("0"),
                                  "No." = FIELD("No.");
                    ToolTip = 'View or add comments for the record.';
                }
            }
            group(Documents)
            {
                Caption = 'Documents';
                Image = Documents;
                group("S&ervice Orders")
                {
                    Caption = 'S&ervice Orders';
                    Image = "Order";
                    action("&Item Lines")
                    {
                        ApplicationArea = Service;
                        Caption = '&Item Lines';
                        Image = ItemLines;
                        RunObject = Page "Service Item Lines";
                        RunPageLink = "Service Item No." = FIELD("No.");
                        RunPageView = SORTING("Service Item No.");
                        ToolTip = 'View ongoing service item lines for the item. ';
                    }
                    action("&Service Lines")
                    {
                        ApplicationArea = Service;
                        Caption = '&Service Lines';
                        Image = ServiceLines;
                        RunObject = Page "Service Line List";
                        RunPageLink = "Service Item No." = FIELD("No.");
                        RunPageView = SORTING("Service Item No.");
                        ToolTip = 'View ongoing service lines for the item.';
                    }
                }
                group("Service Shi&pments")
                {
                    Caption = 'Service Shi&pments';
                    Image = Shipment;
                    action(Action117)
                    {
                        ApplicationArea = Service;
                        Caption = '&Item Lines';
                        Image = ItemLines;
                        RunObject = Page "Posted Shpt. Item Line List";
                        RunPageLink = "Service Item No." = FIELD("No.");
                        RunPageView = SORTING("Service Item No.");
                        ToolTip = 'View ongoing service item lines for the item. ';
                    }
                    action(Action113)
                    {
                        ApplicationArea = Service;
                        Caption = '&Service Lines';
                        Image = ServiceLines;
                        RunObject = Page "Posted Serv. Shpt. Line List";
                        RunPageLink = "Service Item No." = FIELD("No.");
                        RunPageView = SORTING("Service Item No.");
                        ToolTip = 'View ongoing service lines for the item.';
                    }
                }
                action("Ser&vice Contracts")
                {
                    ApplicationArea = Service;
                    Caption = 'Ser&vice Contracts';
                    Image = ServiceAgreement;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    RunObject = Page "Serv. Contr. List (Serv. Item)";
                    RunPageLink = "Service Item No." = FIELD("No.");
                    RunPageView = SORTING("Service Item No.", "Contract Status");
                    ToolTip = 'Open the list of ongoing service contracts.';
                }
            }
            group(History)
            {
                Caption = 'History';
                Image = History;
                action("Service Item Lo&g")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Item Lo&g';
                    Image = Log;
                    Promoted = true;
                    PromotedCategory = Category5;
                    RunObject = Page "Service Item Log";
                    RunPageLink = "Service Item No." = FIELD("No.");
                    ToolTip = 'View a list of the service document changes that have been logged. The program creates entries in the window when, for example, the response time or service order status changed, a resource was allocated, a service order was shipped or invoiced, and so on. Each line in this window identifies the event that occurred to the service document. The line contains the information about the field that was changed, its old and new value, the date and time when the change took place, and the ID of the user who actually made the changes.';
                }
                action("Service Ledger E&ntries")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Ledger E&ntries';
                    Image = ServiceLedger;
                    RunObject = Page "Service Ledger Entries";
                    RunPageLink = "Service Item No. (Serviced)" = FIELD("No."),
                                  "Service Order No." = FIELD("Service Order Filter"),
                                  "Service Contract No." = FIELD("Contract Filter"),
                                  "Posting Date" = FIELD("Date Filter");
                    RunPageView = SORTING("Service Item No. (Serviced)", "Entry Type", "Moved from Prepaid Acc.", Type, "Posting Date");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View all the ledger entries for the service item or service order that result from posting transactions in service documents.';
                }
                action("&Warranty Ledger Entries")
                {
                    ApplicationArea = Service;
                    Caption = '&Warranty Ledger Entries';
                    Image = WarrantyLedger;
                    RunObject = Page "Warranty Ledger Entries";
                    RunPageLink = "Service Item No. (Serviced)" = FIELD("No.");
                    RunPageView = SORTING("Service Item No. (Serviced)", "Posting Date", "Document No.");
                    ToolTip = 'View all the ledger entries for the service item or service order that result from posting transactions in service documents that contain warranty agreements.';
                }
            }
        }
        area(processing)
        {
            group(New)
            {
                Caption = 'New';
                Image = NewItem;
                action("New Item")
                {
                    ApplicationArea = Service;
                    Caption = 'New Item';
                    Image = NewItem;
                    RunObject = Page "Item Card";
                    RunPageMode = Create;
                    ToolTip = 'Create an item card based on the stockkeeping unit.';
                }
                action("TWE ConvertRentalItemToItem")
                {
                    Caption = 'Change Rental Item to Item';
                    Image = NewItem;
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Changes rental item to item.';

                    trigger OnAction()
                    var
                        BusinessRentalMgt: Codeunit "TWE Business Rental Mgt.";
                    begin
                        BusinessRentalMgt.CreateItemFromRentalItem(Rec);
                    end;
                }
            }
        }
        // area(reporting)
        // {
        //     action("Service Line Item Label")
        //     {
        //         ApplicationArea = Service;
        //         Caption = 'Service Line Item Label';
        //         Image = "Report";
        //         Promoted = false;
        //         //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
        //         //PromotedCategory = "Report";
        //         RunObject = Report "Service Item Line Labels";
        //         ToolTip = 'View the list of service items on service orders. The report shows the order number, service item number, serial number, and the name of the item.';
        //     }
        // }
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        if Rec."TWE Main Rental Item" = '' then
            if Rec.GetFilter("TWE Main Rental Item") <> '' then
                if Rec.GetRangeMin("TWE Main Rental Item") = Rec.GetRangeMax("TWE Main Rental Item") then
                    Rec."TWE Main Rental Item" := Rec.GetRangeMin("TWE Main Rental Item");
    end;
}

