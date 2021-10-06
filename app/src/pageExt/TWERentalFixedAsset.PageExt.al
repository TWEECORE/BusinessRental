pageextension 50001 "TWE Rental Fixed Asset" extends "Fixed Asset Card"
{
    layout
    {
        addafter(Maintenance)
        {
            group("TWE Rental")
            {
                Caption = 'Rental';

                field("TWE Rental Item No."; Rec."TWE Rental Item No.")
                {
                    Caption = 'Rental Item No.';
                    ApplicationArea = All;
                    ToolTip = 'Definies the rental item no.';
                    Editable = EditableRentalItemNo;

                    trigger OnValidate()
                    begin
                        if Rec."TWE Rental Item No." <> '' then
                            EditableRentalItemNo := false
                        else
                            EditableRentalItemNo := true;
                    end;
                }
                field("TWE Rental Item Description"; Rec."TWE Rental Item Description")
                {
                    Caption = 'Rental Item Description';
                    ApplicationArea = All;
                    ToolTip = 'Definies the rental item description.';
                }
                field("TWE Rental Item Serial No."; Rec."TWE Rental Item Serial No.")
                {
                    Caption = 'Rental Item Serial No.';
                    ApplicationArea = All;
                    ToolTip = 'Definies the rental item serial no.';
                }
                field("TWE Main Rental Item No."; Rec."TWE Main Rental Item No.")
                {
                    Caption = 'Main Rental Item No.';
                    ApplicationArea = All;
                    ToolTip = 'Definies the main rental item no.';
                }
                field("TWE Main Rental Item Desc."; Rec."TWE Main Rental Item Desc.")
                {
                    Caption = 'Main Rental Item Description';
                    ApplicationArea = All;
                    ToolTip = 'Definies the main rental item description.';
                }
                field("TWE Item No."; Rec."TWE Item No.")
                {
                    Caption = 'Associated Item No.';
                    ApplicationArea = All;
                    ToolTip = 'Definies the associated item no.';
                }
                field("TWE Item Description"; Rec."TWE Item Description")
                {
                    Caption = 'Associated Item Description';
                    ApplicationArea = All;
                    ToolTip = 'Definies the associated item description.';
                }


            }
        }
    }
    var
        EditableRentalItemNo: Boolean;


    trigger OnAfterGetRecord()
    begin
        if Rec."TWE Rental Item No." <> '' then
            EditableRentalItemNo := false
        else
            EditableRentalItemNo := true;
    end;
}
