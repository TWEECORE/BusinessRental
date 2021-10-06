/// <summary>
/// Page TWE Rent.-Item-Attr.-Value Ed. (ID 50020).
/// </summary>
page 50020 "TWE Rent.-Item-Attr.-Value Ed."
{
    Caption = 'Main Rental Item Attribute Values';
    PageType = StandardDialog;
    SourceTable = "TWE Main Rental Item";

    layout
    {
        area(content)
        {
            part(ItemAttributeValueList; "TWE MainRentItemAttrValueList")
            {
                ApplicationArea = Basic, Suite;
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        CurrPage.ItemAttributeValueList.PAGE.LoadAttributes(Rec."No.");
    end;
}

