/// <summary>
/// Page TWE Main Rent. Item Att. FB (ID 50001).
/// </summary>
page 50001 "TWE Main Rent. Item Att. FB"
{
    Caption = 'Main Rental Item Attributes';
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = ListPart;
    RefreshOnActivate = true;
    SourceTable = "Item Attribute Value";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control2)
            {
                ShowCaption = false;
                field(Attribute; Rec.GetAttributeNameInCurrentLanguage())
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Attribute';
                    ToolTip = 'Specifies the name of the item attribute.';
                    Visible = TranslatedValuesVisible;
                }
                field(Value; Rec.GetValueInCurrentLanguage())
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Value';
                    ToolTip = 'Specifies the value of the item attribute.';
                    Visible = TranslatedValuesVisible;
                }
                field("Attribute Name"; Rec."Attribute Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Attribute';
                    ToolTip = 'Specifies the name of the item attribute.';
                    Visible = NOT TranslatedValuesVisible;
                }
                field(RawValue; Rec.Value)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Value';
                    ToolTip = 'Specifies the value of the item attribute.';
                    Visible = NOT TranslatedValuesVisible;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Edit)
            {
                AccessByPermission = TableData "Item Attribute" = R;
                ApplicationArea = Basic, Suite;
                Caption = 'Edit';
                Image = Edit;
                ToolTip = 'Edit item''s attributes, such as color, size, or other characteristics that help to describe the item.';
                Visible = IsItem;

                trigger OnAction()
                var
                    MainRentalItem: Record "TWE Main Rental Item";
                begin
                    if not IsItem then
                        exit;
                    if not MainRentalItem.Get(ContextValue) then
                        exit;
                    PAGE.RunModal(PAGE::"TWE Rent.-Item-Attr.-Value Ed.", MainRentalItem);
                    CurrPage.SaveRecord();
                    LoadItemAttributesData(ContextValue);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.SetAutoCalcFields("Attribute Name");
        TranslatedValuesVisible := ClientTypeManagement.GetCurrentClientType() <> CLIENTTYPE::Phone;
    end;

    var
        ClientTypeManagement: Codeunit "Client Type Management";
        TranslatedValuesVisible: Boolean;
        ContextType: Option "None",Item,Category;
        ContextValue: Code[20];
        IsItem: Boolean;

    /// <summary>
    /// LoadItemAttributesData.
    /// </summary>
    /// <param name="KeyValue">Code[20].</param>
    procedure LoadItemAttributesData(KeyValue: Code[20])
    begin
        Rec.LoadItemAttributesFactBoxDataForRental(KeyValue);
        SetContext(ContextType::Item, KeyValue);
        CurrPage.Update(false);
    end;

    /// <summary>
    /// LoadCategoryAttributesData.
    /// </summary>
    /// <param name="CategoryCode">Code[20].</param>
    procedure LoadCategoryAttributesData(CategoryCode: Code[20])
    begin
        Rec.LoadCategoryAttributesFactBoxData(CategoryCode);
        SetContext(ContextType::Category, CategoryCode);
        CurrPage.Update(false);
    end;

    local procedure SetContext(NewType: Option; NewValue: Code[20])
    begin
        ContextType := NewType;
        ContextValue := NewValue;
        IsItem := ContextType = ContextType::Item;
    end;
}

