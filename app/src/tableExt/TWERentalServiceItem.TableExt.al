/// <summary>
/// TableExtension TWE Rental Service Item (ID 50010) extends Record Service Item.
/// </summary>
tableextension 50010 "TWE Rental Service Item" extends "Service Item"
{
    fields
    {
        field(70704600; "TWE Main Rental Item"; Code[20])
        {
            Caption = 'Main Rental Item';
            DataClassification = CustomerContent;
            TableRelation = "TWE Main Rental Item"."No.";

            trigger OnValidate()
            var
                tweMainRentalItem: Record "TWE Main Rental Item";
            begin
                if Rec."TWE Main Rental Item" <> '' then
                    if tweMainRentalItem.Get(Rec."TWE Main Rental Item") then
                        Rec."TWE Main Rental Item Desc." := tweMainRentalItem.Description;
            end;
        }
        field(50010; "TWE Main Rental Item Desc."; Text[100])
        {
            Caption = 'Main Rental Item Description';
            DataClassification = CustomerContent;
            Editable = False;
        }
        field(70704602; "TWE Rental Item"; Boolean)
        {
            Caption = 'Rental Item';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                CheckIfServiceItemIsRentalItem();
            end;
        }
        field(70704603; "TWE Serial No."; Text[50])
        {
            Caption = 'Serial No.';
            DataClassification = CustomerContent;
        }
        field(70704604; "TWE Rented"; Boolean)
        {
            Caption = 'Rented';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(70704605; "TWE Source Item Entry"; Integer)
        {
            Caption = 'Source Item Entry';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(70704700; "TWE Asset No."; Code[20])
        {
            Caption = 'Asset No.';
            DataClassification = CustomerContent;
            TableRelation = "Fixed Asset"."No." where("TWE Rental Item No." = FIELD("No."));
            Editable = false;
        }

    }

    local procedure CheckIfServiceItemIsRentalItem()
    var
        ChangeItemNoErr: Label 'Please remove the item no. first.';
    begin
        if Rec."TWE Rental Item" then
            if Rec."Item No." <> '' then
                Error(ChangeItemNoErr);
    end;
}
