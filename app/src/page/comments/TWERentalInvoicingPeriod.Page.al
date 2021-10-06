/// <summary>
/// Page TWE Rental Invoicing Period (ID 50003).
/// </summary>
page 50003 "TWE Rental Invoicing Period"
{
    Caption = 'Rental Invoicing Period';
    PageType = List;
    UsageCategory = Lists;
    ApplicationArea = All;
    SourceTable = "TWE Rental Invoicing Period";

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Invoicing Period Code"; Rec."Invoicing Period Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of the involved entry or record.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description of the involved entry or record.';

                }
                field(DateFormular; Rec.DateFormular)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the date formular for rental invoicing period.';

                }
                field("Period Delimitation"; Rec."Period Delimitation")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the period delimitation.';

                }
            }
        }
    }
}
