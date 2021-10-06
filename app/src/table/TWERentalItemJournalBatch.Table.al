/// <summary>
/// Table TWE Rental Item Journal Batch (ID 50013).
/// </summary>
table 50013 "TWE Rental Item Journal Batch"
{
    Caption = 'Item Journal Batch';
    DataCaptionFields = Name, Description;
    LookupPageID = "Item Journal Batches";

    fields
    {
        field(1; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            DataClassification = CustomerContent;
            NotBlank = true;
            TableRelation = "Item Journal Template";
        }
        field(2; Name; Code[10])
        {
            Caption = 'Name';
            DataClassification = CustomerContent;
            NotBlank = true;
        }
        field(3; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
        }
        field(4; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            DataClassification = CustomerContent;
            TableRelation = "Reason Code";

            trigger OnValidate()
            begin
                if "Reason Code" <> xRec."Reason Code" then begin
                    ItemJnlLine.SetRange("Journal Template Name", "Journal Template Name");
                    ItemJnlLine.SetRange("Journal Batch Name", Name);
                    ItemJnlLine.ModifyAll("Reason Code", "Reason Code");
                    Rec.Modify();
                end;
            end;
        }
        field(5; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            DataClassification = CustomerContent;
            TableRelation = "No. Series";

            trigger OnValidate()
            begin
                if "No. Series" <> '' then begin
                    ItemJnlTemplate.Get("Journal Template Name");
                    if ItemJnlTemplate.Recurring then
                        Error(
                          Text000Lbl,
                          FieldCaption("Posting No. Series"));
                    if "No. Series" = "Posting No. Series" then
                        Validate("Posting No. Series", '');
                end;
            end;
        }
        field(6; "Posting No. Series"; Code[20])
        {
            Caption = 'Posting No. Series';
            DataClassification = CustomerContent;
            TableRelation = "No. Series";

            trigger OnValidate()
            begin
                if ("Posting No. Series" = "No. Series") and ("Posting No. Series" <> '') then
                    FieldError("Posting No. Series", StrSubstNo(Text001Lbl, "Posting No. Series"));
                ItemJnlLine.SetRange("Journal Template Name", "Journal Template Name");
                ItemJnlLine.SetRange("Journal Batch Name", Name);
                ItemJnlLine.ModifyAll("Posting No. Series", "Posting No. Series");
                Modify();
            end;
        }
        field(21; "Template Type"; Enum "Item Journal Template Type")
        {
            CalcFormula = Lookup("Item Journal Template".Type WHERE(Name = FIELD("Journal Template Name")));
            Caption = 'Template Type';
            Editable = false;
            FieldClass = FlowField;
        }
        field(22; Recurring; Boolean)
        {
            CalcFormula = Lookup("Item Journal Template".Recurring WHERE(Name = FIELD("Journal Template Name")));
            Caption = 'Recurring';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Journal Template Name", Name)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        ItemJnlLine.SetRange("Journal Template Name", "Journal Template Name");
        ItemJnlLine.SetRange("Journal Batch Name", Name);
        ItemJnlLine.DeleteAll(true);
    end;

    trigger OnInsert()
    begin
        LockTable();
        ItemJnlTemplate.Get("Journal Template Name");
    end;

    trigger OnRename()
    begin
        ItemJnlLine.SetRange("Journal Template Name", xRec."Journal Template Name");
        ItemJnlLine.SetRange("Journal Batch Name", xRec.Name);
        while ItemJnlLine.FindFirst() do
            ItemJnlLine.Rename("Journal Template Name", Name, ItemJnlLine."Line No.");
    end;

    var
        ItemJnlTemplate: Record "Item Journal Template";
        ItemJnlLine: Record "Item Journal Line";
        Text000Lbl: Label 'Only the %1 field can be filled in on recurring journals.', Comment = '%1 Posting No. Series';
        Text001Lbl: Label 'must not be %1', Comment = '%1 Posting No. Series';

    /// <summary>
    /// SetupNewBatch.
    /// </summary>
    procedure SetupNewBatch()
    begin
        ItemJnlTemplate.Get("Journal Template Name");
        "No. Series" := ItemJnlTemplate."No. Series";
        "Posting No. Series" := ItemJnlTemplate."Posting No. Series";
        "Reason Code" := ItemJnlTemplate."Reason Code";

        OnAfterSetupNewBatch(Rec);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetupNewBatch(var RentalItemJournalBatch: Record "TWE Rental Item Journal Batch")
    begin
    end;
}

