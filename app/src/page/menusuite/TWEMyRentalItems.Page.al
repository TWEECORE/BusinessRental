/// <summary>
/// Page TWE My Main Rental Items (ID 70704712).
/// </summary>
page 50001 "TWE My Rental Items"
{
    Caption = 'My Rental Items';
    PageType = ListPart;
    SourceTable = "TWE My Rental Item";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Item No."; Rec."Rental Item No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the item numbers that are displayed in the My Item Cue on the Role Center.';

                    trigger OnValidate()
                    begin
                        SyncFieldsWithItem();
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Description';
                    DrillDown = false;
                    Lookup = false;
                    ToolTip = 'Specifies a description of the item.';
                }
                field("Unit Price"; Rec."Unit Price")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Unit Price';
                    DrillDown = false;
                    Lookup = false;
                    ToolTip = 'Specifies the item''s unit price.';
                }/* 
                field(Inventory; Inventory)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Inventory';
                    ToolTip = 'Specifies the inventory quantities of my items.';
                    Visible = false;
                } */
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Open)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Open';
                Image = ViewDetails;
                RunObject = Page "Service Item Card";
                RunPageLink = "No." = FIELD("Rental Item No.");
                RunPageMode = View;
                ShortCutKey = 'Return';
                ToolTip = 'Open the card for the selected record.';
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        SyncFieldsWithItem();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Clear(RentalItem)
    end;

    trigger OnOpenPage()
    begin
        Rec.SetRange("User ID", UserId);
    end;

    var
        RentalItem: Record "Service Item";

    local procedure SyncFieldsWithItem()
    var
        MyRentalItem: Record "TWE My Rental Item";
    begin
        Clear(MyRentalItem);

        if MyRentalItem.Get(Rec."Rental Item No.") then
            if (Rec.Description <> MyRentalItem.Description) or (Rec."Unit Price" <> MyRentalItem."Unit Price") then begin
                Rec.Description := MyRentalItem.Description;
                Rec."Unit Price" := MyRentalItem."Unit Price";
                if MyRentalItem.Get(Rec."User ID", Rec."Rental Item No.") then
                    Rec.Modify();
            end;
    end;
}

