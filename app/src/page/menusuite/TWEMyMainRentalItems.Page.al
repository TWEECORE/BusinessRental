/// <summary>
/// Page TWE My Main Rental Items (ID 70704712).
/// </summary>
page 50000 "TWE My Main Rental Items"
{
    Caption = 'My Main Rental Items';
    PageType = ListPart;
    SourceTable = "TWE My Main Rental Item";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Item No."; Rec."Main Rental Item No.")
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
                RunObject = Page "TWE Main Rental Item Card";
                RunPageLink = "No." = FIELD("Main Rental Item No.");
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
        Clear(MainRentalItem)
    end;

    trigger OnOpenPage()
    begin
        Rec.SetRange("User ID", UserId);
    end;

    var
        MainRentalItem: Record "TWE Main Rental Item";

    local procedure SyncFieldsWithItem()
    var
        MyMainRentalItem: Record "TWE My Main Rental Item";
    begin
        Clear(MyMainRentalItem);

        if MyMainRentalItem.Get(Rec."Main Rental Item No.") then
            if (Rec.Description <> MyMainRentalItem.Description) or (Rec."Unit Price" <> MainRentalItem."Unit Price") then begin
                Rec.Description := MyMainRentalItem.Description;
                Rec."Unit Price" := MyMainRentalItem."Unit Price";
                if MyMainRentalItem.Get(Rec."User ID", Rec."Main Rental Item No.") then
                    Rec.Modify();
            end;
    end;
}

