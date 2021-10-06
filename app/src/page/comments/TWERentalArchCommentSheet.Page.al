/// <summary>
/// Page TWE Rental Arch. Comment Sheet (ID 70704656).
/// </summary>
page 50000 "TWE Rental Arch. Comment Sheet"
{
    Caption = 'Comment Sheet';
    Editable = false;
    PageType = List;
    SourceTable = "TWE Rental Comment Line Arch.";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Date"; Rec.Date)
                {
                    ApplicationArea = Comments;
                    ToolTip = 'Specifies the version number of the archived document.';
                }
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Comments;
                    ToolTip = 'Specifies the document line number of the quote or order to which the comment applies.';
                    Visible = false;
                }
                field(Comment; Rec.Comment)
                {
                    ApplicationArea = Comments;
                    ToolTip = 'Specifies the line number for the comment.';
                }
            }
        }
    }

    actions
    {
    }
}

