/// <summary>
/// PageExtension TWE Rental Service Item (ID 50002) extends Record Service Item Card.
/// </summary>
pageextension 50002 "TWE Rental Service Item" extends "Service Item Card"

{
    layout
    {
        addafter("Item No.")
        {
            field("TWE Rental Item"; Rec."TWE Rental Item")
            {
                ApplicationArea = Suite;
                ToolTip = 'Indicates whether this service item is a rental item.';
            }
        }
        addafter("Last Service Date")
        {
            field("TWE Asset No."; Rec."TWE Asset No.")
            {
                ApplicationArea = Suite;
                ToolTip = 'Definies the associated asset.';
            }
        }
    }

    actions
    {
        addafter("&Service Item")
        {
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
}
