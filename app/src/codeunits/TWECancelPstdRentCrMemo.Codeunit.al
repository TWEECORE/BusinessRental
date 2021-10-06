codeunit 50003 "TWE Cancel Pstd. Rent.Cr. Memo"
{
    Permissions = TableData "TWE Rental Invoice Header" = rm,
                  TableData "TWE Rental Cr.Memo Header" = rm;
    TableNo = "TWE Rental Cr.Memo Header";

    trigger OnRun()
    var
        RentalHeader: Record "TWE Rental Header";
    begin
        UnapplyEntries(Rec);
        CreateCopyDocument(Rec, RentalHeader);

        CODEUNIT.Run(CODEUNIT::"TWE Rental-Post", RentalHeader);
        SetTrackInfoForCancellation(Rec);

        Commit();
    end;

    var
        AlreadyCancelledErr: Label 'You cannot cancel this posted sales credit memo because it has already been cancelled.';
        NotCorrectiveDocErr: Label 'You cannot cancel this posted sales credit memo because it is not a corrective document.';
        CustomerIsBlockedCancelErr: Label 'You cannot cancel this posted sales credit memo because customer %1 is blocked.', Comment = '%1 = Customer name';
        ItemIsBlockedCancelErr: Label 'You cannot cancel this posted sales credit memo because item %1 %2 is blocked.', Comment = '%1 = Item No. %2 = Item Description';
        AccountIsBlockedCancelErr: Label 'You cannot cancel this posted sales credit memo because %1 %2 is blocked.', Comment = '%1 = Table Caption %2 = Account number.';
        NoFreeInvoiceNoSeriesCancelErr: Label 'You cannot cancel this posted sales credit memo because no unused invoice numbers are available. \\You must extend the range of the number series for sales invoices.';
        NoFreePostInvSeriesCancelErr: Label 'You cannot cancel this posted sales credit memo because no unused posted invoice numbers are available. \\You must extend the range of the number series for posted invoices.';
        PostingNotAllowedCancelErr: Label 'You cannot cancel this posted sales credit memo because it was posted in a posting period that is closed.';
        InvalidDimCodeCancelErr: Label 'You cannot cancel this posted sales credit memo because the dimension rule setup for account ''%1'' %2 prevents %3 %4 from being cancelled.', Comment = '%1 = Table caption %2 = Account number %3 = Item no. %4 = Item description.';
        InvalidDimCombinationCancelErr: Label 'You cannot cancel this posted sales credit memo because the dimension combination for item %1 %2 is not allowed.', Comment = '%1 = Item no. %2 = Item description.';
        InvalidDimCombHeaderCancelErr: Label 'You cannot cancel this posted sales credit memo because the combination of dimensions on the credit memo is blocked.';
        ExternalDocCancelErr: Label 'You cannot cancel this posted sales credit memo because the external document number is required on the credit memo.';
        InventoryPostClosedCancelErr: Label 'You cannot cancel this posted sales credit memo because the inventory period is already closed.';
        PostingCreditMemoFailedOpenPostedInvQst: Label 'Canceling the credit memo failed because of the following error: \\%1\\An invoice is posted. Do you want to open the posted invoice?', Comment = '%1 = error text';
        PostingCreditMemoFailedOpenInvQst: Label 'Canceling the credit memo failed because of the following error: \\%1\\An invoice is created but not posted. Do you want to open the invoice?', Comment = '%1 = error text';
        CreatingInvFailedNothingCreatedErr: Label 'Canceling the credit memo failed because of the following error: \\%1.', Comment = '%1 = error text';
        ErrorType: Option CustomerBlocked,ItemBlocked,AccountBlocked,IsAppliedIncorrectly,IsUnapplied,IsCanceled,IsCorrected,SerieNumInv,SerieNumPostInv,FromOrder,PostingNotAllowed,DimErr,DimCombErr,DimCombHeaderErr,ExtDocErr,InventoryPostClosed;
        UnappliedErr: Label 'You cannot cancel this posted sales credit memo because it is fully or partially applied.\\To reverse an applied sales credit memo, you must manually unapply all applied entries.';
        NotAppliedCorrectlyErr: Label 'You cannot cancel this posted sales credit memo because it is not fully applied to an invoice.';

    procedure CancelPostedCrMemo(var RentalCrMemoHeader: Record "TWE Rental Cr.Memo Header"): Boolean
    var
        RentalHeader: Record "TWE Rental Header";
        RentalInvHeader: Record "TWE Rental Invoice Header";
    begin
        TestCorrectCrMemoIsAllowed(RentalCrMemoHeader);
        if not CODEUNIT.Run(CODEUNIT::"TWE Cancel Pstd. Rent.Cr. Memo", RentalCrMemoHeader) then begin
            RentalInvHeader.SetRange("Applies-to Doc. No.", RentalCrMemoHeader."No.");
            if RentalInvHeader.FindFirst() then begin
                if Confirm(StrSubstNo(PostingCreditMemoFailedOpenPostedInvQst, GetLastErrorText)) then
                    PAGE.Run(PAGE::"TWE Posted Rental Invoice", RentalInvHeader);
            end else begin
                RentalHeader.SetRange("Applies-to Doc. No.", RentalCrMemoHeader."No.");
                if RentalHeader.FindFirst() then begin
                    if Confirm(StrSubstNo(PostingCreditMemoFailedOpenInvQst, GetLastErrorText)) then
                        PAGE.Run(PAGE::"TWE Rental Invoice", RentalHeader);
                end else
                    Error(CreatingInvFailedNothingCreatedErr, GetLastErrorText);
            end;
            exit(false);
        end;
        exit(true);
    end;

    local procedure CreateCopyDocument(var RentalCrMemoHeader: Record "TWE Rental Cr.Memo Header"; var RentalHeader: Record "TWE Rental Header")
    var
        RentalCopyDocMgt: Codeunit "TWE Copy Rental Document Mgt.";
    begin
        Clear(RentalHeader);
        RentalHeader."No." := '';
        RentalHeader."Document Type" := RentalHeader."Document Type"::Invoice;
        RentalHeader.Insert(true);
        RentalCopyDocMgt.SetPropertiesForInvoiceCorrection(false);
        RentalCopyDocMgt.CopyRentalDocForCrMemoCancelling(RentalCrMemoHeader."No.", RentalHeader);
    end;

    procedure TestCorrectCrMemoIsAllowed(var RentalCrMemoHeader: Record "TWE Rental Cr.Memo Header")
    begin
        TestIfPostingIsAllowed(RentalCrMemoHeader);
        TestIfCustomerIsBlocked(RentalCrMemoHeader, RentalCrMemoHeader."Rented-to Customer No.");
        TestIfCustomerIsBlocked(RentalCrMemoHeader, RentalCrMemoHeader."Bill-to Customer No.");
        TestIfInvoiceIsCorrectedOnce(RentalCrMemoHeader);
        TestIfCrMemoIsCorrectiveDoc(RentalCrMemoHeader);
        TestCustomerDimension(RentalCrMemoHeader, RentalCrMemoHeader."Bill-to Customer No.");
        TestDimensionOnHeader(RentalCrMemoHeader);
        TestRentalLines(RentalCrMemoHeader);
        TestIfAnyFreeNumberSeries(RentalCrMemoHeader);
        TestExternalDocument(RentalCrMemoHeader);
        TestInventoryPostingClosed(RentalCrMemoHeader);

        OnAfterTestCorrectCrMemoIsAllowed(RentalCrMemoHeader);
    end;

    local procedure SetTrackInfoForCancellation(var RentalCrMemoHeader: Record "TWE Rental Cr.Memo Header")
    var
        RentalInvHeader: Record "TWE Rental Invoice Header";
        CancelledRentalDocument: Record "TWE Cancelled Rental Document";
    begin
        RentalInvHeader.SetRange("Applies-to Doc. No.", RentalCrMemoHeader."No.");
        if RentalInvHeader.FindLast() then
            CancelledRentalDocument.InsertRentalCrMemoToInvCancelledDocument(RentalCrMemoHeader."No.", RentalInvHeader."No.");
    end;

    local procedure TestDimensionOnHeader(RentalCrMemoHeader: Record "TWE Rental Cr.Memo Header")
    var
        DimensionManagement: Codeunit DimensionManagement;
    begin
        if not DimensionManagement.CheckDimIDComb(RentalCrMemoHeader."Dimension Set ID") then
            ErrorHelperHeader(ErrorType::DimCombHeaderErr, RentalCrMemoHeader);
    end;

    local procedure TestIfCustomerIsBlocked(RentalCrMemoHeader: Record "TWE Rental Cr.Memo Header"; CustNo: Code[20])
    var
        Customer: Record Customer;
    begin
        Customer.Get(CustNo);
        if Customer.Blocked in [Customer.Blocked::Invoice, Customer.Blocked::All] then
            ErrorHelperHeader(ErrorType::CustomerBlocked, RentalCrMemoHeader);
    end;

    local procedure TestIfAppliedCorrectly(RentalCrMemoHeader: Record "TWE Rental Cr.Memo Header"; CustLedgEntry: Record "Cust. Ledger Entry")
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        PartiallyApplied: Boolean;
    begin
        CustLedgEntry.CalcFields(Amount, "Remaining Amount");
        PartiallyApplied :=
          ((CustLedgEntry.Amount <> CustLedgEntry."Remaining Amount") and (CustLedgEntry."Remaining Amount" <> 0));
        if (CalcDtldCustLedgEntryCount(DetailedCustLedgEntry."Entry Type"::"Initial Entry", CustLedgEntry."Entry No.") <> 1) or
           (not (CalcDtldCustLedgEntryCount(DetailedCustLedgEntry."Entry Type"::Application, CustLedgEntry."Entry No.") in [0, 1])) or
           AnyDtldCustLedgEntriesExceptInitialAndApplicaltionExists(CustLedgEntry."Entry No.") or
           PartiallyApplied
        then
            ErrorHelperHeader(ErrorType::IsAppliedIncorrectly, RentalCrMemoHeader);
    end;

    local procedure TestIfUnapplied(RentalCrMemoHeader: Record "TWE Rental Cr.Memo Header")
    begin
        RentalCrMemoHeader.CalcFields("Amount Including VAT");
        RentalCrMemoHeader.CalcFields("Remaining Amount");
        if RentalCrMemoHeader."Amount Including VAT" <> -RentalCrMemoHeader."Remaining Amount" then
            ErrorHelperHeader(ErrorType::IsUnapplied, RentalCrMemoHeader);
    end;

    local procedure TestCustomerDimension(RentalCrMemoHeader: Record "TWE Rental Cr.Memo Header"; CustNo: Code[20])
    var
        Customer: Record Customer;
        DimensionManagement: Codeunit DimensionManagement;
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
    begin
        Customer.Get(CustNo);
        TableID[1] := DATABASE::Customer;
        No[1] := Customer."No.";
        if not DimensionManagement.CheckDimValuePosting(TableID, No, RentalCrMemoHeader."Dimension Set ID") then
            ErrorHelperAccount(ErrorType::DimErr, Customer."No.", Customer.TableCaption, Customer."No.", Customer.Name);
    end;

    local procedure TestRentalLines(RentalCrMemoHeader: Record "TWE Rental Cr.Memo Header")
    var
        RentalCrMemoLine: Record "TWE Rental Cr.Memo Line";
        MainRentalItem: Record "TWE Main Rental Item";
        DimensionManagement: Codeunit DimensionManagement;
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
    begin
        RentalCrMemoLine.SetRange("Document No.", RentalCrMemoHeader."No.");
        if RentalCrMemoLine.Find('-') then
            repeat
                if not IsCommentLine(RentalCrMemoLine) then begin
                    if RentalCrMemoLine.Type = RentalCrMemoLine.Type::"Rental Item" then begin
                        MainRentalItem.Get(RentalCrMemoLine."No.");

                        if MainRentalItem.Blocked then
                            ErrorHelperLine(ErrorType::ItemBlocked, RentalCrMemoLine);

                        TableID[1] := DATABASE::Item;
                        No[1] := RentalCrMemoLine."No.";
                        if not DimensionManagement.CheckDimValuePosting(TableID, No, RentalCrMemoLine."Dimension Set ID") then
                            ErrorHelperAccount(ErrorType::DimErr, No[1], MainRentalItem.TableCaption, MainRentalItem."No.", MainRentalItem.Description);
                    end;

                    TestGenPostingSetup(RentalCrMemoLine);
                    TestCustomerPostingGroup(RentalCrMemoLine, RentalCrMemoHeader."Customer Posting Group");
                    TestVATPostingSetup(RentalCrMemoLine);

                    if not DimensionManagement.CheckDimIDComb(RentalCrMemoLine."Dimension Set ID") then
                        ErrorHelperLine(ErrorType::DimCombErr, RentalCrMemoLine);
                end;
            until RentalCrMemoLine.Next() = 0;
    end;

    local procedure TestGLAccount(AccountNo: Code[20]; RentalCrMemoLine: Record "TWE Rental Cr.Memo Line")
    var
        GLAccount: Record "G/L Account";
        Item: Record Item;
        DimensionManagement: Codeunit DimensionManagement;
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
    begin
        GLAccount.Get(AccountNo);
        if GLAccount.Blocked then
            ErrorHelperAccount(ErrorType::AccountBlocked, AccountNo, GLAccount.TableCaption(), '', '');
        TableID[1] := DATABASE::"G/L Account";
        No[1] := AccountNo;

        if RentalCrMemoLine.Type = RentalCrMemoLine.Type::"Rental Item" then begin
            Item.Get(RentalCrMemoLine."No.");
            if not DimensionManagement.CheckDimValuePosting(TableID, No, RentalCrMemoLine."Dimension Set ID") then
                ErrorHelperAccount(ErrorType::DimErr, AccountNo, GLAccount.TableCaption(), Item."No.", Item.Description);
        end;
    end;

    local procedure TestIfInvoiceIsCorrectedOnce(RentalCrMemoHeader: Record "TWE Rental Cr.Memo Header")
    var
        CancelledRentalDocument: Record "TWE Cancelled Rental Document";
    begin
        if CancelledRentalDocument.FindRentalCancelledCrMemo(RentalCrMemoHeader."No.") then
            ErrorHelperHeader(ErrorType::IsCorrected, RentalCrMemoHeader);
    end;

    local procedure TestIfCrMemoIsCorrectiveDoc(RentalCrMemoHeader: Record "TWE Rental Cr.Memo Header")
    var
        CancelledRentalDocument: Record "TWE Cancelled Rental Document";
    begin
        if not CancelledRentalDocument.FindRentalCorrectiveCrMemo(RentalCrMemoHeader."No.") then
            ErrorHelperHeader(ErrorType::IsCanceled, RentalCrMemoHeader);
    end;

    local procedure TestIfPostingIsAllowed(RentalCrMemoHeader: Record "TWE Rental Cr.Memo Header")
    var
        GenJnlCheckLine: Codeunit "Gen. Jnl.-Check Line";
    begin
        if GenJnlCheckLine.DateNotAllowed(RentalCrMemoHeader."Posting Date") then
            ErrorHelperHeader(ErrorType::PostingNotAllowed, RentalCrMemoHeader);
    end;

    local procedure TestIfAnyFreeNumberSeries(RentalCrMemoHeader: Record "TWE Rental Cr.Memo Header")
    var
        RentalSetup: Record "TWE Rental Setup";
        NoSeriesManagement: Codeunit NoSeriesManagement;
        PostingDate: Date;
    begin
        PostingDate := WorkDate();
        RentalSetup.Get();

        if NoSeriesManagement.TryGetNextNo(RentalSetup."Rental Invoice Nos.", PostingDate) = '' then
            ErrorHelperHeader(ErrorType::SerieNumInv, RentalCrMemoHeader);

        if NoSeriesManagement.TryGetNextNo(RentalSetup."Posted Rental Invoice Nos.", PostingDate) = '' then
            ErrorHelperHeader(ErrorType::SerieNumPostInv, RentalCrMemoHeader);
    end;

    local procedure TestExternalDocument(RentalCrMemoHeader: Record "TWE Rental Cr.Memo Header")
    var
        RentalSetup: Record "TWE Rental Setup";
    begin
        RentalSetup.Get();
        if (RentalCrMemoHeader."External Document No." = '') and RentalSetup."Ext. Doc. No. Mandatory" then
            ErrorHelperHeader(ErrorType::ExtDocErr, RentalCrMemoHeader);
    end;

    local procedure TestInventoryPostingClosed(RentalCrMemoHeader: Record "TWE Rental Cr.Memo Header")
    var
        InventoryPeriod: Record "Inventory Period";
    begin
        InventoryPeriod.SetRange(Closed, true);
        InventoryPeriod.SetFilter("Ending Date", '>=%1', RentalCrMemoHeader."Posting Date");
        if not InventoryPeriod.IsEmpty() then
            ErrorHelperHeader(ErrorType::InventoryPostClosed, RentalCrMemoHeader);
    end;

    local procedure TestGenPostingSetup(RentalCrMemoLine: Record "TWE Rental Cr.Memo Line")
    var
        GenPostingSetup: Record "General Posting Setup";
        MainRentalItem: Record "TWE Main Rental Item";
    begin
        GenPostingSetup.Get(RentalCrMemoLine."Gen. Bus. Posting Group", RentalCrMemoLine."Gen. Prod. Posting Group");
        GenPostingSetup.TestField("TWE Rental Account");
        TestGLAccount(GenPostingSetup."TWE Rental Account", RentalCrMemoLine);
        GenPostingSetup.TestField("TWE Rental Credit Memo Account");
        TestGLAccount(GenPostingSetup."TWE Rental Credit Memo Account", RentalCrMemoLine);
        GenPostingSetup.TestField("TWE Rental Line Disc. Account");
        TestGLAccount(GenPostingSetup."TWE Rental Line Disc. Account", RentalCrMemoLine);
        if RentalCrMemoLine.Type = RentalCrMemoLine.Type::"Rental Item" then begin
            MainRentalItem.Get(RentalCrMemoLine."No.");
            if MainRentalItem.IsInventoriableType() then
                TestGLAccount(GenPostingSetup.GetCOGSAccount(), RentalCrMemoLine);
        end;
    end;

    local procedure TestCustomerPostingGroup(RentalCrMemoLine: Record "TWE Rental Cr.Memo Line"; CustomerPostingGr: Code[20])
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        CustomerPostingGroup.Get(CustomerPostingGr);
        CustomerPostingGroup.TestField("Receivables Account");
        TestGLAccount(CustomerPostingGroup."Receivables Account", RentalCrMemoLine);
    end;

    local procedure TestVATPostingSetup(RentalCrMemoLine: Record "TWE Rental Cr.Memo Line")
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.Get(RentalCrMemoLine."VAT Bus. Posting Group", RentalCrMemoLine."VAT Prod. Posting Group");
        if VATPostingSetup."VAT Calculation Type" <> VATPostingSetup."VAT Calculation Type"::"Sales Tax" then begin
            VATPostingSetup.TestField(VATPostingSetup."TWE Rental VAT Account");
            TestGLAccount(VATPostingSetup."TWE Rental VAT Account", RentalCrMemoLine);
        end;
    end;

    local procedure TestInventoryPostingSetup(RentalCrMemoLine: Record "TWE Rental Cr.Memo Line")
    var
        InventoryPostingSetup: Record "Inventory Posting Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestInventoryPostingSetup(RentalCrMemoLine, IsHandled);
        if IsHandled then
            exit;

        InventoryPostingSetup.Get(RentalCrMemoLine."Location Code", RentalCrMemoLine."Posting Group");
        InventoryPostingSetup.TestField("Inventory Account");
        TestGLAccount(InventoryPostingSetup."Inventory Account", RentalCrMemoLine);
    end;

    local procedure UnapplyEntries(RentalCrMemoHeader: Record "TWE Rental Cr.Memo Header")
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        CustEntryApplyPostedEntries: Codeunit "CustEntry-Apply Posted Entries";
    begin
        FindCustLedgEntry(CustLedgEntry, RentalCrMemoHeader."No.");
        TestIfAppliedCorrectly(RentalCrMemoHeader, CustLedgEntry);
        if CustLedgEntry.Open then
            exit;

        FindDetailedApplicationEntry(DetailedCustLedgEntry, CustLedgEntry);
        CustEntryApplyPostedEntries.PostUnApplyCustomer(
          DetailedCustLedgEntry, DetailedCustLedgEntry."Document No.", DetailedCustLedgEntry."Posting Date");
        TestIfUnapplied(RentalCrMemoHeader);
    end;

    local procedure FindCustLedgEntry(var CustLedgEntry: Record "Cust. Ledger Entry"; DocNo: Code[20])
    begin
        CustLedgEntry.SetRange("Document Type", CustLedgEntry."Document Type"::"Credit Memo");
        CustLedgEntry.SetRange("Document No.", DocNo);
        CustLedgEntry.FindLast();
    end;

    local procedure FindDetailedApplicationEntry(var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; CustLedgEntry: Record "Cust. Ledger Entry")
    begin
        DetailedCustLedgEntry.SetRange("Entry Type", DetailedCustLedgEntry."Entry Type"::Application);
        DetailedCustLedgEntry.SetRange("Customer No.", CustLedgEntry."Customer No.");
        DetailedCustLedgEntry.SetRange("Document No.", CustLedgEntry."Document No.");
        DetailedCustLedgEntry.SetRange("Cust. Ledger Entry No.", CustLedgEntry."Entry No.");
        DetailedCustLedgEntry.SetRange(Unapplied, false);
        DetailedCustLedgEntry.FindFirst();
    end;

    local procedure AnyDtldCustLedgEntriesExceptInitialAndApplicaltionExists(CustLedgEntryNo: Integer): Boolean
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DetailedCustLedgEntry.SetFilter(
          "Entry Type", '<>%1&<>%2', DetailedCustLedgEntry."Entry Type"::"Initial Entry", DetailedCustLedgEntry."Entry Type"::Application);
        DetailedCustLedgEntry.SetRange("Cust. Ledger Entry No.", CustLedgEntryNo);
        exit(not DetailedCustLedgEntry.IsEmpty);
    end;

    local procedure CalcDtldCustLedgEntryCount(EntryType: Enum "Detailed CV Ledger Entry Type"; CustLedgEntryNo: Integer): Integer
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DetailedCustLedgEntry.SetRange("Entry Type", EntryType);
        DetailedCustLedgEntry.SetRange("Cust. Ledger Entry No.", CustLedgEntryNo);
        DetailedCustLedgEntry.SetRange(Unapplied, false);
        exit(DetailedCustLedgEntry.Count);
    end;

    local procedure IsCommentLine(RentalCrMemoLine: Record "TWE Rental Cr.Memo Line"): Boolean
    begin
        exit((RentalCrMemoLine.Type = RentalCrMemoLine.Type::" ") or (RentalCrMemoLine."No." = ''));
    end;

    local procedure ErrorHelperHeader(ErrorOption: Option; RentalCrMemoHeader: Record "TWE Rental Cr.Memo Header")
    var
        Customer: Record Customer;
    begin
        case ErrorOption of
            ErrorType::CustomerBlocked:
                begin
                    Customer.Get(RentalCrMemoHeader."Bill-to Customer No.");
                    Error(CustomerIsBlockedCancelErr, Customer.Name);
                end;
            ErrorType::IsAppliedIncorrectly:
                Error(NotAppliedCorrectlyErr);
            ErrorType::IsUnapplied:
                Error(UnappliedErr);
            ErrorType::IsCorrected:
                Error(AlreadyCancelledErr);
            ErrorType::IsCanceled:
                Error(NotCorrectiveDocErr);
            ErrorType::SerieNumInv:
                Error(NoFreeInvoiceNoSeriesCancelErr);
            ErrorType::SerieNumPostInv:
                Error(NoFreePostInvSeriesCancelErr);
            ErrorType::PostingNotAllowed:
                Error(PostingNotAllowedCancelErr);
            ErrorType::ExtDocErr:
                Error(ExternalDocCancelErr);
            ErrorType::InventoryPostClosed:
                Error(InventoryPostClosedCancelErr);
            ErrorType::DimCombHeaderErr:
                Error(InvalidDimCombHeaderCancelErr);
        end
    end;

    local procedure ErrorHelperLine(ErrorOption: Option; RentalCrMemoLine: Record "TWE Rental Cr.Memo Line")
    var
        MainRentalItem: Record "TWE Main Rental Item";
    begin
        case ErrorOption of
            ErrorType::ItemBlocked:
                begin
                    MainRentalItem.Get(RentalCrMemoLine."No.");
                    Error(ItemIsBlockedCancelErr, MainRentalItem."No.", MainRentalItem.Description);
                end;
            ErrorType::DimCombErr:
                Error(InvalidDimCombinationCancelErr, RentalCrMemoLine."No.", RentalCrMemoLine.Description);
        end
    end;

    local procedure ErrorHelperAccount(ErrorOption: Option; AccountNo: Code[20]; AccountCaption: Text; No: Code[20]; Name: Text)
    begin
        case ErrorOption of
            ErrorType::AccountBlocked:
                Error(AccountIsBlockedCancelErr, AccountCaption, AccountNo);
            ErrorType::DimErr:
                Error(InvalidDimCodeCancelErr, AccountCaption, AccountNo, No, Name);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTestCorrectCrMemoIsAllowed(var RentalCrMemoHeader: Record "TWE Rental Cr.Memo Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestInventoryPostingSetup(RentalCrMemoLine: Record "TWE Rental Cr.Memo Line"; var IsHandled: Boolean)
    begin
    end;
}

