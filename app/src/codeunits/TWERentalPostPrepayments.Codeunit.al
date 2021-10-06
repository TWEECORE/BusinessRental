codeunit 50033 "TWE Rental-Post Prepayments"
{
    Permissions = TableData "TWE Rental Line" = imd,
                  TableData "Invoice Post. Buffer" = imd,
                  TableData "TWE Rental Invoice Header" = imd,
                  TableData "TWE Rental Invoice Line" = imd,
                  TableData "TWE Rental Cr.Memo Header" = imd,
                  TableData "TWE Rental Cr.Memo Line" = imd,
                  TableData "General Posting Setup" = imd;
    TableNo = "TWE Rental Header";

    trigger OnRun()
    begin
        Execute(Rec);
    end;

    var
        GLSetup: Record "General Ledger Setup";
        RentalSetup: Record "TWE Rental Setup";
        GenPostingSetup: Record "General Posting Setup";
        TempGlobalPrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer" temporary;
        TempRentalLine: Record "TWE Rental Line" temporary;
        ErrorMessageMgt: Codeunit "Error Message Management";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        PrepmtDocumentType: Option ,,Invoice,"Credit Memo";
        SuppressCommit: Boolean;
        PreviewMode: Boolean;
        Text000Lbl: Label 'is not within your range of allowed posting dates';
        Text001Lbl: Label 'There is nothing to post.';
        Text002Lbl: Label 'Posting Prepayment Lines   #2######\', Comment = '#2 Counter';
        Text003Lbl: Label '%1 %2 -> Invoice %3', Comment = '%1 = Rental Header Document Type, %2 = Rental Header No., %3 = Rental Inv. Header No.';
        Text004Lbl: Label 'Posting sales and VAT      #3######\', Comment = '#3 Counter';
        Text005Lbl: Label 'Posting to customers       #4######\', Comment = '#4 Counter';
        Text006Lbl: Label 'Posting to bal. account    #5######', Comment = '#5 Counter';
        Text011Lbl: Label '%1 %2 -> Credit Memo %3', Comment = '%1 = Rental Header Document Type, %2 = Rental Header No., %3 = Rental Cr. Memo Header No.';
        Text012Lbl: Label 'Prepayment %1, %2 %3.', Comment = '%1 Counter, %2 document type, %3 document no.';
        Text013Lbl: Label 'It is not possible to assign a prepayment amount of %1 to the rental lines.', Comment = '%1 new total prepayment amount';
        Text014Lbl: Label 'VAT Amount';
        Text015Lbl: Label '%1% VAT', Comment = '%1 is the VAT percentage';
        Text016Lbl: Label 'The new prepayment amount must be between %1 and %2.', Comment = '%1 min value %2 max value';
        Text017Lbl: Label 'At least one line must have %1 > 0 to distribute prepayment amount.', Comment = '%1 field caption prepayment percentage.';
        Text018Lbl: Label 'must be positive when %1 is not 0', Comment = '%1 field caption prepayment percentage.';
        Text019Lbl: Label 'Invoice,Credit Memo';

    procedure SetDocumentType(DocumentType: Option ,,Invoice,"Credit Memo")
    begin
        PrepmtDocumentType := DocumentType;
    end;

    local procedure Execute(var RentalHeader: Record "TWE Rental Header")
    begin
        case PrepmtDocumentType of
            PrepmtDocumentType::Invoice:
                Invoice(RentalHeader);
            PrepmtDocumentType::"Credit Memo":
                CreditMemo(RentalHeader);
        end;
    end;

    procedure Invoice(var RentalHeader: Record "TWE Rental Header")
    var
        Handled: Boolean;
    begin
        OnBeforeInvoice(RentalHeader, Handled);
        if not Handled then
            Code(RentalHeader, 0);
    end;

    procedure CreditMemo(var RentalHeader: Record "TWE Rental Header")
    var
        Handled: Boolean;
    begin
        OnBeforeCreditMemo(RentalHeader, Handled);
        if not Handled then
            Code(RentalHeader, 1);
    end;

    local procedure "Code"(var RentalHeader2: Record "TWE Rental Header"; DocumentType: Option Invoice,"Credit Memo")
    var
        SourceCodeSetup: Record "Source Code Setup";
        RentalHeader: Record "TWE Rental Header";
        RentalLine: Record "TWE Rental Line";
        RentalInvHeader: Record "TWE Rental Invoice Header";
        RentalCrMemoHeader: Record "TWE Rental Cr.Memo Header";
        TempPrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer" temporary;
        TotalPrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer";
        TotalPrepmtInvLineBufferLCY: Record "Prepayment Inv. Line Buffer";
        GenJnlLine: Record "Gen. Journal Line";
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        TempVATAmountLineDeduct: Record "VAT Amount Line" temporary;
        CustLedgEntry: Record "Cust. Ledger Entry";
        TempRentalLines: Record "TWE Rental Line" temporary;
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        RentalPrepaymentMgt: Codeunit "TWE Rental Prepayment Mgt.";
        Window: Dialog;
        GenJnlLineDocNo: Code[20];
        GenJnlLineExtDocNo: Code[35];
        SrcCode: Code[10];
        PostingNoSeriesCode: Code[20];
        ModifyHeader: Boolean;
        CalcPmtDiscOnCrMemos: Boolean;
        PostingDescription: Text[100];
        GenJnlLineDocType: Enum "Gen. Journal Document Type";
        PrevLineNo: Integer;
        LineCount: Integer;
        PostedDocTabNo: Integer;
        LineNo: Integer;
        Placeholder001Lbl: Label '%1 %2', Comment = '%1 = Text019Lbl, %2 = sNo.';
    begin
        OnBeforePostPrepayments(RentalHeader2, DocumentType, SuppressCommit, PreviewMode);

        PrevLineNo := 0;

        RentalHeader := RentalHeader2;
        GLSetup.Get();
        RentalSetup.Get();
        CheckPrepmtDoc(RentalHeader, DocumentType);

        UpdateDocNos(RentalHeader, DocumentType, GenJnlLineDocNo, PostingNoSeriesCode, ModifyHeader);

        if not PreviewMode and ModifyHeader then begin
            RentalHeader.Modify();
            if not SuppressCommit then
                Commit();
        end;

        Window.Open(
          '#1#################################\\' +
          Text002Lbl +
          Text004Lbl +
          Text005Lbl +
          Text006Lbl);
        Window.Update(1, StrSubstNo(Placeholder001Lbl, SelectStr(1 + DocumentType, Text019Lbl), RentalHeader."No."));

        SourceCodeSetup.Get();
        SrcCode := SourceCodeSetup.Sales;
        if RentalHeader."Prepmt. Posting Description" <> '' then
            PostingDescription := RentalHeader."Prepmt. Posting Description"
        else
            PostingDescription :=
              CopyStr(
                StrSubstNo(Text012Lbl, SelectStr(1 + DocumentType, Text019Lbl), RentalHeader."Document Type", RentalHeader."No."),
                1, MaxStrLen(RentalHeader."Posting Description"));

        // Create posted header
        if RentalSetup."Ext. Doc. No. Mandatory" then
            RentalHeader.TestField("External Document No.");
        case DocumentType of
            DocumentType::Invoice:
                begin
                    InsertRentalInvHeader(RentalInvHeader, RentalHeader, PostingDescription, GenJnlLineDocNo, SrcCode, PostingNoSeriesCode);
                    GenJnlLineDocType := GenJnlLine."Document Type"::Invoice;
                    PostedDocTabNo := DATABASE::"TWE Rental Invoice Header";
                    Window.Update(1, StrSubstNo(Text003Lbl, RentalHeader."Document Type", RentalHeader."No.", RentalInvHeader."No."));
                end;
            DocumentType::"Credit Memo":
                begin
                    CalcPmtDiscOnCrMemos := GetCalcPmtDiscOnCrMemos(RentalHeader."Prepmt. Payment Terms Code");
                    InsertRentalCrMemoHeader(
                      RentalCrMemoHeader, RentalHeader, PostingDescription, GenJnlLineDocNo, SrcCode, PostingNoSeriesCode,
                      CalcPmtDiscOnCrMemos);
                    GenJnlLineDocType := GenJnlLine."Document Type"::"Credit Memo";
                    PostedDocTabNo := DATABASE::"TWE Rental Cr.Memo Header";
                    Window.Update(1, StrSubstNo(Text011Lbl, RentalHeader."Document Type", RentalHeader."No.", RentalCrMemoHeader."No."));
                end;
        end;
        GenJnlLineExtDocNo := RentalHeader."External Document No.";
        // Reverse old lines
        if DocumentType = DocumentType::Invoice then begin
            GetRentalLinesToDeduct(RentalHeader, TempRentalLines);
            if not TempRentalLines.IsEmpty then
                CalcVATAmountLines(RentalHeader, TempRentalLines, TempVATAmountLineDeduct, DocumentType::"Credit Memo");
        end;

        // Create Lines
        TempPrepmtInvLineBuffer.DeleteAll();
        CalcVATAmountLines(RentalHeader, RentalLine, TempVATAmountLine, DocumentType);
        TempVATAmountLine.DeductVATAmountLine(TempVATAmountLineDeduct);
        UpdateVATOnLines(RentalHeader, RentalLine, TempVATAmountLine, DocumentType);
        BuildInvLineBuffer(RentalHeader, RentalLine, DocumentType, TempPrepmtInvLineBuffer, true);
        TempPrepmtInvLineBuffer.Find('-');
        repeat
            LineCount := LineCount + 1;
            Window.Update(2, LineCount);
            if TempPrepmtInvLineBuffer."Line No." <> 0 then
                LineNo := PrevLineNo + TempPrepmtInvLineBuffer."Line No."
            else
                LineNo := PrevLineNo + 10000;
            case DocumentType of
                DocumentType::Invoice:
                    begin
                        InsertRentalInvLine(RentalInvHeader, LineNo, TempPrepmtInvLineBuffer, RentalHeader);
                        PostedDocTabNo := DATABASE::"TWE Rental Invoice Line";
                    end;
                DocumentType::"Credit Memo":
                    begin
                        InsertRentalCrMemoLine(RentalCrMemoHeader, LineNo, TempPrepmtInvLineBuffer, RentalHeader);
                        PostedDocTabNo := DATABASE::"TWE Rental Cr.Memo Line";
                    end;
            end;
            PrevLineNo := LineNo;
            InsertExtendedText(
              PostedDocTabNo, GenJnlLineDocNo, TempPrepmtInvLineBuffer."G/L Account No.", RentalHeader."Document Date", RentalHeader."Language Code", PrevLineNo);
        until TempPrepmtInvLineBuffer.Next() = 0;

        if RentalHeader."Compress Prepayment" then
            case DocumentType of
                DocumentType::Invoice:
                    CopyLineCommentLinesCompressedPrepayment(RentalHeader."No.", DATABASE::"TWE Rental Invoice Header", RentalInvHeader."No.");
                DocumentType::"Credit Memo":
                    CopyLineCommentLinesCompressedPrepayment(RentalHeader."No.", DATABASE::"TWE Rental Cr.Memo Header", RentalCrMemoHeader."No.");
            end;

        OnAfterCreateLinesOnBeforeGLPosting(RentalHeader, RentalInvHeader, RentalCrMemoHeader, TempPrepmtInvLineBuffer, DocumentType, LineNo);

        // G/L Posting
        LineCount := 0;
        if not RentalHeader."Compress Prepayment" then
            TempPrepmtInvLineBuffer.CompressBuffer();
        TempPrepmtInvLineBuffer.SetRange(Adjustment, false);
        TempPrepmtInvLineBuffer.FindSet(true);
        repeat
            if DocumentType = DocumentType::Invoice then
                TempPrepmtInvLineBuffer.ReverseAmounts();
            RoundAmounts(RentalHeader, TempPrepmtInvLineBuffer, TotalPrepmtInvLineBuffer, TotalPrepmtInvLineBufferLCY);
            if RentalHeader."Currency Code" = '' then begin
                AdjustInvLineBuffers(RentalHeader, TempPrepmtInvLineBuffer, TotalPrepmtInvLineBuffer, DocumentType);
                TotalPrepmtInvLineBufferLCY := TotalPrepmtInvLineBuffer;
            end else
                AdjustInvLineBuffers(RentalHeader, TempPrepmtInvLineBuffer, TotalPrepmtInvLineBufferLCY, DocumentType);
            TempPrepmtInvLineBuffer.Modify();
        until TempPrepmtInvLineBuffer.Next() = 0;

        TempPrepmtInvLineBuffer.Reset();
        TempPrepmtInvLineBuffer.SetCurrentKey(Adjustment);
        TempPrepmtInvLineBuffer.Find('+');
        repeat
            LineCount := LineCount + 1;
            Window.Update(3, LineCount);

            PostPrepmtInvLineBuffer(
              RentalHeader, TempPrepmtInvLineBuffer, DocumentType, PostingDescription,
              GenJnlLineDocType, GenJnlLineDocNo, GenJnlLineExtDocNo, SrcCode, PostingNoSeriesCode);
        until TempPrepmtInvLineBuffer.Next(-1) = 0;

        // Post customer entry
        Window.Update(4, 1);
        PostCustomerEntry(
          RentalHeader, TotalPrepmtInvLineBuffer, TotalPrepmtInvLineBufferLCY, DocumentType, PostingDescription,
          GenJnlLineDocType, GenJnlLineDocNo, GenJnlLineExtDocNo, SrcCode, PostingNoSeriesCode, CalcPmtDiscOnCrMemos);

        UpdatePostedRentalDocument(DocumentType, GenJnlLineDocNo);

        CustLedgEntry.FindLast();
        CustLedgEntry.CalcFields(Amount);
        If RentalHeader."Document Type" = RentalHeader."Document Type"::Contract then begin
            RentalLine.CalcSums("Amount Including VAT");
            RentalPrepaymentMgt.AssertPrepmtAmountNotMoreThanDocAmount(
                RentalLine."Amount Including VAT", CustLedgEntry.Amount, RentalHeader."Currency Code", RentalSetup."Invoice Rounding");
        end;

        // Balancing account
        if RentalHeader."Bal. Account No." <> '' then begin
            Window.Update(5, 1);
            PostBalancingEntry(
              RentalHeader, TotalPrepmtInvLineBuffer, TotalPrepmtInvLineBufferLCY, CustLedgEntry, DocumentType,
              PostingDescription, GenJnlLineDocType, GenJnlLineDocNo, GenJnlLineExtDocNo, SrcCode, PostingNoSeriesCode);
        end;

        // Update lines & header
        UpdateRentalDocument(RentalHeader, RentalLine, DocumentType, GenJnlLineDocNo);
        if RentalHeader.TestStatusIsNotPendingPrepayment() then
            RentalHeader.Status := RentalHeader.Status::"Pending Prepayment";
        RentalHeader.Modify();

        OnAfterPostPrepaymentsOnBeforeThrowPreviewModeError(RentalHeader, RentalInvHeader, RentalCrMemoHeader, GenJnlPostLine, PreviewMode);

        if PreviewMode then begin
            Window.Close();
            OnBeforeThrowPreviewError(RentalHeader);
            GenJnlPostPreview.ThrowError();
        end;

        RentalHeader2 := RentalHeader;

        OnAfterPostPrepayments(RentalHeader2, DocumentType, SuppressCommit, RentalInvHeader, RentalCrMemoHeader);
    end;

    procedure CheckPrepmtDoc(RentalHeader: Record "TWE Rental Header"; DocumentType: Option Invoice,"Credit Memo")
    var
        Cust: Record Customer;
        GenJnlCheckLine: Codeunit "Gen. Jnl.-Check Line";
    //CheckDimensions: Codeunit "Check Dimensions";
    begin
        OnBeforeCheckPrepmtDoc(RentalHeader, DocumentType, SuppressCommit);
        RentalHeader.TestField("Document Type", RentalHeader."Document Type"::Contract);
        RentalHeader.TestField("Rented-to Customer No.");
        RentalHeader.TestField("Bill-to Customer No.");
        RentalHeader.TestField("Posting Date");
        RentalHeader.TestField("Document Date");
        if GenJnlCheckLine.DateNotAllowed(RentalHeader."Posting Date") then
            RentalHeader.FieldError("Posting Date", Text000Lbl);

        if not CheckOpenPrepaymentLines(RentalHeader, DocumentType) then
            Error(Text001Lbl);

        //CheckDimensions.CheckRentalPrepmtDim(RentalHeader);
        ErrorMessageMgt.Finish(RentalHeader.RecordId);
        RentalHeader.CheckRentalPostRestrictions();
        Cust.Get(RentalHeader."Rented-to Customer No.");
        Cust.CheckBlockedCustOnDocs(Cust, "TWE Rental Document Type".FromInteger(PrepmtDocTypeToDocType(DocumentType)), false, true);
        if RentalHeader."Bill-to Customer No." <> RentalHeader."Rented-to Customer No." then begin
            Cust.Get(RentalHeader."Bill-to Customer No.");
            Cust.CheckBlockedCustOnDocs(Cust, "TWE Rental Document Type".FromInteger(PrepmtDocTypeToDocType(DocumentType)), false, true);
        end;
        OnAfterCheckPrepmtDoc(RentalHeader, DocumentType, SuppressCommit);
    end;

    local procedure UpdateDocNos(var RentalHeader: Record "TWE Rental Header"; DocumentType: Option Invoice,"Credit Memo"; var DocNo: Code[20]; var NoSeriesCode: Code[20]; var ModifyHeader: Boolean)
    var
        NoSeriesMgt: Codeunit NoSeriesManagement;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateDocNos(RentalHeader, DocumentType, DocNo, NoSeriesCode, ModifyHeader, PreviewMode, IsHandled);
        if IsHandled then
            exit;

        ModifyHeader := false;
        case DocumentType of
            DocumentType::Invoice:
                begin
                    RentalHeader.TestField("Prepayment Due Date");
                    RentalHeader.TestField("Prepmt. Cr. Memo No.", '');
                    if RentalHeader."Prepayment No." = '' then
                        if not PreviewMode then begin
                            RentalHeader.TestField("Prepayment No. Series");
                            RentalHeader."Prepayment No." := NoSeriesMgt.GetNextNo(RentalHeader."Prepayment No. Series", RentalHeader."Posting Date", true);
                            ModifyHeader := true;
                        end else
                            RentalHeader."Prepayment No." := '***';
                    DocNo := RentalHeader."Prepayment No.";
                    NoSeriesCode := RentalHeader."Prepayment No. Series";
                end;
            DocumentType::"Credit Memo":
                begin
                    RentalHeader.TestField("Prepayment No.", '');
                    if RentalHeader."Prepmt. Cr. Memo No." = '' then
                        if not PreviewMode then begin
                            RentalHeader.TestField("Prepmt. Cr. Memo No. Series");
                            RentalHeader."Prepmt. Cr. Memo No." := NoSeriesMgt.GetNextNo(RentalHeader."Prepmt. Cr. Memo No. Series", RentalHeader."Posting Date", true);
                            ModifyHeader := true;
                        end else
                            RentalHeader."Prepmt. Cr. Memo No." := '***';
                    DocNo := RentalHeader."Prepmt. Cr. Memo No.";
                    NoSeriesCode := RentalHeader."Prepmt. Cr. Memo No. Series";
                end;
        end;
    end;

    procedure CheckOpenPrepaymentLines(RentalHeader: Record "TWE Rental Header"; DocumentType: Option) Found: Boolean
    var
        RentalLine: Record "TWE Rental Line";
    begin
        ApplyFilter(RentalHeader, DocumentType, RentalLine);
        if RentalLine.Find('-') then
            repeat
                if not Found then
                    Found := PrepmtAmount(RentalLine, DocumentType) <> 0;
                if RentalLine."Prepmt. Amt. Inv." = 0 then begin
                    RentalLine.UpdatePrepmtSetupFields();
                    RentalLine.Modify();
                end;
            until RentalLine.Next() = 0;
        exit(Found);
    end;

    local procedure RoundAmounts(rentalHeader: Record "TWE Rental Header"; var PrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer"; var TotalPrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer"; var TotalPrepmtInvLineBufLCY: Record "Prepayment Inv. Line Buffer")
    var
        VAT: Boolean;
    begin
        TotalPrepmtInvLineBuf.IncrAmounts(PrepmtInvLineBuf);

        if rentalHeader."Currency Code" <> '' then begin
            VAT := PrepmtInvLineBuf.Amount <> PrepmtInvLineBuf."Amount Incl. VAT";
            PrepmtInvLineBuf."Amount Incl. VAT" :=
              AmountToLCY(rentalHeader, TotalPrepmtInvLineBuf."Amount Incl. VAT", TotalPrepmtInvLineBufLCY."Amount Incl. VAT");
            if VAT then
                PrepmtInvLineBuf.Amount := AmountToLCY(rentalHeader, TotalPrepmtInvLineBuf.Amount, TotalPrepmtInvLineBufLCY.Amount)
            else
                PrepmtInvLineBuf.Amount := PrepmtInvLineBuf."Amount Incl. VAT";
            PrepmtInvLineBuf."VAT Amount" := PrepmtInvLineBuf."Amount Incl. VAT" - PrepmtInvLineBuf.Amount;
            if PrepmtInvLineBuf."VAT Base Amount" <> 0 then
                PrepmtInvLineBuf."VAT Base Amount" := PrepmtInvLineBuf.Amount;
        end;

        OnRoundAmountsOnBeforeIncrAmounts(rentalHeader, PrepmtInvLineBuf, TotalPrepmtInvLineBuf, TotalPrepmtInvLineBufLCY);

        TotalPrepmtInvLineBufLCY.IncrAmounts(PrepmtInvLineBuf);

        OnAfterRoundAmounts(rentalHeader, PrepmtInvLineBuf, TotalPrepmtInvLineBuf, TotalPrepmtInvLineBufLCY);
    end;

    local procedure AmountToLCY(RentalHeader: Record "TWE Rental Header"; TotalAmt: Decimal; PrevTotalAmt: Decimal): Decimal
    var
        CurrExchRate: Record "Currency Exchange Rate";
    begin
        CurrExchRate.Init();
        exit(
          Round(
            CurrExchRate.ExchangeAmtFCYToLCY(RentalHeader."Posting Date", RentalHeader."Currency Code", TotalAmt, RentalHeader."Currency Factor")) -
          PrevTotalAmt);
    end;

    local procedure BuildInvLineBuffer(RentalHeader: Record "TWE Rental Header"; var RentalLine: Record "TWE Rental Line"; DocumentType: Option; var TempPrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer" temporary; UpdateLines: Boolean)
    var
        PrepmtInvLineBuf2: Record "Prepayment Inv. Line Buffer";
        TotalPrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer";
        TotalPrepmtInvLineBufferDummy: Record "Prepayment Inv. Line Buffer";
        RentalSetupLocal: Record "TWE Rental Setup";
    begin
        TempGlobalPrepmtInvLineBuf.Reset();
        TempGlobalPrepmtInvLineBuf.DeleteAll();
        TempRentalLine.Reset();
        TempRentalLine.DeleteAll();
        RentalSetupLocal.Get();
        ApplyFilter(RentalHeader, DocumentType, RentalLine);
        if RentalLine.Find('-') then
            repeat
                if PrepmtAmount(RentalLine, DocumentType) <> 0 then begin
                    CheckRentalLineIsNegative(RentalHeader, RentalLine);

                    FillInvLineBuffer(RentalHeader, RentalLine, PrepmtInvLineBuf2);
                    if UpdateLines then
                        TempGlobalPrepmtInvLineBuf.CopyWithLineNo(PrepmtInvLineBuf2, RentalLine."Line No.");
                    TempPrepmtInvLineBuf.InsertInvLineBuffer(PrepmtInvLineBuf2);
                    if RentalSetupLocal."Invoice Rounding" then
                        RoundAmounts(RentalHeader, PrepmtInvLineBuf2, TotalPrepmtInvLineBuffer, TotalPrepmtInvLineBufferDummy);
                    TempRentalLine := RentalLine;
                    TempRentalLine.Insert();
                end;
            until RentalLine.Next() = 0;
        if RentalSetupLocal."Invoice Rounding" then
            if InsertInvoiceRounding(
                 RentalHeader, PrepmtInvLineBuf2, TotalPrepmtInvLineBuffer, RentalLine."Line No.")
            then
                TempPrepmtInvLineBuf.InsertInvLineBuffer(PrepmtInvLineBuf2);

        OnAfterBuildInvLineBuffer(TempPrepmtInvLineBuf);
    end;

    procedure BuildInvLineBuffer(RentalHeader: Record "TWE Rental Header"; var RentalLine: Record "TWE Rental Line"; DocumentType: Option Invoice,"Credit Memo",Statistic; var PrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer")
    begin
        BuildInvLineBuffer(RentalHeader, RentalLine, DocumentType, PrepmtInvLineBuf, false);
    end;

    local procedure AdjustInvLineBuffers(RentalHeader: Record "TWE Rental Header"; var PrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer"; var TotalPrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer"; DocumentType: Option Invoice,"Credit Memo")
    var
        VATAdjustment: array[2] of Decimal;
        VAT: Option ,Base,Amount;
    begin
        CalcPrepmtAmtInvLCYInLines(RentalHeader, PrepmtInvLineBuf, DocumentType, VATAdjustment);
        if Abs(VATAdjustment[VAT::Base]) > GLSetup."Amount Rounding Precision" then
            InsertCorrInvLineBuffer(PrepmtInvLineBuf, RentalHeader, VATAdjustment[VAT::Base])
        else
            if (VATAdjustment[VAT::Base] <> 0) or (VATAdjustment[VAT::Amount] <> 0) then begin
                PrepmtInvLineBuf.AdjustVATBase(VATAdjustment);
                TotalPrepmtInvLineBuf.AdjustVATBase(VATAdjustment);
            end;
    end;

    local procedure CalcPrepmtAmtInvLCYInLines(RentalHeader: Record "TWE Rental Header"; var PrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer"; DocumentType: Option Invoice,"Credit Memo"; var VATAdjustment: array[2] of Decimal)
    var
        RentalLine: Record "TWE Rental Line";
        PrepmtInvBufAmount: array[2] of Decimal;
        TotalAmount: array[2] of Decimal;
        LineAmount: array[2] of Decimal;
        Ratio: array[2] of Decimal;
        PrepmtAmtReminder: array[2] of Decimal;
        PrepmtAmountRnded: array[2] of Decimal;
        VAT: Option ,Base,Amount;
    begin
        PrepmtInvLineBuf.AmountsToArray(PrepmtInvBufAmount);
        if DocumentType = DocumentType::Invoice then
            ReverseDecArray(PrepmtInvBufAmount);

        TempGlobalPrepmtInvLineBuf.SetFilterOnPKey(PrepmtInvLineBuf);
        TempGlobalPrepmtInvLineBuf.CalcSums(Amount, "Amount Incl. VAT");
        TempGlobalPrepmtInvLineBuf.AmountsToArray(TotalAmount);
        for VAT := VAT::Base to VAT::Amount do
            if TotalAmount[VAT] = 0 then
                Ratio[VAT] := 0
            else
                Ratio[VAT] := PrepmtInvBufAmount[VAT] / TotalAmount[VAT];
        if TempGlobalPrepmtInvLineBuf.FindSet() then
            repeat
                TempGlobalPrepmtInvLineBuf.AmountsToArray(LineAmount);
                PrepmtAmountRnded[VAT::Base] :=
                  CalcRoundedAmount(LineAmount[VAT::Base], Ratio[VAT::Base], PrepmtAmtReminder[VAT::Base]);
                PrepmtAmountRnded[VAT::Amount] :=
                  CalcRoundedAmount(LineAmount[VAT::Amount], Ratio[VAT::Amount], PrepmtAmtReminder[VAT::Amount]);

                RentalLine.Get(RentalHeader."Document Type", RentalHeader."No.", TempGlobalPrepmtInvLineBuf."Line No.");
                if DocumentType = DocumentType::"Credit Memo" then begin
                    VATAdjustment[VAT::Base] += RentalLine."Prepmt. Amount Inv. (LCY)" - PrepmtAmountRnded[VAT::Base];
                    RentalLine."Prepmt. Amount Inv. (LCY)" := 0;
                    VATAdjustment[VAT::Amount] += RentalLine."Prepmt. VAT Amount Inv. (LCY)" - PrepmtAmountRnded[VAT::Amount];
                    RentalLine."Prepmt. VAT Amount Inv. (LCY)" := 0;
                end else begin
                    RentalLine."Prepmt. Amount Inv. (LCY)" += PrepmtAmountRnded[VAT::Base];
                    RentalLine."Prepmt. VAT Amount Inv. (LCY)" += PrepmtAmountRnded[VAT::Amount];
                end;
                RentalLine.Modify();
            until TempGlobalPrepmtInvLineBuf.Next() = 0;
        TempGlobalPrepmtInvLineBuf.DeleteAll();
    end;

    local procedure CalcRoundedAmount(LineAmount: Decimal; Ratio: Decimal; var Reminder: Decimal) RoundedAmount: Decimal
    var
        Amount: Decimal;
    begin
        Amount := Reminder + LineAmount * Ratio;
        RoundedAmount := Round(Amount);
        Reminder := Amount - RoundedAmount;
    end;

    local procedure ReverseDecArray(var DecArray: array[2] of Decimal)
    var
        Idx: Integer;
    begin
        for Idx := 1 to ArrayLen(DecArray) do
            DecArray[Idx] := -DecArray[Idx];
    end;

    local procedure InsertCorrInvLineBuffer(var PrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer"; RentalHeader: Record "TWE Rental Header"; VATBaseAdjustment: Decimal)
    var
        NewPrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer";
        SavedPrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer";
        AdjmtAmountACY: Decimal;
    begin
        SavedPrepmtInvLineBuf := PrepmtInvLineBuf;

        if RentalHeader."Currency Code" = '' then
            AdjmtAmountACY := VATBaseAdjustment
        else
            AdjmtAmountACY := 0;

        NewPrepmtInvLineBuf.FillAdjInvLineBuffer(
          PrepmtInvLineBuf,
          GetPrepmtAccNo(PrepmtInvLineBuf."Gen. Bus. Posting Group", PrepmtInvLineBuf."Gen. Prod. Posting Group"),
          VATBaseAdjustment, AdjmtAmountACY);
        PrepmtInvLineBuf.InsertInvLineBuffer(NewPrepmtInvLineBuf);

        NewPrepmtInvLineBuf.FillAdjInvLineBuffer(
          PrepmtInvLineBuf,
          GetCorrBalAccNo(RentalHeader, VATBaseAdjustment > 0),
          -VATBaseAdjustment, -AdjmtAmountACY);
        PrepmtInvLineBuf.InsertInvLineBuffer(NewPrepmtInvLineBuf);

        PrepmtInvLineBuf := SavedPrepmtInvLineBuf;
    end;

    local procedure GetPrepmtAccNo(GenBusPostingGroup: Code[20]; GenProdPostingGroup: Code[20]): Code[20]
    begin
        if (GenBusPostingGroup <> GenPostingSetup."Gen. Bus. Posting Group") or
           (GenProdPostingGroup <> GenPostingSetup."Gen. Prod. Posting Group")
        then
            GenPostingSetup.Get(GenBusPostingGroup, GenProdPostingGroup);
        exit(GenPostingSetup.GetSalesPrepmtAccount());
    end;

    procedure GetCorrBalAccNo(RentalHeader: Record "TWE Rental Header"; PositiveAmount: Boolean): Code[20]
    var
        BalAccNo: Code[20];
    begin
        if RentalHeader."Currency Code" = '' then
            BalAccNo := GetInvRoundingAccNo(RentalHeader."Customer Posting Group")
        else
            BalAccNo := GetGainLossGLAcc(RentalHeader."Currency Code", PositiveAmount);
        exit(BalAccNo);
    end;

    procedure GetInvRoundingAccNo(CustomerPostingGroup: Code[20]): Code[20]
    var
        CustPostingGr: Record "Customer Posting Group";
        GLAcc: Record "G/L Account";
    begin
        CustPostingGr.Get(CustomerPostingGroup);
        GLAcc.Get(CustPostingGr.GetInvRoundingAccount());
        exit(CustPostingGr."Invoice Rounding Account");
    end;

    local procedure GetGainLossGLAcc(CurrencyCode: Code[10]; PositiveAmount: Boolean): Code[20]
    var
        Currency: Record Currency;
    begin
        Currency.Get(CurrencyCode);
        if PositiveAmount then
            exit(Currency.GetRealizedGainsAccount());
        exit(Currency.GetRealizedLossesAccount());
    end;

    local procedure GetCurrencyAmountRoundingPrecision(CurrencyCode: Code[10]): Decimal
    var
        Currency: Record Currency;
    begin
        Currency.Initialize(CurrencyCode);
        Currency.TestField("Amount Rounding Precision");
        exit(Currency."Amount Rounding Precision");
    end;

    procedure FillInvLineBuffer(RentalHeader: Record "TWE Rental Header"; RentalLine: Record "TWE Rental Line"; var PrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer")
    begin
        PrepmtInvLineBuf.Init();
        OnBeforeFillInvLineBuffer(PrepmtInvLineBuf, RentalHeader, RentalLine);
        PrepmtInvLineBuf."G/L Account No." := GetPrepmtAccNo(RentalLine."Gen. Bus. Posting Group", RentalLine."Gen. Prod. Posting Group");

        if not RentalHeader."Compress Prepayment" then begin
            PrepmtInvLineBuf."Line No." := RentalLine."Line No.";
            PrepmtInvLineBuf.Description := RentalLine.Description;
        end;

        //CopyFromRentalLine(RentalLine);
        PrepmtInvLineBuf.FillFromGLAcc(RentalHeader."Compress Prepayment");

        PrepmtInvLineBuf.SetAmounts(
          RentalLine."Prepayment Amount", RentalLine."Prepmt. Amt. Incl. VAT", RentalLine."Prepayment Amount",
          RentalLine."Prepayment Amount", RentalLine."Prepayment Amount", RentalLine."Prepayment VAT Difference");

        PrepmtInvLineBuf."VAT Amount" := RentalLine."Prepmt. Amt. Incl. VAT" - RentalLine."Prepayment Amount";
        PrepmtInvLineBuf."VAT Amount (ACY)" := RentalLine."Prepmt. Amt. Incl. VAT" - RentalLine."Prepayment Amount";
        PrepmtInvLineBuf."VAT Base Before Pmt. Disc." := -RentalLine."Prepayment Amount";

        OnAfterFillInvLineBuffer(PrepmtInvLineBuf, RentalLine);
    end;

    local procedure InsertInvoiceRounding(RentalHeader: Record "TWE Rental Header"; var PrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer"; TotalPrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer"; PrevLineNo: Integer): Boolean
    var
        RentalLine: Record "TWE Rental Line";
    begin
        if InitInvoiceRoundingLine(RentalHeader, TotalPrepmtInvLineBuf."Amount Incl. VAT", RentalLine) then begin
            CreateDimensions(RentalLine);
            PrepmtInvLineBuf.Init();
            PrepmtInvLineBuf."Line No." := PrevLineNo + 10000;
            PrepmtInvLineBuf."Invoice Rounding" := true;
            PrepmtInvLineBuf."G/L Account No." := RentalLine."No.";

            //PrepmtInvLineBuf.CopyFromRentalLine(RentalLine);
            PrepmtInvLineBuf."Gen. Bus. Posting Group" := RentalHeader."Gen. Bus. Posting Group";
            PrepmtInvLineBuf."VAT Bus. Posting Group" := RentalHeader."VAT Bus. Posting Group";

            PrepmtInvLineBuf.SetAmounts(
              RentalLine."Line Amount", RentalLine."Amount Including VAT", RentalLine."Line Amount",
              RentalLine."Prepayment Amount", RentalLine."Line Amount", 0);

            PrepmtInvLineBuf."VAT Amount" := RentalLine."Amount Including VAT" - RentalLine."Line Amount";
            PrepmtInvLineBuf."VAT Amount (ACY)" := RentalLine."Amount Including VAT" - RentalLine."Line Amount";

            OnAfterInsertInvoiceRounding(RentalHeader, PrepmtInvLineBuf, TotalPrepmtInvLineBuf, PrevLineNo);
            exit(true);
        end;
    end;

    local procedure InitInvoiceRoundingLine(RentalHeader: Record "TWE Rental Header"; TotalAmount: Decimal; var RentalLine: Record "TWE Rental Line"): Boolean
    var
        Currency: Record Currency;
        InvoiceRoundingAmount: Decimal;
    begin
        Currency.Initialize(RentalHeader."Currency Code");
        Currency.TestField("Invoice Rounding Precision");
        InvoiceRoundingAmount :=
          -Round(
            TotalAmount -
            Round(
              TotalAmount,
              Currency."Invoice Rounding Precision",
              Currency.InvoiceRoundingDirection()),
            Currency."Amount Rounding Precision");

        if InvoiceRoundingAmount = 0 then
            exit(false);

        RentalLine.SetHideValidationDialog(true);
        RentalLine."Document Type" := RentalHeader."Document Type";
        RentalLine."Document No." := RentalHeader."No.";
        RentalLine."System-Created Entry" := true;
        RentalLine.Type := RentalLine.Type::"G/L Account";
        RentalLine.Validate("No.", GetInvRoundingAccNo(RentalHeader."Customer Posting Group"));
        RentalLine.Validate(Quantity, 1);
        if RentalHeader."Prices Including VAT" then
            RentalLine.Validate("Unit Price", InvoiceRoundingAmount)
        else
            RentalLine.Validate(
              RentalLine."Unit Price",
              Round(
                InvoiceRoundingAmount /
                (1 + (1 - RentalHeader."VAT Base Discount %" / 100) * RentalLine."VAT %" / 100),
                Currency."Amount Rounding Precision"));
        RentalLine."Prepayment Amount" := RentalLine."Unit Price";
        RentalLine.Validate("Amount Including VAT", InvoiceRoundingAmount);

        exit(true);
    end;

    local procedure CopyHeaderCommentLines(FromNumber: Code[20]; ToDocType: Integer; ToNumber: Code[20])
    var
        RentalCommentLine: Record "TWE Rental Comment Line";
    begin
        if not RentalSetup."Copy Comments Contract to Inv." then
            exit;

        case ToDocType of
            DATABASE::"TWE Rental Invoice Header":
                RentalCommentLine.CopyHeaderComments(
                    RentalCommentLine."Document Type"::Order.AsInteger(), RentalCommentLine."Document Type"::"Posted Invoice".AsInteger(),
                    FromNumber, ToNumber);
            DATABASE::"TWE Rental Cr.Memo Header":
                RentalCommentLine.CopyHeaderComments(
                    RentalCommentLine."Document Type"::Order.AsInteger(), RentalCommentLine."Document Type"::"Posted Credit Memo".AsInteger(),
                        FromNumber, ToNumber);
        end;
    end;

    local procedure CopyLineCommentLines(FromNumber: Code[20]; ToDocType: Integer; ToNumber: Code[20]; FromLineNo: Integer; ToLineNo: Integer)
    var
        RentalCommentLine: Record "TWE Rental Comment Line";
    begin
        if not RentalSetup."Copy Comments Contract to Inv." then
            exit;

        case ToDocType of
            DATABASE::"TWE Rental Invoice Header":
                RentalCommentLine.CopyLineComments(
                    RentalCommentLine."Document Type"::Order.AsInteger(), RentalCommentLine."Document Type"::"Posted Invoice".AsInteger(),
                    FromNumber, ToNumber, FromLineNo, ToLineNo);
            DATABASE::"TWE Rental Cr.Memo Header":
                RentalCommentLine.CopyLineComments(
                    RentalCommentLine."Document Type"::Order.AsInteger(), RentalCommentLine."Document Type"::"Posted Credit Memo".AsInteger(),
                    FromNumber, ToNumber, FromLineNo, ToLineNo);
        end;
    end;

    local procedure CopyLineCommentLinesCompressedPrepayment(FromNumber: Code[20]; ToDocType: Integer; ToNumber: Code[20])
    var
        RentalCommentLine: Record "TWE Rental Comment Line";
    begin
        if not RentalSetup."Copy Comments Contract to Inv." then
            exit;

        case ToDocType of
            DATABASE::"TWE Rental Invoice Header":
                RentalCommentLine.CopyLineCommentsFromRentalLines(
                  RentalCommentLine."Document Type"::Order.AsInteger(), RentalCommentLine."Document Type"::"Posted Invoice".AsInteger(),
                  FromNumber, ToNumber, TempRentalLine);
            DATABASE::"TWE Rental Cr.Memo Header":
                RentalCommentLine.CopyLineCommentsFromRentalLines(
                  RentalCommentLine."Document Type"::Order.AsInteger(), RentalCommentLine."Document Type"::"Posted Credit Memo".AsInteger(),
                  FromNumber, ToNumber, TempRentalLine);
        end;
    end;

    local procedure InsertExtendedText(TabNo: Integer; DocNo: Code[20]; GLAccNo: Code[20]; DocDate: Date; LanguageCode: Code[10]; var PrevLineNo: Integer)
    var
        TempExtTextLine: Record "Extended Text Line" temporary;
        RentalInvLine: Record "TWE Rental Invoice Line";
        RentalCrMemoLine: Record "TWE Rental Cr.Memo Line";
        TransferExtText: Codeunit "Transfer Extended Text";
        NextLineNo: Integer;
    begin
        OnBeforeInsertExtendedText(TabNo, DocNo, GLAccNo, DocDate, LanguageCode, PrevLineNo);
        TransferExtText.PrepmtGetAnyExtText(GLAccNo, TabNo, DocDate, LanguageCode, TempExtTextLine);
        if TempExtTextLine.Find('-') then begin
            NextLineNo := PrevLineNo + 10000;
            repeat
                case TabNo of
                    DATABASE::"TWE Rental Invoice Line":
                        begin
                            RentalInvLine.Init();
                            RentalInvLine."Document No." := DocNo;
                            RentalInvLine."Line No." := NextLineNo;
                            RentalInvLine.Description := TempExtTextLine.Text;
                            RentalInvLine.Insert();
                        end;
                    DATABASE::"TWE Rental Cr.Memo Line":
                        begin
                            RentalCrMemoLine.Init();
                            RentalCrMemoLine."Document No." := DocNo;
                            RentalCrMemoLine."Line No." := NextLineNo;
                            RentalCrMemoLine.Description := TempExtTextLine.Text;
                            RentalCrMemoLine.Insert();
                        end;
                end;
                PrevLineNo := NextLineNo;
                NextLineNo := NextLineNo + 10000;
            until TempExtTextLine.Next() = 0;
        end;
    end;

    procedure UpdateVATOnLines(RentalHeader: Record "TWE Rental Header"; var RentalLine: Record "TWE Rental Line"; var VATAmountLine: Record "VAT Amount Line"; DocumentType: Option Invoice,"Credit Memo",Statistic)
    var
        TempVATAmountLineRemainder: Record "VAT Amount Line" temporary;
        Currency: Record Currency;
        PrepmtAmt: Decimal;
        NewAmount: Decimal;
        NewAmountIncludingVAT: Decimal;
        NewVATBaseAmount: Decimal;
        VATAmount: Decimal;
        VATDifference: Decimal;
        PrepmtAmtToInvTotal: Decimal;
        RemainderExists: Boolean;
    begin
        Currency.Initialize(RentalHeader."Currency Code");

        ApplyFilter(RentalHeader, DocumentType, RentalLine);
        RentalLine.LockTable();
        RentalLine.CalcSums("Prepmt. Line Amount", "Prepmt. Amt. Inv.");
        PrepmtAmtToInvTotal := RentalLine."Prepmt. Line Amount" - RentalLine."Prepmt. Amt. Inv.";
        if RentalLine.FindSet() then
            repeat
                PrepmtAmt := PrepmtAmount(RentalLine, DocumentType);
                if PrepmtAmt <> 0 then begin
                    VATAmountLine.Get(
                      RentalLine."Prepayment VAT Identifier", RentalLine."Prepmt. VAT Calc. Type", RentalLine."Prepayment Tax Group Code", false, PrepmtAmt >= 0);
                    OnUpdateVATOnLinesOnAfterVATAmountLineGet(VATAmountLine);
                    if VATAmountLine.Modified then begin
                        RemainderExists :=
                          TempVATAmountLineRemainder.Get(
                            RentalLine."Prepayment VAT Identifier", RentalLine."Prepmt. VAT Calc. Type", RentalLine."Prepayment Tax Group Code", false, PrepmtAmt >= 0);
                        OnUpdateVATOnLinesOnAfterGetRemainder(TempVATAmountLineRemainder, RemainderExists);
                        if not RemainderExists then begin
                            TempVATAmountLineRemainder := VATAmountLine;
                            TempVATAmountLineRemainder.Init();
                            TempVATAmountLineRemainder.Insert();
                        end;

                        if RentalHeader."Prices Including VAT" then begin
                            if PrepmtAmt = 0 then begin
                                VATAmount := 0;
                                NewAmountIncludingVAT := 0;
                            end else begin
                                VATAmount :=
                                  TempVATAmountLineRemainder."VAT Amount" +
                                  VATAmountLine."VAT Amount" * PrepmtAmt / VATAmountLine."Line Amount";
                                NewAmountIncludingVAT :=
                                  TempVATAmountLineRemainder."Amount Including VAT" +
                                  VATAmountLine."Amount Including VAT" * PrepmtAmt / VATAmountLine."Line Amount";
                            end;
                            NewAmount :=
                              Round(NewAmountIncludingVAT, Currency."Amount Rounding Precision") -
                              Round(VATAmount, Currency."Amount Rounding Precision");
                            NewVATBaseAmount :=
                              Round(
                                NewAmount * (1 - RentalHeader."VAT Base Discount %" / 100),
                                Currency."Amount Rounding Precision");
                        end else begin
                            if RentalLine."VAT Calculation Type" = RentalLine."VAT Calculation Type"::"Full VAT" then begin
                                VATAmount := PrepmtAmt;
                                NewAmount := 0;
                                NewVATBaseAmount := 0;
                            end else begin
                                NewAmount := PrepmtAmt;
                                NewVATBaseAmount :=
                                  Round(
                                    NewAmount * (1 - RentalHeader."VAT Base Discount %" / 100),
                                    Currency."Amount Rounding Precision");
                                if VATAmountLine."VAT Base" = 0 then
                                    VATAmount := 0
                                else
                                    VATAmount :=
                                      TempVATAmountLineRemainder."VAT Amount" +
                                      VATAmountLine."VAT Amount" * NewAmount / VATAmountLine."VAT Base";
                            end;
                            NewAmountIncludingVAT := NewAmount + Round(VATAmount, Currency."Amount Rounding Precision");
                        end;

                        RentalLine."Prepayment Amount" := NewAmount;
                        RentalLine."Prepmt. Amt. Incl. VAT" :=
                          Round(NewAmountIncludingVAT, Currency."Amount Rounding Precision");
                        RentalLine."Prepmt. VAT Base Amt." := NewVATBaseAmount;

                        if (VATAmountLine."Line Amount" - VATAmountLine."Invoice Discount Amount") = 0 then
                            VATDifference := 0
                        else
                            if PrepmtAmtToInvTotal = 0 then
                                VATDifference :=
                                  VATAmountLine."VAT Difference" * (RentalLine."Prepmt. Line Amount" - RentalLine."Prepmt. Amt. Inv.") /
                                  (VATAmountLine."Line Amount" - VATAmountLine."Invoice Discount Amount")
                            else
                                VATDifference :=
                                  VATAmountLine."VAT Difference" * (RentalLine."Prepmt. Line Amount" - RentalLine."Prepmt. Amt. Inv.") /
                                  PrepmtAmtToInvTotal;

                        RentalLine."Prepayment VAT Difference" := Round(VATDifference, Currency."Amount Rounding Precision");
                        OnUpdateVATOnLinesOnBeforeRentalLineModify(RentalHeader, RentalLine, TempVATAmountLineRemainder, NewAmount, NewAmountIncludingVAT, NewVATBaseAmount);
                        RentalLine.Modify();

                        TempVATAmountLineRemainder."Amount Including VAT" :=
                          NewAmountIncludingVAT - Round(NewAmountIncludingVAT, Currency."Amount Rounding Precision");
                        TempVATAmountLineRemainder."VAT Amount" := VATAmount - NewAmountIncludingVAT + NewAmount;
                        TempVATAmountLineRemainder."VAT Difference" := VATDifference - RentalLine."Prepayment VAT Difference";
                        TempVATAmountLineRemainder.Modify();
                    end;
                end;
            until RentalLine.Next() = 0;

        OnAfterUpdateVATOnLines(RentalHeader, RentalLine, VATAmountLine, DocumentType);
    end;

    procedure CalcVATAmountLines(var RentalHeader: Record "TWE Rental Header"; var RentalLine: Record "TWE Rental Line"; var VATAmountLine: Record "VAT Amount Line"; DocumentType: Option Invoice,"Credit Memo",Statistic)
    var
        Currency: Record Currency;
        NewAmount: Decimal;
        NewPrepmtVATDiffAmt: Decimal;
    begin
        Currency.Initialize(RentalHeader."Currency Code");

        VATAmountLine.DeleteAll();

        ApplyFilter(RentalHeader, DocumentType, RentalLine);
        if RentalLine.Find('-') then
            repeat
                NewAmount := PrepmtAmount(RentalLine, DocumentType);
                if NewAmount <> 0 then begin
                    if DocumentType = DocumentType::Invoice then
                        NewAmount := RentalLine."Prepmt. Line Amount";
                    if RentalLine."Prepmt. VAT Calc. Type" in
                       [RentalLine."VAT Calculation Type"::"Reverse Charge VAT", RentalLine."VAT Calculation Type"::"Sales Tax"]
                    then
                        RentalLine."VAT %" := 0;
                    if not VATAmountLine.Get(
                         RentalLine."Prepayment VAT Identifier", RentalLine."Prepmt. VAT Calc. Type", RentalLine."Prepayment Tax Group Code", false, NewAmount >= 0)
                    then
                        VATAmountLine.InsertNewLine(
                          RentalLine."Prepayment VAT Identifier", RentalLine."Prepmt. VAT Calc. Type", RentalLine."Prepayment Tax Group Code", false,
                          RentalLine."Prepayment VAT %", NewAmount >= 0, true);

                    VATAmountLine."Line Amount" := VATAmountLine."Line Amount" + NewAmount;
                    NewPrepmtVATDiffAmt := PrepmtVATDiffAmount(RentalLine, DocumentType);
                    if DocumentType = DocumentType::Invoice then
                        NewPrepmtVATDiffAmt := RentalLine."Prepayment VAT Difference" + RentalLine."Prepmt VAT Diff. to Deduct" +
                          RentalLine."Prepmt VAT Diff. Deducted";
                    VATAmountLine."VAT Difference" := VATAmountLine."VAT Difference" + NewPrepmtVATDiffAmt;
                    VATAmountLine.Modify();
                end;
            until RentalLine.Next() = 0;


        VATAmountLine.UpdateLines(
          NewAmount, Currency, RentalHeader."Currency Factor", RentalHeader."Prices Including VAT",
          RentalHeader."VAT Base Discount %", RentalHeader."Tax Area Code", RentalHeader."Tax Liable", RentalHeader."Posting Date");

        OnAfterCalcVATAmountLines(RentalHeader, RentalLine, VATAmountLine, DocumentType);
    end;

    procedure SumPrepmt(RentalHeader: Record "TWE Rental Header"; var RentalLine: Record "TWE Rental Line"; var VATAmountLine: Record "VAT Amount Line"; var TotalAmount: Decimal; var TotalVATAmount: Decimal; var VATAmountText: Text[30])
    var
        TempPrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer" temporary;
        TotalPrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer";
        TotalPrepmtInvLineBufLCY: Record "Prepayment Inv. Line Buffer";
        DifVATPct: Boolean;
        PrevVATPct: Decimal;
    begin
        CalcVATAmountLines(RentalHeader, RentalLine, VATAmountLine, 2);
        UpdateVATOnLines(RentalHeader, RentalLine, VATAmountLine, 2);
        BuildInvLineBuffer(RentalHeader, RentalLine, 2, TempPrepmtInvLineBuf, false);
        if TempPrepmtInvLineBuf.Find('-') then begin
            PrevVATPct := TempPrepmtInvLineBuf."VAT %";
            repeat
                RoundAmounts(RentalHeader, TempPrepmtInvLineBuf, TotalPrepmtInvLineBuf, TotalPrepmtInvLineBufLCY);
                if TempPrepmtInvLineBuf."VAT %" <> PrevVATPct then
                    DifVATPct := true;
            until TempPrepmtInvLineBuf.Next() = 0;
        end;

        TotalAmount := TotalPrepmtInvLineBuf.Amount;
        TotalVATAmount := TotalPrepmtInvLineBuf."VAT Amount";
        if DifVATPct or (TempPrepmtInvLineBuf."VAT %" = 0) then
            VATAmountText := Text014Lbl
        else
            VATAmountText := StrSubstNo(Text015Lbl, PrevVATPct);
    end;

    procedure GetRentalLines(RentalHeader: Record "TWE Rental Header"; DocumentType: Option Invoice,"Credit Memo",Statistic; var ToRentalLine: Record "TWE Rental Line")
    var
        LocalRentalSetup: Record "TWE Rental Setup";
        FromRentalLine: Record "TWE Rental Line";
        InvRoundingRentalLine: Record "TWE Rental Line";
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        TotalAmt: Decimal;
        NextLineNo: Integer;
    begin
        ApplyFilter(RentalHeader, DocumentType, FromRentalLine);
        if FromRentalLine.Find('-') then begin
            repeat
                ToRentalLine := FromRentalLine;
                ToRentalLine.Insert();
            until FromRentalLine.Next() = 0;

            LocalRentalSetup.Get();
            if LocalRentalSetup."Invoice Rounding" then begin
                CalcVATAmountLines(RentalHeader, ToRentalLine, TempVATAmountLine, 2);
                UpdateVATOnLines(RentalHeader, ToRentalLine, TempVATAmountLine, 2);
                ToRentalLine.CalcSums("Prepmt. Amt. Incl. VAT");
                TotalAmt := ToRentalLine."Prepmt. Amt. Incl. VAT";
                ToRentalLine.FindLast();
                if InitInvoiceRoundingLine(RentalHeader, TotalAmt, InvRoundingRentalLine) then
                    NextLineNo := ToRentalLine."Line No." + 1;
                ToRentalLine := InvRoundingRentalLine;
                ToRentalLine."Line No." := NextLineNo;

                if DocumentType <> DocumentType::"Credit Memo" then
                    ToRentalLine."Prepmt. Line Amount" := ToRentalLine."Line Amount"
                else
                    ToRentalLine."Prepmt. Amt. Inv." := ToRentalLine."Line Amount";
                ToRentalLine."Prepmt. VAT Calc. Type" := ToRentalLine."VAT Calculation Type";
                ToRentalLine."Prepayment VAT Identifier" := ToRentalLine."VAT Identifier";
                ToRentalLine."Prepayment Tax Group Code" := ToRentalLine."Tax Group Code";
                ToRentalLine."Prepayment VAT Identifier" := ToRentalLine."VAT Identifier";
                ToRentalLine."Prepayment Tax Group Code" := ToRentalLine."Tax Group Code";
                ToRentalLine."Prepayment VAT %" := ToRentalLine."VAT %";
                ToRentalLine.Insert();
            end;
        end;
    end;

    local procedure ApplyFilter(RentalHeader: Record "TWE Rental Header"; DocumentType: Option Invoice,"Credit Memo",Statistic; var RentalLine: Record "TWE Rental Line")
    begin
        RentalLine.Reset();
        RentalLine.SetRange("Document Type", RentalHeader."Document Type");
        RentalLine.SetRange("Document No.", RentalHeader."No.");
        RentalLine.SetFilter(Type, '<>%1', RentalLine.Type::" ");
        if DocumentType in [DocumentType::Invoice, DocumentType::Statistic] then
            RentalLine.SetFilter("Prepmt. Line Amount", '<>0')
        else
            RentalLine.SetFilter("Prepmt. Amt. Inv.", '<>0');

        OnAfterApplyFilter(RentalLine, RentalHeader, DocumentType);
    end;

    procedure PrepmtAmount(RentalLine: Record "TWE Rental Line"; DocumentType: Option Invoice,"Credit Memo",Statistic): Decimal
    begin
        case DocumentType of
            DocumentType::Statistic:
                exit(RentalLine."Prepmt. Line Amount");
            DocumentType::Invoice:
                exit(RentalLine."Prepmt. Line Amount" - RentalLine."Prepmt. Amt. Inv.");
            else
                exit(RentalLine."Prepmt. Amt. Inv." - RentalLine."Prepmt Amt Deducted");
        end;
    end;

    local procedure PostPrepmtInvLineBuffer(RentalHeader: Record "TWE Rental Header"; PrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; DocumentType: Option Invoice,"Credit Memo"; PostingDescription: Text[100]; DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20];
                                                                                                                                                                                                                                         ExtDocNo: Text[35];
                                                                                                                                                                                                                                         SrcCode: Code[10];
                                                                                                                                                                                                                                         PostingNoSeriesCode: Code[20])
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        GenJnlLine.InitNewLine(
          RentalHeader."Posting Date", RentalHeader."Document Date", PostingDescription,
          PrepmtInvLineBuffer."Global Dimension 1 Code", PrepmtInvLineBuffer."Global Dimension 2 Code",
          PrepmtInvLineBuffer."Dimension Set ID", RentalHeader."Reason Code");

        GenJnlLine.CopyDocumentFields(DocType, DocNo, ExtDocNo, SrcCode, PostingNoSeriesCode);
        GenJnlLine.CopyFromRentalHeaderPrepmt(RentalHeader);
        GenJnlLine.CopyFromPrepmtInvoiceBuffer(PrepmtInvLineBuffer);

        if not PrepmtInvLineBuffer.Adjustment then
            GenJnlLine."Gen. Posting Type" := GenJnlLine."Gen. Posting Type"::Sale;
        GenJnlLine.Correction :=
          (DocumentType = DocumentType::"Credit Memo") and GLSetup."Mark Cr. Memos as Corrections";

        OnBeforePostPrepmtInvLineBuffer(GenJnlLine, PrepmtInvLineBuffer, SuppressCommit);
        RunGenJnlPostLine(GenJnlLine);
        OnAfterPostPrepmtInvLineBuffer(GenJnlLine, PrepmtInvLineBuffer, SuppressCommit, GenJnlPostLine);
    end;

    local procedure PostCustomerEntry(RentalHeader: Record "TWE Rental Header"; TotalPrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; TotalPrepmtInvLineBufferLCY: Record "Prepayment Inv. Line Buffer"; DocumentType: Option Invoice,"Credit Memo"; PostingDescription: Text[100]; DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20];
                                                                                                                                                                                                                                                                                                           ExtDocNo: Text[35];
                                                                                                                                                                                                                                                                                                           SrcCode: Code[10];
                                                                                                                                                                                                                                                                                                           PostingNoSeriesCode: Code[20];
                                                                                                                                                                                                                                                                                                           CalcPmtDisc: Boolean)
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        GenJnlLine.InitNewLine(
          RentalHeader."Posting Date", RentalHeader."Document Date", PostingDescription,
          RentalHeader."Shortcut Dimension 1 Code", RentalHeader."Shortcut Dimension 2 Code",
          RentalHeader."Dimension Set ID", RentalHeader."Reason Code");

        GenJnlLine.CopyDocumentFields(DocType, DocNo, ExtDocNo, SrcCode, PostingNoSeriesCode);

        GenJnlLine.CopyFromRentalHeaderPrepmtPost(RentalHeader, (DocumentType = DocumentType::Invoice) or CalcPmtDisc);

        GenJnlLine.Amount := -TotalPrepmtInvLineBuffer."Amount Incl. VAT";
        GenJnlLine."Source Currency Amount" := -TotalPrepmtInvLineBuffer."Amount Incl. VAT";
        GenJnlLine."Amount (LCY)" := -TotalPrepmtInvLineBufferLCY."Amount Incl. VAT";
        GenJnlLine."Sales/Purch. (LCY)" := -TotalPrepmtInvLineBufferLCY.Amount;
        GenJnlLine."Profit (LCY)" := -TotalPrepmtInvLineBufferLCY.Amount;

        GenJnlLine.Correction := (DocumentType = DocumentType::"Credit Memo") and GLSetup."Mark Cr. Memos as Corrections";

        OnBeforePostCustomerEntry(GenJnlLine, TotalPrepmtInvLineBuffer, TotalPrepmtInvLineBufferLCY, SuppressCommit);
        GenJnlPostLine.RunWithCheck(GenJnlLine);
        OnAfterPostCustomerEntry(GenJnlLine, TotalPrepmtInvLineBuffer, TotalPrepmtInvLineBufferLCY, SuppressCommit);
    end;

    local procedure PostBalancingEntry(RentalHeader: Record "TWE Rental Header"; TotalPrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; TotalPrepmtInvLineBufferLCY: Record "Prepayment Inv. Line Buffer"; CustLedgEntry: Record "Cust. Ledger Entry"; DocumentType: Option Invoice,"Credit Memo"; PostingDescription: Text[100]; DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20];
                                                                                                                                                                                                                                                                                                                                                        ExtDocNo: Text[35];
                                                                                                                                                                                                                                                                                                                                                        SrcCode: Code[10];
                                                                                                                                                                                                                                                                                                                                                        PostingNoSeriesCode: Code[20])
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        GenJnlLine.InitNewLine(
          RentalHeader."Posting Date", RentalHeader."Document Date", PostingDescription,
          RentalHeader."Shortcut Dimension 1 Code", RentalHeader."Shortcut Dimension 2 Code",
          RentalHeader."Dimension Set ID", RentalHeader."Reason Code");

        if DocType = GenJnlLine."Document Type"::"Credit Memo" then
            GenJnlLine.CopyDocumentFields(GenJnlLine."Document Type"::Refund, DocNo, ExtDocNo, SrcCode, PostingNoSeriesCode)
        else
            GenJnlLine.CopyDocumentFields(GenJnlLine."Document Type"::Payment, DocNo, ExtDocNo, SrcCode, PostingNoSeriesCode);

        GenJnlLine.CopyFromRentalHeaderPrepmtPost(RentalHeader, false);
        if RentalHeader."Bal. Account Type" = RentalHeader."Bal. Account Type"::"Bank Account" then
            GenJnlLine."Bal. Account Type" := GenJnlLine."Bal. Account Type"::"Bank Account";
        GenJnlLine."Bal. Account No." := RentalHeader."Bal. Account No.";

        GenJnlLine.Amount := TotalPrepmtInvLineBuffer."Amount Incl. VAT" + CustLedgEntry."Remaining Pmt. Disc. Possible";
        GenJnlLine."Source Currency Amount" := GenJnlLine.Amount;
        if CustLedgEntry.Amount = 0 then
            GenJnlLine."Amount (LCY)" := TotalPrepmtInvLineBufferLCY."Amount Incl. VAT"
        else
            GenJnlLine."Amount (LCY)" :=
              TotalPrepmtInvLineBufferLCY."Amount Incl. VAT" +
              Round(
                CustLedgEntry."Remaining Pmt. Disc. Possible" / CustLedgEntry."Adjusted Currency Factor");

        GenJnlLine.Correction := (DocumentType = DocumentType::"Credit Memo") and GLSetup."Mark Cr. Memos as Corrections";

        GenJnlLine."Applies-to Doc. Type" := DocType;
        GenJnlLine."Applies-to Doc. No." := DocNo;

        OnBeforePostBalancingEntry(GenJnlLine, CustLedgEntry, TotalPrepmtInvLineBuffer, TotalPrepmtInvLineBufferLCY, SuppressCommit);
        GenJnlPostLine.RunWithCheck(GenJnlLine);
        OnAfterPostBalancingEntry(GenJnlLine, CustLedgEntry, TotalPrepmtInvLineBuffer, TotalPrepmtInvLineBufferLCY, SuppressCommit);
    end;

    local procedure RunGenJnlPostLine(var GenJnlLine: Record "Gen. Journal Line")
    begin
        GenJnlPostLine.RunWithCheck(GenJnlLine);
    end;

    procedure UpdatePrepmtAmountOnRentallines(RentalHeader: Record "TWE Rental Header"; NewTotalPrepmtAmount: Decimal)
    var
        Currency: Record Currency;
        RentalLine: Record "TWE Rental Line";
        TotalLineAmount: Decimal;
        TotalPrepmtAmount: Decimal;
        TotalPrepmtAmtInv: Decimal;
        LastLineNo: Integer;
    begin
        TotalPrepmtAmount := 0;
        Currency.Initialize(RentalHeader."Currency Code");

        RentalLine.SetRange("Document Type", RentalHeader."Document Type");
        RentalLine.SetRange("Document No.", RentalHeader."No.");
        RentalLine.SetFilter(Type, '<>%1', RentalLine.Type::" ");
        RentalLine.SetFilter("Line Amount", '<>0');
        RentalLine.SetFilter("Prepayment %", '<>0');
        RentalLine.LockTable();
        if RentalLine.Find('-') then
            repeat
                TotalLineAmount := TotalLineAmount + RentalLine."Line Amount";
                TotalPrepmtAmtInv := TotalPrepmtAmtInv + RentalLine."Prepmt. Amt. Inv.";
                LastLineNo := RentalLine."Line No.";
            until RentalLine.Next() = 0
        else
            Error(Text017Lbl, RentalLine.FieldCaption("Prepayment %"));
        if TotalLineAmount = 0 then
            Error(Text013Lbl, NewTotalPrepmtAmount);
        if not (NewTotalPrepmtAmount in [TotalPrepmtAmtInv .. TotalLineAmount]) then
            Error(Text016Lbl, TotalPrepmtAmtInv, TotalLineAmount);
        if RentalLine.Find('-') then
            repeat
                if RentalLine."Line No." <> LastLineNo then
                    RentalLine.Validate(
                      "Prepmt. Line Amount",
                      Round(
                        NewTotalPrepmtAmount * RentalLine."Line Amount" / TotalLineAmount,
                        Currency."Amount Rounding Precision"))
                else
                    RentalLine.Validate("Prepmt. Line Amount", NewTotalPrepmtAmount - TotalPrepmtAmount);
                TotalPrepmtAmount := TotalPrepmtAmount + RentalLine."Prepmt. Line Amount";
                RentalLine.Modify();
            until RentalLine.Next() = 0;

    end;

    local procedure CreateDimensions(var RentalLine: Record "TWE Rental Line")
    var
        SourceCodeSetup: Record "Source Code Setup";
        DimMgt: Codeunit DimensionManagement;
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
    begin
        SourceCodeSetup.Get();
        TableID[1] := DATABASE::"G/L Account";
        No[1] := RentalLine."No.";
        TableID[3] := DATABASE::"Responsibility Center";
        No[3] := RentalLine."Responsibility Center";
        RentalLine."Shortcut Dimension 1 Code" := '';
        RentalLine."Shortcut Dimension 2 Code" := '';
        RentalLine."Dimension Set ID" :=
          DimMgt.GetRecDefaultDimID(
            RentalLine, 0, TableID, No, SourceCodeSetup.Sales,
            RentalLine."Shortcut Dimension 1 Code", RentalLine."Shortcut Dimension 2 Code", RentalLine."Dimension Set ID", DATABASE::Customer);
    end;

    local procedure PrepmtDocTypeToDocType(DocumentType: Option Invoice,"Credit Memo"): Integer
    begin
        case DocumentType of
            DocumentType::Invoice:
                exit(2);
            DocumentType::"Credit Memo":
                exit(3);
        end;
        exit(2);
    end;

    procedure GetRentalLinesToDeduct(RentalHeader: Record "TWE Rental Header"; var RentalLines: Record "TWE Rental Line")
    var
        RentalLine: Record "TWE Rental Line";
    begin
        ApplyFilter(RentalHeader, 1, RentalLine);
        if RentalLine.FindSet() then
            repeat
                if (PrepmtAmount(RentalLine, 0) <> 0) and (PrepmtAmount(RentalLine, 1) <> 0) then begin
                    RentalLines := RentalLine;
                    RentalLines.Insert();
                end;
            until RentalLine.Next() = 0;
    end;

    local procedure PrepmtVATDiffAmount(RentalLine: Record "TWE Rental Line"; DocumentType: Option Invoice,"Credit Memo",Statistic): Decimal
    begin
        case DocumentType of
            DocumentType::Statistic:
                exit(RentalLine."Prepayment VAT Difference");
            DocumentType::Invoice:
                exit(RentalLine."Prepayment VAT Difference");
            else
                exit(RentalLine."Prepmt VAT Diff. to Deduct");
        end;
    end;

    local procedure UpdateRentalDocument(var RentalHeader: Record "TWE Rental Header"; var RentalLine: Record "TWE Rental Line"; DocumentType: Option Invoice,"Credit Memo"; GenJnlLineDocNo: Code[20])
    begin
        RentalLine.Reset();
        RentalLine.SetRange("Document Type", RentalHeader."Document Type");
        RentalLine.SetRange("Document No.", RentalHeader."No.");
        if DocumentType = DocumentType::Invoice then begin
            RentalHeader."Last Prepayment No." := GenJnlLineDocNo;
            RentalHeader."Prepayment No." := '';
            RentalLine.SetFilter("Prepmt. Line Amount", '<>0');
            if RentalLine.FindSet(true) then
                repeat
                    if RentalLine."Prepmt. Line Amount" <> RentalLine."Prepmt. Amt. Inv." then begin
                        RentalLine."Prepmt. Amt. Inv." := RentalLine."Prepmt. Line Amount";
                        RentalLine."Prepmt. Amount Inv. Incl. VAT" := RentalLine."Prepmt. Amt. Incl. VAT";
                        RentalLine.CalcPrepaymentToDeduct();
                        RentalLine."Prepmt VAT Diff. to Deduct" :=
                          RentalLine."Prepmt VAT Diff. to Deduct" + RentalLine."Prepayment VAT Difference";
                        RentalLine."Prepayment VAT Difference" := 0;
                        RentalLine.Modify();
                    end;
                until RentalLine.Next() = 0;
        end else begin
            RentalHeader."Last Prepmt. Cr. Memo No." := GenJnlLineDocNo;
            RentalHeader."Prepmt. Cr. Memo No." := '';
            RentalLine.SetFilter("Prepmt. Amt. Inv.", '<>0');
            if RentalLine.FindSet(true) then
                repeat
                    RentalLine."Prepmt. Amt. Inv." := RentalLine."Prepmt Amt Deducted";
                    if RentalHeader."Prices Including VAT" then
                        RentalLine."Prepmt. Amount Inv. Incl. VAT" := RentalLine."Prepmt. Amt. Inv."
                    else
                        RentalLine."Prepmt. Amount Inv. Incl. VAT" :=
                          Round(
                            RentalLine."Prepmt. Amt. Inv." * (100 + RentalLine."Prepayment VAT %") / 100,
                            GetCurrencyAmountRoundingPrecision(RentalLine."Currency Code"));
                    RentalLine."Prepmt. Amt. Incl. VAT" := RentalLine."Prepmt. Amount Inv. Incl. VAT";
                    RentalLine."Prepayment Amount" := RentalLine."Prepmt. Amt. Inv.";
                    RentalLine."Prepmt Amt to Deduct" := 0;
                    RentalLine."Prepmt VAT Diff. to Deduct" := 0;
                    RentalLine."Prepayment VAT Difference" := 0;
                    RentalLine.Modify();
                until RentalLine.Next() = 0;
        end;
    end;

    local procedure UpdatePostedRentalDocument(DocumentType: Option Invoice,"Credit Memo"; DocumentNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        RentalInvoiceHeader: Record "TWE Rental Invoice Header";
        RentalCrMemoHeader: Record "TWE Rental Cr.Memo Header";
    begin
        case DocumentType of
            DocumentType::Invoice:
                begin
                    CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
                    CustLedgerEntry.SetRange("Document No.", DocumentNo);
                    CustLedgerEntry.FindFirst();
                    RentalInvoiceHeader.Get(DocumentNo);
                    RentalInvoiceHeader."Cust. Ledger Entry No." := CustLedgerEntry."Entry No.";
                    RentalInvoiceHeader.Modify();
                end;
            DocumentType::"Credit Memo":
                begin
                    CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::"Credit Memo");
                    CustLedgerEntry.SetRange("Document No.", DocumentNo);
                    CustLedgerEntry.FindFirst();
                    RentalCrMemoHeader.Get(DocumentNo);
                    RentalCrMemoHeader."Cust. Ledger Entry No." := CustLedgerEntry."Entry No.";
                    RentalCrMemoHeader.Modify();
                end;
        end;

        OnAfterUpdatePostedRentalDocument(DocumentType, DocumentNo, SuppressCommit);
    end;

    local procedure InsertRentalInvHeader(var RentalInvHeader: Record "TWE Rental Invoice Header"; RentalHeader: Record "TWE Rental Header"; PostingDescription: Text[100]; GenJnlLineDocNo: Code[20]; SrcCode: Code[10]; PostingNoSeriesCode: Code[20])
    begin
        RentalInvHeader.Init();
        RentalInvHeader.TransferFields(RentalHeader);
        RentalInvHeader."Posting Description" := PostingDescription;
        RentalInvHeader."Payment Terms Code" := RentalHeader."Prepmt. Payment Terms Code";
        RentalInvHeader."Due Date" := RentalHeader."Prepayment Due Date";
        RentalInvHeader."Pmt. Discount Date" := RentalHeader."Prepmt. Pmt. Discount Date";
        RentalInvHeader."Payment Discount %" := RentalHeader."Prepmt. Payment Discount %";
        RentalInvHeader."No." := GenJnlLineDocNo;
        RentalInvHeader."Pre-Assigned No. Series" := '';
        RentalInvHeader."Source Code" := SrcCode;
        RentalInvHeader."User ID" := Format(UserId);
        RentalInvHeader."No. Printed" := 0;
        RentalInvHeader."Prepayment Invoice" := true;
        RentalInvHeader."Prepayment Order No." := RentalHeader."No.";
        RentalInvHeader."No. Series" := PostingNoSeriesCode;
        OnBeforeRentalInvHeaderInsert(RentalInvHeader, RentalHeader, SuppressCommit);
        RentalInvHeader.Insert();
        CopyHeaderCommentLines(RentalHeader."No.", DATABASE::"TWE Rental Invoice Header", GenJnlLineDocNo);
        OnAfterRentalInvHeaderInsert(RentalInvHeader, RentalHeader, SuppressCommit);
    end;

    local procedure InsertRentalInvLine(RentalInvHeader: Record "TWE Rental Invoice Header"; LineNo: Integer; PrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; RentalHeader: Record "TWE Rental Header")
    var
        RentalInvLine: Record "TWE Rental Invoice Line";
    begin
        RentalInvLine.Init();
        RentalInvLine."Document No." := RentalInvHeader."No.";
        RentalInvLine."Line No." := LineNo;
        RentalInvLine."Rented-to Customer No." := RentalInvHeader."Rented-to Customer No.";
        RentalInvLine."Bill-to Customer No." := RentalInvHeader."Bill-to Customer No.";
        RentalInvLine.Type := RentalInvLine.Type::"G/L Account";
        RentalInvLine."No." := PrepmtInvLineBuffer."G/L Account No.";
        RentalInvLine."Posting Date" := RentalInvHeader."Posting Date";
        RentalInvLine."Shortcut Dimension 1 Code" := PrepmtInvLineBuffer."Global Dimension 1 Code";
        RentalInvLine."Shortcut Dimension 2 Code" := PrepmtInvLineBuffer."Global Dimension 2 Code";
        RentalInvLine."Dimension Set ID" := PrepmtInvLineBuffer."Dimension Set ID";
        RentalInvLine.Description := PrepmtInvLineBuffer.Description;
        RentalInvLine.Quantity := 1;
        if RentalInvHeader."Prices Including VAT" then begin
            RentalInvLine."Unit Price" := PrepmtInvLineBuffer."Amount Incl. VAT";
            RentalInvLine."Line Amount" := PrepmtInvLineBuffer."Amount Incl. VAT";
        end else begin
            RentalInvLine."Unit Price" := PrepmtInvLineBuffer.Amount;
            RentalInvLine."Line Amount" := PrepmtInvLineBuffer.Amount;
        end;
        RentalInvLine."Gen. Bus. Posting Group" := PrepmtInvLineBuffer."Gen. Bus. Posting Group";
        RentalInvLine."Gen. Prod. Posting Group" := PrepmtInvLineBuffer."Gen. Prod. Posting Group";
        RentalInvLine."VAT Bus. Posting Group" := PrepmtInvLineBuffer."VAT Bus. Posting Group";
        RentalInvLine."VAT Prod. Posting Group" := PrepmtInvLineBuffer."VAT Prod. Posting Group";
        RentalInvLine."VAT %" := PrepmtInvLineBuffer."VAT %";
        RentalInvLine.Amount := PrepmtInvLineBuffer.Amount;
        RentalInvLine."VAT Difference" := PrepmtInvLineBuffer."VAT Difference";
        RentalInvLine."Amount Including VAT" := PrepmtInvLineBuffer."Amount Incl. VAT";
        RentalInvLine."VAT Calculation Type" := PrepmtInvLineBuffer."VAT Calculation Type";
        RentalInvLine."VAT Base Amount" := PrepmtInvLineBuffer."VAT Base Amount";
        RentalInvLine."VAT Identifier" := PrepmtInvLineBuffer."VAT Identifier";
        OnBeforeRentalInvLineInsert(RentalInvLine, RentalInvHeader, PrepmtInvLineBuffer, SuppressCommit);
        RentalInvLine.Insert();
        if not RentalHeader."Compress Prepayment" then
            CopyLineCommentLines(
              RentalHeader."No.", DATABASE::"TWE Rental Invoice Header", RentalInvHeader."No.", PrepmtInvLineBuffer."Line No.", LineNo);
        OnAfterRentalInvLineInsert(RentalInvLine, RentalInvHeader, PrepmtInvLineBuffer, SuppressCommit);
    end;

    local procedure InsertRentalCrMemoHeader(var RentalCrMemoHeader: Record "TWE Rental Cr.Memo Header"; RentalHeader: Record "TWE Rental Header"; PostingDescription: Text[100]; GenJnlLineDocNo: Code[20]; SrcCode: Code[10]; PostingNoSeriesCode: Code[20]; CalcPmtDiscOnCrMemos: Boolean)
    begin
        RentalCrMemoHeader.Init();
        RentalCrMemoHeader.TransferFields(RentalHeader);
        RentalCrMemoHeader."Payment Terms Code" := RentalHeader."Prepmt. Payment Terms Code";
        RentalCrMemoHeader."Pmt. Discount Date" := RentalHeader."Prepmt. Pmt. Discount Date";
        RentalCrMemoHeader."Payment Discount %" := RentalHeader."Prepmt. Payment Discount %";
        if (RentalHeader."Prepmt. Payment Terms Code" <> '') and not CalcPmtDiscOnCrMemos then begin
            RentalCrMemoHeader."Payment Discount %" := 0;
            RentalCrMemoHeader."Pmt. Discount Date" := 0D;
        end;
        RentalCrMemoHeader."Posting Description" := PostingDescription;
        RentalCrMemoHeader."Due Date" := RentalHeader."Prepayment Due Date";
        RentalCrMemoHeader."No." := GenJnlLineDocNo;
        RentalCrMemoHeader."Pre-Assigned No. Series" := '';
        RentalCrMemoHeader."Source Code" := SrcCode;
        RentalCrMemoHeader."User ID" := Format(UserId);
        RentalCrMemoHeader."No. Printed" := 0;
        RentalCrMemoHeader."Prepayment Credit Memo" := true;
        RentalCrMemoHeader."Prepayment Order No." := RentalHeader."No.";
        RentalCrMemoHeader.Correction := GLSetup."Mark Cr. Memos as Corrections";
        RentalCrMemoHeader."No. Series" := PostingNoSeriesCode;
        OnBeforeRentalCrMemoHeaderInsert(RentalCrMemoHeader, RentalHeader, SuppressCommit);
        RentalCrMemoHeader.Insert();
        CopyHeaderCommentLines(RentalHeader."No.", DATABASE::"TWE Rental Cr.Memo Header", GenJnlLineDocNo);
        OnAfterRentalCrMemoHeaderInsert(RentalCrMemoHeader, RentalHeader, SuppressCommit);
    end;

    local procedure InsertRentalCrMemoLine(RentalCrMemoHeader: Record "TWE Rental Cr.Memo Header"; LineNo: Integer; PrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; RentalHeader: Record "TWE Rental Header")
    var
        RentalCrMemoLine: Record "TWE Rental Cr.Memo Line";
    begin
        RentalCrMemoLine.Init();
        RentalCrMemoLine."Document No." := RentalCrMemoHeader."No.";
        RentalCrMemoLine."Line No." := LineNo;
        RentalCrMemoLine."Rented-to Customer No." := RentalCrMemoHeader."Rented-to Customer No.";
        RentalCrMemoLine."Bill-to Customer No." := RentalCrMemoHeader."Bill-to Customer No.";
        RentalCrMemoLine.Type := RentalCrMemoLine.Type::"G/L Account";
        RentalCrMemoLine."No." := PrepmtInvLineBuffer."G/L Account No.";
        RentalCrMemoLine."Posting Date" := RentalCrMemoHeader."Posting Date";
        RentalCrMemoLine."Shortcut Dimension 1 Code" := PrepmtInvLineBuffer."Global Dimension 1 Code";
        RentalCrMemoLine."Shortcut Dimension 2 Code" := PrepmtInvLineBuffer."Global Dimension 2 Code";
        RentalCrMemoLine."Dimension Set ID" := PrepmtInvLineBuffer."Dimension Set ID";
        RentalCrMemoLine.Description := PrepmtInvLineBuffer.Description;
        RentalCrMemoLine.Quantity := 1;
        if RentalCrMemoHeader."Prices Including VAT" then begin
            RentalCrMemoLine."Unit Price" := PrepmtInvLineBuffer."Amount Incl. VAT";
            RentalCrMemoLine."Line Amount" := PrepmtInvLineBuffer."Amount Incl. VAT";
        end else begin
            RentalCrMemoLine."Unit Price" := PrepmtInvLineBuffer.Amount;
            RentalCrMemoLine."Line Amount" := PrepmtInvLineBuffer.Amount;
        end;
        RentalCrMemoLine."Gen. Bus. Posting Group" := PrepmtInvLineBuffer."Gen. Bus. Posting Group";
        RentalCrMemoLine."Gen. Prod. Posting Group" := PrepmtInvLineBuffer."Gen. Prod. Posting Group";
        RentalCrMemoLine."VAT Bus. Posting Group" := PrepmtInvLineBuffer."VAT Bus. Posting Group";
        RentalCrMemoLine."VAT Prod. Posting Group" := PrepmtInvLineBuffer."VAT Prod. Posting Group";
        RentalCrMemoLine."VAT %" := PrepmtInvLineBuffer."VAT %";
        RentalCrMemoLine.Amount := PrepmtInvLineBuffer.Amount;
        RentalCrMemoLine."VAT Difference" := PrepmtInvLineBuffer."VAT Difference";
        RentalCrMemoLine."Amount Including VAT" := PrepmtInvLineBuffer."Amount Incl. VAT";
        RentalCrMemoLine."VAT Calculation Type" := PrepmtInvLineBuffer."VAT Calculation Type";
        RentalCrMemoLine."VAT Base Amount" := PrepmtInvLineBuffer."VAT Base Amount";
        RentalCrMemoLine."VAT Identifier" := PrepmtInvLineBuffer."VAT Identifier";
        OnBeforeRentalCrMemoLineInsert(RentalCrMemoLine, RentalCrMemoHeader, PrepmtInvLineBuffer, SuppressCommit);
        RentalCrMemoLine.Insert();
        if not RentalHeader."Compress Prepayment" then
            CopyLineCommentLines(
              RentalHeader."No.", DATABASE::"TWE Rental Cr.Memo Header", RentalCrMemoHeader."No.", PrepmtInvLineBuffer."Line No.", LineNo);
        OnAfterRentalCrMemoLineInsert(RentalCrMemoLine, RentalCrMemoHeader, PrepmtInvLineBuffer, SuppressCommit);
    end;

    local procedure GetCalcPmtDiscOnCrMemos(PrepmtPmtTermsCode: Code[10]): Boolean
    var
        PaymentTerms: Record "Payment Terms";
    begin
        if PrepmtPmtTermsCode = '' then
            exit(false);
        PaymentTerms.Get(PrepmtPmtTermsCode);
        exit(PaymentTerms."Calc. Pmt. Disc. on Cr. Memos");
    end;

    procedure GetPreviewMode(): Boolean
    begin
        exit(PreviewMode);
    end;

    procedure GetSuppressCommit(): Boolean
    begin
        exit(SuppressCommit);
    end;

    procedure SetSuppressCommit(NewSuppressCommit: Boolean)
    begin
        SuppressCommit := NewSuppressCommit;
    end;

    procedure SetPreviewMode(NewPreviewMode: Boolean)
    begin
        PreviewMode := NewPreviewMode;
    end;

    local procedure CheckRentalLineIsNegative(RentalHeader: Record "TWE Rental Header"; RentalLine: Record "TWE Rental Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckRentalLineIsNegative(RentalLine, IsHandled);
        if IsHandled then
            exit;

        if RentalLine.Quantity < 0 then
            RentalLine.FieldError(Quantity, StrSubstNo(Text018Lbl, RentalHeader.FieldCaption("Prepayment %")));
        if RentalLine."Unit Price" < 0 then
            RentalLine.FieldError("Unit Price", StrSubstNo(Text018Lbl, RentalHeader.FieldCaption("Prepayment %")));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterApplyFilter(var RentalLine: Record "TWE Rental Line"; RentalHeader: Record "TWE Rental Header"; DocumentType: Option)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterBuildInvLineBuffer(var PrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcVATAmountLines(RentalHeader: Record "TWE Rental Header"; var RentalLine: Record "TWE Rental Line"; var VATAmountLine: Record "VAT Amount Line"; DocumentType: Option Invoice,"Credit Memo",Statistic)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckPrepmtDoc(RentalHeader: Record "TWE Rental Header"; DocumentType: Option Invoice,"Credit Memo"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateLinesOnBeforeGLPosting(var RentalHeader: Record "TWE Rental Header"; RentalInvHeader: Record "TWE Rental Invoice Header"; RentalCrMemoHeader: Record "TWE Rental Cr.Memo Header"; var TempPrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer" temporary; DocumentType: Option; var LastLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFillInvLineBuffer(var PrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer"; RentalLine: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertInvoiceRounding(RentalHeader: Record "TWE Rental Header"; var PrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; var TotalPrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer"; var PrevLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostPrepayments(var RentalHeader: Record "TWE Rental Header"; DocumentType: Option Invoice,"Credit Memo"; CommitIsSuppressed: Boolean; var RentalInvoiceHeader: Record "TWE Rental Invoice Header"; var RentalCrMemoHeader: Record "TWE Rental Cr.Memo Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostPrepaymentsOnBeforeThrowPreviewModeError(var RentalHeader: Record "TWE Rental Header"; var RentalInvHeader: Record "TWE Rental Invoice Header"; var RentalCrMemoHeader: Record "TWE Rental Cr.Memo Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; PreviewMode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostBalancingEntry(var GenJnlLine: Record "Gen. Journal Line"; CustLedgEntry: Record "Cust. Ledger Entry"; TotalPrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; TotalPrepmtInvLineBufferLCY: Record "Prepayment Inv. Line Buffer"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostCustomerEntry(var GenJnlLine: Record "Gen. Journal Line"; TotalPrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; TotalPrepmtInvLineBufferLCY: Record "Prepayment Inv. Line Buffer"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostPrepmtInvLineBuffer(var GenJnlLine: Record "Gen. Journal Line"; PrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; CommitIsSuppressed: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRoundAmounts(RentalHeader: Record "TWE Rental Header"; var PrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; var TotalPrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer"; var TotalPrepmtInvLineBufLCY: Record "Prepayment Inv. Line Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRentalInvHeaderInsert(var RentalInvoiceHeader: Record "TWE Rental Invoice Header"; RentalHeader: Record "TWE Rental Header"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRentalInvLineInsert(var RentalInvLine: Record "TWE Rental Invoice Line"; RentalInvHeader: Record "TWE Rental Invoice Header"; PrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRentalCrMemoHeaderInsert(var RentalCrMemoHeader: Record "TWE Rental Cr.Memo Header"; RentalHeader: Record "TWE Rental Header"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRentalCrMemoLineInsert(var RentalCrMemoLine: Record "TWE Rental Cr.Memo Line"; RentalCrMemoHeader: Record "TWE Rental Cr.Memo Header"; PrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdatePostedRentalDocument(DocumentType: Option Invoice,"Credit Memo"; DocumentNo: Code[20]; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateVATOnLines(RentalHeader: Record "TWE Rental Header"; var RentalLine: Record "TWE Rental Line"; var VATAmountLine: Record "VAT Amount Line"; DocumentType: Option Invoice,"Credit Memo",Statistic)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckPrepmtDoc(RentalHeader: Record "TWE Rental Header"; DocumentType: Option; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInvoice(var RentalHeader: Record "TWE Rental Header"; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreditMemo(var RentalHeader: Record "TWE Rental Header"; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFillInvLineBuffer(var PrepaymentInvLineBuffer: Record "Prepayment Inv. Line Buffer"; RentalHeader: Record "TWE Rental Header"; RentalLine: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertExtendedText(TabNo: Integer; DocNo: Code[20]; GLAccNo: Code[20]; DocDate: Date; LanguageCode: Code[10]; var PrevLineNo: Integer);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostPrepayments(var RentalHeader: Record "TWE Rental Header"; DocumentType: Option Invoice,"Credit Memo"; CommitIsSuppressed: Boolean; PreviewMode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRentalInvHeaderInsert(var RentalInvHeader: Record "TWE Rental Invoice Header"; RentalHeader: Record "TWE Rental Header"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRentalInvLineInsert(var RentalInvLine: Record "TWE Rental Invoice Line"; RentalInvHeader: Record "TWE Rental Invoice Header"; PrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRentalCrMemoHeaderInsert(var RentalCrMemoHeader: Record "TWE Rental Cr.Memo Header"; RentalHeader: Record "TWE Rental Header"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRentalCrMemoLineInsert(var RentalCrMemoLine: Record "TWE Rental Cr.Memo Line"; RentalCrMemoHeader: Record "TWE Rental Cr.Memo Header"; PrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostBalancingEntry(var GenJnlLine: Record "Gen. Journal Line"; CustLedgEntry: Record "Cust. Ledger Entry"; TotalPrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; TotalPrepmtInvLineBufferLCY: Record "Prepayment Inv. Line Buffer"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostCustomerEntry(var GenJnlLine: Record "Gen. Journal Line"; TotalPrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; TotalPrepmtInvLineBufferLCY: Record "Prepayment Inv. Line Buffer"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateDocNos(var RentalHeader: Record "TWE Rental Header"; DocumentType: Option Invoice,"Credit Memo"; var DocNo: Code[20]; var NoSeriesCode: Code[20]; var ModifyHeader: Boolean; IsPreviewMode: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostPrepmtInvLineBuffer(var GenJnlLine: Record "Gen. Journal Line"; PrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRoundAmountsOnBeforeIncrAmounts(RentalHeader: Record "TWE Rental Header"; VAR PrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer"; VAR TotalPrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer"; VAR TotalPrepmtInvLineBufLCY: Record "Prepayment Inv. Line Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateVATOnLinesOnAfterGetRemainder(var VATAmountLineRemainder: Record "VAT Amount Line"; var RemainderExists: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateVATOnLinesOnAfterVATAmountLineGet(var VATAmountLine: Record "VAT Amount Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateVATOnLinesOnBeforeRentalLineModify(RentalHeader: Record "TWE Rental Header"; VAR RentalLine: Record "TWE Rental Line"; VAR TempVATAmountLineRemainder: Record "VAT Amount Line"; NewAmount: Decimal; NewAmountIncludingVAT: Decimal; NewVATBaseAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeThrowPreviewError(RentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckRentalLineIsNegative(RentalLine: Record "TWE Rental Line"; var IsHandled: Boolean)
    begin
    end;
}
