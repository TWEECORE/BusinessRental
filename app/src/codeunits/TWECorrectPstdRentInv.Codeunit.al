codeunit 50007 "TWE Correct Pstd. Rent. Inv."
{
    Permissions = TableData "TWE Rental Invoice Header" = rm,
                  TableData "TWE Rental Cr.Memo Header" = rm;
    TableNo = "TWE Rental Invoice Header";

    trigger OnRun()
    var
        RentalHeader: Record "TWE Rental Header";
    begin
        UnapplyCostApplication(Rec."No.");

        OnBeforeCreateCorrectiveRentalCrMemo(Rec);
        CreateCopyDocument(Rec, RentalHeader, RentalHeader."Document Type"::"Credit Memo", false);
        OnAfterCreateCorrectiveRentalCrMemo(Rec, RentalHeader, CancellingOnly);

        CODEUNIT.Run(CODEUNIT::"TWE Rental-Post", RentalHeader);
        SetTrackInfoForCancellation(Rec);
        UpdateRentalContractLinesFromCancelledInvoice(Rec."No.");

        Commit();
    end;

    var
        RentalSetup: Record "TWE Rental Setup";
        ErrorType: Option IsPaid,CustomerBlocked,ItemBlocked,AccountBlocked,IsCorrected,IsCorrective,SerieNumInv,SerieNumCM,SerieNumPostCM,ItemIsReturned,FromOrder,PostingNotAllowed,LineFromOrder,WrongItemType,LineFromJob,DimErr,DimCombErr,DimCombHeaderErr,ExtDocErr,InventoryPostClosed;
        CancellingOnly: Boolean;
        PostedInvoiceIsPaidCorrectErr: Label 'You cannot correct this posted sales invoice because it is fully or partially paid.\\To reverse a paid sales invoice, you must manually create a sales credit memo.';
        PostedInvoiceIsPaidCCancelErr: Label 'You cannot cancel this posted sales invoice because it is fully or partially paid.\\To reverse a paid sales invoice, you must manually create a sales credit memo.';
        AlreadyCorrectedErr: Label 'You cannot correct this posted sales invoice because it has been canceled.';
        AlreadyCancelledErr: Label 'You cannot cancel this posted sales invoice because it has already been canceled.';
        CorrCorrectiveDocErr: Label 'You cannot correct this posted sales invoice because it represents a correction of a credit memo.';
        CancelCorrectiveDocErr: Label 'You cannot cancel this posted sales invoice because it represents a correction of a credit memo.';
        CustomerIsBlockedCorrectErr: Label 'You cannot correct this posted sales invoice because customer %1 is blocked.', Comment = '%1 = Customer name';
        CustomerIsBlockedCancelErr: Label 'You cannot cancel this posted sales invoice because customer %1 is blocked.', Comment = '%1 = Customer name';
        ItemIsBlockedCorrectErr: Label 'You cannot correct this posted sales invoice because item %1 %2 is blocked.', Comment = '%1 = Item No. %2 = Item Description';
        ItemIsBlockedCancelErr: Label 'You cannot cancel this posted sales invoice because item %1 %2 is blocked.', Comment = '%1 = Item No. %2 = Item Description';
        AccountIsBlockedCorrectErr: Label 'You cannot correct this posted sales invoice because %1 %2 is blocked.', Comment = '%1 = Table Caption %2 = Account number.';
        AccountIsBlockedCancelErr: Label 'You cannot cancel this posted sales invoice because %1 %2 is blocked.', Comment = '%1 = Table Caption %2 = Account number.';
        NoFreeInvoiceNoSeriesCorrectErr: Label 'You cannot correct this posted sales invoice because no unused invoice numbers are available. \\You must extend the range of the number series for sales invoices.';
        NoFreeInvoiceNoSeriesCancelErr: Label 'You cannot cancel this posted sales invoice because no unused invoice numbers are available. \\You must extend the range of the number series for sales invoices.';
        NoFreeCMSeriesCorrectErr: Label 'You cannot correct this posted sales invoice because no unused credit memo numbers are available. \\You must extend the range of the number series for credit memos.';
        NoFreeCMSeriesCancelErr: Label 'You cannot cancel this posted sales invoice because no unused credit memo numbers are available. \\You must extend the range of the number series for credit memos.';
        NoFreePostCMSeriesCorrectErr: Label 'You cannot correct this posted sales invoice because no unused posted credit memo numbers are available. \\You must extend the range of the number series for posted credit memos.';
        NoFreePostCMSeriesCancelErr: Label 'You cannot cancel this posted sales invoice because no unused posted credit memo numbers are available. \\You must extend the range of the number series for posted credit memos.';
        RentalLineFromOrderCorrectErr: Label 'You cannot correct this posted sales invoice because item %1 %2 is used on a sales order.', Comment = '%1 = Item no. %2 = Item description';
        ShippedQtyReturnedCorrectErr: Label 'You cannot correct this posted sales invoice because item %1 %2 has already been fully or partially returned.', Comment = '%1 = Item no. %2 = Item description.';
        ShippedQtyReturnedCancelErr: Label 'You cannot cancel this posted sales invoice because item %1 %2 has already been fully or partially returned.', Comment = '%1 = Item no. %2 = Item description.';
        UsedInJobCorrectErr: Label 'You cannot correct this posted sales invoice because item %1 %2 is used in a job.', Comment = '%1 = Item no. %2 = Item description.';
        UsedInJobCancelErr: Label 'You cannot cancel this posted sales invoice because item %1 %2 is used in a job.', Comment = '%1 = Item no. %2 = Item description.';
        PostingNotAllowedCorrectErr: Label 'You cannot correct this posted sales invoice because it was posted in a posting period that is closed.';
        PostingNotAllowedCancelErr: Label 'You cannot cancel this posted sales invoice because it was posted in a posting period that is closed.';
        LineTypeNotAllowedCorrectErr: Label 'You cannot correct this posted sales invoice because the sales invoice line for %1 %2 is of type %3, which is not allowed on a simplified sales invoice.', Comment = '%1 = Item no. %2 = Item description %3 = Item type.';
        LineTypeNotAllowedCancelErr: Label 'You cannot cancel this posted sales invoice because the sales invoice line for %1 %2 is of type %3, which is not allowed on a simplified sales invoice.', Comment = '%1 = Item no. %2 = Item description %3 = Item type.';
        InvalidDimCodeCorrectErr: Label 'You cannot correct this posted sales invoice because the dimension rule setup for account ''%1'' %2 prevents %3 %4 from being canceled.', Comment = '%1 = Table caption %2 = Account number %3 = Item no. %4 = Item description.';
        InvalidDimCodeCancelErr: Label 'You cannot cancel this posted sales invoice because the dimension rule setup for account ''%1'' %2 prevents %3 %4 from being canceled.', Comment = '%1 = Table caption %2 = Account number %3 = Item no. %4 = Item description.';
        InvalidDimCombinationCorrectErr: Label 'You cannot correct this posted sales invoice because the dimension combination for item %1 %2 is not allowed.', Comment = '%1 = Item no. %2 = Item description.';
        InvalidDimCombinationCancelErr: Label 'You cannot cancel this posted sales invoice because the dimension combination for item %1 %2 is not allowed.', Comment = '%1 = Item no. %2 = Item description.';
        InvalidDimCombHeaderCorrectErr: Label 'You cannot correct this posted sales invoice because the combination of dimensions on the invoice is blocked.';
        InvalidDimCombHeaderCancelErr: Label 'You cannot cancel this posted sales invoice because the combination of dimensions on the invoice is blocked.';
        ExternalDocCorrectErr: Label 'You cannot correct this posted sales invoice because the external document number is required on the invoice.';
        ExternalDocCancelErr: Label 'You cannot cancel this posted sales invoice because the external document number is required on the invoice.';
        InventoryPostClosedCorrectErr: Label 'You cannot correct this posted sales invoice because the posting inventory period is already closed.';
        InventoryPostClosedCancelErr: Label 'You cannot cancel this posted sales invoice because the posting inventory period is already closed.';
        PostingCreditMemoFailedOpenPostedCMQst: Label 'Canceling the invoice failed because of the following error: \\%1\\A credit memo is posted. Do you want to open the posted credit memo?', Comment = '%1 = Last Error Message';
        PostingCreditMemoFailedOpenCMQst: Label 'Canceling the invoice failed because of the following error: \\%1\\A credit memo is created but not posted. Do you want to open the credit memo?', Comment = '%1 = Last Error Message';
        CreatingCreditMemoFailedNothingCreatedErr: Label 'Canceling the invoice failed because of the following error: \\%1.', Comment = '%1 = Last Error Message';
        WrongDocumentTypeForCopyDocumentErr: Label 'You cannot correct or cancel this type of document.';
        CheckPrepaymentErr: Label 'You cannot correct or cancel a posted sales prepayment invoice.\\Open the related sales order and choose the Post Prepayment Credit Memo.';
        InvoicePartiallyPaidMsg: Label 'Invoice %1 is partially paid or credited. The corrective credit memo may not be fully closed by the invoice.', Comment = '%1 - invoice no.';
        InvoiceClosedMsg: Label 'Invoice %1 is closed. The corrective credit memo will not be applied to the invoice.', Comment = '%1 - invoice no.';
        SkipLbl: Label 'Skip';
        CreateCreditMemoLbl: Label 'Create credit memo anyway';
        ShowEntriesLbl: Label 'Show applied entries';

    procedure CancelPostedInvoice(var RentalInvoiceHeader: Record "TWE Rental Invoice Header"): Boolean
    begin
        CancellingOnly := true;
        exit(CreateCreditMemo(RentalInvoiceHeader));
    end;

    local procedure CreateCreditMemo(var RentalInvoiceHeader: Record "TWE Rental Invoice Header"): Boolean
    var
        RentalHeader: Record "TWE Rental Header";
        RentalCrMemoHeader: Record "TWE Rental Cr.Memo Header";
        IsHandled: Boolean;
    begin
        TestCorrectInvoiceIsAllowed(RentalInvoiceHeader, CancellingOnly);
        if not CODEUNIT.Run(CODEUNIT::"TWE Correct Pstd. Rent. Inv.", RentalInvoiceHeader) then begin
            RentalCrMemoHeader.SetRange("Applies-to Doc. No.", RentalInvoiceHeader."No.");
            if RentalCrMemoHeader.FindFirst() then begin
                if Confirm(StrSubstNo(PostingCreditMemoFailedOpenPostedCMQst, GetLastErrorText)) then
                    PAGE.Run(PAGE::"TWE Posted Rental Credit Memo", RentalCrMemoHeader);
            end else begin
                RentalHeader.SetRange("Applies-to Doc. No.", RentalInvoiceHeader."No.");
                if RentalHeader.FindFirst() then begin
                    if Confirm(StrSubstNo(PostingCreditMemoFailedOpenCMQst, GetLastErrorText)) then begin
                        IsHandled := false;
                        OnCreateCreditMemoOnBeforePageRun(RentalHeader, IsHandled);
                        if not IsHandled then
                            PAGE.Run(PAGE::"TWE Rental Credit Memo", RentalHeader);
                    end;
                end else
                    Error(CreatingCreditMemoFailedNothingCreatedErr, GetLastErrorText);
            end;
            exit(false);
        end;
        exit(true);
    end;

    local procedure CreateCopyDocument(var RentalInvoiceHeader: Record "TWE Rental Invoice Header"; var RentalHeader: Record "TWE Rental Header"; DocumentType: Enum "TWE Rental Document Type"; SkipCopyFromDescription: Boolean)
    var
        RentalCopyDocMgt: Codeunit "TWE Copy Rental Document Mgt.";
    begin
        Clear(RentalHeader);
        RentalHeader."No." := '';
        RentalHeader."Document Type" := DocumentType;
        RentalHeader.SetAllowSelectNoSeries();
        OnBeforeRentalHeaderInsert(RentalHeader, RentalInvoiceHeader, CancellingOnly);
        RentalHeader.Insert(true);

        case DocumentType of
            RentalHeader."Document Type"::"Credit Memo":
                RentalCopyDocMgt.SetPropertiesForCreditMemoCorrection();
            RentalHeader."Document Type"::Invoice:
                RentalCopyDocMgt.SetPropertiesForInvoiceCorrection(SkipCopyFromDescription);
            else
                Error(WrongDocumentTypeForCopyDocumentErr);
        end;

        RentalCopyDocMgt.CopyRentalDocForInvoiceCancelling(RentalInvoiceHeader."No.", RentalHeader);
        OnAfterCreateCopyDocument(RentalHeader, RentalInvoiceHeader);
    end;

    procedure CreateCreditMemoCopyDocument(var RentalInvoiceHeader: Record "TWE Rental Invoice Header"; var RentalHeader: Record "TWE Rental Header"): Boolean
    begin
        OnBeforeCreateCreditMemoCopyDocument(RentalInvoiceHeader);
        TestNotRentalPrepaymentlInvoice(RentalInvoiceHeader);
        if not RentalInvoiceHeader.IsFullyOpen() then begin
            ShowInvoiceAppliedNotification(RentalInvoiceHeader);
            exit(false);
        end;
        CreateCopyDocument(RentalInvoiceHeader, RentalHeader, RentalHeader."Document Type"::"Credit Memo", false);
        exit(true);
    end;

    procedure CreateCorrectiveCreditMemo(var InvoiceNotification: Notification)
    var
        RentalHeader: Record "TWE Rental Header";
        RentalInvoiceHeader: Record "TWE Rental Invoice Header";
    begin
        RentalInvoiceHeader.Get(InvoiceNotification.GetData(RentalInvoiceHeader.FieldName("No.")));
        InvoiceNotification.Recall();

        CreateCopyDocument(RentalInvoiceHeader, RentalHeader, RentalHeader."Document Type"::"Credit Memo", false);
        PAGE.Run(PAGE::"TWE Rental Credit Memo", RentalHeader);
    end;

    procedure ShowAppliedEntries(var InvoiceNotification: Notification)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        RentalInvoiceHeader: Record "TWE Rental Invoice Header";
    begin
        RentalInvoiceHeader.Get(InvoiceNotification.GetData(RentalInvoiceHeader.FieldName("No.")));
        CustLedgerEntry.Get(RentalInvoiceHeader."Cust. Ledger Entry No.");
        PAGE.RunModal(PAGE::"Applied Customer Entries", CustLedgerEntry);
    end;

    procedure SkipCorrectiveCreditMemo(var InvoiceNotification: Notification)
    begin
        InvoiceNotification.Recall();
    end;

    procedure CancelPostedInvoiceCreateNewInvoice(var RentalInvoiceHeader: Record "TWE Rental Invoice Header"; var RentalHeader: Record "TWE Rental Header")
    begin
        CancellingOnly := false;

        if CreateCreditMemo(RentalInvoiceHeader) then begin
            CreateCopyDocument(RentalInvoiceHeader, RentalHeader, RentalHeader."Document Type"::Invoice, true);
            OnAfterCreateCorrRentalInvoice(RentalHeader);
            Commit();
        end;
    end;

    procedure TestCorrectInvoiceIsAllowed(var RentalInvoiceHeader: Record "TWE Rental Invoice Header"; Cancelling: Boolean)
    begin
        CancellingOnly := Cancelling;

        RentalInvoiceHeader.CalcFields(Amount);
        RentalInvoiceHeader.TestField(Amount);
        TestIfPostingIsAllowed(RentalInvoiceHeader);
        TestIfInvoiceIsCorrectedOnce(RentalInvoiceHeader);
        TestIfInvoiceIsNotCorrectiveDoc(RentalInvoiceHeader);
        TestIfInvoiceIsPaid(RentalInvoiceHeader);
        TestIfCustomerIsBlocked(RentalInvoiceHeader, RentalInvoiceHeader."Rented-to Customer No.");
        TestIfCustomerIsBlocked(RentalInvoiceHeader, RentalInvoiceHeader."Bill-to Customer No.");
        TestCustomerDimension(RentalInvoiceHeader, RentalInvoiceHeader."Bill-to Customer No.");
        TestDimensionOnHeader(RentalInvoiceHeader);
        TestRentalLines(RentalInvoiceHeader);
        TestIfAnyFreeNumberSeries(RentalInvoiceHeader);
        TestExternalDocument(RentalInvoiceHeader);
        TestInventoryPostingClosed(RentalInvoiceHeader);
        TestNotRentalPrepaymentlInvoice(RentalInvoiceHeader);

        OnAfterTestCorrectInvoiceIsAllowed(RentalInvoiceHeader, Cancelling);
    end;

    local procedure ShowInvoiceAppliedNotification(RentalInvoiceHeader: Record "TWE Rental Invoice Header")
    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        InvoiceNotification: Notification;
        NotificationText: Text;
    begin
        InvoiceNotification.Id := CreateGuid();
        InvoiceNotification.Scope(NOTIFICATIONSCOPE::LocalScope);
        InvoiceNotification.SetData(RentalInvoiceHeader.FieldName("No."), RentalInvoiceHeader."No.");
        RentalInvoiceHeader.CalcFields(Closed);
        if RentalInvoiceHeader.Closed then
            NotificationText := StrSubstNo(InvoiceClosedMsg, RentalInvoiceHeader."No.")
        else
            NotificationText := StrSubstNo(InvoicePartiallyPaidMsg, RentalInvoiceHeader."No.");
        InvoiceNotification.Message(NotificationText);
        InvoiceNotification.AddAction(ShowEntriesLbl, CODEUNIT::"TWE Correct Pstd. Rent. Inv.", 'ShowAppliedEntries');
        InvoiceNotification.AddAction(SkipLbl, CODEUNIT::"TWE Correct Pstd. Rent. Inv.", 'SkipCorrectiveCreditMemo');
        InvoiceNotification.AddAction(CreateCreditMemoLbl, CODEUNIT::"TWE Correct Pstd. Rent. Inv.", 'CreateCorrectiveCreditMemo');
        NotificationLifecycleMgt.SendNotification(InvoiceNotification, RentalInvoiceHeader.RecordId);
    end;

    local procedure SetTrackInfoForCancellation(var RentalInvoiceHeader: Record "TWE Rental Invoice Header")
    var
        RentalCrMemoHeader: Record "TWE Rental Cr.Memo Header";
        CancelledRentalDocument: Record "TWE Cancelled Rental Document";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetTrackInfoForCancellation(RentalInvoiceHeader, IsHandled);
        if IsHandled then
            exit;

        RentalCrMemoHeader.SetRange("Applies-to Doc. No.", RentalInvoiceHeader."No.");
        if RentalCrMemoHeader.FindLast() then
            CancelledRentalDocument.InsertRentalInvToCrMemoCancelledDocument(RentalInvoiceHeader."No.", RentalCrMemoHeader."No.");
    end;

    local procedure TestDimensionOnHeader(RentalInvoiceHeader: Record "TWE Rental Invoice Header")
    var
        DimensionManagement: Codeunit DimensionManagement;
    begin
        if not DimensionManagement.CheckDimIDComb(RentalInvoiceHeader."Dimension Set ID") then
            ErrorHelperHeader(ErrorType::DimCombHeaderErr, RentalInvoiceHeader);
    end;

    local procedure TestIfCustomerIsBlocked(RentalInvoiceHeader: Record "TWE Rental Invoice Header"; CustNo: Code[20])
    var
        Customer: Record Customer;
    begin
        Customer.Get(CustNo);
        if Customer.Blocked in [Customer.Blocked::Invoice, Customer.Blocked::All] then
            ErrorHelperHeader(ErrorType::CustomerBlocked, RentalInvoiceHeader);
    end;

    local procedure TestCustomerDimension(RentalInvoiceHeader: Record "TWE Rental Invoice Header"; CustNo: Code[20])
    var
        Customer: Record Customer;
        DimensionManagement: Codeunit DimensionManagement;
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
    begin
        Customer.Get(CustNo);
        TableID[1] := DATABASE::Customer;
        No[1] := Customer."No.";
        if not DimensionManagement.CheckDimValuePosting(TableID, No, RentalInvoiceHeader."Dimension Set ID") then
            ErrorHelperAccount(ErrorType::DimErr, CopyStr(Customer.TableCaption, 1, 20), Customer."No.", Customer."No.", Customer.Name);
    end;

    local procedure TestRentalLines(RentalInvoiceHeader: Record "TWE Rental Invoice Header")
    var
        RentalInvoiceLine: Record "TWE Rental Invoice Line";
        MainRentalItem: Record "TWE Main Rental Item";
        DimensionManagement: Codeunit DimensionManagement;
        ShippedQtyNoReturned: Decimal;
        RevUnitCostLCY: Decimal;
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
    begin
        RentalInvoiceLine.SetRange("Document No.", RentalInvoiceHeader."No.");
        if RentalInvoiceLine.Find('-') then
            repeat
                if not IsCommentLine(RentalInvoiceLine) then begin
                    TestRentalLineType(RentalInvoiceLine);

                    if RentalInvoiceLine.Type = RentalInvoiceLine.Type::"Rental Item" then begin
                        if (RentalInvoiceLine.Quantity > 0) and (RentalInvoiceLine."Job No." = '') and
                           WasNotCancelled(RentalInvoiceHeader."No.")
                        then begin
                            RentalInvoiceLine.CalcShippedSaleNotReturned(ShippedQtyNoReturned, RevUnitCostLCY, false);
                            if RentalInvoiceLine.Quantity <> ShippedQtyNoReturned then
                                ErrorHelperLine(ErrorType::ItemIsReturned, RentalInvoiceLine);
                        end;

                        MainRentalItem.Get(RentalInvoiceLine."No.");

                        if MainRentalItem.Blocked then
                            ErrorHelperLine(ErrorType::ItemBlocked, RentalInvoiceLine);

                        TableID[1] := DATABASE::Item;
                        No[1] := RentalInvoiceLine."No.";
                        if not DimensionManagement.CheckDimValuePosting(TableID, No, RentalInvoiceLine."Dimension Set ID") then
                            ErrorHelperAccount(ErrorType::DimErr, CopyStr(MainRentalItem.TableCaption, 1, 20), No[1], MainRentalItem."No.", MainRentalItem.Description);
                    end;

                    TestGenPostingSetup(RentalInvoiceLine);
                    TestCustomerPostingGroup(RentalInvoiceLine, RentalInvoiceHeader."Customer Posting Group");
                    TestVATPostingSetup(RentalInvoiceLine);

                    if not DimensionManagement.CheckDimIDComb(RentalInvoiceLine."Dimension Set ID") then
                        ErrorHelperLine(ErrorType::DimCombErr, RentalInvoiceLine);
                end;
            until RentalInvoiceLine.Next() = 0;
    end;

    local procedure TestGLAccount(AccountNo: Code[20]; RentalInvoiceLine: Record "TWE Rental Invoice Line")
    var
        GLAccount: Record "G/L Account";
        Item: Record Item;
        DimensionManagement: Codeunit DimensionManagement;
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
    begin
        GLAccount.Get(AccountNo);
        if GLAccount.Blocked then
            ErrorHelperAccount(ErrorType::AccountBlocked, CopyStr(GLAccount.TableCaption, 1, 20), AccountNo, '', '');
        TableID[1] := DATABASE::"G/L Account";
        No[1] := AccountNo;

        if RentalInvoiceLine.Type = RentalInvoiceLine.Type::"Rental Item" then begin
            Item.Get(RentalInvoiceLine."No.");
            if not DimensionManagement.CheckDimValuePosting(TableID, No, RentalInvoiceLine."Dimension Set ID") then
                ErrorHelperAccount(ErrorType::DimErr, CopyStr(GLAccount.TableCaption, 1, 20), AccountNo, Item."No.", Item.Description);
        end;
    end;

    local procedure TestIfInvoiceIsPaid(RentalInvoiceHeader: Record "TWE Rental Invoice Header")
    begin
        RentalInvoiceHeader.CalcFields("Amount Including VAT");
        RentalInvoiceHeader.CalcFields("Remaining Amount");
        if RentalInvoiceHeader."Amount Including VAT" <> RentalInvoiceHeader."Remaining Amount" then
            ErrorHelperHeader(ErrorType::IsPaid, RentalInvoiceHeader);
    end;

    local procedure TestIfInvoiceIsCorrectedOnce(RentalInvoiceHeader: Record "TWE Rental Invoice Header")
    var
        CancelledDocument: Record "TWE Cancelled Rental Document";
    begin
        if CancelledDocument.FindRentalCancelledInvoice(RentalInvoiceHeader."No.") then
            ErrorHelperHeader(ErrorType::IsCorrected, RentalInvoiceHeader);
    end;

    local procedure TestIfInvoiceIsNotCorrectiveDoc(RentalInvoiceHeader: Record "TWE Rental Invoice Header")
    var
        CancelledRentalDocument: Record "TWE Cancelled Rental Document";
    begin
        if CancelledRentalDocument.FindRentalCorrectiveInvoice(RentalInvoiceHeader."No.") then
            ErrorHelperHeader(ErrorType::IsCorrective, RentalInvoiceHeader);
    end;

    local procedure TestIfPostingIsAllowed(RentalInvoiceHeader: Record "TWE Rental Invoice Header")
    var
        GenJnlCheckLine: Codeunit "Gen. Jnl.-Check Line";
    begin
        if GenJnlCheckLine.DateNotAllowed(RentalInvoiceHeader."Posting Date") then
            ErrorHelperHeader(ErrorType::PostingNotAllowed, RentalInvoiceHeader);
    end;

    local procedure TestIfAnyFreeNumberSeries(RentalInvoiceHeader: Record "TWE Rental Invoice Header")
    var
        NoSeriesManagement: Codeunit NoSeriesManagement;
        PostingDate: Date;
    begin
        PostingDate := WorkDate();
        RentalSetup.Get();

        if NoSeriesManagement.TryGetNextNo(RentalSetup."Rental Credit Memo Nos.", PostingDate) = '' then
            ErrorHelperHeader(ErrorType::SerieNumCM, RentalInvoiceHeader);

        if NoSeriesManagement.TryGetNextNo(RentalSetup."Posted Rental Credit Memo Nos.", PostingDate) = '' then
            ErrorHelperHeader(ErrorType::SerieNumPostCM, RentalInvoiceHeader);

        if (not CancellingOnly) and (NoSeriesManagement.TryGetNextNo(RentalSetup."Rental Invoice Nos.", PostingDate) = '') then
            ErrorHelperHeader(ErrorType::SerieNumInv, RentalInvoiceHeader);
    end;

    local procedure TestExternalDocument(RentalInvoiceHeader: Record "TWE Rental Invoice Header")
    begin
        RentalSetup.Get();
        if (RentalInvoiceHeader."External Document No." = '') and RentalSetup."Ext. Doc. No. Mandatory" then
            ErrorHelperHeader(ErrorType::ExtDocErr, RentalInvoiceHeader);
    end;

    local procedure TestInventoryPostingClosed(RentalInvoiceHeader: Record "TWE Rental Invoice Header")
    var
        InventoryPeriod: Record "Inventory Period";
        RentalInvoiceLine: Record "TWE Rental Invoice Line";
        DocumentHasLineWithRestrictedType: Boolean;
    begin
        RentalInvoiceLine.SetRange("Document No.", RentalInvoiceHeader."No.");
        RentalInvoiceLine.SetFilter(Quantity, '<>%1', 0);
        RentalInvoiceLine.SetFilter(Type, '%1', RentalInvoiceLine.Type::"Rental Item");
        DocumentHasLineWithRestrictedType := not RentalInvoiceLine.IsEmpty;

        if DocumentHasLineWithRestrictedType then begin
            InventoryPeriod.SetRange(Closed, true);
            InventoryPeriod.SetFilter("Ending Date", '>=%1', RentalInvoiceHeader."Posting Date");
            if not InventoryPeriod.IsEmpty() then
                ErrorHelperHeader(ErrorType::InventoryPostClosed, RentalInvoiceHeader);
        end;
    end;

    local procedure TestRentalLineType(RentalInvoiceLine: Record "TWE Rental Invoice Line")
    var
        IsHandled: Boolean;
    begin
        if RentalInvoiceLine.IsCancellationSupported() then
            exit;

        if (RentalInvoiceLine."Job No." <> '') and (RentalInvoiceLine.Type = RentalInvoiceLine.Type::Resource) then
            exit;

        IsHandled := false;
        OnAfterTestRentalLineType(RentalInvoiceLine, IsHandled);
        if not IsHandled then
            ErrorHelperLine(ErrorType::WrongItemType, RentalInvoiceLine);
    end;

    local procedure TestGenPostingSetup(RentalInvoiceLine: Record "TWE Rental Invoice Line")
    var
        GenPostingSetup: Record "General Posting Setup";
        MainRentalItem: Record "TWE Main Rental Item";
    begin
        if RentalInvoiceLine."VAT Calculation Type" = RentalInvoiceLine."VAT Calculation Type"::"Sales Tax" then
            exit;

        RentalSetup.Get();
        GenPostingSetup.Get(RentalInvoiceLine."Gen. Bus. Posting Group", RentalInvoiceLine."Gen. Prod. Posting Group");
        if RentalInvoiceLine.Type <> RentalInvoiceLine.Type::"G/L Account" then begin
            GenPostingSetup.TestField("TWE Rental Account");
            TestGLAccount(GenPostingSetup."TWE Rental Account", RentalInvoiceLine);
            GenPostingSetup.TestField("TWE Rental Credit Memo Account");
            TestGLAccount(GenPostingSetup."TWE Rental Credit Memo Account", RentalInvoiceLine);
        end;
        if HasLineDiscountSetup() then
            if GenPostingSetup."TWE Rental Line Disc. Account" <> '' then
                TestGLAccount(GenPostingSetup."TWE Rental Line Disc. Account", RentalInvoiceLine);
        if RentalInvoiceLine.Type = RentalInvoiceLine.Type::"Rental Item" then begin
            MainRentalItem.Get(RentalInvoiceLine."No.");
            if MainRentalItem.IsInventoriableType() then
                TestGLAccount(GenPostingSetup.GetCOGSAccount(), RentalInvoiceLine);
        end;
    end;

    local procedure TestCustomerPostingGroup(RentalInvoiceLine: Record "TWE Rental Invoice Line"; CustomerPostingGr: Code[20])
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        CustomerPostingGroup.Get(CustomerPostingGr);
        CustomerPostingGroup.TestField("Receivables Account");
        TestGLAccount(CustomerPostingGroup."Receivables Account", RentalInvoiceLine);
    end;

    local procedure TestVATPostingSetup(RentalInvoiceLine: Record "TWE Rental Invoice Line")
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.Get(RentalInvoiceLine."VAT Bus. Posting Group", RentalInvoiceLine."VAT Prod. Posting Group");
        if VATPostingSetup."VAT Calculation Type" <> VATPostingSetup."VAT Calculation Type"::"Sales Tax" then begin
            VATPostingSetup.TestField("TWE Rental VAT Account");
            TestGLAccount(VATPostingSetup."TWE Rental VAT Account", RentalInvoiceLine);
        end;
    end;

    local procedure TestInventoryPostingSetup(RentalInvoiceLine: Record "TWE Rental Invoice Line")
    var
        InventoryPostingSetup: Record "Inventory Posting Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestInventoryPostingSetup(RentalInvoiceLine, IsHandled);
        if IsHandled then
            exit;

        InventoryPostingSetup.Get(RentalInvoiceLine."Location Code", RentalInvoiceLine."Posting Group");
        InventoryPostingSetup.TestField("Inventory Account");
        TestGLAccount(InventoryPostingSetup."Inventory Account", RentalInvoiceLine);
    end;

    local procedure TestNotRentalPrepaymentlInvoice(RentalInvoiceHeader: Record "TWE Rental Invoice Header")
    begin
        if RentalInvoiceHeader."Prepayment Invoice" then
            Error(CheckPrepaymentErr);
    end;

    local procedure IsCommentLine(RentalInvoiceLine: Record "TWE Rental Invoice Line"): Boolean
    begin
        exit((RentalInvoiceLine.Type = RentalInvoiceLine.Type::" ") or (RentalInvoiceLine."No." = ''));
    end;

    local procedure WasNotCancelled(InvNo: Code[20]): Boolean
    var
        RentalCrMemoHeader: Record "TWE Rental Cr.Memo Header";
    begin
        RentalCrMemoHeader.SetRange("Applies-to Doc. Type", RentalCrMemoHeader."Applies-to Doc. Type"::Invoice);
        RentalCrMemoHeader.SetRange("Applies-to Doc. No.", InvNo);
        exit(RentalCrMemoHeader.IsEmpty);
    end;

    local procedure UnapplyCostApplication(InvNo: Code[20])
    var
        TempItemLedgEntry: Record "Item Ledger Entry" temporary;
        TempItemApplicationEntry: Record "Item Application Entry" temporary;
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
    begin
        FindItemLedgEntries(TempItemLedgEntry, InvNo);
        if FindAppliedInbndEntries(TempItemApplicationEntry, TempItemLedgEntry) then begin
            repeat
                ItemJnlPostLine.UnApply(TempItemApplicationEntry);
            until TempItemApplicationEntry.Next() = 0;
            ItemJnlPostLine.RedoApplications();
        end;
    end;

    procedure FindItemLedgEntries(var ItemLedgEntry: Record "Item Ledger Entry"; InvNo: Code[20])
    var
        RentalInvLine: Record "TWE Rental Invoice Line";
    begin
        RentalInvLine.SetRange("Document No.", InvNo);
        RentalInvLine.SetRange(Type, RentalInvLine.Type::"Rental Item");
        if RentalInvLine.FindSet() then
            repeat
                RentalInvLine.GetItemLedgEntries(ItemLedgEntry, false);
            until RentalInvLine.Next() = 0;
    end;

    local procedure FindAppliedInbndEntries(var TempItemApplicationEntry: Record "Item Application Entry" temporary; var ItemLedgEntry: Record "Item Ledger Entry"): Boolean
    var
        ItemApplicationEntry: Record "Item Application Entry";
    begin
        TempItemApplicationEntry.Reset();
        TempItemApplicationEntry.DeleteAll();
        if ItemLedgEntry.FindSet() then
            repeat
                if ItemApplicationEntry.AppliedInbndEntryExists(ItemLedgEntry."Entry No.", true) then
                    repeat
                        TempItemApplicationEntry := ItemApplicationEntry;
                        if not TempItemApplicationEntry.Find() then
                            TempItemApplicationEntry.Insert();
                    until ItemApplicationEntry.Next() = 0;
            until ItemLedgEntry.Next() = 0;
        exit(TempItemApplicationEntry.FindSet());
    end;

    local procedure ErrorHelperHeader(ErrorOption: Option; RentalInvoiceHeader: Record "TWE Rental Invoice Header")
    var
        Customer: Record Customer;
    begin
        if CancellingOnly then
            case ErrorOption of
                ErrorType::IsPaid:
                    Error(PostedInvoiceIsPaidCCancelErr);
                ErrorType::CustomerBlocked:
                    begin
                        Customer.Get(RentalInvoiceHeader."Bill-to Customer No.");
                        Error(CustomerIsBlockedCancelErr, Customer.Name);
                    end;
                ErrorType::IsCorrected:
                    Error(AlreadyCancelledErr);
                ErrorType::IsCorrective:
                    Error(CancelCorrectiveDocErr);
                ErrorType::SerieNumInv:
                    Error(NoFreeInvoiceNoSeriesCancelErr);
                ErrorType::SerieNumCM:
                    Error(NoFreeCMSeriesCancelErr);
                ErrorType::SerieNumPostCM:
                    Error(NoFreePostCMSeriesCancelErr);
                ErrorType::PostingNotAllowed:
                    Error(PostingNotAllowedCancelErr);
                ErrorType::ExtDocErr:
                    Error(ExternalDocCancelErr);
                ErrorType::InventoryPostClosed:
                    Error(InventoryPostClosedCancelErr);
                ErrorType::DimCombHeaderErr:
                    Error(InvalidDimCombHeaderCancelErr);
            end
        else
            case ErrorOption of
                ErrorType::IsPaid:
                    Error(PostedInvoiceIsPaidCorrectErr);
                ErrorType::CustomerBlocked:
                    begin
                        Customer.Get(RentalInvoiceHeader."Bill-to Customer No.");
                        Error(CustomerIsBlockedCorrectErr, Customer.Name);
                    end;
                ErrorType::IsCorrected:
                    Error(AlreadyCorrectedErr);
                ErrorType::IsCorrective:
                    Error(CorrCorrectiveDocErr);
                ErrorType::SerieNumInv:
                    Error(NoFreeInvoiceNoSeriesCorrectErr);
                ErrorType::SerieNumPostCM:
                    Error(NoFreePostCMSeriesCorrectErr);
                ErrorType::SerieNumCM:
                    Error(NoFreeCMSeriesCorrectErr);
                ErrorType::PostingNotAllowed:
                    Error(PostingNotAllowedCorrectErr);
                ErrorType::ExtDocErr:
                    Error(ExternalDocCorrectErr);
                ErrorType::InventoryPostClosed:
                    Error(InventoryPostClosedCorrectErr);
                ErrorType::DimCombHeaderErr:
                    Error(InvalidDimCombHeaderCorrectErr);
            end;
    end;

    local procedure ErrorHelperLine(ErrorOption: Option; RentalInvoiceLine: Record "TWE Rental Invoice Line")
    var
        Item: Record Item;
    begin
        if CancellingOnly then
            case ErrorOption of
                ErrorType::ItemBlocked:
                    begin
                        Item.Get(RentalInvoiceLine."No.");
                        Error(ItemIsBlockedCancelErr, Item."No.", Item.Description);
                    end;
                ErrorType::ItemIsReturned:
                    begin
                        Item.Get(RentalInvoiceLine."No.");
                        Error(ShippedQtyReturnedCancelErr, Item."No.", Item.Description);
                    end;
                ErrorType::WrongItemType:
                    Error(LineTypeNotAllowedCancelErr, RentalInvoiceLine."No.", RentalInvoiceLine.Description, RentalInvoiceLine.Type);
                ErrorType::LineFromJob:
                    Error(UsedInJobCancelErr, RentalInvoiceLine."No.", RentalInvoiceLine.Description);
                ErrorType::DimCombErr:
                    Error(InvalidDimCombinationCancelErr, RentalInvoiceLine."No.", RentalInvoiceLine.Description);
            end
        else
            case ErrorOption of
                ErrorType::ItemBlocked:
                    begin
                        Item.Get(RentalInvoiceLine."No.");
                        Error(ItemIsBlockedCorrectErr, Item."No.", Item.Description);
                    end;
                ErrorType::ItemIsReturned:
                    begin
                        Item.Get(RentalInvoiceLine."No.");
                        Error(ShippedQtyReturnedCorrectErr, Item."No.", Item.Description);
                    end;
                ErrorType::LineFromOrder:
                    Error(RentalLineFromOrderCorrectErr, RentalInvoiceLine."No.", RentalInvoiceLine.Description);
                ErrorType::WrongItemType:
                    Error(LineTypeNotAllowedCorrectErr, RentalInvoiceLine."No.", RentalInvoiceLine.Description, RentalInvoiceLine.Type);
                ErrorType::LineFromJob:
                    Error(UsedInJobCorrectErr, RentalInvoiceLine."No.", RentalInvoiceLine.Description);
                ErrorType::DimCombErr:
                    Error(InvalidDimCombinationCorrectErr, RentalInvoiceLine."No.", RentalInvoiceLine.Description);
            end;
    end;

    local procedure ErrorHelperAccount(ErrorOption: Option; AccountNo: Code[20]; AccountCaption: Text; No: Code[20]; Name: Text)
    begin
        if CancellingOnly then
            case ErrorOption of
                ErrorType::AccountBlocked:
                    Error(AccountIsBlockedCancelErr, AccountCaption, AccountNo);
                ErrorType::DimErr:
                    Error(InvalidDimCodeCancelErr, AccountCaption, AccountNo, No, Name);
            end
        else
            case ErrorOption of
                ErrorType::AccountBlocked:
                    Error(AccountIsBlockedCorrectErr, AccountCaption, AccountNo);
                ErrorType::DimErr:
                    Error(InvalidDimCodeCorrectErr, AccountCaption, AccountNo, No, Name);
            end;
    end;

    local procedure HasLineDiscountSetup() Result: Boolean
    begin
        RentalSetup.Get();
        Result := RentalSetup."Discount Posting" in [RentalSetup."Discount Posting"::"Line Discounts", RentalSetup."Discount Posting"::"All Discounts"];
        OnHasLineDiscountSetup(RentalSetup, Result);
    end;

    local procedure UpdateRentalContractLinesFromCancelledInvoice(RentalInvoiceHeaderNo: Code[20])
    var
        RentalLine: Record "TWE Rental Line";
        RentalInvoiceLine: Record "TWE Rental Invoice Line";
    begin
        RentalInvoiceLine.SetRange("Document No.", RentalInvoiceHeaderNo);
        if RentalInvoiceLine.FindSet() then
            repeat
                if RentalLine.Get(RentalLine."Document Type"::Contract, RentalInvoiceLine."Order No.", RentalInvoiceLine."Order Line No.") then
                    UpdateRentalContractLineInvoicedQuantity(RentalLine, RentalInvoiceLine.Quantity, RentalInvoiceLine."Quantity (Base)");
            until RentalInvoiceLine.Next() = 0;
    end;

    local procedure UpdateRentalContractLineInvoicedQuantity(var RentalLine: Record "TWE Rental Line"; CancelledQuantity: Decimal; CancelledQtyBase: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateRentalOrderLineInvoicedQuantity(RentalLine, CancelledQuantity, CancelledQtyBase, IsHandled);
        if IsHandled then
            exit;

        RentalLine."Quantity Invoiced" -= CancelledQuantity;
        RentalLine."Qty. Invoiced (Base)" -= CancelledQtyBase;
        RentalLine."Quantity Shipped" -= CancelledQuantity;
        RentalLine."Qty. Shipped (Base)" -= CancelledQtyBase;
        RentalLine.InitOutstanding();
        RentalLine.InitQtyToShip();
        RentalLine.InitQtyToInvoice();
        RentalLine.Modify();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateCopyDocument(var RentalHeader: Record "TWE Rental Header"; var RentalInvoiceHeader: Record "TWE Rental Invoice Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTestCorrectInvoiceIsAllowed(var RentalInvoiceHeader: Record "TWE Rental Invoice Header"; Cancelling: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTestRentalLineType(RentalInvoiceLine: Record "TWE Rental Invoice Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateCorrRentalInvoice(var RentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateCorrectiveRentalCrMemo(RentalInvoiceHeader: Record "TWE Rental Invoice Header"; var RentalHeader: Record "TWE Rental Header"; var CancellingOnly: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateCorrectiveRentalCrMemo(RentalInvoiceHeader: Record "TWE Rental Invoice Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateCreditMemoCopyDocument(var RentalInvoiceHeader: Record "TWE Rental Invoice Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRentalHeaderInsert(var RentalHeader: Record "TWE Rental Header"; var RentalInvoiceHeader: Record "TWE Rental Invoice Header"; CancellingOnly: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetTrackInfoForCancellation(var RentalInvoiceHeader: Record "TWE Rental Invoice Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnHasLineDiscountSetup(RentalSetup: Record "TWE Rental Setup"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestInventoryPostingSetup(RentalInvoiceLine: Record "TWE Rental Invoice Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateRentalOrderLineInvoicedQuantity(var RentalLine: Record "TWE Rental Line"; CancelledQuantity: Decimal; CancelledQtyBase: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateCreditMemoOnBeforePageRun(var RentalHeader: Record "TWE Rental Header"; var IsHandled: Boolean)
    begin
    end;
}

