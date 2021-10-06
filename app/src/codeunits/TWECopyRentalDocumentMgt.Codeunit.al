/// <summary>
/// Codeunit TWE Copy Rental Document Mgt. (ID 50006).
/// </summary>
codeunit 50006 "TWE Copy Rental Document Mgt."
{

    trigger OnRun()
    begin
    end;

    var
        Currency: Record Currency;
        MainRentalItem: Record "TWE Main Rental Item";
        TempRentalInvLine: Record "TWE Rental Invoice Line" temporary;
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        GLSetup: Record "General Ledger Setup";
        TranslationHelper: Codeunit "Translation Helper";
        RentalCustCheckCreditLimit: Codeunit "TWE Rent. Cust-Check Cr. Limit";
        RentalTransferExtendedText: Codeunit "TWE Rental Trans. Ext. Text";
        TransferOldExtLines: Codeunit "Transfer Old Ext. Text Lines";
        ItemTrackingDocMgt: Codeunit "Item Tracking Doc. Management";
        UOMMgt: Codeunit "Unit of Measure Management";
        ErrorMessageMgt: Codeunit "Error Message Management";
        Window: Dialog;
        WindowUpdateDateTime: DateTime;
        InsertCancellationLine: Boolean;
        ServDocType: Option Quote,Contract;
        IncludeHeader: Boolean;
        RecalculateLines: Boolean;
        MoveNegLines: Boolean;
        Text008Lbl: Label 'There are no negative rental lines to move.';
        //Text009Lbl: Label 'NOTE: A Payment Discount was Received by %1 %2.';
        CreateToHeader: Boolean;
        HideDialog: Boolean;
        Text013Lbl: Label 'Shipment No.,Invoice No.,Return Receipt No.,Credit Memo No.';
        Text015Lbl: Label '%1 %2:', Comment = '%1 Old Document Type, %2 Old Document No.';
        Text016Lbl: Label 'Inv. No. ,Shpt. No. ,Cr. Memo No. ,Rtrn. Rcpt. No. ';
        Text018Lbl: Label '%1 - %2:', Comment = '%1 Old Document No., %2 Old Document No.';
        Text019Lbl: Label 'Exact Cost Reversing Link has not been created for all copied document lines.';
        Text022Lbl: Label 'Copying document lines...\';
        Text023Lbl: Label 'Processing source lines      #1######\', Comment = '#1 Counter';
        Text024Lbl: Label 'Creating new lines           #2######', Comment = '#2 Counter';
        Text000Lbl: Label 'Please enter a Document No.';
        Text001Lbl: Label '%1 %2 cannot be copied onto itself.', Comment = '%1 - To Rental Header Document Type,%2 - To Rental Header Document No.';
        DeleteLinesQst: Label 'The existing lines for %1 %2 will be deleted.\\Do you want to continue?', Comment = '%1=Document type, e.g. Invoice. %2=Document No., e.g. 001';
        Text006Lbl: Label 'NOTE: A Payment Discount was Granted by %1 %2.', Comment = '%1 - Option Caption, %2 Document No.';
        Text007Lbl: Label 'Quote,Blanket Order,Order,Invoice,Credit Memo,Posted Shipment,Posted Invoice,Posted Credit Memo,Posted Return Receipt';
        ExactCostRevMandatory: Boolean;
        ReappDone: Boolean;
        Text025Lbl: Label 'For one or more return document lines, you chose to return the original quantity, which is already fully applied. Therefore, when you post the return document, the program will reapply relevant entries. Beware that this may change the cost of existing entries. To avoid this, you must delete the affected return document lines before posting.';
        SkippedLine: Boolean;
        Text029Lbl: Label 'One or more return document lines were not inserted or they contain only the remaining quantity of the original document line. This is because quantities on the posted document line are already fully or partially applied. If you want to reverse the full quantity, you must select Return Original Quantity before getting the posted document lines.';
        Text030Lbl: Label 'One or more return document lines were not copied. This is because quantities on the posted document line are already fully or partially applied, so the Exact Cost Reversing link could not be created.';
        Text031Lbl: Label 'Return document line contains only the original document line quantity, that is not already manually applied.';
        SomeAreFixed: Boolean;
        FromDocOccurrenceNo: Integer;
        FromDocVersionNo: Integer;
        SkipCopyFromDescription: Boolean;
        SkipTestCreditLimit: Boolean;
        WarningDone: Boolean;
        DiffPostDateOrderQst: Label 'The Posting Date of the copied document is different from the Posting Date of the original document. The original document already has a Posting No. based on a number series with date order. When you post the copied document, you may have the wrong date order in the posted documents.\Do you want to continue?';
        CrMemoCancellationMsg: Label 'Cancellation of credit memo %1.', Comment = '%1 = Document No.';
        CopyJobData: Boolean;
        SkipWarningNotification: Boolean;
        IsBlockedErr: Label '%1 %2 is blocked.', Comment = '%1 - type of entity, e.g. Item; %2 - entity''s No.';
        IsRentalBlockedItemErr: Label 'You cannot sell item %1 because the Rental Blocked check box is selected on the item card.', Comment = '%1 - Item No.';
        IsPurchBlockedItemErr: Label 'You cannot purchase item %1 because the Purchasing Blocked check box is selected on the item card.', Comment = '%1 - Item No.';
        DirectPostingErr: Label 'G/L account %1 does not allow direct posting.', Comment = '%1 - g/l account no.';
        RentalErrorContextMsg: Label 'Copying sales document %1', Comment = '%1 - document no.';

    /// <summary>
    /// SetProperties.
    /// </summary>
    /// <param name="NewIncludeHeader">Boolean.</param>
    /// <param name="NewRecalculateLines">Boolean.</param>
    /// <param name="NewMoveNegLines">Boolean.</param>
    /// <param name="NewCreateToHeader">Boolean.</param>
    /// <param name="NewHideDialog">Boolean.</param>
    /// <param name="NewExactCostRevMandatory">Boolean.</param>
    /// <param name="NewApplyFully">Boolean.</param>
    procedure SetProperties(NewIncludeHeader: Boolean; NewRecalculateLines: Boolean; NewMoveNegLines: Boolean; NewCreateToHeader: Boolean; NewHideDialog: Boolean; NewExactCostRevMandatory: Boolean; NewApplyFully: Boolean)
    begin
        IncludeHeader := NewIncludeHeader;
        RecalculateLines := NewRecalculateLines;
        MoveNegLines := NewMoveNegLines;
        CreateToHeader := NewCreateToHeader;
        HideDialog := NewHideDialog;
        ExactCostRevMandatory := NewExactCostRevMandatory;
        ReappDone := false;
        SkippedLine := false;
        SomeAreFixed := false;
        SkipCopyFromDescription := false;
        SkipTestCreditLimit := false;
    end;

    /// <summary>
    /// SetPropertiesForCreditMemoCorrection.
    /// </summary>
    procedure SetPropertiesForCreditMemoCorrection()
    begin
        SetProperties(true, false, false, false, true, true, false);
    end;

    /// <summary>
    /// SetPropertiesForInvoiceCorrection.
    /// </summary>
    /// <param name="NewSkipCopyFromDescription">Boolean.</param>
    procedure SetPropertiesForInvoiceCorrection(NewSkipCopyFromDescription: Boolean)
    begin
        SetProperties(true, false, false, false, true, false, false);
        SkipTestCreditLimit := true;
        SkipCopyFromDescription := NewSkipCopyFromDescription;
    end;

    /// <summary>
    /// GetRentalDocumentType.
    /// </summary>
    /// <param name="FromDocType">Enum "TWE Rental Document Type From".</param>
    /// <returns>Return value of type Enum "TWE Rental Document Type".</returns>
    procedure GetRentalDocumentType(FromDocType: Enum "TWE Rental Document Type From"): Enum "TWE Rental Document Type"
    begin
        case FromDocType of
            FromDocType::Quote:
                exit("TWE Rental Document Type"::Quote);
            FromDocType::Contract:
                exit("TWE Rental Document Type"::Contract);
            FromDocType::Invoice:
                exit("TWE Rental Document Type"::Invoice);
            FromDocType::"Return Shipment":
                exit("TWE Rental Document Type"::"Return Shipment");
            FromDocType::"Credit Memo":
                exit("TWE Rental Document Type"::"Credit Memo");
            FromDocType::"Arch. Quote":
                exit("TWE Rental Document Type"::Quote);
            FromDocType::"Arch. Contract":
                exit("TWE Rental Document Type"::Contract);
        end;
    end;

    /// <summary>
    /// CopyRentalDocForInvoiceCancelling.
    /// </summary>
    /// <param name="FromDocNo">Code[20].</param>
    /// <param name="ToRentalHeader">VAR Record "TWE Rental Header".</param>
    procedure CopyRentalDocForInvoiceCancelling(FromDocNo: Code[20]; var ToRentalHeader: Record "TWE Rental Header")
    begin
        CopyJobData := true;
        SkipWarningNotification := true;
        OnBeforeCopyRentalDocForInvoiceCancelling(ToRentalHeader, FromDocNo);

        CopyRentalDoc("TWE Rental Document Type From"::"Posted Invoice", FromDocNo, ToRentalHeader);
    end;

    /// <summary>
    /// CopyRentalDocForCrMemoCancelling.
    /// </summary>
    /// <param name="FromDocNo">Code[20].</param>
    /// <param name="ToRentalHeader">VAR Record "TWE Rental Header".</param>
    procedure CopyRentalDocForCrMemoCancelling(FromDocNo: Code[20]; var ToRentalHeader: Record "TWE Rental Header")
    begin
        SkipWarningNotification := true;
        InsertCancellationLine := true;
        OnBeforeCopyRentalDocForCrMemoCancelling(ToRentalHeader, FromDocNo, CopyJobData);

        CopyRentalDoc("TWE Rental Document Type From"::"Posted Credit Memo", FromDocNo, ToRentalHeader);
        InsertCancellationLine := false;
    end;

    /// <summary>
    /// CopyRentalDoc.
    /// </summary>
    /// <param name="FromDocType">Enum "TWE Rental Document Type From".</param>
    /// <param name="FromDocNo">Code[20].</param>
    /// <param name="ToRentalHeader">VAR Record "TWE Rental Header".</param>
    procedure CopyRentalDoc(FromDocType: Enum "TWE Rental Document Type From"; FromDocNo: Code[20]; var ToRentalHeader: Record "TWE Rental Header")
    var
        ToRentalLine: Record "TWE Rental Line";
        FromRentalHeader: Record "TWE Rental Header";
        FromRentalShptHeader: Record "TWE Rental Shipment Header";
        FromRentalInvHeader: Record "TWE Rental Invoice Header";
        FromReturnRcptHeader: Record "Return Receipt Header";
        FromRentalCrMemoHeader: Record "TWE Rental Cr.Memo Header";
        FromRentalHeaderArchive: Record "TWE Rental Header Archive";
        ReleaseRentalDocument: Codeunit "TWE Release Rental Document";
        ConfirmManagement: Codeunit "Confirm Management";
        ErrorContextElement: Codeunit "Error Context Element";
        ErrorMessageHandler: Codeunit "Error Message Handler";
        NextLineNo: Integer;
        LinesNotCopied: Integer;
        MissingExCostRevLink: Boolean;
        ReleaseDocument: Boolean;
        IsHandled: Boolean;
    begin
        if not CreateToHeader then begin
            ToRentalHeader.TestField(Status, ToRentalHeader.Status::Open);
            if FromDocNo = '' then
                Error(Text000Lbl);
            ToRentalHeader.Find();
        end;

        OnBeforeCopyRentalDocument(FromDocType.AsInteger(), FromDocNo, ToRentalHeader);

        TransferOldExtLines.ClearLineNumbers();

        if not InitAndCheckRentalDocuments(
             FromDocType.AsInteger(), FromDocNo, FromRentalHeader, ToRentalHeader, ToRentalLine,
             FromRentalShptHeader, FromRentalInvHeader, FromReturnRcptHeader, FromRentalCrMemoHeader,
             FromRentalHeaderArchive)
        then
            exit;

        ToRentalLine.LockTable();

        ToRentalLine.SetRange("Document Type", ToRentalHeader."Document Type");
        if CreateToHeader then begin
            OnCopyRentalDocOnBeforeToRentalHeaderInsert(ToRentalHeader, FromRentalHeader, MoveNegLines);
            ToRentalHeader.Insert(true);
            ToRentalLine.SetRange("Document No.", ToRentalHeader."No.");
        end else begin
            ToRentalLine.SetRange("Document No.", ToRentalHeader."No.");
            if IncludeHeader then
                if not ToRentalLine.IsEmpty then begin
                    Commit();
                    if not ConfirmManagement.GetResponseOrDefault(
                         StrSubstNo(DeleteLinesQst, ToRentalHeader."Document Type", ToRentalHeader."No."), true)
                    then
                        exit;
                    ToRentalLine.DeleteAll(true);
                end;
        end;

        if ToRentalLine.FindLast() then
            NextLineNo := ToRentalLine."Line No."
        else
            NextLineNo := 0;

        if IncludeHeader then
            CopyRentalDocUpdateHeader(
                FromDocType, FromDocNo, ToRentalHeader, FromRentalHeader,
                FromRentalShptHeader, FromRentalInvHeader, FromReturnRcptHeader, FromRentalCrMemoHeader, FromRentalHeaderArchive, ReleaseDocument)
        else
            OnCopyRentalDocWithoutHeader(ToRentalHeader, FromDocType.AsInteger(), FromDocNo, FromDocOccurrenceNo, FromDocVersionNo);

        LinesNotCopied := 0;
        ErrorMessageMgt.Activate(ErrorMessageHandler);
        ErrorMessageMgt.PushContext(ErrorContextElement, ToRentalHeader.RecordId, 0, StrSubstNo(RentalErrorContextMsg, FromDocNo));

        IsHandled := false;
        OnCopyRentalDocOnBeforeCopyLines(FromRentalHeader, ToRentalHeader, IsHandled);
        if not IsHandled then
            case FromDocType of
                "TWE Rental Document Type From"::Quote,
                                                        "TWE Rental Document Type From"::Contract,
                                                        "TWE Rental Document Type From"::Invoice,
                                                        "TWE Rental Document Type From"::"Return Shipment",
                                                        "TWE Rental Document Type From"::"Credit Memo":
                    CopyRentalDocRentalLine(FromRentalHeader, ToRentalHeader, LinesNotCopied, NextLineNo);
                "TWE Rental Document Type From"::"Posted Shipment":
                    begin
                        FromRentalHeader.TransferFields(FromRentalShptHeader);
                        OnCopyRentalDocOnBeforeCopyRentalDocShptLine(FromRentalShptHeader, ToRentalHeader);
                        CopyRentalDocShptLine(FromRentalShptHeader, ToRentalHeader, LinesNotCopied, MissingExCostRevLink);
                    end;
                "TWE Rental Document Type From"::"Posted Invoice":
                    begin
                        FromRentalHeader.TransferFields(FromRentalInvHeader);
                        OnCopyRentalDocOnBeforeCopyRentalDocInvLine(FromRentalInvHeader, ToRentalHeader);
                        CopyRentalDocInvLine(FromRentalInvHeader, ToRentalHeader, LinesNotCopied, MissingExCostRevLink);
                    end;
                "TWE Rental Document Type From"::"Posted Credit Memo":
                    begin
                        FromRentalHeader.TransferFields(FromRentalCrMemoHeader);
                        OnCopyRentalDocOnBeforeCopyRentalDocCrMemoLine(FromRentalCrMemoHeader, ToRentalHeader);
                        CopyRentalDocCrMemoLine(FromRentalCrMemoHeader, ToRentalHeader, LinesNotCopied, MissingExCostRevLink);
                    end;
                "TWE Rental Document Type From"::"Arch. Quote",
                "TWE Rental Document Type From"::"Arch. Contract":
                    CopyRentalDocRentalLineArchive(FromRentalHeaderArchive, ToRentalHeader, LinesNotCopied, NextLineNo);
            end;

        OnCopyRentalDocOnBeforeUpdateRentalInvoiceDiscountValue(
          ToRentalHeader, FromDocType.AsInteger(), FromDocNo, FromDocOccurrenceNo, FromDocVersionNo, RecalculateLines);

        UpdateRentalInvoiceDiscountValue(ToRentalHeader);

        if MoveNegLines then begin
            OnBeforeDeleteNegRentalLines(FromDocType.AsInteger(), FromDocNo, ToRentalHeader);
            DeleteRentalLinesWithNegQty(FromRentalHeader, false);
        end;

        OnCopyRentalDocOnAfterCopyRentalDocLines(
          FromDocType.AsInteger(), FromDocNo, FromDocOccurrenceNo, FromDocVersionNo, FromRentalHeader, IncludeHeader, ToRentalHeader);

        if ReleaseDocument then begin
            ToRentalHeader.Status := ToRentalHeader.Status::Released;
            ReleaseRentalDocument.Reopen(ToRentalHeader);
        end else
            if (FromDocType in
                ["TWE Rental Document Type From"::Quote,
                 "TWE Rental Document Type From"::Contract,
                 "TWE Rental Document Type From"::Invoice,
                 "TWE Rental Document Type From"::"Return Shipment",
                 "TWE Rental Document Type From"::"Credit Memo"])
               and not IncludeHeader and not RecalculateLines
            then
                if FromRentalHeader.Status = FromRentalHeader.Status::Released then begin
                    ReleaseRentalDocument.Run(ToRentalHeader);
                    ReleaseRentalDocument.Reopen(ToRentalHeader);
                end;

        if ShowWarningNotification(ToRentalHeader, MissingExCostRevLink) then
            ErrorMessageHandler.NotifyAboutErrors();

        OnAfterCopyRentalDocument(
          FromDocType.AsInteger(), FromDocNo, ToRentalHeader, FromDocOccurrenceNo, FromDocVersionNo, IncludeHeader, RecalculateLines, MoveNegLines);
    end;

    local procedure CopyRentalDocRentalLine(FromRentalHeader: Record "TWE Rental Header"; var ToRentalHeader: Record "TWE Rental Header"; var LinesNotCopied: Integer; NextLineNo: Integer)
    var
        ToRentalLine: Record "TWE Rental Line";
        FromRentalLine: Record "TWE Rental Line";
    begin
        FromRentalLine.Reset();
        FromRentalLine.SetRange("Document Type", FromRentalHeader."Document Type");
        FromRentalLine.SetRange("Document No.", FromRentalHeader."No.");
        if MoveNegLines then
            FromRentalLine.SetFilter(Quantity, '<=0');
        OnCopyRentalDocRentalLineOnAfterSetFilters(FromRentalHeader, FromRentalLine, ToRentalHeader);
        if FromRentalLine.Find('-') then
            repeat
                if not ExtTxtAttachedToPosRentalLine(FromRentalHeader, MoveNegLines, FromRentalLine."Attached to Line No.") then begin
                    ToRentalLine."Document Type" := ToRentalHeader."Document Type";

                    if CopyRentalDocLine(
                             ToRentalHeader, ToRentalLine, FromRentalHeader, FromRentalLine, NextLineNo, LinesNotCopied, false,
                             "TWE Rental Document Type From".FromInteger("TWE Rental Document Type From"::"Posted Shipment".AsInteger()),
                              FromRentalLine."Line No.") then
                        OnAfterCopyRentalLineFromRentalDocRentalLine(
                          ToRentalHeader, ToRentalLine, FromRentalLine, IncludeHeader, RecalculateLines);
                end;
            until FromRentalLine.Next() = 0;
    end;

    local procedure CopyRentalDocShptLine(FromRentalShptHeader: Record "TWE Rental Shipment Header"; ToRentalHeader: Record "TWE Rental Header"; var LinesNotCopied: Integer; var MissingExCostRevLink: Boolean)
    var
        FromRentalShptLine: Record "TWE Rental Shipment Line";
    begin
        FromRentalShptLine.Reset();
        FromRentalShptLine.SetRange("Document No.", FromRentalShptHeader."No.");
        if MoveNegLines then
            FromRentalShptLine.SetFilter(Quantity, '<=0');
        OnCopyRentalDocShptLineOnAfterSetFilters(ToRentalHeader, FromRentalShptHeader, FromRentalShptLine);
        CopyRentalShptLinesToDoc(ToRentalHeader, FromRentalShptLine, LinesNotCopied, MissingExCostRevLink);
    end;

    local procedure CopyRentalDocInvLine(FromRentalInvHeader: Record "TWE Rental Invoice Header"; ToRentalHeader: Record "TWE Rental Header"; var LinesNotCopied: Integer; var MissingExCostRevLink: Boolean)
    var
        FromRentalInvLine: Record "TWE Rental Invoice Line";
    begin
        FromRentalInvHeader.Reset();
        FromRentalInvLine.SetRange("Document No.", FromRentalInvHeader."No.");
        if MoveNegLines then
            FromRentalInvLine.SetFilter(Quantity, '<=0');
        OnCopyRentalDocInvLineOnAfterSetFilters(ToRentalHeader, FromRentalInvHeader, FromRentalInvLine);
        CopyRentalInvLinesToDoc(ToRentalHeader, FromRentalInvLine, LinesNotCopied, MissingExCostRevLink);
    end;

    local procedure CopyRentalDocCrMemoLine(FromRentalCrMemoHeader: Record "TWE Rental Cr.Memo Header"; ToRentalHeader: Record "TWE Rental Header"; var LinesNotCopied: Integer; var MissingExCostRevLink: Boolean)
    var
        FromRentalCrMemoLine: Record "TWE Rental Cr.Memo Line";
    begin
        FromRentalCrMemoLine.Reset();
        FromRentalCrMemoLine.SetRange("Document No.", FromRentalCrMemoHeader."No.");
        if MoveNegLines then
            FromRentalCrMemoLine.SetFilter(Quantity, '<=0');
        OnCopyRentalDocCrMemoLineOnAfterSetFilters(ToRentalHeader, FromRentalCrMemoHeader, FromRentalCrMemoLine);
        CopyRentalCrMemoLinesToDoc(ToRentalHeader, FromRentalCrMemoLine, LinesNotCopied, MissingExCostRevLink);
    end;

    local procedure CopyRentalDocRentalLineArchive(FromRentalHeaderArchive: Record "TWE Rental Header Archive"; var ToRentalHeader: Record "TWE Rental Header"; var LinesNotCopied: Integer; NextLineNo: Integer)
    var
        ToRentalLine: Record "TWE Rental Line";
        FromRentalLineArchive: Record "TWE Rental Line Archive";
    begin
        FromRentalLineArchive.Reset();
        FromRentalLineArchive.SetRange("Document Type", FromRentalHeaderArchive."Document Type");
        FromRentalLineArchive.SetRange("Document No.", FromRentalHeaderArchive."No.");
        FromRentalLineArchive.SetRange("Doc. No. Occurrence", FromRentalHeaderArchive."Doc. No. Occurrence");
        FromRentalLineArchive.SetRange("Version No.", FromRentalHeaderArchive."Version No.");
        if MoveNegLines then
            FromRentalLineArchive.SetFilter(Quantity, '<=0');
        OnCopyRentalDocRentalLineArchiveOnAfterSetFilters(FromRentalHeaderArchive, FromRentalLineArchive, ToRentalHeader);
        if FromRentalLineArchive.Find('-') then
            repeat
                if CopyArchRentalLine(
                     ToRentalHeader, ToRentalLine, FromRentalHeaderArchive, FromRentalLineArchive, NextLineNo, LinesNotCopied, false)
                then begin
                    CopyFromArchRentalDocDimToLine(ToRentalLine, FromRentalLineArchive);

                    OnAfterCopyArchRentalLine(ToRentalHeader, ToRentalLine, FromRentalLineArchive, IncludeHeader, RecalculateLines);
                end;
            until FromRentalLineArchive.Next() = 0;
    end;

    local procedure CopyRentalDocUpdateHeader(FromDocType: Enum "TWE Rental Document Type From"; FromDocNo: Code[20]; var ToRentalHeader: Record "TWE Rental Header"; FromRentalHeader: Record "TWE Rental Header"; FromRentalShptHeader: Record "TWE Rental Shipment Header"; FromRentalInvHeader: Record "TWE Rental Invoice Header"; FromReturnRcptHeader: Record "Return Receipt Header"; FromRentalCrMemoHeader: Record "TWE Rental Cr.Memo Header"; FromRentalHeaderArchive: Record "TWE Rental Header Archive"; var ReleaseDocument: Boolean);
    var
        OldRentalHeader: Record "TWE Rental Header";
    begin
        CheckCustomer(FromRentalHeader, ToRentalHeader);
        OldRentalHeader := ToRentalHeader;
        OnBeforeCopyRentalHeaderDone(ToRentalHeader, FromRentalHeader);
        case FromDocType of
            "TWE Rental Document Type From"::Quote,
            "TWE Rental Document Type From"::Contract,
            "TWE Rental Document Type From"::Invoice,
            "TWE Rental Document Type From"::"Return Shipment",
            "TWE Rental Document Type From"::"Credit Memo":
                CopyRentalHeaderFromRentalHeader(FromDocType, FromRentalHeader, OldRentalHeader, ToRentalHeader);
            "TWE Rental Document Type From"::"Posted Shipment":
                CopyRentalHeaderFromPostedShipment(FromRentalShptHeader, ToRentalHeader, OldRentalHeader);
            /*                                     "TWE Rental Document Type From"::"Posted Return Shipment":
                                CopyRentalHeaderFromPostedShipment(FromRentalShptHeader, ToRentalHeader, OldRentalHeader); */
            "TWE Rental Document Type From"::"Posted Invoice":
                CopyRentalHeaderFromPostedInvoice(FromRentalInvHeader, ToRentalHeader, OldRentalHeader);
            "TWE Rental Document Type From"::"Posted Credit Memo":
                TransferFieldsFromCrMemoToInv(ToRentalHeader, FromRentalCrMemoHeader);
            "TWE Rental Document Type From"::"Arch. Quote",
            "TWE Rental Document Type From"::"Arch. Contract":
                CopyRentalHeaderFromRentalHeaderArchive(FromRentalHeaderArchive, ToRentalHeader, OldRentalHeader);
        end;
        OnAfterCopyRentalHeaderDone(
            ToRentalHeader, OldRentalHeader, FromRentalHeader, FromRentalShptHeader, FromRentalInvHeader,
            FromReturnRcptHeader, FromRentalCrMemoHeader, FromRentalHeaderArchive);

        ToRentalHeader.Invoice := false;
        ToRentalHeader.Ship := false;
        if ToRentalHeader.Status = ToRentalHeader.Status::Released then begin
            ToRentalHeader.Status := ToRentalHeader.Status::Open;
            ReleaseDocument := true;
        end;
        if MoveNegLines or IncludeHeader then
            ToRentalHeader.Validate("Location Code");
        CopyShiptoCodeFromInvToCrMemo(ToRentalHeader, FromRentalInvHeader, FromDocType);
        CopyFieldsFromOldRentalHeader(ToRentalHeader, OldRentalHeader);
        OnAfterCopyFieldsFromOldRentalHeader(ToRentalHeader, OldRentalHeader, MoveNegLines, IncludeHeader);
        if RecalculateLines then
            ToRentalHeader.CreateDim(
                DATABASE::"Responsibility Center", ToRentalHeader."Responsibility Center",
                DATABASE::Customer, ToRentalHeader."Bill-to Customer No.",
                DATABASE::"Salesperson/Purchaser", ToRentalHeader."Salesperson Code",
                DATABASE::Campaign, ToRentalHeader."Campaign No.",
                DATABASE::"Customer Templ.", ToRentalHeader."Bill-to Customer Template Code");
        ToRentalHeader."No. Printed" := 0;
        ToRentalHeader."Applies-to Doc. Type" := ToRentalHeader."Applies-to Doc. Type"::" ";
        ToRentalHeader."Applies-to Doc. No." := '';
        ToRentalHeader."Applies-to ID" := '';
        ToRentalHeader."Opportunity No." := '';
        ToRentalHeader."Quote No." := '';
        OnCopyRentalDocUpdateHeaderOnBeforeUpdateCustLedgerEntry(ToRentalHeader, FromDocType.AsInteger(), FromDocNo);

        if ((FromDocType = "TWE Rental Document Type From"::"Posted Invoice") and
            (ToRentalHeader."Document Type" in [ToRentalHeader."Document Type"::"Credit Memo"])) or
            ((FromDocType = "TWE Rental Document Type From"::"Posted Credit Memo") and
            not (ToRentalHeader."Document Type" in [ToRentalHeader."Document Type"::"Credit Memo"]))
        then
            UpdateCustLedgerEntry(ToRentalHeader, FromDocType, FromDocNo);

        HandleZeroAmountPostedInvoices(FromRentalInvHeader, ToRentalHeader, FromDocType, FromDocNo);

        ToRentalHeader.Correction := false;
        if ToRentalHeader."Document Type" in [ToRentalHeader."Document Type"::"Credit Memo"] then
            UpdateRentalCreditMemoHeader(ToRentalHeader);

        OnBeforeModifyRentalHeader(ToRentalHeader, FromDocType.AsInteger(), FromDocNo, IncludeHeader, FromDocOccurrenceNo, FromDocVersionNo, RecalculateLines);

        if CreateToHeader then begin
            ToRentalHeader.Validate("Payment Terms Code");
            ToRentalHeader.Modify(true);
        end else
            ToRentalHeader.Modify();
        OnCopyRentalDocWithHeader(FromDocType.AsInteger(), FromDocNo, ToRentalHeader, FromDocOccurrenceNo, FromDocVersionNo);
    end;

    local procedure CopyRentalHeaderFromRentalHeader(FromDocType: Enum "TWE Rental Document Type From"; FromRentalHeader: Record "TWE Rental Header"; OldRentalHeader: Record "TWE Rental Header"; var ToRentalHeader: Record "TWE Rental Header")
    begin
        FromRentalHeader.CalcFields("Work Description");
        ToRentalHeader.TransferFields(FromRentalHeader, false);
        UpdateRentalHeaderWhenCopyFromRentalHeader(ToRentalHeader, OldRentalHeader, FromDocType);
        OnAfterCopyRentalHeader(ToRentalHeader, OldRentalHeader, FromRentalHeader);
    end;

    local procedure CopyRentalHeaderFromPostedShipment(FromRentalShptHeader: Record "TWE Rental Shipment Header"; var ToRentalHeader: Record "TWE Rental Header"; var OldRentalHeader: Record "TWE Rental Header")
    begin
        ToRentalHeader.Validate("Rented-to Customer No.", FromRentalShptHeader."Rented-to Customer No.");
        OnCopyRentalDocOnBeforeTransferPostedShipmentFields(ToRentalHeader, FromRentalShptHeader);
        ToRentalHeader.TransferFields(FromRentalShptHeader, false);
        OnAfterCopyPostedShipment(ToRentalHeader, OldRentalHeader, FromRentalShptHeader);
    end;

    local procedure CopyRentalHeaderFromPostedInvoice(FromRentalInvHeader: Record "TWE Rental Invoice Header"; var ToRentalHeader: Record "TWE Rental Header"; var OldRentalHeader: Record "TWE Rental Header")
    begin
        FromRentalInvHeader.CalcFields("Work Description");
        ToRentalHeader.Validate("Rented-to Customer No.", FromRentalInvHeader."Rented-to Customer No.");
        OnCopyRentalDocOnBeforeTransferPostedInvoiceFields(ToRentalHeader, FromRentalInvHeader, CopyJobData);
        ToRentalHeader.TransferFields(FromRentalInvHeader, false);
        OnCopyRentalDocOnAfterTransferPostedInvoiceFields(ToRentalHeader, FromRentalInvHeader, OldRentalHeader);
    end;

    local procedure CopyRentalHeaderFromRentalHeaderArchive(FromRentalHeaderArchive: Record "TWE Rental Header Archive"; var ToRentalHeader: Record "TWE Rental Header"; var OldRentalHeader: Record "TWE Rental Header")
    begin
        ToRentalHeader.Validate("Rented-to Customer No.", FromRentalHeaderArchive."Rented-to Customer No.");
        ToRentalHeader.TransferFields(FromRentalHeaderArchive, false);
        OnCopyRentalDocOnAfterTransferArchRentalHeaderFields(ToRentalHeader, FromRentalHeaderArchive);
        UpdateRentalHeaderWhenCopyFromRentalHeaderArchive(ToRentalHeader);
        CopyFromArchRentalDocDimToHdr(ToRentalHeader, FromRentalHeaderArchive);
        OnAfterCopyRentalHeaderArchive(ToRentalHeader, OldRentalHeader, FromRentalHeaderArchive)
    end;

    procedure CheckCustomer(var FromRentalHeader: Record "TWE Rental Header"; var ToRentalHeader: Record "TWE Rental Header")
    var
        Cust: Record Customer;
    begin
        if Cust.Get(FromRentalHeader."Rented-to Customer No.") then
            Cust.CheckBlockedCustOnDocs(Cust, ToRentalHeader."Document Type", false, false);
        if Cust.Get(FromRentalHeader."Bill-to Customer No.") then
            Cust.CheckBlockedCustOnDocs(Cust, ToRentalHeader."Document Type", false, false);
    end;

    local procedure HandleZeroAmountPostedInvoices(var FromRentalInvHeader: Record "TWE Rental Invoice Header"; var ToRentalHeader: Record "TWE Rental Header"; FromDocType: Enum "TWE Rental Document Type From"; FromDocNo: Code[20])
    begin
        FromRentalInvHeader.CalcFields(Amount);
        if (ToRentalHeader."Applies-to Doc. Type" = ToRentalHeader."Applies-to Doc. Type"::" ") and (ToRentalHeader."Applies-to Doc. No." = '') and
           (FromDocType = "TWE Rental Document Type From"::"Posted Invoice") and (FromRentalInvHeader.Amount = 0)
        then begin
            ToRentalHeader."Applies-to Doc. Type" := ToRentalHeader."Applies-to Doc. Type"::Invoice;
            ToRentalHeader."Applies-to Doc. No." := FromDocNo;
        end;
    end;

    procedure ShowRentalDoc(ToRentalHeader: Record "TWE Rental Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowRentalDoc(ToRentalHeader, IsHandled);
        IF IsHandled then
            exit;

        case ToRentalHeader."Document Type" of
            ToRentalHeader."Document Type"::Contract:
                PAGE.Run(PAGE::"TWE Rental Contract", ToRentalHeader);
            ToRentalHeader."Document Type"::Invoice:
                PAGE.Run(PAGE::"TWE Rental Invoice", ToRentalHeader);
            ToRentalHeader."Document Type"::"Return Shipment":
                PAGE.Run(PAGE::"TWE Rental Return Shipment", ToRentalHeader);
            ToRentalHeader."Document Type"::"Credit Memo":
                PAGE.Run(PAGE::"TWE Rental Credit Memo", ToRentalHeader);
        end;
    end;

    local procedure ShowWarningNotification(SourceVariant: Variant; MissingExCostRevLink: Boolean): Boolean
    var
        TempErrorMessage: Record "Error Message" temporary;
    begin
        if MissingExCostRevLink then
            ErrorMessageMgt.LogWarning(0, Text019Lbl, SourceVariant, 0, '');

        if ErrorMessageMgt.GetErrors(TempErrorMessage) then begin
            TempErrorMessage.SetRange("Message Type", TempErrorMessage."Message Type"::Error);
            if TempErrorMessage.FindFirst() then begin
                if SkipWarningNotification then
                    Error(TempErrorMessage.Description);
                exit(true);
            end;
            exit(not SkipWarningNotification);
        end;
    end;

    local procedure DeleteRentalLinesWithNegQty(FromRentalHeader: Record "TWE Rental Header"; OnlyTest: Boolean)
    var
        FromRentalLine: Record "TWE Rental Line";
    begin
        FromRentalLine.SetRange("Document Type", FromRentalHeader."Document Type");
        FromRentalLine.SetRange("Document No.", FromRentalHeader."No.");
        FromRentalLine.SetFilter(Quantity, '<0');
        OnDeleteRentalLinesWithNegQtyOnAfterSetFilters(FromRentalLine);
        if OnlyTest then begin
            if not FromRentalLine.Find('-') then
                Error(Text008Lbl);
            repeat
                FromRentalLine.TestField("Shipment No.", '');
                FromRentalLine.TestField("Return Receipt No.", '');
                FromRentalLine.TestField("Quantity Shipped", 0);
                FromRentalLine.TestField("Quantity Invoiced", 0);
            until FromRentalLine.Next() = 0;
        end else
            FromRentalLine.DeleteAll(true);
    end;

    procedure CopyRentalDocLine(var ToRentalHeader: Record "TWE Rental Header"; var ToRentalLine: Record "TWE Rental Line"; var FromRentalHeader: Record "TWE Rental Header"; var FromRentalLine: Record "TWE Rental Line"; var NextLineNo: Integer; var LinesNotCopied: Integer; RecalculateAmount: Boolean; FromRentalDocType: Enum "TWE Rental Document Type From"; DocLineNo: Integer): Boolean
    var
        RoundingLineInserted: Boolean;
        CopyThisLine: Boolean;
        CheckVATBusGroup: Boolean;
        InvDiscountAmount: Decimal;
    begin
        CopyThisLine := true;
        OnBeforeCopyRentalLine(ToRentalHeader, FromRentalHeader, FromRentalLine, RecalculateLines, CopyThisLine, MoveNegLines);
        if not CopyThisLine then begin
            LinesNotCopied := LinesNotCopied + 1;
            exit(false);
        end;

        CheckRentalRounding(FromRentalLine, RoundingLineInserted);

        if ((ToRentalHeader."Language Code" <> FromRentalHeader."Language Code") or RecalculateLines) and
           (FromRentalLine."Attached to Line No." <> 0) or
           FromRentalLine."Prepayment Line" or RoundingLineInserted
        then
            exit(false);

        ToRentalLine.SetRentalHeader(ToRentalHeader);
        if RecalculateLines and not FromRentalLine."System-Created Entry" then begin
            ToRentalLine.Init();
            OnAfterInitToRentalLine(FromRentalLine);
        end else begin
            ToRentalLine := FromRentalLine;
            OnCopyRentalLineOnAfterTransferFieldsToRentalLine(ToRentalLine, FromRentalLine);
            if ToRentalHeader."Document Type" in [ToRentalHeader."Document Type"::Quote] then
                ToRentalLine."Deferral Code" := '';
            if MoveNegLines and (ToRentalLine.Type <> ToRentalLine.Type::" ") then begin
                ToRentalLine.Amount := -ToRentalLine.Amount;
                ToRentalLine."Amount Including VAT" := -ToRentalLine."Amount Including VAT";
            end
        end;

        CheckVATBusGroup := (not RecalculateLines) and (ToRentalLine."No." <> '');
        OnCopyRentalLineOnBeforeCheckVATBusGroup(ToRentalLine, CheckVATBusGroup);
        if CheckVATBusGroup then
            ToRentalLine.TestField("VAT Bus. Posting Group", ToRentalHeader."VAT Bus. Posting Group");

        NextLineNo := NextLineNo + 10000;
        ToRentalLine."Document Type" := ToRentalHeader."Document Type";
        ToRentalLine."Document No." := ToRentalHeader."No.";
        ToRentalLine."Line No." := NextLineNo;
        ToRentalLine."Copied From Posted Doc." := FromRentalLine."Copied From Posted Doc.";
        if (ToRentalLine.Type <> ToRentalLine.Type::" ") and
           (ToRentalLine."Document Type" in [ToRentalLine."Document Type"::"Return Shipment", ToRentalLine."Document Type"::"Credit Memo"])
        then
            if (ToRentalLine.Amount = 0) or
               (ToRentalHeader."Prices Including VAT" <> FromRentalHeader."Prices Including VAT") or
               (ToRentalHeader."Currency Factor" <> FromRentalHeader."Currency Factor")
            then begin
                InvDiscountAmount := ToRentalLine."Inv. Discount Amount";
                ToRentalLine.Validate("Line Discount %");
                ToRentalLine.Validate("Inv. Discount Amount", InvDiscountAmount);
            end;

        ToRentalLine.Validate("Currency Code", FromRentalHeader."Currency Code");

        UpdateRentalLine(
          ToRentalHeader, ToRentalLine, FromRentalHeader, FromRentalLine,
          CopyThisLine, RecalculateAmount, FromRentalDocType);
        ToRentalLine.CheckLocationOnWMS();

        if ExactCostRevMandatory and
           (FromRentalLine.Type = FromRentalLine.Type::"Rental Item") and
           (FromRentalLine."Appl.-from Item Entry" <> 0) and
           not MoveNegLines
        then begin
            if RecalculateAmount then begin
                ToRentalLine.Validate("Unit Price", FromRentalLine."Unit Price");
                ToRentalLine.Validate("Line Discount %", FromRentalLine."Line Discount %");
                ToRentalLine.Validate(
                  "Line Discount Amount",
                  Round(FromRentalLine."Line Discount Amount", Currency."Amount Rounding Precision"));
                ToRentalLine.Validate(
                  "Inv. Discount Amount",
                  Round(FromRentalLine."Inv. Discount Amount", Currency."Amount Rounding Precision"));
            end;
            ToRentalLine.Validate("Appl.-from Item Entry", FromRentalLine."Appl.-from Item Entry");
            if not CreateToHeader then
                if ToRentalLine."Shipment Date" = 0D then
                    InitShipmentDateInLine(ToRentalHeader, ToRentalLine);
        end;

        if MoveNegLines and (ToRentalLine.Type <> ToRentalLine.Type::" ") then begin
            ToRentalLine.Validate(Quantity, -FromRentalLine.Quantity);
            ToRentalLine.Validate("Unit Price", FromRentalLine."Unit Price");
            ToRentalLine.Validate("Line Discount %", FromRentalLine."Line Discount %");
            ToRentalLine."Appl.-to Item Entry" := FromRentalLine."Appl.-to Item Entry";
            ToRentalLine."Appl.-from Item Entry" := FromRentalLine."Appl.-from Item Entry";
        end;

        CopyRentalLineExtText(ToRentalHeader, ToRentalLine, FromRentalHeader, FromRentalLine, DocLineNo, NextLineNo);

        if not RecalculateLines then begin
            ToRentalLine."Dimension Set ID" := FromRentalLine."Dimension Set ID";
            ToRentalLine."Shortcut Dimension 1 Code" := FromRentalLine."Shortcut Dimension 1 Code";
            ToRentalLine."Shortcut Dimension 2 Code" := FromRentalLine."Shortcut Dimension 2 Code";
            OnCopyRentalLineOnAfterSetDimensions(ToRentalLine, FromRentalLine);
        end;

        if CopyThisLine then begin
            OnBeforeInsertToRentalLine(
              ToRentalLine, FromRentalLine, FromRentalDocType.AsInteger(), RecalculateLines, ToRentalHeader, DocLineNo, NextLineNo);
            ToRentalLine.Insert();
            if ToRentalLine.Reserve = ToRentalLine.Reserve::Always then
                ToRentalLine.AutoReserve();
            OnAfterInsertToRentalLine(ToRentalLine, FromRentalLine, RecalculateLines, DocLineNo, FromRentalDocType);
        end else
            LinesNotCopied := LinesNotCopied + 1;

        exit(CopyThisLine);
    end;

    procedure UpdateRentalHeaderWhenCopyFromRentalHeader(var RentalHeader: Record "TWE Rental Header"; OriginalRentalHeader: Record "TWE Rental Header"; FromDocType: Enum "TWE Rental Document Type From")
    begin
        ClearRentalLastNoSFields(RentalHeader);
        RentalHeader.Status := RentalHeader.Status::Open;
        if RentalHeader."Document Type" <> RentalHeader."Document Type"::Contract then
            RentalHeader."Prepayment %" := 0;
        if FromDocType = "TWE Rental Document Type From"::"Return Shipment" then begin
            RentalHeader.CopySellToAddressToShipToAddress();
            ;
            RentalHeader.Validate("Ship-to Code");
        end;
        if FromDocType in ["TWE Rental Document Type From"::Quote] then
            if OriginalRentalHeader."Posting Date" = 0D then
                RentalHeader."Posting Date" := WorkDate()
            else
                RentalHeader."Posting Date" := OriginalRentalHeader."Posting Date";
    end;

    local procedure UpdateRentalHeaderWhenCopyFromRentalHeaderArchive(var RentalHeader: Record "TWE Rental Header")
    begin
        ClearRentalLastNoSFields(RentalHeader);
        RentalHeader.Status := RentalHeader.Status::Open;
    end;

    procedure ClearRentalLastNoSFields(var RentalHeader: Record "TWE Rental Header")
    begin
        RentalHeader."Last Shipping No." := '';
        RentalHeader."Last Posting No." := '';
        RentalHeader."Last Prepayment No." := '';
        RentalHeader."Last Prepmt. Cr. Memo No." := '';
        RentalHeader."Last Return Receipt No." := '';
    end;

    local procedure UpdateRentalLine(var ToRentalHeader: Record "TWE Rental Header"; var ToRentalLine: Record "TWE Rental Line"; var FromRentalHeader: Record "TWE Rental Header"; var FromRentalLine: Record "TWE Rental Line"; var CopyThisLine: Boolean; RecalculateAmount: Boolean; FromRentalDocType: Enum "TWE Rental Document Type From")
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        OnBeforeUpdateRentalLine(
          ToRentalHeader, ToRentalLine, FromRentalHeader, FromRentalLine,
          CopyThisLine, RecalculateAmount, FromRentalDocType.AsInteger());

        if RecalculateLines and not FromRentalLine."System-Created Entry" then
            RecalculateRentalLine(ToRentalHeader, ToRentalLine, FromRentalHeader, FromRentalLine, CopyThisLine);

        if ToRentalLine."Document Type" <> ToRentalLine."Document Type"::Contract then begin
            ToRentalLine."Drop Shipment" := false;
            ToRentalLine."Special Order" := false;
        end;
        if RecalculateAmount and (FromRentalLine."Appl.-from Item Entry" = 0) then begin
            if (ToRentalLine.Type <> ToRentalLine.Type::" ") and (ToRentalLine."No." <> '') then begin
                ToRentalLine.Validate("Line Discount %", FromRentalLine."Line Discount %");
                ToRentalLine.Validate(
                  "Inv. Discount Amount", Round(FromRentalLine."Inv. Discount Amount", Currency."Amount Rounding Precision"));
            end;
            ToRentalLine.Validate("Unit Cost (LCY)", FromRentalLine."Unit Cost (LCY)");
        end;
        if VATPostingSetup.Get(ToRentalLine."VAT Bus. Posting Group", ToRentalLine."VAT Prod. Posting Group") then begin
            ToRentalLine."VAT Identifier" := VATPostingSetup."VAT Identifier";
            ToRentalLine."VAT Clause Code" := VATPostingSetup."VAT Clause Code";
        end;

        ToRentalLine.UpdateWithWarehouseShip();
        if (ToRentalLine.Type = ToRentalLine.Type::"Rental Item") and (ToRentalLine."No." <> '') then begin
            GetItem(ToRentalLine."No.");
            if (MainRentalItem."Costing Method" = MainRentalItem."Costing Method"::Standard) and not ToRentalLine.IsShipment() then
                ToRentalLine.GetUnitCost();

            if MainRentalItem.Reserve = MainRentalItem.Reserve::Optional then
                ToRentalLine.Reserve := ToRentalHeader.Reserve
            else
                ToRentalLine.Reserve := MainRentalItem.Reserve;
            if ToRentalLine.Reserve = ToRentalLine.Reserve::Always then
                InitShipmentDateInLine(ToRentalHeader, ToRentalLine);
        end;

        OnAfterUpdateRentalLine(
          ToRentalHeader, ToRentalLine, FromRentalHeader, FromRentalLine,
          CopyThisLine, RecalculateAmount, FromRentalDocType.AsInteger());
    end;

    local procedure RecalculateRentalLine(var ToRentalHeader: Record "TWE Rental Header"; var ToRentalLine: Record "TWE Rental Line"; var FromRentalHeader: Record "TWE Rental Header"; var FromRentalLine: Record "TWE Rental Line"; var CopyThisLine: Boolean)
    var
        GLAcc: Record "G/L Account";
    begin
        OnBeforeRecalculateRentalLine(ToRentalHeader, ToRentalLine, FromRentalHeader, FromRentalLine, CopyThisLine);

        ToRentalLine.Validate(Type, FromRentalLine.Type);
        ToRentalLine.Description := FromRentalLine.Description;
        ToRentalLine.Validate("Description 2", FromRentalLine."Description 2");
        OnUpdateRentalLine(ToRentalLine, FromRentalLine);

        if (FromRentalLine.Type <> FromRentalLine.Type::" ") and (FromRentalLine."No." <> '') then begin
            if ToRentalLine.Type = ToRentalLine.Type::"G/L Account" then begin
                ToRentalLine."No." := FromRentalLine."No.";
                GLAcc.Get(FromRentalLine."No.");
                CopyThisLine := GLAcc."Direct Posting";
                if CopyThisLine then
                    ToRentalLine.Validate("No.", FromRentalLine."No.");
            end else begin
                ToRentalLine.Validate("No.", FromRentalLine."No.");
                if ToRentalLine.Type = ToRentalLine.Type::"Rental Item" then
                    ToRentalLine.Validate("Rental Item", FromRentalLine."Rental Item");
            end;
            ToRentalLine.Validate("Variant Code", FromRentalLine."Variant Code");
            ToRentalLine.Validate("Location Code", FromRentalLine."Location Code");
            ToRentalLine.Validate("Unit of Measure", FromRentalLine."Unit of Measure");
            ToRentalLine.Validate("Unit of Measure Code", FromRentalLine."Unit of Measure Code");
            ToRentalLine.Validate(Quantity, FromRentalLine.Quantity);
            OnRecalculateRentalLineOnAfterValidateQuantity(ToRentalLine, FromRentalLine);

            if not (FromRentalLine.Type in [FromRentalLine.Type::"Rental Item", FromRentalLine.Type::Resource]) then begin
                if (FromRentalHeader."Currency Code" <> ToRentalHeader."Currency Code") or
                   (FromRentalHeader."Prices Including VAT" <> ToRentalHeader."Prices Including VAT")
                then begin
                    ToRentalLine."Unit Price" := 0;
                    ToRentalLine."Line Discount %" := 0;
                end else begin
                    ToRentalLine.Validate("Unit Price", FromRentalLine."Unit Price");
                    ToRentalLine.Validate("Line Discount %", FromRentalLine."Line Discount %");
                end;
                if ToRentalLine.Quantity <> 0 then
                    ToRentalLine.Validate("Line Discount Amount", FromRentalLine."Line Discount Amount");
            end;
            ToRentalLine.Validate("Work Type Code", FromRentalLine."Work Type Code");
            if (ToRentalLine."Document Type" = ToRentalLine."Document Type"::Contract) and
               (FromRentalLine."Purchasing Code" <> '')
            then
                ToRentalLine.Validate("Purchasing Code", FromRentalLine."Purchasing Code");
        end;
        if (FromRentalLine.Type = FromRentalLine.Type::" ") and (FromRentalLine."No." <> '') then
            ToRentalLine.Validate("No.", FromRentalLine."No.");

        OnAfterRecalculateRentalLine(ToRentalHeader, ToRentalLine, FromRentalHeader, FromRentalLine, CopyThisLine);
    end;

    local procedure CheckRentalRounding(FromRentalLine: Record "TWE Rental Line"; var RoundingLineInserted: Boolean)
    var
        RentalSetup: Record "TWE Rental Setup";
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        if (FromRentalLine.Type <> FromRentalLine.Type::"G/L Account") or (FromRentalLine."No." = '') then
            exit;
        if not FromRentalLine."System-Created Entry" then
            exit;

        RentalSetup.Get();
        if RentalSetup."Invoice Rounding" then begin
            Customer.Get(FromRentalLine."Bill-to Customer No.");
            CustomerPostingGroup.Get(Customer."Customer Posting Group");
            RoundingLineInserted := FromRentalLine."No." = CustomerPostingGroup.GetInvRoundingAccount();
        end;
    end;

    local procedure WarnRentalInvoicePmtDisc(var ToRentalHeader: Record "TWE Rental Header"; FromDocType: Enum "TWE Rental Document Type From"; FromDocNo: Code[20])
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        if HideDialog then
            exit;

        if IncludeHeader and
           (ToRentalHeader."Document Type" in
            [ToRentalHeader."Document Type"::"Return Shipment", ToRentalHeader."Document Type"::"Credit Memo"])
        then begin
            CustLedgEntry.SetCurrentKey("Document No.");
            CustLedgEntry.SetRange("Document Type", CustLedgEntry."Document Type"::Invoice);
            CustLedgEntry.SetRange("Document No.", FromDocNo);
            if CustLedgEntry.FindFirst() then
                if (CustLedgEntry."Pmt. Disc. Given (LCY)" <> 0) and
                   (CustLedgEntry."Journal Batch Name" = '')
                then
                    Message(Text006Lbl, SelectStr(FromDocType.AsInteger(), Text007Lbl), FromDocNo);
        end;
    end;

    local procedure CheckCopyFromRentalHeaderAvail(FromRentalHeader: Record "TWE Rental Header"; ToRentalHeader: Record "TWE Rental Header")
    var
        FromRentalLine: Record "TWE Rental Line";
        ToRentalLine: Record "TWE Rental Line";
    begin
        if ToRentalHeader."Document Type" in [ToRentalHeader."Document Type"::Contract, ToRentalHeader."Document Type"::Invoice] then begin
            FromRentalLine.SetRange("Document Type", FromRentalHeader."Document Type");
            FromRentalLine.SetRange("Document No.", FromRentalHeader."No.");
            FromRentalLine.SetRange(Type, FromRentalLine.Type::"Rental Item");
            FromRentalLine.SetFilter("No.", '<>%1', '');
            FromRentalLine.SetFilter(Quantity, '>0');
            if FromRentalLine.FindSet() then
                repeat
                    if not IsItemBlocked(FromRentalLine."No.") then begin
                        ToRentalLine.CopyFromTWERentalLine(FromRentalLine);
                        if ToRentalHeader."Document Type" = ToRentalHeader."Document Type"::Contract then
                            ToRentalLine."Outstanding Quantity" := FromRentalLine.Quantity - FromRentalLine."Qty. to Assemble to Order";
                        CheckItemAvailability(ToRentalHeader, ToRentalLine);
                        OnCheckCopyFromRentalHeaderAvailOnAfterCheckItemAvailability(
                          ToRentalHeader, ToRentalLine, FromRentalHeader, IncludeHeader, FromRentalLine);

                        if ToRentalHeader."Document Type" = ToRentalHeader."Document Type"::Contract then begin
                            ToRentalLine."Outstanding Quantity" := FromRentalLine.Quantity;
                            if ToRentalHeader."Document Type" = ToRentalHeader."Document Type"::Contract then
                                ToRentalLine."Outstanding Quantity" := FromRentalLine.Quantity - FromRentalLine."Qty. to Assemble to Order";
                            ToRentalLine."Qty. to Assemble to Order" := 0;
                            ToRentalLine."Drop Shipment" := FromRentalLine."Drop Shipment";
                            CheckItemAvailability(ToRentalHeader, ToRentalLine);

                            if ToRentalHeader."Document Type" = ToRentalHeader."Document Type"::Contract then begin
                                ToRentalLine."Outstanding Quantity" := FromRentalLine.Quantity;
                                ToRentalLine."Qty. to Assemble to Order" := FromRentalLine."Qty. to Assemble to Order";
                                //CheckATOItemAvailable(FromRentalLine, ToRentalLine);
                            end;
                        end;
                    end;
                until FromRentalLine.Next() = 0;
        end;
    end;

    local procedure CheckCopyFromRentalShptAvail(FromRentalShptHeader: Record "TWE Rental Shipment Header"; ToRentalHeader: Record "TWE Rental Header")
    var
        FromRentalShptLine: Record "TWE Rental Shipment Line";
        ToRentalLine: Record "TWE Rental Line";
        FromPostedAsmHeader: Record "Posted Assembly Header";
    begin
        if not (ToRentalHeader."Document Type" in [ToRentalHeader."Document Type"::Contract, ToRentalHeader."Document Type"::Invoice]) then
            exit;

        FromRentalShptLine.SetRange("Document No.", FromRentalShptHeader."No.");
        FromRentalShptLine.SetRange(Type, FromRentalShptLine.Type::"Rental Item");
        FromRentalShptLine.SetFilter("No.", '<>%1', '');
        FromRentalShptLine.SetFilter(Quantity, '>0');
        if FromRentalShptLine.FindSet() then
            repeat
                if not IsItemBlocked(FromRentalShptLine."No.") then begin
                    ToRentalLine.CopyFromRentalShptLine(FromRentalShptLine);
                    if ToRentalLine."Document Type" = ToRentalLine."Document Type"::Contract then
                        if FromRentalShptLine.AsmToShipmentExists(FromPostedAsmHeader) then
                            ToRentalLine."Outstanding Quantity" := FromRentalShptLine.Quantity - FromPostedAsmHeader.Quantity;
                    CheckItemAvailability(ToRentalHeader, ToRentalLine);
                    OnCheckCopyFromRentalShptAvailOnAfterCheckItemAvailability(
                      ToRentalHeader, ToRentalLine, FromRentalShptHeader, IncludeHeader, FromRentalShptLine);

                    if ToRentalLine."Document Type" = ToRentalLine."Document Type"::Contract then
                        if FromRentalShptLine.AsmToShipmentExists(FromPostedAsmHeader) then
                            ToRentalLine."Qty. to Assemble to Order" := FromPostedAsmHeader.Quantity;
                end;
            until FromRentalShptLine.Next() = 0;
    end;

    local procedure CheckCopyFromRentalInvoiceAvail(FromRentalInvHeader: Record "TWE Rental Invoice Header"; ToRentalHeader: Record "TWE Rental Header")
    var
        FromRentalInvLine: Record "TWE Rental Invoice Line";
        ToRentalLine: Record "TWE Rental Line";
    begin
        if not (ToRentalHeader."Document Type" in [ToRentalHeader."Document Type"::Contract, ToRentalHeader."Document Type"::Invoice]) then
            exit;

        FromRentalInvLine.SetRange("Document No.", FromRentalInvHeader."No.");
        FromRentalInvLine.SetRange(Type, FromRentalInvLine.Type::"Rental Item");
        FromRentalInvLine.SetFilter("No.", '<>%1', '');
        FromRentalInvLine.SetRange("Prepayment Line", false);
        FromRentalInvLine.SetFilter(Quantity, '>0');
        if FromRentalInvLine.FindSet() then
            repeat
                if not IsItemBlocked(FromRentalInvLine."No.") then begin
                    ToRentalLine.CopyFromRentalInvLine(FromRentalInvLine);
                    CheckItemAvailability(ToRentalHeader, ToRentalLine);
                    OnCheckCopyFromRentalInvoiceAvailOnAfterCheckItemAvailability(
                      ToRentalHeader, ToRentalLine, FromRentalInvHeader, IncludeHeader, FromRentalInvLine);
                end;
            until FromRentalInvLine.Next() = 0;
    end;

    local procedure CheckCopyFromRentalCrMemoAvail(FromRentalCrMemoHeader: Record "TWE Rental Cr.Memo Header"; ToRentalHeader: Record "TWE Rental Header")
    var
        FromRentalCrMemoLine: Record "TWE Rental Cr.Memo Line";
        ToRentalLine: Record "TWE Rental Line";
    begin
        if not (ToRentalHeader."Document Type" in [ToRentalHeader."Document Type"::Contract, ToRentalHeader."Document Type"::Invoice]) then
            exit;

        FromRentalCrMemoLine.SetRange("Document No.", FromRentalCrMemoHeader."No.");
        FromRentalCrMemoLine.SetRange(Type, FromRentalCrMemoLine.Type::"Rental Item");
        FromRentalCrMemoLine.SetFilter("No.", '<>%1', '');
        FromRentalCrMemoLine.SetRange("Prepayment Line", false);
        FromRentalCrMemoLine.SetFilter(Quantity, '>0');
        if FromRentalCrMemoLine.FindSet() then
            repeat
                if not IsItemBlocked(FromRentalCrMemoLine."No.") then begin
                    ToRentalLine.CopyFromRentalCrMemoLine(FromRentalCrMemoLine);
                    CheckItemAvailability(ToRentalHeader, ToRentalLine);
                    OnCheckCopyFromRentalCrMemoAvailOnAfterCheckItemAvailability(
                      ToRentalHeader, ToRentalLine, FromRentalCrMemoHeader, IncludeHeader, FromRentalCrMemoLine);
                end;
            until FromRentalCrMemoLine.Next() = 0;
    end;

    local procedure CheckCopyFromRentalHeaderArchiveAvail(FromRentalHeaderArchive: Record "TWE Rental Header Archive"; ToRentalHeader: Record "TWE Rental Header")
    var
        FromRentalLineArchive: Record "TWE Rental Line Archive";
        ToRentalLine: Record "TWE Rental Line";
    begin
        if not (ToRentalHeader."Document Type" in [ToRentalHeader."Document Type"::Contract, ToRentalHeader."Document Type"::Invoice]) then
            exit;

        FromRentalLineArchive.SetRange("Document Type", FromRentalHeaderArchive."Document Type");
        FromRentalLineArchive.SetRange("Document No.", FromRentalHeaderArchive."No.");
        FromRentalLineArchive.SetRange("Doc. No. Occurrence", FromRentalHeaderArchive."Doc. No. Occurrence");
        FromRentalLineArchive.SetRange("Version No.", FromRentalHeaderArchive."Version No.");
        FromRentalLineArchive.SetRange(Type, FromRentalLineArchive.Type::"Rental Item");
        FromRentalLineArchive.SetFilter("No.", '<>%1', '');
        if FromRentalLineArchive.FindSet() then
            repeat
                if FromRentalLineArchive.Quantity > 0 then begin
                    ToRentalLine."No." := FromRentalLineArchive."No.";
                    ToRentalLine."Variant Code" := FromRentalLineArchive."Variant Code";
                    ToRentalLine."Location Code" := FromRentalLineArchive."Location Code";
                    ToRentalLine."Bin Code" := FromRentalLineArchive."Bin Code";
                    ToRentalLine."Unit of Measure Code" := FromRentalLineArchive."Unit of Measure Code";
                    ToRentalLine."Qty. per Unit of Measure" := FromRentalLineArchive."Qty. per Unit of Measure";
                    ToRentalLine."Outstanding Quantity" := FromRentalLineArchive.Quantity;
                    CheckItemAvailability(ToRentalHeader, ToRentalLine);
                    OnCheckCopyFromRentalHeaderArchiveAvailOnAfterCheckItemAvailability(ToRentalHeader, ToRentalLine,
                    FromRentalHeaderArchive, FromRentalLineArchive, IncludeHeader);
                end;
            until FromRentalLineArchive.Next() = 0;
    end;

    local procedure CheckItemAvailability(var ToRentalHeader: Record "TWE Rental Header"; var ToRentalLine: Record "TWE Rental Line")
    var
        IsHandled: Boolean;
    begin
        OnBeforeCheckItemAvailability(ToRentalHeader, ToRentalLine, HideDialog, IsHandled);
        if IsHandled then
            exit;

        if HideDialog then
            exit;

        ToRentalLine."Document Type" := ToRentalHeader."Document Type";
        ToRentalLine."Document No." := ToRentalHeader."No.";
        ToRentalLine.Type := ToRentalLine.Type::"Rental Item";
        ToRentalLine."Purchase Order No." := '';
        ToRentalLine."Purch. Order Line No." := 0;
        ToRentalLine."Drop Shipment" :=
          not RecalculateLines and ToRentalLine."Drop Shipment" and
          (ToRentalHeader."Document Type" = ToRentalHeader."Document Type"::Contract);

        SetShipmentDateInLine(ToRentalHeader, ToRentalLine);
        /* 
                if ItemCheckAvail.RentalLineCheck(ToRentalLine) then
                    ItemCheckAvail.RaiseUpdateInterruptedError; */
    end;

    local procedure InitShipmentDateInLine(RentalHeader: Record "TWE Rental Header"; var RentalLine: Record "TWE Rental Line")
    begin
        if RentalHeader."Shipment Date" <> 0D then
            RentalLine."Shipment Date" := RentalHeader."Shipment Date"
        else
            RentalLine."Shipment Date" := WorkDate();
    end;

    local procedure SetShipmentDateInLine(RentalHeader: Record "TWE Rental Header"; var RentalLine: Record "TWE Rental Line")
    begin
        OnBeforeSetShipmentDateInLine(RentalHeader, RentalLine);
        if RentalLine."Shipment Date" = 0D then begin
            InitShipmentDateInLine(RentalHeader, RentalLine);
            RentalLine.Validate("Shipment Date");
        end;
    end;

    procedure CopyServContractLines(ToServContractHeader: Record "Service Contract Header"; FromDocType: Option; FromDocNo: Code[20]; var FromServContractLine: Record "Service Contract Line") AllLinesCopied: Boolean
    var
        ExistingServContractLine: Record "Service Contract Line";
        LineNo: Integer;
    begin
        if FromDocNo = '' then
            Error(Text000Lbl);

        ExistingServContractLine.LockTable();
        ExistingServContractLine.Reset();
        ExistingServContractLine.SetRange("Contract Type", ToServContractHeader."Contract Type");
        ExistingServContractLine.SetRange("Contract No.", ToServContractHeader."Contract No.");
        if ExistingServContractLine.FindLast() then
            LineNo := ExistingServContractLine."Line No." + 10000
        else
            LineNo := 10000;

        AllLinesCopied := true;
        FromServContractLine.Reset();
        FromServContractLine.SetRange("Contract Type", FromDocType);
        FromServContractLine.SetRange("Contract No.", FromDocNo);
        if FromServContractLine.Find('-') then
            repeat
                if not ProcessServContractLine(
                     ToServContractHeader,
                     FromServContractLine,
                     LineNo)
                then begin
                    AllLinesCopied := false;
                    FromServContractLine.Mark(true)
                end else
                    LineNo := LineNo + 10000
            until FromServContractLine.Next() = 0;

        OnAfterCopyServContractLines(ToServContractHeader, FromDocType, FromDocNo, FromServContractLine);
    end;

    procedure ServContractHeaderDocType(DocType: Option): Integer
    var
        ServContractHeader: Record "Service Contract Header";
    begin
        case DocType of
            ServDocType::Quote:
                exit(ServContractHeader."Contract Type"::Quote);
            ServDocType::Contract:
                exit(ServContractHeader."Contract Type"::Contract);
        end;
    end;

    local procedure ProcessServContractLine(ToServContractHeader: Record "Service Contract Header"; var FromServContractLine: Record "Service Contract Line"; LineNo: Integer): Boolean
    var
        ToServContractLine: Record "Service Contract Line";
        ExistingServContractLine: Record "Service Contract Line";
        ServItem: Record "Service Item";
    begin
        if FromServContractLine."Service Item No." <> '' then begin
            ServItem.Get(FromServContractLine."Service Item No.");
            if ServItem."Customer No." <> ToServContractHeader."Customer No." then
                exit(false);

            ExistingServContractLine.Reset();
            ExistingServContractLine.SetCurrentKey("Service Item No.", "Contract Status");
            ExistingServContractLine.SetRange("Service Item No.", FromServContractLine."Service Item No.");
            ExistingServContractLine.SetRange("Contract Type", ToServContractHeader."Contract Type");
            ExistingServContractLine.SetRange("Contract No.", ToServContractHeader."Contract No.");
            if not ExistingServContractLine.IsEmpty then
                exit(false);
        end;

        ToServContractLine := FromServContractLine;
        ToServContractLine."Last Planned Service Date" := 0D;
        ToServContractLine."Last Service Date" := 0D;
        ToServContractLine."Last Preventive Maint. Date" := 0D;
        ToServContractLine."Invoiced to Date" := 0D;
        ToServContractLine."Contract Type" := ToServContractHeader."Contract Type";
        ToServContractLine."Contract No." := ToServContractHeader."Contract No.";
        ToServContractLine."Line No." := LineNo;
        ToServContractLine."New Line" := true;
        ToServContractLine.Credited := false;
        ToServContractLine.SetupNewLine();
        ToServContractLine.Insert(true);

        OnAfterProcessServContractLine(ToServContractLine, FromServContractLine);
        exit(true);
    end;

    procedure CopyRentalShptLinesToDoc(ToRentalHeader: Record "TWE Rental Header"; var FromRentalShptLine: Record "TWE Rental Shipment Line"; var LinesNotCopied: Integer; var MissingExCostRevLink: Boolean)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        TempTrkgItemLedgEntry: Record "Item Ledger Entry" temporary;
        FromRentalHeader: Record "TWE Rental Header";
        FromRentalLine: Record "TWE Rental Line";
        ToRentalLine: Record "TWE Rental Line";
        TempFromRentalLineBuf: Record "TWE Rental Line" temporary;
        FromRentalShptHeader: Record "TWE Rental Shipment Header";
        TempItemTrkgEntry: Record "Reservation Entry" temporary;
        TempDocRentalLine: Record "TWE Rental Line" temporary;
        OldDocNo: Code[20];
        NextLineNo: Integer;
        NextItemTrkgEntryNo: Integer;
        FromLineCounter: Integer;
        ToLineCounter: Integer;
        CopyItemTrkg: Boolean;
        SplitLine: Boolean;
        FillExactCostRevLink: Boolean;
        CopyLine: Boolean;
        InsertDocNoLine: Boolean;
    begin
        OldDocNo := '';
        MissingExCostRevLink := false;
        InitCurrency(ToRentalHeader."Currency Code");
        OpenWindow();

        OnBeforeCopyRentalShptLinesToDoc(TempDocRentalLine, ToRentalHeader, FromRentalShptLine);

        if FromRentalShptLine.FindSet() then
            repeat
                FromLineCounter := FromLineCounter + 1;
                if IsTimeForUpdate() then
                    Window.Update(1, FromLineCounter);
                if FromRentalShptHeader."No." <> FromRentalShptLine."Document No." then begin
                    FromRentalShptHeader.Get(FromRentalShptLine."Document No.");
                    TransferOldExtLines.ClearLineNumbers();
                end;
                FromRentalShptHeader.TestField("Prices Including VAT", ToRentalHeader."Prices Including VAT");
                FromRentalHeader.TransferFields(FromRentalShptHeader);
                OnCopyRentalShptLinesToDocOnAfterFromRentalHeaderTransferFields(FromRentalShptHeader, FromRentalHeader);
                FillExactCostRevLink :=
                  IsRentalFillExactCostRevLink(ToRentalHeader, 0, FromRentalHeader."Currency Code");
                FromRentalLine.TransferFields(FromRentalShptLine);
                FromRentalLine."Appl.-from Item Entry" := 0;
                FromRentalLine."Copied From Posted Doc." := true;

                if FromRentalShptLine."Document No." <> OldDocNo then begin
                    OldDocNo := FromRentalShptLine."Document No.";
                    InsertDocNoLine := true;
                end;

                OnBeforeCopyRentalShptLinesToBuffer(FromRentalLine, FromRentalShptLine, ToRentalHeader);

                SplitLine := true;
                FromRentalShptLine.FilterPstdDocLnItemLedgEntries(ItemLedgEntry);
                if not SplitPstdRentalLinesPerILE(
                     ToRentalHeader, FromRentalHeader, ItemLedgEntry, TempFromRentalLineBuf,
                     FromRentalLine, TempDocRentalLine, NextLineNo, CopyItemTrkg, MissingExCostRevLink, FillExactCostRevLink, true)
                then
                    if CopyItemTrkg then
                        SplitLine :=
                          SplitRentalDocLinesPerItemTrkg(
                            ItemLedgEntry, TempItemTrkgEntry, TempFromRentalLineBuf,
                            FromRentalLine, TempDocRentalLine, NextLineNo, NextItemTrkgEntryNo, MissingExCostRevLink, true)
                    else
                        SplitLine := false;

                if not SplitLine then begin
                    TempFromRentalLineBuf := FromRentalLine;
                    CopyLine := true;
                end else
                    CopyLine := TempFromRentalLineBuf.FindSet() and FillExactCostRevLink;

                Window.Update(1, FromLineCounter);
                if CopyLine then begin
                    NextLineNo := GetLastToRentalLineNo(ToRentalHeader);
                    if InsertDocNoLine then begin
                        InsertOldRentalDocNoLine(ToRentalHeader, FromRentalShptLine."Document No.", 1, NextLineNo);
                        InsertDocNoLine := false;
                    end;
                    repeat
                        ToLineCounter := ToLineCounter + 1;
                        if IsTimeForUpdate() then
                            Window.Update(2, ToLineCounter);

                        OnCopyRentalShptLinesToDocOnBeforeCopyRentalLine(ToRentalHeader, TempFromRentalLineBuf);

                        if CopyRentalDocLine(
                             ToRentalHeader, ToRentalLine, FromRentalHeader, TempFromRentalLineBuf, NextLineNo, LinesNotCopied, false,
                             "TWE Rental Document Type From".FromInteger("TWE Rental Document Type From"::"Posted Shipment".AsInteger()),
                              TempFromRentalLineBuf."Line No.")
                        then begin
                            if CopyItemTrkg then
                                if SplitLine then
                                    ItemTrackingDocMgt.CollectItemTrkgPerPostedDocLine(
                                      TempItemTrkgEntry, TempTrkgItemLedgEntry, false, TempFromRentalLineBuf."Document No.", TempFromRentalLineBuf."Line No.")
                                else
                                    ItemTrackingDocMgt.CopyItemLedgerEntriesToTemp(TempTrkgItemLedgEntry, ItemLedgEntry);

                            OnAfterCopyRentalLineFromRentalShptLineBuffer(
                              ToRentalLine, FromRentalShptLine, IncludeHeader, RecalculateLines, TempFromRentalLineBuf, ToRentalHeader, TempFromRentalLineBuf);
                        end;
                    until TempFromRentalLineBuf.Next() = 0;
                end;
            until FromRentalShptLine.Next() = 0;

        Window.Close();
    end;

    procedure CopyRentalInvLinesToDoc(ToRentalHeader: Record "TWE Rental Header"; var FromRentalInvLine: Record "TWE Rental Invoice Line"; var LinesNotCopied: Integer; var MissingExCostRevLink: Boolean)
    var
        TempItemLedgEntryBuf: Record "Item Ledger Entry" temporary;
        FromRentalHeader: Record "TWE Rental Header";
        FromRentalLine: Record "TWE Rental Line";
        FromRentalLine2: Record "TWE Rental Line";
        ToRentalLine: Record "TWE Rental Line";
        TempRentalLineBuf: Record "TWE Rental Line" temporary;
        FromRentalInvHeader: Record "TWE Rental Invoice Header";
        TempItemTrkgEntry: Record "Reservation Entry" temporary;
        TempDocRentalLine: Record "TWE Rental Line" temporary;
        OldInvDocNo: Code[20];
        OldShptDocNo: Code[20];
        OldBufDocNo: Code[20];
        NextLineNo: Integer;
        RentalCombDocLineNo: Integer;
        NextItemTrkgEntryNo: Integer;
        FromLineCounter: Integer;
        ToLineCounter: Integer;
        CopyItemTrkg: Boolean;
        SplitLine: Boolean;
        FillExactCostRevLink: Boolean;
        RentalInvLineCount: Integer;
        FirstLineShipped: Boolean;
        FirstLineText: Boolean;
    begin
        OldInvDocNo := '';
        OldBufDocNo := '';
        MissingExCostRevLink := false;
        InitCurrency(ToRentalHeader."Currency Code");
        TempRentalLineBuf.Reset();
        TempRentalLineBuf.DeleteAll();
        TempItemTrkgEntry.Reset();
        TempItemTrkgEntry.DeleteAll();
        OpenWindow();
        TempRentalInvLine.DeleteAll();

        OnBeforeCopyRentalInvLines(TempDocRentalLine, ToRentalHeader, FromRentalInvLine, CopyJobData);

        // Fill sales line buffer
        RentalInvLineCount := 0;
        FirstLineText := false;
        if FromRentalInvLine.FindSet() then
            repeat
                FromLineCounter := FromLineCounter + 1;
                if IsTimeForUpdate() then
                    Window.Update(1, FromLineCounter);
                SetTempRentalInvLine(FromRentalInvLine, TempRentalInvLine, RentalInvLineCount, NextLineNo, FirstLineText);
                if FromRentalInvHeader."No." <> FromRentalInvLine."Document No." then begin
                    FromRentalInvHeader.Get(FromRentalInvLine."Document No.");
                    TransferOldExtLines.ClearLineNumbers();
                    OnCopyRentalInvLinesToDocOnAfterGetFromRentalInvHeader(ToRentalHeader, FromRentalInvHeader);
                end;
                FromRentalInvHeader.TestField("Prices Including VAT", ToRentalHeader."Prices Including VAT");
                FromRentalHeader.TransferFields(FromRentalInvHeader);
                OnCopyRentalInvLinesToDocOnAfterFromRentalHeaderTransferFields(FromRentalHeader, FromRentalInvHeader);
                FillExactCostRevLink := IsRentalFillExactCostRevLink(ToRentalHeader, 1, FromRentalHeader."Currency Code");
                FromRentalLine.TransferFields(FromRentalInvLine);
                FromRentalLine."Appl.-from Item Entry" := 0;
                // Reuse fields to buffer invoice line information
                FromRentalLine."Shipment No." := FromRentalInvLine."Document No.";
                FromRentalLine."Shipment Line No." := 0;
                FromRentalLine."Return Receipt No." := '';
                FromRentalLine."Return Receipt Line No." := FromRentalInvLine."Line No.";
                FromRentalLine."Copied From Posted Doc." := true;

                OnBeforeCopyRentalInvLinesToBuffer(FromRentalLine, FromRentalInvLine, ToRentalHeader);

                SplitLine := true;
                FromRentalInvLine.GetItemLedgEntries(TempItemLedgEntryBuf, true);
                if not SplitPstdRentalLinesPerILE(
                     ToRentalHeader, FromRentalHeader, TempItemLedgEntryBuf, TempRentalLineBuf,
                     FromRentalLine, TempDocRentalLine, NextLineNo, CopyItemTrkg, MissingExCostRevLink, FillExactCostRevLink, false)
                then
                    if CopyItemTrkg then
                        SplitLine := SplitRentalDocLinesPerItemTrkg(
                            TempItemLedgEntryBuf, TempItemTrkgEntry, TempRentalLineBuf,
                            FromRentalLine, TempDocRentalLine, NextLineNo, NextItemTrkgEntryNo, MissingExCostRevLink, false)
                    else
                        SplitLine := false;

                if not SplitLine then
                    CopyRentalLinesToBuffer(
                      FromRentalHeader, FromRentalLine, FromRentalLine2, TempRentalLineBuf,
                      ToRentalHeader, TempDocRentalLine, FromRentalInvLine."Document No.", NextLineNo);

                OnAfterCopyRentalInvLine(TempDocRentalLine, ToRentalHeader, TempRentalLineBuf, FromRentalInvLine);
            until FromRentalInvLine.Next() = 0;

        // Create sales line from buffer
        Window.Update(1, FromLineCounter);
        FirstLineShipped := true;
        // Sorting according to Rental Line Document No.,Line No.
        /*TempRentalLineBuf.SetCurrentKey("Document Type", "Document No.", "Line No.");
              if TempRentalLineBuf.FindSet() then
                  repeat
                      if TempRentalLineBuf.Type = TempRentalLineBuf.Type::"Rental Item" then
                          RentalLineCount += 1;
                  until TempRentalLineBuf.Next() = 0; */
        if TempRentalLineBuf.FindSet() then begin
            NextLineNo := GetLastToRentalLineNo(ToRentalHeader);
            repeat
                ToLineCounter := ToLineCounter + 1;
                if IsTimeForUpdate() then
                    Window.Update(2, ToLineCounter);
                if TempRentalLineBuf."Shipment No." <> OldInvDocNo then begin
                    OldInvDocNo := TempRentalLineBuf."Shipment No.";
                    OldShptDocNo := '';
                    FirstLineShipped := true;
                    OnCopyRentalInvLinesToDocOnBeforeInsertOldRentalDocNoLine(ToRentalHeader, SkipCopyFromDescription);
                    InsertOldRentalDocNoLine(ToRentalHeader, OldInvDocNo, 2, NextLineNo);
                    OnCopyRentalInvLinesToDocOnAfterInsertOldRentalDocNoLine(ToRentalHeader, SkipCopyFromDescription);
                end;
                CheckFirstLineShipped(TempRentalLineBuf."Document No.", TempRentalLineBuf."Shipment Line No.", RentalCombDocLineNo, NextLineNo, FirstLineShipped);
                if (TempRentalLineBuf."Document No." <> OldShptDocNo) and (TempRentalLineBuf."Shipment Line No." > 0) then begin
                    if FirstLineShipped then
                        RentalCombDocLineNo := NextLineNo;
                    OldShptDocNo := TempRentalLineBuf."Document No.";
                    InsertOldRentalCombDocNoLine(ToRentalHeader, OldInvDocNo, OldShptDocNo, RentalCombDocLineNo, true);
                    NextLineNo := NextLineNo + 10000;
                    FirstLineShipped := true;
                end;

                InitFromRentalLine(FromRentalLine2, TempRentalLineBuf);
                if GetRentalDocNo(TempDocRentalLine, TempRentalLineBuf."Line No.") <> OldBufDocNo then begin
                    OldBufDocNo := GetRentalDocNo(TempDocRentalLine, TempRentalLineBuf."Line No.");
                    TransferOldExtLines.ClearLineNumbers();
                end;

                OnCopyRentalInvLinesToDocOnBeforeCopyRentalLine(ToRentalHeader, FromRentalLine2);

                if CopyRentalDocLine(
                    ToRentalHeader, ToRentalLine, FromRentalHeader, FromRentalLine2, NextLineNo, LinesNotCopied, TempRentalLineBuf."Return Receipt No." = '',
                    "TWE Rental Document Type From".FromInteger("TWE Rental Document Type From"::"Posted Invoice".AsInteger()),
                     GetRentalLineNo(TempDocRentalLine, FromRentalLine2."Line No."))
                then begin
                    FromRentalInvLine.Get(TempRentalLineBuf."Shipment No.", TempRentalLineBuf."Return Receipt Line No.");

                    // copy item tracking
                    if (TempRentalLineBuf.Type = TempRentalLineBuf.Type::"Rental Item") and (TempRentalLineBuf.Quantity <> 0) and RentalDocCanReceiveTracking(ToRentalHeader) then begin
                        FromRentalInvLine."Document No." := OldInvDocNo;
                        FromRentalInvLine."Line No." := TempRentalLineBuf."Return Receipt Line No.";
                        FromRentalInvLine.GetItemLedgEntries(TempItemLedgEntryBuf, true);
                        if IsCopyItemTrkg(TempItemLedgEntryBuf, CopyItemTrkg, FillExactCostRevLink) then
                            CopyItemLedgEntryTrackingToRentalLine(TempItemLedgEntryBuf, TempItemTrkgEntry, TempRentalLineBuf);
                    end;

                    OnAfterCopyRentalLineFromRentalLineBuffer(
                      ToRentalLine, FromRentalInvLine, IncludeHeader, RecalculateLines, TempDocRentalLine, ToRentalHeader, TempRentalLineBuf,
                      FromRentalLine2);
                end;
            until TempRentalLineBuf.Next() = 0;
        end;
        Window.Close();
    end;

    procedure CopyRentalCrMemoLinesToDoc(ToRentalHeader: Record "TWE Rental Header"; var FromRentalCrMemoLine: Record "TWE Rental Cr.Memo Line"; var LinesNotCopied: Integer; var MissingExCostRevLink: Boolean)
    var
        TempItemLedgEntryBuf: Record "Item Ledger Entry" temporary;
        TempTrkgItemLedgEntry: Record "Item Ledger Entry" temporary;
        FromRentalHeader: Record "TWE Rental Header";
        FromRentalLine: Record "TWE Rental Line";
        FromRentalLine2: Record "TWE Rental Line";
        ToRentalLine: Record "TWE Rental Line";
        TempFromRentalLineBuf: Record "TWE Rental Line" temporary;
        FromRentalCrMemoHeader: Record "TWE Rental Cr.Memo Header";
        TempItemTrkgEntry: Record "Reservation Entry" temporary;
        TempDocRentalLine: Record "TWE Rental Line" temporary;
        OldCrMemoDocNo: Code[20];
        OldReturnRcptDocNo: Code[20];
        OldBufDocNo: Code[20];
        NextLineNo: Integer;
        NextItemTrkgEntryNo: Integer;
        FromLineCounter: Integer;
        ToLineCounter: Integer;
        CopyItemTrkg: Boolean;
        SplitLine: Boolean;
        FillExactCostRevLink: Boolean;
    begin
        OldCrMemoDocNo := '';
        OldBufDocNo := '';
        MissingExCostRevLink := false;
        InitCurrency(ToRentalHeader."Currency Code");
        TempFromRentalLineBuf.Reset();
        TempFromRentalLineBuf.DeleteAll();
        TempItemTrkgEntry.Reset();
        TempItemTrkgEntry.DeleteAll();
        OpenWindow();

        OnBeforeCopyRentalCrMemoLinesToDoc(TempDocRentalLine, ToRentalHeader, FromRentalCrMemoLine, CopyJobData);

        // Fill sales line buffer
        if FromRentalCrMemoLine.FindSet() then
            repeat
                FromLineCounter := FromLineCounter + 1;
                if IsTimeForUpdate() then
                    Window.Update(1, FromLineCounter);
                if FromRentalCrMemoHeader."No." <> FromRentalCrMemoLine."Document No." then begin
                    FromRentalCrMemoHeader.Get(FromRentalCrMemoLine."Document No.");
                    TransferOldExtLines.ClearLineNumbers();
                end;
                FromRentalHeader.TransferFields(FromRentalCrMemoHeader);
                OnCopyRentalCrMemoLinesToDocOnAfterFromRentalHeaderTransferFields(FromRentalCrMemoHeader, FromRentalHeader);
                FillExactCostRevLink :=
                  IsRentalFillExactCostRevLink(ToRentalHeader, 3, FromRentalHeader."Currency Code");
                FromRentalLine.TransferFields(FromRentalCrMemoLine);
                FromRentalLine."Appl.-from Item Entry" := 0;
                // Reuse fields to buffer credit memo line information
                FromRentalLine."Shipment No." := FromRentalCrMemoLine."Document No.";
                FromRentalLine."Shipment Line No." := 0;
                FromRentalLine."Return Receipt No." := '';
                FromRentalLine."Return Receipt Line No." := FromRentalCrMemoLine."Line No.";
                FromRentalLine."Copied From Posted Doc." := true;

                OnBeforeCopyRentalCrMemoLinesToBuffer(FromRentalLine, FromRentalCrMemoLine, ToRentalHeader);

                SplitLine := true;
                FromRentalCrMemoLine.GetItemLedgEntries(TempItemLedgEntryBuf, true);
                if not SplitPstdRentalLinesPerILE(
                     ToRentalHeader, FromRentalHeader, TempItemLedgEntryBuf, TempFromRentalLineBuf,
                     FromRentalLine, TempDocRentalLine, NextLineNo, CopyItemTrkg, MissingExCostRevLink, FillExactCostRevLink, false)
                then
                    if CopyItemTrkg then
                        SplitLine :=
                          SplitRentalDocLinesPerItemTrkg(
                            TempItemLedgEntryBuf, TempItemTrkgEntry, TempFromRentalLineBuf,
                            FromRentalLine, TempDocRentalLine, NextLineNo, NextItemTrkgEntryNo, MissingExCostRevLink, false)
                    else
                        SplitLine := false;

                if not SplitLine then
                    CopyRentalLinesToBuffer(
                      FromRentalHeader, FromRentalLine, FromRentalLine2, TempFromRentalLineBuf,
                      ToRentalHeader, TempDocRentalLine, FromRentalCrMemoLine."Document No.", NextLineNo);
            until FromRentalCrMemoLine.Next() = 0;

        // Create sales line from buffer
        Window.Update(1, FromLineCounter);
        // Sorting according to Rental Line Document No.,Line No.
        TempFromRentalLineBuf.SetCurrentKey("Document Type", "Document No.", "Line No.");
        if TempFromRentalLineBuf.FindSet() then begin
            NextLineNo := GetLastToRentalLineNo(ToRentalHeader);
            repeat
                ToLineCounter := ToLineCounter + 1;
                if IsTimeForUpdate() then
                    Window.Update(2, ToLineCounter);
                if TempFromRentalLineBuf."Shipment No." <> OldCrMemoDocNo then begin
                    OldCrMemoDocNo := TempFromRentalLineBuf."Shipment No.";
                    OldReturnRcptDocNo := '';
                    InsertOldRentalDocNoLine(ToRentalHeader, OldCrMemoDocNo, 4, NextLineNo);
                end;
                if (TempFromRentalLineBuf."Document No." <> OldReturnRcptDocNo) and (TempFromRentalLineBuf."Shipment Line No." > 0) then begin
                    OldReturnRcptDocNo := TempFromRentalLineBuf."Document No.";
                    InsertOldRentalCombDocNoLine(ToRentalHeader, OldCrMemoDocNo, OldReturnRcptDocNo, NextLineNo, false);
                end;

                // Empty buffer fields
                FromRentalLine2 := TempFromRentalLineBuf;
                FromRentalLine2."Shipment No." := '';
                FromRentalLine2."Shipment Line No." := 0;
                FromRentalLine2."Return Receipt No." := '';
                FromRentalLine2."Return Receipt Line No." := 0;
                if GetRentalDocNo(TempDocRentalLine, TempFromRentalLineBuf."Line No.") <> OldBufDocNo then begin
                    OldBufDocNo := GetRentalDocNo(TempDocRentalLine, TempFromRentalLineBuf."Line No.");
                    TransferOldExtLines.ClearLineNumbers();
                end;

                OnCopyRentalCrMemoLinesToDocOnBeforeCopyRentalLine(ToRentalHeader, FromRentalLine2);

                if CopyRentalDocLine(
                     ToRentalHeader, ToRentalLine, FromRentalHeader,
                     FromRentalLine2, NextLineNo, LinesNotCopied, TempFromRentalLineBuf."Return Receipt No." = '',
                     "TWE Rental Document Type From".FromInteger("TWE Rental Document Type From"::"Posted Credit Memo".AsInteger()),
                     GetRentalLineNo(TempDocRentalLine, FromRentalLine2."Line No."))
                then begin
                    FromRentalCrMemoLine.Get(TempFromRentalLineBuf."Shipment No.", TempFromRentalLineBuf."Return Receipt Line No.");

                    // copy item tracking
                    if (TempFromRentalLineBuf.Type = TempFromRentalLineBuf.Type::"Rental Item") and (TempFromRentalLineBuf.Quantity <> 0) then begin
                        FromRentalCrMemoLine."Document No." := OldCrMemoDocNo;
                        FromRentalCrMemoLine."Line No." := TempFromRentalLineBuf."Return Receipt Line No.";
                        FromRentalCrMemoLine.GetItemLedgEntries(TempItemLedgEntryBuf, true);
                        if IsCopyItemTrkg(TempItemLedgEntryBuf, CopyItemTrkg, FillExactCostRevLink) then
                            if MoveNegLines or not ExactCostRevMandatory then
                                ItemTrackingDocMgt.CopyItemLedgerEntriesToTemp(TempTrkgItemLedgEntry, TempItemLedgEntryBuf)
                            else
                                ItemTrackingDocMgt.CollectItemTrkgPerPostedDocLine(
                                  TempItemTrkgEntry, TempTrkgItemLedgEntry, false, TempFromRentalLineBuf."Document No.", TempFromRentalLineBuf."Line No.");
                    end;
                    OnAfterCopyRentalLineFromRentalCrMemoLineBuffer(
                      ToRentalLine, FromRentalCrMemoLine, IncludeHeader, RecalculateLines, TempDocRentalLine, ToRentalHeader, TempFromRentalLineBuf);
                end;
            until TempFromRentalLineBuf.Next() = 0;
        end;

        Window.Close();
    end;

    local procedure CopyRentalLinesToBuffer(FromRentalHeader: Record "TWE Rental Header"; FromRentalLine: Record "TWE Rental Line"; var FromRentalLine2: Record "TWE Rental Line"; var TempRentalLineBuf: Record "TWE Rental Line" temporary; ToRentalHeader: Record "TWE Rental Header"; var TempDocRentalLine: Record "TWE Rental Line" temporary; DocNo: Code[20]; var NextLineNo: Integer)
    begin
        FromRentalLine2 := TempRentalLineBuf;
        TempRentalLineBuf := FromRentalLine;
        TempRentalLineBuf."Document No." := FromRentalLine2."Document No.";
        TempRentalLineBuf."Shipment Line No." := FromRentalLine2."Shipment Line No.";
        TempRentalLineBuf."Line No." := NextLineNo;
        OnAfterCopyRentalLinesToBufferFields(TempRentalLineBuf, FromRentalLine2);

        NextLineNo := NextLineNo + 10000;
        if not IsRecalculateAmount(
             FromRentalHeader."Currency Code", ToRentalHeader."Currency Code",
             FromRentalHeader."Prices Including VAT", ToRentalHeader."Prices Including VAT")
        then
            TempRentalLineBuf."Return Receipt No." := DocNo;
        ReCalcRentalLine(FromRentalHeader, ToRentalHeader, TempRentalLineBuf);
        OnCopyRentalLinesToBufferTransferFields(FromRentalHeader, FromRentalLine, TempRentalLineBuf);
        TempRentalLineBuf.Insert();
        AddRentalDocLine(TempDocRentalLine, TempRentalLineBuf."Line No.", DocNo, FromRentalLine."Line No.");
    end;

    local procedure CopyItemLedgEntryTrackingToRentalLine(var TempItemLedgEntry: Record "Item Ledger Entry" temporary; var TempReservationEntry: Record "Reservation Entry" temporary; TempFromRentalLine: Record "TWE Rental Line" temporary)
    var
        TempTrkgItemLedgEntry: Record "Item Ledger Entry" temporary;
    begin
        if MoveNegLines or not ExactCostRevMandatory then
            ItemTrackingDocMgt.CopyItemLedgerEntriesToTemp(TempTrkgItemLedgEntry, TempItemLedgEntry)
        else
            ItemTrackingDocMgt.CollectItemTrkgPerPostedDocLine(
              TempReservationEntry, TempTrkgItemLedgEntry, false, TempFromRentalLine."Document No.", TempFromRentalLine."Line No.");
    end;

    local procedure SplitPstdRentalLinesPerILE(ToRentalHeader: Record "TWE Rental Header"; FromRentalHeader: Record "TWE Rental Header"; var ItemLedgEntry: Record "Item Ledger Entry"; var TempRentalLineBuf: Record "TWE Rental Line" temporary; FromRentalLine: Record "TWE Rental Line"; var TempDocRentalLine: Record "TWE Rental Line" temporary; var NextLineNo: Integer; var CopyItemTrkg: Boolean; var MissingExCostRevLink: Boolean; FillExactCostRevLink: Boolean; FromShptOrRcpt: Boolean): Boolean
    var
        OrgQtyBase: Decimal;
    begin
        if FromShptOrRcpt then begin
            TempRentalLineBuf.Reset();
            TempRentalLineBuf.DeleteAll();
        end else
            TempRentalLineBuf.Init();

        CopyItemTrkg := false;

        if (FromRentalLine.Type <> FromRentalLine.Type::"Rental Item") or (FromRentalLine.Quantity = 0) then
            exit(false);
        if IsCopyItemTrkg(ItemLedgEntry, CopyItemTrkg, FillExactCostRevLink) or
           not FillExactCostRevLink or MoveNegLines or
           not ExactCostRevMandatory
        then
            exit(false);

        ItemLedgEntry.FindSet();
        if ItemLedgEntry.Quantity >= 0 then begin
            TempRentalLineBuf."Document No." := ItemLedgEntry."Document No.";
            if GetRentalDocTypeForItemLedgEntry(ItemLedgEntry) in
               [TempRentalLineBuf."Document Type"::Contract]
            then
                TempRentalLineBuf."Shipment Line No." := 1;
            exit(false);
        end;
        OrgQtyBase := FromRentalLine."Quantity (Base)";
        repeat
            if ItemLedgEntry."Shipped Qty. Not Returned" = 0 then
                SkippedLine := true;

            if ItemLedgEntry."Shipped Qty. Not Returned" < 0 then begin
                TempRentalLineBuf := FromRentalLine;

                if -ItemLedgEntry."Shipped Qty. Not Returned" < Abs(FromRentalLine."Quantity (Base)") then begin
                    if FromRentalLine."Quantity (Base)" > 0 then
                        TempRentalLineBuf."Quantity (Base)" := -ItemLedgEntry."Shipped Qty. Not Returned"
                    else
                        TempRentalLineBuf."Quantity (Base)" := ItemLedgEntry."Shipped Qty. Not Returned";
                    if TempRentalLineBuf."Qty. per Unit of Measure" = 0 then
                        TempRentalLineBuf.Quantity := TempRentalLineBuf."Quantity (Base)"
                    else
                        TempRentalLineBuf.Quantity :=
                          Round(
                            TempRentalLineBuf."Quantity (Base)" / TempRentalLineBuf."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision());
                end;
                FromRentalLine."Quantity (Base)" := FromRentalLine."Quantity (Base)" - TempRentalLineBuf."Quantity (Base)";
                FromRentalLine.Quantity := FromRentalLine.Quantity - TempRentalLineBuf.Quantity;
                TempRentalLineBuf."Appl.-from Item Entry" := ItemLedgEntry."Entry No.";
                NextLineNo := NextLineNo + 1;
                TempRentalLineBuf."Line No." := NextLineNo;
                NextLineNo := NextLineNo + 1;
                TempRentalLineBuf."Document No." := ItemLedgEntry."Document No.";
                if GetRentalDocTypeForItemLedgEntry(ItemLedgEntry) in
                   [TempRentalLineBuf."Document Type"::Contract]
                then
                    TempRentalLineBuf."Shipment Line No." := 1;

                if not FromShptOrRcpt then
                    UpdateRevRentalLineAmount(
                      TempRentalLineBuf, OrgQtyBase,
                      FromRentalHeader."Prices Including VAT", ToRentalHeader."Prices Including VAT");

                OnSplitPstdRentalLinesPerILETransferFields(FromRentalHeader, FromRentalLine, TempRentalLineBuf, ToRentalHeader);
                TempRentalLineBuf.Insert();
                AddRentalDocLine(TempDocRentalLine, TempRentalLineBuf."Line No.", ItemLedgEntry."Document No.", TempRentalLineBuf."Line No.");
            end;
        until (ItemLedgEntry.Next() = 0) or (FromRentalLine."Quantity (Base)" = 0);

        if (FromRentalLine."Quantity (Base)" <> 0) and FillExactCostRevLink then
            MissingExCostRevLink := true;
        CheckUnappliedLines(SkippedLine, MissingExCostRevLink);
        exit(true);
    end;

    local procedure SplitRentalDocLinesPerItemTrkg(var ItemLedgEntry: Record "Item Ledger Entry"; var TempItemTrkgEntry: Record "Reservation Entry" temporary; var TempRentalLineBuf: Record "TWE Rental Line" temporary; FromRentalLine: Record "TWE Rental Line"; var TempDocRentalLine: Record "TWE Rental Line" temporary; var NextLineNo: Integer; var NextItemTrkgEntryNo: Integer; var MissingExCostRevLink: Boolean; FromShptOrRcpt: Boolean): Boolean
    var
        RentalLineBuf: array[2] of Record "TWE Rental Line" temporary;
        Tracked: Boolean;
        ReversibleQtyBase: Decimal;
        SignFactor: Integer;
        i: Integer;
    begin
        if FromShptOrRcpt then begin
            TempRentalLineBuf.Reset();
            TempRentalLineBuf.DeleteAll();
            TempItemTrkgEntry.Reset();
            TempItemTrkgEntry.DeleteAll();
        end else
            TempRentalLineBuf.Init();

        if MoveNegLines or not ExactCostRevMandatory then
            exit(false);

        if FromRentalLine."Quantity (Base)" < 0 then
            SignFactor := -1
        else
            SignFactor := 1;

        ItemLedgEntry.SetCurrentKey("Document No.", "Document Type", "Document Line No.");
        ItemLedgEntry.FindSet();
        repeat
            RentalLineBuf[1] := FromRentalLine;
            RentalLineBuf[1]."Line No." := NextLineNo;
            RentalLineBuf[1]."Quantity (Base)" := 0;
            RentalLineBuf[1].Quantity := 0;
            RentalLineBuf[1]."Document No." := ItemLedgEntry."Document No.";
            if GetRentalDocTypeForItemLedgEntry(ItemLedgEntry) in
               [RentalLineBuf[1]."Document Type"::Contract]
            then
                RentalLineBuf[1]."Shipment Line No." := 1;
            RentalLineBuf[2] := RentalLineBuf[1];
            RentalLineBuf[2]."Line No." := RentalLineBuf[2]."Line No." + 1;

            if not FromShptOrRcpt then begin
                ItemLedgEntry.SetRange("Document No.", ItemLedgEntry."Document No.");
                ItemLedgEntry.SetRange("Document Type", ItemLedgEntry."Document Type");
                ItemLedgEntry.SetRange("Document Line No.", ItemLedgEntry."Document Line No.");
            end;
            repeat
                i := 1;
                if not ItemLedgEntry.Positive then
                    ItemLedgEntry."Shipped Qty. Not Returned" :=
                      ItemLedgEntry."Shipped Qty. Not Returned" -
                      CalcDistributedQty(TempItemTrkgEntry, ItemLedgEntry, RentalLineBuf[2]."Line No." + 1);
                if ItemLedgEntry."Shipped Qty. Not Returned" = 0 then
                    SkippedLine := true;

                if ItemLedgEntry."Document Type" in [ItemLedgEntry."Document Type"::"Sales Return Receipt", ItemLedgEntry."Document Type"::"Sales Credit Memo"] then
                    if ItemLedgEntry."Remaining Quantity" < FromRentalLine."Quantity (Base)" * SignFactor then
                        ReversibleQtyBase := ItemLedgEntry."Remaining Quantity" * SignFactor
                    else
                        ReversibleQtyBase := FromRentalLine."Quantity (Base)"
                else
                    if ItemLedgEntry.Positive then begin
                        ReversibleQtyBase := ItemLedgEntry."Remaining Quantity";
                        if ReversibleQtyBase < FromRentalLine."Quantity (Base)" * SignFactor then
                            ReversibleQtyBase := ReversibleQtyBase * SignFactor
                        else
                            ReversibleQtyBase := FromRentalLine."Quantity (Base)";
                    end else
                        if -ItemLedgEntry."Shipped Qty. Not Returned" < FromRentalLine."Quantity (Base)" * SignFactor then
                            ReversibleQtyBase := -ItemLedgEntry."Shipped Qty. Not Returned" * SignFactor
                        else
                            ReversibleQtyBase := FromRentalLine."Quantity (Base)";

                if ReversibleQtyBase <> 0 then begin
                    if not ItemLedgEntry.Positive then
                        if IsSplitItemLedgEntry(ItemLedgEntry) then
                            i := 2;

                    RentalLineBuf[i]."Quantity (Base)" := RentalLineBuf[i]."Quantity (Base)" + ReversibleQtyBase;
                    if RentalLineBuf[i]."Qty. per Unit of Measure" = 0 then
                        RentalLineBuf[i].Quantity := RentalLineBuf[i]."Quantity (Base)"
                    else
                        RentalLineBuf[i].Quantity :=
                          Round(
                            RentalLineBuf[i]."Quantity (Base)" / RentalLineBuf[i]."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision());
                    FromRentalLine."Quantity (Base)" := FromRentalLine."Quantity (Base)" - ReversibleQtyBase;
                    // Fill buffer with exact cost reversing link
                    InsertTempItemTrkgEntry(
                      ItemLedgEntry, TempItemTrkgEntry, -Abs(ReversibleQtyBase),
                      RentalLineBuf[i]."Line No.", NextItemTrkgEntryNo, true);
                    Tracked := true;
                end;
            until (ItemLedgEntry.Next() = 0) or (FromRentalLine."Quantity (Base)" = 0);

            for i := 1 to 2 do
                if RentalLineBuf[i]."Quantity (Base)" <> 0 then begin
                    TempRentalLineBuf := RentalLineBuf[i];
                    TempRentalLineBuf.Insert();
                    AddRentalDocLine(TempDocRentalLine, TempRentalLineBuf."Line No.", ItemLedgEntry."Document No.", FromRentalLine."Line No.");
                    NextLineNo := RentalLineBuf[i]."Line No." + 1;
                end;

            if not FromShptOrRcpt then begin
                ItemLedgEntry.SetRange("Document No.");
                ItemLedgEntry.SetRange("Document Type");
                ItemLedgEntry.SetRange("Document Line No.");
            end;
        until (ItemLedgEntry.Next() = 0) or FromShptOrRcpt;

        if (FromRentalLine."Quantity (Base)" <> 0) and not Tracked then
            MissingExCostRevLink := true;
        CheckUnappliedLines(SkippedLine, MissingExCostRevLink);

        exit(true);
    end;

    local procedure CalcDistributedQty(var TempItemTrkgEntry: Record "Reservation Entry" temporary; ItemLedgEntry: Record "Item Ledger Entry"; NextLineNo: Integer): Decimal
    begin
        TempItemTrkgEntry.Reset();
        TempItemTrkgEntry.SetCurrentKey("Source ID", "Source Ref. No.");
        TempItemTrkgEntry.SetRange("Source ID", ItemLedgEntry."Document No.");
        TempItemTrkgEntry.SetFilter("Source Ref. No.", '<%1', NextLineNo);
        TempItemTrkgEntry.SetRange("Item Ledger Entry No.", ItemLedgEntry."Entry No.");
        TempItemTrkgEntry.CalcSums("Quantity (Base)");
        TempItemTrkgEntry.Reset();
        exit(TempItemTrkgEntry."Quantity (Base)");
    end;

    [Scope('OnPrem')]
    procedure IsEntityBlocked(TableNo: Integer; CreditDocType: Boolean; Type: Option; EntityNo: Code[20]) EntityIsBlocked: Boolean
    var
        GLAccount: Record "G/L Account";
        Item: Record Item;
        Resource: Record Resource;
        ForwardLinkMgt: Codeunit "Forward Link Mgt.";
        MessageType: Option Error,Warning,Information;
        BlockedForRentalPurch: Boolean;
        IsHandled: Boolean;
    begin
        OnBeforeIsEntityBlocked(TableNo, CreditDocType, Type, EntityNo, EntityIsBlocked, IsHandled);
        if IsHandled then
            exit(EntityIsBlocked);

        if SkipWarningNotification then
            MessageType := MessageType::Error
        else
            MessageType := MessageType::Warning;
        case Type of
            "TWE Rental Line Type"::"G/L Account".AsInteger():
                if GLAccount.Get(EntityNo) then begin
                    if not GLAccount."Direct Posting" then
                        ErrorMessageMgt.LogMessage(
                          MessageType, 0, StrSubstNo(DirectPostingErr, GLAccount."No."), GLAccount, GLAccount.FieldNo("Direct Posting"), '')
                    else
                        if GLAccount.Blocked then
                            ErrorMessageMgt.LogMessage(
                              MessageType, 0, StrSubstNo(IsBlockedErr, GLAccount.TableCaption, GLAccount."No.")
                              , GLAccount, GLAccount.FieldNo(Blocked), '');
                    exit(not GLAccount."Direct Posting" or GLAccount.Blocked);
                end;
            "TWE Rental Line Type"::"Rental item".AsInteger():
                if MainRentalItem.Get(EntityNo) then begin
                    if MainRentalItem.Blocked then begin
                        ErrorMessageMgt.LogMessage(
                            MessageType, 0, StrSubstNo(IsBlockedErr, MainRentalItem.TableCaption, MainRentalItem."No."),
                            Item, MainRentalItem.FieldNo(Blocked), ForwardLinkMgt.GetHelpCodeForBlockedItem());
                        exit(true);
                    end;
                    case TableNo of
                        database::"TWE Rental Line":
                            if MainRentalItem."Sales Blocked" and not CreditDocType then begin
                                BlockedForRentalPurch := true;
                                ErrorMessageMgt.LogMessage(
                                    MessageType, 0, StrSubstNo(IsRentalBlockedItemErr, MainRentalItem."No."), Item,
                                    MainRentalItem.FieldNo("Sales Blocked"), ForwardLinkMgt.GetHelpCodeForBlockedItem());
                            end;
                        database::"Purchase Line":
                            if MainRentalItem."Purchasing Blocked" and not CreditDocType then begin
                                BlockedForRentalPurch := true;
                                ErrorMessageMgt.LogMessage(
                                    MessageType, 0, StrSubstNo(IsPurchBlockedItemErr, MainRentalItem."No."), Item,
                                    MainRentalItem.FieldNo("Purchasing Blocked"), ForwardLinkMgt.GetHelpCodeForBlockedItem());
                            end;
                        else
                            BlockedForRentalPurch := false;
                    end;
                    exit(BlockedForRentalPurch);
                end;
            "TWE Rental Line Type"::Resource.AsInteger():
                if Resource.Get(EntityNo) then begin
                    if Resource.Blocked then
                        ErrorMessageMgt.LogMessage(
                          MessageType, 0, StrSubstNo(IsBlockedErr, Resource.TableCaption, Resource."No."), Resource, Resource.FieldNo(Blocked), '');
                    exit(Resource.Blocked);
                end;
        end;
    end;

    local procedure IsItemBlocked(ItemNo: Code[20]): Boolean
    var
        localmainRentalItem: Record "TWE Main Rental Item";
    begin
        exit(localmainRentalItem.Get(ItemNo) and localmainRentalItem.Blocked);
    end;

    local procedure IsSplitItemLedgEntry(OrgItemLedgEntry: Record "Item Ledger Entry"): Boolean
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        ItemLedgEntry.SetCurrentKey("Document No.");
        ItemLedgEntry.SetRange("Document No.", OrgItemLedgEntry."Document No.");
        ItemLedgEntry.SetRange("Document Type", OrgItemLedgEntry."Document Type");
        ItemLedgEntry.SetRange("Document Line No.", OrgItemLedgEntry."Document Line No.");
        ItemLedgEntry.SetRange("Lot No.", OrgItemLedgEntry."Lot No.");
        ItemLedgEntry.SetRange("Serial No.", OrgItemLedgEntry."Serial No.");
        ItemLedgEntry.SetFilter("Entry No.", '<%1', OrgItemLedgEntry."Entry No.");
        exit(not ItemLedgEntry.IsEmpty);
    end;

    local procedure IsCopyItemTrkg(var ItemLedgEntry: Record "Item Ledger Entry"; var CopyItemTrkg: Boolean; FillExactCostRevLink: Boolean) Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIsCopyItemTrkg(ItemLedgEntry, CopyItemTrkg, FillExactCostRevLink, Result, IsHandled);
        If IsHandled then
            exit(Result);

        if ItemLedgEntry.IsEmpty() then
            exit(true);
        ItemLedgEntry.SetFilter("Lot No.", '<>''''');
        if not ItemLedgEntry.IsEmpty() then begin
            if FillExactCostRevLink then
                CopyItemTrkg := true;
            exit(true);
        end;
        ItemLedgEntry.SetRange("Lot No.");
        ItemLedgEntry.SetFilter("Serial No.", '<>''''');
        if not ItemLedgEntry.IsEmpty() then begin
            if FillExactCostRevLink then
                CopyItemTrkg := true;
            exit(true);
        end;
        ItemLedgEntry.SetRange("Serial No.");
        exit(false);
    end;

    local procedure InsertTempItemTrkgEntry(ItemLedgEntry: Record "Item Ledger Entry"; var TempItemTrkgEntry: Record "Reservation Entry"; QtyBase: Decimal; DocLineNo: Integer; var NextEntryNo: Integer; FillExactCostRevLink: Boolean)
    begin
        if QtyBase = 0 then
            exit;

        TempItemTrkgEntry.Init();
        TempItemTrkgEntry."Entry No." := NextEntryNo;
        NextEntryNo := NextEntryNo + 1;
        if not FillExactCostRevLink then
            TempItemTrkgEntry."Reservation Status" := TempItemTrkgEntry."Reservation Status"::Prospect;
        TempItemTrkgEntry."Source ID" := ItemLedgEntry."Document No.";
        TempItemTrkgEntry."Source Ref. No." := DocLineNo;
        TempItemTrkgEntry."Item Ledger Entry No." := ItemLedgEntry."Entry No.";
        TempItemTrkgEntry."Quantity (Base)" := QtyBase;
        TempItemTrkgEntry.Insert();
    end;

    local procedure GetLastToRentalLineNo(ToRentalHeader: Record "TWE Rental Header"): Decimal
    var
        ToRentalLine: Record "TWE Rental Line";
    begin
        ToRentalLine.LockTable();
        ToRentalLine.SetRange("Document Type", ToRentalHeader."Document Type");
        ToRentalLine.SetRange("Document No.", ToRentalHeader."No.");
        if ToRentalLine.FindLast() then
            exit(ToRentalLine."Line No.");
        exit(0);
    end;

    local procedure InsertOldRentalDocNoLine(ToRentalHeader: Record "TWE Rental Header"; OldDocNo: Code[20]; OldDocType: Integer; var NextLineNo: Integer)
    var
        ToRentalLine2: Record "TWE Rental Line";
        IsHandled: Boolean;
    begin
        if SkipCopyFromDescription then
            exit;

        NextLineNo := NextLineNo + 10000;
        ToRentalLine2.Init();
        ToRentalLine2."Line No." := NextLineNo;
        ToRentalLine2."Document Type" := ToRentalHeader."Document Type";
        ToRentalLine2."Document No." := ToRentalHeader."No.";

        TranslationHelper.SetGlobalLanguageByCode(ToRentalHeader."Language Code");
        if InsertCancellationLine then
            ToRentalLine2.Description := StrSubstNo(CrMemoCancellationMsg, OldDocNo)
        else
            ToRentalLine2.Description := StrSubstNo(Text015Lbl, SelectStr(OldDocType, Text013Lbl), OldDocNo);
        TranslationHelper.RestoreGlobalLanguage();

        IsHandled := false;
        OnBeforeInsertOldRentalDocNoLine(ToRentalHeader, ToRentalLine2, OldDocType, OldDocNo, IsHandled);
        if not IsHandled then
            ToRentalLine2.Insert();
    end;

    local procedure InsertOldRentalCombDocNoLine(ToRentalHeader: Record "TWE Rental Header"; OldDocNo: Code[20]; OldDocNo2: Code[20]; var NextLineNo: Integer; CopyFromInvoice: Boolean)
    var
        ToRentalLine2: Record "TWE Rental Line";
    begin
        NextLineNo := NextLineNo + 10000;
        ToRentalLine2.Init();
        ToRentalLine2."Line No." := NextLineNo;
        ToRentalLine2."Document Type" := ToRentalHeader."Document Type";
        ToRentalLine2."Document No." := ToRentalHeader."No.";

        TranslationHelper.SetGlobalLanguageByCode(ToRentalHeader."Language Code");
        if CopyFromInvoice then
            ToRentalLine2.Description :=
              StrSubstNo(
                Text018Lbl,
                CopyStr(SelectStr(1, Text016Lbl) + OldDocNo, 1, 23),
                CopyStr(SelectStr(2, Text016Lbl) + OldDocNo2, 1, 23))
        else
            ToRentalLine2.Description :=
              StrSubstNo(
                Text018Lbl,
                CopyStr(SelectStr(3, Text016Lbl) + OldDocNo, 1, 23),
                CopyStr(SelectStr(4, Text016Lbl) + OldDocNo2, 1, 23));
        TranslationHelper.RestoreGlobalLanguage();

        OnBeforeInsertOldRentalCombDocNoLine(ToRentalHeader, ToRentalLine2, CopyFromInvoice, OldDocNo, OldDocNo2);
        ToRentalLine2.Insert();
    end;

    procedure IsRentalFillExactCostRevLink(ToRentalHeader: Record "TWE Rental Header"; FromDocType: Option "Rental Shipment","Rental Invoice","Rental Return Receipt","Rental Credit Memo"; CurrencyCode: Code[10]): Boolean
    begin
        case FromDocType of
            FromDocType::"Rental Shipment":
                exit(ToRentalHeader."Document Type" in [ToRentalHeader."Document Type"::"Return Shipment", ToRentalHeader."Document Type"::"Credit Memo"]);
            FromDocType::"Rental Invoice":
                exit(
                  (ToRentalHeader."Document Type" in [ToRentalHeader."Document Type"::"Return Shipment", ToRentalHeader."Document Type"::"Credit Memo"]) and
                  (ToRentalHeader."Currency Code" = CurrencyCode));
            FromDocType::"Rental Return Receipt":
                exit(ToRentalHeader."Document Type" in [ToRentalHeader."Document Type"::Contract, ToRentalHeader."Document Type"::Invoice]);
            FromDocType::"Rental Credit Memo":
                exit(
                  (ToRentalHeader."Document Type" in [ToRentalHeader."Document Type"::Contract, ToRentalHeader."Document Type"::Invoice]) and
                  (ToRentalHeader."Currency Code" = CurrencyCode));
        end;
        exit(false);
    end;

    local procedure GetRentalDocTypeForItemLedgEntry(ItemLedgEntry: Record "Item Ledger Entry"): Enum "TWE Rental Document Type"
    begin
        case ItemLedgEntry."Document Type" of
            ItemLedgEntry."Document Type"::"Rental Shipment":
                exit("TWE Rental Document Type"::Contract);
            ItemLedgEntry."Document Type"::"Rental Invoice":
                exit("TWE Rental Document Type"::Invoice);
            ItemLedgEntry."Document Type"::"Rental Credit Memo":
                exit("TWE Rental Document Type"::"Credit Memo");
            ItemLedgEntry."Document Type"::"Sales Return Receipt":
                exit("TWE Rental Document Type"::"Return Shipment");
        end;
    end;

    local procedure GetItem(ItemNo: Code[20])
    begin
        if ItemNo <> MainRentalItem."No." then
            if not MainRentalItem.Get(ItemNo) then
                MainRentalItem.Init();
    end;

    local procedure CalcVAT(var Value: Decimal; VATPercentage: Decimal; FromPricesInclVAT: Boolean; ToPricesInclVAT: Boolean; RndgPrecision: Decimal)
    begin
        if (ToPricesInclVAT = FromPricesInclVAT) or (Value = 0) then
            exit;

        if ToPricesInclVAT then
            Value := Round(Value * (100 + VATPercentage) / 100, RndgPrecision)
        else
            Value := Round(Value * 100 / (100 + VATPercentage), RndgPrecision);
    end;

    local procedure ReCalcRentalLine(FromRentalHeader: Record "TWE Rental Header"; ToRentalHeader: Record "TWE Rental Header"; var RentalLine: Record "TWE Rental Line")
    var
        CurrExchRate: Record "Currency Exchange Rate";
        RentalLineAmount: Decimal;
    begin
        if not IsRecalculateAmount(
             FromRentalHeader."Currency Code", ToRentalHeader."Currency Code",
             FromRentalHeader."Prices Including VAT", ToRentalHeader."Prices Including VAT")
        then
            exit;

        if FromRentalHeader."Currency Code" <> ToRentalHeader."Currency Code" then begin
            if RentalLine.Quantity <> 0 then
                RentalLineAmount := RentalLine."Unit Price" * RentalLine.Quantity
            else
                RentalLineAmount := RentalLine."Unit Price";
            if FromRentalHeader."Currency Code" <> '' then begin
                RentalLineAmount :=
                  CurrExchRate.ExchangeAmtFCYToLCY(
                    FromRentalHeader."Posting Date", FromRentalHeader."Currency Code",
                    RentalLineAmount, FromRentalHeader."Currency Factor");
                RentalLine."Line Discount Amount" :=
                  CurrExchRate.ExchangeAmtFCYToLCY(
                    FromRentalHeader."Posting Date", FromRentalHeader."Currency Code",
                    RentalLine."Line Discount Amount", FromRentalHeader."Currency Factor");
                RentalLine."Inv. Discount Amount" :=
                  CurrExchRate.ExchangeAmtFCYToLCY(
                    FromRentalHeader."Posting Date", FromRentalHeader."Currency Code",
                    RentalLine."Inv. Discount Amount", FromRentalHeader."Currency Factor");
            end;

            if ToRentalHeader."Currency Code" <> '' then begin
                RentalLineAmount :=
                  CurrExchRate.ExchangeAmtLCYToFCY(
                    ToRentalHeader."Posting Date", ToRentalHeader."Currency Code", RentalLineAmount, ToRentalHeader."Currency Factor");
                RentalLine."Line Discount Amount" :=
                  CurrExchRate.ExchangeAmtLCYToFCY(
                    ToRentalHeader."Posting Date", ToRentalHeader."Currency Code", RentalLine."Line Discount Amount", ToRentalHeader."Currency Factor");
                RentalLine."Inv. Discount Amount" :=
                  CurrExchRate.ExchangeAmtLCYToFCY(
                    ToRentalHeader."Posting Date", ToRentalHeader."Currency Code", RentalLine."Inv. Discount Amount", ToRentalHeader."Currency Factor");
            end;
        end;

        RentalLine."Currency Code" := ToRentalHeader."Currency Code";
        if RentalLine.Quantity <> 0 then begin
            RentalLineAmount := Round(RentalLineAmount, Currency."Amount Rounding Precision");
            RentalLine."Unit Price" := Round(RentalLineAmount / RentalLine.Quantity, Currency."Unit-Amount Rounding Precision");
        end else
            RentalLine."Unit Price" := Round(RentalLineAmount, Currency."Unit-Amount Rounding Precision");
        RentalLine."Line Discount Amount" := Round(RentalLine."Line Discount Amount", Currency."Amount Rounding Precision");
        RentalLine."Inv. Discount Amount" := Round(RentalLine."Inv. Discount Amount", Currency."Amount Rounding Precision");

        CalcVAT(
          RentalLine."Unit Price", RentalLine."VAT %", FromRentalHeader."Prices Including VAT",
          ToRentalHeader."Prices Including VAT", Currency."Unit-Amount Rounding Precision");
        CalcVAT(
          RentalLine."Line Discount Amount", RentalLine."VAT %", FromRentalHeader."Prices Including VAT",
          ToRentalHeader."Prices Including VAT", Currency."Amount Rounding Precision");
        CalcVAT(
          RentalLine."Inv. Discount Amount", RentalLine."VAT %", FromRentalHeader."Prices Including VAT",
          ToRentalHeader."Prices Including VAT", Currency."Amount Rounding Precision");
    end;

    local procedure IsRecalculateAmount(FromCurrencyCode: Code[10]; ToCurrencyCode: Code[10]; FromPricesInclVAT: Boolean; ToPricesInclVAT: Boolean): Boolean
    begin
        exit(
          (FromCurrencyCode <> ToCurrencyCode) or
          (FromPricesInclVAT <> ToPricesInclVAT));
    end;

    local procedure UpdateRevRentalLineAmount(var RentalLine: Record "TWE Rental Line"; OrgQtyBase: Decimal; FromPricesInclVAT: Boolean; ToPricesInclVAT: Boolean)
    var
        Amount: Decimal;
    begin
        if (OrgQtyBase = 0) or (RentalLine.Quantity = 0) or
           ((FromPricesInclVAT = ToPricesInclVAT) and (OrgQtyBase = RentalLine."Quantity (Base)"))
        then
            exit;

        Amount := RentalLine.Quantity * RentalLine."Unit Price";
        CalcVAT(
          Amount, RentalLine."VAT %", FromPricesInclVAT, ToPricesInclVAT, Currency."Amount Rounding Precision");
        RentalLine."Unit Price" := Amount / RentalLine.Quantity;
        RentalLine."Line Discount Amount" :=
          Round(
            Round(RentalLine.Quantity * RentalLine."Unit Price", Currency."Amount Rounding Precision") *
            RentalLine."Line Discount %" / 100,
            Currency."Amount Rounding Precision");
        Amount :=
          Round(RentalLine."Inv. Discount Amount" / OrgQtyBase * RentalLine."Quantity (Base)", Currency."Amount Rounding Precision");
        CalcVAT(
          Amount, RentalLine."VAT %", FromPricesInclVAT, ToPricesInclVAT, Currency."Amount Rounding Precision");
        RentalLine."Inv. Discount Amount" := Amount;
    end;

    procedure CalculateRevRentalLineAmount(var RentalLine: Record "TWE Rental Line"; OrgQtyBase: Decimal; FromPricesInclVAT: Boolean; ToPricesInclVAT: Boolean)
    var
        UnitPrice: Decimal;
        LineDiscAmt: Decimal;
        InvDiscAmt: Decimal;
    begin
        UpdateRevRentalLineAmount(RentalLine, OrgQtyBase, FromPricesInclVAT, ToPricesInclVAT);

        UnitPrice := RentalLine."Unit Price";
        LineDiscAmt := RentalLine."Line Discount Amount";
        InvDiscAmt := RentalLine."Inv. Discount Amount";

        RentalLine.Validate("Unit Price", UnitPrice);
        RentalLine.Validate("Line Discount Amount", LineDiscAmt);
        RentalLine.Validate("Inv. Discount Amount", InvDiscAmt);
    end;

    local procedure InitCurrency(CurrencyCode: Code[10])
    begin
        if CurrencyCode <> '' then
            Currency.Get(CurrencyCode)
        else
            Currency.InitRoundingPrecision();

        Currency.TestField("Unit-Amount Rounding Precision");
        Currency.TestField("Amount Rounding Precision");
    end;

    local procedure OpenWindow()
    begin
        Window.Open(
          Text022Lbl +
          Text023Lbl +
          Text024Lbl);
        WindowUpdateDateTime := CurrentDateTime;
    end;

    local procedure IsTimeForUpdate(): Boolean
    begin
        if CurrentDateTime - WindowUpdateDateTime >= 1000 then begin
            WindowUpdateDateTime := CurrentDateTime;
            exit(true);
        end;
        exit(false);
    end;

    procedure ShowMessageReapply(OriginalQuantity: Boolean)
    var
        Text: Text[1024];
    begin
        Text := '';
        if SkippedLine then
            Text := Text029Lbl;
        if OriginalQuantity and ReappDone then
            if Text = '' then
                Text := Text025Lbl;
        if SomeAreFixed then
            Message(Text031Lbl);
        if Text <> '' then
            Message(Text);
    end;

    /// <summary>
    /// ArchRentalHeaderDocType.
    /// </summary>
    /// <param name="DocType">Option.</param>
    /// <returns>Return value of type Integer.</returns>
    procedure ArchRentalHeaderDocType(DocType: Option): Integer
    begin
        exit(GetRentalDocumentType("TWE Rental Document Type From".FromInteger(DocType)).AsInteger());
    end;

    local procedure CopyFromArchRentalDocDimToHdr(var ToRentalHeader: Record "TWE Rental Header"; FromRentalHeaderArchive: Record "TWE Rental Header Archive")
    begin
        ToRentalHeader."Shortcut Dimension 1 Code" := FromRentalHeaderArchive."Shortcut Dimension 1 Code";
        ToRentalHeader."Shortcut Dimension 2 Code" := FromRentalHeaderArchive."Shortcut Dimension 2 Code";
        ToRentalHeader."Dimension Set ID" := FromRentalHeaderArchive."Dimension Set ID";
    end;

    local procedure CopyFromArchRentalDocDimToLine(var ToRentalLine: Record "TWE Rental Line"; FromRentalLineArchive: Record "TWE Rental Line Archive")
    begin
        if IncludeHeader then begin
            ToRentalLine."Shortcut Dimension 1 Code" := FromRentalLineArchive."Shortcut Dimension 1 Code";
            ToRentalLine."Shortcut Dimension 2 Code" := FromRentalLineArchive."Shortcut Dimension 2 Code";
            ToRentalLine."Dimension Set ID" := FromRentalLineArchive."Dimension Set ID";
        end;
    end;

    procedure SetArchDocVal(DocOccurrencyNo: Integer; DocVersionNo: Integer)
    begin
        FromDocOccurrenceNo := DocOccurrencyNo;
        FromDocVersionNo := DocVersionNo;
    end;

    local procedure CopyArchRentalLine(var ToRentalHeader: Record "TWE Rental Header"; var ToRentalLine: Record "TWE Rental Line"; var FromRentalHeaderArchive: Record "TWE Rental Header Archive"; var FromRentalLineArchive: Record "TWE Rental Line Archive"; var NextLineNo: Integer; var LinesNotCopied: Integer; RecalculateAmount: Boolean): Boolean
    var
        VATPostingSetup: Record "VAT Posting Setup";
        FromRentalHeader: Record "TWE Rental Header";
        FromRentalLine: Record "TWE Rental Line";
        CopyThisLine: Boolean;
    begin
        CopyThisLine := true;
        OnBeforeCopyArchRentalLine(ToRentalHeader, FromRentalHeaderArchive, FromRentalLineArchive, RecalculateLines, CopyThisLine);
        if not CopyThisLine then begin
            LinesNotCopied := LinesNotCopied + 1;
            exit(false);
        end;

        if ((ToRentalHeader."Language Code" <> FromRentalHeaderArchive."Language Code") or RecalculateLines) and
           (FromRentalLineArchive."Attached to Line No." <> 0)
        then
            exit(false);

        ToRentalLine.SetRentalHeader(ToRentalHeader);
        if RecalculateLines and not FromRentalLineArchive."System-Created Entry" then
            ToRentalLine.Init()
        else
            ToRentalLine.TransferFields(FromRentalLineArchive);
        NextLineNo := NextLineNo + 10000;
        ToRentalLine."Document Type" := ToRentalHeader."Document Type";
        ToRentalLine."Document No." := ToRentalHeader."No.";
        ToRentalLine."Line No." := NextLineNo;
        ToRentalLine.Validate("Currency Code", FromRentalHeaderArchive."Currency Code");

        if RecalculateLines and not FromRentalLineArchive."System-Created Entry" then begin
            FromRentalHeader.TransferFields(FromRentalHeaderArchive, true);
            FromRentalLine.TransferFields(FromRentalLineArchive, true);
            RecalculateRentalLine(ToRentalHeader, ToRentalLine, FromRentalHeader, FromRentalLine, CopyThisLine);
        end else begin
            InitRentalLineFields(ToRentalLine);

            ToRentalLine.InitOutstanding();
            ToRentalLine.InitQtyToShip();
            ToRentalLine."VAT Difference" := FromRentalLineArchive."VAT Difference";
            if not CreateToHeader then
                ToRentalLine."Shipment Date" := ToRentalHeader."Shipment Date";
            ToRentalLine."Appl.-from Item Entry" := 0;
            ToRentalLine."Appl.-to Item Entry" := 0;

            CleanSpecialOrderDropShipmentInRentalLine(ToRentalLine);
            if RecalculateAmount and (FromRentalLineArchive."Appl.-from Item Entry" = 0) then begin
                ToRentalLine.Validate("Line Discount %", FromRentalLineArchive."Line Discount %");
                ToRentalLine.Validate(
                  "Inv. Discount Amount",
                  Round(FromRentalLineArchive."Inv. Discount Amount", Currency."Amount Rounding Precision"));
                ToRentalLine.Validate("Unit Cost (LCY)", FromRentalLineArchive."Unit Cost (LCY)");
            end;
            if VATPostingSetup.Get(ToRentalLine."VAT Bus. Posting Group", ToRentalLine."VAT Prod. Posting Group") then
                ToRentalLine."VAT Identifier" := VATPostingSetup."VAT Identifier";

            ToRentalLine.UpdateWithWarehouseShip();
            if (ToRentalLine.Type = ToRentalLine.Type::"Rental Item") and (ToRentalLine."No." <> '') then begin
                GetItem(ToRentalLine."No.");
                if (MainRentalItem."Costing Method" = MainRentalItem."Costing Method"::Standard) and not ToRentalLine.IsShipment() then
                    ToRentalLine.GetUnitCost();
            end;
        end;

        if ExactCostRevMandatory and
           (FromRentalLineArchive.Type = FromRentalLineArchive.Type::"Rental Item") and
           (FromRentalLineArchive."Appl.-from Item Entry" <> 0) and
           not MoveNegLines
        then begin
            if RecalculateAmount then begin
                ToRentalLine.Validate("Unit Price", FromRentalLineArchive."Unit Price");
                ToRentalLine.Validate(
                  "Line Discount Amount",
                  Round(FromRentalLineArchive."Line Discount Amount", Currency."Amount Rounding Precision"));
                ToRentalLine.Validate(
                  "Inv. Discount Amount",
                  Round(FromRentalLineArchive."Inv. Discount Amount", Currency."Amount Rounding Precision"));
            end;
            ToRentalLine.Validate("Appl.-from Item Entry", FromRentalLineArchive."Appl.-from Item Entry");
            if not CreateToHeader then
                if ToRentalLine."Shipment Date" = 0D then
                    InitShipmentDateInLine(ToRentalHeader, ToRentalLine);
        end;

        if MoveNegLines and (ToRentalLine.Type <> ToRentalLine.Type::" ") then begin
            ToRentalLine.Validate(Quantity, -FromRentalLineArchive.Quantity);
            ToRentalLine.Validate("Line Discount %", FromRentalLineArchive."Line Discount %");
            ToRentalLine."Appl.-to Item Entry" := FromRentalLineArchive."Appl.-to Item Entry";
            ToRentalLine."Appl.-from Item Entry" := FromRentalLineArchive."Appl.-from Item Entry";
        end;

        if not ((ToRentalHeader."Language Code" <> FromRentalHeaderArchive."Language Code") or RecalculateLines) then
            ToRentalLine."Attached to Line No." :=
              TransferOldExtLines.TransferExtendedText(
                FromRentalLineArchive."Line No.", NextLineNo, FromRentalLineArchive."Attached to Line No.")
        else
            if RentalTransferExtendedText.RentalCheckIfAnyExtText(ToRentalLine, false) then begin
                RentalTransferExtendedText.InsertRentalExtText(ToRentalLine);
                ToRentalLine.SetRange("Document Type", ToRentalLine."Document Type");
                ToRentalLine.SetRange("Document No.", ToRentalLine."Document No.");
                ToRentalLine.FindLast();
                NextLineNo := ToRentalLine."Line No.";
            end;

        if CopyThisLine then begin
            OnCopyArchRentalLineOnBeforeToRentalLineInsert(ToRentalLine, FromRentalLineArchive, RecalculateLines, NextLineNo);
            ToRentalLine.Insert();
            OnCopyArchRentalLineOnAfterToRentalLineInsert(ToRentalLine, FromRentalLineArchive, RecalculateLines);
        end else
            LinesNotCopied := LinesNotCopied + 1;

        exit(CopyThisLine);
    end;

    local procedure CheckCreditLimit(FromRentalHeader: Record "TWE Rental Header"; ToRentalHeader: Record "TWE Rental Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckCreditLimit(FromRentalHeader, ToRentalHeader, SkipTestCreditLimit, IsHandled);
        if IsHandled then
            exit;

        if SkipTestCreditLimit then
            exit;

        if IncludeHeader then
            RentalCustCheckCreditLimit.RentalHeaderCheck(FromRentalHeader)
        else
            RentalCustCheckCreditLimit.RentalHeaderCheck(ToRentalHeader);
    end;

    local procedure CheckUnappliedLines(SkippedLine: Boolean; var MissingExCostRevLink: Boolean)
    begin
        if SkippedLine and MissingExCostRevLink then begin
            if not WarningDone then
                Message(Text030Lbl);
            MissingExCostRevLink := false;
            WarningDone := true;
        end;
    end;

    procedure CopyFieldsFromOldRentalHeader(var ToRentalHeader: Record "TWE Rental Header"; OldRentalHeader: Record "TWE Rental Header")
    begin
        ToRentalHeader."No. Series" := OldRentalHeader."No. Series";
        ToRentalHeader."Posting Description" := OldRentalHeader."Posting Description";
        ToRentalHeader."Posting No." := OldRentalHeader."Posting No.";
        ToRentalHeader."Posting No. Series" := OldRentalHeader."Posting No. Series";
        ToRentalHeader."Shipping No." := OldRentalHeader."Shipping No.";
        ToRentalHeader."Shipping No. Series" := OldRentalHeader."Shipping No. Series";
        ToRentalHeader."Return Receipt No." := OldRentalHeader."Return Receipt No.";
        ToRentalHeader."Prepayment No. Series" := OldRentalHeader."Prepayment No. Series";
        ToRentalHeader."Prepayment No." := OldRentalHeader."Prepayment No.";
        ToRentalHeader."Prepmt. Posting Description" := OldRentalHeader."Prepmt. Posting Description";
        ToRentalHeader."Prepmt. Cr. Memo No." := OldRentalHeader."Prepmt. Cr. Memo No.";
        ToRentalHeader."Prepmt. Posting Description" := OldRentalHeader."Prepmt. Posting Description";
        SetSalespersonPurchaserCode(ToRentalHeader."Salesperson Code");
    end;

    local procedure CheckFromRentalHeader(RentalHeaderFrom: Record "TWE Rental Header"; RentalHeaderTo: Record "TWE Rental Header")
    begin
        RentalHeaderFrom.TestField("Rented-to Customer No.", RentalHeaderTo."Rented-to Customer No.");
        RentalHeaderFrom.TestField("Bill-to Customer No.", RentalHeaderTo."Bill-to Customer No.");
        RentalHeaderFrom.TestField("Customer Posting Group", RentalHeaderTo."Customer Posting Group");
        RentalHeaderFrom.TestField("Gen. Bus. Posting Group", RentalHeaderTo."Gen. Bus. Posting Group");
        RentalHeaderFrom.TestField("Currency Code", RentalHeaderTo."Currency Code");
        RentalHeaderFrom.TestField("Prices Including VAT", RentalHeaderTo."Prices Including VAT");

        OnAfterCheckFromRentalHeader(RentalHeaderFrom, RentalHeaderTo);
    end;

    local procedure CheckFromRentalShptHeader(RentalShipmentHeaderFrom: Record "TWE Rental Shipment Header"; RentalHeaderTo: Record "TWE Rental Header")
    begin
        RentalShipmentHeaderFrom.TestField("Rented-to Customer No.", RentalHeaderTo."Rented-to Customer No.");
        RentalShipmentHeaderFrom.TestField("Bill-to Customer No.", RentalHeaderTo."Bill-to Customer No.");
        RentalShipmentHeaderFrom.TestField("Customer Posting Group", RentalHeaderTo."Customer Posting Group");
        RentalShipmentHeaderFrom.TestField("Gen. Bus. Posting Group", RentalHeaderTo."Gen. Bus. Posting Group");
        RentalShipmentHeaderFrom.TestField("Currency Code", RentalHeaderTo."Currency Code");
        RentalShipmentHeaderFrom.TestField("Prices Including VAT", RentalHeaderTo."Prices Including VAT");

        OnAfterCheckFromRentalShptHeader(RentalShipmentHeaderFrom, RentalHeaderTo);
    end;

    local procedure CheckFromRentalInvHeader(RentalInvoiceHeaderFrom: Record "TWE Rental Invoice Header"; RentalHeaderTo: Record "TWE Rental Header")
    begin
        RentalInvoiceHeaderFrom.TestField("Rented-to Customer No.", RentalHeaderTo."Rented-to Customer No.");
        RentalInvoiceHeaderFrom.TestField("Bill-to Customer No.", RentalHeaderTo."Bill-to Customer No.");
        RentalInvoiceHeaderFrom.TestField("Customer Posting Group", RentalHeaderTo."Customer Posting Group");
        RentalInvoiceHeaderFrom.TestField("Gen. Bus. Posting Group", RentalHeaderTo."Gen. Bus. Posting Group");
        RentalInvoiceHeaderFrom.TestField("Currency Code", RentalHeaderTo."Currency Code");
        RentalInvoiceHeaderFrom.TestField("Prices Including VAT", RentalHeaderTo."Prices Including VAT");

        OnAfterCheckFromRentalInvHeader(RentalInvoiceHeaderFrom, RentalHeaderTo);
    end;

    local procedure CheckFromRentalCrMemoHeader(RentalCrMemoHeaderFrom: Record "TWE Rental Cr.Memo Header"; RentalHeaderTo: Record "TWE Rental Header")
    begin
        RentalCrMemoHeaderFrom.TestField("Rented-to Customer No.", RentalHeaderTo."Rented-to Customer No.");
        RentalCrMemoHeaderFrom.TestField("Bill-to Customer No.", RentalHeaderTo."Bill-to Customer No.");
        RentalCrMemoHeaderFrom.TestField("Customer Posting Group", RentalHeaderTo."Customer Posting Group");
        RentalCrMemoHeaderFrom.TestField("Gen. Bus. Posting Group", RentalHeaderTo."Gen. Bus. Posting Group");
        RentalCrMemoHeaderFrom.TestField("Currency Code", RentalHeaderTo."Currency Code");
        RentalCrMemoHeaderFrom.TestField("Prices Including VAT", RentalHeaderTo."Prices Including VAT");

        OnAfterCheckFromRentalCrMemoHeader(RentalCrMemoHeaderFrom, RentalHeaderTo);
    end;

    local procedure InitFromRentalLine(var FromRentalLine2: Record "TWE Rental Line"; var FromRentalLineBuf: Record "TWE Rental Line")
    begin
        // Empty buffer fields
        FromRentalLine2 := FromRentalLineBuf;
        FromRentalLine2."Shipment No." := '';
        FromRentalLine2."Shipment Line No." := 0;
        FromRentalLine2."Return Receipt No." := '';
        FromRentalLine2."Return Receipt Line No." := 0;

        OnAfterInitFromRentalLine(FromRentalLine2, FromRentalLineBuf);
    end;

    local procedure CleanSpecialOrderDropShipmentInRentalLine(var RentalLine: Record "TWE Rental Line")
    begin
        RentalLine."Purchase Order No." := '';
        RentalLine."Purch. Order Line No." := 0;
        RentalLine."Special Order Purchase No." := '';
        RentalLine."Special Order Purch. Line No." := 0;

        OnAfterCleanSpecialOrderDropShipmentInRentalLine(RentalLine);
    end;

    procedure CheckDateOrder(PostingNo: Code[20]; PostingNoSeries: Code[20]; OldPostingDate: Date; NewPostingDate: Date): Boolean
    var
        NoSeries: Record "No. Series";
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if IncludeHeader then
            if (PostingNo <> '') and (OldPostingDate <> NewPostingDate) then
                if NoSeries.Get(PostingNoSeries) then
                    if NoSeries."Date Order" then
                        exit(ConfirmManagement.GetResponseOrDefault(DiffPostDateOrderQst, true));
        exit(true)
    end;

    local procedure CheckRentalDocItselfCopy(FromRentalHeader: Record "TWE Rental Header"; ToRentalHeader: Record "TWE Rental Header")
    begin
        if (FromRentalHeader."Document Type" = ToRentalHeader."Document Type") and
           (FromRentalHeader."No." = ToRentalHeader."No.")
        then
            Error(Text001Lbl, ToRentalHeader."Document Type", ToRentalHeader."No.");
    end;

    procedure UpdateCustLedgerEntry(var ToRentalHeader: Record "TWE Rental Header"; FromDocType: Enum "Gen. Journal Document Type"; FromDocNo: Code[20])
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        OnBeforeUpdateCustLedgEntry(ToRentalHeader, CustLedgEntry);

        CustLedgEntry.SetCurrentKey("Document No.");
        if FromDocType = "TWE Rental Document Type From"::"Posted Invoice" then
            CustLedgEntry.SetRange("Document Type", CustLedgEntry."Document Type"::Invoice)
        else
            CustLedgEntry.SetRange("Document Type", CustLedgEntry."Document Type"::"Credit Memo");
        CustLedgEntry.SetRange("Document No.", FromDocNo);
        CustLedgEntry.SetRange("Customer No.", ToRentalHeader."Bill-to Customer No.");
        CustLedgEntry.SetRange(Open, true);
        if CustLedgEntry.FindFirst() then begin
            ToRentalHeader."Bal. Account No." := '';
            if FromDocType = "TWE Rental Document Type From"::"Posted Invoice" then begin
                ToRentalHeader."Applies-to Doc. Type" := ToRentalHeader."Applies-to Doc. Type"::Invoice;
                ToRentalHeader."Applies-to Doc. No." := FromDocNo;
            end else begin
                ToRentalHeader."Applies-to Doc. Type" := ToRentalHeader."Applies-to Doc. Type"::"Credit Memo";
                ToRentalHeader."Applies-to Doc. No." := FromDocNo;
            end;
            CustLedgEntry.CalcFields("Remaining Amount");
            CustLedgEntry."Amount to Apply" := CustLedgEntry."Remaining Amount";
            CustLedgEntry."Accepted Payment Tolerance" := 0;
            CustLedgEntry."Accepted Pmt. Disc. Tolerance" := false;
            CODEUNIT.Run(CODEUNIT::"Cust. Entry-Edit", CustLedgEntry);
        end;
    end;

    local procedure UpdateRentalCreditMemoHeader(var RentalHeader: Record "TWE Rental Header")
    var
        PaymentTerms: Record "Payment Terms";
    begin
        RentalHeader."Shipment Date" := 0D;
        GLSetup.Get();
        RentalHeader.Correction := GLSetup."Mark Cr. Memos as Corrections";
        if (RentalHeader."Payment Terms Code" <> '') and (RentalHeader."Document Date" <> 0D) then
            PaymentTerms.Get(RentalHeader."Payment Terms Code")
        else
            Clear(PaymentTerms);
        if not PaymentTerms."Calc. Pmt. Disc. on Cr. Memos" then begin
            RentalHeader."Payment Discount %" := 0;
            RentalHeader."Pmt. Discount Date" := 0D;
        end;
    end;

    local procedure UpdateRentalInvoiceDiscountValue(var RentalHeader: Record "TWE Rental Header")
    begin
        if IncludeHeader and RecalculateLines then begin
            RentalHeader.CalcFields(Amount);
            if RentalHeader."Invoice Discount Value" > RentalHeader.Amount then begin
                RentalHeader."Invoice Discount Value" := RentalHeader.Amount;
                RentalHeader.Modify();
            end;
        end;
    end;

    local procedure ExtTxtAttachedToPosRentalLine(RentalHeader: Record "TWE Rental Header"; MoveNegLines: Boolean; AttachedToLineNo: Integer): Boolean
    var
        AttachedToRentalLine: Record "TWE Rental Line";
    begin
        if MoveNegLines then
            if AttachedToLineNo <> 0 then
                if AttachedToRentalLine.Get(RentalHeader."Document Type", RentalHeader."No.", AttachedToLineNo) then
                    if AttachedToRentalLine.Quantity >= 0 then
                        exit(true);

        exit(false);
    end;

    local procedure RentalDocCanReceiveTracking(RentalHeader: Record "TWE Rental Header"): Boolean
    begin
        exit(
          (RentalHeader."Document Type" <> RentalHeader."Document Type"::Quote));
    end;

    local procedure CheckFirstLineShipped(DocNo: Code[20]; ShipmentLineNo: Integer; var RentalCombDocLineNo: Integer; var NextLineNo: Integer; var FirstLineShipped: Boolean)
    begin
        if (DocNo = '') and (ShipmentLineNo = 0) and FirstLineShipped then begin
            FirstLineShipped := false;
            RentalCombDocLineNo := NextLineNo;
            NextLineNo := NextLineNo + 10000;
        end;
    end;

    local procedure SetTempRentalInvLine(FromRentalInvLine: Record "TWE Rental Invoice Line"; var TempRentalInvLine: Record "TWE Rental Invoice Line" temporary; var RentalInvLineCount: Integer; var NextLineNo: Integer; var FirstLineText: Boolean)
    begin
        if FromRentalInvLine.Type = FromRentalInvLine.Type::"Rental Item" then begin
            RentalInvLineCount += 1;
            TempRentalInvLine := FromRentalInvLine;
            TempRentalInvLine.Insert();
            if FirstLineText then begin
                NextLineNo := NextLineNo + 10000;
                FirstLineText := false;
            end;
        end else
            if FromRentalInvLine.Type = FromRentalInvLine.Type::" " then
                FirstLineText := true;
    end;

    procedure InitAndCheckRentalDocuments(FromDocType: Option; FromDocNo: Code[20]; var FromRentalHeader: Record "TWE Rental Header"; var ToRentalHeader: Record "TWE Rental Header"; var ToRentalLine: Record "TWE Rental Line"; var FromRentalShipmentHeader: Record "TWE Rental Shipment Header"; var FromRentalInvoiceHeader: Record "TWE Rental Invoice Header"; var FromReturnReceiptHeader: Record "Return Receipt Header"; var FromRentalCrMemoHeader: Record "TWE Rental Cr.Memo Header"; var FromRentalHeaderArchive: Record "TWE Rental Header Archive"): Boolean
    var
        FromDocType2: Enum "TWE Rental Document Type From";
    begin
        FromDocType2 := "TWE Rental Document Type From".FromInteger(FromDocType);
        case FromDocType2 of
            "TWE Rental Document Type From"::Quote,
            "TWE Rental Document Type From"::Contract,
            "TWE Rental Document Type From"::Invoice,
            "TWE Rental Document Type From"::"Return Shipment",
            "TWE Rental Document Type From"::"Credit Memo":
                begin
                    FromRentalHeader.Get(GetRentalDocumentType(FromDocType2), FromDocNo);
                    if not CheckDateOrder(
                         ToRentalHeader."Posting No.", ToRentalHeader."Posting No. Series",
                         ToRentalHeader."Posting Date", FromRentalHeader."Posting Date")
                    then
                        exit(false);
                    if MoveNegLines then
                        DeleteRentalLinesWithNegQty(FromRentalHeader, true);
                    CheckRentalDocItselfCopy(ToRentalHeader, FromRentalHeader);

                    if ToRentalHeader."Document Type".AsInteger() <= ToRentalHeader."Document Type"::Invoice.AsInteger() then begin
                        FromRentalHeader.CalcFields("Amount Including VAT");
                        ToRentalHeader."Amount Including VAT" := FromRentalHeader."Amount Including VAT";
                        CheckCreditLimit(FromRentalHeader, ToRentalHeader);
                    end;
                    CheckCopyFromRentalHeaderAvail(FromRentalHeader, ToRentalHeader);

                    if not IncludeHeader and not RecalculateLines then
                        CheckFromRentalHeader(FromRentalHeader, ToRentalHeader);
                end;
            "TWE Rental Document Type From"::"Posted Shipment":
                begin
                    FromRentalShipmentHeader.Get(FromDocNo);
                    if not CheckDateOrder(
                         ToRentalHeader."Posting No.", ToRentalHeader."Posting No. Series",
                         ToRentalHeader."Posting Date", FromRentalShipmentHeader."Posting Date")
                    then
                        exit(false);
                    CheckCopyFromRentalShptAvail(FromRentalShipmentHeader, ToRentalHeader);

                    if not IncludeHeader and not RecalculateLines then
                        CheckFromRentalShptHeader(FromRentalShipmentHeader, ToRentalHeader);
                end;
            "TWE Rental Document Type From"::"Posted Invoice":
                begin
                    FromRentalInvoiceHeader.Get(FromDocNo);
                    FromRentalInvoiceHeader.TestField("Prepayment Invoice", false);
                    WarnRentalInvoicePmtDisc(ToRentalHeader, FromDocType2, FromDocNo);
                    if not CheckDateOrder(
                         ToRentalHeader."Posting No.", ToRentalHeader."Posting No. Series",
                         ToRentalHeader."Posting Date", FromRentalInvoiceHeader."Posting Date")
                    then
                        exit(false);
                    if ToRentalHeader."Document Type".AsInteger() <= ToRentalHeader."Document Type"::Invoice.AsInteger() then begin
                        FromRentalInvoiceHeader.CalcFields("Amount Including VAT");
                        ToRentalHeader."Amount Including VAT" := FromRentalInvoiceHeader."Amount Including VAT";
                        if IncludeHeader then
                            FromRentalHeader.TransferFields(FromRentalInvoiceHeader);
                        CheckCreditLimit(FromRentalHeader, ToRentalHeader);
                    end;
                    CheckCopyFromRentalInvoiceAvail(FromRentalInvoiceHeader, ToRentalHeader);

                    if not IncludeHeader and not RecalculateLines then
                        CheckFromRentalInvHeader(FromRentalInvoiceHeader, ToRentalHeader);
                end;
            "TWE Rental Document Type From"::"Posted Credit Memo":
                begin
                    FromRentalCrMemoHeader.Get(FromDocNo);
                    FromRentalCrMemoHeader.TestField("Prepayment Credit Memo", false);
                    WarnRentalInvoicePmtDisc(ToRentalHeader, FromDocType2, FromDocNo);
                    if not CheckDateOrder(
                         ToRentalHeader."Posting No.", ToRentalHeader."Posting No. Series",
                         ToRentalHeader."Posting Date", FromRentalCrMemoHeader."Posting Date")
                    then
                        exit(false);
                    if ToRentalHeader."Document Type".AsInteger() <= ToRentalHeader."Document Type"::Invoice.AsInteger() then begin
                        FromRentalCrMemoHeader.CalcFields("Amount Including VAT");
                        ToRentalHeader."Amount Including VAT" := FromRentalCrMemoHeader."Amount Including VAT";
                        if IncludeHeader then
                            FromRentalHeader.TransferFields(FromRentalCrMemoHeader);
                        CheckCreditLimit(FromRentalHeader, ToRentalHeader);
                    end;
                    CheckCopyFromRentalCrMemoAvail(FromRentalCrMemoHeader, ToRentalHeader);

                    if not IncludeHeader and not RecalculateLines then
                        CheckFromRentalCrMemoHeader(FromRentalCrMemoHeader, ToRentalHeader);
                end;
            "TWE Rental Document Type From"::"Arch. Quote",
            "TWE Rental Document Type From"::"Arch. Contract":
                begin
                    FromRentalHeaderArchive.Get(GetRentalDocumentType(FromDocType2), FromDocNo, FromDocOccurrenceNo, FromDocVersionNo);
                    if FromDocType2.AsInteger() <= "TWE Rental Document Type From"::Invoice.AsInteger() then begin
                        FromRentalHeaderArchive.CalcFields("Amount Including VAT");
                        ToRentalHeader."Amount Including VAT" := FromRentalHeaderArchive."Amount Including VAT";
                        //RentalCustCheckCreditLimit.RentalHeaderCheck(ToRentalHeader);
                    end;

                    CheckCopyFromRentalHeaderArchiveAvail(FromRentalHeaderArchive, ToRentalHeader);

                    if not IncludeHeader and not RecalculateLines then begin
                        FromRentalHeaderArchive.TestField("Rented-to Customer No.", ToRentalHeader."Rented-to Customer No.");
                        FromRentalHeaderArchive.TestField("Bill-to Customer No.", ToRentalHeader."Bill-to Customer No.");
                        FromRentalHeaderArchive.TestField("Customer Posting Group", ToRentalHeader."Customer Posting Group");
                        FromRentalHeaderArchive.TestField("Gen. Bus. Posting Group", ToRentalHeader."Gen. Bus. Posting Group");
                        FromRentalHeaderArchive.TestField("Currency Code", ToRentalHeader."Currency Code");
                        FromRentalHeaderArchive.TestField("Prices Including VAT", ToRentalHeader."Prices Including VAT");
                    end;
                end;
        end;
        OnAfterInitAndCheckRentalDocuments(
            FromDocType, FromDocNo, FromDocOccurrenceNo, FromDocVersionNo,
            FromRentalHeader, ToRentalHeader, ToRentalLine,
            FromRentalShipmentHeader, FromRentalInvoiceHeader, FromRentalCrMemoHeader, FromRentalHeaderArchive,
            IncludeHeader, RecalculateLines);

        exit(true);
    end;

    local procedure InitRentalLineFields(var ToRentalLine: Record "TWE Rental Line")
    begin
        OnBeforeInitRentalLineFields(ToRentalLine);

        if ToRentalLine."Document Type" <> ToRentalLine."Document Type"::Contract then begin
            ToRentalLine."Prepayment %" := 0;
            ToRentalLine."Prepayment VAT %" := 0;
            ToRentalLine."Prepmt. VAT Calc. Type" := "Tax Calculation Type"::"Normal VAT";
            ToRentalLine."Prepayment VAT Identifier" := '';
            ToRentalLine."Prepayment VAT %" := 0;
            ToRentalLine."Prepayment Tax Group Code" := '';
            ToRentalLine."Prepmt. Line Amount" := 0;
            ToRentalLine."Prepmt. Amt. Incl. VAT" := 0;
        end;
        ToRentalLine."Prepmt. Amt. Inv." := 0;
        ToRentalLine."Prepmt. Amount Inv. (LCY)" := 0;
        ToRentalLine."Prepayment Amount" := 0;
        ToRentalLine."Prepmt. VAT Base Amt." := 0;
        ToRentalLine."Prepmt Amt to Deduct" := 0;
        ToRentalLine."Prepmt Amt Deducted" := 0;
        ToRentalLine."Prepmt. Amount Inv. Incl. VAT" := 0;
        ToRentalLine."Prepayment VAT Difference" := 0;
        ToRentalLine."Prepmt VAT Diff. to Deduct" := 0;
        ToRentalLine."Prepmt VAT Diff. Deducted" := 0;
        ToRentalLine."Prepmt. Amt. Incl. VAT" := 0;
        ToRentalLine."Prepmt. VAT Amount Inv. (LCY)" := 0;
        ToRentalLine."Quantity Shipped" := 0;
        ToRentalLine."Qty. Shipped (Base)" := 0;
        ToRentalLine."Quantity Invoiced" := 0;
        ToRentalLine."Qty. Invoiced (Base)" := 0;
        ToRentalLine."Reserved Quantity" := 0;
        ToRentalLine."Reserved Qty. (Base)" := 0;
        ToRentalLine."Qty. to Ship" := 0;
        ToRentalLine."Qty. to Ship (Base)" := 0;
        /*         ToRentalLine."Return Qty. to Receive" := 0;
                ToRentalLine."Return Qty. to Receive (Base)" := 0; */
        ToRentalLine."Qty. to Invoice" := 0;
        ToRentalLine."Qty. to Invoice (Base)" := 0;
        ToRentalLine."Qty. Shipped Not Invoiced" := 0;
        ToRentalLine."Shipped Not Invoiced" := 0;
        ToRentalLine."Qty. Shipped Not Invd. (Base)" := 0;
        ToRentalLine."Shipped Not Invoiced (LCY)" := 0;

        OnAfterInitRentalLineFields(ToRentalLine);
    end;

    local procedure CopyRentalLineExtText(ToRentalHeader: Record "TWE Rental Header"; var ToRentalLine: Record "TWE Rental Line"; FromRentalHeader: Record "TWE Rental Header"; FromRentalLine: Record "TWE Rental Line"; DocLineNo: Integer; var NextLineNo: Integer)
    var
        ToRentalLine2: Record "TWE Rental Line";
        IsHandled: Boolean;
        CopyExtText: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyRentalLineExtText(ToRentalHeader, ToRentalLine, FromRentalHeader, FromRentalLine, DocLineNo, NextLineNo, IsHandled);
        if IsHandled then
            exit;

        if (ToRentalHeader."Language Code" <> FromRentalHeader."Language Code") or RecalculateLines or CopyExtText then
            if RentalTransferExtendedText.RentalCheckIfAnyExtText(ToRentalLine, false) then begin
                RentalTransferExtendedText.InsertRentalExtText(ToRentalLine);
                ToRentalLine2.SetRange("Document Type", ToRentalLine."Document Type");
                ToRentalLine2.SetRange("Document No.", ToRentalLine."Document No.");
                ToRentalLine2.FindLast();
                NextLineNo := ToRentalLine2."Line No.";
                exit;
            end;

        ToRentalLine."Attached to Line No." :=
          TransferOldExtLines.TransferExtendedText(DocLineNo, NextLineNo, FromRentalLine."Attached to Line No.");
    end;

    procedure CopyRentalLinesToDoc(FromDocType: Option; ToRentalHeader: Record "TWE Rental Header"; var FromRentalShipmentLine: Record "TWE Rental Shipment Line"; var FromRentalInvoiceLine: Record "TWE Rental Invoice Line"; var FromRentalCrMemoLine: Record "TWE Rental Cr.Memo Line"; var LinesNotCopied: Integer; var MissingExCostRevLink: Boolean)
    begin
        OnBeforeCopyRentalLinesToDoc(
          FromDocType, ToRentalHeader, FromRentalShipmentLine, FromRentalInvoiceLine, FromRentalCrMemoLine,
          LinesNotCopied, MissingExCostRevLink);
        case FromDocType of
            "TWE Rental Document Type From"::"Posted Shipment".AsInteger():
                CopyRentalShptLinesToDoc(ToRentalHeader, FromRentalShipmentLine, LinesNotCopied, MissingExCostRevLink);
            "TWE Rental Document Type From"::"Posted Invoice".AsInteger():
                CopyRentalInvLinesToDoc(ToRentalHeader, FromRentalInvoiceLine, LinesNotCopied, MissingExCostRevLink);
            "TWE Rental Document Type From"::"Posted Credit Memo".AsInteger():
                CopyRentalCrMemoLinesToDoc(ToRentalHeader, FromRentalCrMemoLine, LinesNotCopied, MissingExCostRevLink);
        end;
        OnAfterCopyRentalLinesToDoc(
          FromDocType, ToRentalHeader, FromRentalShipmentLine, FromRentalInvoiceLine, FromRentalCrMemoLine,
          LinesNotCopied, MissingExCostRevLink);
    end;

    local procedure CopyShiptoCodeFromInvToCrMemo(var ToRentalHeader: Record "TWE Rental Header"; FromRentalInvHeader: Record "TWE Rental Invoice Header"; FromDocType: Enum "TWE Rental Document Type From")
    begin
        if (FromDocType = "TWE Rental Document Type From"::"Posted Invoice") and
           (FromRentalInvHeader."Ship-to Code" <> '') and
           (ToRentalHeader."Document Type" = ToRentalHeader."Document Type"::"Credit Memo")
        then
            ToRentalHeader."Ship-to Code" := FromRentalInvHeader."Ship-to Code";
    end;

    local procedure TransferFieldsFromCrMemoToInv(var ToRentalHeader: Record "TWE Rental Header"; FromRentalCrMemoHeader: Record "TWE Rental Cr.Memo Header")
    begin
        ToRentalHeader.Validate("Rented-to Customer No.", FromRentalCrMemoHeader."Rented-to Customer No.");
        ToRentalHeader.TransferFields(FromRentalCrMemoHeader, false);
        if (ToRentalHeader."Document Type" = ToRentalHeader."Document Type"::Invoice) and IncludeHeader then begin
            ToRentalHeader.CopySellToAddressToShipToAddress();
            ToRentalHeader.Validate("Ship-to Code", FromRentalCrMemoHeader."Ship-to Code");
        end;

        OnAfterTransferFieldsFromCrMemoToInv(ToRentalHeader, FromRentalCrMemoHeader, CopyJobData);
    end;

    local procedure SetSalespersonPurchaserCode(var SalespersonPurchaserCode: Code[20])
    begin
        if SalespersonPurchaserCode <> '' then
            if SalespersonPurchaser.Get(SalespersonPurchaserCode) then
                if SalespersonPurchaser.VerifySalesPersonPurchaserPrivacyBlocked(SalespersonPurchaser) then
                    SalespersonPurchaserCode := ''
    end;


    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyRentalDocument(FromDocumentType: Option; FromDocumentNo: Code[20]; var ToRentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyRentalLine(var ToRentalHeader: Record "TWE Rental Header"; FromRentalHeader: Record "TWE Rental Header"; FromRentalLine: Record "TWE Rental Line"; RecalculateAmount: Boolean; var CopyThisLine: Boolean; MoveNegLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyArchRentalLine(var ToRentalHeader: Record "TWE Rental Header"; FromRentalHeaderArchive: Record "TWE Rental Header Archive"; FromRentalLineArchive: Record "TWE Rental Line Archive"; RecalculateAmount: Boolean; var CopyThisLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyRentalHeader(var ToRentalHeader: Record "TWE Rental Header"; FromDocType: Option; FromDocNo: Code[20]; IncludeHeader: Boolean; FromDocOccurenceNo: Integer; FromDocVersionNo: Integer; RecalculateLines: Boolean)
    begin
    end;

    local procedure AddRentalDocLine(var TempDocRentalLine: Record "TWE Rental Line" temporary; BufferLineNo: Integer; DocumentNo: Code[20]; DocumentLineNo: Integer)
    begin
        OnBeforeAddRentalDocLine(TempDocRentalLine, BufferLineNo, DocumentNo, DocumentLineNo);

        TempDocRentalLine."Document No." := DocumentNo;
        TempDocRentalLine."Line No." := DocumentLineNo;
        TempDocRentalLine."Shipment Line No." := BufferLineNo;
        TempDocRentalLine.Insert();
    end;

    local procedure GetRentalLineNo(var TempDocRentalLine: Record "TWE Rental Line" temporary; BufferLineNo: Integer): Integer
    begin
        TempDocRentalLine.SetRange("Shipment Line No.", BufferLineNo);
        if not TempDocRentalLine.FindFirst() then
            exit(0);
        exit(TempDocRentalLine."Line No.");
    end;

    local procedure GetRentalDocNo(var TempDocRentalLine: Record "TWE Rental Line" temporary; BufferLineNo: Integer): Code[20]
    begin
        TempDocRentalLine.SetRange("Shipment Line No.", BufferLineNo);
        if not TempDocRentalLine.FindFirst() then
            exit('');
        exit(TempDocRentalLine."Document No.");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAddRentalDocLine(var TempDocRentalLine: Record "TWE Rental Line" temporary; BufferLineNo: Integer; DocumentNo: Code[20]; DocumentLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyRentalShptLinesToDoc(var TempDocRentalLine: Record "TWE Rental Line" temporary; var ToRentalHeader: Record "TWE Rental Header"; var FromRentalShptLine: Record "TWE Rental Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyRentalShptLinesToBuffer(var FromRentalLine: Record "TWE Rental Line"; var FromRentalShptLine: Record "TWE Rental Shipment Line"; var ToRentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyRentalInvLines(var TempDocRentalLine: Record "TWE Rental Line" temporary; var ToRentalHeader: Record "TWE Rental Header"; var FromRentalInvLine: Record "TWE Rental Invoice Line"; var CopyJobData: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyRentalInvLinesToBuffer(var FromRentalLine: Record "TWE Rental Line"; var FromRentalInvLine: Record "TWE Rental Invoice Line"; var ToRentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyRentalCrMemoLinesToDoc(var TempDocRentalLine: Record "TWE Rental Line" temporary; var ToRentalHeader: Record "TWE Rental Header"; var FromRentalCrMemoLine: Record "TWE Rental Cr.Memo Line"; var CopyJobData: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyRentalCrMemoLinesToBuffer(var FromRentalLine: Record "TWE Rental Line"; var FromRentalCrMemoLine: Record "TWE Rental Cr.Memo Line"; var ToRentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyRentalLinesToDoc(FromDocType: Option; var ToRentalHeader: Record "TWE Rental Header"; var FromRentalShipmentLine: Record "TWE Rental Shipment Line"; var FromRentalInvoiceLine: Record "TWE Rental Invoice Line"; var FromRentalCrMemoLine: Record "TWE Rental Cr.Memo Line"; var LinesNotCopied: Integer; var MissingExCostRevLink: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyRentalLineExtText(ToRentalHeader: Record "TWE Rental Header"; var ToRentalLine: Record "TWE Rental Line"; FromRentalHeader: Record "TWE Rental Header"; FromRentalLine: Record "TWE Rental Line"; DocLineNo: Integer; var NextLineNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyRentalDocForInvoiceCancelling(var ToRentalHeader: Record "TWE Rental Header"; FromDocNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyRentalDocForCrMemoCancelling(var ToRentalHeader: Record "TWE Rental Header"; FromDocNo: Code[20]; var CopyJobData: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteNegRentalLines(FromDocType: Option; FromDocNo: Code[20]; var ToRentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsEntityBlocked(TableNo: Integer; CreditDocType: Boolean; Type: Option; EntityNo: Code[20]; var EntityIsBlocked: Boolean; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetShipmentDateInLine(RentalHeader: Record "TWE Rental Header"; var RentalLine: Record "TWE Rental Line")
    begin
    end;


    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateRentalLine(var ToRentalHeader: Record "TWE Rental Header"; var ToRentalLine: Record "TWE Rental Line"; var FromRentalHeader: Record "TWE Rental Header"; var FromRentalLine: Record "TWE Rental Line"; var CopyThisLine: Boolean; RecalculateAmount: Boolean; FromRentalDocType: Option)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRecalculateRentalLine(var ToRentalHeader: Record "TWE Rental Header"; var ToRentalLine: Record "TWE Rental Line"; var FromRentalHeader: Record "TWE Rental Header"; var FromRentalLine: Record "TWE Rental Line"; var CopyThisLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckFromRentalHeader(RentalHeaderFrom: Record "TWE Rental Header"; RentalHeaderTo: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckFromRentalShptHeader(RentalShipmentHeaderFrom: Record "TWE Rental Shipment Header"; RentalHeaderTo: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckFromRentalInvHeader(RentalInvoiceHeaderFrom: Record "TWE Rental Invoice Header"; RentalHeaderTo: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckFromRentalCrMemoHeader(RentalCrMemoHeaderFrom: Record "TWE Rental Cr.Memo Header"; RentalHeaderTo: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyArchRentalLine(ToRentalHeader: Record "TWE Rental Header"; var ToRentalLine: Record "TWE Rental Line"; FromRentalLineArchive: Record "TWE Rental Line Archive"; IncludeHeader: Boolean; RecalculateLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyPostedShipment(var ToRentalHeader: Record "TWE Rental Header"; OldRentalHeader: Record "TWE Rental Header"; FromRentalShipmentHeader: Record "TWE Rental Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyRentalDocument(FromDocumentType: Option; FromDocumentNo: Code[20]; var ToRentalHeader: Record "TWE Rental Header"; FromDocOccurenceNo: Integer; FromDocVersionNo: Integer; IncludeHeader: Boolean; RecalculateLines: Boolean; MoveNegLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyRentalHeaderArchive(var ToRentalHeader: Record "TWE Rental Header"; OldRentalHeader: Record "TWE Rental Header"; FromRentalHeaderArchive: Record "TWE Rental Header Archive")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyRentalHeaderDone(var ToRentalHeader: Record "TWE Rental Header"; OldRentalHeader: Record "TWE Rental Header"; FromRentalHeader: Record "TWE Rental Header"; FromRentalShipmentHeader: Record "TWE Rental Shipment Header"; FromRentalInvoiceHeader: Record "TWE Rental Invoice Header"; FromReturnReceiptHeader: Record "Return Receipt Header"; FromRentalCrMemoHeader: Record "TWE Rental Cr.Memo Header"; FromRentalHeaderArchive: Record "TWE Rental Header Archive")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyRentalHeaderDone(var ToRentalHeader: Record "TWE Rental Header"; FromRentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyRentalInvLine(var TempDocRentalLine: Record "TWE Rental Line" temporary; var ToRentalHeader: Record "TWE Rental Header"; var FromRentalLineBuf: Record "TWE Rental Line"; var FromRentalInvLine: Record "TWE Rental Invoice Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyRentalLinesToBufferFields(var TempRentalLine: Record "TWE Rental Line" temporary; FromRentalLine: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyRentalLinesToDoc(FromDocType: Option; var ToRentalHeader: Record "TWE Rental Header"; var FromRentalShipmentLine: Record "TWE Rental Shipment Line"; var FromRentalInvoiceLine: Record "TWE Rental Invoice Line"; var FromRentalCrMemoLine: Record "TWE Rental Cr.Memo Line"; var LinesNotCopied: Integer; var MissingExCostRevLink: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyServContractLines(ToServiceContractHeader: Record "Service Contract Header"; FromDocType: Option; FromDocNo: Code[20]; var FormServiceContractLine: Record "Service Contract Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitFromRentalLine(var FromRentalLine2: Record "TWE Rental Line"; var FromRentalLineBuf: Record "TWE Rental Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterProcessServContractLine(var ToServContractLine: Record "Service Contract Line"; FromServContractLine: Record "Service Contract Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRecalculateRentalLine(var ToRentalHeader: Record "TWE Rental Header"; var ToRentalLine: Record "TWE Rental Line"; var FromRentalHeader: Record "TWE Rental Header"; var FromRentalLine: Record "TWE Rental Line"; var CopyThisLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFieldsFromCrMemoToInv(var ToRentalHeader: Record "TWE Rental Header"; FromRentalCrMemoHeader: Record "TWE Rental Cr.Memo Header"; var CopyJobData: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateRentalLine(var ToRentalHeader: Record "TWE Rental Header"; var ToRentalLine: Record "TWE Rental Line"; var FromRentalHeader: Record "TWE Rental Header"; var FromRentalLine: Record "TWE Rental Line"; var CopyThisLine: Boolean; RecalculateAmount: Boolean; FromRentalDocType: Option)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateRentalLine(var ToRentalLine: Record "TWE Rental Line"; var FromRentalLine: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyRentalDocWithHeader(FromDocType: Option; FromDocNo: Code[20]; var ToRentalHeader: Record "TWE Rental Header"; FromDocOccurenceNo: Integer; FromDocVersionNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitAndCheckRentalDocuments(FromDocType: Option; FromDocNo: Code[20]; FromDocOccurrenceNo: Integer; FromDocVersionNo: Integer; var FromRentalHeader: Record "TWE Rental Header"; var ToRentalHeader: Record "TWE Rental Header"; var ToRentalLine: Record "TWE Rental Line"; var FromRentalShipmentHeader: Record "TWE Rental Shipment Header"; var FromRentalInvoiceHeader: Record "TWE Rental Invoice Header"; var FromRentalCrMemoHeader: Record "TWE Rental Cr.Memo Header"; var FromRentalHeaderArchive: Record "TWE Rental Header Archive"; IncludeHeader: Boolean; RecalculateLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitRentalLineFields(var RentalLine: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitToRentalLine(var ToRentalLine: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitRentalLineFields(var RentalLine: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertToRentalLine(var ToRentalLine: Record "TWE Rental Line"; FromRentalLine: Record "TWE Rental Line"; FromDocType: Option; RecalcLines: Boolean; var ToRentalHeader: Record "TWE Rental Header"; DocLineNo: Integer; var NextLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertOldRentalDocNoLine(var ToRentalHeader: Record "TWE Rental Header"; var ToRentalLine: Record "TWE Rental Line"; OldDocType: Option; OldDocNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertOldRentalCombDocNoLine(var ToRentalHeader: Record "TWE Rental Header"; var ToRentalLine: Record "TWE Rental Line"; CopyFromInvoice: Boolean; OldDocNo: Code[20]; OldDocNo2: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowRentalDoc(var ToRentalHeader: Record "TWE Rental Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateCustLedgEntry(var ToRentalHeader: Record "TWE Rental Header"; var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertToRentalLine(var ToRentalLine: Record "TWE Rental Line"; FromRentalLine: Record "TWE Rental Line"; RecalculateLines: Boolean; DocLineNo: Integer; FromRentalDocType: Enum "TWE Rental Document Type From")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyRentalHeader(var ToRentalHeader: Record "TWE Rental Header"; OldRentalHeader: Record "TWE Rental Header"; FromRentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCleanSpecialOrderDropShipmentInRentalLine(var RentalLine: Record "TWE Rental Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyRentalLineFromRentalDocRentalLine(ToRentalHeader: Record "TWE Rental Header"; var ToRentalLine: Record "TWE Rental Line"; var FromRentalLine: Record "TWE Rental Line"; IncludeHeader: Boolean; RecalculateLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyRentalLineFromRentalLineBuffer(var ToRentalLine: Record "TWE Rental Line"; FromRentalInvLine: Record "TWE Rental Invoice Line"; IncludeHeader: Boolean; RecalculateLines: Boolean; var TempDocRentalLine: Record "TWE Rental Line" temporary; ToRentalHeader: Record "TWE Rental Header"; FromRentalLineBuf: Record "TWE Rental Line"; var FromRentalLine2: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyRentalLineFromRentalCrMemoLineBuffer(var ToRentalLine: Record "TWE Rental Line"; FromRentalCrMemoLine: Record "TWE Rental Cr.Memo Line"; IncludeHeader: Boolean; RecalculateLines: Boolean; var TempDocRentalLine: Record "TWE Rental Line" temporary; ToRentalHeader: Record "TWE Rental Header"; FromRentalLineBuf: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyRentalLineFromRentalShptLineBuffer(var ToRentalLine: Record "TWE Rental Line"; FromRentalShipmentLine: Record "TWE Rental Shipment Line"; IncludeHeader: Boolean; RecalculateLines: Boolean; var TempDocRentalLine: Record "TWE Rental Line" temporary; ToRentalHeader: Record "TWE Rental Header"; FromRentalLineBuf: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFieldsFromOldRentalHeader(var ToRentalHeader: Record "TWE Rental Header"; OldRentalHeader: Record "TWE Rental Header"; MoveNegLines: Boolean; IncludeHeader: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckCreditLimit(FromRentalHeader: Record "TWE Rental Header"; ToRentalHeader: Record "TWE Rental Header"; var SkipTestCreditLimit: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsCopyItemTrkg(var ItemLedgEntry: Record "Item Ledger Entry"; var CopyItemTrkg: Boolean; var FillExactCostRevLink: Boolean; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckCopyFromRentalHeaderAvailOnAfterCheckItemAvailability(ToRentalHeader: Record "TWE Rental Header"; var ToRentalLine: Record "TWE Rental Line"; FromRentalHeader: Record "TWE Rental Header"; IncludeHeader: Boolean; FromRentalLine: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckCopyFromRentalHeaderArchiveAvailOnAfterCheckItemAvailability(ToRentalHeader: Record "TWE Rental Header"; var ToRentalLine: Record "TWE Rental Line"; FromRentalHeaderArchive: Record "TWE Rental Header Archive"; FromRentalLineArchive: Record "TWE Rental Line Archive"; IncludeHeader: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckCopyFromRentalCrMemoAvailOnAfterCheckItemAvailability(ToRentalHeader: Record "TWE Rental Header"; var ToRentalLine: Record "TWE Rental Line"; FromRentalCrMemoHeader: Record "TWE Rental Cr.Memo Header"; IncludeHeader: Boolean; FromRentalCrMemoLine: Record "TWE Rental Cr.Memo Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckCopyFromRentalInvoiceAvailOnAfterCheckItemAvailability(ToRentalHeader: Record "TWE Rental Header"; var ToRentalLine: Record "TWE Rental Line"; FromRentalInvoiceHeader: Record "TWE Rental Invoice Header"; IncludeHeader: Boolean; FromRentalInvLine: Record "TWE Rental Invoice Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckCopyFromRentalShptAvailOnAfterCheckItemAvailability(ToRentalHeader: Record "TWE Rental Header"; var ToRentalLine: Record "TWE Rental Line"; FromRentalShipmentHeader: Record "TWE Rental Shipment Header"; IncludeHeader: Boolean; FromRentalShptLine: Record "TWE Rental Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyArchRentalLineOnAfterToRentalLineInsert(var ToRentalLine: Record "TWE Rental Line"; FromRentalLineArchive: Record "TWE Rental Line Archive"; RecalculateLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyArchRentalLineOnBeforeToRentalLineInsert(var ToRentalLine: Record "TWE Rental Line"; FromRentalLineArchive: Record "TWE Rental Line Archive"; RecalculateLines: Boolean; var NextLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckItemAvailability(var ToRentalHeader: Record "TWE Rental Header"; var ToRentalLine: Record "TWE Rental Line"; var HideDialog: Boolean; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyRentalDocOnBeforeCopyLines(FromRentalHeader: Record "TWE Rental Header"; var ToRentalHeader: Record "TWE Rental Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyRentalDocOnAfterCopyRentalDocLines(FromDocType: Option; FromDocNo: Code[20]; FromDocOccurrenceNo: Integer; FromDocVersionNo: Integer; FromRentalHeader: Record "TWE Rental Header"; IncludeHeader: Boolean; var ToRentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyRentalDocOnBeforeCopyRentalDocShptLine(var FromRentalShipmentHeader: Record "TWE Rental Shipment Header"; var ToRentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyRentalDocOnBeforeCopyRentalDocInvLine(var FromRentalInvoiceHeader: Record "TWE Rental Invoice Header"; var ToRentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyRentalDocOnBeforeCopyRentalDocCrMemoLine(var FromRentalCrMemoHeader: Record "TWE Rental Cr.Memo Header"; var ToRentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyRentalDocOnBeforeToRentalHeaderInsert(var ToRentalHeader: Record "TWE Rental Header"; FromRentalHeader: Record "TWE Rental Header"; MoveNegLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyRentalDocOnBeforeTransferPostedShipmentFields(var ToRentalHeader: Record "TWE Rental Header"; RentalShipmentHeader: Record "TWE Rental Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyRentalDocOnAfterTransferPostedInvoiceFields(var ToRentalHeader: Record "TWE Rental Header"; RentalInvoiceHeader: Record "TWE Rental Invoice Header"; OldRentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyRentalDocOnAfterTransferArchRentalHeaderFields(var ToRentalHeader: Record "TWE Rental Header"; FromRentalHeaderArchive: Record "TWE Rental Header Archive")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyRentalDocOnBeforeTransferPostedInvoiceFields(var ToRentalHeader: Record "TWE Rental Header"; RentalInvoiceHeader: Record "TWE Rental Invoice Header"; var CopyJobData: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyRentalDocOnBeforeUpdateRentalInvoiceDiscountValue(var ToRentalHeader: Record "TWE Rental Header"; FromDocType: Option; FromDocNo: Code[20]; FromDocOccurrenceNo: Integer; FromDocVersionNo: Integer; RecalculateLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyRentalDocInvLineOnAfterSetFilters(var ToRentalHeader: Record "TWE Rental Header"; var FromRentalInvoiceHeader: Record "TWE Rental Invoice Header"; var FromRentalInvoiceLine: Record "TWE Rental Invoice Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyRentalDocCrMemoLineOnAfterSetFilters(var ToRentalHeader: Record "TWE Rental Header"; var FromRentalCrMemoHeader: Record "TWE Rental Cr.Memo Header"; var FromRentalCrMemoLine: Record "TWE Rental Cr.Memo Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyRentalDocShptLineOnAfterSetFilters(var ToRentalHeader: Record "TWE Rental Header"; var FromRentalShipmentHeader: Record "TWE Rental Shipment Header"; var FromRentalShipmentLine: Record "TWE Rental Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyRentalDocRentalLineOnAfterSetFilters(FromRentalHeader: Record "TWE Rental Header"; var FromRentalLine: Record "TWE Rental Line"; var ToRentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyRentalDocRentalLineArchiveOnAfterSetFilters(FromRentalHeaderArchive: Record "TWE Rental Header Archive"; var FromRentalLineArchive: Record "TWE Rental Line Archive"; var ToRentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyRentalDocUpdateHeaderOnBeforeUpdateCustLedgerEntry(var ToRentalHeader: Record "TWE Rental Header"; FromDocType: Option; FromDocNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyRentalDocWithoutHeader(var ToRentalHeader: Record "TWE Rental Header"; FromDocType: Option; FromDocNo: Code[20]; FromOccurenceNo: Integer; FromVersionNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyRentalLineOnAfterTransferFieldsToRentalLine(var ToRentalLine: Record "TWE Rental Line"; FromRentalLine: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyRentalShptLinesToDocOnAfterFromRentalHeaderTransferFields(FromRentalShptHeader: Record "TWE Rental Shipment Header"; var FromRentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyRentalShptLinesToDocOnBeforeCopyRentalLine(ToRentalHeader: Record "TWE Rental Header"; var FromRentalLine: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyRentalInvLinesToDocOnBeforeCopyRentalLine(ToRentalHeader: Record "TWE Rental Header"; var FromRentalLine: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyRentalInvLinesToDocOnAfterGetFromRentalInvHeader(var ToRentalHeader: Record "TWE Rental Header"; FromRentalInvHeader: Record "TWE Rental Invoice Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyRentalInvLinesToDocOnAfterInsertOldRentalDocNoLine(ToRentalHeader: Record "TWE Rental Header"; var SkipCopyFromDescription: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyRentalInvLinesToDocOnBeforeInsertOldRentalDocNoLine(ToRentalHeader: Record "TWE Rental Header"; var SkipCopyFromDescription: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyRentalInvLinesToDocOnAfterFromRentalHeaderTransferFields(var FromRentalHeader: Record "TWE Rental Header"; FromRentalInvHeader: Record "TWE Rental Invoice Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyRentalCrMemoLinesToDocOnAfterFromRentalHeaderTransferFields(FromRentalCrMemoHeader: Record "TWE Rental Cr.Memo Header"; var FromRentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyRentalCrMemoLinesToDocOnBeforeCopyRentalLine(ToRentalHeader: Record "TWE Rental Header"; var FromRentalLine: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyRentalLineOnBeforeCheckVATBusGroup(RentalLine: Record "TWE Rental Line"; var CheckVATBusGroup: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyRentalLinesToBufferTransferFields(RentalHeader: Record "TWE Rental Header"; RentalLine: Record "TWE Rental Line"; var TempRentalLineBuf: Record "TWE Rental Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyRentalLineOnAfterSetDimensions(var ToRentalLine: Record "TWE Rental Line"; FromRentalLine: Record "TWE Rental Line")
    begin
    end;


    [IntegrationEvent(false, false)]
    local procedure OnDeleteRentalLinesWithNegQtyOnAfterSetFilters(var FromRentalLine: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSplitPstdRentalLinesPerILETransferFields(var FromRentalHeader: Record "TWE Rental Header"; var FromRentalLine: Record "TWE Rental Line"; var TempRentalLineBuf: Record "TWE Rental Line" temporary; var ToRentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRecalculateRentalLineOnAfterValidateQuantity(var ToRentalLine: Record "TWE Rental Line"; var FromRentalLine: Record "TWE Rental Line")
    begin
    end;


}

