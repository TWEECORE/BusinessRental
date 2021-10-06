/// <summary>
/// Page TWE Rental Rates (ID 70704604).
/// </summary>
page 50015 "TWE Rental Rates"
{
    Caption = 'Rental Rates';
    PageType = List;
    UsageCategory = Lists;
    ApplicationArea = All;
    SourceTable = "TWE Rental Rates";

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Rate Code"; Rec."Rate Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of the involved entry or record.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description of the involved entry or record.';

                }
                field("Rental Rate Type"; Rec."Rental Rate Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the type of the rental rate.';

                }
                field("Rental Calendar"; Rec."Rental Calendar")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the rental calendar, based on the basis calendar from Business Central.';

                }
                field("Qty. in Days"; Rec."Qty. in Days")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the quantity of days within the rental rate.';

                }
                field("DateFormular for Flat Rate"; Rec."DateFormular for Flat Rate")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the date formular for rental rates.';

                }
                field("One-time Rental"; Rec."One-time Rental")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether this rental rate is a one-time rental.';

                }
                field("Print Text for Documents"; Rec."Print Text for Documents")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the text that will be printed on documents.';

                }


            }
        }
    }
}
