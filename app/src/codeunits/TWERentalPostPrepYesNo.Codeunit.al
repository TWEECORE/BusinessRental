codeunit 50034 "TWE Rental-Post Prep.(Yes/No)"
{
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
    end;

    var
        RentalInvHeader: Record "TWE Rental Invoice Header";
        RentalCrMemoHeader: Record "TWE Rental Cr.Memo Header";
        PrepmtDocumentType: Option ,,Invoice,"Credit Memo";
        Text000Lbl: Label 'Do you want to post the prepayments for %1 %2?', Comment = '%1 = Document Type, %2 = Document No.';
        Text001Lbl: Label 'Do you want to post a credit memo for the prepayments for %1 %2?', Comment = '%1 = Document Type, %2 = Document No.';
        UnsupportedDocTypeErr: Label 'Unsupported prepayment document type.';

    procedure PostPrepmtInvoiceYN(var RentalHeader2: Record "TWE Rental Header"; Print: Boolean)
    var
        RentalHeader: Record "TWE Rental Header";
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        RentalHeader.Copy(RentalHeader2);
        if not ConfirmManagement.GetResponseOrDefault(
             StrSubstNo(Text000Lbl, RentalHeader."Document Type", RentalHeader."No."), true)
        then
            exit;

        PostPrepmtDocument(RentalHeader, RentalHeader."Document Type"::Invoice);

        if Print then begin
            Commit();
            GetReport(RentalHeader, 0);
        end;

        OnAfterPostPrepmtInvoiceYN(RentalHeader);

        RentalHeader2 := RentalHeader;
    end;

    procedure PostPrepmtCrMemoYN(var RentalHeader2: Record "TWE Rental Header"; Print: Boolean)
    var
        RentalHeader: Record "TWE Rental Header";
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        RentalHeader.Copy(RentalHeader2);
        if not ConfirmManagement.GetResponseOrDefault(
             StrSubstNo(Text001Lbl, RentalHeader."Document Type", RentalHeader."No."), true)
        then
            exit;

        PostPrepmtDocument(RentalHeader, RentalHeader."Document Type"::"Credit Memo");

        if Print then
            GetReport(RentalHeader, 1);

        Commit();
        OnAfterPostPrepmtCrMemoYN(RentalHeader);

        RentalHeader2 := RentalHeader;
    end;

    local procedure PostPrepmtDocument(var RentalHeader: Record "TWE Rental Header"; PrepmtDocumentType: Enum "TWE Rental Document Type")
    var
        RentalPostPrepayments: Codeunit "TWE Rental-Post Prepayments";
        ErrorMessageHandler: Codeunit "Error Message Handler";
        ErrorMessageMgt: Codeunit "Error Message Management";
    begin
        OnBeforePostPrepmtDocument(RentalHeader, PrepmtDocumentType.AsInteger());

        ErrorMessageMgt.Activate(ErrorMessageHandler);
        RentalPostPrepayments.SetDocumentType(PrepmtDocumentType.AsInteger());
        Commit();
        if not RentalPostPrepayments.Run(RentalHeader) then
            ErrorMessageHandler.ShowErrors();
    end;

    procedure Preview(var RentalHeader: Record "TWE Rental Header"; DocumentType: Option)
    var
        RentalPostPrepaymentYesNo: Codeunit "TWE Rental-Post Prep.(Yes/No)";
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
    begin
        BindSubscription(RentalPostPrepaymentYesNo);
        RentalPostPrepaymentYesNo.SetDocumentType(DocumentType);
        GenJnlPostPreview.Preview(RentalPostPrepaymentYesNo, RentalHeader);
    end;

    procedure GetReport(var RentalHeader: Record "TWE Rental Header"; DocumentType: Option Invoice,"Credit Memo")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetReport(RentalHeader, DocumentType, IsHandled);
        if IsHandled then
            exit;
        case DocumentType of
            DocumentType::Invoice:
                begin
                    RentalInvHeader."No." := RentalHeader."Last Prepayment No.";
                    RentalInvHeader.SetRecFilter();
                    RentalInvHeader.PrintRecords(false);
                end;
            DocumentType::"Credit Memo":
                begin
                    RentalCrMemoHeader."No." := RentalHeader."Last Prepmt. Cr. Memo No.";
                    RentalCrMemoHeader.SetRecFilter();
                    RentalCrMemoHeader.PrintRecords(false);
                end;
        end;
    end;

    procedure SetDocumentType(NewPrepmtDocumentType: Option)
    begin
        PrepmtDocumentType := NewPrepmtDocumentType;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostPrepmtInvoiceYN(var RentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostPrepmtCrMemoYN(var RentalHeader: Record "TWE Rental Header")
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Preview", 'OnRunPreview', '', false, false)]
    local procedure OnRunPreview(var Result: Boolean; Subscriber: Variant; RecVar: Variant)
    var
        RentalHeader: Record "TWE Rental Header";
        RentalPostPrepayments: Codeunit "TWE Rental-Post Prepayments";
    begin
        RentalHeader.Copy(RecVar);
        RentalHeader.Invoice := true;

        if PrepmtDocumentType in [PrepmtDocumentType::Invoice, PrepmtDocumentType::"Credit Memo"] then
            RentalPostPrepayments.SetDocumentType(PrepmtDocumentType)
        else
            Error(UnsupportedDocTypeErr);

        RentalPostPrepayments.SetPreviewMode(true);
        Result := RentalPostPrepayments.Run(RentalHeader);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetReport(var RentalHeader: Record "TWE Rental Header"; DocumentType: Option Invoice,"Credit Memo"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostPrepmtDocument(var RentalHeader: Record "TWE Rental Header"; PrepmtDocumentType: Option)
    begin
    end;
}

