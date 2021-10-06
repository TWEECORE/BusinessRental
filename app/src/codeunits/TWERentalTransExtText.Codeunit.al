codeunit 50060 "TWE Rental Trans. Ext. Text"
{

    trigger OnRun()
    begin
    end;

    var
        GLAcc: Record "G/L Account";
        MainRentalItem: Record "TWE Main Rental Item";
        Res: Record Resource;
        TempExtTextLine: Record "Extended Text Line" temporary;
        NextLineNo: Integer;
        LineSpacing: Integer;
        MakeUpdateRequired: Boolean;
        AutoText: Boolean;
        Text000Lbl: Label 'There is not enough space to insert extended text lines.';

    procedure RentalCheckIfAnyExtText(var RentalLine: Record "TWE Rental Line"; Unconditionally: Boolean): Boolean
    var
        RentalHeader: Record "TWE Rental Header";
    begin
        exit(RentalCheckIfAnyExtText(RentalLine, Unconditionally, RentalHeader));
    end;

    procedure RentalCheckIfAnyExtText(var RentalLine: Record "TWE Rental Line"; Unconditionally: Boolean; RentalHeader: Record "TWE Rental Header"): Boolean
    var
        ExtTextHeader: Record "Extended Text Header";
    begin
        MakeUpdateRequired := false;
        if IsDeleteAttachedLines(RentalLine."Line No.", RentalLine."No.", RentalLine."Attached to Line No.") then
            MakeUpdateRequired := DeleteRentalLines(RentalLine);

        AutoText := false;

        if Unconditionally then
            AutoText := true
        else
            case RentalLine.Type of
                RentalLine.Type::" ":
                    AutoText := true;
                RentalLine.Type::"G/L Account":
                    if GLAcc.Get(RentalLine."No.") then
                        AutoText := GLAcc."Automatic Ext. Texts";
                RentalLine.Type::"Rental Item":
                    if MainRentalItem.Get(RentalLine."No.") then
                        AutoText := MainRentalItem."Automatic Ext. Texts";
                RentalLine.Type::Resource:
                    if Res.Get(RentalLine."No.") then
                        AutoText := Res."Automatic Ext. Texts";
            end;

        OnSalesCheckIfAnyExtTextOnBeforeSetFilters(RentalLine, AutoText, Unconditionally);

        if AutoText then begin
            RentalLine.TestField("Document No.");

            if RentalHeader."No." = '' then
                RentalHeader.Get(RentalLine."Document Type", RentalLine."Document No.");

            ExtTextHeader.SetRange("Table Name", RentalLine.Type.AsInteger());
            ExtTextHeader.SetRange("No.", RentalLine."No.");
            case RentalLine."Document Type" of
                RentalLine."Document Type"::Quote:
                    ExtTextHeader.SetRange("TWE Rental Quote", true);
                RentalLine."Document Type"::Contract:
                    ExtTextHeader.SetRange("TWE Rental Contract", true);
                RentalLine."Document Type"::Invoice:
                    ExtTextHeader.SetRange("TWE Rental Invoice", true);
                RentalLine."Document Type"::"Return Shipment":
                    ExtTextHeader.SetRange("TWE Rental Ret. Shipment", true);
                RentalLine."Document Type"::"Credit Memo":
                    ExtTextHeader.SetRange("TWE Rental Credit Memo", true);
            end;
            OnRentalCheckIfAnyExtTextAutoText(ExtTextHeader, RentalHeader, RentalLine, Unconditionally, MakeUpdateRequired);
            exit(ReadExtTextLines(ExtTextHeader, RentalHeader."Document Date", RentalHeader."Language Code"));
        end;
    end;

    procedure InsertRentalExtText(var RentalLine: Record "TWE Rental Line")
    var
        DummyRentalLine: Record "TWE Rental Line";
    begin
        InsertRentalExtTextRetLast(RentalLine, DummyRentalLine);
    end;

    procedure InsertRentalExtTextRetLast(var RentalLine: Record "TWE Rental Line"; var LastInsertedRentalLine: Record "TWE Rental Line")
    var
        ToRentalLine: Record "TWE Rental Line";
        IsHandled: Boolean;
    begin
        OnBeforeInsertRentalExtText(RentalLine, TempExtTextLine, IsHandled, MakeUpdateRequired);
        if IsHandled then
            exit;

        ToRentalLine.Reset();
        ToRentalLine.SetRange("Document Type", RentalLine."Document Type");
        ToRentalLine.SetRange("Document No.", RentalLine."Document No.");
        ToRentalLine := RentalLine;
        if ToRentalLine.Find('>') then begin
            LineSpacing :=
              (ToRentalLine."Line No." - RentalLine."Line No.") div
              (1 + TempExtTextLine.Count);
            if LineSpacing = 0 then
                Error(Text000Lbl);
        end else
            LineSpacing := 10000;

        NextLineNo := RentalLine."Line No." + LineSpacing;

        TempExtTextLine.Reset();
        if TempExtTextLine.Find('-') then begin
            repeat
                ToRentalLine.Init();
                ToRentalLine."Document Type" := RentalLine."Document Type";
                ToRentalLine."Document No." := RentalLine."Document No.";
                ToRentalLine."Line No." := NextLineNo;
                NextLineNo := NextLineNo + LineSpacing;
                ToRentalLine.Description := TempExtTextLine.Text;
                ToRentalLine."Attached to Line No." := RentalLine."Line No.";
                OnBeforeToRentalLineInsert(ToRentalLine, RentalLine, TempExtTextLine, NextLineNo, LineSpacing);
                ToRentalLine.Insert();
            until TempExtTextLine.Next() = 0;
            MakeUpdateRequired := true;
        end;
        TempExtTextLine.DeleteAll();
        LastInsertedRentalLine := ToRentalLine;
    end;

    local procedure DeleteRentalLines(var RentalLine: Record "TWE Rental Line"): Boolean
    var
        RentalLine2: Record "TWE Rental Line";
    begin
        RentalLine2.SetRange("Document Type", RentalLine."Document Type");
        RentalLine2.SetRange("Document No.", RentalLine."Document No.");
        RentalLine2.SetRange("Attached to Line No.", RentalLine."Line No.");
        OnDeleteRentalLinesOnAfterSetFilters(RentalLine2, RentalLine);
        RentalLine2 := RentalLine;
        if RentalLine2.Find('>') then begin
            repeat
                RentalLine2.Delete(true);
            until RentalLine2.Next() = 0;
            exit(true);
        end;
    end;

    procedure MakeUpdate(): Boolean
    begin
        exit(MakeUpdateRequired);
    end;

    procedure ReadExtTextLines(var ExtTextHeader: Record "Extended Text Header"; DocDate: Date; LanguageCode: Code[10]) Result: Boolean
    var
        ExtTextLine: Record "Extended Text Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeReadLines(ExtTextHeader, DocDate, LanguageCode, IsHandled, Result, TempExtTextLine);
        if IsHandled then
            exit(Result);

        ExtTextHeader.SetCurrentKey(
          "Table Name", "No.", "Language Code", "All Language Codes", "Starting Date", "Ending Date");
        ExtTextHeader.SetRange("Starting Date", 0D, DocDate);
        ExtTextHeader.SetFilter("Ending Date", '%1..|%2', DocDate, 0D);
        if LanguageCode = '' then begin
            ExtTextHeader.SetRange("Language Code", '');
            if not ExtTextHeader.FindSet() then
                exit;
        end else begin
            ExtTextHeader.SetRange("Language Code", LanguageCode);
            if not ExtTextHeader.FindSet() then begin
                ExtTextHeader.SetRange("All Language Codes", true);
                ExtTextHeader.SetRange("Language Code", '');
                if not ExtTextHeader.FindSet() then
                    exit;
            end;
        end;
        TempExtTextLine.DeleteAll();
        repeat
            ExtTextLine.SetRange("Table Name", ExtTextHeader."Table Name");
            ExtTextLine.SetRange("No.", ExtTextHeader."No.");
            ExtTextLine.SetRange("Language Code", ExtTextHeader."Language Code");
            ExtTextLine.SetRange("Text No.", ExtTextHeader."Text No.");
            if ExtTextLine.FindSet() then begin
                repeat
                    TempExtTextLine := ExtTextLine;
                    TempExtTextLine.Insert();
                until ExtTextLine.Next() = 0;
                Result := true;
            end;
        until ExtTextHeader.Next() = 0;

        OnAfterReadLines(TempExtTextLine, ExtTextHeader, LanguageCode);
    end;

    procedure GetTempExtTextLine(var ToTempExtendedTextLine: Record "Extended Text Line" temporary)
    begin
        ToTempExtendedTextLine.Copy(TempExtTextLine, true);
    end;

    local procedure IsDeleteAttachedLines(LineNo: Integer; No: Code[20]; AttachedToLineNo: Integer): Boolean
    begin
        exit((LineNo <> 0) and (AttachedToLineNo = 0) and (No <> ''));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReadLines(var TempExtendedTextLine: Record "Extended Text Line" temporary; var ExtendedTextHeader: Record "Extended Text Header"; LanguageCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReadLines(var ExtendedTextHeader: Record "Extended Text Header"; DocDate: Date; LanguageCode: Code[10]; var IsHandled: Boolean; var Result: Boolean; var TempExtTextLine: Record "Extended Text Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeToRentalLineInsert(var ToRentalLine: Record "TWE Rental Line"; RentalLine: Record "TWE Rental Line"; TempExtTextLine: Record "Extended Text Line" temporary; var NextLineNo: Integer; LineSpacing: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteRentalLinesOnAfterSetFilters(var ToRentalLine: Record "TWE Rental Line"; FromRentalLine: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRentalCheckIfAnyExtTextAutoText(var ExtendedTextHeader: Record "Extended Text Header"; var RentalHeader: Record "TWE Rental Header"; var RentalLine: Record "TWE Rental Line"; Unconditionally: Boolean; var MakeUpdateRequired: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertRentalExtText(var RentalLine: Record "TWE Rental Line"; var TempExtTextLine: Record "Extended Text Line" temporary; var IsHandled: Boolean; var MakeUpdateRequired: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSalesCheckIfAnyExtTextOnBeforeSetFilters(var RentalLine: Record "TWE Rental Line"; var AutoText: Boolean; Unconditionally: Boolean)
    begin
    end;
}

