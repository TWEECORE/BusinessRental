/// <summary>
/// Page Main Rent. Item Inv. FactBox (ID 50002).
/// </summary>
page 50002 "TWE Main R. Item Inv. FactBox"
{
    Caption = 'Main Rental Item Details - Invoicing';
    PageType = CardPart;
    SourceTable = "TWE Main Rental Item";

    layout
    {
        area(content)
        {
            field("No."; Rec."No.")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Main Rental Item No.';
                ToolTip = 'Specifies the number of the item.';

                trigger OnDrillDown()
                begin
                    ShowDetails();
                end;
            }
            field("Costing Method"; Rec."Costing Method")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies how the item''s cost flow is recorded and whether an actual or budgeted value is capitalized and used in the cost calculation.';
            }
            field("Unit Cost"; Rec."Unit Cost")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the cost of one unit of the item or resource on the line.';
            }
            field("Profit %"; Rec."Profit %")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the profit margin that you want to sell the item at. You can enter a profit percentage manually or have it entered according to the Price/Profit Calculation field';
            }
            field("Unit Price"; Rec."Unit Price")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the price of one unit of the item or resource. You can enter a price manually or have it entered according to the Price/Profit Calculation field on the related card.';
            }
        }
    }

    actions
    {
    }

    local procedure ShowDetails()
    begin
        PAGE.Run(PAGE::"TWE Main Rental Item Card", Rec);
    end;
}

