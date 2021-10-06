/// <summary>
/// Table TWE Rental Comment Line (ID 50002).
/// </summary>
table 50002 "TWE Rental Comment Line"
{
    Caption = 'Rental Comment Line';
    DrillDownPageID = "TWE Rental Comment List";
    LookupPageID = "TWE Rental Comment List";

    fields
    {
        field(1; "Document Type"; Enum "TWE Rental Comment Document Type")
        {
            Caption = 'Document Type';
            DataClassification = CustomerContent;
        }
        field(2; "No."; Code[20])
        {
            Caption = 'No.';
            DataClassification = CustomerContent;
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
            DataClassification = CustomerContent;
        }
        field(4; "Date"; Date)
        {
            Caption = 'Date';
            DataClassification = CustomerContent;
        }
        field(5; "Code"; Code[10])
        {
            Caption = 'Code';
            DataClassification = CustomerContent;
        }
        field(6; Comment; Text[80])
        {
            Caption = 'Comment';
            DataClassification = CustomerContent;
        }
        field(7; "Document Line No."; Integer)
        {
            Caption = 'Document Line No.';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(Key1; "Document Type", "No.", "Document Line No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    /// <summary>
    /// SetUpNewLine.
    /// </summary>
    procedure SetUpNewLine()
    var
        TWERentalCommentLine: Record "TWE Rental Comment Line";
    begin
        TWERentalCommentLine.SetRange("Document Type", "Document Type");
        TWERentalCommentLine.SetRange("No.", "No.");
        TWERentalCommentLine.SetRange("Document Line No.", "Document Line No.");
        TWERentalCommentLine.SetRange(Date, WorkDate());
        if not TWERentalCommentLine.FindFirst() then
            Date := WorkDate();

        OnAfterSetUpNewLine(Rec, TWERentalCommentLine);
    end;

    /// <summary>
    /// CopyComments.
    /// </summary>
    /// <param name="FromDocumentType">Integer.</param>
    /// <param name="ToDocumentType">Integer.</param>
    /// <param name="FromNumber">Code[20].</param>
    /// <param name="ToNumber">Code[20].</param>
    procedure CopyComments(FromDocumentType: Integer; ToDocumentType: Integer; FromNumber: Code[20]; ToNumber: Code[20])
    var
        RentalCommentLine: Record "TWE Rental Comment Line";
        RentalCommentLine2: Record "TWE Rental Comment Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyComments(RentalCommentLine, ToDocumentType, IsHandled, FromDocumentType, FromNumber, ToNumber);
        if IsHandled then
            exit;

        RentalCommentLine.SetRange("Document Type", FromDocumentType);
        RentalCommentLine.SetRange("No.", FromNumber);
        if RentalCommentLine.FindSet() then
            repeat
                RentalCommentLine2 := RentalCommentLine;
                RentalCommentLine2."Document Type" := "TWE Rental Comment Document Type".FromInteger(ToDocumentType);
                RentalCommentLine2."No." := ToNumber;
                RentalCommentLine2.Insert();
            until RentalCommentLine.Next() = 0;
    end;

    /// <summary>
    /// CopyLineComments.
    /// </summary>
    /// <param name="FromDocumentType">Integer.</param>
    /// <param name="ToDocumentType">Integer.</param>
    /// <param name="FromNumber">Code[20].</param>
    /// <param name="ToNumber">Code[20].</param>
    /// <param name="FromDocumentLineNo">Integer.</param>
    /// <param name="ToDocumentLineNo">Integer.</param>
    procedure CopyLineComments(FromDocumentType: Integer; ToDocumentType: Integer; FromNumber: Code[20]; ToNumber: Code[20]; FromDocumentLineNo: Integer; ToDocumentLineNo: Integer)
    var
        RentalCommentLineSource: Record "TWE Rental Comment Line";
        RentalCommentLineTarget: Record "TWE Rental Comment Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyLineComments(
          RentalCommentLineTarget, IsHandled, FromDocumentType, ToDocumentType, FromNumber, ToNumber, FromDocumentLineNo, ToDocumentLineNo);
        if IsHandled then
            exit;

        RentalCommentLineSource.SetRange("Document Type", FromDocumentType);
        RentalCommentLineSource.SetRange("No.", FromNumber);
        RentalCommentLineSource.SetRange("Document Line No.", FromDocumentLineNo);
        if RentalCommentLineSource.FindSet() then
            repeat
                RentalCommentLineTarget := RentalCommentLineSource;
                RentalCommentLineTarget."Document Type" := "TWE Rental Comment Document Type".FromInteger(ToDocumentType);
                RentalCommentLineTarget."No." := ToNumber;
                RentalCommentLineTarget."Document Line No." := ToDocumentLineNo;
                RentalCommentLineTarget.Insert();
            until RentalCommentLineSource.Next() = 0;
    end;

    /// <summary>
    /// CopyLineCommentsFromRentalLines.
    /// </summary>
    /// <param name="FromDocumentType">Integer.</param>
    /// <param name="ToDocumentType">Integer.</param>
    /// <param name="FromNumber">Code[20].</param>
    /// <param name="ToNumber">Code[20].</param>
    /// <param name="TempRentalLineSource">Temporary VAR Record "TWE Rental Line".</param>
    procedure CopyLineCommentsFromRentalLines(FromDocumentType: Integer; ToDocumentType: Integer; FromNumber: Code[20]; ToNumber: Code[20]; var TempRentalLineSource: Record "TWE Rental Line" temporary)
    var
        RentalCommentLineSource: Record "TWE Rental Comment Line";
        RentalCommentLineTarget: Record "TWE Rental Comment Line";
        IsHandled: Boolean;
        NextLineNo: Integer;
    begin
        IsHandled := false;
        OnBeforeCopyLineCommentsFromRentalLines(
          RentalCommentLineTarget, IsHandled, FromDocumentType, ToDocumentType, FromNumber, ToNumber, TempRentalLineSource);
        if IsHandled then
            exit;

        RentalCommentLineTarget.SetRange("Document Type", ToDocumentType);
        RentalCommentLineTarget.SetRange("No.", ToNumber);
        RentalCommentLineTarget.SetRange("Document Line No.", 0);
        if RentalCommentLineTarget.FindLast() then;
        NextLineNo := RentalCommentLineTarget."Line No." + 10000;
        RentalCommentLineTarget.Reset();

        RentalCommentLineSource.SetRange("Document Type", FromDocumentType);
        RentalCommentLineSource.SetRange("No.", FromNumber);
        if TempRentalLineSource.FindSet() then
            repeat
                RentalCommentLineSource.SetRange("Document Line No.", TempRentalLineSource."Line No.");
                if RentalCommentLineSource.FindSet() then
                    repeat
                        RentalCommentLineTarget := RentalCommentLineSource;
                        RentalCommentLineTarget."Document Type" := "TWE Rental Comment Document Type".FromInteger(ToDocumentType);
                        RentalCommentLineTarget."No." := ToNumber;
                        RentalCommentLineTarget."Document Line No." := 0;
                        RentalCommentLineTarget."Line No." := NextLineNo;
                        RentalCommentLineTarget.Insert();
                        NextLineNo += 10000;
                    until RentalCommentLineSource.Next() = 0;
            until TempRentalLineSource.Next() = 0;
    end;

    /// <summary>
    /// CopyHeaderComments.
    /// </summary>
    /// <param name="FromDocumentType">Integer.</param>
    /// <param name="ToDocumentType">Integer.</param>
    /// <param name="FromNumber">Code[20].</param>
    /// <param name="ToNumber">Code[20].</param>
    procedure CopyHeaderComments(FromDocumentType: Integer; ToDocumentType: Integer; FromNumber: Code[20]; ToNumber: Code[20])
    var
        RentalCommentLineSource: Record "TWE Rental Comment Line";
        RentalCommentLineTarget: Record "TWE Rental Comment Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyHeaderComments(RentalCommentLineTarget, IsHandled, FromDocumentType, ToDocumentType, FromNumber, ToNumber);
        if IsHandled then
            exit;

        RentalCommentLineSource.SetRange("Document Type", FromDocumentType);
        RentalCommentLineSource.SetRange("No.", FromNumber);
        RentalCommentLineSource.SetRange("Document Line No.", 0);
        if RentalCommentLineSource.FindSet() then
            repeat
                RentalCommentLineTarget := RentalCommentLineSource;
                RentalCommentLineTarget."Document Type" := "TWE Rental Comment Document Type".FromInteger(ToDocumentType);
                RentalCommentLineTarget."No." := ToNumber;
                RentalCommentLineTarget.Insert();
            until RentalCommentLineSource.Next() = 0;
    end;

    /// <summary>
    /// DeleteComments.
    /// </summary>
    /// <param name="DocType">Option.</param>
    /// <param name="DocNo">Code[20].</param>
    procedure DeleteComments(DocType: Option; DocNo: Code[20])
    begin
        SetRange("Document Type", DocType);
        SetRange("No.", DocNo);
        if not IsEmpty then
            DeleteAll();
    end;

    /// <summary>
    /// ShowComments.
    /// </summary>
    /// <param name="DocType">Option.</param>
    /// <param name="DocNo">Code[20].</param>
    /// <param name="DocLineNo">Integer.</param>
    procedure ShowComments(DocType: Option; DocNo: Code[20]; DocLineNo: Integer)
    var
        RentalCommentSheet: Page "TWE Rental Comment Sheet";
    begin
        SetRange("Document Type", DocType);
        SetRange("No.", DocNo);
        SetRange("Document Line No.", DocLineNo);
        Clear(RentalCommentSheet);
        RentalCommentSheet.SetTableView(Rec);
        RentalCommentSheet.RunModal();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetUpNewLine(var RentalCommentLineRec: Record "TWE REntal Comment Line"; var RentalCommentLineFilter: Record "TWE Rental Comment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyComments(var RentalCommentLine: Record "TWE Rental Comment Line"; ToDocumentType: Integer; var IsHandled: Boolean; FromDocumentType: Integer; FromNumber: Code[20]; ToNumber: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyLineComments(var RentalCommentLine: Record "TWE Rental Comment Line"; var IsHandled: Boolean; FromDocumentType: Integer; ToDocumentType: Integer; FromNumber: Code[20]; ToNumber: Code[20]; FromDocumentLineNo: Integer; ToDocumentLine: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyLineCommentsFromRentalLines(var RentalCommentLine: Record "TWE Rental Comment Line"; var IsHandled: Boolean; FromDocumentType: Integer; ToDocumentType: Integer; FromNumber: Code[20]; ToNumber: Code[20]; var TempRentalLineSource: Record "TWE Rental Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyHeaderComments(var RentalCommentLine: Record "TWE Rental Comment Line"; var IsHandled: Boolean; FromDocumentType: Integer; ToDocumentType: Integer; FromNumber: Code[20]; ToNumber: Code[20])
    begin
    end;
}

