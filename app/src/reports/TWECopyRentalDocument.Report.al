/// <summary>
/// Report TWE Copy Rental Document (ID 50005).
/// </summary>
report 50005 "TWE Copy Rental Document"
{
    Caption = 'Copy Rental Document';
    ProcessingOnly = true;

    dataset
    {
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(DocumentType; FromDocType)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Document Type';
                        ToolTip = 'Specifies the type of document that is processed by the report or batch job.';

                        trigger OnValidate()
                        begin
                            FromDocNo := '';
                            ValidateDocNo();
                        end;
                    }
                    field(DocumentNo; FromDocNo)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Document No.';
                        ShowMandatory = true;
                        ToolTip = 'Specifies the number of the document that is processed by the report or batch job.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            LookupDocNo();
                        end;

                        trigger OnValidate()
                        begin
                            ValidateDocNo();
                        end;
                    }
                    field(FromDocNoOccurrence; FromDocNoOccurrenceInteger)
                    {
                        ApplicationArea = Suite;
                        BlankZero = true;
                        Caption = 'Doc. No. Occurrence';
                        Editable = false;
                        ToolTip = 'Specifies the number of times the No. value has been used in the number series.';
                    }
                    field(FromDocVersionNo; FromDocVersionNoInteger)
                    {
                        ApplicationArea = Suite;
                        BlankZero = true;
                        Caption = 'Version No.';
                        Editable = false;
                        ToolTip = 'Specifies the version of the document to be copied.';
                    }
                    field(RentedToCustNo; FromRentalHeader."Rented-to Customer No.")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Rented-to Customer No.';
                        Editable = false;
                        ToolTip = 'Specifies the sell-to customer number that will appear on the new rental document.';
                    }
                    field(RentedToCustName; FromRentalHeader."Rented-to Customer Name")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Rented-to Customer Name';
                        Editable = false;
                        ToolTip = 'Specifies the sell-to customer name that will appear on the new rental document.';
                    }
                    field("IncludeHeader_Options"; IncludeHeader)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Include Header';
                        ToolTip = 'Specifies if you also want to copy the information from the document header. When you copy quotes, if the posting date field of the new document is empty, the work date is used as the posting date of the new document.';

                        trigger OnValidate()
                        begin
                            ValidateIncludeHeader();
                        end;
                    }
                    field(RecalculateLines; RecalculateLinesBoolean)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Recalculate Lines';
                        ToolTip = 'Specifies that lines are recalculate and inserted on the rental document you are creating. The batch job retains the item numbers and item quantities but recalculates the amounts on the lines based on the customer information on the new document header. In this way, the batch job accounts for item prices and discounts that are specifically linked to the customer on the new header.';

                        trigger OnValidate()
                        begin
                            if (FromDocType = FromDocType::"Posted Shipment") then
                                RecalculateLinesBoolean := true;
                        end;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if FromDocNo <> '' then begin
                case FromDocType of
                    FromDocType::Quote:
                        if FromRentalHeader.Get(FromRentalHeader."Document Type"::Quote, FromDocNo) then
                            ;
                    FromDocType::Contract:
                        if FromRentalHeader.Get(FromRentalHeader."Document Type"::Contract, FromDocNo) then
                            ;
                    FromDocType::Invoice:
                        if FromRentalHeader.Get(FromRentalHeader."Document Type"::Invoice, FromDocNo) then
                            ;
                    FromDocType::"Return Shipment":
                        if FromRentalHeader.Get(FromRentalHeader."Document Type"::"Return Shipment", FromDocNo) then
                            ;
                    FromDocType::"Credit Memo":
                        if FromRentalHeader.Get(FromRentalHeader."Document Type"::"Credit Memo", FromDocNo) then
                            ;
                    FromDocType::"Posted Shipment":
                        if FromRentalShptHeader.Get(FromDocNo) then
                            FromRentalHeader.TransferFields(FromRentalShptHeader);
                    FromDocType::"Posted Invoice":
                        if FromRentalInvHeader.Get(FromDocNo) then
                            FromRentalHeader.TransferFields(FromRentalInvHeader);
                    FromDocType::"Posted Credit Memo":
                        if FromRentalCrMemoHeader.Get(FromDocNo) then
                            FromRentalHeader.TransferFields(FromRentalCrMemoHeader);
                    FromDocType::"Arch. Contract":
                        if FromRentalHeaderArchive.Get(FromRentalHeaderArchive."Document Type"::Contract, FromDocNo, FromDocNoOccurrenceInteger, FromDocVersionNoInteger) then
                            FromRentalHeader.TransferFields(FromRentalHeaderArchive);
                    FromDocType::"Arch. Quote":
                        if FromRentalHeaderArchive.Get(FromRentalHeaderArchive."Document Type"::Quote, FromDocNo, FromDocNoOccurrenceInteger, FromDocVersionNoInteger) then
                            FromRentalHeader.TransferFields(FromRentalHeaderArchive);
                end;
                if FromRentalHeader."No." = '' then
                    FromDocNo := '';
            end;
            ValidateDocNo();

            OnAfterOpenPage();
        end;

        trigger OnQueryClosePage(CloseAction: Action): Boolean
        begin
            if CloseAction = ACTION::OK then
                if FromDocNo = '' then
                    Error(DocNoNotSerErr)
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    var
        ExactCostReversingMandatory: Boolean;
    begin
        OnBeforePreReport();

        RentalSetup.Get();

        OnPreReportOnBeforeCopyRentalDocMgtSetProperties(FromDocType, FromDocNo, RentalHeader, ExactCostReversingMandatory);
        CopyRentalDocMgt.SetProperties(
          IncludeHeader, RecalculateLinesBoolean, false, false, false, ExactCostReversingMandatory, false);
        CopyRentalDocMgt.SetArchDocVal(FromDocNoOccurrenceInteger, FromDocVersionNoInteger);

        OnPreReportOnBeforeCopyRentalDoc(CopyRentalDocMgt, FromDocType.AsInteger(), FromDocNo, RentalHeader);

        CopyRentalDocMgt.CopyRentalDoc(FromDocType, FromDocNo, RentalHeader);
    end;

    var
        RentalHeader: Record "TWE Rental Header";
        FromRentalHeader: Record "TWE Rental Header";
        FromRentalShptHeader: Record "TWE Rental Shipment Header";
        FromRentalInvHeader: Record "TWE Rental Invoice Header";
        FromRentalCrMemoHeader: Record "TWE Rental Cr.Memo Header";
        FromRentalHeaderArchive: Record "TWE Rental Header Archive";
        RentalSetup: Record "TWE Rental Setup";
        CopyRentalDocMgt: Codeunit "TWE Copy Rental Document Mgt.";
        FromDocType: Enum "TWE Rental Document Type From";
        FromDocNo: Code[20];
        IncludeHeader: Boolean;
        RecalculateLinesBoolean: Boolean;
        Text000Lbl: Label 'The price information may not be reversed correctly, if you copy a %1. If possible copy a %2 instead or use %3 functionality.', Comment = '%1 = FromDocType,%2 =  FromDocType,%3 = Text001Lbl)';
        Text001Lbl: Label 'Undo Shipment';
        Text003Lbl: Label 'Quote,Blanket Order,Order,Invoice,Return Order,Credit Memo,Posted Shipment,Posted Invoice,Posted Return Receipt,Posted Credit Memo';
        FromDocNoOccurrenceInteger: Integer;
        FromDocVersionNoInteger: Integer;
        DocNoNotSerErr: Label 'Select a document number to continue, or choose Cancel to close the page.';

    /// <summary>
    /// SetRentalHeader.
    /// </summary>
    /// <param name="NewRentalHeader">VAR Record "TWE Rental Header".</param>
    procedure SetRentalHeader(var NewRentalHeader: Record "TWE Rental Header")
    begin
        NewRentalHeader.TestField("No.");
        RentalHeader := NewRentalHeader;
    end;

    local procedure ValidateDocNo()
    var
        FromDocType2: Enum "TWE Rental Document Type From";
    begin
        if FromDocNo = '' then begin
            FromRentalHeader.Init();
            FromDocNoOccurrenceInteger := 0;
            FromDocVersionNoInteger := 0;
        end else
            if FromRentalHeader."No." = '' then begin
                FromRentalHeader.Init();
                case FromDocType of
                    FromDocType::Quote,
                    FromDocType::Contract,
                    FromDocType::Invoice,
                    FromDocType::"Credit Memo",
                    FromDocType::"Return Shipment":
                        FromRentalHeader.Get(CopyRentalDocMgt.GetRentalDocumentType(FromDocType), FromDocNo);
                    FromDocType::"Posted Shipment":
                        begin
                            FromRentalShptHeader.Get(FromDocNo);
                            FromRentalHeader.TransferFields(FromRentalShptHeader);
                            if RentalHeader."Document Type" in
                               [RentalHeader."Document Type"::"Return Shipment", RentalHeader."Document Type"::"Credit Memo"]
                            then begin
                                FromDocType2 := FromDocType2::"Posted Invoice";
                                Message(
                                    Text000Lbl,
                                    SelectStr(1 + FromDocType.AsInteger(), Text003Lbl),
                                    SelectStr(1 + FromDocType2.AsInteger(), Text003Lbl), Text001Lbl);
                            end;
                        end;
                    FromDocType::"Posted Invoice":
                        begin
                            FromRentalInvHeader.Get(FromDocNo);
                            FromRentalHeader.TransferFields(FromRentalInvHeader);
                        end;
                    FromDocType::"Posted Credit Memo":
                        begin
                            FromRentalCrMemoHeader.Get(FromDocNo);
                            FromRentalHeader.TransferFields(FromRentalCrMemoHeader);
                        end;
                    FromDocType::"Arch. Quote",
                    FromDocType::"Arch. Contract":
                        begin
                            if not FromRentalHeaderArchive.Get(
                                 CopyRentalDocMgt.GetRentalDocumentType(FromDocType), FromDocNo, FromDocNoOccurrenceInteger, FromDocVersionNoInteger)
                            then begin
                                FromRentalHeaderArchive.SetRange("No.", FromDocNo);
                                if FromRentalHeaderArchive.FindLast() then begin
                                    FromDocNoOccurrenceInteger := FromRentalHeaderArchive."Doc. No. Occurrence";
                                    FromDocVersionNoInteger := FromRentalHeaderArchive."Version No.";
                                end;
                            end;
                            FromRentalHeader.TransferFields(FromRentalHeaderArchive);
                        end;
                end;
            end;
        FromRentalHeader."No." := '';

        IncludeHeader :=
          (FromDocType in [FromDocType::"Posted Invoice", FromDocType::"Posted Credit Memo"]) and
          ((FromDocType = FromDocType::"Posted Credit Memo") <>
           (RentalHeader."Document Type" in
            [RentalHeader."Document Type"::"Return Shipment", RentalHeader."Document Type"::"Credit Memo"])) and
          (RentalHeader."Bill-to Customer No." in [FromRentalHeader."Bill-to Customer No.", '']);

        OnBeforeValidateIncludeHeader(IncludeHeader);
        ValidateIncludeHeader();
        OnAfterValidateIncludeHeader(IncludeHeader, RecalculateLinesBoolean);
    end;

    local procedure LookupDocNo()
    begin
        OnBeforeLookupDocNo(RentalHeader);

        case FromDocType of
            FromDocType::Quote,
            FromDocType::Contract,
            FromDocType::Invoice,
            FromDocType::"Credit Memo",
            FromDocType::"Return Shipment":
                LookupRentalDoc();
            FromDocType::"Posted Shipment":
                LookupPostedShipment();
            FromDocType::"Posted Invoice":
                LookupPostedInvoice();
            FromDocType::"Posted Credit Memo":
                LookupPostedCrMemo();
            FromDocType::"Arch. Quote",
                    FromDocType::"Arch. Contract":
                LookupRentalArchive();
        end;

        ValidateDocNo();
    end;

    local procedure LookupRentalDoc()
    begin
        OnBeforeLookupRentalDoc(FromRentalHeader, RentalHeader);

        FromRentalHeader.FilterGroup := 0;
        FromRentalHeader.SetRange("Document Type", CopyRentalDocMgt.GetRentalDocumentType(FromDocType));
        if RentalHeader."Document Type" = CopyRentalDocMgt.GetRentalDocumentType(FromDocType) then
            FromRentalHeader.SetFilter("No.", '<>%1', RentalHeader."No.");
        FromRentalHeader.FilterGroup := 2;
        FromRentalHeader."Document Type" := CopyRentalDocMgt.GetRentalDocumentType(FromDocType);
        FromRentalHeader."No." := FromDocNo;
        if (FromDocNo = '') and (RentalHeader."Rented-to Customer No." <> '') then
            if FromRentalHeader.SetCurrentKey("Document Type", "Rented-to Customer No.") then begin
                FromRentalHeader."Rented-to Customer No." := RentalHeader."Rented-to Customer No.";
                if FromRentalHeader.Find('=><') then;
            end;
        if PAGE.RunModal(0, FromRentalHeader) = ACTION::LookupOK then
            FromDocNo := FromRentalHeader."No.";
    end;

    local procedure LookupRentalArchive()
    begin
        FromRentalHeaderArchive.Reset();
        OnLookupRentalArchiveOnBeforeSetFilters(FromRentalHeaderArchive, RentalHeader);
        FromRentalHeaderArchive.FilterGroup := 0;
        FromRentalHeaderArchive.SetRange("Document Type", CopyRentalDocMgt.GetRentalDocumentType(FromDocType));
        FromRentalHeaderArchive.FilterGroup := 2;
        FromRentalHeaderArchive."Document Type" := CopyRentalDocMgt.GetRentalDocumentType(FromDocType);
        FromRentalHeaderArchive."No." := FromDocNo;
        FromRentalHeaderArchive."Doc. No. Occurrence" := FromDocNoOccurrenceInteger;
        FromRentalHeaderArchive."Version No." := FromDocVersionNoInteger;
        if (FromDocNo = '') and (RentalHeader."Rented-to Customer No." <> '') then
            if FromRentalHeaderArchive.SetCurrentKey("Document Type", "Rented-to Customer No.") then begin
                FromRentalHeaderArchive."Rented-to Customer No." := RentalHeader."Rented-to Customer No.";
                if FromRentalHeaderArchive.Find('=><') then;
            end;
        if PAGE.RunModal(0, FromRentalHeaderArchive) = ACTION::LookupOK then begin
            FromDocNo := FromRentalHeaderArchive."No.";
            FromDocNoOccurrenceInteger := FromRentalHeaderArchive."Doc. No. Occurrence";
            FromDocVersionNoInteger := FromRentalHeaderArchive."Version No.";
            RequestOptionsPage.Update(false);
        end;
    end;

    local procedure LookupPostedShipment()
    begin
        OnBeforeLookupPostedShipment(FromRentalShptHeader, RentalHeader);

        FromRentalShptHeader."No." := FromDocNo;
        if (FromDocNo = '') and (RentalHeader."Rented-to Customer No." <> '') then
            if FromRentalShptHeader.SetCurrentKey("Rented-to Customer No.") then begin
                FromRentalShptHeader."Rented-to Customer No." := RentalHeader."Rented-to Customer No.";
                if FromRentalShptHeader.Find('=><') then;
            end;
        if PAGE.RunModal(0, FromRentalShptHeader) = ACTION::LookupOK then
            FromDocNo := FromRentalShptHeader."No.";
    end;

    local procedure LookupPostedInvoice()
    begin
        OnBeforeLookupPostedInvoice(FromRentalInvHeader, RentalHeader);

        FromRentalInvHeader."No." := FromDocNo;
        if (FromDocNo = '') and (RentalHeader."Rented-to Customer No." <> '') then
            if FromRentalInvHeader.SetCurrentKey("Rented-to Customer No.") then begin
                FromRentalInvHeader."Rented-to Customer No." := RentalHeader."Rented-to Customer No.";
                if FromRentalInvHeader.Find('=><') then;
            end;
        FromRentalInvHeader.FilterGroup(2);
        FromRentalInvHeader.SetRange("Prepayment Invoice", false);
        FromRentalInvHeader.FilterGroup(0);
        if PAGE.RunModal(0, FromRentalInvHeader) = ACTION::LookupOK then
            FromDocNo := FromRentalInvHeader."No.";
    end;

    local procedure LookupPostedCrMemo()
    begin
        OnBeforeLookupPostedCrMemo(FromRentalCrMemoHeader, RentalHeader);

        FromRentalCrMemoHeader."No." := FromDocNo;
        if (FromDocNo = '') and (RentalHeader."Rented-to Customer No." <> '') then
            if FromRentalCrMemoHeader.SetCurrentKey("Rented-to Customer No.") then begin
                FromRentalCrMemoHeader."Rented-to Customer No." := RentalHeader."Rented-to Customer No.";
                if FromRentalCrMemoHeader.Find('=><') then;
            end;
        FromRentalCrMemoHeader.FilterGroup(2);
        FromRentalCrMemoHeader.SetRange("Prepayment Credit Memo", false);
        FromRentalCrMemoHeader.FilterGroup(0);
        if PAGE.RunModal(0, FromRentalCrMemoHeader) = ACTION::LookupOK then
            FromDocNo := FromRentalCrMemoHeader."No.";
    end;

    local procedure ValidateIncludeHeader()
    begin
        RecalculateLinesBoolean :=
          (FromDocType in [FromDocType::"Posted Shipment"]) or not IncludeHeader;
    end;

    /// <summary>
    /// SetParameters.
    /// </summary>
    /// <param name="NewFromDocType">Enum "TWE Rental Document Type From".</param>
    /// <param name="NewFromDocNo">Code[20].</param>
    /// <param name="NewIncludeHeader">Boolean.</param>
    /// <param name="NewRecalcLines">Boolean.</param>
    procedure SetParameters(NewFromDocType: Enum "TWE Rental Document Type From"; NewFromDocNo: Code[20]; NewIncludeHeader: Boolean; NewRecalcLines: Boolean)
    begin
        FromDocType := NewFromDocType;
        FromDocNo := NewFromDocNo;
        IncludeHeader := NewIncludeHeader;
        RecalculateLinesBoolean := NewRecalcLines;
    end;

    /// <summary>
    /// InitializeRequest.
    /// </summary>
    /// <param name="NewDocType">Option.</param>
    /// <param name="NewDocNo">Code[20].</param>
    /// <param name="NewIncludeHeader">Boolean.</param>
    /// <param name="NewRecalcLines">Boolean.</param>
    procedure InitializeRequest(NewDocType: Option; NewDocNo: Code[20]; NewIncludeHeader: Boolean; NewRecalcLines: Boolean)
    begin
        SetParameters("TWE Rental Document Type From".FromInteger(NewDocType), NewDocNo, NewIncludeHeader, NewRecalcLines);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOpenPage()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateIncludeHeader(var IncludeHeader: Boolean; var RecalculateLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupDocNo(var RentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupRentalDoc(var FromRentalHeader: Record "TWE Rental Header"; var RentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupPostedCrMemo(var FromRentalCrMemoHeader: Record "TWE Rental Cr.Memo Header"; var RentalHeader: Record "TWE Rental Header");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupPostedInvoice(var FromRentalInvHeader: Record "TWE Rental Invoice Header"; var RentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupPostedShipment(var FromRentalShptHeader: Record "TWE Rental Shipment Header"; var RentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePreReport()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateIncludeHeader(var DoIncludeHeader: Boolean)
    begin
    end;


    [IntegrationEvent(false, false)]
    local procedure OnLookupRentalArchiveOnBeforeSetFilters(var FromRentalHeaderArchive: Record "TWE Rental Header Archive"; var RentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPreReportOnBeforeCopyRentalDoc(var CopyRentalDocumentMgt: Codeunit "TWE Copy Rental Document Mgt."; DocType: Integer; DocNo: Code[20]; RentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPreReportOnBeforeCopyRentalDocMgtSetProperties(FromDocType: Enum "TWE Rental Document Type From"; FromDocNo: Code[20]; RentalHeader: Record "TWE Rental Header"; var ExactCostReversingMandatory: Boolean)
    begin
    end;
}

