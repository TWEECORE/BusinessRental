/// <summary>
/// PageExtension TWE Item (ID 50000) extends Record Item Card.
/// </summary>
pageextension 50000 "TWE Item" extends "Item Card"
{
    layout
    {

    }

    actions
    {
        addafter(CopyItem)
        {
            action("TWE ChangeItemToRentalItem")
            {
                Caption = 'Change Item to Main Rental Item';
                Image = NewItem;
                ApplicationArea = Basic, Suite;
                ToolTip = 'Changes item to main rental item.';

                trigger OnAction()
                var
                    BusinessRentalMgt: Codeunit "TWE Business Rental Mgt.";
                begin
                    BusinessRentalMgt.CreateMainRentalItemFromItem(Rec);
                end;
            }
        }
    }
}
