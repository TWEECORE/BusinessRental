/// <summary>
/// Page TWE Rental Line FactBox (ID 50006).
/// </summary>
page 50006 "TWE Rental Line FactBox"
{
    Caption = 'Rental Line Details';
    PageType = CardPart;
    SourceTable = "TWE Rental Line";

    layout
    {
        area(content)
        {
            field(ItemNo; ShowNo())
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Item No.';
                Lookup = false;
                ToolTip = 'Specifies the item that is handled on the sales line.';

                trigger OnDrillDown()
                begin
                    RentalInfoPaneMgt.LookupItem(Rec);
                end;
            }
            field("Required Quantity"; Rec."Outstanding Quantity" - Rec."Reserved Quantity")
            {
                ApplicationArea = Reservation;
                Caption = 'Required Quantity';
                DecimalPlaces = 0 : 5;
                ToolTip = 'Specifies how many units of the item are required on the sales line.';
            }
            group(Attachments)
            {
                Caption = 'Attachments';
                field("Attached Doc Count"; Rec."Attached Doc Count")
                {
                    ApplicationArea = All;
                    Caption = 'Documents';
                    ToolTip = 'Specifies the number of attachments.';

                    trigger OnDrillDown()
                    var
                        DocumentAttachmentDetails: Page "Document Attachment Details";
                        RecRef: RecordRef;
                    begin
                        RecRef.GetTable(Rec);
                        DocumentAttachmentDetails.OpenForRecRef(RecRef);
                        DocumentAttachmentDetails.RunModal();
                    end;
                }
            }
            group(Availability)
            {
                Caption = 'Availability';
                field("Scheduled Receipt"; RentalInfoPaneMgt.CalcScheduledReceipt(Rec))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Scheduled Receipt';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies how many units of the assembly component are inbound on purchase orders, transfer orders, assembly orders, firm planned production orders, and released production orders.';
                }
                field("Reserved Receipt"; RentalInfoPaneMgt.CalcReservedRequirements(Rec))
                {
                    ApplicationArea = Reservation;
                    Caption = 'Reserved Receipt';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies how many units of the item on the sales line are reserved on incoming receipts.';
                }
                field("Gross Requirements"; RentalInfoPaneMgt.CalcGrossRequirements(Rec))
                {
                    ApplicationArea = Service;
                    Caption = 'Gross Requirements';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies, for the item on the sales line, dependent demand plus independent demand. Dependent demand comes production order components of all statuses, assembly order components, and planning lines. Independent demand comes from sales orders, transfer orders, service orders, job tasks, and demand forecasts.';
                }
                field("Reserved Requirements"; RentalInfoPaneMgt.CalcReservedDemand(Rec))
                {
                    ApplicationArea = Reservation;
                    Caption = 'Reserved Requirements';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies, for the item on the sales line, how many are reserved on demand records.';
                }
            }
            group(Item)
            {
                Caption = 'Item';
                field(UnitofMeasureCode; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Unit of Measure Code';
                    ToolTip = 'Specifies the unit of measure that is used to determine the value in the Unit Price field on the sales line.';
                }
                field("Qty. per Unit of Measure"; Rec."Qty. per Unit of Measure")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Qty. per Unit of Measure';
                    ToolTip = 'Specifies an auto-filled number if you have included Sales Unit of Measure on the item card and a quantity in the Qty. per Unit of Measure field.';
                }
                field(SalesPrices; RentalInfoPaneMgt.CalcNoOfRentalPrices(Rec))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Prices';
                    DrillDown = true;
                    ToolTip = 'Specifies special sales prices that you grant when certain conditions are met, such as customer, quantity, or ending date. The price agreements can be for individual customers, for a group of customers, for all customers or for a campaign.';

                    trigger OnDrillDown()
                    begin
                        Rec.PickPrice();
                        CurrPage.Update();
                    end;
                }
                field(SalesLineDiscounts; RentalInfoPaneMgt.CalcNoOfRentalLineDisc(Rec))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Line Discounts';
                    DrillDown = true;
                    ToolTip = 'Specifies how many special discounts you grant for the sales line. Choose the value to see the sales line discounts.';

                    trigger OnDrillDown()
                    begin
                        Rec.PickDiscount();
                        CurrPage.Update();
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    begin
        Rec.ClearRentalHeader();
    end;

    trigger OnAfterGetRecord()
    begin
        Rec.CalcFields("Reserved Quantity", "Attached Doc Count");
        RentalInfoPaneMgt.ResetItemNo();
    end;

    var
        RentalInfoPaneMgt: Codeunit "TWE Rental Info-Pane Mgt.";

    local procedure ShowNo(): Code[20]
    begin
        if Rec.Type <> Rec.Type::"Rental Item" then
            exit('');
        exit(Rec."No.");
    end;
}

