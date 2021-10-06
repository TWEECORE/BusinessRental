tableextension 50004 "TWE Rental Fixed Asset" extends "Fixed Asset"
{
    fields
    {
        field(50004; "TWE Rental Item No."; Code[20])
        {
            Caption = 'Rental Item No.';
            DataClassification = CustomerContent;
            TableRelation = "Service Item"."No.";

            trigger OnValidate()
            var
                RentalItem: Record "Service Item";
                MainRentalItem: Record "TWE Main Rental Item";
                Item: Record Item;
            begin
                if "TWE Rental Item No." <> '' then
                    if RentalItem.Get("TWE Rental Item No.") then begin
                        "TWE Rental Item Description" := RentalItem.Description;
                        "TWE Rental Item Serial No." := RentalItem."TWE Serial No.";
                        "TWE Main Rental Item No." := RentalItem."TWE Main Rental Item";
                        "TWE Main Rental Item Desc." := RentalItem."TWE Main Rental Item Desc.";

                        if MainRentalItem.Get("TWE Main Rental Item No.") then
                            "TWE Item No." := MainRentalItem."Orginal Item No.";

                        if Item.Get(MainRentalItem."Orginal Item No.") then
                            "TWE Item Description" := Item.Description;

                        RentalItem."TWE Asset No." := Rec."No.";
                        RentalItem.Modify(true);
                    end;
            end;
        }
        field(70704701; "TWE Rental Item Description"; Text[100])
        {
            Caption = 'Rental Item Description';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(70704702; "TWE Rental Item Serial No."; Text[50])
        {
            Caption = 'Rental Item Serial No.';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(70704703; "TWE Main Rental Item No."; Code[20])
        {
            Caption = 'Main Rental Item No.';
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(70704704; "TWE Main Rental Item Desc."; Text[100])
        {
            Caption = 'Main Rental Item Desc.';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(70704705; "TWE Item No."; Code[20])
        {
            Caption = 'Item No.';
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(70704706; "TWE Item Description"; Text[100])
        {
            Caption = 'Item Description';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }
}
