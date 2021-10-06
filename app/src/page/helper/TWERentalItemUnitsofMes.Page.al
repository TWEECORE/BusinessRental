/// <summary>
/// Page TWE Rental Item Units of Mes. (ID 50008).
/// </summary>
page 50008 "TWE Rental Item Units of Mes."
{
    Caption = 'Rental Item Units of Measure';
    DataCaptionFields = "Item No.";
    PageType = List;
    PopulateAllFields = true;
    SourceTable = "TWE Rental Item Unit Of Meas.";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the item card from which you opened the Item Units of Measure window.';
                    Visible = false;
                }
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                    StyleExpr = StyleName;
                    ToolTip = 'Specifies a unit of measure code that has been set up in the Unit of Measure table.';
                }
                field("Qty. per Unit of Measure"; Rec."Qty. per Unit of Measure")
                {
                    ApplicationArea = Basic, Suite;
                    StyleExpr = StyleName;
                    ToolTip = 'Specifies how many of the base unit of measure are contained in one unit of the item.';
                }
                field(Height; Rec.Height)
                {
                    ApplicationArea = Basic, Suite;
                    StyleExpr = StyleName;
                    ToolTip = 'Specifies the height of one item unit when measured in the unit of measure in the Code field.';
                }
                field(Width; Rec.Width)
                {
                    ApplicationArea = Basic, Suite;
                    StyleExpr = StyleName;
                    ToolTip = 'Specifies the width of one item unit when measured in the specified unit of measure.';
                }
                field(Length; Rec.Length)
                {
                    ApplicationArea = Basic, Suite;
                    StyleExpr = StyleName;
                    ToolTip = 'Specifies the length of one item unit when measured in the specified unit of measure.';
                }
                field(Cubage; Rec.Cubage)
                {
                    ApplicationArea = Basic, Suite;
                    StyleExpr = StyleName;
                    ToolTip = 'Specifies the volume (cubage) of one item unit in the unit of measure in the Code field.';
                }
                field(Weight; Rec.Weight)
                {
                    ApplicationArea = Basic, Suite;
                    StyleExpr = StyleName;
                    ToolTip = 'Specifies the weight of one item unit when measured in the specified unit of measure.';
                }
            }
            group("Current Base Unit of Measure")
            {
                Caption = 'Current Base Unit of Measure';
                field(ItemUnitOfMeasure; ItemBaseUOM)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Base Unit of Measure';
                    Lookup = true;
                    TableRelation = "Unit of Measure".Code;
                    ToolTip = 'Specifies the unit in which the item is held on inventory. The base unit of measure also serves as the conversion basis for alternate units of measure.';

                    trigger OnValidate()
                    begin
                        MainRentalItem.TestField("No.");
                        MainRentalItem.LockTable();
                        MainRentalItem.Find();
                        MainRentalItem.Validate("Base Unit of Measure", ItemBaseUOM);
                        MainRentalItem.Modify(true);
                        CurrPage.Update();
                    end;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        SetStyle();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        if Rec."Item No." = '' then
            Rec."Item No." := MainRentalItem."No.";
        SetStyle();
    end;

    trigger OnOpenPage()
    begin
        if Rec.GetFilter("Item No.") <> '' then begin
            Rec.CopyFilter("Item No.", MainRentalItem."No.");
            if MainRentalItem.FindFirst() then
                ItemBaseUOM := MainRentalItem."Base Unit of Measure";
        end;
    end;

    var
        MainRentalItem: Record "TWE Main Rental Item";
        ItemBaseUOM: Code[10];
        StyleName: Text;

    local procedure SetStyle()
    begin
        if Rec.Code = ItemBaseUOM then
            StyleName := 'Strong'
        else
            StyleName := '';
    end;
}

