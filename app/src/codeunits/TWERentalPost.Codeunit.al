/// <summary>
/// Codeunit TWE Rental-Post (ID 50029).
/// </summary>

codeunit 50029 "TWE Rental-Post"
{
    Permissions = TableData "TWE Rental Line" = imd,
                  TableData "Purchase Header" = m,
                  TableData "Purchase Line" = m,
                  TableData "Invoice Post. Buffer" = imd,
                  TableData "TWE Rental Shipment Header" = imd,
                  TableData "TWE Rental Shipment Line" = imd,
                  TableData "TWE Rental Invoice Header" = imd,
                  TableData "TWE Rental Invoice Line" = imd,
                  TableData "TWE Rental Return Ship. Header" = imd,
                  TableData "TWE Rental Return Ship. Line" = imd,
                  TableData "TWE Rental Cr.Memo Header" = imd,
                  TableData "TWE Rental Cr.Memo Line" = imd,
                  TableData "Purch. Rcpt. Header" = imd,
                  TableData "Purch. Rcpt. Line" = imd,
                  TableData "Drop Shpt. Post. Buffer" = imd,
                  TableData "General Posting Setup" = imd,
                  TableData "Posted Assemble-to-Order Link" = i,
                  TableData "Item Entry Relation" = ri,
                  TableData "Value Entry Relation" = rid,
                  TableData "Return Receipt Header" = imd,
                  TableData "Return Receipt Line" = imd;
    TableNo = "TWE Rental Header";

    trigger OnRun()
    var
        RentalHeader: Record "TWE Rental Header";
        TempInvoicePostBuffer: Record "Invoice Post. Buffer" temporary;
        TempItemLedgEntryNotInvoiced: Record "Item Ledger Entry" temporary;
        CustLedgEntry: Record "Cust. Ledger Entry";
        TempServiceItem2: Record "Service Item" temporary;
        TempServiceItemComp2: Record "Service Item Component" temporary;
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        TempVATAmountLineRemainder: Record "VAT Amount Line" temporary;
        TempDropShptPostBuffer: Record "Drop Shpt. Post. Buffer" temporary;
        DisableAggregateTableUpdate: Codeunit "Disable Aggregate Table Update";
        UpdateAnalysisView: Codeunit "Update Analysis View";
        UpdateItemAnalysisView: Codeunit "Update Item Analysis View";
        ErrorContextElementProcessLines: Codeunit "Error Context Element";
        ErrorContextElementPostLine: Codeunit "Error Context Element";
        ZeroRentalLineRecID: RecordId;
        HasATOShippedNotInvoiced: Boolean;
        EverythingInvoiced: Boolean;
        SavedPreviewMode: Boolean;
        SavedSuppressCommit: Boolean;
        BiggestLineNo: Integer;
        ICGenJnlLineNo: Integer;
        LineCount: Integer;
        SavedHideProgressWindow: Boolean;
    begin

        PostingEvents.OnBeforePostRentalDoc(Rec, SuppressCommit, PreviewMode, HideProgressWindow);
        if not GuiAllowed then
            LockTimeout(false);

        SetupDisableAggregateTableUpdate(Rec, DisableAggregateTableUpdate);

        ValidatePostingAndDocumentDate(Rec);

        SavedPreviewMode := PreviewMode;
        SavedSuppressCommit := SuppressCommit;
        SavedHideProgressWindow := HideProgressWindow;
        ClearAllVariables();
        SuppressCommit := SavedSuppressCommit;
        PreviewMode := SavedPreviewMode;
        HideProgressWindow := SavedHideProgressWindow;

        GetGLSetup();
        GetCurrency(Rec."Currency Code");

        GetSalesSetup();
        RentalHeader := Rec;
        FillTempLines(RentalHeader, TempRentalLineGlobal);
        TempServiceItem2.DeleteAll();
        TempServiceItemComp2.DeleteAll();

        if RentalHeader.Invoice then
            CheckTotalInvoiceAmount(RentalHeader);

        // Header
        CheckAndUpdate(RentalHeader);

        TempDeferralHeader.DeleteAll();
        TempDeferralLine.DeleteAll();
        TempInvoicePostBuffer.DeleteAll();
        TempDropShptPostBuffer.DeleteAll();
        EverythingInvoiced := true;

        // Lines
        GetZeroRentalLineRecID(RentalHeader, ZeroRentalLineRecID);
        ErrorMessageMgt.PushContext(ErrorContextElementProcessLines, ZeroRentalLineRecID, 0, PostDocumentLinesMsg);
        PostingEvents.OnBeforePostLines(TempRentalLineGlobal, RentalHeader, SuppressCommit, PreviewMode);

        LineCount := 0;
        RoundingLineInserted := false;
        AdjustFinalInvWith100PctPrepmt(TempRentalLineGlobal);

        TempVATAmountLineRemainder.DeleteAll();
        TempRentalLineGlobal.CalcVATAmountLines(1, RentalHeader, TempRentalLineGlobal, TempVATAmountLine);

        PostingEvents.OnBeforePostRentalLines(RentalHeader, TempRentalLineGlobal, TempVATAmountLine);

        RentalLinesProcessed := false;
        if TempRentalLineGlobal.FindSet() then
            repeat
                ErrorMessageMgt.PushContext(ErrorContextElementPostLine, TempRentalLineGlobal.RecordId, 0, PostDocumentLinesMsg);
                ItemJnlRollRndg := false;
                LineCount := LineCount + 1;
                if not HideProgressWindow then
                    Window.Update(2, LineCount);

                PostRentalLine(
                  RentalHeader, TempRentalLineGlobal, EverythingInvoiced, TempInvoicePostBuffer, TempVATAmountLine, TempVATAmountLineRemainder,
                  TempItemLedgEntryNotInvoiced, HasATOShippedNotInvoiced, TempDropShptPostBuffer, ICGenJnlLineNo,
                  TempServiceItem2, TempServiceItemComp2);

                if RoundingLineInserted then
                    LastLineRetrieved := true
                else begin
                    BiggestLineNo := MAX(BiggestLineNo, TempRentalLineGlobal."Line No.");
                    LastLineRetrieved := TempRentalLineGlobal.Next() = 0;
                    if LastLineRetrieved and RentalSetup."Invoice Rounding" then
                        InvoiceRounding(RentalHeader, TempRentalLineGlobal, false, BiggestLineNo);
                end;
            until LastLineRetrieved;

        PostingEvents.OnAfterPostRentalLines(
          RentalHeader, RentalShptHeader, RentalInvHeader, RentalCrMemoHeader, ReturnRcptHeader, WhseShip, WhseReceive, RentalLinesProcessed,
          SuppressCommit, EverythingInvoiced);
        ErrorMessageMgt.Finish(ZeroRentalLineRecID);
        if not RentalHeader.IsCreditDocType() then begin
            ReverseAmount(TotalRentalLine);
            ReverseAmount(TotalRentalLineLCY);
            TotalRentalLineLCY."Unit Cost (LCY)" := -TotalRentalLineLCY."Unit Cost (LCY)";
        end;

        PostDropOrderShipment(RentalHeader, TempDropShptPostBuffer);
        if RentalHeader.Invoice then
            PostGLAndCustomer(RentalHeader, TempInvoicePostBuffer, CustLedgEntry);

        if ICGenJnlLineNo > 0 then
            PostICGenJnl();

        MakeInventoryAdjustment();
        UpdateLastPostingNos(RentalHeader);

        PostingEvents.OnRunOnBeforeFinalizePosting(
          RentalHeader, RentalShptHeader, RentalInvHeader, RentalCrMemoHeader, ReturnRcptHeader, GenJnlPostLine, SuppressCommit);

        FinalizePosting(RentalHeader, EverythingInvoiced, TempDropShptPostBuffer);

        Rec := RentalHeader;
        SynchBOMSerialNo(TempServiceItem2, TempServiceItemComp2);
        if not (InvtPickPutaway or SuppressCommit) then begin
            Commit();
            UpdateAnalysisView.UpdateAll(0, true);
            UpdateItemAnalysisView.UpdateAll(0, true);
        end;

        PostingEvents.OnAfterPostRentalDoc(
          Rec, GenJnlPostLine, RentalShptHeader."No.", ReturnRcptHeader."No.",
          RentalInvHeader."No.", RentalCrMemoHeader."No.", SuppressCommit, InvtPickPutaway,
          CustLedgEntry, WhseShip, WhseReceive);
        PostingEvents.OnAfterPostRentalDocDropShipment(PurchRcptHeader."No.", SuppressCommit);
    end;

    var
        NothingToPostErr: Label 'There is nothing to post.';
        PostingLinesMsg: Label 'Posting lines              #2######\', Comment = '#2###### Counter';
        PostingSalesAndVATMsg: Label 'Posting sales and VAT      #3######\', Comment = '#3###### Counter';
        PostingCustomersMsg: Label 'Posting to customers       #4######\', Comment = '#4###### Counter';
        PostingBalAccountMsg: Label 'Posting to bal. account    #5######', Comment = '#5###### Counter';
        PostingLines2Msg: Label 'Posting lines              #2######', Comment = '#2###### Counter';
        InvoiceNoMsg: Label '%1 %2 -> Invoice %3', Comment = '%1 = Document Type, %2 = Document No, %3 = Invoice No.';
        CreditMemoNoMsg: Label '%1 %2 -> Credit Memo %3', Comment = '%1 = Document Type, %2 = Document No, %3 = Credit Memo No.';
        DropShipmentErr: Label 'You cannot ship sales order line %1. The line is marked as a drop shipment and is not yet associated with a purchase order.', Comment = '%1 = Line No.';
        ShipmentSameSignErr: Label 'must have the same sign as the shipment';
        ShipmentLinesDeletedErr: Label 'The shipment lines have been deleted.';
        InvoiceMoreThanShippedErr: Label 'You cannot invoice more than you have shipped for order %1.', Comment = '%1 = Order No.';
        VATAmountTxt: Label 'VAT Amount';
        VATRateTxt: Label '%1% VAT', Comment = '%1 = VAT Rate';
        BlanketOrderQuantityGreaterThanErr: Label 'in the associated blanket order must not be greater than %1', Comment = '%1 = Quantity';
        BlanketOrderQuantityReducedErr: Label 'in the associated blanket order must not be reduced';
        ShipInvoiceReceiveErr: Label 'Please enter "Yes" in Ship and/or Invoice and/or Receive.';
        WarehouseRequiredErr: Label 'Warehouse handling is required for %1 = %2, %3 = %4, %5 = %6.', Comment = '%1/%2 = Document Type, %3/%4 - Document No.,%5/%6 = Line No.';
        ReturnReceiptSameSignErr: Label 'must have the same sign as the return receipt';
        ReturnReceiptInvoicedErr: Label 'Line %1 of the return receipt %2, which you are attempting to invoice, has already been invoiced.', Comment = '%1 = Line No., %2 = Document No.';
        ShipmentInvoiceErr: Label 'Line %1 of the shipment %2, which you are attempting to invoice, has already been invoiced.', Comment = '%1 = Line No., %2 = Document No.';
        QuantityToInvoiceGreaterErr: Label 'The quantity you are attempting to invoice is greater than the quantity in shipment %1.', Comment = '%1 = Document No.';
        CannotAssignMoreErr: Label 'You cannot assign more than %1 units in %2 = %3, %4 = %5,%6 = %7.', Comment = '%1 = Quantity, %2/%3 = Document Type, %4/%5 - Document No.,%6/%7 = Line No.';
        MustAssignErr: Label 'You must assign all item charges, if you invoice everything.';
        MainRentalItem: Record "TWE Main Rental Item";
        RentalSetup: Record "TWE Rental Setup";
        GLSetup: Record "General Ledger Setup";
        [SecurityFiltering(SecurityFilter::Ignored)]
        GLEntry: Record "G/L Entry";
        TempRentalLineGlobal: Record "TWE Rental Line" temporary;
        xRentalLine: Record "TWE Rental Line";
        RentalLineACY: Record "TWE Rental Line";
        TotalRentalLine: Record "TWE Rental Line";
        TotalRentalLineLCY: Record "TWE Rental Line";
        RentalShptHeader: Record "TWE Rental Shipment Header";
        RentalInvHeader: Record "TWE Rental Invoice Header";
        RentalCrMemoHeader: Record "TWE Rental Cr.Memo Header";
        RentalRtnShipHeader: Record "TWE Rental Return Ship. Header";
        ReturnRcptHeader: Record "Return Receipt Header";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)";
        TempItemChargeAssgntSales: Record "Item Charge Assignment (Sales)" temporary;
        SourceCodeSetup: Record "Source Code Setup";
        Currency: Record Currency;
        WhseRcptHeader: Record "Warehouse Receipt Header";
        TempWhseRcptHeader: Record "Warehouse Receipt Header" temporary;
        WhseShptHeader: Record "Warehouse Shipment Header";
        TempWhseShptHeader: Record "Warehouse Shipment Header" temporary;
        PostedWhseRcptHeader: Record "Posted Whse. Receipt Header";
        PostedWhseRcptLine: Record "Posted Whse. Receipt Line";
        PostedWhseShptHeader: Record "Posted Whse. Shipment Header";
        PostedWhseShptLine: Record "Posted Whse. Shipment Line";
        Location: Record Location;
        TempHandlingSpecification: Record "Tracking Specification" temporary;
        TempATOTrackingSpecification: Record "Tracking Specification" temporary;
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        TempTrackingSpecificationInv: Record "Tracking Specification" temporary;
        TempWhseSplitSpecification: Record "Tracking Specification" temporary;
        TempValueEntryRelation: Record "Value Entry Relation" temporary;
        JobTaskRentalLine: Record "TWE Rental Line";
        TempICGenJnlLine: Record "Gen. Journal Line" temporary;
        TempPrepmtDeductLCYRentalLine: Record "TWE Rental Line" temporary;
        TempSKU: Record "Stockkeeping Unit" temporary;
        DeferralPostBuffer: Record "Deferral Posting Buffer";
        TempDeferralHeader: Record "Deferral Header" temporary;
        TempDeferralLine: Record "Deferral Line" temporary;
        PostingEvents: Codeunit "TWE Rental-Post Events";
        ErrorMessageMgt: Codeunit "Error Message Management";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        ResJnlPostLine: Codeunit "Res. Jnl.-Post Line";
        RentalItemJnlPostLine: Codeunit "TWE Rental Item Jnl.-Post Line";
        ReserveSalesLine: Codeunit "Sales Line-Reserve";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        WhseJnlPostLine: Codeunit "Whse. Jnl.-Register Line";
        WhsePostRcpt: Codeunit "Whse.-Post Receipt";
        WhsePostShpt: Codeunit "Whse.-Post Shipment";
        PurchPost: Codeunit "Purch.-Post";
        CostCalcMgt: Codeunit "Cost Calculation Management";
        JobPostLine: Codeunit "Job Post-Line";
        ServItemMgt: Codeunit ServItemManagement;
        AsmPost: Codeunit "Assembly-Post";
        DeferralUtilities: Codeunit "Deferral Utilities";
        UOMMgt: Codeunit "Unit of Measure Management";
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
        Window: Dialog;
        UseDate: Date;
        GenJnlLineDocNo: Code[20];
        GenJnlLineExtDocNo: Code[35];
        SrcCode: Code[10];
        GenJnlLineDocType: Enum "Gen. Journal Document Type";
        ItemLedgShptEntryNo: Integer;
        FALineNo: Integer;
        RoundingLineNo: Integer;
        DeferralLineNo: Integer;
        InvDefLineNo: Integer;
        RemQtyToBeInvoiced: Decimal;
        RemQtyToBeInvoicedBase: Decimal;
        RemAmt: Decimal;
        RemDiscAmt: Decimal;
        TotalChargeAmt: Decimal;
        TotalChargeAmtLCY: Decimal;
        LastLineRetrieved: Boolean;
        RoundingLineInserted: Boolean;
        DropShipOrder: Boolean;
        CannotAssignInvoicedErr: Label 'You cannot assign item charges to the %1 %2 = %3,%4 = %5, %6 = %7, because it has been invoiced.', Comment = '%1 = Sales Line, %2/%3 = Document Type, %4/%5 - Document No.,%6/%7 = Line No.';
        ReturnReceiptLinesDeletedErr: Label 'The return receipt lines have been deleted.';
        ItemJnlRollRndg: Boolean;
        RelatedItemLedgEntriesNotFoundErr: Label 'Related item ledger entries cannot be found.';
        ItemTrackingWrongSignErr: Label 'Item Tracking is signed wrongly.';
        ItemTrackingMismatchErr: Label 'Item Tracking does not match.';
        WhseShip: Boolean;
        WhseReceive: Boolean;
        InvtPickPutaway: Boolean;
        PostingDateNotAllowedErr: Label '%1 is not within your range of allowed posting dates.', Comment = '%1 - Posting Date field caption';
        ItemTrackQuantityMismatchErr: Label 'The %1 does not match the quantity defined in item tracking.', Comment = '%1 = Quantity';
        CannotBeGreaterThanErr: Label 'cannot be more than %1.', Comment = '%1 = Amount';
        CannotBeSmallerThanErr: Label 'must be at least %1.', Comment = '%1 = Amount';
        JobContractLine: Boolean;
        GLSetupRead: Boolean;
        RentalSetupRead: Boolean;
        ItemTrkgAlreadyOverruled: Boolean;
        PrepAmountToDeductToBigErr: Label 'The total %1 cannot be more than %2.', Comment = '%1 = Prepmt Amt to Deduct, %2 = Max Amount';
        PrepAmountToDeductToSmallErr: Label 'The total %1 must be at least %2.', Comment = '%1 = Prepmt Amt to Deduct, %2 = Max Amount';
        MustAssignItemChargeErr: Label 'You must assign item charge %1 if you want to invoice it.', Comment = '%1 = Item Charge No.';
        CannotInvoiceItemChargeErr: Label 'You can not invoice item charge %1 because there is no item ledger entry to assign it to.', Comment = '%1 = Item Charge No.';
        RentalLinesProcessed: Boolean;
        AssemblyCheckProgressMsg: Label '#1#################################\\Checking Assembly #2###########', Comment = '%1 = Text, %2 = Progress bar';
        AssemblyPostProgressMsg: Label '#1#################################\\Posting Assembly #2###########', Comment = '%1 = Text, %2 = Progress bar';
        AssemblyFinalizeProgressMsg: Label '#1#################################\\Finalizing Assembly #2###########', Comment = '%1 = Text, %2 = Progress bar';
        ReassignItemChargeErr: Label 'The order line that the item charge was originally assigned to has been fully posted. You must reassign the item charge to the posted receipt or shipment.';
        ReservationDisruptedQst: Label 'One or more reservation entries exist for the item with %1 = %2, %3 = %4, %5 = %6 which may be disrupted if you post this negative adjustment. Do you want to continue?', Comment = '%1 = %2, %3 = %4, %5 = %6 One or more reservation entries exist for the item with No. = 1000, Location Code = SILVER, Variant Code = NEW which may be disrupted if you post this negative adjustment. Do you want to continue?';
        NotSupportedDocumentTypeErr: Label 'Document type %1 is not supported.', Comment = '%1 = Document Type';
        DownloadShipmentAlsoQst: Label 'You can also download the Rental - Shipment document now. Alternatively, you can access it from the Posted Rental Shipments window later.\\Do you want to download the Rental - Shipment document now?';
        PreviewMode: Boolean;
        TotalInvoiceAmountNegativeErr: Label 'The total amount for the invoice must be 0 or greater.';
        SuppressCommit: Boolean;
        PostingPreviewNoTok: Label '***', Locked = true;
        InvPickExistsErr: Label 'One or more related inventory picks must be registered before you can post the shipment.';
        InvPutAwayExistsErr: Label 'One or more related inventory put-aways must be registered before you can post the receipt.';
        CheckRentalHeaderMsg: Label 'Check sales document fields.';
        PostDocumentLinesMsg: Label 'Post document lines.';
        HideProgressWindow: Boolean;
        SalesReturnRcptHeaderConflictErr: Label 'Cannot post the sales return because its ID, %1, is already assigned to a record. Update the number series and try again.', Comment = '%1 = Return Receipt No.';
        SalesShptHeaderConflictErr: Label 'Cannot post the sales shipment because its ID, %1, is already assigned to a record. Update the number series and try again.', Comment = '%1 = Shipping No.';
        SalesInvHeaderConflictErr: Label 'Cannot post the sales invoice because its ID, %1, is already assigned to a record. Update the number series and try again.', Comment = '%1 = Posting No.';
        SalesCrMemoHeaderConflictErr: Label 'Cannot post the sales credit memo because its ID, %1, is already assigned to a record. Update the number series and try again.', Comment = '%1 = Posting No.';
        SalesLinePostCategoryTok: Label 'Sales Line Post', Locked = true;
        SameIdFoundLbl: Label 'Same line id found.', Locked = true;
        EmptyIdFoundLbl: Label 'Empty line id found.', Locked = true;

    local procedure GetZeroRentalLineRecID(RentalHeader: Record "TWE Rental Header"; var RentalLineRecID: RecordId)
    var
        ZeroRentalLine: Record "TWE Rental Line";
    begin
        ZeroRentalLine."Document Type" := RentalHeader."Document Type";
        ZeroRentalLine."Document No." := RentalHeader."No.";
        ZeroRentalLine."Line No." := 0;
        RentalLineRecID := ZeroRentalLine.RecordId;
    end;

    procedure CopyToTempLines(RentalHeader: Record "TWE Rental Header"; var TempRentalLine: Record "TWE Rental Line" temporary)
    var
        RentalLine: Record "TWE Rental Line";
    begin
        RentalLine.SetRange("Document Type", RentalHeader."Document Type");
        RentalLine.SetRange("Document No.", RentalHeader."No.");
        PostingEvents.OnCopyToTempLinesOnAfterSetFilters(RentalLine, RentalHeader);
        if RentalLine.FindSet() then
            repeat
                TempRentalLine := RentalLine;
                TempRentalLine.Insert();
            until RentalLine.Next() = 0;
    end;

    procedure FillTempLines(RentalHeader: Record "TWE Rental Header"; var TempRentalLine: Record "TWE Rental Line" temporary)
    begin
        TempRentalLine.Reset();
        if TempRentalLine.IsEmpty() then
            CopyToTempLines(RentalHeader, TempRentalLine);
    end;

    local procedure SetupDisableAggregateTableUpdate(var RentalHeader: Record "TWE Rental Header"; var DisableAggregateTableUpdate: Codeunit "Disable Aggregate Table Update")
    var
        AggregateTableID: Integer;
    begin
        //AggregateTableID := DisableAggregateTableUpdate.GetAggregateTableIDFromRentalHeader(RentalHeader);
        if not (AggregateTableID > 0) then
            exit;

        DisableAggregateTableUpdate.SetAggregateTableIDDisabled(AggregateTableID);
        DisableAggregateTableUpdate.SetTableSystemIDDisabled(RentalHeader.SystemId);
        BindSubscription(DisableAggregateTableUpdate);
    end;

    local procedure ModifyTempLine(var TempRentalLineLocal: Record "TWE Rental Line" temporary)
    var
        RentalLine: Record "TWE Rental Line";
    begin
        TempRentalLineLocal.Modify();
        RentalLine.Get(TempRentalLineLocal.RecordId);
        RentalLine.TransferFields(TempRentalLineLocal, false);
        RentalLine.Modify();
    end;

    procedure RefreshTempLines(RentalHeader: Record "TWE Rental Header"; var TempRentalLine: Record "TWE Rental Line" temporary)
    begin
        TempRentalLine.Reset();
        TempRentalLine.SetRange("Prepayment Line", false);
        TempRentalLine.DeleteAll();
        TempRentalLine.Reset();
        CopyToTempLines(RentalHeader, TempRentalLine);
    end;

    local procedure ResetTempLines(var TempRentalLineLocal: Record "TWE Rental Line" temporary)
    begin
        TempRentalLineLocal.Reset();
        TempRentalLineLocal.Copy(TempRentalLineGlobal, true);
        PostingEvents.OnAfterResetTempLines(TempRentalLineLocal);
    end;

    local procedure CalcInvoice(RentalHeader: Record "TWE Rental Header") NewInvoice: Boolean
    var
        TempRentalLine: Record "TWE Rental Line" temporary;
    begin
        ResetTempLines(TempRentalLine);
        TempRentalLine.SetFilter(Quantity, '<>0');
        if RentalHeader."Document Type" in [RentalHeader."Document Type"::Contract] then
            TempRentalLine.SetRange("Line Closed", false);
        NewInvoice := not TempRentalLine.IsEmpty;
        if NewInvoice then
            case RentalHeader."Document Type" of
                RentalHeader."Document Type"::Contract:
                    if not RentalHeader.Ship then begin
                        TempRentalLine.SetFilter("Quantity Shipped", '<>0');
                        NewInvoice := not TempRentalLine.IsEmpty;
                    end;
            end;
        PostingEvents.OnAfterCalcInvoice(TempRentalLine, NewInvoice, RentalHeader);
        exit(NewInvoice);
    end;

    local procedure CalcInvDiscount(var RentalHeader: Record "TWE Rental Header")
    var
        RentalHeaderCopy: Record "TWE Rental Header";
        RentalLine: Record "TWE Rental Line";
    begin
        if not (RentalSetup."Calc. Inv. Discount" and (RentalHeader.Status <> RentalHeader.Status::Open)) then
            exit;

        RentalHeaderCopy := RentalHeader;
        RentalLine.Reset();
        RentalLine.SetRange("Document Type", RentalHeader."Document Type");
        RentalLine.SetRange("Document No.", RentalHeader."No.");
        PostingEvents.OnCalcInvDiscountSetFilter(RentalLine, RentalHeader);
        RentalLine.FindFirst();
        CODEUNIT.Run(CODEUNIT::"TWE Rental-Calc. Discount", RentalLine);
        RefreshTempLines(RentalHeader, TempRentalLineGlobal);
        RentalHeader.Get(RentalHeader."Document Type", RentalHeader."No.");
        RestoreRentalHeader(RentalHeader, RentalHeaderCopy);
        if not (PreviewMode or SuppressCommit) then
            Commit();
    end;

    local procedure RestoreRentalHeader(var RentalHeader: Record "TWE Rental Header"; RentalHeaderCopy: Record "TWE Rental Header")
    begin
        RentalHeader.Invoice := RentalHeaderCopy.Invoice;
        RentalHeader.Receive := RentalHeaderCopy.Receive;
        RentalHeader.Ship := RentalHeaderCopy.Ship;
        RentalHeader."Posting No." := RentalHeaderCopy."Posting No.";
        RentalHeader."Shipping No." := RentalHeaderCopy."Shipping No.";
        RentalHeader."Return Receipt No." := RentalHeaderCopy."Return Receipt No.";

        PostingEvents.OnAfterRestoreRentalHeader(RentalHeader, RentalHeaderCopy);
    end;

    local procedure CheckAndUpdate(var RentalHeader: Record "TWE Rental Header")
    var
        GenJnlCheckLine: Codeunit "Gen. Jnl.-Check Line";
        CheckDimensions: Codeunit "Check Dimensions";
        ErrorContextElement: Codeunit "Error Context Element";
        ForwardLinkMgt: Codeunit "Forward Link Mgt.";
        ReportDistributionManagement: Codeunit "Report Distribution Management";
        SetupRecID: RecordID;
        ModifyHeader: Boolean;
        RefreshTempLinesNeeded: Boolean;
    begin
        // Check
        ErrorMessageMgt.PushContext(ErrorContextElement, RentalHeader.RecordId, 0, CheckRentalHeaderMsg);
        CheckMandatoryHeaderFields(RentalHeader);
        if GenJnlCheckLine.IsDateNotAllowed(RentalHeader."Posting Date", SetupRecID) then
            ErrorMessageMgt.LogContextFieldError(
              RentalHeader.FieldNo("Posting Date"), StrSubstNo(PostingDateNotAllowedErr, RentalHeader.FieldCaption("Posting Date")),
              SetupRecID, ErrorMessageMgt.GetFieldNo(SetupRecID.TableNo, GLSetup.FieldName("Allow Posting From")),
              ForwardLinkMgt.GetHelpCodeForAllowedPostingDate);

        SetPostingFlags(RentalHeader);

        PostingEvents.OnCheckAndUpdateOnAfterSetPostingFlags(RentalHeader, TempRentalLineGlobal);

        if not HideProgressWindow then
            InitProgressWindow(RentalHeader);

        InvtPickPutaway := RentalHeader."Posting from Whse. Ref." <> 0;
        RentalHeader."Posting from Whse. Ref." := 0;

        //CheckDimensions.CheckSalesDim(RentalHeader, TempRentalLineGlobal);

        CheckPostRestrictions(RentalHeader);

        if RentalHeader.Invoice then
            RentalHeader.Invoice := CalcInvoice(RentalHeader);

        /*   if Invoice then
              CopyAndCheckItemCharge(RentalHeader); */

        if RentalHeader.Invoice and not RentalHeader.IsCreditDocType then
            RentalHeader.TestField("Due Date");

        if RentalHeader.Ship then begin
            InitPostATOs(RentalHeader);
            RentalHeader.Ship := CheckTrackingAndWarehouseForShip(RentalHeader);
            if not InvtPickPutaway then
                if CheckIfInvPickExists(RentalHeader) then
                    Error(InvPickExistsErr);
        end;

        if RentalHeader.Receive then begin
            RentalHeader.Receive := CheckTrackingAndWarehouseForReceive(RentalHeader);
            if not InvtPickPutaway then
                if CheckIfInvPutawayExists then
                    Error(InvPutAwayExistsErr);
        end;

        if not (RentalHeader.Ship or RentalHeader.Invoice or RentalHeader.Receive) then
            Error(NothingToPostErr);

        CheckAssosOrderLines(RentalHeader);

        //ReportDistributionManagement.RunDefaultCheckSalesElectronicDocument(RentalHeader);

        PostingEvents.OnAfterCheckRentalDoc(RentalHeader, SuppressCommit, WhseShip, WhseReceive);
        ErrorMessageMgt.Finish(RentalHeader.RecordId);

        // Update
        if RentalHeader.Invoice then
            CreatePrepaymentLines(RentalHeader, true);

        ModifyHeader := UpdatePostingNos(RentalHeader);

        DropShipOrder := UpdateAssosOrderPostingNos(RentalHeader);

        PostingEvents.OnBeforePostCommitRentalDoc(RentalHeader, GenJnlPostLine, PreviewMode, ModifyHeader, SuppressCommit, TempRentalLineGlobal);
        if not PreviewMode and ModifyHeader then begin
            RentalHeader.Modify();
            if not SuppressCommit then
                Commit();
        end;

        RefreshTempLinesNeeded := false;
        PostingEvents.OnCheckAndUpdateOnBeforeCalcInvDiscount(
          RentalHeader, TempWhseRcptHeader, TempWhseShptHeader, WhseReceive, WhseShip, RefreshTempLinesNeeded);
        if RefreshTempLinesNeeded then
            RefreshTempLines(RentalHeader, TempRentalLineGlobal);

        CalcInvDiscount(RentalHeader);
        PostingEvents.OnCheckAndUpdateOnAfterCalcInvDiscount(RentalHeader);

        ReleaseSalesDocument(RentalHeader);

        if RentalHeader.Ship or RentalHeader.Receive then
            ArchiveUnpostedOrder(RentalHeader);

        CheckICPartnerBlocked(RentalHeader);
        SendICDocument(RentalHeader, ModifyHeader);
        UpdateHandledICInboxTransaction(RentalHeader);

        LockTables(RentalHeader);

        SourceCodeSetup.Get();
        SrcCode := SourceCodeSetup.Sales;

        PostingEvents.OnCheckAndUpdateOnAfterSetSourceCode(RentalHeader, SourceCodeSetup, SrcCode);

        InsertPostedHeaders(RentalHeader);

        UpdateIncomingDocument(RentalHeader."Incoming Document Entry No.", RentalHeader."Posting Date", GenJnlLineDocNo);

        PostingEvents.OnAfterCheckAndUpdate(RentalHeader, SuppressCommit, PreviewMode);
    end;

    local procedure CheckTotalInvoiceAmount(RentalHeader: Record "TWE Rental Header")
    var
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        PostingEvents.OnBeforeCheckTotalInvoiceAmount(RentalHeader, IsHandled);
        if IsHandled then
            exit;

        if RentalHeader."Document Type" in [RentalHeader."Document Type"::Invoice, RentalHeader."Document Type"::Contract] then begin
            TempRentalLineGlobal.CalcVATAmountLines(1, RentalHeader, TempRentalLineGlobal, TempVATAmountLine);
            if TempVATAmountLine.GetTotalAmountInclVAT() < 0 then
                Error(TotalInvoiceAmountNegativeErr);
        end;
    end;

    local procedure PostRentalLine(var RentalHeader: Record "TWE Rental Header"; var RentalLine: Record "TWE Rental Line"; var EverythingInvoiced: Boolean; var TempInvoicePostBuffer: Record "Invoice Post. Buffer" temporary; var TempVATAmountLine: Record "VAT Amount Line" temporary; var TempVATAmountLineRemainder: Record "VAT Amount Line" temporary; var TempItemLedgEntryNotInvoiced: Record "Item Ledger Entry" temporary; HasATOShippedNotInvoiced: Boolean; var TempDropShptPostBuffer: Record "Drop Shpt. Post. Buffer" temporary; var ICGenJnlLineNo: Integer; var TempServiceItem2: Record "Service Item" temporary; var TempServiceItemComp2: Record "Service Item Component" temporary)
    var
        RentalShptLine: Record "TWE Rental Shipment Line";
        RentalRtnShptLine: Record "TWE Rental Return Ship. Line";
        RentalInvLine: Record "TWE Rental Invoice Line";
        SearchRentalInvLine: Record "TWE Rental Invoice Line";
        RentalCrMemoLine: Record "TWE Rental Cr.Memo Line";
        SearchRentalCrMemoLine: Record "TWE Rental Cr.Memo Line";
        TempPostedATOLink: Record "Posted Assemble-to-Order Link" temporary;
        InvoicePostBuffer: Record "Invoice Post. Buffer";
        CostBaseAmount: Decimal;
        QuantityToInvoice: Decimal;
        IsHandled: Boolean;
    begin
        if RentalLine.Type = RentalLine.Type::"Rental Item" then begin
            CostBaseAmount := RentalLine.GetLineAmountToInvoice();
            // Skip UoM validation for partially shipped documents and lines fetch through "Get Shipment Lines"
            if (RentalLine."No." <> '') and (RentalLine."Qty. Shipped (Base)" = 0) and (RentalLine."Shipment No." = '') then
                RentalLine.TestField("Unit of Measure Code");
        end;
        if RentalLine."Qty. per Unit of Measure" = 0 then
            RentalLine."Qty. per Unit of Measure" := 1;

        TestRentalLine(RentalHeader, RentalLine);

        TempPostedATOLink.Reset();
        TempPostedATOLink.DeleteAll();
        if RentalHeader.Ship then
            PostATO(RentalHeader, RentalLine, TempPostedATOLink);

        UpdateRentalLineBeforePost(RentalHeader, RentalLine);

        TestUpdatedRentalLine(RentalLine);
        PostingEvents.OnPostSalesLineOnAfterTestUpdatedSalesLine(RentalLine, EverythingInvoiced, RentalHeader);

        if RentalLine.Type <> RentalLine.Type::"Rental Item" then begin
            if RentalLine."Qty. to Invoice" + RentalLine."Quantity Invoiced" <> RentalLine.Quantity then
                EverythingInvoiced := false;
        end else
            if RentalLine."Total Days to Invoice" <> RentalLine."Invoiced Duration" then
                EverythingInvoiced := false;

        PostingEvents.OnPostSalesLineOnAfterSetEverythingInvoiced(RentalLine, EverythingInvoiced);


        if (RentalLine.Type <> RentalLine.Type::"Rental Item") or (RentalLine."Document Type" = RentalLine."Document Type"::"Return Shipment") then begin
            QuantityToInvoice := RentalLine."Qty. to Invoice";
            RemQtyToBeInvoiced := RentalLine."Qty. to Invoice";
            RemQtyToBeInvoicedBase := RentalLine."Qty. to Invoice (Base)";
        end else
            If RentalHeader.Invoice then begin
                QuantityToInvoice := RentalLine.Quantity;
                RemQtyToBeInvoiced := -RentalLine.Quantity;
                RemQtyToBeInvoicedBase := -RentalLine."Quantity (Base)";
            end;


        if RentalLine.Quantity <> 0 then
            DivideAmount(RentalHeader, RentalLine, 1, QuantityToInvoice, TempVATAmountLine, TempVATAmountLineRemainder);


        CheckItemReservDisruption(RentalLine);

        RoundAmount(RentalHeader, RentalLine, QuantityToInvoice);

        if not RentalLine.IsCreditDocType then begin
            ReverseAmount(RentalLine);
            ReverseAmount(RentalLineACY);
        end;

        PostingEvents.OnPostSalesLineOnBeforePostItemTrackingLine(RentalHeader, RentalLine, WhseShip, WhseReceive, InvtPickPutaway);

        PostItemTrackingLine(RentalHeader, RentalLine, TempItemLedgEntryNotInvoiced, HasATOShippedNotInvoiced);

        PostingEvents.OnPostSalesLineOnAfterPostItemTrackingLine(RentalHeader, RentalLine, WhseShip, WhseReceive, InvtPickPutaway);

        case RentalLine.Type of
            RentalLine.Type::"G/L Account":
                PostGLAccICLine(RentalHeader, RentalLine, ICGenJnlLineNo);
            RentalLine.Type::"Rental Item":
                PostItemLine(RentalHeader, RentalLine, TempDropShptPostBuffer, TempPostedATOLink);
            RentalLine.Type::Resource:
                PostResJnlLine(RentalHeader, RentalLine, JobTaskRentalLine);
        end;

        PostingEvents.OnPostSalesLineOnAfterCaseType(
            RentalHeader, RentalLine, GenJnlLineDocNo, GenJnlLineExtDocNo, GenJnlLineDocType.AsInteger(), SrcCode, GenJnlPostLine);

        if (RentalLine.Type <> RentalLine.Type::" ") and (QuantityToInvoice <> 0) then begin
            AdjustPrepmtAmountLCY(RentalHeader, RentalLine);
            FillInvoicePostingBuffer(RentalHeader, RentalLine, RentalLineACY, TempInvoicePostBuffer, InvoicePostBuffer);
            InsertPrepmtAdjInvPostingBuf(RentalHeader, RentalLine, TempInvoicePostBuffer, InvoicePostBuffer);
        end;

        IsHandled := false;
        PostingEvents.OnPostSalesLineOnBeforeTestJobNo(RentalLine, IsHandled);
        /*   if not IsHandled then
              if not ("Document Type" in ["Document Type"::Invoice, "Document Type"::"Credit Memo"]) then
                  TestField("Job No.", ''); */

        IsHandled := false;
        PostingEvents.OnPostSalesLineOnBeforeInsertShipmentLine(
          RentalHeader, RentalLine, IsHandled, RentalLineACY, GenJnlLineDocType.AsInteger(), GenJnlLineDocNo, GenJnlLineExtDocNo);

        if not IsHandled then
            if (RentalShptHeader."No." <> '') and (RentalLine."Shipment No." = '') and
               not RoundingLineInserted and not RentalLine."Prepayment Line"
            then
                InsertShipmentLine(RentalHeader, RentalShptHeader, RentalLine, CostBaseAmount, TempServiceItem2, TempServiceItemComp2);

        IsHandled := false;
        PostingEvents.OnPostSalesLineOnBeforeInsertReturnReceiptLine(RentalHeader, RentalLine, IsHandled);
        if (RentalRtnShipHeader."No." <> '') and (RentalLine."Return Receipt No." = '') and
           not RoundingLineInserted
        then
            InsertRentalRtnShipLine(RentalRtnShipHeader, RentalLine, CostBaseAmount);

        IsHandled := false;
        if RentalHeader.Invoice then
            if RentalHeader."Document Type" in [RentalHeader."Document Type"::Contract, RentalHeader."Document Type"::Invoice] then begin
                PostingEvents.OnPostSalesLineOnBeforeInsertInvoiceLine(RentalHeader, RentalLine, IsHandled, xRentalLine, RentalInvHeader);
                if not IsHandled then begin
                    RentalInvLine.InitFromRentalLine(RentalInvHeader, xRentalLine);
                    RentalItemJnlPostLine.CollectValueEntryRelation(TempValueEntryRelation, RentalInvLine.RowID1);
                    if RentalLine."Document Type" = RentalLine."Document Type"::Contract then begin
                        RentalInvLine."Order No." := RentalLine."Document No.";
                        RentalInvLine."Order Line No." := RentalLine."Line No.";
                    end else
                        if RentalShptLine.Get(RentalLine."Shipment No.", RentalLine."Shipment Line No.") then begin
                            RentalInvLine."Order No." := RentalShptLine."Order No.";
                            RentalInvLine."Order Line No." := RentalShptLine."Order Line No.";
                        end;
                    PostingEvents.OnBeforeSalesInvLineInsert(RentalInvLine, RentalInvHeader, xRentalLine, SuppressCommit);
                    if not IsNullGuid(xRentalLine.SystemId) then begin
                        SearchRentalInvLine.SetRange(SystemId, xRentalLine.SystemId);
                        if SearchRentalInvLine.IsEmpty() then begin
                            RentalInvLine.SystemId := xRentalLine.SystemId;
                            RentalInvLine.Insert(true, true);
                        end else begin
                            Session.LogMessage('0000DD6', SameIdFoundLbl, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', SalesLinePostCategoryTok);
                            RentalInvLine.Insert(true);
                        end;
                    end else begin
                        RentalInvLine.Insert(true);
                        Session.LogMessage('0000DDC', EmptyIdFoundLbl, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', SalesLinePostCategoryTok);
                    end;
                    PostingEvents.OnAfterRentalInvLineInsert(
                      RentalInvLine, RentalInvHeader, xRentalLine, ItemLedgShptEntryNo, WhseShip, WhseReceive, SuppressCommit,
                      RentalHeader, TempItemChargeAssgntSales);
                end;
            end else begin
                PostingEvents.OnPostSalesLineOnBeforeInsertCrMemoLine(RentalHeader, RentalLine, IsHandled, xRentalLine, RentalCrMemoHeader);
                if not IsHandled then begin
                    RentalCrMemoLine.InitFromRentalLine(RentalCrMemoHeader, xRentalLine);
                    RentalItemJnlPostLine.CollectValueEntryRelation(TempValueEntryRelation, RentalCrMemoLine.RowID1);
                    if RentalLine."Document Type" = RentalLine."Document Type"::"Return Shipment" then begin
                        RentalCrMemoLine."Order No." := RentalLine."Document No.";
                        RentalCrMemoLine."Order Line No." := RentalLine."Line No.";
                    end;
                    PostingEvents.OnBeforeSalesCrMemoLineInsert(RentalCrMemoLine, RentalCrMemoHeader, xRentalLine, SuppressCommit);
                    if not IsNullGuid(xRentalLine.SystemId) then begin
                        SearchRentalCrMemoLine.SetRange(SystemId, xRentalLine.SystemId);
                        if SearchRentalCrMemoLine.IsEmpty() then begin
                            RentalCrMemoLine.SystemId := xRentalLine.SystemId;
                            RentalCrMemoLine.Insert(true, true);
                        end else begin
                            Session.LogMessage('0000DD7', SameIdFoundLbl, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', SalesLinePostCategoryTok);
                            RentalCrMemoLine.Insert(true);
                        end;
                    end else begin
                        RentalCrMemoLine.Insert(true);
                        Session.LogMessage('0000DDD', SameIdFoundLbl, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', SalesLinePostCategoryTok);
                    end;
                    PostingEvents.OnAfterRentalCrMemoLineInsert(
                      RentalCrMemoLine, RentalCrMemoHeader, RentalHeader, xRentalLine, TempItemChargeAssgntSales, SuppressCommit);
                end;
            end;

        PostingEvents.OnAfterPostRentalLine(RentalHeader, RentalLine, SuppressCommit, RentalInvLine, RentalCrMemoLine, xRentalLine);
    end;

    local procedure PostGLAndCustomer(var RentalHeader: Record "TWE Rental Header"; var TempInvoicePostBuffer: Record "Invoice Post. Buffer" temporary; var CustLedgEntry: Record "Cust. Ledger Entry")
    var
        IsHandled: Boolean;
    begin
        PostingEvents.OnBeforePostGLAndCustomer(RentalHeader, TempInvoicePostBuffer, CustLedgEntry, SuppressCommit, PreviewMode, GenJnlPostLine, IsHandled);
        if IsHandled then
            exit;

        // Post sales and VAT to G/L entries from posting buffer
        PostInvoicePostBuffer(RentalHeader, TempInvoicePostBuffer);

        // Post customer entry
        if GuiAllowed and not HideProgressWindow then
            Window.Update(4, 1);
        PostCustomerEntry(
         RentalHeader, TotalRentalLine, TotalRentalLineLCY, GenJnlLineDocType, GenJnlLineDocNo, GenJnlLineExtDocNo, SrcCode);

        UpdateRentalHeader(CustLedgEntry);

        // Balancing account
        if RentalHeader."Bal. Account No." <> '' then begin
            if GuiAllowed and not HideProgressWindow then
                Window.Update(5, 1);
            PostBalancingEntry(
              RentalHeader, TotalRentalLine, TotalRentalLineLCY, GenJnlLineDocType, GenJnlLineDocNo, GenJnlLineExtDocNo, SrcCode);
        end;

        PostingEvents.OnAfterPostGLAndCustomer(RentalHeader, GenJnlPostLine, TotalRentalLine, TotalRentalLineLCY, SuppressCommit);
    end;

    local procedure PostGLAccICLine(RentalHeader: Record "TWE Rental Header"; RentalLine: Record "TWE Rental Line"; var ICGenJnlLineNo: Integer)
    var
        GLAcc: Record "G/L Account";
    begin
        if (RentalLine."No." <> '') and not RentalLine."System-Created Entry" then begin
            GLAcc.Get(RentalLine."No.");
            GLAcc.TestField("Direct Posting", true);
            /*             if (RentalLine."IC Partner Code" <> '') and RentalHeader.Invoice then
                            InsertICGenJnlLine(RentalHeader, xRentalLine, ICGenJnlLineNo); */
        end;
    end;

    local procedure PostItemLine(RentalHeader: Record "TWE Rental Header"; var RentalLine: Record "TWE Rental Line"; var TempDropShptPostBuffer: Record "Drop Shpt. Post. Buffer" temporary; var TempPostedATOLink: Record "Posted Assemble-to-Order Link" temporary)
    var
        DummyTrackingSpecification: Record "Tracking Specification";
        RentalLineToShip: Record "TWE Rental Line";
        QtyToInvoice: Decimal;
        QtyToInvoiceBase: Decimal;
    begin
        ItemLedgShptEntryNo := 0;
        QtyToInvoice := RemQtyToBeInvoiced;
        QtyToInvoiceBase := RemQtyToBeInvoicedBase;

        ProcessAssocItemJnlLine(RentalHeader, RentalLine, TempDropShptPostBuffer);

        Clear(TempPostedATOLink);
        TempPostedATOLink.SetRange("Order No.", RentalLine."Document No.");
        TempPostedATOLink.SetRange("Order Line No.", RentalLine."Line No.");
        if TempPostedATOLink.FindFirst() then
            PostATOAssocItemJnlLine(RentalHeader, RentalLine, TempPostedATOLink, QtyToInvoice, QtyToInvoiceBase);

        if QtyToInvoice <> 0 then
            ItemLedgShptEntryNo :=
              PostItemJnlLine(
                RentalHeader, RentalLine,
                QtyToInvoice, QtyToInvoiceBase,
                QtyToInvoice, QtyToInvoiceBase,
                0, '', DummyTrackingSpecification, false);

        // Invoice discount amount is also included in expected sales amount posted for shipment or return receipt.
        MakeSalesLineToShip(RentalLineToShip, RentalLine);

        if not RentalLineToShip.IsCreditDocType then begin
            if Abs(RentalLineToShip."Qty. to Ship") > Abs(QtyToInvoice) + Abs(TempPostedATOLink."Assembled Quantity") then
                ItemLedgShptEntryNo :=
                  PostItemJnlLine(
                    RentalHeader, RentalLineToShip,
                    RentalLineToShip."Qty. to Ship" - TempPostedATOLink."Assembled Quantity" - QtyToInvoice,
                    RentalLineToShip."Qty. to Ship (Base)" - TempPostedATOLink."Assembled Quantity (Base)" - QtyToInvoiceBase,
                    0, 0, 0, '', DummyTrackingSpecification, false);
        end;

        PostingEvents.OnAfterPostItemLine(RentalHeader, RentalLine, QtyToInvoice, QtyToInvoiceBase, SuppressCommit);
    end;

    local procedure ProcessAssocItemJnlLine(RentalHeader: Record "TWE Rental Header"; var RentalLine: Record "TWE Rental Line"; var TempDropShptPostBuffer: Record "Drop Shpt. Post. Buffer" temporary)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        PostingEvents.OnBeforeProcessAssocItemJnlLine(RentalLine, IsHandled);
        if IsHandled then
            exit;

        if (RentalLine."Qty. to Ship" <> 0) and (RentalLine."Purch. Order Line No." <> 0) then begin
            TempDropShptPostBuffer."Order No." := RentalLine."Purchase Order No.";
            TempDropShptPostBuffer."Order Line No." := RentalLine."Purch. Order Line No.";
            TempDropShptPostBuffer.Quantity := -RentalLine."Qty. to Ship";
            TempDropShptPostBuffer."Quantity (Base)" := -RentalLine."Qty. to Ship (Base)";
            TempDropShptPostBuffer."Item Shpt. Entry No." :=
                PostAssocItemJnlLine(RentalHeader, RentalLine, TempDropShptPostBuffer.Quantity, TempDropShptPostBuffer."Quantity (Base)");
            TempDropShptPostBuffer.Insert();
            RentalLine."Appl.-to Item Entry" := TempDropShptPostBuffer."Item Shpt. Entry No.";
        end;
    end;

    local procedure PostItemChargeLine(RentalHeader: Record "TWE Rental Header"; RentalLine: Record "TWE Rental Line")
    var
        RentalLineBackup: Record "TWE Rental Line";
    begin
        if not (RentalHeader.Invoice and (RentalLine."Qty. to Invoice" <> 0)) then
            exit;

        ItemJnlRollRndg := true;
        RentalLineBackup.Copy(RentalLine);
        if FindTempItemChargeAssgntSales(RentalLineBackup."Line No.") then
            repeat
                PostingEvents.OnPostItemChargeLineOnBeforePostItemCharge(TempItemChargeAssgntSales, RentalHeader, RentalLineBackup);
                case TempItemChargeAssgntSales."Applies-to Doc. Type" of
                    TempItemChargeAssgntSales."Applies-to Doc. Type"::Shipment:
                        begin
                            PostItemChargePerShpt(RentalHeader, RentalLineBackup);
                            TempItemChargeAssgntSales.Mark(true);
                        end;
                    TempItemChargeAssgntSales."Applies-to Doc. Type"::"Return Receipt":
                        begin
                            PostItemChargePerRetRcpt(RentalHeader, RentalLineBackup);
                            TempItemChargeAssgntSales.Mark(true);
                        end;
                    TempItemChargeAssgntSales."Applies-to Doc. Type"::Order,
                    TempItemChargeAssgntSales."Applies-to Doc. Type"::Invoice,
                    TempItemChargeAssgntSales."Applies-to Doc. Type"::"Return Order",
                    TempItemChargeAssgntSales."Applies-to Doc. Type"::"Credit Memo":
                        CheckItemCharge(TempItemChargeAssgntSales);
                end;
            until TempItemChargeAssgntSales.Next() = 0;
    end;

    local procedure PostItemTrackingLine(RentalHeader: Record "TWE Rental Header"; RentalLine: Record "TWE Rental Line"; var TempItemLedgEntryNotInvoiced: Record "Item Ledger Entry" temporary; HasATOShippedNotInvoiced: Boolean)
    var
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        TrackingSpecificationExists: Boolean;
    begin
        if RentalLine."Prepayment Line" then
            exit;

        if RentalHeader.Invoice then
            if RentalLine."Qty. to Invoice" = 0 then
                TrackingSpecificationExists := false;
        /*             else
                        TrackingSpecificationExists :=
                          ReserveRentalLine.RetrieveInvoiceSpecification(RentalLine, TempTrackingSpecification); */
        if (RentalLine."Qty. to Invoice" > 0) or (RentalLine.Type <> RentalLine.Type::"Rental Item") then
            PostItemTracking(
            RentalHeader, RentalLine, TrackingSpecificationExists, TempTrackingSpecification,
            TempItemLedgEntryNotInvoiced, HasATOShippedNotInvoiced);

        if TrackingSpecificationExists then
            SaveInvoiceSpecification(TempTrackingSpecification);
    end;

    procedure PostItemJnlLine(RentalHeader: Record "TWE Rental Header"; RentalLine: Record "TWE Rental Line"; QtyToBeShipped: Decimal; QtyToBeShippedBase: Decimal; QtyToBeInvoiced: Decimal; QtyToBeInvoicedBase: Decimal; ItemLedgShptEntryNo: Integer; ItemChargeNo: Code[20]; TrackingSpecification: Record "Tracking Specification"; IsATO: Boolean): Integer
    var
        RentalItemJnlLine: Record "TWE Rental Item Journal Line";
        TempWhseJnlLine: Record "Warehouse Journal Line" temporary;
        TempWhseTrackingSpecification: Record "Tracking Specification" temporary;
        OriginalRentalItemJnlLine: Record "TWE Rental Item Journal Line";
        CurrExchRate: Record "Currency Exchange Rate";
        DummyItemTrackingSetup: Record "Item Tracking Setup";
        PostWhseJnlLine: Boolean;
        InvDiscAmountPerShippedQty: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        PostingEvents.OnBeforePostItemJnlLine(
          RentalHeader, RentalLine, QtyToBeShipped, QtyToBeShippedBase, QtyToBeInvoiced, QtyToBeInvoicedBase,
          ItemLedgShptEntryNo, ItemChargeNo, TrackingSpecification, IsATO, SuppressCommit, IsHandled);
        if IsHandled then
            exit;

        ClearRemAmtIfNotItemJnlRollRndg(RentalLine);

        RentalItemJnlLine.Init();
        RentalItemJnlLine.CopyFromRentalHeader(RentalHeader);
        RentalItemJnlLine.CopyFromRentalLine(RentalLine);
        RentalItemJnlLine."Country/Region Code" := GetCountryCode(RentalLine, RentalHeader);

        RentalItemJnlLine.CopyTrackingFromSpec(TrackingSpecification);
        RentalItemJnlLine."Item Shpt. Entry No." := ItemLedgShptEntryNo;

        RentalItemJnlLine.Quantity := -QtyToBeShipped;
        RentalItemJnlLine."Quantity (Base)" := -QtyToBeShippedBase;
        RentalItemJnlLine."Invoiced Quantity" := -QtyToBeInvoiced;
        RentalItemJnlLine."Invoiced Qty. (Base)" := -QtyToBeInvoicedBase;

        PostItemJnlLineCopyDocumentFields(RentalItemJnlLine, RentalHeader, RentalLine, QtyToBeShipped, QtyToBeInvoiced);
        if QtyToBeInvoiced <> 0 then
            RentalItemJnlLine."Invoice No." := GenJnlLineDocNo;

        RentalItemJnlLine."Assemble to Order" := IsATO;
        RentalItemJnlLine."Applies-to Entry" := RentalLine."Appl.-to Item Entry";

        if ItemChargeNo <> '' then begin
            RentalItemJnlLine."Item Charge No." := ItemChargeNo;
            RentalLine."Qty. to Invoice" := QtyToBeInvoiced;
            PostingEvents.OnPostItemJnlLineOnAfterCopyItemCharge(RentalItemJnlLine, TempItemChargeAssgntSales);
        end else
            RentalItemJnlLine."Applies-from Entry" := RentalLine."Appl.-from Item Entry";

        if RentalLine.Type = RentalLine.Type::"Rental Item" then
            RentalLine."Qty. to Invoice" := QtyToBeInvoiced;

        if QtyToBeInvoiced <> 0 then begin
            RentalItemJnlLine.Amount := -(RentalLine.Amount * (QtyToBeInvoiced / RentalLine."Qty. to Invoice") - RemAmt);
            if RentalHeader."Prices Including VAT" then
                RentalItemJnlLine."Discount Amount" :=
                  -((RentalLine."Line Discount Amount" + RentalLine."Inv. Discount Amount") /
                    (1 + RentalLine."VAT %" / 100) * (QtyToBeInvoiced / RentalLine."Qty. to Invoice") - RemDiscAmt)
            else
                RentalItemJnlLine."Discount Amount" :=
                  -((RentalLine."Line Discount Amount" + RentalLine."Inv. Discount Amount") *
                    (QtyToBeInvoiced / RentalLine."Qty. to Invoice") - RemDiscAmt);
            RemAmt := RentalItemJnlLine.Amount - Round(RentalItemJnlLine.Amount);
            RemDiscAmt := RentalItemJnlLine."Discount Amount" - Round(RentalItemJnlLine."Discount Amount");
            RentalItemJnlLine.Amount := Round(RentalItemJnlLine.Amount);
            RentalItemJnlLine."Discount Amount" := Round(RentalItemJnlLine."Discount Amount");
        end else begin
            InvDiscAmountPerShippedQty := Abs(RentalLine."Inv. Discount Amount") * QtyToBeShipped / RentalLine.Quantity;
            RentalItemJnlLine.Amount := QtyToBeShipped * RentalLine."Unit Price";
            if RentalHeader."Prices Including VAT" then
                RentalItemJnlLine.Amount :=
                  -((RentalItemJnlLine.Amount * (1 - RentalLine."Line Discount %" / 100) - InvDiscAmountPerShippedQty) /
                    (1 + RentalLine."VAT %" / 100) - RemAmt)
            else
                RentalItemJnlLine.Amount :=
                  -(RentalItemJnlLine.Amount * (1 - RentalLine."Line Discount %" / 100) - InvDiscAmountPerShippedQty - RemAmt);
            RemAmt := RentalItemJnlLine.Amount - Round(RentalItemJnlLine.Amount);
            if RentalHeader."Currency Code" <> '' then
                RentalItemJnlLine.Amount :=
                  Round(
                    CurrExchRate.ExchangeAmtFCYToLCY(
                      RentalHeader."Posting Date", RentalHeader."Currency Code",
                      RentalItemJnlLine.Amount, RentalHeader."Currency Factor"))
            else
                RentalItemJnlLine.Amount := Round(RentalItemJnlLine.Amount);
        end;

        PostingEvents.OnPostItemJnlLineOnAfterPrepareItemJnlLine(RentalItemJnlLine, RentalLine, RentalHeader);

        if not JobContractLine then begin
            PostItemJnlLineBeforePost(RentalItemJnlLine, RentalLine, TempWhseJnlLine, PostWhseJnlLine, QtyToBeShippedBase);

            OriginalRentalItemJnlLine := RentalItemJnlLine;
            if not IsItemJnlPostLineHandled(RentalItemJnlLine, RentalLine, RentalHeader) then
                RentalItemJnlPostLine.RunWithCheck(RentalItemJnlLine);

            if IsATO then
                PostItemJnlLineTracking(
                  RentalLine, TempWhseTrackingSpecification, PostWhseJnlLine, QtyToBeInvoiced, TempATOTrackingSpecification)
            else
                PostItemJnlLineTracking(RentalLine, TempWhseTrackingSpecification, PostWhseJnlLine, QtyToBeInvoiced, TempHandlingSpecification);

            IsHandled := false;
            PostingEvents.OnPostItemJnlLineOnBeforePostItemJnlLineWhseLine(
              RentalItemJnlLine, TempWhseJnlLine, TempWhseTrackingSpecification, TempTrackingSpecification, IsHandled);
            if not IsHandled then
                PostItemJnlLineWhseLine(TempWhseJnlLine, TempWhseTrackingSpecification);

            PostingEvents.OnAfterPostItemJnlLineWhseLine(RentalLine, ItemLedgShptEntryNo, WhseShip, WhseReceive, SuppressCommit);

            if (RentalLine.Type = RentalLine.Type::"Rental Item") and RentalHeader.Invoice then
                PostItemJnlLineItemCharges(RentalHeader, RentalLine, OriginalRentalItemJnlLine, RentalItemJnlLine."Item Shpt. Entry No.");
        end;

        PostingEvents.OnAfterPostItemJnlLine(RentalItemJnlLine, RentalLine, RentalHeader, RentalItemJnlPostLine);

        exit(RentalItemJnlLine."Item Shpt. Entry No.");
    end;

    local procedure ClearRemAmtIfNotItemJnlRollRndg(RentalLine: Record "TWE Rental Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        PostingEvents.OnBeforeClearRemAmtIfNotItemJnlRollRndg(RentalLine, ItemJnlRollRndg, RemAmt, RemDiscAmt, IsHandled);
        if IsHandled then
            exit;

        if not ItemJnlRollRndg then begin
            RemAmt := 0;
            RemDiscAmt := 0;
        end;
    end;

    local procedure PostItemJnlLineCopyDocumentFields(var RentalItemJnlLine: Record "TWE Rental Item Journal Line"; RentalHeader: Record "TWE Rental Header"; RentalLine: Record "TWE Rental Line"; QtyToBeShipped: Decimal; QtyToBeInvoiced: Decimal)
    begin
        if QtyToBeShipped = 0 then
            if RentalLine.IsCreditDocType then
                RentalItemJnlLine.CopyDocumentFields(
                  RentalItemJnlLine."Document Type"::"Sales Credit Memo", GenJnlLineDocNo, GenJnlLineExtDocNo, SrcCode, RentalHeader."Posting No. Series")
            else
                RentalItemJnlLine.CopyDocumentFields(
                  RentalItemJnlLine."Document Type"::"Sales Invoice", GenJnlLineDocNo, GenJnlLineExtDocNo, SrcCode, RentalHeader."Posting No. Series")
        else begin
            if RentalLine.IsCreditDocType then
                RentalItemJnlLine.CopyDocumentFields(
                  RentalItemJnlLine."Document Type"::"Sales Return Receipt",
                  ReturnRcptHeader."No.", ReturnRcptHeader."External Document No.", SrcCode, ReturnRcptHeader."No. Series")
            else
                RentalItemJnlLine.CopyDocumentFields(
                  RentalItemJnlLine."Document Type"::"Sales Shipment", RentalShptHeader."No.", RentalShptHeader."External Document No.", SrcCode,
                  RentalShptHeader."No. Series");
            if QtyToBeInvoiced <> 0 then begin
                if RentalItemJnlLine."Document No." = '' then
                    if RentalLine."Document Type" = RentalLine."Document Type"::"Credit Memo" then
                        RentalItemJnlLine.CopyDocumentFields(
                          RentalItemJnlLine."Document Type"::"Sales Credit Memo", GenJnlLineDocNo, GenJnlLineExtDocNo, SrcCode, RentalHeader."Posting No. Series")
                    else
                        RentalItemJnlLine.CopyDocumentFields(
                          RentalItemJnlLine."Document Type"::"Sales Invoice", GenJnlLineDocNo, GenJnlLineExtDocNo, SrcCode, RentalHeader."Posting No. Series");
                RentalItemJnlLine."Posting No. Series" := RentalHeader."Posting No. Series";
            end;
        end;

        PostingEvents.OnPostItemJnlLineOnAfterCopyDocumentFields(RentalItemJnlLine, RentalLine, TempWhseRcptHeader, TempWhseShptHeader);
    end;

    local procedure PostItemJnlLineItemCharges(RentalHeader: Record "TWE Rental Header"; RentalLine: Record "TWE Rental Line"; var OriginalRentalItemJnlLine: Record "TWE Rental Item Journal Line"; ItemShptEntryNo: Integer)
    var
        ItemChargeRentalLine: Record "TWE Rental Line";
    begin
        ClearItemChargeAssgntFilter;
        TempItemChargeAssgntSales.SetCurrentKey(
          "Applies-to Doc. Type", "Applies-to Doc. No.", "Applies-to Doc. Line No.");
        TempItemChargeAssgntSales.SetRange("Applies-to Doc. Type", RentalLine."Document Type");
        TempItemChargeAssgntSales.SetRange("Applies-to Doc. No.", RentalLine."Document No.");
        TempItemChargeAssgntSales.SetRange("Applies-to Doc. Line No.", RentalLine."Line No.");
        if TempItemChargeAssgntSales.FindSet() then
            repeat
                //TestField("Allow Item Charge Assignment");
                GetItemChargeLine(RentalHeader, ItemChargeRentalLine);
            //ItemChargeRentalLine.CalcFields("Qty. Assigned");
            /*                     if (ItemChargeLine."Qty. to Invoice" <> 0) or
                                   (Abs(ItemRentalChargeRentalLine."Qty. Assigned") < Abs(ItemChargeRentalLine."Quantity Invoiced"))
                                then begin
                                    OriginalItemJnlLine."Item Shpt. Entry No." := ItemShptEntryNo;
                                    PostItemChargePerOrder(RentalHeader, RentalLine, OriginalItemJnlLine, ItemChargeRentalLine);
                                    TempItemChargeAssgntSales.Mark(true);
                                end; */
            until TempItemChargeAssgntSales.Next() = 0;
    end;

    local procedure PostItemJnlLineTracking(RentalLine: Record "TWE Rental Line"; var TempWhseTrackingSpecification: Record "Tracking Specification" temporary; PostWhseJnlLine: Boolean; QtyToBeInvoiced: Decimal; var TempTrackingSpec: Record "Tracking Specification" temporary)
    begin
        if RentalItemJnlPostLine.CollectTrackingSpecification(TempTrackingSpec) then
            if TempTrackingSpec.FindSet() then
                repeat
                    TempTrackingSpecification := TempTrackingSpec;
                    //TempTrackingSpecification.SetSourceFromSalesLine(RentalLine);
                    if TempTrackingSpecification.Insert() then;
                    if QtyToBeInvoiced <> 0 then begin
                        TempTrackingSpecificationInv := TempTrackingSpecification;
                        if TempTrackingSpecificationInv.Insert() then;
                    end;
                    if PostWhseJnlLine then begin
                        TempWhseTrackingSpecification := TempTrackingSpecification;
                        if TempWhseTrackingSpecification.Insert() then;
                    end;
                until TempTrackingSpec.Next() = 0;
    end;

    local procedure PostItemJnlLineWhseLine(var TempWhseJnlLine: Record "Warehouse Journal Line" temporary; var TempWhseTrackingSpecification: Record "Tracking Specification" temporary)
    var
        TempWhseJnlLine2: Record "Warehouse Journal Line" temporary;
    begin
        ItemTrackingMgt.SplitWhseJnlLine(TempWhseJnlLine, TempWhseJnlLine2, TempWhseTrackingSpecification, false);
        if TempWhseJnlLine2.FindSet() then
            repeat
                WhseJnlPostLine.Run(TempWhseJnlLine2);
            until TempWhseJnlLine2.Next() = 0;
        TempWhseTrackingSpecification.DeleteAll();
    end;

    local procedure PostItemJnlLineBeforePost(var RentalItemJnlLine: Record "TWE Rental Item Journal Line"; RentalLine: Record "TWE Rental Line"; var TempWhseJnlLine: Record "Warehouse Journal Line" temporary; var PostWhseJnlLine: Boolean; QtyToBeShippedBase: Decimal)
    var
        CheckApplFromItemEntry: Boolean;
    begin
        if (RentalLine.Type = RentalLine.Type::"Rental Item") then //RentalSetup."Exact Cost Reversing Mandatory" and 
            if RentalLine.IsCreditDocType then
                CheckApplFromItemEntry := RentalLine.Quantity > 0
            else
                CheckApplFromItemEntry := RentalLine.Quantity < 0;

        if (RentalLine."Location Code" <> '') and (RentalLine.Type = RentalLine.Type::"Rental Item") and (RentalItemJnlLine.Quantity <> 0) then
            if ShouldPostWhseJnlLine(RentalLine) then begin
                CreateWhseJnlLine(RentalItemJnlLine, RentalLine, TempWhseJnlLine);
                PostWhseJnlLine := true;
            end;

        PostingEvents.OnPostItemJnlLineOnBeforeTransferReservToItemJnlLine(RentalLine, RentalItemJnlLine);

        /*             if QtyToBeShippedBase <> 0 then begin
                        if RentalLine.IsCreditDocType then
                            ReserveRentalLine.TransferSalesLineToItemJnlLine(RentalLine, ItemJnlLine, QtyToBeShippedBase, CheckApplFromItemEntry, false)
                        else
                            TransferReservToItemJnlLine(
                              RentalLine, ItemJnlLine, -QtyToBeShippedBase, TempTrackingSpecification, CheckApplFromItemEntry); */

        /*     if CheckApplFromItemEntry and RentalLine.IsInventoriableItem then
                RentalLine.TestField("Appl.-from Item Entry"); */
        /*             end;
                end; */

        PostingEvents.OnAfterPostItemJnlLineBeforePost(RentalItemJnlLine, RentalLine);
    end;

    local procedure ShouldPostWhseJnlLine(RentalLine: Record "TWE Rental Line") Result: Boolean
    var
        IsHandled: Boolean;
    begin
        PostingEvents.OnBeforeShouldPostWhseJnlLine(RentalLine, Result, IsHandled);
        if IsHandled then
            exit(Result);

        GetLocation(RentalLine."Location Code");
        if ((RentalLine."Document Type" in [RentalLine."Document Type"::Invoice, RentalLine."Document Type"::"Credit Memo"]) and
            Location."Directed Put-away and Pick") or
           (Location."Bin Mandatory" and not (WhseShip or WhseReceive or InvtPickPutaway or RentalLine."Drop Shipment"))
        then
            exit(true);
        exit(false);
    end;

    local procedure PostItemChargePerOrder(RentalHeader: Record "TWE Rental Header"; RentalLine: Record "TWE Rental Line"; RentalItemJnlLine2: Record "TWE Rental Item Journal Line"; ItemChargeRentalLine: Record "TWE Rental Line")
    var
        NonDistrRentalItemJnlLine: Record "TWE Rental Item Journal Line";
        CurrExchRate: Record "Currency Exchange Rate";
        QtyToInvoice: Decimal;
        Factor: Decimal;
        OriginalAmt: Decimal;
        OriginalDiscountAmt: Decimal;
        OriginalQty: Decimal;
        SignFactor: Integer;
        TotalChargeAmt2: Decimal;
        TotalChargeAmtLCY2: Decimal;
        IsHandled: Boolean;
    begin
        PostingEvents.OnBeforePostItemChargePerOrder(RentalHeader, RentalLine, RentalItemJnlLine2, ItemChargeRentalLine, SuppressCommit);

        IsHandled := false;
        PostingEvents.OnPostItemChargePerOrderOnBeforeTestJobNo(RentalLine, IsHandled);
        /*         if not IsHandled then
                    RentalLine.TestField("Job No.", ''); */
        //RentalLine.TestField("Allow Item Charge Assignment", true);

        RentalItemJnlLine2."Document No." := GenJnlLineDocNo;
        RentalItemJnlLine2."External Document No." := GenJnlLineExtDocNo;
        RentalItemJnlLine2."Item Charge No." := TempItemChargeAssgntSales."Item Charge No.";
        RentalItemJnlLine2.Description := ItemChargeRentalLine.Description;
        RentalItemJnlLine2."Unit of Measure Code" := '';
        RentalItemJnlLine2."Qty. per Unit of Measure" := 1;
        RentalItemJnlLine2."Applies-from Entry" := 0;
        /* if "Document Type" in ["Document Type"::"Return Order", "Document Type"::"Credit Memo"] then
            QtyToInvoice :=
              CalcQtyToInvoice(RentalLine."Return Qty. to Receive (Base)", RentalLine."Qty. to Invoice (Base)")
        else */
        QtyToInvoice :=
          CalcQtyToInvoice(RentalLine."Qty. to Ship (Base)", RentalLine."Qty. to Invoice (Base)");
        if RentalItemJnlLine2."Invoiced Quantity" = 0 then begin
            RentalItemJnlLine2."Invoiced Quantity" := RentalItemJnlLine2.Quantity;
            RentalItemJnlLine2."Invoiced Qty. (Base)" := RentalItemJnlLine2."Quantity (Base)";
        end;
        RentalItemJnlLine2."Document Line No." := ItemChargeRentalLine."Line No.";

        RentalItemJnlLine2.Amount := TempItemChargeAssgntSales."Amount to Assign" * RentalItemJnlLine2."Invoiced Qty. (Base)" / QtyToInvoice;
        if TempItemChargeAssgntSales."Document Type" in [TempItemChargeAssgntSales."Document Type"::"Return Order", TempItemChargeAssgntSales."Document Type"::"Credit Memo"] then
            RentalItemJnlLine2.Amount := -RentalItemJnlLine2.Amount;
        RentalItemJnlLine2."Unit Cost (ACY)" :=
          Round(RentalItemJnlLine2.Amount / RentalItemJnlLine2."Invoiced Qty. (Base)",
            Currency."Unit-Amount Rounding Precision");

        TotalChargeAmt2 := TotalChargeAmt2 + RentalItemJnlLine2.Amount;
        if RentalHeader."Currency Code" <> '' then
            RentalItemJnlLine2.Amount :=
              CurrExchRate.ExchangeAmtFCYToLCY(
                UseDate, RentalHeader."Currency Code", TotalChargeAmt2 + TotalRentalLine.Amount, RentalHeader."Currency Factor") -
              TotalChargeAmtLCY2 - TotalRentalLineLCY.Amount
        else
            RentalItemJnlLine2.Amount := TotalChargeAmt2 - TotalChargeAmtLCY2;

        TotalChargeAmtLCY2 := TotalChargeAmtLCY2 + RentalItemJnlLine2.Amount;
        RentalItemJnlLine2."Unit Cost" := Round(
            RentalItemJnlLine2.Amount / RentalItemJnlLine2."Invoiced Qty. (Base)", GLSetup."Unit-Amount Rounding Precision");
        RentalItemJnlLine2."Applies-to Entry" := RentalItemJnlLine2."Item Shpt. Entry No.";

        if RentalHeader."Currency Code" <> '' then
            RentalItemJnlLine2."Discount Amount" := Round(
                CurrExchRate.ExchangeAmtFCYToLCY(
                  UseDate, RentalHeader."Currency Code",
                  (ItemChargeRentalLine."Inv. Discount Amount" + ItemChargeRentalLine."Line Discount Amount") *
                  RentalItemJnlLine2."Invoiced Qty. (Base)" / ItemChargeRentalLine."Quantity (Base)" *
                  TempItemChargeAssgntSales."Qty. to Assign" / QtyToInvoice,
                  RentalHeader."Currency Factor"),
                GLSetup."Amount Rounding Precision")
        else
            RentalItemJnlLine2."Discount Amount" := Round(
                (ItemChargeRentalLine."Inv. Discount Amount" + ItemChargeRentalLine."Line Discount Amount") *
                RentalItemJnlLine2."Invoiced Qty. (Base)" / ItemChargeRentalLine."Quantity (Base)" *
                TempItemChargeAssgntSales."Qty. to Assign" / QtyToInvoice,
                GLSetup."Amount Rounding Precision");

        if RentalLine.IsCreditDocType then
            RentalItemJnlLine2."Discount Amount" := -RentalItemJnlLine2."Discount Amount";
        RentalItemJnlLine2."Shortcut Dimension 1 Code" := ItemChargeRentalLine."Shortcut Dimension 1 Code";
        RentalItemJnlLine2."Shortcut Dimension 2 Code" := ItemChargeRentalLine."Shortcut Dimension 2 Code";
        RentalItemJnlLine2."Dimension Set ID" := ItemChargeRentalLine."Dimension Set ID";
        RentalItemJnlLine2."Gen. Prod. Posting Group" := ItemChargeRentalLine."Gen. Prod. Posting Group";

        PostingEvents.OnPostItemChargePerOrderOnAfterCopyToItemJnlLine(
          RentalItemJnlLine2, ItemChargeRentalLine, GLSetup, QtyToInvoice, TempItemChargeAssgntSales);

        TempTrackingSpecificationInv.Reset;
        TempTrackingSpecificationInv.SetRange("Source Type", DATABASE::"TWE Rental Line");
        TempTrackingSpecificationInv.SetRange("Source ID", TempItemChargeAssgntSales."Applies-to Doc. No.");
        TempTrackingSpecificationInv.SetRange("Source Ref. No.", TempItemChargeAssgntSales."Applies-to Doc. Line No.");
        if TempTrackingSpecificationInv.IsEmpty() then
            RentalItemJnlPostLine.RunWithCheck(RentalItemJnlLine2)
        else begin
            TempTrackingSpecificationInv.FindSet();
            NonDistrRentalItemJnlLine := RentalItemJnlLine2;
            OriginalAmt := NonDistrRentalItemJnlLine.Amount;
            OriginalDiscountAmt := NonDistrRentalItemJnlLine."Discount Amount";
            OriginalQty := NonDistrRentalItemJnlLine."Quantity (Base)";
            if (TempTrackingSpecificationInv."Quantity (Base)" / OriginalQty) > 0 then
                SignFactor := 1
            else
                SignFactor := -1;
            repeat
                Factor := TempTrackingSpecificationInv."Quantity (Base)" / OriginalQty * SignFactor;
                if Abs(TempTrackingSpecificationInv."Quantity (Base)") < Abs(NonDistrRentalItemJnlLine."Quantity (Base)") then begin
                    RentalItemJnlLine2."Quantity (Base)" := -TempTrackingSpecificationInv."Quantity (Base)";
                    RentalItemJnlLine2."Invoiced Qty. (Base)" := RentalItemJnlLine2."Quantity (Base)";
                    RentalItemJnlLine2.Amount :=
                      Round(OriginalAmt * Factor, GLSetup."Amount Rounding Precision");
                    RentalItemJnlLine2."Discount Amount" :=
                      Round(OriginalDiscountAmt * Factor, GLSetup."Amount Rounding Precision");
                    RentalItemJnlLine2."Unit Cost" :=
                      Round(RentalItemJnlLine2.Amount / RentalItemJnlLine2."Invoiced Qty. (Base)",
                        GLSetup."Unit-Amount Rounding Precision") * SignFactor;
                    RentalItemJnlLine2."Item Shpt. Entry No." := TempTrackingSpecificationInv."Item Ledger Entry No.";
                    RentalItemJnlLine2."Applies-to Entry" := TempTrackingSpecificationInv."Item Ledger Entry No.";
                    RentalItemJnlLine2.CopyTrackingFromSpec(TempTrackingSpecificationInv);
                    RentalItemJnlPostLine.RunWithCheck(RentalItemJnlLine2);
                    RentalItemJnlLine2."Location Code" := NonDistrRentalItemJnlLine."Location Code";
                    NonDistrRentalItemJnlLine."Quantity (Base)" -= RentalItemJnlLine2."Quantity (Base)";
                    NonDistrRentalItemJnlLine.Amount -= RentalItemJnlLine2.Amount;
                    NonDistrRentalItemJnlLine."Discount Amount" -= RentalItemJnlLine2."Discount Amount";
                end else begin // the last time
                    NonDistrRentalItemJnlLine."Quantity (Base)" := -TempTrackingSpecificationInv."Quantity (Base)";
                    NonDistrRentalItemJnlLine."Invoiced Qty. (Base)" := -TempTrackingSpecificationInv."Quantity (Base)";
                    NonDistrRentalItemJnlLine."Unit Cost" :=
                      Round(NonDistrRentalItemJnlLine.Amount / NonDistrRentalItemJnlLine."Invoiced Qty. (Base)",
                        GLSetup."Unit-Amount Rounding Precision");
                    NonDistrRentalItemJnlLine."Item Shpt. Entry No." := TempTrackingSpecificationInv."Item Ledger Entry No.";
                    NonDistrRentalItemJnlLine."Applies-to Entry" := TempTrackingSpecificationInv."Item Ledger Entry No.";
                    NonDistrRentalItemJnlLine.CopyTrackingFromSpec(TempTrackingSpecificationInv);
                    RentalItemJnlPostLine.RunWithCheck(NonDistrRentalItemJnlLine);
                    NonDistrRentalItemJnlLine."Location Code" := RentalItemJnlLine2."Location Code";
                end;
            until TempTrackingSpecificationInv.Next() = 0;
        end;
    end;

    local procedure PostItemChargePerShpt(RentalHeader: Record "TWE Rental Header"; var RentalLine: Record "TWE Rental Line")
    var
        RentalShptLine: Record "TWE Rental Shipment Line";
        TempItemLedgEntry: Record "Item Ledger Entry" temporary;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        DistributeCharge: Boolean;
        IsHandled: Boolean;
    begin
        if not RentalShptLine.Get(
             TempItemChargeAssgntSales."Applies-to Doc. No.", TempItemChargeAssgntSales."Applies-to Doc. Line No.")
        then
            Error(ShipmentLinesDeletedErr);

        IsHandled := false;
        PostingEvents.OnPostItemChargePerShptOnBeforeTestJobNo(RentalShptLine, IsHandled, RentalLine);
        if not IsHandled then
            RentalShptLine.TestField("Job No.", '');

        if RentalShptLine."Item Shpt. Entry No." <> 0 then
            DistributeCharge :=
              CostCalcMgt.SplitItemLedgerEntriesExist(
                TempItemLedgEntry, -RentalShptLine."Quantity (Base)", RentalShptLine."Item Shpt. Entry No.")
        else begin
            DistributeCharge := true;
            if not ItemTrackingMgt.CollectItemEntryRelation(TempItemLedgEntry,
                 DATABASE::"Sales Shipment Line", 0, RentalShptLine."Document No.",
                 '', 0, RentalShptLine."Line No.", -RentalShptLine."Quantity (Base)")
            then
                Error(RelatedItemLedgEntriesNotFoundErr);
        end;

        if DistributeCharge then
            PostDistributeItemCharge(
              RentalHeader, RentalLine, TempItemLedgEntry, RentalShptLine."Quantity (Base)",
              TempItemChargeAssgntSales."Qty. to Assign", TempItemChargeAssgntSales."Amount to Assign")
        else
            PostItemCharge(RentalHeader, RentalLine,
              RentalShptLine."Item Shpt. Entry No.", RentalShptLine."Quantity (Base)",
              TempItemChargeAssgntSales."Amount to Assign",
              TempItemChargeAssgntSales."Qty. to Assign");
    end;

    local procedure PostItemChargePerRetRcpt(RentalHeader: Record "TWE Rental Header"; var RentalLine: Record "TWE Rental Line")
    var
        ReturnRcptLine: Record "Return Receipt Line";
        TempItemLedgEntry: Record "Item Ledger Entry" temporary;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        DistributeCharge: Boolean;
        IsHandled: Boolean;
    begin
        if not ReturnRcptLine.Get(
             TempItemChargeAssgntSales."Applies-to Doc. No.", TempItemChargeAssgntSales."Applies-to Doc. Line No.")
        then
            Error(ShipmentLinesDeletedErr);

        IsHandled := false;
        PostingEvents.OnPostItemChargePerRetRcptOnBeforeTestFieldJobNo(ReturnRcptLine, IsHandled, RentalLine);
        if not IsHandled then
            ReturnRcptLine.TestField("Job No.", '');

        if ReturnRcptLine."Item Rcpt. Entry No." <> 0 then
            DistributeCharge :=
              CostCalcMgt.SplitItemLedgerEntriesExist(
                TempItemLedgEntry, ReturnRcptLine."Quantity (Base)", ReturnRcptLine."Item Rcpt. Entry No.")
        else begin
            DistributeCharge := true;
            if not ItemTrackingMgt.CollectItemEntryRelation(TempItemLedgEntry,
                 DATABASE::"Return Receipt Line", 0, ReturnRcptLine."Document No.",
                 '', 0, ReturnRcptLine."Line No.", ReturnRcptLine."Quantity (Base)")
            then
                Error(RelatedItemLedgEntriesNotFoundErr);
        end;

        if DistributeCharge then
            PostDistributeItemCharge(
              RentalHeader, RentalLine, TempItemLedgEntry, ReturnRcptLine."Quantity (Base)",
              TempItemChargeAssgntSales."Qty. to Assign", TempItemChargeAssgntSales."Amount to Assign")
        else
            PostItemCharge(RentalHeader, RentalLine,
              ReturnRcptLine."Item Rcpt. Entry No.", ReturnRcptLine."Quantity (Base)",
              TempItemChargeAssgntSales."Amount to Assign",
              TempItemChargeAssgntSales."Qty. to Assign")
    end;

    local procedure PostDistributeItemCharge(RentalHeader: Record "TWE Rental Header"; RentalLine: Record "TWE Rental Line"; var TempItemLedgEntry: Record "Item Ledger Entry" temporary; NonDistrQuantity: Decimal; NonDistrQtyToAssign: Decimal; NonDistrAmountToAssign: Decimal)
    var
        Factor: Decimal;
        QtyToAssign: Decimal;
        AmountToAssign: Decimal;
    begin
        if TempItemLedgEntry.FindSet() then
            repeat
                Factor := Abs(TempItemLedgEntry.Quantity / NonDistrQuantity);
                QtyToAssign := NonDistrQtyToAssign * Factor;
                AmountToAssign := Round(NonDistrAmountToAssign * Factor, GLSetup."Amount Rounding Precision");
                if Factor < 1 then begin
                    PostItemCharge(RentalHeader, RentalLine,
                      TempItemLedgEntry."Entry No.", -TempItemLedgEntry.Quantity,
                      AmountToAssign, QtyToAssign);
                    NonDistrQuantity := NonDistrQuantity + TempItemLedgEntry.Quantity;
                    NonDistrQtyToAssign := NonDistrQtyToAssign - QtyToAssign;
                    NonDistrAmountToAssign := NonDistrAmountToAssign - AmountToAssign;
                end else // the last time
                    PostItemCharge(RentalHeader, RentalLine,
                      TempItemLedgEntry."Entry No.", -TempItemLedgEntry.Quantity,
                      NonDistrAmountToAssign, NonDistrQtyToAssign);
            until TempItemLedgEntry.Next() = 0
        else
            Error(RelatedItemLedgEntriesNotFoundErr);
    end;

    local procedure PostAssocItemJnlLine(RentalHeader: Record "TWE Rental Header"; RentalLine: Record "TWE Rental Line"; QtyToBeShipped: Decimal; QtyToBeShippedBase: Decimal): Integer
    var
        RentalItemJnlLine: Record "TWE Rental Item Journal Line";
        TempHandlingSpecification2: Record "Tracking Specification" temporary;
        ItemEntryRelation: Record "Item Entry Relation";
        PurchOrderHeader: Record "Purchase Header";
        PurchOrderLine: Record "Purchase Line";
        IsHandled: Boolean;
    begin
        PurchOrderHeader.Get(
          PurchOrderHeader."Document Type"::Order, RentalLine."Purchase Order No.");
        PurchOrderLine.Get(
          PurchOrderLine."Document Type"::Order, RentalLine."Purchase Order No.", RentalLine."Purch. Order Line No.");

        InitAssocItemJnlLine(RentalItemJnlLine, PurchOrderHeader, PurchOrderLine, RentalHeader, RentalLine, QtyToBeShipped, QtyToBeShippedBase);

        IsHandled := false;
        PostingEvents.OnPostAssocItemJnlLineOnBeforePost(RentalItemJnlLine, PurchOrderLine, IsHandled);
        if (PurchOrderLine."Job No." = '') or IsHandled then begin
            TransferReservFromPurchLine(PurchOrderLine, RentalItemJnlLine, RentalLine, QtyToBeShippedBase);
            PostingEvents.OnBeforePostAssocItemJnlLine(RentalItemJnlLine, PurchOrderLine, SuppressCommit, RentalLine);
            RentalItemJnlPostLine.RunWithCheck(RentalItemJnlLine);

            // Handle Item Tracking
            if RentalItemJnlPostLine.CollectTrackingSpecification(TempHandlingSpecification2) then begin
                if TempHandlingSpecification2.FindSet() then
                    repeat
                        TempTrackingSpecification := TempHandlingSpecification2;
                        TempTrackingSpecification.SetSourceFromPurchLine(PurchOrderLine);
                        if TempTrackingSpecification.Insert() then;
                        ItemEntryRelation.InitFromTrackingSpec(TempHandlingSpecification2);
                        ItemEntryRelation.SetSource(DATABASE::"Purch. Rcpt. Line", 0, PurchOrderHeader."Receiving No.", PurchOrderLine."Line No.");
                        ItemEntryRelation.SetOrderInfo(PurchOrderLine."Document No.", PurchOrderLine."Line No.");
                        ItemEntryRelation.Insert();
                    until TempHandlingSpecification2.Next() = 0;
                exit(0);
            end;
        end;

        exit(RentalItemJnlLine."Item Shpt. Entry No.");
    end;

    local procedure InitAssocItemJnlLine(var RentalItemJnlLine: Record "TWE Rental Item Journal Line"; PurchOrderHeader: Record "Purchase Header"; PurchOrderLine: Record "Purchase Line"; RentalHeader: Record "TWE Rental Header"; RentalLine: Record "TWE Rental Line"; QtyToBeShipped: Decimal; QtyToBeShippedBase: Decimal)
    begin
        PostingEvents.OnBeforeInitAssocItemJnlLine(RentalItemJnlLine, PurchOrderHeader, PurchOrderLine, RentalHeader, RentalLine);


        RentalItemJnlLine.Init;
        RentalItemJnlLine."Entry Type" := RentalItemJnlLine."Entry Type"::Purchase;
        RentalItemJnlLine.CopyDocumentFields(
          RentalItemJnlLine."Document Type"::"Purchase Receipt", PurchOrderHeader."Receiving No.", PurchOrderHeader."No.", SrcCode,
          PurchOrderHeader."Posting No. Series");

        RentalItemJnlLine.CopyFromPurchHeader(PurchOrderHeader);
        RentalItemJnlLine."Posting Date" := RentalHeader."Posting Date";
        RentalItemJnlLine."Document Date" := RentalHeader."Document Date";
        RentalItemJnlLine.CopyFromPurchLine(PurchOrderLine);

        RentalItemJnlLine.Quantity := QtyToBeShipped;
        RentalItemJnlLine."Quantity (Base)" := QtyToBeShippedBase;
        RentalItemJnlLine."Invoiced Quantity" := 0;
        RentalItemJnlLine."Invoiced Qty. (Base)" := 0;
        RentalItemJnlLine."Source Currency Code" := RentalHeader."Currency Code";
        RentalItemJnlLine.Amount := Round(PurchOrderLine.Amount * QtyToBeShipped / PurchOrderLine.Quantity);
        RentalItemJnlLine."Discount Amount" := PurchOrderLine."Line Discount Amount";

        RentalItemJnlLine."Applies-to Entry" := 0;

        PostingEvents.OnAfterInitAssocItemJnlLine(RentalItemJnlLine, PurchOrderHeader, PurchOrderLine, RentalHeader, RentalLine);
    end;

    local procedure ReleaseSalesDocument(var RentalHeader: Record "TWE Rental Header")
    var
        RentalHeaderCopy: Record "TWE Rental Header";
        TempAsmHeader: Record "Assembly Header" temporary;
        ReleaseRentalDocument: Codeunit "TWE Release Rental Document";
        LinesWereModified: Boolean;
        SavedStatus: Enum "Sales Document Status";
        IsHandled: Boolean;
    begin
        if not (RentalHeader.Status = RentalHeader.Status::Open) or (RentalHeader.Status = RentalHeader.Status::"Pending Prepayment") then
            exit;

        RentalHeaderCopy := RentalHeader;
        SavedStatus := RentalHeader.Status;
        GetOpenLinkedATOs(TempAsmHeader);
        PostingEvents.OnBeforeReleaseSalesDoc(RentalHeader);
        LinesWereModified := ReleaseRentalDocument.ReleaseTWERentalHeader(RentalHeader, PreviewMode);
        if LinesWereModified then
            RefreshTempLines(RentalHeader, TempRentalLineGlobal);
        TestStatusRelease(RentalHeader);
        RentalHeader.Status := SavedStatus;
        RestoreRentalHeader(RentalHeader, RentalHeaderCopy);
        ReopenAsmOrders(TempAsmHeader);
        PostingEvents.OnAfterReleaseSalesDoc(RentalHeader);
        if not (PreviewMode or SuppressCommit) then begin
            RentalHeader.Modify();
            Commit();
        end;
        IsHandled := false;
        PostingEvents.OnReleaseSalesDocumentOnBeforeSetStatus(RentalHeader, IsHandled, SavedStatus, PreviewMode, SuppressCommit);
        if not IsHandled then
            RentalHeader.Status := RentalHeader.Status::Released;
    end;

    local procedure TestStatusRelease(RentalHeader: Record "TWE Rental Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        PostingEvents.OnBeforeTestStatusRelease(RentalHeader, IsHandled);
        if not IsHandled then
            RentalHeader.TestField(Status, RentalHeader.Status::Released);
    end;

    local procedure TestRentalLine(RentalHeader: Record "TWE Rental Header"; RentalLine: Record "TWE Rental Line")
    var
        DummyTrackingSpecification: Record "Tracking Specification";
        rentalItem: Record "Service Item";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        PostingEvents.OnBeforeTestRentalLine(RentalHeader, RentalLine, SuppressCommit, IsHandled);
        if IsHandled then
            exit;

        case RentalLine.Type of
            RentalLine.Type::"Rental Item":
                begin
                    if not RentalHeader.IsCreditDocType() and (RentalLine."Qty. Shipped (Base)" = 0) then begin
                        if rentalItem.Get(RentalLine."Rental Item") then
                            rentalItem.TestField("TWE Rented", false);
                    end;

                    DummyTrackingSpecification.CheckItemTrackingQuantity(
                        DATABASE::"TWE Rental Line", RentalLine."Document Type".AsInteger(), RentalLine."Document No.", RentalLine."Line No.",
                        RentalLine."Qty. to Ship (Base)", RentalLine."Qty. to Invoice (Base)", RentalHeader.Ship, RentalHeader.Invoice);
                end;
        /*                 else
                            TestSalesLineOthers(RentalLine); */
        end;
        TestSalesLineJob(RentalLine);

        case RentalLine."Document Type" of
            RentalLine."Document Type"::Invoice:
                begin
                    if RentalLine."Shipment No." = '' then
                        RentalLine.TestField("Qty. to Ship", RentalLine.Quantity);

                    RentalLine.TestField("Qty. to Invoice", RentalLine.Quantity);
                end;
            RentalLine."Document Type"::"Credit Memo":
                begin/* 
                        if "Return Receipt No." = '' then
                            TestField("Return Qty. to Receive", Quantity); */
                    RentalLine.TestField("Qty. to Ship", 0);
                    RentalLine.TestField("Qty. to Invoice", 0);
                end;
            RentalLine."Document Type"::"Return Shipment":
                begin
                    RentalLine.TestField("Return Quantity", RentalLine.Quantity);
                    If RentalLine.Type = RentalLine.Type::"Rental Item" then
                        RentalLine.TestField("Quantity Returned", 0);
                end;
        end;



        PostingEvents.OnAfterTestSalesLine(RentalHeader, RentalLine, WhseShip, WhseReceive, SuppressCommit);
    end;

    local procedure TestSalesLineItemCharge(RentalLine: Record "TWE Rental Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        PostingEvents.OnBeforeTestSalesLineItemCharge(RentalLine, IsHandled);
        if IsHandled then
            exit;

        RentalLine.TestField(Amount);
        /*             RentalLine.TestField("Job No.", '');
                    RentalLine.TestField("Job Contract Entry No.", 0); */
    end;

    local procedure TestSalesLineFixedAsset(RentalLine: Record "TWE Rental Line")
    var
        FixedAsset: Record "Fixed Asset";
        DeprBook: Record "Depreciation Book";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        PostingEvents.OnBeforeTestSalesLineFixedAsset(RentalLine, IsHandled);
        if IsHandled then
            exit;

        /*             RentalLine.TestField("Job No.", '');
                    RentalLine.TestField("Depreciation Book Code");
                    DeprBook.Get("Depreciation Book Code"); */
        DeprBook.TestField("G/L Integration - Disposal", true);
        FixedAsset.Get(RentalLine."No.");
        FixedAsset.TestField("Budgeted Asset", false);
    end;

    local procedure TestSalesLineJob(RentalLine: Record "TWE Rental Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        PostingEvents.OnBeforeTestSalesLineJob(RentalLine, IsHandled);
        if IsHandled then
            exit;

        /*             if not (RentalLine."Document Type" in [RentalLine."Document Type"::Invoice, RentalLine."Document Type"::"Credit Memo"]) then
                        RentalLine.TestField("Job No.", ''); */
    end;

    local procedure TestUpdatedRentalLine(RentalLine: Record "TWE Rental Line")
    var
        ForwardLinkMgt: Codeunit "Forward Link Mgt.";
    begin
        if RentalLine."Drop Shipment" then begin
            if RentalLine.Type <> RentalLine.Type::"Rental Item" then
                RentalLine.TestField("Drop Shipment", false);
            if (RentalLine."Qty. to Ship" <> 0) and (RentalLine."Purch. Order Line No." = 0) then
                ErrorMessageMgt.LogErrorMessage(RentalLine.FieldNo("Purchasing Code"), StrSubstNo(DropShipmentErr, RentalLine."Line No."),
                    0, 0, ForwardLinkMgt.GetHelpCodeForSalesLineDropShipmentErr());
        end;

        if RentalLine.Quantity = 0 then
            RentalLine.TestField(Amount, 0)
        else begin
            RentalLine.TestField("No.");
            RentalLine.TestField(Type);
            if not ApplicationAreaMgmt.IsSalesTaxEnabled then begin
                RentalLine.TestField("Gen. Bus. Posting Group");
                RentalLine.TestField("Gen. Prod. Posting Group");
            end;
        end;
    end;

    local procedure UpdatePostingNos(var RentalHeader: Record "TWE Rental Header") ModifyHeader: Boolean
    var
        NoSeriesMgt: Codeunit NoSeriesManagement;
        IsHandled: Boolean;
        TelemetryCustomDimensions: Dictionary of [Text, Text];
        PreviewTokenFoundLbl: Label 'Preview token %1 found on fields.', Locked = true;
    begin
        PostingEvents.OnBeforeUpdatePostingNos(RentalHeader, NoSeriesMgt, SuppressCommit, ModifyHeader);

        IsHandled := false;
        PostingEvents.OnBeforeUpdateShippingNo(RentalHeader, WhseShip, WhseReceive, InvtPickPutaway, PreviewMode, ModifyHeader, IsHandled);

        if (RentalHeader."Shipping No." = PostingPreviewNoTok) or (RentalHeader."Return Receipt No." = PostingPreviewNoTok) or (RentalHeader."Posting No." = PostingPreviewNoTok) then begin
            TelemetryCustomDimensions.Add(RentalHeader.FieldCaption("No."), RentalHeader."No.");
            TelemetryCustomDimensions.Add(RentalHeader.FieldCaption("Document Type"), Format(RentalHeader."Document Type"));

            if RentalHeader."Shipping No." = PostingPreviewNoTok then begin
                TelemetryCustomDimensions.Add(RentalHeader.FieldCaption("Shipping No."), RentalHeader."Shipping No.");
                RentalHeader."Shipping No." := '';
            end;
            if RentalHeader."Return Receipt No." = PostingPreviewNoTok then begin
                TelemetryCustomDimensions.Add(RentalHeader.FieldCaption("Return Receipt No."), RentalHeader."Return Receipt No.");
                RentalHeader."Return Receipt No." := '';
            end;
            if RentalHeader."Posting No." = PostingPreviewNoTok then begin
                TelemetryCustomDimensions.Add(RentalHeader.FieldCaption("Posting No."), RentalHeader."Posting No.");
                RentalHeader."Posting No." := '';
            end;

            Session.LogMessage('0000CUV', StrSubstNo(PreviewTokenFoundLbl, PostingPreviewNoTok), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::All, TelemetryCustomDimensions);
        end;

        if not IsHandled then
            if RentalHeader.Ship and (RentalHeader."Shipping No." = '') then
                if (RentalHeader."Document Type" = RentalHeader."Document Type"::Contract) or
                   ((RentalHeader."Document Type" = RentalHeader."Document Type"::Invoice) and RentalSetup."Shipment on Invoice")
                then
                    if not PreviewMode then begin
                        ResetPostingNoSeriesFromSetup(RentalHeader."Shipping No. Series", RentalSetup."Posted Rental Shipment Nos.");
                        RentalHeader.TestField("Shipping No. Series");
                        RentalHeader."Shipping No." := NoSeriesMgt.GetNextNo(RentalHeader."Shipping No. Series", RentalHeader."Posting Date", true);
                        ModifyHeader := true;

                        // Check for posting conflicts.
                        if RentalShptHeader.Get(RentalHeader."Shipping No.") then
                            Error(SalesShptHeaderConflictErr, RentalHeader."Shipping No.");
                    end else
                        RentalHeader."Shipping No." := PostingPreviewNoTok;

        if RentalHeader.Receive and (RentalHeader."Return Receipt No." = '') then
            if (RentalHeader."Document Type" = RentalHeader."Document Type"::"Credit Memo") then //and RentalSetup."Return Receipt on Credit Memo")
                if not PreviewMode then begin
                    /*  ResetPostingNoSeriesFromSetup("Return Receipt No. Series", RentalSetup."Posted Return Receipt Nos.");
                     TestField("Return Receipt No. Series");
                     "Return Receipt No." := NoSeriesMgt.GetNextNo("Return Receipt No. Series", "Posting Date", true); */
                    ModifyHeader := true;

                    // Check for posting conflicts.
                    if ReturnRcptHeader.Get(RentalHeader."Return Receipt No.") then
                        Error(SalesReturnRcptHeaderConflictErr, RentalHeader."Return Receipt No.")
                end else
                    RentalHeader."Return Receipt No." := PostingPreviewNoTok;

        IsHandled := false;
        PostingEvents.OnBeforeUpdatePostingNo(RentalHeader, PreviewMode, ModifyHeader, IsHandled);
        if not IsHandled then
            if RentalHeader.Invoice and (RentalHeader."Posting No." = '') then begin
                if (RentalHeader."No. Series" <> '') or
                   (RentalHeader."Document Type" in [RentalHeader."Document Type"::Contract])
                then begin
                    /*                         if "Document Type" in ["Document Type"::"Return Order"] then
                                                ResetPostingNoSeriesFromSetup("Posting No. Series", RentalSetup."Posted Credit Memo Nos.")
                                            else */
                    ResetPostingNoSeriesFromSetup(RentalHeader."Posting No. Series", RentalSetup."Posted Rental Invoice Nos.");
                    RentalHeader.TestField("Posting No. Series");
                end;
                if (RentalHeader."No. Series" <> RentalHeader."Posting No. Series") or
                   (RentalHeader."Document Type" in [RentalHeader."Document Type"::Contract])
                then begin
                    if not PreviewMode then begin
                        RentalHeader."Posting No." := NoSeriesMgt.GetNextNo(RentalHeader."Posting No. Series", RentalHeader."Posting Date", true);
                        ModifyHeader := true;
                    end else
                        RentalHeader."Posting No." := PostingPreviewNoTok;
                end;

                // Check for posting conflicts.
                if not PreviewMode then
                    if RentalHeader."Document Type" in [RentalHeader."Document Type"::Contract, RentalHeader."Document Type"::Invoice] then begin
                        if RentalInvHeader.Get(RentalHeader."Posting No.") then
                            Error(SalesInvHeaderConflictErr, RentalHeader."Posting No.");
                    end else
                        if RentalCrMemoHeader.Get(RentalHeader."Posting No.") then
                            Error(SalesCrMemoHeaderConflictErr, RentalHeader."Posting No.");
            end;

        PostingEvents.OnAfterUpdatePostingNos(RentalHeader, NoSeriesMgt, SuppressCommit);
    end;

    local procedure ResetPostingNoSeriesFromSetup(var PostingNoSeries: Code[20]; SetupNoSeries: Code[20])
    begin
        if (PostingNoSeries = '') and (SetupNoSeries <> '') then
            PostingNoSeries := SetupNoSeries;
    end;

    local procedure UpdateAssocOrder(var TempDropShptPostBuffer: Record "Drop Shpt. Post. Buffer" temporary)
    var
        PurchOrderHeader: Record "Purchase Header";
        PurchOrderLine: Record "Purchase Line";
        ReservePurchLine: Codeunit "Purch. Line-Reserve";
    begin
        TempDropShptPostBuffer.Reset();
        if TempDropShptPostBuffer.IsEmpty() then
            exit;
        Clear(PurchOrderHeader);
        TempDropShptPostBuffer.FindSet();
        repeat
            if PurchOrderHeader."No." <> TempDropShptPostBuffer."Order No." then begin
                PurchOrderHeader.Get(PurchOrderHeader."Document Type"::Order, TempDropShptPostBuffer."Order No.");
                PurchOrderHeader."Last Receiving No." := PurchOrderHeader."Receiving No.";
                PurchOrderHeader."Receiving No." := '';
                PurchOrderHeader.Modify();
                PostingEvents.OnUpdateAssosOrderOnAfterPurchOrderHeaderModify(PurchOrderHeader);
                ReservePurchLine.UpdateItemTrackingAfterPosting(PurchOrderHeader);
            end;
            PurchOrderLine.Get(
              PurchOrderLine."Document Type"::Order,
              TempDropShptPostBuffer."Order No.", TempDropShptPostBuffer."Order Line No.");
            PurchOrderLine."Quantity Received" := PurchOrderLine."Quantity Received" + TempDropShptPostBuffer.Quantity;
            PurchOrderLine."Qty. Received (Base)" := PurchOrderLine."Qty. Received (Base)" + TempDropShptPostBuffer."Quantity (Base)";
            PurchOrderLine.InitOutstanding();
            PurchOrderLine.ClearQtyIfBlank;
            PurchOrderLine.InitQtyToReceive;
            PostingEvents.OnUpdateAssocOrderOnBeforeModifyPurchLine(PurchOrderLine, TempDropShptPostBuffer);
            PurchOrderLine.Modify();
            PostingEvents.OnUpdateAssocOrderOnAfterModifyPurchLine(PurchOrderLine, TempDropShptPostBuffer);
        until TempDropShptPostBuffer.Next() = 0;

        TempDropShptPostBuffer.DeleteAll();
    end;

    local procedure UpdateAssocLines(var RentalOrderLine: Record "TWE Rental Line")
    var
        PurchOrderLine: Record "Purchase Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        PostingEvents.OnBeforeUpdateAssocLines(RentalOrderLine, IsHandled);
        if IsHandled then
            exit;

        if not PurchOrderLine.Get(
                PurchOrderLine."Document Type"::Order,
                RentalOrderLine."Purchase Order No.", RentalOrderLine."Purch. Order Line No.") then
            exit;
        PurchOrderLine."Sales Order No." := '';
        PurchOrderLine."Sales Order Line No." := 0;
        PurchOrderLine.Modify();
        RentalOrderLine."Purchase Order No." := '';
        RentalOrderLine."Purch. Order Line No." := 0;
    end;

    local procedure UpdateAssosOrderPostingNos(RentalHeader: Record "TWE Rental Header") DropShipment: Boolean
    var
        TempRentalLine: Record "TWE Rental Line" temporary;
        PurchOrderHeader: Record "Purchase Header";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        ReleasePurchaseDocument: Codeunit "Release Purchase Document";
    begin
        ResetTempLines(TempRentalLine);
        TempRentalLine.SetFilter("Purch. Order Line No.", '<>0');
        DropShipment := not TempRentalLine.IsEmpty;

        TempRentalLine.SetFilter("Qty. to Ship", '<>0');
        if DropShipment and RentalHeader.Ship then
            if TempRentalLine.FindSet() then
                repeat
                    if PurchOrderHeader."No." <> TempRentalLine."Purchase Order No." then begin
                        PurchOrderHeader.Get(PurchOrderHeader."Document Type"::Order, TempRentalLine."Purchase Order No.");
                        PurchOrderHeader.TestField("Pay-to Vendor No.");
                        PurchOrderHeader.Receive := true;
                        PostingEvents.OnUpdateAssosOrderPostingNosOnBeforeReleasePurchaseDocument(PurchOrderHeader);
                        ReleasePurchaseDocument.ReleasePurchaseHeader(PurchOrderHeader, PreviewMode);
                        if PurchOrderHeader."Receiving No." = '' then begin
                            PurchOrderHeader.TestField("Receiving No. Series");
                            PurchOrderHeader."Receiving No." :=
                              NoSeriesMgt.GetNextNo(PurchOrderHeader."Receiving No. Series", RentalHeader."Posting Date", true);
                            PurchOrderHeader.Modify();
                        end;
                        PostingEvents.OnUpdateAssosOrderPostingNosOnAfterReleasePurchaseDocument(PurchOrderHeader);
                    end;
                until TempRentalLine.Next() = 0;

        PostingEvents.OnAfterUpdateAssosOrderPostingNos(RentalHeader, TempRentalLine, DropShipment);
        exit(DropShipment);
    end;

    local procedure UpdateAfterPosting(RentalHeader: Record "TWE Rental Header")
    var
        TempRentalLine: Record "TWE Rental Line" temporary;
    begin

        ResetTempLines(TempRentalLine);
        TempRentalLine.SetFilter("Qty. to Assemble to Order", '<>0');
        if TempRentalLine.FindSet() then
            repeat
                FinalizePostATO(TempRentalLine);
            until TempRentalLine.Next() = 0;

        ResetTempLines(TempRentalLine);

        PostingEvents.OnAfterUpdateAfterPosting(RentalHeader, TempRentalLine);
    end;

    local procedure UpdateLastPostingNos(var RentalHeader: Record "TWE Rental Header")
    begin
        if RentalHeader.Ship then begin
            RentalHeader."Last Shipping No." := RentalHeader."Shipping No.";
            RentalHeader."Shipping No." := '';
        end;
        if RentalHeader.Invoice then begin
            RentalHeader."Last Posting No." := RentalHeader."Posting No.";
            RentalHeader."Posting No." := '';
        end;
        if RentalHeader.Receive then begin
            RentalHeader."Last Return Receipt No." := RentalHeader."Return Receipt No.";
            RentalHeader."Return Receipt No." := '';
        end;

        PostingEvents.OnAfterUpdateLastPostingNos(RentalHeader);
    end;

    local procedure UpdateRentalLineBeforePost(RentalHeader: Record "TWE Rental Header"; var RentalLine: Record "TWE Rental Line")
    begin
        PostingEvents.OnBeforeUpdateSalesLineBeforePost(RentalLine, RentalHeader, WhseShip, WhseReceive, RoundingLineInserted, SuppressCommit);

        if not (RentalHeader.Ship or RoundingLineInserted) then begin
            RentalLine."Qty. to Ship" := 0;
            RentalLine."Qty. to Ship (Base)" := 0;
        end;

        JobContractLine := false;
        if RentalLine.Type = RentalLine.Type::Resource then
            JobTaskRentalLine := RentalLine;

        if (RentalHeader."Document Type" = RentalHeader."Document Type"::Invoice) and (RentalLine."Shipment No." <> '') then begin
            RentalLine."Quantity Shipped" := RentalLine.Quantity;
            RentalLine."Qty. Shipped (Base)" := RentalLine."Quantity (Base)";
            RentalLine."Qty. to Ship" := 0;
            RentalLine."Qty. to Ship (Base)" := 0;
        end;


        if RentalHeader.Invoice then begin
            if RentalLine."Document Type" <> RentalLine."Document Type"::"Credit Memo" then
                if Abs(RentalLine."Qty. to Invoice") > Abs(RentalLine.MaxQtyToInvoice) then
                    RentalLine.InitQtyToInvoice;
        end else begin
            RentalLine."Qty. to Invoice" := 0;
            RentalLine."Qty. to Invoice (Base)" := 0;
        end;

        if (RentalLine.Type = RentalLine.Type::"Rental Item") and (RentalLine."No." <> '') then begin
            RentalLine.GetMainRentalItem(MainRentalItem);
            if (MainRentalItem."Costing Method" = MainRentalItem."Costing Method"::Standard) and not RentalLine.IsShipment then
                RentalLine.GetUnitCost;
        end;

        PostingEvents.OnAfterUpdateSalesLineBeforePost(RentalLine, RentalHeader, WhseShip, WhseReceive, SuppressCommit);
    end;

    local procedure UpdateWhseDocuments(RentalHeader: Record "TWE Rental Header")
    begin
        if WhseReceive then begin
            WhsePostRcpt.PostUpdateWhseDocuments(WhseRcptHeader);
            TempWhseRcptHeader.Delete();
        end;
        if WhseShip then begin
            WhsePostShpt.PostUpdateWhseDocuments(WhseShptHeader);
            TempWhseShptHeader.Delete();
        end;

        PostingEvents.OnAfterUpdateWhseDocuments(RentalHeader, WhseShip, WhseReceive, WhseShptHeader, WhseRcptHeader);
    end;

    local procedure DeleteAfterPosting(var RentalHeader: Record "TWE Rental Header")
    var
        RentalCommentLine: Record "TWE Rental Comment Line";
        RentalLine: Record "TWE Rental Line";
        TempRentalLine: Record "TWE Rental Line" temporary;
        WarehouseRequest: Record "Warehouse Request";
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
        SkipDelete: Boolean;
    begin
        PostingEvents.OnBeforeDeleteAfterPosting(RentalHeader, RentalInvHeader, RentalCrMemoHeader, SkipDelete, SuppressCommit);
        if SkipDelete then
            exit;

        RentalLine.SetRange("Document Type", RentalHeader."Document Type");
        RentalLine.SetRange("Document No.", RentalHeader."No.");
        if RentalHeader."Document Type" = "TWE Rental Document Type"::Contract then begin
            RentalLine.SetRange("Line Closed", False);
            if not RentalLine.IsEmpty() then
                exit;
        end else begin
            if RentalHeader."Document Type" = RentalHeader."Document Type"::"Return Shipment" then begin
                checkAndDeleteCompletedContract(RentalHeader);
            end;
        end;

        if RentalHeader.HasLinks() then
            RentalHeader.DeleteLinks();
        RentalHeader.Delete();
        DeleteATOLinks(RentalHeader);
        ResetTempLines(TempRentalLine);
        if TempRentalLine.FindFirst() then
            repeat
                if TempRentalLine."Deferral Code" <> '' then
                    DeferralUtilities.RemoveOrSetDeferralSchedule(
                      '', "Deferral Document Type"::Sales.AsInteger(), '', '', TempRentalLine."Document Type".AsInteger(),
                      TempRentalLine."Document No.", TempRentalLine."Line No.", 0, 0D, TempRentalLine.Description, '', true);
                if TempRentalLine.HasLinks then
                    TempRentalLine.DeleteLinks();
            until TempRentalLine.Next() = 0;

        RentalLine.SetRange("Line Closed");
        PostingEvents.OnBeforeSalesLineDeleteAll(RentalLine, SuppressCommit);
        RentalLine.DeleteAll();

        DeleteItemChargeAssgnt(RentalHeader);
        RentalCommentLine.DeleteComments(RentalHeader."Document Type".AsInteger(), RentalHeader."No.");
        WarehouseRequest.DeleteRequest(DATABASE::"TWE Rental Line", RentalHeader."Document Type".AsInteger(), RentalHeader."No.");

        PostingEvents.OnAfterDeleteAfterPosting(RentalHeader, RentalInvHeader, RentalCrMemoHeader, SuppressCommit);
    end;

    local procedure checkAndDeleteCompletedContract(rentalHeader: Record "TWE Rental Header")
    var
        contractRentalHeader: Record "TWE Rental Header";
        contractRentalLine: Record "TWE Rental Line";
    begin
        if contractRentalHeader.Get(contractRentalHeader."Document Type"::Contract, rentalHeader."Belongs to Rental Contract") then begin
            contractRentalLine.SetRange("Document Type", contractRentalHeader."Document Type");
            contractRentalLine.SetRange("Document No.", contractRentalHeader."No.");
            contractRentalLine.SetRange("Line Closed", False);
            if contractRentalLine.IsEmpty() then begin
                if RentalSetup."Delete Contract" then begin
                    if contractRentalHeader.HasLinks() then
                        contractRentalHeader.DeleteLinks();
                    contractRentalHeader.Delete();
                    contractRentalLine.SetRange("Line Closed");
                    contractRentalLine.DeleteAll();
                end else begin
                    contractRentalHeader."Rental Contract closed" := true;
                    contractRentalHeader.Modify();
                end;
            end;
        end;
    end;

    local procedure FinalizePosting(var RentalHeader: Record "TWE Rental Header"; EverythingInvoiced: Boolean; var TempDropShptPostBuffer: Record "Drop Shpt. Post. Buffer" temporary)
    var
        TempRentalLine: Record "TWE Rental Line" temporary;
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        ICInboxOutboxMgt: Codeunit ICInboxOutboxMgt;
        WhseSalesRelease: Codeunit "Whse.-Sales Release";
        RentalArchiveManagement: Codeunit "TWE Rental Archive Management";
        IsHandled: Boolean;
    begin
        PostingEvents.OnBeforeFinalizePosting(RentalHeader, TempRentalLineGlobal, EverythingInvoiced, SuppressCommit, GenJnlPostLine);

        if (RentalHeader."Document Type" in [RentalHeader."Document Type"::Contract]) and
           (not EverythingInvoiced)
        then begin
            RentalHeader.Modify();
            InsertTrackingSpecification(RentalHeader);
            PostUpdateOrderLine(RentalHeader);
            UpdateRentalLineAfterPosting(RentalHeader);
            UpdateAssocOrder(TempDropShptPostBuffer);
            UpdateWhseDocuments(RentalHeader);
            UpdateItemChargeAssgnt();
        end else begin
            case RentalHeader."Document Type" of
                RentalHeader."Document Type"::Invoice:
                    begin
                        PostUpdateInvoiceLine;
                        InsertTrackingSpecification(RentalHeader);
                    end;
                RentalHeader."Document Type"::"Credit Memo":
                    begin
                        InsertTrackingSpecification(RentalHeader);
                    end;
                else begin
                        UpdateAssocOrder(TempDropShptPostBuffer);
                        if DropShipOrder then
                            InsertTrackingSpecification(RentalHeader);

                        ResetTempLines(TempRentalLine);
                        TempRentalLine.SetFilter("Purch. Order Line No.", '<>0');
                        if TempRentalLine.FindSet() then
                            repeat
                                UpdateAssocLines(TempRentalLine);
                                TempRentalLine.Modify();
                            until TempRentalLine.Next() = 0;

                        ResetTempLines(TempRentalLine);
                        TempRentalLine.SetFilter("Prepayment %", '<>0');
                        if TempRentalLine.FindSet() then
                            repeat
                                DecrementPrepmtAmtInvLCY(
                                  TempRentalLine, TempRentalLine."Prepmt. Amount Inv. (LCY)", TempRentalLine."Prepmt. VAT Amount Inv. (LCY)");
                                TempRentalLine.Modify();
                            until TempRentalLine.Next() = 0;
                    end;
            end;
            UpdateAfterPosting(RentalHeader);
            UpdateRentalLineAfterPosting(RentalHeader);
            UpdateEmailParameters(RentalHeader);
            UpdateWhseDocuments(RentalHeader);

            RentalArchiveManagement.AutoArchiveRentalDocument(RentalHeader);
            ApprovalsMgmt.DeleteApprovalEntries(RentalHeader.RecordId);
            if not PreviewMode then
                DeleteAfterPosting(RentalHeader);
        end;

        InsertValueEntryRelation;

        PostingEvents.OnAfterFinalizePostingOnBeforeCommit(
          RentalHeader, RentalShptHeader, RentalInvHeader, RentalCrMemoHeader, ReturnRcptHeader, GenJnlPostLine,
          SuppressCommit, PreviewMode, WhseShip, WhseReceive);

        if PreviewMode then begin
            if not HideProgressWindow then
                Window.Close();
            GenJnlPostPreview.ThrowError;
        end;
        if not (InvtPickPutaway or SuppressCommit) then begin
            Commit();
        end;

        if not HideProgressWindow then
            Window.Close();

        IsHandled := false;
        PostingEvents.OnFinalizePostingOnBeforeCreateOutboxSalesTrans(RentalHeader, IsHandled, EverythingInvoiced);

        PostingEvents.OnAfterFinalizePosting(
          RentalHeader, RentalShptHeader, RentalInvHeader, RentalCrMemoHeader, ReturnRcptHeader,
          GenJnlPostLine, SuppressCommit, PreviewMode);

        ClearPostBuffers;
    end;

    local procedure FillInvoicePostingBuffer(RentalHeader: Record "TWE Rental Header"; RentalLine: Record "TWE Rental Line"; RentalLineACY: Record "TWE Rental Line"; var TempInvoicePostBuffer: Record "Invoice Post. Buffer" temporary; var InvoicePostBuffer: Record "Invoice Post. Buffer")
    var
        GenPostingSetup: Record "General Posting Setup";
        TotalVAT: Decimal;
        TotalVATACY: Decimal;
        TotalAmount: Decimal;
        TotalAmountACY: Decimal;
        AmtToDefer: Decimal;
        AmtToDeferACY: Decimal;
        TotalVATBase: Decimal;
        TotalVATBaseACY: Decimal;
        DeferralAccount: Code[20];
        SalesAccount: Code[20];
        InvDiscAccount: code[20];
        LineDiscAccount: code[20];
        IsHandled: Boolean;
    begin
        GenPostingSetup.Get(RentalLine."Gen. Bus. Posting Group", RentalLine."Gen. Prod. Posting Group");

        InvoicePostBuffer.PrepareRental(RentalLine);

        TotalVAT := RentalLine."Amount Including VAT" - RentalLine.Amount;
        TotalVATACY := RentalLineACY."Amount Including VAT" - RentalLineACY.Amount;
        TotalAmount := RentalLine.Amount;
        TotalAmountACY := RentalLineACY.Amount;
        TotalVATBase := RentalLine."VAT Base Amount";
        TotalVATBaseACY := RentalLineACY."VAT Base Amount";

        PostingEvents.OnAfterInvoicePostingBufferAssignAmounts(RentalLine, TotalAmount, TotalAmountACY);

        if RentalLine."Deferral Code" <> '' then
            GetAmountsForDeferral(RentalLine, AmtToDefer, AmtToDeferACY, DeferralAccount)
        else begin
            AmtToDefer := 0;
            AmtToDeferACY := 0;
            DeferralAccount := '';
        end;

        if RentalSetup."Discount Posting" in
           [RentalSetup."Discount Posting"::"Invoice Discounts", RentalSetup."Discount Posting"::"All Discounts"]
        then begin
            IsHandled := false;
            PostingEvents.OnBeforeCalcInvoiceDiscountPosting(
              TempInvoicePostBuffer, InvoicePostBuffer, RentalHeader, RentalLine, TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY, IsHandled);
            if not IsHandled then begin
                CalcInvoiceDiscountPosting(RentalHeader, RentalLine, RentalLineACY, InvoicePostBuffer);
                if (InvoicePostBuffer.Amount <> 0) or (InvoicePostBuffer."Amount (ACY)" <> 0) then begin
                    IsHandled := false;
                    PostingEvents.OnFillInvoicePostingBufferOnBeforeSetInvDiscAccount(RentalLine, GenPostingSetup, InvDiscAccount, IsHandled);
                    if not IsHandled then
                        InvDiscAccount := GenPostingSetup.GetSalesInvDiscAccount;
                    InvoicePostBuffer.SetAccount(InvDiscAccount, TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY);
                    InvoicePostBuffer.UpdateVATBase(TotalVATBase, TotalVATBaseACY);
                    UpdateInvoicePostBuffer(TempInvoicePostBuffer, InvoicePostBuffer, true);
                end;
            end;
        end;

        if RentalSetup."Discount Posting" in
           [RentalSetup."Discount Posting"::"Line Discounts", RentalSetup."Discount Posting"::"All Discounts"]
        then begin
            IsHandled := false;
            PostingEvents.OnBeforeCalcLineDiscountPosting(
              TempInvoicePostBuffer, InvoicePostBuffer, RentalHeader, RentalLine, TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY, IsHandled);
            if not IsHandled then begin
                CalcLineDiscountPosting(RentalHeader, RentalLine, RentalLineACY, InvoicePostBuffer);
                if (InvoicePostBuffer.Amount <> 0) or (InvoicePostBuffer."Amount (ACY)" <> 0) then begin
                    IsHandled := false;
                    PostingEvents.OnFillInvoicePostingBufferOnBeforeSetLineDiscAccount(RentalLine, GenPostingSetup, LineDiscAccount, IsHandled);
                    if not IsHandled then
                        LineDiscAccount := GenPostingSetup.GetSalesLineDiscAccount;
                    InvoicePostBuffer.SetAccount(LineDiscAccount, TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY);
                    InvoicePostBuffer.UpdateVATBase(TotalVATBase, TotalVATBaseACY);
                    UpdateInvoicePostBuffer(TempInvoicePostBuffer, InvoicePostBuffer, true);
                    PostingEvents.OnFillInvoicePostingBufferOnAfterSetLineDiscAccount(RentalLine, GenPostingSetup, InvoicePostBuffer, TempInvoicePostBuffer);
                end;
            end;
        end;

        PostingEvents.OnFillInvoicePostingBufferOnBeforeDeferrals(RentalLine, TotalAmount, TotalAmountACY, UseDate);
        DeferralUtilities.AdjustTotalAmountForDeferralsNoBase(
          RentalLine."Deferral Code", AmtToDefer, AmtToDeferACY, TotalAmount, TotalAmountACY);

        PostingEvents.OnBeforeInvoicePostingBufferSetAmounts(
          RentalLine, TempInvoicePostBuffer, InvoicePostBuffer,
          TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY, TotalVATBase, TotalVATBaseACY);

        InvoicePostBuffer.SetAmounts(
          TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY, RentalLine."VAT Difference", TotalVATBase, TotalVATBaseACY);

        PostingEvents.OnAfterInvoicePostingBufferSetAmounts(InvoicePostBuffer, RentalLine);

        SalesAccount := GetSalesAccount(RentalLine, GenPostingSetup);

        PostingEvents.OnFillInvoicePostingBufferOnBeforeSetAccount(RentalHeader, RentalLine, SalesAccount);

        InvoicePostBuffer.SetAccount(SalesAccount, TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY);
        InvoicePostBuffer.UpdateVATBase(TotalVATBase, TotalVATBaseACY);
        InvoicePostBuffer."Deferral Code" := RentalLine."Deferral Code";
        PostingEvents.OnAfterFillInvoicePostBuffer(InvoicePostBuffer, RentalLine, TempInvoicePostBuffer, SuppressCommit);
        UpdateInvoicePostBuffer(TempInvoicePostBuffer, InvoicePostBuffer, false);

        PostingEvents.OnFillInvoicePostingBufferOnAfterUpdateInvoicePostBuffer(RentalHeader, RentalLine, InvoicePostBuffer, TempInvoicePostBuffer);
    end;

    local procedure GetSalesAccount(RentalLine: Record "TWE Rental Line"; GenPostingSetup: Record "General Posting Setup") SalesAccountNo: Code[20]
    begin
        if (RentalLine.Type = RentalLine.Type::"G/L Account") then
            SalesAccountNo := RentalLine."No."
        else
            if RentalLine.IsCreditDocType then
                SalesAccountNo := GenPostingSetup.GetSalesCrMemoAccount
            else
                SalesAccountNo := GenPostingSetup.GetSalesAccount;
        PostingEvents.OnAfterGetRentalAccount(RentalLine, GenPostingSetup, SalesAccountNo);
    end;

    local procedure UpdateInvoicePostBuffer(var TempInvoicePostBuffer: Record "Invoice Post. Buffer" temporary; InvoicePostBuffer: Record "Invoice Post. Buffer"; ForceGLAccountType: Boolean)
    var
        RestoreFAType: Boolean;
    begin
        if InvoicePostBuffer.Type = InvoicePostBuffer.Type::"Fixed Asset" then begin
            FALineNo := FALineNo + 1;
            InvoicePostBuffer."Fixed Asset Line No." := FALineNo;
            if ForceGLAccountType then begin
                RestoreFAType := true;
                InvoicePostBuffer.Type := InvoicePostBuffer.Type::"G/L Account";
            end;
        end;

        TempInvoicePostBuffer.Update(InvoicePostBuffer, InvDefLineNo, DeferralLineNo);

        if RestoreFAType then
            TempInvoicePostBuffer.Type := TempInvoicePostBuffer.Type::"Fixed Asset";
    end;

    local procedure InsertPrepmtAdjInvPostingBuf(RentalHeader: Record "TWE Rental Header"; PrepmtRentalLine: Record "TWE Rental Line"; var TempInvoicePostBuffer: Record "Invoice Post. Buffer" temporary; InvoicePostBuffer: Record "Invoice Post. Buffer")
    var
        SalesPostPrepayments: Codeunit "Sales-Post Prepayments";
        AdjAmount: Decimal;
    begin
        if PrepmtRentalLine."Prepayment Line" then
            if PrepmtRentalLine."Prepmt. Amount Inv. (LCY)" <> 0 then begin
                AdjAmount := -PrepmtRentalLine."Prepmt. Amount Inv. (LCY)";
                InvoicePostBuffer.FillPrepmtAdjBuffer(TempInvoicePostBuffer, InvoicePostBuffer,
                  PrepmtRentalLine."No.", AdjAmount, RentalHeader."Currency Code" = '');
                //InvoicePostBuffer.FillPrepmtAdjBuffer(TempInvoicePostBuffer, InvoicePostBuffer,
                //SalesPostPrepayments.GetCorrBalAccNo(RentalHeader, AdjAmount > 0),
                //-AdjAmount, RentalHeader."Currency Code" = '');
            end else
                if (PrepmtRentalLine."Prepayment %" = 100) and (PrepmtRentalLine."Prepmt. VAT Amount Inv. (LCY)" <> 0) then
                    InvoicePostBuffer.FillPrepmtAdjBuffer(TempInvoicePostBuffer, InvoicePostBuffer,
                      SalesPostPrepayments.GetInvRoundingAccNo(RentalHeader."Customer Posting Group"),
                      PrepmtRentalLine."Prepmt. VAT Amount Inv. (LCY)", RentalHeader."Currency Code" = '');
    end;

    local procedure GetCurrency(CurrencyCode: Code[10])
    begin
        if CurrencyCode = '' then
            Currency.InitRoundingPrecision
        else begin
            Currency.Get(CurrencyCode);
            Currency.TestField("Amount Rounding Precision");
        end;
    end;

    local procedure DivideAmount(RentalHeader: Record "TWE Rental Header"; var RentalLine: Record "TWE Rental Line"; QtyType: Option General,Invoicing,Shipping; SalesLineQty: Decimal; var TempVATAmountLine: Record "VAT Amount Line" temporary; var TempVATAmountLineRemainder: Record "VAT Amount Line" temporary)
    begin
        DivideAmount(RentalHeader, RentalLine, QtyType, SalesLineQty, TempVATAmountLine, TempVATAmountLineRemainder, true);
    end;

    local procedure DivideAmount(RentalHeader: Record "TWE Rental Header"; var RentalLine: Record "TWE Rental Line"; QtyType: Option General,Invoicing,Shipping; SalesLineQty: Decimal; var TempVATAmountLine: Record "VAT Amount Line" temporary; var TempVATAmountLineRemainder: Record "VAT Amount Line" temporary; IncludePrepayments: Boolean)
    var
        OriginalDeferralAmount: Decimal;
        TempDec: Decimal;
        TempDec2: Decimal;
    begin
        if RoundingLineInserted and (RoundingLineNo = RentalLine."Line No.") then
            exit;

        PostingEvents.OnBeforeDivideAmount(RentalHeader, RentalLine, QtyType, SalesLineQty, TempVATAmountLine, TempVATAmountLineRemainder);


        if (SalesLineQty = 0) or (RentalLine."Unit Price" = 0) then begin
            RentalLine."Line Amount" := 0;
            RentalLine."Line Discount Amount" := 0;
            RentalLine."Inv. Discount Amount" := 0;
            RentalLine."VAT Base Amount" := 0;
            RentalLine.Amount := 0;
            RentalLine."Amount Including VAT" := 0;
        end else begin
            TempVATAmountLine.Get(RentalLine."VAT Identifier", RentalLine."VAT Calculation Type", RentalLine."Tax Group Code", false, RentalLine."Line Amount" >= 0);
            if RentalLine."VAT Calculation Type" = RentalLine."VAT Calculation Type"::"Sales Tax" then
                RentalLine."VAT %" := TempVATAmountLine."VAT %";
            TempVATAmountLineRemainder := TempVATAmountLine;
            if not TempVATAmountLineRemainder.Find() then begin
                TempVATAmountLineRemainder.Init();
                TempVATAmountLineRemainder.Insert();
            end;

            if IncludePrepayments then begin
                TempDec := RentalLine.GetLineAmountToHandleInclPrepmt(SalesLineQty);
                TempDec2 := GetPrepmtDiffToLineAmount(RentalLine);
                RentalLine."Line Amount" := TempDec + TempDec2;
            end else begin
                RentalLine."Line Amount" := RentalLine.GetLineAmountToInvoice();
            end;

            if SalesLineQty <> RentalLine.Quantity then
                RentalLine."Line Discount Amount" :=
                  Round(RentalLine."Line Discount Amount" * SalesLineQty / RentalLine.Quantity, Currency."Amount Rounding Precision");

            if RentalLine."Allow Invoice Disc." and (TempVATAmountLine."Inv. Disc. Base Amount" <> 0) then
                if QtyType = QtyType::Invoicing then
                    RentalLine."Inv. Discount Amount" := RentalLine."Inv. Disc. Amount to Invoice"
                else begin
                    TempVATAmountLineRemainder."Invoice Discount Amount" :=
                      TempVATAmountLineRemainder."Invoice Discount Amount" +
                      TempVATAmountLine."Invoice Discount Amount" * RentalLine."Line Amount" /
                      TempVATAmountLine."Inv. Disc. Base Amount";
                    RentalLine."Inv. Discount Amount" :=
                      Round(
                        TempVATAmountLineRemainder."Invoice Discount Amount", Currency."Amount Rounding Precision");
                    TempVATAmountLineRemainder."Invoice Discount Amount" :=
                      TempVATAmountLineRemainder."Invoice Discount Amount" - RentalLine."Inv. Discount Amount";
                end;

            if RentalHeader."Prices Including VAT" then begin
                if (TempVATAmountLine.CalcLineAmount = 0) or (RentalLine."Line Amount" = 0) then begin
                    TempVATAmountLineRemainder."VAT Amount" := 0;
                    TempVATAmountLineRemainder."Amount Including VAT" := 0;
                end else begin
                    TempVATAmountLineRemainder."VAT Amount" +=
                      TempVATAmountLine."VAT Amount" * RentalLine.CalcLineAmountToInvoice() / TempVATAmountLine.CalcLineAmount();
                    TempVATAmountLineRemainder."Amount Including VAT" +=
                      TempVATAmountLine."Amount Including VAT" * RentalLine.CalcLineAmountToInvoice() / TempVATAmountLine.CalcLineAmount();
                end;
                if RentalLine."Line Discount %" <> 100 then
                    RentalLine."Amount Including VAT" :=
                      Round(TempVATAmountLineRemainder."Amount Including VAT", Currency."Amount Rounding Precision")
                else
                    RentalLine."Amount Including VAT" := 0;
                RentalLine.Amount :=
                  Round(RentalLine."Amount Including VAT", Currency."Amount Rounding Precision") -
                  Round(TempVATAmountLineRemainder."VAT Amount", Currency."Amount Rounding Precision");
                CalcVATBaseAmount(RentalHeader, RentalLine, TempVATAmountLine, TempVATAmountLineRemainder);
                TempVATAmountLineRemainder."Amount Including VAT" :=
                  TempVATAmountLineRemainder."Amount Including VAT" - RentalLine."Amount Including VAT";
                TempVATAmountLineRemainder."VAT Amount" :=
                  TempVATAmountLineRemainder."VAT Amount" - RentalLine."Amount Including VAT" + RentalLine.Amount;
            end else
                if RentalLine."VAT Calculation Type" = RentalLine."VAT Calculation Type"::"Full VAT" then begin
                    if RentalLine."Line Discount %" <> 100 then
                        RentalLine."Amount Including VAT" := RentalLine.CalcLineAmountToInvoice()
                    else
                        RentalLine."Amount Including VAT" := 0;
                    RentalLine.Amount := 0;
                    RentalLine."VAT Base Amount" := 0;
                end else begin
                    RentalLine.Amount := RentalLine.CalcLineAmountToInvoice();
                    CalcVATBaseAmount(RentalHeader, RentalLine, TempVATAmountLine, TempVATAmountLineRemainder);
                    if TempVATAmountLine."VAT Base" = 0 then
                        TempVATAmountLineRemainder."VAT Amount" := 0
                    else
                        TempVATAmountLineRemainder."VAT Amount" +=
                          TempVATAmountLine."VAT Amount" * RentalLine.CalcLineAmountToInvoice() / TempVATAmountLine.CalcLineAmount;
                    if RentalLine."Line Discount %" <> 100 then
                        RentalLine."Amount Including VAT" :=
                          RentalLine.Amount + Round(TempVATAmountLineRemainder."VAT Amount", Currency."Amount Rounding Precision")
                    else
                        RentalLine."Amount Including VAT" := 0;
                    TempVATAmountLineRemainder."VAT Amount" :=
                      TempVATAmountLineRemainder."VAT Amount" - RentalLine."Amount Including VAT" + RentalLine.Amount;
                end;

            PostingEvents.OnDivideAmountOnBeforeTempVATAmountLineRemainderModify(RentalHeader, RentalLine, TempVATAmountLine, TempVATAmountLineRemainder);
            TempVATAmountLineRemainder.Modify();
        end;

        PostingEvents.OnAfterDivideAmount(RentalHeader, RentalLine, QtyType, SalesLineQty, TempVATAmountLine, TempVATAmountLineRemainder);
    end;

    local procedure RoundAmount(RentalHeader: Record "TWE Rental Header"; var RentalLine: Record "TWE Rental Line"; SalesLineQty: Decimal)
    var
        CurrExchRate: Record "Currency Exchange Rate";
        NoVAT: Boolean;
    begin
        PostingEvents.OnBeforeRoundAmount(RentalHeader, RentalLine, SalesLineQty);

        IncrAmount(RentalHeader, RentalLine, TotalRentalLine);

        xRentalLine := RentalLine;
        RentalLineACY := RentalLine;
        PostingEvents.OnRoundAmountOnAfterAssignSalesLines(xRentalLine, RentalLineACY, RentalHeader);

        if RentalHeader."Currency Code" <> '' then begin
            if RentalHeader."Posting Date" = 0D then
                UseDate := WorkDate()
            else
                UseDate := RentalHeader."Posting Date";

            NoVAT := RentalLine.Amount = RentalLine."Amount Including VAT";
            RentalLine."Amount Including VAT" :=
              Round(
                CurrExchRate.ExchangeAmtFCYToLCY(
                  UseDate, RentalHeader."Currency Code",
                  TotalRentalLine."Amount Including VAT", RentalHeader."Currency Factor")) -
              TotalRentalLineLCY."Amount Including VAT";
            if NoVAT then
                RentalLine.Amount := RentalLine."Amount Including VAT"
            else
                RentalLine.Amount :=
                  Round(
                    CurrExchRate.ExchangeAmtFCYToLCY(
                      UseDate, RentalHeader."Currency Code",
                      TotalRentalLine.Amount, RentalHeader."Currency Factor")) -
                  TotalRentalLineLCY.Amount;
            RentalLine."Line Amount" :=
              Round(
                CurrExchRate.ExchangeAmtFCYToLCY(
                  UseDate, RentalHeader."Currency Code",
                  TotalRentalLine."Line Amount", RentalHeader."Currency Factor")) -
              TotalRentalLineLCY."Line Amount";
            RentalLine."Line Discount Amount" :=
              Round(
                CurrExchRate.ExchangeAmtFCYToLCY(
                  UseDate, RentalHeader."Currency Code",
                  TotalRentalLine."Line Discount Amount", RentalHeader."Currency Factor")) -
              TotalRentalLineLCY."Line Discount Amount";
            RentalLine."Inv. Discount Amount" :=
              Round(
                CurrExchRate.ExchangeAmtFCYToLCY(
                  UseDate, RentalHeader."Currency Code",
                  TotalRentalLine."Inv. Discount Amount", RentalHeader."Currency Factor")) -
              TotalRentalLineLCY."Inv. Discount Amount";
            RentalLine."VAT Difference" :=
              Round(
                CurrExchRate.ExchangeAmtFCYToLCY(
                  UseDate, RentalHeader."Currency Code",
                  TotalRentalLine."VAT Difference", RentalHeader."Currency Factor")) -
              TotalRentalLineLCY."VAT Difference";
            RentalLine."VAT Base Amount" :=
              Round(
                CurrExchRate.ExchangeAmtFCYToLCY(
                  UseDate, RentalHeader."Currency Code",
                  TotalRentalLine."VAT Base Amount", RentalHeader."Currency Factor")) -
              TotalRentalLineLCY."VAT Base Amount";
        end;

        PostingEvents.OnRoundAmountOnBeforeIncrAmount(RentalHeader, RentalLine, SalesLineQty, TotalRentalLine, TotalRentalLineLCY);
        IncrAmount(RentalHeader, RentalLine, TotalRentalLineLCY);
        Increment(TotalRentalLineLCY."Unit Cost (LCY)", Round(SalesLineQty * RentalLine."Unit Cost (LCY)"));

        PostingEvents.OnAfterRoundAmount(RentalHeader, RentalLine, SalesLineQty);
    end;

    procedure ReverseAmount(var RentalLine: Record "TWE Rental Line")
    begin

        RentalLine."Qty. to Ship" := -RentalLine."Qty. to Ship";
        RentalLine."Qty. to Ship (Base)" := -RentalLine."Qty. to Ship (Base)";
        RentalLine."Qty. to Invoice" := -RentalLine."Qty. to Invoice";
        RentalLine."Qty. to Invoice (Base)" := -RentalLine."Qty. to Invoice (Base)";
        RentalLine."Line Amount" := -RentalLine."Line Amount";
        RentalLine.Amount := -RentalLine.Amount;
        RentalLine."VAT Base Amount" := -RentalLine."VAT Base Amount";
        RentalLine."VAT Difference" := -RentalLine."VAT Difference";
        RentalLine."Amount Including VAT" := -RentalLine."Amount Including VAT";
        RentalLine."Line Discount Amount" := -RentalLine."Line Discount Amount";
        RentalLine."Inv. Discount Amount" := -RentalLine."Inv. Discount Amount";
        PostingEvents.OnAfterReverseAmount(RentalLine);
    end;

    local procedure InvoiceRounding(RentalHeader: Record "TWE Rental Header"; var RentalLine: Record "TWE Rental Line"; UseTempData: Boolean; BiggestLineNo: Integer)
    var
        CustPostingGr: Record "Customer Posting Group";
        InvoiceRoundingAmount: Decimal;
    begin
        Currency.TestField("Invoice Rounding Precision");
        InvoiceRoundingAmount :=
          -Round(
            TotalRentalLine."Amount Including VAT" -
            Round(
              TotalRentalLine."Amount Including VAT", Currency."Invoice Rounding Precision", Currency.InvoiceRoundingDirection),
            Currency."Amount Rounding Precision");

        PostingEvents.OnBeforeInvoiceRoundingAmount(
          RentalHeader, TotalRentalLine."Amount Including VAT", UseTempData, InvoiceRoundingAmount, SuppressCommit, TotalRentalLine);
        if InvoiceRoundingAmount <> 0 then begin
            CustPostingGr.Get(RentalHeader."Customer Posting Group");

            RentalLine.Init;
            BiggestLineNo := BiggestLineNo + 10000;
            RentalLine."System-Created Entry" := true;
            if UseTempData then begin
                RentalLine."Line No." := 0;
                RentalLine.Type := RentalLine.Type::"G/L Account";
                RentalLine.SetHideValidationDialog(true);
            end else begin
                RentalLine."Line No." := BiggestLineNo;
                RentalLine.Validate(Type, RentalLine.Type::"G/L Account");
            end;
            RentalLine.Validate("No.", CustPostingGr.GetInvRoundingAccount);
            RentalLine.Validate(Quantity, 1);
            if not RentalLine.IsCreditDocType then
                RentalLine.Validate("Qty. to Ship", RentalLine.Quantity);
            if RentalHeader."Prices Including VAT" then
                RentalLine.Validate("Unit Price", InvoiceRoundingAmount)
            else
                RentalLine.Validate(
                  "Unit Price",
                  Round(
                    InvoiceRoundingAmount /
                    (1 + (1 - RentalHeader."VAT Base Discount %" / 100) * RentalLine."VAT %" / 100),
                    Currency."Amount Rounding Precision"));
            RentalLine.Validate("Amount Including VAT", InvoiceRoundingAmount);
            RentalLine."Line No." := BiggestLineNo;
            LastLineRetrieved := false;
            RoundingLineInserted := true;
            RoundingLineNo := RentalLine."Line No.";
        end;

        PostingEvents.OnAfterInvoiceRoundingAmount(RentalHeader, RentalLine, TotalRentalLine, UseTempData, InvoiceRoundingAmount, SuppressCommit);
    end;

    local procedure IncrAmount(RentalHeader: Record "TWE Rental Header"; RentalLine: Record "TWE Rental Line"; var TotalRentalLine: Record "TWE Rental Line")
    begin
        if RentalHeader."Prices Including VAT" or
           (RentalLine."VAT Calculation Type" <> RentalLine."VAT Calculation Type"::"Full VAT")
        then
            Increment(TotalRentalLine."Line Amount", RentalLine."Line Amount");
        Increment(TotalRentalLine.Amount, RentalLine.Amount);
        Increment(TotalRentalLine."VAT Base Amount", RentalLine."VAT Base Amount");
        Increment(TotalRentalLine."VAT Difference", RentalLine."VAT Difference");
        Increment(TotalRentalLine."Amount Including VAT", RentalLine."Amount Including VAT");
        Increment(TotalRentalLine."Line Discount Amount", RentalLine."Line Discount Amount");
        Increment(TotalRentalLine."Inv. Discount Amount", RentalLine."Inv. Discount Amount");
        Increment(TotalRentalLine."Inv. Disc. Amount to Invoice", RentalLine."Inv. Disc. Amount to Invoice");
        Increment(TotalRentalLine."Prepmt. Line Amount", RentalLine."Prepmt. Line Amount");
        Increment(TotalRentalLine."Prepmt. Amt. Inv.", RentalLine."Prepmt. Amt. Inv.");
        Increment(TotalRentalLine."Prepmt Amt to Deduct", RentalLine."Prepmt Amt to Deduct");
        Increment(TotalRentalLine."Prepmt Amt Deducted", RentalLine."Prepmt Amt Deducted");
        Increment(TotalRentalLine."Prepayment VAT Difference", RentalLine."Prepayment VAT Difference");
        Increment(TotalRentalLine."Prepmt VAT Diff. to Deduct", RentalLine."Prepmt VAT Diff. to Deduct");
        Increment(TotalRentalLine."Prepmt VAT Diff. Deducted", RentalLine."Prepmt VAT Diff. Deducted");
        PostingEvents.OnAfterIncrAmount(TotalRentalLine, RentalLine, RentalHeader);
    end;

    local procedure Increment(var Number: Decimal; Number2: Decimal)
    begin
        Number := Number + Number2;
    end;

    procedure GetRentalLines(var RentalHeader: Record "TWE Rental Header"; var NewRentalLine: Record "TWE Rental Line"; QtyType: Option General,Invoicing,Shipping)
    begin
        GetRentalLines(RentalHeader, NewRentalLine, QtyType, true);
    end;

    internal procedure GetRentalLines(var RentalHeader: Record "TWE Rental Header"; var NewRentalLine: Record "TWE Rental Line"; QtyType: Option General,Invoicing,Shipping; IncludePrepayments: Boolean)
    var
        TotalAdjCostLCY: Decimal;
    begin
        FillTempLines(RentalHeader, TempRentalLineGlobal);
        if (QtyType = QtyType::Invoicing) and IncludePrepayments then
            CreatePrepaymentLines(RentalHeader, false);
        SumSalesLines2(RentalHeader, NewRentalLine, TempRentalLineGlobal, QtyType, true, false, TotalAdjCostLCY, IncludePrepayments);
    end;

    procedure GetRentalLinesTemp(var RentalHeader: Record "TWE Rental Header"; var NewRentalLine: Record "TWE Rental Line"; var OldRentalLine: Record "TWE Rental Line"; QtyType: Option General,Invoicing,Shipping)
    var
        TotalAdjCostLCY: Decimal;
    begin
        OldRentalLine.SetRentalHeader(RentalHeader);
        SumSalesLines2(RentalHeader, NewRentalLine, OldRentalLine, QtyType, true, false, TotalAdjCostLCY);
    end;

    procedure SumSalesLines(var NewRentalHeader: Record "TWE Rental Header"; QtyType: Option General,Invoicing,Shipping; var NewTotalRentalLine: Record "TWE Rental Line"; var NewTotalRentalLineLCY: Record "TWE Rental Line"; var VATAmount: Decimal; var VATAmountText: Text[30]; var ProfitLCY: Decimal; var ProfitPct: Decimal; var TotalAdjCostLCY: Decimal)
    var
        OldRentalLine: Record "TWE Rental Line";
    begin
        SumSalesLinesTemp(
          NewRentalHeader, OldRentalLine, QtyType, NewTotalRentalLine, NewTotalRentalLineLCY,
          VATAmount, VATAmountText, ProfitLCY, ProfitPct, TotalAdjCostLCY);
    end;

    procedure SumSalesLinesTemp(var RentalHeader: Record "TWE Rental Header"; var OldRentalLine: Record "TWE Rental Line"; QtyType: Option General,Invoicing,Shipping; var NewTotalRentalLine: Record "TWE Rental Line"; var NewTotalRentalLineLCY: Record "TWE Rental Line"; var VATAmount: Decimal; var VATAmountText: Text[30]; var ProfitLCY: Decimal; var ProfitPct: Decimal; var TotalAdjCostLCY: Decimal)
    begin
        SumSalesLinesTemp(RentalHeader, OldRentalLine, QtyType, NewTotalRentalLine, NewTotalRentalLineLCY, VATAmount, VATAmountText, ProfitLCY, ProfitPct, TotalAdjCostLCY, true);
    end;

    procedure SumSalesLinesTemp(var RentalHeader: Record "TWE Rental Header"; var OldRentalLine: Record "TWE Rental Line"; QtyType: Option General,Invoicing,Shipping; var NewTotalRentalLine: Record "TWE Rental Line"; var NewTotalRentalLineLCY: Record "TWE Rental Line"; var VATAmount: Decimal; var VATAmountText: Text[30]; var ProfitLCY: Decimal; var ProfitPct: Decimal; var TotalAdjCostLCY: Decimal; IncludePrepayments: Boolean)
    var
        RentalLine: Record "TWE Rental Line";
    begin

        SumSalesLines2(RentalHeader, RentalLine, OldRentalLine, QtyType, false, true, TotalAdjCostLCY, IncludePrepayments);
        ProfitLCY := TotalRentalLineLCY.Amount - TotalRentalLineLCY."Unit Cost (LCY)";
        if TotalRentalLineLCY.Amount = 0 then
            ProfitPct := 0
        else
            ProfitPct := Round(ProfitLCY / TotalRentalLineLCY.Amount * 100, 0.1);
        VATAmount := TotalRentalLine."Amount Including VAT" - TotalRentalLine.Amount;
        if TotalRentalLine."VAT %" = 0 then
            VATAmountText := VATAmountTxt
        else
            VATAmountText := StrSubstNo(VATRateTxt, TotalRentalLine."VAT %");
        NewTotalRentalLine := TotalRentalLine;
        NewTotalRentalLineLCY := TotalRentalLineLCY;

    end;

    local procedure SumSalesLines2(RentalHeader: Record "TWE Rental Header"; var NewRentalLine: Record "TWE Rental Line"; var OldRentalLine: Record "TWE Rental Line"; QtyType: Option General,Invoicing,Shipping; InsertSalesLine: Boolean; CalcAdCostLCY: Boolean; var TotalAdjCostLCY: Decimal)
    begin
        SumSalesLines2(RentalHeader, NewRentalLine, OldRentalLine, QtyType, InsertSalesLine, CalcAdCostLCY, TotalAdjCostLCY, true);
    end;

    local procedure SumSalesLines2(RentalHeader: Record "TWE Rental Header"; var NewRentalLine: Record "TWE Rental Line"; var OldRentalLine: Record "TWE Rental Line"; QtyType: Option General,Invoicing,Shipping; InsertSalesLine: Boolean; CalcAdCostLCY: Boolean; var TotalAdjCostLCY: Decimal; IncludePrepayments: Boolean)
    var
        RentalLine: Record "TWE Rental Line";
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        TempVATAmountLineRemainder: Record "VAT Amount Line" temporary;
        SalesLineQty: Decimal;
        AdjCostLCY: Decimal;
        BiggestLineNo: Integer;
        IsHandled: Boolean;
    begin
        TotalAdjCostLCY := 0;
        TempVATAmountLineRemainder.DeleteAll();
        OldRentalLine.CalcVATAmountLines(QtyType, RentalHeader, OldRentalLine, TempVATAmountLine, IncludePrepayments);
        GetGLSetup();
        GetSalesSetup();
        GetCurrency(RentalHeader."Currency Code");
        OldRentalLine.SetRange("Document Type", RentalHeader."Document Type");
        OldRentalLine.SetRange("Document No.", RentalHeader."No.");
        PostingEvents.OnSumSalesLines2SetFilter(OldRentalLine, RentalHeader, InsertSalesLine);
        RoundingLineInserted := false;
        if OldRentalLine.FindSet() then
            repeat
                if not RoundingLineInserted then
                    RentalLine := OldRentalLine;
                case QtyType of
                    QtyType::General:
                        SalesLineQty := RentalLine.Quantity;
                    QtyType::Invoicing:
                        SalesLineQty := RentalLine."Qty. to Invoice";
                    QtyType::Shipping:
                        begin
                            if not RentalHeader.IsCreditDocType then
                                SalesLineQty := RentalLine."Qty. to Ship";
                        end;
                end;
                IsHandled := false;
                PostingEvents.OnSumSalesLines2OnBeforeDivideAmount(OldRentalLine, IsHandled);
                if not IsHandled then
                    DivideAmount(RentalHeader, RentalLine, QtyType, SalesLineQty, TempVATAmountLine, TempVATAmountLineRemainder, IncludePrepayments);
                RentalLine.Quantity := SalesLineQty;
                if SalesLineQty <> 0 then begin
                    if (RentalLine.Amount <> 0) and not RoundingLineInserted then
                        if TotalRentalLine.Amount = 0 then
                            TotalRentalLine."VAT %" := RentalLine."VAT %"
                        else
                            if TotalRentalLine."VAT %" <> RentalLine."VAT %" then
                                TotalRentalLine."VAT %" := 0;
                    RoundAmount(RentalHeader, RentalLine, SalesLineQty);

                    if (QtyType in [QtyType::General, QtyType::Invoicing]) and
                      not InsertSalesLine and CalcAdCostLCY
                   then begin
                        TotalAdjCostLCY := TotalAdjCostLCY + GetRentalLineAdjCostLCY(RentalLine, QtyType, AdjCostLCY);
                    end;

                    RentalLine := xRentalLine;
                end;
                if InsertSalesLine then begin
                    NewRentalLine := RentalLine;
                    NewRentalLine.Insert();
                end;
                if RoundingLineInserted then
                    LastLineRetrieved := true
                else begin
                    BiggestLineNo := MAX(BiggestLineNo, OldRentalLine."Line No.");
                    LastLineRetrieved := OldRentalLine.Next() = 0;
                    if LastLineRetrieved and RentalSetup."Invoice Rounding" then
                        InvoiceRounding(RentalHeader, RentalLine, true, BiggestLineNo);
                end;
            until LastLineRetrieved;
    end;

    local procedure GetRentalLineAdjCostLCY(RentalLine2: Record "TWE Rental Line"; QtyType: Option General,Invoicing,Shipping; AdjCostLCY: Decimal): Decimal
    begin
        if RentalLine2."Document Type" in [RentalLine2."Document Type"::Contract, RentalLine2."Document Type"::Invoice] then
            AdjCostLCY := -AdjCostLCY;

        case true of
            RentalLine2."Shipment No." <> '', RentalLine2."Return Receipt No." <> '':
                exit(AdjCostLCY);
            QtyType = QtyType::General:
                exit(Round(RentalLine2."Outstanding Quantity" * RentalLine2."Unit Cost (LCY)") + AdjCostLCY);
            RentalLine2."Document Type" in [RentalLine2."Document Type"::Contract, RentalLine2."Document Type"::Invoice]:
                begin
                    if RentalLine2."Qty. to Invoice" > RentalLine2."Qty. to Ship" then
                        exit(Round(RentalLine2."Qty. to Ship" * RentalLine2."Unit Cost (LCY)") + AdjCostLCY);
                    exit(Round(RentalLine2."Qty. to Invoice" * RentalLine2."Unit Cost (LCY)"));
                end;
            RentalLine2.IsCreditDocType:
                begin
                    exit(Round(RentalLine2."Qty. to Invoice" * RentalLine2."Unit Cost (LCY)"));
                end;
        end;
    end;

    local procedure RunGenJnlPostLine(var GenJnlLine: Record "Gen. Journal Line"): Integer
    begin
        exit(GenJnlPostLine.RunWithCheck(GenJnlLine));
    end;

    local procedure DeleteItemChargeAssgnt(RentalHeader: Record "TWE Rental Header")
    var
        ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)";
    begin
        ItemChargeAssgntSales.SetRange("Document Type", RentalHeader."Document Type");
        ItemChargeAssgntSales.SetRange("Document No.", RentalHeader."No.");
        if not ItemChargeAssgntSales.IsEmpty() then
            ItemChargeAssgntSales.DeleteAll();
    end;

    local procedure UpdateItemChargeAssgnt()
    var
        ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)";
    begin
        ClearItemChargeAssgntFilter();
        TempItemChargeAssgntSales.MarkedOnly(true);
        if TempItemChargeAssgntSales.FindSet() then
            repeat
                ItemChargeAssgntSales.Get(TempItemChargeAssgntSales."Document Type", TempItemChargeAssgntSales."Document No.", TempItemChargeAssgntSales."Document Line No.", TempItemChargeAssgntSales."Line No.");
                ItemChargeAssgntSales."Qty. Assigned" :=
                  ItemChargeAssgntSales."Qty. Assigned" + TempItemChargeAssgntSales."Qty. to Assign";
                ItemChargeAssgntSales."Qty. to Assign" := 0;
                ItemChargeAssgntSales."Amount to Assign" := 0;
                ItemChargeAssgntSales.Modify();
            until TempItemChargeAssgntSales.Next() = 0;
    end;

    local procedure UpdateSalesOrderChargeAssgnt(RentalOrderInvLine: Record "TWE Rental Line"; RentalOrderLine: Record "TWE Rental Line")
    var
        RentalOrderLine2: Record "TWE Rental Line";
        RentalOrderInvLine2: Record "TWE Rental Line";
        RentalShptLine: Record "TWE Rental Shipment Line";
        ReturnRcptLine: Record "Return Receipt Line";
    begin
        ClearItemChargeAssgntFilter;
        TempItemChargeAssgntSales.SetRange("Document Type", RentalOrderInvLine."Document Type");
        TempItemChargeAssgntSales.SetRange("Document No.", RentalOrderInvLine."Document No.");
        TempItemChargeAssgntSales.SetRange("Document Line No.", RentalOrderInvLine."Line No.");
        TempItemChargeAssgntSales.MarkedOnly(true);
        if TempItemChargeAssgntSales.FindSet() then
            repeat
                if TempItemChargeAssgntSales."Applies-to Doc. Type" = RentalOrderInvLine."Document Type" then begin
                    RentalOrderInvLine2.Get(
                      TempItemChargeAssgntSales."Applies-to Doc. Type",
                      TempItemChargeAssgntSales."Applies-to Doc. No.",
                      TempItemChargeAssgntSales."Applies-to Doc. Line No.");
                    if RentalOrderLine."Document Type" = RentalOrderLine."Document Type"::Contract then begin
                        if not
                           RentalShptLine.Get(RentalOrderInvLine2."Shipment No.", RentalOrderInvLine2."Shipment Line No.")
                        then
                            Error(ShipmentLinesDeletedErr);
                        RentalOrderLine2.Get(
                          RentalOrderLine2."Document Type"::Contract,
                          RentalShptLine."Order No.", RentalShptLine."Order Line No.");
                        /*  end else begin
                             if not
                                ReturnRcptLine.Get(SalesOrderInvLine2."Return Receipt No.", SalesOrderInvLine2."Return Receipt Line No.")
                             then
                                 Error(ReturnReceiptLinesDeletedErr);
                             SalesOrderLine2.Get(
                               SalesOrderLine2."Document Type"::"Return Order",
                               ReturnRcptLine."Return Order No.", ReturnRcptLine."Return Order Line No."); */
                    end;
                    UpdateSalesChargeAssgntLines(
                      RentalOrderLine,
                      RentalOrderLine2."Document Type",
                      RentalOrderLine2."Document No.",
                      RentalOrderLine2."Line No.",
                      TempItemChargeAssgntSales."Qty. to Assign");
                end else
                    UpdateSalesChargeAssgntLines(
                      RentalOrderLine,
                      TempItemChargeAssgntSales."Applies-to Doc. Type",
                      TempItemChargeAssgntSales."Applies-to Doc. No.",
                      TempItemChargeAssgntSales."Applies-to Doc. Line No.",
                      TempItemChargeAssgntSales."Qty. to Assign");
            until TempItemChargeAssgntSales.Next() = 0;
    end;

    local procedure UpdateSalesChargeAssgntLines(RentalOrderLine: Record "TWE Rental Line"; ApplToDocType: Enum "Sales Applies-to Document Type"; ApplToDocNo: Code[20];
                                                                                                         ApplToDocLineNo: Integer;
                                                                                                         QtyToAssign: Decimal)
    var
        ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)";
        ItemChargeAssgntSales2: Record "Item Charge Assignment (Sales)";
        LastLineNo: Integer;
        TotalToAssign: Decimal;
    begin
        ItemChargeAssgntSales.SetRange("Document Type", RentalOrderLine."Document Type");
        ItemChargeAssgntSales.SetRange("Document No.", RentalOrderLine."Document No.");
        ItemChargeAssgntSales.SetRange("Document Line No.", RentalOrderLine."Line No.");
        ItemChargeAssgntSales.SetRange("Applies-to Doc. Type", ApplToDocType);
        ItemChargeAssgntSales.SetRange("Applies-to Doc. No.", ApplToDocNo);
        ItemChargeAssgntSales.SetRange("Applies-to Doc. Line No.", ApplToDocLineNo);
        if ItemChargeAssgntSales.FindFirst() then begin
            ItemChargeAssgntSales."Qty. Assigned" := ItemChargeAssgntSales."Qty. Assigned" + QtyToAssign;
            ItemChargeAssgntSales."Qty. to Assign" := 0;
            ItemChargeAssgntSales."Amount to Assign" := 0;
            ItemChargeAssgntSales.Modify();
        end else begin
            ItemChargeAssgntSales.SetRange("Applies-to Doc. Type");
            ItemChargeAssgntSales.SetRange("Applies-to Doc. No.");
            ItemChargeAssgntSales.SetRange("Applies-to Doc. Line No.");
            ItemChargeAssgntSales.CalcSums("Qty. to Assign");

            // calculate total qty. to assign of the invoice charge line
            ItemChargeAssgntSales2.SetRange("Document Type", TempItemChargeAssgntSales."Document Type");
            ItemChargeAssgntSales2.SetRange("Document No.", TempItemChargeAssgntSales."Document No.");
            ItemChargeAssgntSales2.SetRange("Document Line No.", TempItemChargeAssgntSales."Document Line No.");
            ItemChargeAssgntSales2.CalcSums("Qty. to Assign");

            TotalToAssign := ItemChargeAssgntSales."Qty. to Assign" +
              ItemChargeAssgntSales2."Qty. to Assign";

            if ItemChargeAssgntSales.FindLast() then
                LastLineNo := ItemChargeAssgntSales."Line No.";

            if RentalOrderLine.Quantity < TotalToAssign then
                repeat
                    TotalToAssign := TotalToAssign - ItemChargeAssgntSales."Qty. to Assign";
                    ItemChargeAssgntSales."Qty. to Assign" := 0;
                    ItemChargeAssgntSales."Amount to Assign" := 0;
                    ItemChargeAssgntSales.Modify();
                until (ItemChargeAssgntSales.Next(-1) = 0) or
                      (TotalToAssign = RentalOrderLine.Quantity);

            InsertAssocOrderCharge(
              RentalOrderLine, ApplToDocType, ApplToDocNo, ApplToDocLineNo, LastLineNo,
              TempItemChargeAssgntSales."Applies-to Doc. Line Amount");
        end;
    end;

    local procedure InsertAssocOrderCharge(RentalOrderLine: Record "TWE Rental Line"; ApplToDocType: Enum "Sales Applies-to Document Type"; ApplToDocNo: Code[20];
                                                                                                   ApplToDocLineNo: Integer;
                                                                                                   LastLineNo: Integer;
                                                                                                   ApplToDocLineAmt: Decimal)
    var
        NewItemChargeAssgntSales: Record "Item Charge Assignment (Sales)";
    begin

        NewItemChargeAssgntSales.Init;
        NewItemChargeAssgntSales."Document Type" := RentalOrderLine."Document Type";
        NewItemChargeAssgntSales."Document No." := RentalOrderLine."Document No.";
        NewItemChargeAssgntSales."Document Line No." := RentalOrderLine."Line No.";
        NewItemChargeAssgntSales."Line No." := LastLineNo + 10000;
        NewItemChargeAssgntSales."Item Charge No." := TempItemChargeAssgntSales."Item Charge No.";
        NewItemChargeAssgntSales."Item No." := TempItemChargeAssgntSales."Item No.";
        NewItemChargeAssgntSales."Qty. Assigned" := TempItemChargeAssgntSales."Qty. to Assign";
        NewItemChargeAssgntSales."Qty. to Assign" := 0;
        NewItemChargeAssgntSales."Amount to Assign" := 0;
        NewItemChargeAssgntSales.Description := TempItemChargeAssgntSales.Description;
        NewItemChargeAssgntSales."Unit Cost" := TempItemChargeAssgntSales."Unit Cost";
        NewItemChargeAssgntSales."Applies-to Doc. Type" := ApplToDocType;
        NewItemChargeAssgntSales."Applies-to Doc. No." := ApplToDocNo;
        NewItemChargeAssgntSales."Applies-to Doc. Line No." := ApplToDocLineNo;
        NewItemChargeAssgntSales."Applies-to Doc. Line Amount" := ApplToDocLineAmt;
        NewItemChargeAssgntSales.Insert;
    end;

    /*     local procedure CopyAndCheckItemCharge(RentalHeader: Record "TWE Rental Header")
        var
            TempRentalLine: Record "TWE Rental Line" temporary;
            RentalLine: Record "TWE Rental Line";
            InvoiceEverything: Boolean;
            AssignError: Boolean;
            QtyNeeded: Decimal;
        begin
            TempItemChargeAssgntSales.Reset();
            TempItemChargeAssgntSales.DeleteAll();

            // Check for max qty posting
            with TempRentalLine do begin
                ResetTempLines(TempRentalLine);
                SetRange(Type, Type::"Charge (Item)");
                if IsEmpty() then
                    exit;

                ItemChargeAssgntSales.Reset();
                ItemChargeAssgntSales.SetRange("Document Type", "Document Type");
                ItemChargeAssgntSales.SetRange("Document No.", "Document No.");
                ItemChargeAssgntSales.SetFilter("Qty. to Assign", '<>0');
                if ItemChargeAssgntSales.FindSet() then
                    repeat
                        TempItemChargeAssgntSales.Init();
                        TempItemChargeAssgntSales := ItemChargeAssgntSales;
                        TempItemChargeAssgntSales.Insert();
                    until ItemChargeAssgntSales.Next() = 0;

                SetFilter("Qty. to Invoice", '<>0');
                if FindSet() then
                    repeat
                        PostingEvents.OnCopyAndCheckItemChargeOnBeforeLoop(TempRentalLine, RentalHeader);
                        TestField("Job No.", '');
                        TestField("Job Contract Entry No.", 0);
                        if ("Qty. to Ship" + "Return Qty. to Receive" <> 0) and
                           ((RentalHeader.Ship or RentalHeader.Receive) or
                            (Abs("Qty. to Invoice") >
                             Abs("Qty. Shipped Not Invoiced" + "Qty. to Ship") +
                             Abs("Ret. Qty. Rcd. Not Invd.(Base)" + "Return Qty. to Receive")))
                        then
                            TestField("Line Amount");

                        if not RentalHeader.Ship then
                            "Qty. to Ship" := 0;
                        if not RentalHeader.Receive then
                            "Return Qty. to Receive" := 0;
                        if Abs("Qty. to Invoice") >
                           Abs("Quantity Shipped" + "Qty. to Ship" + "Return Qty. Received" + "Return Qty. to Receive" - "Quantity Invoiced")
                        then
                            "Qty. to Invoice" :=
                              "Quantity Shipped" + "Qty. to Ship" + "Return Qty. Received" + "Return Qty. to Receive" - "Quantity Invoiced";

                        CalcFields("Qty. to Assign", "Qty. Assigned");
                        if Abs("Qty. to Assign" + "Qty. Assigned") > Abs("Qty. to Invoice" + "Quantity Invoiced") then
                            Error(CannotAssignMoreErr,
                              "Qty. to Invoice" + "Quantity Invoiced" - "Qty. Assigned",
                              FieldCaption("Document Type"), "Document Type",
                              FieldCaption("Document No."), "Document No.",
                              FieldCaption("Line No."), "Line No.");
                        if Quantity = "Qty. to Invoice" + "Quantity Invoiced" then begin
                            if "Qty. to Assign" <> 0 then
                                if Quantity = "Quantity Invoiced" then begin
                                    TempItemChargeAssgntSales.SetRange("Document Line No.", "Line No.");
                                    TempItemChargeAssgntSales.SetRange("Applies-to Doc. Type", "Document Type");
                                    if TempItemChargeAssgntSales.FindSet() then
                                        repeat
                                            RentalLine.Get(
                                              TempItemChargeAssgntSales."Applies-to Doc. Type",
                                              TempItemChargeAssgntSales."Applies-to Doc. No.",
                                              TempItemChargeAssgntSales."Applies-to Doc. Line No.");
                                            if RentalLine.Quantity = RentalLine."Quantity Invoiced" then
                                                Error(CannotAssignInvoicedErr, RentalLine.TableCaption,
                                                  RentalLine.FieldCaption("Document Type"), RentalLine."Document Type",
                                                  RentalLine.FieldCaption("Document No."), RentalLine."Document No.",
                                                  RentalLine.FieldCaption("Line No."), RentalLine."Line No.");
                                        until TempItemChargeAssgntSales.Next() = 0;
                                end;
                            if Quantity <> "Qty. to Assign" + "Qty. Assigned" then
                                AssignError := true;
                        end;

                        if ("Qty. to Assign" + "Qty. Assigned") < ("Qty. to Invoice" + "Quantity Invoiced") then
                            Error(MustAssignItemChargeErr, "No.");

                        // check if all ILEs exist
                        QtyNeeded := "Qty. to Assign";
                        TempItemChargeAssgntSales.SetRange("Document Line No.", "Line No.");
                        if TempItemChargeAssgntSales.FindSet() then
                            repeat
                                if (TempItemChargeAssgntSales."Applies-to Doc. Type" <> "Document Type") or
                                   (TempItemChargeAssgntSales."Applies-to Doc. No." <> "Document No.")
                                then
                                    QtyNeeded := QtyNeeded - TempItemChargeAssgntSales."Qty. to Assign"
                                else begin
                                    RentalLine.Get(
                                      TempItemChargeAssgntSales."Applies-to Doc. Type",
                                      TempItemChargeAssgntSales."Applies-to Doc. No.",
                                      TempItemChargeAssgntSales."Applies-to Doc. Line No.");
                                    if ItemLedgerEntryExist(SalesLine, RentalHeader.Ship or RentalHeader.Receive) then
                                        QtyNeeded := QtyNeeded - TempItemChargeAssgntSales."Qty. to Assign";
                                end;
                            until TempItemChargeAssgntSales.Next() = 0;

                        if QtyNeeded <> 0 then
                            Error(CannotInvoiceItemChargeErr, "No.");
                    until Next() = 0;

                // Check saleslines
                if AssignError then
                    if RentalHeader."Document Type" in
                       [RentalHeader."Document Type"::Invoice, RentalHeader."Document Type"::"Credit Memo"]
                    then
                        InvoiceEverything := true
                    else begin
                        Reset;
                        SetFilter(Type, '%1|%2', Type::Item, Type::"Charge (Item)");
                        if FindSet() then
                            repeat
                                if RentalHeader.Ship or RentalHeader.Receive then
                                    InvoiceEverything :=
                                      Quantity = "Qty. to Invoice" + "Quantity Invoiced"
                                else
                                    InvoiceEverything :=
                                      (Quantity = "Qty. to Invoice" + "Quantity Invoiced") and
                                      ("Qty. to Invoice" =
                                       "Qty. Shipped Not Invoiced" + "Ret. Qty. Rcd. Not Invd.(Base)");
                            until (Next() = 0) or (not InvoiceEverything);
                    end;

                if InvoiceEverything and AssignError then
                    Error(MustAssignErr);
            end;
        end;
     */
    local procedure ClearItemChargeAssgntFilter()
    begin
        TempItemChargeAssgntSales.SetRange("Document Line No.");
        TempItemChargeAssgntSales.SetRange("Applies-to Doc. Type");
        TempItemChargeAssgntSales.SetRange("Applies-to Doc. No.");
        TempItemChargeAssgntSales.SetRange("Applies-to Doc. Line No.");
        TempItemChargeAssgntSales.MarkedOnly(false);
    end;

    local procedure GetItemChargeLine(RentalHeader: Record "TWE Rental Header"; var ItemChargeRentalLine: Record "TWE Rental Line")
    var
        RentalShptLine: Record "TWE Rental Shipment Line";
        ReturnReceiptLine: Record "Return Receipt Line";
        QtyShippedNotInvd: Decimal;
        QtyReceivedNotInvd: Decimal;
    begin
        if (ItemChargeRentalLine."Document Type" <> TempItemChargeAssgntSales."Document Type") or
           (ItemChargeRentalLine."Document No." <> TempItemChargeAssgntSales."Document No.") or
           (ItemChargeRentalLine."Line No." <> TempItemChargeAssgntSales."Document Line No.")
        then begin
            ItemChargeRentalLine.Get(TempItemChargeAssgntSales."Document Type", TempItemChargeAssgntSales."Document No.", TempItemChargeAssgntSales."Document Line No.");
            if not RentalHeader.Ship then
                ItemChargeRentalLine."Qty. to Ship" := 0;
            /*                 if not RentalHeader.Receive then
                                ItemChargeRentalLine."Return Qty. to Receive" := 0; */
            if ItemChargeRentalLine."Shipment No." <> '' then begin
                RentalShptLine.Get(ItemChargeRentalLine."Shipment No.", ItemChargeRentalLine."Shipment Line No.");
                QtyShippedNotInvd := TempItemChargeAssgntSales."Qty. to Assign" - TempItemChargeAssgntSales."Qty. Assigned";
            end else
                QtyShippedNotInvd := ItemChargeRentalLine."Quantity Shipped";
            if ItemChargeRentalLine."Return Receipt No." <> '' then begin
                ReturnReceiptLine.Get(ItemChargeRentalLine."Return Receipt No.", ItemChargeRentalLine."Return Receipt Line No.");
                QtyReceivedNotInvd := TempItemChargeAssgntSales."Qty. to Assign" - TempItemChargeAssgntSales."Qty. Assigned";
            end; /* else
                    QtyReceivedNotInvd := ItemChargeRentalLine."Return Qty. Received"; */
                 /*  if Abs(ItemChargeRentalLine."Qty. to Invoice") >
                     Abs(QtyShippedNotInvd + ItemChargeRentalLine."Qty. to Ship" +
                       QtyReceivedNotInvd + ItemChargeRentalLine."Return Qty. to Receive" -
                       ItemChargeRentalLine."Quantity Invoiced")
                  then
                      ItemChargeRentalLine."Qty. to Invoice" :=
                        QtyShippedNotInvd + ItemChargeRentalLine."Qty. to Ship" +
                        QtyReceivedNotInvd + ItemChargeRentalLine."Return Qty. to Receive" -
                        ItemChargeRentalLine."Quantity Invoiced"; */
        end;
    end;

    local procedure CalcQtyToInvoice(QtyToHandle: Decimal; QtyToInvoice: Decimal): Decimal
    begin
        if Abs(QtyToHandle) > Abs(QtyToInvoice) then
            exit(-QtyToHandle);

        exit(-QtyToInvoice);
    end;

    local procedure CheckWarehouse(var TempItemRentalLine: Record "TWE Rental Line" temporary)
    var
        WhseValidateSourceLine: Codeunit "Whse. Validate Source Line";
        ShowError: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        PostingEvents.OnBeforeCheckWarehouse(TempItemRentalLine, IsHandled);
        if IsHandled then
            exit;

        TempItemRentalLine.SetRange(Type, TempItemRentalLine.Type::"Rental Item");
        TempItemRentalLine.SetRange("Drop Shipment", false);
        if TempItemRentalLine.FindSet() then
            repeat
                GetLocation(TempItemRentalLine."Location Code");
                case TempItemRentalLine."Document Type" of
                    TempItemRentalLine."Document Type"::Contract:
                        if ((Location."Require Receive" or Location."Require Put-away") and (TempItemRentalLine.Quantity < 0)) or
                           ((Location."Require Shipment" or Location."Require Pick") and (TempItemRentalLine.Quantity >= 0))
                        then begin
                            if Location."Directed Put-away and Pick" then
                                ShowError := true
                            else
                                if WhseValidateSourceLine.WhseLinesExist(
                                     DATABASE::"Sales Line", TempItemRentalLine."Document Type".AsInteger(), TempItemRentalLine."Document No.", TempItemRentalLine."Line No.", 0, TempItemRentalLine.Quantity)
                                then
                                    ShowError := true;
                        end;
                    /* TempItemRentalLine."Document Type"::"Return Order":
                        if ((Location."Require Receive" or Location."Require Put-away") and (TempItemRentalLine.Quantity >= 0)) or
                           ((Location."Require Shipment" or Location."Require Pick") and (TempItemRentalLine.Quantity < 0))
                        then begin
                            if Location."Directed Put-away and Pick" then
                                ShowError := true
                            else
                                if WhseValidateSourceLine.WhseLinesExist(
                                     DATABASE::"TWE Rental Line", "Document Type".AsInteger(), TempItemRentalLine."Document No.", TempItemRentalLine."Line No.", 0, vTempItemRentalLine.Quantity)
                                then
                                    ShowError := true;
                        end; */
                    TempItemRentalLine."Document Type"::Invoice, TempItemRentalLine."Document Type"::"Credit Memo":
                        if Location."Directed Put-away and Pick" then
                            Location.TestField("Adjustment Bin Code");
                end;
                if ShowError then
                    Error(
                      WarehouseRequiredErr,
                      TempItemRentalLine.FieldCaption("Document Type"), TempItemRentalLine."Document Type",
                      TempItemRentalLine.FieldCaption("Document No."), TempItemRentalLine."Document No.",
                      TempItemRentalLine.FieldCaption("Line No."), TempItemRentalLine."Line No.");
            until TempItemRentalLine.Next() = 0;
    end;

    local procedure CreateWhseJnlLine(RentalItemJnlLine: Record "TWE Rental Item Journal Line"; RentalLine: Record "TWE Rental Line"; var TempWhseJnlLine: Record "Warehouse Journal Line" temporary)
    var
        WhseMgt: Codeunit "Whse. Management";
        WMSMgt: Codeunit "WMS Management";
    begin
        WMSMgt.CheckAdjmtBin(Location, RentalItemJnlLine.Quantity, true);
        //WMSMgt.CreateWhseJnlLine(RentalItemJnlLine, 0, TempWhseJnlLine, false);
        TempWhseJnlLine."Source Type" := DATABASE::"TWE Rental Line";
        TempWhseJnlLine."Source Subtype" := RentalLine."Document Type".AsInteger();
        TempWhseJnlLine."Source Code" := SrcCode;
        TempWhseJnlLine."Source Document" := WhseMgt.GetWhseJnlSourceDocument(TempWhseJnlLine."Source Type", TempWhseJnlLine."Source Subtype");
        TempWhseJnlLine."Source No." := RentalLine."Document No.";
        TempWhseJnlLine."Source Line No." := RentalLine."Line No.";
        case RentalLine."Document Type" of
            RentalLine."Document Type"::Contract:
                TempWhseJnlLine."Reference Document" :=
                  TempWhseJnlLine."Reference Document"::"Posted Shipment";
            RentalLine."Document Type"::Invoice:
                TempWhseJnlLine."Reference Document" :=
                  TempWhseJnlLine."Reference Document"::"Posted S. Inv.";
            RentalLine."Document Type"::"Credit Memo":
                TempWhseJnlLine."Reference Document" :=
                  TempWhseJnlLine."Reference Document"::"Posted S. Cr. Memo";
        /*    RentalLine."Document Type"::"Return Order":
               TempWhseJnlLine."Reference Document" :=
                 TempWhseJnlLine."Reference Document"::"Posted Rtrn. Shipment"; */
        end;
        TempWhseJnlLine."Reference No." := RentalItemJnlLine."Document No.";
    end;

    procedure WhseHandlingRequiredExternal(RentalLine: Record "TWE Rental Line"): Boolean
    begin
        exit(WhseHandlingRequired(RentalLine));
    end;

    local procedure WhseHandlingRequired(RentalLine: Record "TWE Rental Line") Required: Boolean
    var
        WhseSetup: Record "Warehouse Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        PostingEvents.OnBeforeWhseHandlingRequired(RentalLine, Required, IsHandled);
        if IsHandled then
            exit(Required);

        if (RentalLine.Type = RentalLine.Type::"Rental Item") and (not RentalLine."Drop Shipment") then begin
            if RentalLine."Location Code" = '' then begin
                WhseSetup.Get();
                /* if RentalLine."Document Type" = RentalLine."Document Type"::"Return Order" then
                    exit(WhseSetup."Require Receive"); */

                exit(WhseSetup."Require Shipment");
            end;

            GetLocation(RentalLine."Location Code");
            /*   if RentalLine."Document Type" = RentalLine."Document Type"::"Return Order" then
                  exit(Location."Require Receive"); */

            exit(Location."Require Shipment");
        end;
        exit(false);
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if LocationCode = '' then
            Location.GetLocationSetup(LocationCode, Location)
        else
            if Location.Code <> LocationCode then
                Location.Get(LocationCode);
    end;

    local procedure InsertShptEntryRelation(var RentalShptLine: Record "TWE Rental Shipment Line"): Integer
    var
        ItemEntryRelation: Record "Item Entry Relation";
    begin
        TempHandlingSpecification.CopySpecification(TempTrackingSpecificationInv);
        TempHandlingSpecification.CopySpecification(TempATOTrackingSpecification);
        TempHandlingSpecification.Reset();
        if TempHandlingSpecification.FindSet() then begin
            repeat
                ItemEntryRelation.InitFromTrackingSpec(TempHandlingSpecification);
                ItemEntryRelation.TransferFieldsRentalShptLine(RentalShptLine);
                ItemEntryRelation.Insert();
            until TempHandlingSpecification.Next() = 0;
            TempHandlingSpecification.DeleteAll();
            exit(0);
        end;
        exit(ItemLedgShptEntryNo);
    end;

    local procedure InsertReturnEntryRelation(var ReturnRcptLine: Record "Return Receipt Line"): Integer
    var
        ItemEntryRelation: Record "Item Entry Relation";
    begin
        TempHandlingSpecification.CopySpecification(TempTrackingSpecificationInv);
        TempHandlingSpecification.CopySpecification(TempATOTrackingSpecification);
        TempHandlingSpecification.Reset();
        if TempHandlingSpecification.FindSet() then begin
            repeat
                ItemEntryRelation.InitFromTrackingSpec(TempHandlingSpecification);
                ItemEntryRelation.TransferFieldsReturnRcptLine(ReturnRcptLine);
                ItemEntryRelation.Insert();
            until TempHandlingSpecification.Next() = 0;
            TempHandlingSpecification.DeleteAll();
            exit(0);
        end;
        exit(ItemLedgShptEntryNo);
    end;

    local procedure CheckTrackingSpecification(RentalHeader: Record "TWE Rental Header"; var TempItemRentalLine: Record "TWE Rental Line" temporary)
    var
        ReservationEntry: Record "Reservation Entry";
        ItemTrackingCode: Record "Item Tracking Code";
        ItemTrackingSetup: Record "Item Tracking Setup";
        RentalItemJnlLine: Record "TWE Rental Item Journal Line";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        ItemTrackingManagement: Codeunit "Item Tracking Management";
        ErrorFieldCaption: Text[250];
        SignFactor: Integer;
        SalesLineQtyToHandle: Decimal;
        TrackingQtyToHandle: Decimal;
        Inbound: Boolean;
        CheckSalesLine: Boolean;
    begin
        // if a SalesLine is posted with ItemTracking then tracked quantity must be equal to posted quantity
        if not (RentalHeader."Document Type" in
                [RentalHeader."Document Type"::Contract])
        then
            exit;

        TrackingQtyToHandle := 0;

        TempItemRentalLine.SetRange(Type, TempItemRentalLine.Type::"Rental Item");
        if RentalHeader.Ship then begin
            TempItemRentalLine.SetFilter("Quantity Shipped", '<>%1', 0);
            ErrorFieldCaption := TempItemRentalLine.FieldCaption("Qty. to Ship");
            /* end else begin
                TempItemRentalLine.SetFilter("Return Qty. Received", '<>%1', 0);
                ErrorFieldCaption := TempItemRentalLine.FieldCaption("Return Qty. to Receive"); */
        end;

        if TempItemRentalLine.FindSet() then begin
            ReservationEntry."Source Type" := DATABASE::"Sales Line";
            ReservationEntry."Source Subtype" := RentalHeader."Document Type".AsInteger();
            SignFactor := CreateReservEntry.SignFactor(ReservationEntry);
            repeat
                // Only Item where no SerialNo or LotNo is required
                TempItemRentalLine.GetMainRentalItem(MainRentalItem);
                if MainRentalItem."Item Tracking Code" <> '' then begin
                    Inbound := (TempItemRentalLine.Quantity * SignFactor) > 0;
                    ItemTrackingCode.Code := MainRentalItem."Item Tracking Code";
                    ItemTrackingManagement.GetItemTrackingSetup(
                        ItemTrackingCode, RentalItemJnlLine."Entry Type"::Sale.AsInteger(), Inbound, ItemTrackingSetup);
                    CheckSalesLine := not ItemTrackingSetup.TrackingRequired();
                    if CheckSalesLine then
                        CheckSalesLine := CheckTrackingExists(TempItemRentalLine);
                end else
                    CheckSalesLine := false;

                TrackingQtyToHandle := 0;

                if CheckSalesLine then begin
                    TrackingQtyToHandle := GetTrackingQuantities(TempItemRentalLine) * SignFactor;
                    if RentalHeader.Ship then
                        SalesLineQtyToHandle := TempItemRentalLine."Qty. to Ship (Base)";/* 
                        else
                            SalesLineQtyToHandle := TempItemRentalLine."Return Qty. to Receive (Base)"; */
                    if TrackingQtyToHandle <> SalesLineQtyToHandle then
                        Error(ItemTrackQuantityMismatchErr, ErrorFieldCaption);
                end;
            until TempItemRentalLine.Next() = 0;
        end;
        if RentalHeader.Ship then
            TempItemRentalLine.SetRange("Quantity Shipped");/* 
            else
                TempItemRentalLine.SetRange("Return Qty. Received"); */
    end;

    local procedure CheckTrackingExists(RentalLine: Record "TWE Rental Line"): Boolean
    begin
        exit(
          ItemTrackingMgt.ItemTrackingExistsOnDocumentLine(
            DATABASE::"Sales Line", RentalLine."Document Type".AsInteger(), RentalLine."Document No.", RentalLine."Line No."));
    end;

    local procedure GetTrackingQuantities(RentalLine: Record "TWE Rental Line"): Decimal
    begin
        exit(
          ItemTrackingMgt.CalcQtyToHandleForTrackedQtyOnDocumentLine(
            DATABASE::"Sales Line", RentalLine."Document Type".AsInteger(), RentalLine."Document No.", RentalLine."Line No."));
    end;

    local procedure SaveInvoiceSpecification(var TempInvoicingSpecification: Record "Tracking Specification" temporary)
    begin
        TempInvoicingSpecification.Reset();
        if TempInvoicingSpecification.FindSet() then begin
            repeat
                TempInvoicingSpecification."Quantity Invoiced (Base)" += TempInvoicingSpecification."Quantity actual Handled (Base)";
                TempInvoicingSpecification."Quantity actual Handled (Base)" := 0;
                TempTrackingSpecification := TempInvoicingSpecification;
                TempTrackingSpecification."Buffer Status" := TempTrackingSpecification."Buffer Status"::Modify;
                if not TempTrackingSpecification.Insert() then begin
                    TempTrackingSpecification.Get(TempInvoicingSpecification."Entry No.");
                    TempTrackingSpecification."Qty. to Invoice (Base)" += TempInvoicingSpecification."Qty. to Invoice (Base)";
                    TempTrackingSpecification."Quantity Invoiced (Base)" += TempInvoicingSpecification."Qty. to Invoice (Base)";
                    TempTrackingSpecification."Qty. to Invoice" += TempInvoicingSpecification."Qty. to Invoice";
                    TempTrackingSpecification.Modify();
                end;
                PostingEvents.OnSaveInvoiceSpecificationOnAfterUpdateTempTrackingSpecification(TempTrackingSpecification, TempInvoicingSpecification);
            until TempInvoicingSpecification.Next() = 0;
            TempInvoicingSpecification.DeleteAll();
        end;
    end;

    local procedure InsertTrackingSpecification(RentalHeader: Record "TWE Rental Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        PostingEvents.OnBeforeInsertTrackingSpecification(RentalHeader, TempTrackingSpecification, IsHandled);
        if IsHandled then
            exit;

        TempTrackingSpecification.Reset();
        if not TempTrackingSpecification.IsEmpty() then //begin
            TempTrackingSpecification.InsertSpecification;
        //ReserveRentalLine.UpdateItemTrackingAfterPosting(RentalHeader);
        //end;
    end;

    local procedure InsertValueEntryRelation()
    var
        ValueEntryRelation: Record "Value Entry Relation";
    begin
        TempValueEntryRelation.Reset();
        if TempValueEntryRelation.FindSet() then begin
            repeat
                ValueEntryRelation := TempValueEntryRelation;
                ValueEntryRelation.Insert();
            until TempValueEntryRelation.Next() = 0;
            TempValueEntryRelation.DeleteAll();
        end;
    end;

    local procedure SetPaymentInstructions(RentalHeader: Record "TWE Rental Header")
    var
        O365PaymentInstructions: Record "O365 Payment Instructions";
        OutStream: OutStream;
    begin
        if not O365PaymentInstructions.Get(RentalHeader."Payment Instructions Id") then
            exit;

        RentalInvHeader."Payment Instructions".CreateOutStream(OutStream, TEXTENCODING::Windows);
        OutStream.WriteText(O365PaymentInstructions.GetPaymentInstructionsInCurrentLanguage);

        RentalInvHeader."Payment Instructions Name" := O365PaymentInstructions.GetNameInCurrentLanguage;
    end;

    local procedure PostItemCharge(RentalHeader: Record "TWE Rental Header"; var RentalLine: Record "TWE Rental Line"; ItemLedgEntryNo: Integer; QuantityBase: Decimal; AmountToAssign: Decimal; QtyToAssign: Decimal)
    var
        DummyTrackingSpecification: Record "Tracking Specification";
        RentalLineToPost: Record "TWE Rental Line";
        CurrExchRate: Record "Currency Exchange Rate";
    begin
        PostingEvents.OnBeforePostItemCharge(RentalHeader, RentalLine, TempItemChargeAssgntSales, ItemLedgEntryNo);

        RentalLineToPost := RentalLine;
        RentalLineToPost."No." := TempItemChargeAssgntSales."Item No.";
        RentalLineToPost."Appl.-to Item Entry" := ItemLedgEntryNo;
        if not (TempItemChargeAssgntSales."Document Type" in [TempItemChargeAssgntSales."Document Type"::"Return Order", TempItemChargeAssgntSales."Document Type"::"Credit Memo"]) then
            RentalLineToPost.Amount := -AmountToAssign
        else
            RentalLineToPost.Amount := AmountToAssign;

        if RentalLineToPost."Currency Code" <> '' then
            RentalLineToPost."Unit Cost" := Round(
                RentalLineToPost.Amount / QuantityBase, Currency."Unit-Amount Rounding Precision")
        else
            RentalLineToPost."Unit Cost" := Round(
                RentalLineToPost.Amount / QuantityBase, GLSetup."Unit-Amount Rounding Precision");
        TotalChargeAmt := TotalChargeAmt + RentalLineToPost.Amount;

        if RentalHeader."Currency Code" <> '' then
            RentalLineToPost.Amount :=
              CurrExchRate.ExchangeAmtFCYToLCY(
                UseDate, RentalHeader."Currency Code", TotalChargeAmt, RentalHeader."Currency Factor");
        RentalLineToPost."Inv. Discount Amount" := Round(
            RentalLine."Inv. Discount Amount" / RentalLine.Quantity * QtyToAssign,
            GLSetup."Amount Rounding Precision");
        RentalLineToPost."Line Discount Amount" := Round(
            RentalLine."Line Discount Amount" / RentalLine.Quantity * QtyToAssign,
            GLSetup."Amount Rounding Precision");
        RentalLineToPost."Line Amount" := Round(
            RentalLine."Line Amount" / RentalLine.Quantity * QtyToAssign,
            GLSetup."Amount Rounding Precision");
        RentalLine."Inv. Discount Amount" := RentalLine."Inv. Discount Amount" - RentalLineToPost."Inv. Discount Amount";
        RentalLine."Line Discount Amount" := RentalLine."Line Discount Amount" - RentalLineToPost."Line Discount Amount";
        RentalLine."Line Amount" := RentalLine."Line Amount" - RentalLineToPost."Line Amount";
        RentalLine.Quantity := RentalLine.Quantity - QtyToAssign;
        RentalLineToPost.Amount := Round(RentalLineToPost.Amount, GLSetup."Amount Rounding Precision") - TotalChargeAmtLCY;
        if RentalHeader."Currency Code" <> '' then
            TotalChargeAmtLCY := TotalChargeAmtLCY + RentalLineToPost.Amount;
        RentalLineToPost."Unit Cost (LCY)" := Round(
            RentalLineToPost.Amount / QuantityBase, GLSetup."Unit-Amount Rounding Precision");
        UpdateRentalLineDimSetIDFromAppliedEntry(RentalLineToPost, RentalLine);
        RentalLineToPost."Line No." := TempItemChargeAssgntSales."Document Line No.";

        PostingEvents.OnPostItemChargeOnBeforePostItemJnlLine(RentalLineToPost, RentalLine, QtyToAssign, TempItemChargeAssgntSales);

        PostItemJnlLine(
          RentalHeader, RentalLineToPost, 0, 0, -QuantityBase, -QuantityBase,
          RentalLineToPost."Appl.-to Item Entry", TempItemChargeAssgntSales."Item Charge No.", DummyTrackingSpecification, false);

        PostingEvents.OnPostItemChargeOnAfterPostItemJnlLine(RentalHeader, RentalLineToPost);

        PostingEvents.OnAfterPostItemCharge(RentalHeader, RentalLine, TempItemChargeAssgntSales, ItemLedgEntryNo);
    end;

    local procedure SaveTempWhseSplitSpec(var RentalLine3: Record "TWE Rental Line"; var TempSrcTrackingSpec: Record "Tracking Specification" temporary)
    begin
        TempWhseSplitSpecification.Reset();
        TempWhseSplitSpecification.DeleteAll();
        if TempSrcTrackingSpec.FindSet() then
            repeat
                TempWhseSplitSpecification := TempSrcTrackingSpec;
                TempWhseSplitSpecification.SetSource(
                  DATABASE::"Sales Line", RentalLine3."Document Type".AsInteger(), RentalLine3."Document No.", RentalLine3."Line No.", '', 0);
                TempWhseSplitSpecification.Insert();
            until TempSrcTrackingSpec.Next() = 0;
    end;

    /*     local procedure TransferReservToItemJnlLine(var RentalOrderLine: Record "TWE Rental Line"; var RentalItemJnlLine: Record "TWE Rental Item Journal Line"; QtyToBeShippedBase: Decimal; var TempTrackingSpecification2: Record "Tracking Specification" temporary; var CheckApplFromItemEntry: Boolean)
        var
            RemainingQuantity: Decimal;
        begin
            // Handle Item Tracking and reservations, also PostingEvents.On drop shipment
            if QtyToBeShippedBase = 0 then
                exit;

            Clear(ReserveSalesLine);
            if not RentalOrderLine."Drop Shipment" then
                if not HasSpecificTracking(RentalOrderLine."No.") and HasInvtPickLine(RentalOrderLine) then
                    ReserveRentalLine.TransferSalesLineToItemJnlLine(
                      RentalOrderLine, RentalItemJnlLine, QtyToBeShippedBase, CheckApplFromItemEntry, true)
                else
                    ReserveRentalLine.TransferSalesLineToItemJnlLine(
                      RentalOrderLine, RentalItemJnlLine, QtyToBeShippedBase, CheckApplFromItemEntry, false)
            else begin
                ReserveRentalLine.SetApplySpecificItemTracking(true);
                TempTrackingSpecification2.Reset();
                TempTrackingSpecification2.SetSourceFilter(
                  DATABASE::"Purchase Line", 1, RentalOrderLine."Purchase Order No.", RentalOrderLine."Purch. Order Line No.", false);
                TempTrackingSpecification2.SetSourceFilter('', 0);
                if TempTrackingSpecification2.IsEmpty() then
                    ReserveRentalLine.TransferSalesLineToItemJnlLine(
                      RentalOrderLine, RentalItemJnlLine, QtyToBeShippedBase, CheckApplFromItemEntry, false)
                else begin
                    ReserveRentalLine.SetOverruleItemTracking(true);
                    ReserveRentalLine.SetItemTrkgAlreadyOverruled(ItemTrkgAlreadyOverruled);
                    TempTrackingSpecification2.FindSet();
                    if TempTrackingSpecification2."Quantity (Base)" / QtyToBeShippedBase < 0 then
                        Error(ItemTrackingWrongSignErr);
                    repeat
                        RentalItemJnlLine.CopyTrackingFromSpec(TempTrackingSpecification2);
                        RentalItemJnlLine."Applies-to Entry" := TempTrackingSpecification2."Item Ledger Entry No.";
                        RemainingQuantity :=
                          ReserveRentalLine.TransferSalesLineToItemJnlLine(
                            RentalOrderLine, RentalItemJnlLine, TempTrackingSpecification2."Quantity (Base)", CheckApplFromItemEntry, false);
                        if RemainingQuantity <> 0 then
                            Error(ItemTrackingMismatchErr);
                    until TempTrackingSpecification2.Next() = 0;
                    RentalItemJnlLine.ClearTracking;
                    RentalItemJnlLine."Applies-to Entry" := 0;
                end;
            end; 
        end;*/

    local procedure TransferReservFromPurchLine(var PurchOrderLine: Record "Purchase Line"; var RentalItemJnlLine: Record "TWE Rental Item Journal Line"; RentalLine: Record "TWE Rental Line"; QtyToBeShippedBase: Decimal)
    var
        ReservEntry: Record "Reservation Entry";
        TempTrackingSpecification2: Record "Tracking Specification" temporary;
        ReservePurchLine: Codeunit "Purch. Line-Reserve";
        RemainingQuantity: Decimal;
        CheckApplToItemEntry: Boolean;
    begin
        // Handle Item Tracking on Drop Shipment
        ItemTrkgAlreadyOverruled := false;
        if QtyToBeShippedBase = 0 then
            exit;

        ReservEntry.SetSourceFilter(
          DATABASE::"Sales Line", RentalLine."Document Type".AsInteger(), RentalLine."Document No.", RentalLine."Line No.", true);
        ReservEntry.SetSourceFilter('', 0);
        ReservEntry.SetFilter("Qty. to Handle (Base)", '<>0');
        if not ReservEntry.IsEmpty() then
            ItemTrackingMgt.SumUpItemTracking(ReservEntry, TempTrackingSpecification2, false, true);
        TempTrackingSpecification2.SetFilter("Qty. to Handle (Base)", '<>0');
        if TempTrackingSpecification2.IsEmpty() then begin
            //ReserveRentalLine.SetApplySpecificItemTracking(true);
            /*          ReservePurchLine.TransferPurchLineToItemJnlLine(
                       PurchOrderLine, RentalItemJnlLine, QtyToBeShippedBase, CheckApplToItemEntry) */
        end else begin
            ReservePurchLine.SetOverruleItemTracking(true);
            ItemTrkgAlreadyOverruled := true;
            TempTrackingSpecification2.FindSet();
            if -TempTrackingSpecification2."Quantity (Base)" / QtyToBeShippedBase < 0 then
                Error(ItemTrackingWrongSignErr);
            if PurchOrderLine.ReservEntryExist then
                repeat
                    RentalItemJnlLine.CopyTrackingFromSpec(TempTrackingSpecification2);
                    /*  RemainingQuantity :=
                       ReservePurchLine.TransferPurchLineToItemJnlLine(
                         PurchOrderLine, RentalItemJnlLine,
                         -TempTrackingSpecification2."Qty. to Handle (Base)", CheckApplToItemEntry); */
                    if RemainingQuantity <> 0 then
                        Error(ItemTrackingMismatchErr);
                until TempTrackingSpecification2.Next() = 0;
            RentalItemJnlLine.ClearTracking;
            RentalItemJnlLine."Applies-to Entry" := 0;
        end;
    end;

    procedure SetWhseRcptHeader(var WhseRcptHeader2: Record "Warehouse Receipt Header")
    begin
        WhseRcptHeader := WhseRcptHeader2;
        TempWhseRcptHeader := WhseRcptHeader;
        TempWhseRcptHeader.Insert();
    end;

    procedure SetWhseShptHeader(var WhseShptHeader2: Record "Warehouse Shipment Header")
    begin
        WhseShptHeader := WhseShptHeader2;
        TempWhseShptHeader := WhseShptHeader;
        TempWhseShptHeader.Insert();
    end;

    local procedure GetItem(RentalLine: Record "TWE Rental Line")
    begin
        RentalLine.TestField(Type, RentalLine.Type::"Rental Item");
        RentalLine.TestField("No.");
        if RentalLine."No." <> MainRentalItem."No." then
            MainRentalItem.Get(RentalLine."No.");
    end;

    local procedure CreatePrepaymentLines(RentalHeader: Record "TWE Rental Header"; CompleteFunctionality: Boolean)
    var
        GLAcc: Record "G/L Account";
        TempRentalLine: Record "TWE Rental Line" temporary;
        TempExtTextLine: Record "Extended Text Line" temporary;
        GenPostingSetup: Record "General Posting Setup";
        TempPrepmtRentalLine: Record "TWE Rental Line" temporary;
        TransferExtText: Codeunit "Transfer Extended Text";
        NextLineNo: Integer;
        Fraction: Decimal;
        VATDifference: Decimal;
        TempLineFound: Boolean;
        PrepmtAmtToDeduct: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        PostingEvents.OnBeforeCreatePrepaymentLines(RentalHeader, TempPrepmtRentalLine, CompleteFunctionality, IsHandled);
        if IsHandled then
            exit;

        GetGLSetup();
        // Get Sales lines
        FillTempLines(RentalHeader, TempRentalLineGlobal);
        // Copy TempRentalLineGlobal to TempSalesLine
        ResetTempLines(TempRentalLine);

        if not TempRentalLine.FindLast() then
            exit;

        NextLineNo := TempRentalLine."Line No." + 10000;
        TempRentalLine.SetFilter(Quantity, '>0');
        TempRentalLine.SetFilter("Qty. to Invoice", '>0');
        TempPrepmtRentalLine.SetHasBeenShown;

        // Get all sales lines
        if TempRentalLine.FindSet() then begin
            if CompleteFunctionality and (TempRentalLine."Document Type" = TempRentalLine."Document Type"::Invoice) then
                TestGetShipmentPPmtAmtToDeduct;
            repeat
                if CompleteFunctionality then
                    if RentalHeader."Document Type" <> RentalHeader."Document Type"::Invoice then begin
                        if not RentalHeader.Ship and (TempRentalLine."Qty. to Invoice" = TempRentalLine.Quantity - TempRentalLine."Quantity Invoiced") then
                            if TempRentalLine."Qty. Shipped Not Invoiced" < TempRentalLine."Qty. to Invoice" then
                                TempRentalLine.Validate("Qty. to Invoice", TempRentalLine."Qty. Shipped Not Invoiced");
                        Fraction := (TempRentalLine."Qty. to Invoice" + TempRentalLine."Quantity Invoiced") / TempRentalLine.Quantity;

                        if TempRentalLine."Prepayment %" <> 100 then
                            case true of
                                (TempRentalLine."Prepmt Amt to Deduct" <> 0) and
                              (TempRentalLine."Prepmt Amt to Deduct" > Round(Fraction * TempRentalLine."Line Amount", Currency."Amount Rounding Precision")):
                                    TempRentalLine.FieldError(
                                      "Prepmt Amt to Deduct",
                                      StrSubstNo(CannotBeGreaterThanErr,
                                        Round(Fraction * TempRentalLine."Line Amount", Currency."Amount Rounding Precision")));
                                (TempRentalLine."Prepmt. Amt. Inv." <> 0) and
                              (Round((1 - Fraction) * TempRentalLine."Line Amount", Currency."Amount Rounding Precision") <
                               Round(
                                 Round(
                                   Round(TempRentalLine."Unit Price" * (TempRentalLine.Quantity - TempRentalLine."Quantity Invoiced" - TempRentalLine."Qty. to Invoice"),
                                     Currency."Amount Rounding Precision") *
                                   (1 - (TempRentalLine."Line Discount %" / 100)), Currency."Amount Rounding Precision") *
                                 TempRentalLine."Prepayment %" / 100, Currency."Amount Rounding Precision")):
                                    TempRentalLine.FieldError(
                                      TempRentalLine."Prepmt Amt to Deduct",
                                      StrSubstNo(CannotBeSmallerThanErr,
                                        Round(
                                          TempRentalLine."Prepmt. Amt. Inv." - TempRentalLine."Prepmt Amt Deducted" - (1 - Fraction) * TempRentalLine."Line Amount",
                                          Currency."Amount Rounding Precision")));
                            end;
                    end;
                if TempRentalLine."Prepmt Amt to Deduct" <> 0 then begin
                    if (TempRentalLine."Gen. Bus. Posting Group" <> GenPostingSetup."Gen. Bus. Posting Group") or
                       (TempRentalLine."Gen. Prod. Posting Group" <> GenPostingSetup."Gen. Prod. Posting Group")
                    then
                        GenPostingSetup.Get(TempRentalLine."Gen. Bus. Posting Group", TempRentalLine."Gen. Prod. Posting Group");
                    GLAcc.Get(GenPostingSetup.GetSalesPrepmtAccount);
                    TempLineFound := false;
                    if RentalHeader."Compress Prepayment" then begin
                        TempPrepmtRentalLine.SetRange("No.", GLAcc."No.");
                        TempPrepmtRentalLine.SetRange("Dimension Set ID", TempRentalLine."Dimension Set ID");
                        TempLineFound := TempPrepmtRentalLine.FindFirst();
                    end;
                    if TempLineFound then begin
                        PrepmtAmtToDeduct :=
                          TempPrepmtRentalLine."Prepmt Amt to Deduct" +
                          InsertedPrepmtVATBaseToDeduct(
                            RentalHeader, TempRentalLine, TempPrepmtRentalLine."Line No.", TempPrepmtRentalLine."Unit Price");
                        VATDifference := TempPrepmtRentalLine."VAT Difference";
                        TempPrepmtRentalLine.Validate(
                          "Unit Price", TempPrepmtRentalLine."Unit Price" + TempRentalLine."Prepmt Amt to Deduct");
                        TempPrepmtRentalLine.Validate("VAT Difference", VATDifference - TempRentalLine."Prepmt VAT Diff. to Deduct");
                        TempPrepmtRentalLine."Prepmt Amt to Deduct" := PrepmtAmtToDeduct;
                        if TempRentalLine."Prepayment %" < TempPrepmtRentalLine."Prepayment %" then
                            TempPrepmtRentalLine."Prepayment %" := TempRentalLine."Prepayment %";
                        PostingEvents.OnBeforeTempPrepmtSalesLineModify(TempPrepmtRentalLine, TempRentalLine, RentalHeader, CompleteFunctionality);
                        TempPrepmtRentalLine.Modify();
                    end else begin
                        TempPrepmtRentalLine.Init();
                        TempPrepmtRentalLine."Document Type" := RentalHeader."Document Type";
                        TempPrepmtRentalLine."Document No." := RentalHeader."No.";
                        TempPrepmtRentalLine."Line No." := 0;
                        TempPrepmtRentalLine."System-Created Entry" := true;
                        if CompleteFunctionality then
                            TempPrepmtRentalLine.Validate(Type, TempPrepmtRentalLine.Type::"G/L Account")
                        else
                            TempPrepmtRentalLine.Type := TempPrepmtRentalLine.Type::"G/L Account";

                        // deduct from prepayment 
                        TempPrepmtRentalLine.Validate("No.", GenPostingSetup."Sales Prepayments Account");
                        TempPrepmtRentalLine.Validate(Quantity, -1);
                        TempPrepmtRentalLine."Qty. to Ship" := TempPrepmtRentalLine.Quantity;
                        TempPrepmtRentalLine."Qty. to Invoice" := TempPrepmtRentalLine.Quantity;
                        PrepmtAmtToDeduct := InsertedPrepmtVATBaseToDeduct(RentalHeader, TempRentalLine, NextLineNo, 0);
                        TempPrepmtRentalLine.Validate("Unit Price", TempRentalLine."Prepmt Amt to Deduct");
                        TempPrepmtRentalLine.Validate("VAT Difference", -TempRentalLine."Prepmt VAT Diff. to Deduct");
                        TempPrepmtRentalLine."Prepmt Amt to Deduct" := PrepmtAmtToDeduct;
                        TempPrepmtRentalLine."Prepayment %" := TempRentalLine."Prepayment %";
                        TempPrepmtRentalLine."Prepayment Line" := true;
                        TempPrepmtRentalLine."Shortcut Dimension 1 Code" := TempRentalLine."Shortcut Dimension 1 Code";
                        TempPrepmtRentalLine."Shortcut Dimension 2 Code" := TempRentalLine."Shortcut Dimension 2 Code";
                        TempPrepmtRentalLine."Dimension Set ID" := TempRentalLine."Dimension Set ID";
                        TempPrepmtRentalLine."Line No." := NextLineNo;
                        NextLineNo := NextLineNo + 10000;
                        PostingEvents.OnBeforeTempPrepmtSalesLineInsert(TempPrepmtRentalLine, TempRentalLine, RentalHeader, CompleteFunctionality);
                        TempPrepmtRentalLine.Insert();

                        TransferExtText.PrepmtGetAnyExtText(
                          TempPrepmtRentalLine."No.", DATABASE::"Sales Invoice Line",
                          RentalHeader."Document Date", RentalHeader."Language Code", TempExtTextLine);
                        if TempExtTextLine.Find('-') then
                            repeat
                                TempPrepmtRentalLine.Init();
                                TempPrepmtRentalLine.Description := TempExtTextLine.Text;
                                TempPrepmtRentalLine."System-Created Entry" := true;
                                TempPrepmtRentalLine."Prepayment Line" := true;
                                TempPrepmtRentalLine."Line No." := NextLineNo;
                                NextLineNo := NextLineNo + 10000;
                                TempPrepmtRentalLine.Insert();
                            until TempExtTextLine.Next() = 0;
                    end;
                end;
            until TempRentalLine.Next() = 0
        end;
        DividePrepmtAmountLCY(TempPrepmtRentalLine, RentalHeader);
        if TempPrepmtRentalLine.FindSet() then
            repeat
                TempRentalLineGlobal := TempPrepmtRentalLine;
                TempRentalLineGlobal.Insert();
            until TempPrepmtRentalLine.Next() = 0;
    end;

    local procedure InsertedPrepmtVATBaseToDeduct(RentalHeader: Record "TWE Rental Header"; RentalLine: Record "TWE Rental Line"; PrepmtLineNo: Integer; TotalPrepmtAmtToDeduct: Decimal): Decimal
    var
        PrepmtVATBaseToDeduct: Decimal;
    begin
        if RentalHeader."Prices Including VAT" then
            PrepmtVATBaseToDeduct :=
              Round(
                (TotalPrepmtAmtToDeduct + RentalLine."Prepmt Amt to Deduct") / (1 + RentalLine."Prepayment VAT %" / 100),
                Currency."Amount Rounding Precision") -
              Round(
                TotalPrepmtAmtToDeduct / (1 + RentalLine."Prepayment VAT %" / 100),
                Currency."Amount Rounding Precision")
        else
            PrepmtVATBaseToDeduct := RentalLine."Prepmt Amt to Deduct";

        TempPrepmtDeductLCYRentalLine := RentalLine;
        if TempPrepmtDeductLCYRentalLine."Document Type" = TempPrepmtDeductLCYRentalLine."Document Type"::Contract then
            TempPrepmtDeductLCYRentalLine."Qty. to Invoice" := GetQtyToInvoice(RentalLine, RentalHeader.Ship)
        else
            GetLineDataFromOrder(TempPrepmtDeductLCYRentalLine);
        if (TempPrepmtDeductLCYRentalLine."Prepmt Amt to Deduct" = 0) or (TempPrepmtDeductLCYRentalLine."Document Type" = TempPrepmtDeductLCYRentalLine."Document Type"::Invoice) then
            TempPrepmtDeductLCYRentalLine.CalcPrepaymentToDeduct;
        TempPrepmtDeductLCYRentalLine."Line Amount" := TempPrepmtDeductLCYRentalLine.GetLineAmountToHandleInclPrepmt(TempPrepmtDeductLCYRentalLine."Qty. to Invoice");
        TempPrepmtDeductLCYRentalLine."Attached to Line No." := PrepmtLineNo;
        TempPrepmtDeductLCYRentalLine."VAT Base Amount" := PrepmtVATBaseToDeduct;
        TempPrepmtDeductLCYRentalLine.Insert;

        PostingEvents.OnAfterInsertedPrepmtVATBaseToDeduct(
          RentalHeader, RentalLine, PrepmtLineNo, TotalPrepmtAmtToDeduct, TempPrepmtDeductLCYRentalLine, PrepmtVATBaseToDeduct);

        exit(PrepmtVATBaseToDeduct);
    end;

    local procedure DividePrepmtAmountLCY(var PrepmtRentalLine: Record "TWE Rental Line"; RentalHeader: Record "TWE Rental Header")
    var
        CurrExchRate: Record "Currency Exchange Rate";
        ActualCurrencyFactor: Decimal;
    begin
        PrepmtRentalLine.Reset;
        PrepmtRentalLine.SetFilter(Type, '<>%1', PrepmtRentalLine.Type::" ");
        if PrepmtRentalLine.FindSet() then
            repeat
                if RentalHeader."Currency Code" <> '' then
                    ActualCurrencyFactor :=
                      Round(
                        CurrExchRate.ExchangeAmtFCYToLCY(
                          RentalHeader."Posting Date",
                          RentalHeader."Currency Code",
                          PrepmtRentalLine."Prepmt Amt to Deduct",
                          RentalHeader."Currency Factor")) /
                      PrepmtRentalLine."Prepmt Amt to Deduct"
                else
                    ActualCurrencyFactor := 1;

                UpdatePrepmtAmountInvBuf(PrepmtRentalLine."Line No.", ActualCurrencyFactor);
            until PrepmtRentalLine.Next() = 0;
        PrepmtRentalLine.Reset;
    end;

    local procedure UpdatePrepmtAmountInvBuf(PrepmtSalesLineNo: Integer; CurrencyFactor: Decimal)
    var
        PrepmtAmtRemainder: Decimal;
    begin
        TempPrepmtDeductLCYRentalLine.Reset;
        TempPrepmtDeductLCYRentalLine.SetRange("Attached to Line No.", PrepmtSalesLineNo);
        if TempPrepmtDeductLCYRentalLine.FindSet(true) then
            repeat
                TempPrepmtDeductLCYRentalLine."Prepmt. Amount Inv. (LCY)" :=
                  CalcRoundedAmount(CurrencyFactor * TempPrepmtDeductLCYRentalLine."VAT Base Amount", PrepmtAmtRemainder);
                TempPrepmtDeductLCYRentalLine.Modify();
            until TempPrepmtDeductLCYRentalLine.Next() = 0;
    end;

    local procedure AdjustPrepmtAmountLCY(RentalHeader: Record "TWE Rental Header"; var PrepmtRentalLine: Record "TWE Rental Line")
    var
        RentalLine: Record "TWE Rental Line";
        SalesInvoiceLine: Record "TWE Rental Line";
        DeductionFactor: Decimal;
        PrepmtVATPart: Decimal;
        PrepmtVATAmtRemainder: Decimal;
        TotalRoundingAmount: array[2] of Decimal;
        TotalPrepmtAmount: array[2] of Decimal;
        FinalInvoice: Boolean;
        PricesInclVATRoundingAmount: array[2] of Decimal;
    begin
        if PrepmtRentalLine."Prepayment Line" then begin
            PrepmtVATPart :=
              (PrepmtRentalLine."Amount Including VAT" - PrepmtRentalLine.Amount) / PrepmtRentalLine."Unit Price";

            TempPrepmtDeductLCYRentalLine.Reset;
            TempPrepmtDeductLCYRentalLine.SetRange("Attached to Line No.", PrepmtRentalLine."Line No.");
            if TempPrepmtDeductLCYRentalLine.FindSet(true) then begin
                FinalInvoice := TempPrepmtDeductLCYRentalLine.IsFinalInvoice();
                repeat
                    RentalLine := TempPrepmtDeductLCYRentalLine;
                    RentalLine.Find();
                    if TempPrepmtDeductLCYRentalLine."Document Type" = TempPrepmtDeductLCYRentalLine."Document Type"::Invoice then begin
                        SalesInvoiceLine := RentalLine;
                        GetSalesOrderLine(RentalLine, SalesInvoiceLine);
                        RentalLine."Qty. to Invoice" := SalesInvoiceLine."Qty. to Invoice";
                    end;
                    if RentalLine."Qty. to Invoice" <> TempPrepmtDeductLCYRentalLine."Qty. to Invoice" then
                        RentalLine."Prepmt Amt to Deduct" := CalcPrepmtAmtToDeduct(RentalLine, RentalHeader.Ship);
                    DeductionFactor :=
                      RentalLine."Prepmt Amt to Deduct" /
                      (RentalLine."Prepmt. Amt. Inv." - RentalLine."Prepmt Amt Deducted");

                    TempPrepmtDeductLCYRentalLine."Prepmt. VAT Amount Inv. (LCY)" :=
                      CalcRoundedAmount(RentalLine."Prepmt Amt to Deduct" * PrepmtVATPart, PrepmtVATAmtRemainder);
                    if (TempPrepmtDeductLCYRentalLine."Prepayment %" <> 100) or TempPrepmtDeductLCYRentalLine.IsFinalInvoice or (TempPrepmtDeductLCYRentalLine."Currency Code" <> '') then
                        CalcPrepmtRoundingAmounts(TempPrepmtDeductLCYRentalLine, RentalLine, DeductionFactor, TotalRoundingAmount);
                    TempPrepmtDeductLCYRentalLine.Modify();

                    if RentalHeader."Prices Including VAT" then
                        if ((TempPrepmtDeductLCYRentalLine."Prepayment %" <> 100) or TempPrepmtDeductLCYRentalLine.IsFinalInvoice) and (DeductionFactor = 1) then begin
                            PricesInclVATRoundingAmount[1] := TotalRoundingAmount[1];
                            PricesInclVATRoundingAmount[2] := TotalRoundingAmount[2];
                        end;

                    if TempPrepmtDeductLCYRentalLine."VAT Calculation Type" <> TempPrepmtDeductLCYRentalLine."VAT Calculation Type"::"Full VAT" then
                        TotalPrepmtAmount[1] += TempPrepmtDeductLCYRentalLine."Prepmt. Amount Inv. (LCY)";
                    TotalPrepmtAmount[2] += TempPrepmtDeductLCYRentalLine."Prepmt. VAT Amount Inv. (LCY)";
                    FinalInvoice := FinalInvoice and TempPrepmtDeductLCYRentalLine.IsFinalInvoice;
                until TempPrepmtDeductLCYRentalLine.Next() = 0;
            end;

            UpdatePrepmtSalesLineWithRounding(
              PrepmtRentalLine, TotalRoundingAmount, TotalPrepmtAmount,
              FinalInvoice, PricesInclVATRoundingAmount);
        end;
    end;

    local procedure CalcPrepmtAmtToDeduct(RentalLine: Record "TWE Rental Line"; Ship: Boolean): Decimal
    begin
        RentalLine."Qty. to Invoice" := GetQtyToInvoice(RentalLine, Ship);
        RentalLine.CalcPrepaymentToDeduct;
        exit(RentalLine."Prepmt Amt to Deduct");
    end;

    local procedure GetQtyToInvoice(RentalLine: Record "TWE Rental Line"; Ship: Boolean): Decimal
    var
        AllowedQtyToInvoice: Decimal;
    begin
        AllowedQtyToInvoice := RentalLine."Qty. Shipped Not Invoiced";
        if Ship then
            AllowedQtyToInvoice := AllowedQtyToInvoice + RentalLine."Qty. to Ship";
        if RentalLine."Qty. to Invoice" > AllowedQtyToInvoice then
            exit(AllowedQtyToInvoice);
        exit(RentalLine."Qty. to Invoice");
    end;

    local procedure GetLineDataFromOrder(var RentalLine: Record "TWE Rental Line")
    var
        RentalShptLine: Record "TWE Rental Shipment Line";
        RentalOrderLine: Record "TWE Rental Line";
    begin
        RentalShptLine.Get(RentalLine."Shipment No.", RentalLine."Shipment Line No.");
        RentalOrderLine.Get(RentalLine."Document Type"::Contract, RentalShptLine."Order No.", RentalShptLine."Order Line No.");

        RentalLine.Quantity := RentalOrderLine.Quantity;
        RentalLine."Qty. Shipped Not Invoiced" := RentalOrderLine."Qty. Shipped Not Invoiced";
        RentalLine."Quantity Invoiced" := RentalOrderLine."Quantity Invoiced";
        RentalLine."Prepmt Amt Deducted" := RentalOrderLine."Prepmt Amt Deducted";
        RentalLine."Prepmt. Amt. Inv." := RentalOrderLine."Prepmt. Amt. Inv.";
        RentalLine."Line Discount Amount" := RentalOrderLine."Line Discount Amount";

        PostingEvents.OnAfterGetLineDataFromOrder(RentalLine, RentalOrderLine);
    end;

    local procedure CalcPrepmtRoundingAmounts(var PrepmtSalesLineBuf: Record "TWE Rental Line"; RentalLine: Record "TWE Rental Line"; DeductionFactor: Decimal; var TotalRoundingAmount: array[2] of Decimal)
    var
        RoundingAmount: array[2] of Decimal;
    begin
        if PrepmtSalesLineBuf."VAT Calculation Type" <> PrepmtSalesLineBuf."VAT Calculation Type"::"Full VAT" then begin
            RoundingAmount[1] :=
              PrepmtSalesLineBuf."Prepmt. Amount Inv. (LCY)" - Round(DeductionFactor * RentalLine."Prepmt. Amount Inv. (LCY)");
            PrepmtSalesLineBuf."Prepmt. Amount Inv. (LCY)" := PrepmtSalesLineBuf."Prepmt. Amount Inv. (LCY)" - RoundingAmount[1];
            TotalRoundingAmount[1] += RoundingAmount[1];
        end;
        RoundingAmount[2] :=
          PrepmtSalesLineBuf."Prepmt. VAT Amount Inv. (LCY)" - Round(DeductionFactor * RentalLine."Prepmt. VAT Amount Inv. (LCY)");
        PrepmtSalesLineBuf."Prepmt. VAT Amount Inv. (LCY)" := PrepmtSalesLineBuf."Prepmt. VAT Amount Inv. (LCY)" - RoundingAmount[2];
        TotalRoundingAmount[2] += RoundingAmount[2];
    end;

    local procedure UpdatePrepmtSalesLineWithRounding(var PrepmtRentalLine: Record "TWE Rental Line"; TotalRoundingAmount: array[2] of Decimal; TotalPrepmtAmount: array[2] of Decimal; FinalInvoice: Boolean; PricesInclVATRoundingAmount: array[2] of Decimal)
    var
        NewAmountIncludingVAT: Decimal;
        Prepmt100PctVATRoundingAmt: Decimal;
        AmountRoundingPrecision: Decimal;
    begin
        PostingEvents.OnBeforeUpdatePrepmtSalesLineWithRounding(
          PrepmtRentalLine, TotalRoundingAmount, TotalPrepmtAmount, FinalInvoice, PricesInclVATRoundingAmount,
          TotalRentalLine, TotalRentalLineLCY);

        NewAmountIncludingVAT := TotalPrepmtAmount[1] + TotalPrepmtAmount[2] + TotalRoundingAmount[1] + TotalRoundingAmount[2];
        if PrepmtRentalLine."Prepayment %" = 100 then
            TotalRoundingAmount[1] += PrepmtRentalLine."Amount Including VAT" - NewAmountIncludingVAT;
        AmountRoundingPrecision :=
          GetAmountRoundingPrecisionInLCY(PrepmtRentalLine."Document Type", PrepmtRentalLine."Document No.", PrepmtRentalLine."Currency Code");

        if (Abs(TotalRoundingAmount[1]) <= AmountRoundingPrecision) and
           (Abs(TotalRoundingAmount[2]) <= AmountRoundingPrecision) and
           (PrepmtRentalLine."Prepayment %" = 100)
        then begin
            Prepmt100PctVATRoundingAmt := TotalRoundingAmount[1];
            TotalRoundingAmount[1] := 0;
        end;

        PrepmtRentalLine."Prepmt. Amount Inv. (LCY)" := TotalRoundingAmount[1];
        PrepmtRentalLine.Amount := TotalPrepmtAmount[1] + TotalRoundingAmount[1];

        if (PricesInclVATRoundingAmount[1] <> 0) and (TotalRoundingAmount[1] = 0) then begin
            if (PrepmtRentalLine."Prepayment %" = 100) and FinalInvoice and
               (PrepmtRentalLine.Amount + TotalPrepmtAmount[2] = PrepmtRentalLine."Amount Including VAT")
            then
                Prepmt100PctVATRoundingAmt := 0;
            PricesInclVATRoundingAmount[1] := 0;
        end;

        if ((TotalRoundingAmount[2] <> 0) or FinalInvoice) and (TotalRoundingAmount[1] = 0) then begin
            if (PrepmtRentalLine."Prepayment %" = 100) and (PrepmtRentalLine."Prepmt. Amount Inv. (LCY)" = 0) then
                Prepmt100PctVATRoundingAmt += TotalRoundingAmount[2];
            if (PrepmtRentalLine."Prepayment %" = 100) or FinalInvoice then
                TotalRoundingAmount[2] := 0;
        end;

        if (PricesInclVATRoundingAmount[2] <> 0) and (TotalRoundingAmount[2] = 0) then begin
            if Abs(Prepmt100PctVATRoundingAmt) <= AmountRoundingPrecision then
                Prepmt100PctVATRoundingAmt := 0;
            PricesInclVATRoundingAmount[2] := 0;
        end;

        PrepmtRentalLine."Prepmt. VAT Amount Inv. (LCY)" := TotalRoundingAmount[2] + Prepmt100PctVATRoundingAmt;
        NewAmountIncludingVAT := PrepmtRentalLine.Amount + TotalPrepmtAmount[2] + TotalRoundingAmount[2];
        if (PricesInclVATRoundingAmount[1] = 0) and (PricesInclVATRoundingAmount[2] = 0) or
           (PrepmtRentalLine."Currency Code" <> '') and FinalInvoice
        then
            Increment(
              TotalRentalLineLCY."Amount Including VAT",
              PrepmtRentalLine."Amount Including VAT" - NewAmountIncludingVAT - Prepmt100PctVATRoundingAmt);
        if PrepmtRentalLine."Currency Code" = '' then
            TotalRentalLine."Amount Including VAT" := TotalRentalLineLCY."Amount Including VAT";
        PrepmtRentalLine."Amount Including VAT" := NewAmountIncludingVAT;

        if FinalInvoice and (TotalRentalLine.Amount = 0) and (TotalRentalLine."Amount Including VAT" <> 0) and
           (Abs(TotalRentalLine."Amount Including VAT") <= Currency."Amount Rounding Precision")
        then begin
            PrepmtRentalLine."Amount Including VAT" += TotalRentalLineLCY."Amount Including VAT";
            TotalRentalLine."Amount Including VAT" := 0;
            TotalRentalLineLCY."Amount Including VAT" := 0;
        end;

        PostingEvents.OnAfterUpdatePrepmtSalesLineWithRounding(
          PrepmtRentalLine, TotalRoundingAmount, TotalPrepmtAmount, FinalInvoice, PricesInclVATRoundingAmount,
          TotalRentalLine, TotalRentalLineLCY);
    end;

    local procedure CalcRoundedAmount(Amount: Decimal; var Remainder: Decimal): Decimal
    var
        AmountRnded: Decimal;
    begin
        Amount := Amount + Remainder;
        AmountRnded := Round(Amount, GLSetup."Amount Rounding Precision");
        Remainder := Amount - AmountRnded;
        exit(AmountRnded);
    end;

    local procedure GetSalesOrderLine(var RentalOrderLine: Record "TWE Rental Line"; RentalLine: Record "TWE Rental Line")
    var
        RentalShptLine: Record "TWE Rental Shipment Line";
    begin
        RentalShptLine.Get(RentalLine."Shipment No.", RentalLine."Shipment Line No.");
        RentalOrderLine.Get(
          RentalOrderLine."Document Type"::Contract,
          RentalShptLine."Order No.", RentalShptLine."Order Line No.");
        RentalOrderLine."Prepmt Amt to Deduct" := RentalLine."Prepmt Amt to Deduct";
    end;

    local procedure DecrementPrepmtAmtInvLCY(RentalLine: Record "TWE Rental Line"; var PrepmtAmountInvLCY: Decimal; var PrepmtVATAmountInvLCY: Decimal)
    begin
        TempPrepmtDeductLCYRentalLine.Reset();
        TempPrepmtDeductLCYRentalLine := RentalLine;
        if TempPrepmtDeductLCYRentalLine.Find() then begin
            PrepmtAmountInvLCY := PrepmtAmountInvLCY - TempPrepmtDeductLCYRentalLine."Prepmt. Amount Inv. (LCY)";
            PrepmtVATAmountInvLCY := PrepmtVATAmountInvLCY - TempPrepmtDeductLCYRentalLine."Prepmt. VAT Amount Inv. (LCY)";
        end;
    end;

    local procedure AdjustFinalInvWith100PctPrepmt(var CombinedRentalLine: Record "TWE Rental Line")
    var
        DiffToLineDiscAmt: Decimal;
    begin
        TempPrepmtDeductLCYRentalLine.Reset;
        TempPrepmtDeductLCYRentalLine.SetRange("Prepayment %", 100);
        if TempPrepmtDeductLCYRentalLine.FindSet(true) then
            repeat
                if TempPrepmtDeductLCYRentalLine.IsFinalInvoice then begin
                    DiffToLineDiscAmt := TempPrepmtDeductLCYRentalLine."Prepmt Amt to Deduct" - TempPrepmtDeductLCYRentalLine."Line Amount";
                    if TempPrepmtDeductLCYRentalLine."Document Type" = TempPrepmtDeductLCYRentalLine."Document Type"::Contract then
                        DiffToLineDiscAmt := DiffToLineDiscAmt * TempPrepmtDeductLCYRentalLine.Quantity / TempPrepmtDeductLCYRentalLine."Qty. to Invoice";
                    if DiffToLineDiscAmt <> 0 then begin
                        CombinedRentalLine.Get(TempPrepmtDeductLCYRentalLine."Document Type", TempPrepmtDeductLCYRentalLine."Document No.", TempPrepmtDeductLCYRentalLine."Line No.");
                        TempPrepmtDeductLCYRentalLine."Line Discount Amount" := CombinedRentalLine."Line Discount Amount" - DiffToLineDiscAmt;
                        TempPrepmtDeductLCYRentalLine.Modify();
                    end;
                end;
            until TempPrepmtDeductLCYRentalLine.Next() = 0;
        TempPrepmtDeductLCYRentalLine.Reset;
    end;

    local procedure GetPrepmtDiffToLineAmount(RentalLine: Record "TWE Rental Line"): Decimal
    begin
        if RentalLine."Prepayment %" = 100 then
            if TempPrepmtDeductLCYRentalLine.Get(RentalLine."Document Type", RentalLine."Document No.", RentalLine."Line No.") then
                exit(TempPrepmtDeductLCYRentalLine."Prepmt Amt to Deduct" + TempPrepmtDeductLCYRentalLine."Inv. Disc. Amount to Invoice" - TempPrepmtDeductLCYRentalLine."Line Amount");
    end;

    local procedure InsertICGenJnlLine(RentalHeader: Record "TWE Rental Header"; RentalLine: Record "TWE Rental Line"; var ICGenJnlLineNo: Integer)
    var
        ICGLAccount: Record "IC G/L Account";
        Vend: Record Vendor;
        ICPartner: Record "IC Partner";
        CurrExchRate: Record "Currency Exchange Rate";
        GenJnlLine: Record "Gen. Journal Line";
    begin
        RentalHeader.TestField("Rented-to IC Partner Code", '');
        RentalHeader.TestField("Bill-to IC Partner Code", '');
        /*         RentalLine.TestField("IC Partner Ref. Type", RentalLine."IC Partner Ref. Type"::"G/L Account");
                ICGLAccount.Get(RentalLine."IC Partner Reference"); */
        ICGenJnlLineNo := ICGenJnlLineNo + 1;

        TempICGenJnlLine.InitNewLine(
          RentalHeader."Posting Date", RentalHeader."Document Date", RentalHeader."Posting Description",
          RentalLine."Shortcut Dimension 1 Code", RentalLine."Shortcut Dimension 2 Code", RentalLine."Dimension Set ID",
          RentalHeader."Reason Code");
        TempICGenJnlLine."Line No." := ICGenJnlLineNo;

        TempICGenJnlLine.CopyDocumentFields(GenJnlLineDocType, GenJnlLineDocNo, GenJnlLineExtDocNo, SrcCode, RentalHeader."Posting No. Series");

        TempICGenJnlLine."Account Type" := TempICGenJnlLine."Account Type"::"IC Partner";
        //Validate("Account No.", RentalLine."IC Partner Code");
        TempICGenJnlLine."Source Currency Code" := RentalHeader."Currency Code";
        TempICGenJnlLine."Source Currency Amount" := TempICGenJnlLine.Amount;
        TempICGenJnlLine.Correction := RentalHeader.Correction;
        TempICGenJnlLine."Country/Region Code" := RentalHeader."VAT Country/Region Code";
        TempICGenJnlLine."Source Type" := GenJnlLine."Source Type"::Customer;
        TempICGenJnlLine."Source No." := RentalHeader."Bill-to Customer No.";
        TempICGenJnlLine."Source Line No." := RentalLine."Line No.";
        TempICGenJnlLine.Validate("Bal. Account Type", TempICGenJnlLine."Bal. Account Type"::"G/L Account");
        TempICGenJnlLine.Validate("Bal. Account No.", RentalLine."No.");
        TempICGenJnlLine."Shortcut Dimension 1 Code" := RentalLine."Shortcut Dimension 1 Code";
        TempICGenJnlLine."Shortcut Dimension 2 Code" := RentalLine."Shortcut Dimension 2 Code";
        TempICGenJnlLine."Dimension Set ID" := RentalLine."Dimension Set ID";

        //Vend.SetRange("IC Partner Code", RentalLine."IC Partner Code");
        if Vend.FindFirst() then begin
            TempICGenJnlLine.Validate("Bal. Gen. Bus. Posting Group", Vend."Gen. Bus. Posting Group");
            TempICGenJnlLine.Validate("Bal. VAT Bus. Posting Group", Vend."VAT Bus. Posting Group");
        end;
        TempICGenJnlLine.Validate("Bal. VAT Prod. Posting Group", RentalLine."VAT Prod. Posting Group");
        //"IC Partner Code" := RentalLine."IC Partner Code";
        //"IC Partner G/L Acc. No." := RentalLine."IC Partner Reference";
        TempICGenJnlLine."IC Direction" := TempICGenJnlLine."IC Direction"::Outgoing;
        //ICPartner.Get(RentalLine."IC Partner Code");
        if ICPartner."Cost Distribution in LCY" and (RentalLine."Currency Code" <> '') then begin
            TempICGenJnlLine."Currency Code" := '';
            TempICGenJnlLine."Currency Factor" := 0;
            Currency.Get(RentalLine."Currency Code");
            if RentalHeader.IsCreditDocType then
                TempICGenJnlLine.Amount :=
                  Round(
                    CurrExchRate.ExchangeAmtFCYToLCY(
                      RentalHeader."Posting Date", RentalLine."Currency Code",
                      RentalLine.Amount, RentalHeader."Currency Factor"))
            else
                TempICGenJnlLine.Amount :=
                  -Round(
                    CurrExchRate.ExchangeAmtFCYToLCY(
                      RentalHeader."Posting Date", RentalLine."Currency Code",
                      RentalLine.Amount, RentalHeader."Currency Factor"));
        end else begin
            Currency.InitRoundingPrecision;
            TempICGenJnlLine."Currency Code" := RentalHeader."Currency Code";
            TempICGenJnlLine."Currency Factor" := RentalHeader."Currency Factor";
            if RentalHeader.IsCreditDocType then
                TempICGenJnlLine.Amount := RentalLine.Amount
            else
                TempICGenJnlLine.Amount := -RentalLine.Amount;
        end;
        if TempICGenJnlLine."Bal. VAT %" <> 0 then
            TempICGenJnlLine.Amount := Round(TempICGenJnlLine.Amount * (1 + TempICGenJnlLine."Bal. VAT %" / 100), Currency."Amount Rounding Precision");
        TempICGenJnlLine.Validate(Amount);
        PostingEvents.OnBeforeInsertICGenJnlLine(TempICGenJnlLine, RentalHeader, RentalLine, SuppressCommit);
        TempICGenJnlLine.Insert;
    end;

    local procedure PostICGenJnl()
    var
        ICInOutBoxMgt: Codeunit ICInboxOutboxMgt;
        ICOutboxExport: Codeunit "IC Outbox Export";
        ICTransactionNo: Integer;
    begin
        TempICGenJnlLine.Reset();
        TempICGenJnlLine.SetFilter(Amount, '<>%1', 0);
        if TempICGenJnlLine.Find('-') then
            repeat
                ICTransactionNo := ICInOutBoxMgt.CreateOutboxJnlTransaction(TempICGenJnlLine, false);
                ICInOutBoxMgt.CreateOutboxJnlLine(ICTransactionNo, 1, TempICGenJnlLine);
                //ICOutboxExport.ProcessAutoSendOutboxTransactionNo(ICTransactionNo);
                GenJnlPostLine.RunWithCheck(TempICGenJnlLine);
            until TempICGenJnlLine.Next() = 0;
    end;

    local procedure TestGetShipmentPPmtAmtToDeduct()
    var
        TempRentalLine: Record "TWE Rental Line" temporary;
        TempShippedRentalLine: Record "TWE Rental Line" temporary;
        TempTotalRentalLine: Record "TWE Rental Line" temporary;
        TempRentalShptLine: Record "TWE Rental Shipment Line" temporary;
        RentalShptLine: Record "TWE Rental Shipment Line";
        RentalOrderLine: Record "TWE Rental Line";
        MaxAmtToDeduct: Decimal;
    begin
        ResetTempLines(TempRentalLine);
        TempRentalLine.SetFilter(Quantity, '>0');
        TempRentalLine.SetFilter("Qty. to Invoice", '>0');
        TempRentalLine.SetFilter("Shipment No.", '<>%1', '');
        TempRentalLine.SetFilter("Prepmt Amt to Deduct", '<>0');
        if TempRentalLine.IsEmpty() then
            exit;

        TempRentalLine.SetRange("Prepmt Amt to Deduct");
        if TempRentalLine.FindSet() then
            repeat
                if RentalShptLine.Get(TempRentalLine."Shipment No.", TempRentalLine."Shipment Line No.") then begin
                    TempShippedRentalLine := TempRentalLine;
                    TempShippedRentalLine.Insert();
                    TempRentalShptLine := RentalShptLine;
                    if TempRentalShptLine.Insert() then;

                    if not TempTotalRentalLine.Get(TempRentalLine."Document Type"::Contract, RentalShptLine."Order No.", RentalShptLine."Order Line No.") then begin
                        TempTotalRentalLine.Init();
                        TempTotalRentalLine."Document Type" := TempRentalLine."Document Type"::Contract;
                        TempTotalRentalLine."Document No." := RentalShptLine."Order No.";
                        TempTotalRentalLine."Line No." := RentalShptLine."Order Line No.";
                        TempTotalRentalLine.Insert();
                    end;
                    TempTotalRentalLine."Qty. to Invoice" := TempTotalRentalLine."Qty. to Invoice" + TempRentalLine."Qty. to Invoice";
                    TempTotalRentalLine."Prepmt Amt to Deduct" := TempTotalRentalLine."Prepmt Amt to Deduct" + TempRentalLine."Prepmt Amt to Deduct";
                    AdjustInvLineWith100PctPrepmt(TempRentalLine, TempTotalRentalLine);
                    TempTotalRentalLine.Modify();
                end;
            until TempRentalLine.Next() = 0;

        if TempShippedRentalLine.FindSet() then
            repeat
                if TempRentalLine.Get(TempShippedRentalLine."Shipment No.", TempShippedRentalLine."Shipment Line No.") then
                    if RentalOrderLine.Get(
                         TempShippedRentalLine."Document Type"::Contract, TempRentalShptLine."Order No.", TempRentalShptLine."Order Line No.")
                    then
                        if TempTotalRentalLine.Get(
                             TempShippedRentalLine."Document Type"::Contract, TempRentalShptLine."Order No.", TempRentalShptLine."Order Line No.")
                        then begin
                            MaxAmtToDeduct := RentalOrderLine."Prepmt. Amt. Inv." - RentalOrderLine."Prepmt Amt Deducted";

                            if TempTotalRentalLine."Prepmt Amt to Deduct" > MaxAmtToDeduct then
                                Error(PrepAmountToDeductToBigErr, TempRentalLine.FieldCaption("Prepmt Amt to Deduct"), MaxAmtToDeduct);

                            if (TempTotalRentalLine."Qty. to Invoice" = RentalOrderLine.Quantity - RentalOrderLine."Quantity Invoiced") and
                               (TempTotalRentalLine."Prepmt Amt to Deduct" <> MaxAmtToDeduct)
                            then
                                Error(PrepAmountToDeductToSmallErr, TempRentalLine.FieldCaption("Prepmt Amt to Deduct"), MaxAmtToDeduct);
                        end;
            until TempShippedRentalLine.Next() = 0;
    end;

    local procedure AdjustInvLineWith100PctPrepmt(var RentalInvoiceLine: Record "TWE Rental Line"; var TempTotalRentalLine: Record "TWE Rental Line" temporary)
    var
        RentalOrderLine: Record "TWE Rental Line";
        DiffAmtToDeduct: Decimal;
    begin
        if RentalInvoiceLine."Prepayment %" = 100 then begin
            RentalOrderLine := TempTotalRentalLine;
            RentalOrderLine.Find();
            if TempTotalRentalLine."Qty. to Invoice" = RentalOrderLine.Quantity - RentalOrderLine."Quantity Invoiced" then begin
                DiffAmtToDeduct :=
                  RentalOrderLine."Prepmt. Amt. Inv." - RentalOrderLine."Prepmt Amt Deducted" - TempTotalRentalLine."Prepmt Amt to Deduct";
                if DiffAmtToDeduct <> 0 then begin
                    RentalInvoiceLine."Prepmt Amt to Deduct" := RentalInvoiceLine."Prepmt Amt to Deduct" + DiffAmtToDeduct;
                    RentalInvoiceLine."Line Amount" := RentalInvoiceLine."Prepmt Amt to Deduct";
                    RentalInvoiceLine."Line Discount Amount" := RentalInvoiceLine."Line Discount Amount" - DiffAmtToDeduct;
                    ModifyTempLine(RentalInvoiceLine);
                    TempTotalRentalLine."Prepmt Amt to Deduct" := TempTotalRentalLine."Prepmt Amt to Deduct" + DiffAmtToDeduct;
                end;
            end;
        end;
    end;

    procedure ArchiveUnpostedOrder(RentalHeader: Record "TWE Rental Header")
    var
        RentalLine: Record "TWE Rental Line";
        RentalArchiveManagement: Codeunit "TWE Rental Archive Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        PostingEvents.OnBeforeArchiveUnpostedOrder(RentalHeader, IsHandled);
        if IsHandled then
            exit;

        GetSalesSetup();
        if not (RentalHeader."Document Type" in [RentalHeader."Document Type"::Contract]) then
            exit;
        if (RentalHeader."Document Type" = RentalHeader."Document Type"::Contract) and not RentalSetup."Archive Contracts" then
            exit;

        RentalLine.Reset();
        RentalLine.SetRange("Document Type", RentalHeader."Document Type");
        RentalLine.SetRange("Document No.", RentalHeader."No.");
        RentalLine.SetFilter(Quantity, '<>0');
        if RentalHeader."Document Type" = RentalHeader."Document Type"::Contract then
            RentalLine.SetFilter("Qty. to Ship", '<>0');
        /*         else
                    RentalLine.SetFilter("Return Qty. to Receive", '<>0'); */
        /*         if not RentalLine.IsEmpty and not PreviewMode then begin
                    RoundDeferralsForArchive(RentalHeader, RentalLine);
                RentalArchiveManagement.ArchRentalDocumentNoConfirm(RentalHeader);
                end; */
    end;

    local procedure SynchBOMSerialNo(var ServItemTmp3: Record "Service Item" temporary; var ServItemTmpCmp3: Record "Service Item Component" temporary)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        ItemLedgEntry2: Record "Item Ledger Entry";
        TempSalesShipMntLine: Record "Sales Shipment Line" temporary;
        TempServItemTmpCmp4: Record "Service Item Component" temporary;
        ServItemCompLocal: Record "Service Item Component";
        TempItemLedgEntry2: Record "Item Ledger Entry" temporary;
        ChildCount: Integer;
        EndLoop: Boolean;
    begin
        if not ServItemTmpCmp3.Find('-') then
            exit;

        if not ServItemTmp3.Find('-') then
            exit;

        TempSalesShipMntLine.DeleteAll();
        repeat
            Clear(TempSalesShipMntLine);
            TempSalesShipMntLine."Document No." := ServItemTmp3."Sales/Serv. Shpt. Document No.";
            TempSalesShipMntLine."Line No." := ServItemTmp3."Sales/Serv. Shpt. Line No.";
            if TempSalesShipMntLine.Insert() then;
        until ServItemTmp3.Next() = 0;

        if not TempSalesShipMntLine.Find('-') then
            exit;

        ServItemTmp3.SetCurrentKey("Sales/Serv. Shpt. Document No.", "Sales/Serv. Shpt. Line No.");
        Clear(ItemLedgEntry);
        ItemLedgEntry.SetCurrentKey("Document No.", "Document Type", "Document Line No.");

        repeat
            ChildCount := 0;
            TempServItemTmpCmp4.DeleteAll();
            ServItemTmp3.SetRange("Sales/Serv. Shpt. Document No.", TempSalesShipMntLine."Document No.");
            ServItemTmp3.SetRange("Sales/Serv. Shpt. Line No.", TempSalesShipMntLine."Line No.");
            if ServItemTmp3.Find('-') then
                repeat
                    ServItemTmpCmp3.SetRange(Active, true);
                    ServItemTmpCmp3.SetRange("Parent Service Item No.", ServItemTmp3."No.");
                    if ServItemTmpCmp3.Find('-') then
                        repeat
                            ChildCount += 1;
                            TempServItemTmpCmp4 := ServItemTmpCmp3;
                            TempServItemTmpCmp4.Insert();
                        until ServItemTmpCmp3.Next() = 0;
                until ServItemTmp3.Next() = 0;
            ItemLedgEntry.SetRange("Document No.", TempSalesShipMntLine."Document No.");
            ItemLedgEntry.SetRange("Document Type", ItemLedgEntry."Document Type"::"Sales Shipment");
            ItemLedgEntry.SetRange("Document Line No.", TempSalesShipMntLine."Line No.");
            if ItemLedgEntry.FindFirst() and TempServItemTmpCmp4.Find('-') then begin
                Clear(ItemLedgEntry2);
                ItemLedgEntry2.Get(ItemLedgEntry."Entry No.");
                EndLoop := false;
                repeat
                    if ItemLedgEntry2."Item No." = TempServItemTmpCmp4."No." then
                        EndLoop := true
                    else
                        if ItemLedgEntry2.Next() = 0 then
                            EndLoop := true;
                until EndLoop;
                ItemLedgEntry2.SetRange("Entry No.", ItemLedgEntry2."Entry No.", ItemLedgEntry2."Entry No." + ChildCount - 1);
                if ItemLedgEntry2.FindSet() then
                    repeat
                        TempItemLedgEntry2 := ItemLedgEntry2;
                        TempItemLedgEntry2.Insert();
                    until ItemLedgEntry2.Next() = 0;
                repeat
                    if ServItemCompLocal.Get(
                         TempServItemTmpCmp4.Active,
                         TempServItemTmpCmp4."Parent Service Item No.",
                         TempServItemTmpCmp4."Line No.")
                    then begin
                        TempItemLedgEntry2.SetRange("Item No.", ServItemCompLocal."No.");
                        if TempItemLedgEntry2.FindFirst() then begin
                            ServItemCompLocal."Serial No." := TempItemLedgEntry2."Serial No.";
                            ServItemCompLocal.Modify();
                            TempItemLedgEntry2.Delete();
                        end;
                    end;
                until TempServItemTmpCmp4.Next() = 0;
            end;
        until TempSalesShipMntLine.Next() = 0;
    end;

    local procedure GetGLSetup()
    begin
        if not GLSetupRead then
            GLSetup.Get();

        GLSetupRead := true;

        PostingEvents.OnAfterGetGLSetup(GLSetup);
    end;

    local procedure GetSalesSetup()
    begin
        if not RentalSetupRead then
            RentalSetup.Get;

        RentalSetupRead := true;

        PostingEvents.OnAfterGetRentalSetup(RentalSetup);
    end;

    local procedure LockTables(var RentalHeader: Record "TWE Rental Header")
    var
        RentalLine: Record "TWE Rental Line";
        PurchOrderHeader: Record "Purchase Header";
        PurchOrderLine: Record "Purchase Line";
    begin
        PostingEvents.OnBeforeLockTables(RentalHeader, PreviewMode, SuppressCommit);

        RentalLine.LockTable();
        ItemChargeAssgntSales.LockTable();
        PurchOrderLine.LockTable();
        PurchOrderHeader.LockTable();
        GetGLSetup();
        if not GLSetup.OptimGLEntLockForMultiuserEnv then begin
            GLEntry.LockTable();
            if GLEntry.FindLast() then;
        end;
    end;

    local procedure PostCustomerEntry(var RentalHeader: Record "TWE Rental Header"; TotalRentalLine2: Record "TWE Rental Line"; TotalRentalLineLCY2: Record "TWE Rental Line"; DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20];
                                                                                                                                                                          ExtDocNo: Code[35];
                                                                                                                                                                          SourceCode: Code[10])
    var
        GenJnlLine: Record "Gen. Journal Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        PostingEvents.OnBeforeRunPostCustomerEntry(RentalHeader, TotalRentalLine2, TotalRentalLineLCY2, SuppressCommit, PreviewMode, DocType, DocNo, ExtDocNo, SourceCode, GenJnlPostLine, IsHandled);
        if IsHandled then
            exit;

        GenJnlLine.InitNewLine(
          RentalHeader."Posting Date", RentalHeader."Document Date", RentalHeader."Posting Description",
          RentalHeader."Shortcut Dimension 1 Code", RentalHeader."Shortcut Dimension 2 Code",
          RentalHeader."Dimension Set ID", RentalHeader."Reason Code");

        GenJnlLine.CopyDocumentFields(DocType, DocNo, ExtDocNo, SourceCode, '');
        GenJnlLine."Account Type" := GenJnlLine."Account Type"::Customer;
        GenJnlLine."Account No." := RentalHeader."Bill-to Customer No.";
        GenJnlLine.CopyFromRentalHeader(RentalHeader);
        GenJnlLine.SetCurrencyFactor(RentalHeader."Currency Code", RentalHeader."Currency Factor");

        GenJnlLine."System-Created Entry" := true;

        GenJnlLine.CopyFromRentalHeaderApplyTo(RentalHeader);
        GenJnlLine.CopyFromRentalHeaderPayment(RentalHeader);

        GenJnlLine.Amount := -TotalRentalLine2."Amount Including VAT";
        GenJnlLine."Source Currency Amount" := -TotalRentalLine2."Amount Including VAT";
        GenJnlLine."Amount (LCY)" := -TotalRentalLineLCY2."Amount Including VAT";
        GenJnlLine."Sales/Purch. (LCY)" := -TotalRentalLineLCY2.Amount;
        GenJnlLine."Profit (LCY)" := -(TotalRentalLineLCY2.Amount - TotalRentalLineLCY2."Unit Cost (LCY)");
        GenJnlLine."Inv. Discount (LCY)" := -TotalRentalLineLCY2."Inv. Discount Amount";

        PostingEvents.OnBeforePostCustomerEntry(GenJnlLine, RentalHeader, TotalRentalLine2, TotalRentalLineLCY2, SuppressCommit, PreviewMode, GenJnlPostLine);
        GenJnlPostLine.RunWithCheck(GenJnlLine);
        PostingEvents.OnAfterPostCustomerEntry(GenJnlLine, RentalHeader, TotalRentalLine2, TotalRentalLineLCY2, SuppressCommit, GenJnlPostLine);
    end;

    local procedure UpdateRentalHeader(var CustLedgerEntry: Record "Cust. Ledger Entry")
    var
        GenJnlLine: Record "Gen. Journal Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        PostingEvents.OnBeforeUpdateRentalHeader(CustLedgerEntry, RentalInvHeader, RentalCrMemoHeader, GenJnlLineDocType.AsInteger(), IsHandled);
        if IsHandled then
            exit;

        case GenJnlLineDocType of
            GenJnlLine."Document Type"::Invoice:
                begin
                    FindCustLedgEntry(GenJnlLineDocType, GenJnlLineDocNo, CustLedgerEntry);
                    RentalInvHeader."Cust. Ledger Entry No." := CustLedgerEntry."Entry No.";
                    RentalInvHeader.Modify();
                end;
            GenJnlLine."Document Type"::"Credit Memo":
                begin
                    FindCustLedgEntry(GenJnlLineDocType, GenJnlLineDocNo, CustLedgerEntry);
                    RentalCrMemoHeader."Cust. Ledger Entry No." := CustLedgerEntry."Entry No.";
                    RentalCrMemoHeader.Modify();
                end;
        end;

        PostingEvents.OnAfterUpdateRentalHeader(CustLedgerEntry, RentalInvHeader, RentalCrMemoHeader, GenJnlLineDocType.AsInteger());
    end;

    local procedure MakeSalesLineToShip(var RentalLineToShip: Record "TWE Rental Line"; RentalLineInvoiced: Record "TWE Rental Line")
    var
        TempRentalLine: Record "TWE Rental Line" temporary;
    begin
        ResetTempLines(TempRentalLine);
        TempRentalLine := RentalLineInvoiced;
        TempRentalLine.Find();

        RentalLineToShip := RentalLineInvoiced;
        RentalLineToShip."Inv. Discount Amount" := TempRentalLine."Inv. Discount Amount";
    end;

    local procedure "MAX"(number1: Integer; number2: Integer): Integer
    begin
        if number1 > number2 then
            exit(number1);
        exit(number2);
    end;

    local procedure PostBalancingEntry(RentalHeader: Record "TWE Rental Header"; TotalRentalLine2: Record "TWE Rental Line"; TotalRentalLineLCY2: Record "TWE Rental Line"; DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20];
                                                                                                                                                                       ExtDocNo: Code[35];
                                                                                                                                                                       SourceCode: Code[10])
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        GenJnlLine: Record "Gen. Journal Line";
        EntryFound: Boolean;
    begin
        EntryFound := false;
        PostingEvents.OnPostBalancingEntryOnBeforeFindCustLedgEntry(
          RentalHeader, TotalRentalLine2, DocType.AsInteger(), DocNo, ExtDocNo, CustLedgEntry, EntryFound);
        if not EntryFound then
            FindCustLedgEntry(DocType, DocNo, CustLedgEntry);

        GenJnlLine.InitNewLine(
          RentalHeader."Posting Date", RentalHeader."Document Date", RentalHeader."Posting Description",
          RentalHeader."Shortcut Dimension 1 Code", RentalHeader."Shortcut Dimension 2 Code",
          RentalHeader."Dimension Set ID", RentalHeader."Reason Code");

        GenJnlLine.CopyDocumentFields("Gen. Journal Document Type"::" ", DocNo, ExtDocNo, SourceCode, '');
        GenJnlLine."Account Type" := GenJnlLine."Account Type"::Customer;
        GenJnlLine."Account No." := RentalHeader."Bill-to Customer No.";
        GenJnlLine.CopyFromRentalHeader(RentalHeader);
        GenJnlLine.SetCurrencyFactor(RentalHeader."Currency Code", RentalHeader."Currency Factor");

        if RentalHeader.IsCreditDocType then
            GenJnlLine."Document Type" := GenJnlLine."Document Type"::Refund
        else
            GenJnlLine."Document Type" := GenJnlLine."Document Type"::Payment;

        SetApplyToDocNo(RentalHeader, GenJnlLine, DocType, DocNo);

        GenJnlLine.Amount := TotalRentalLine2."Amount Including VAT" + CustLedgEntry."Remaining Pmt. Disc. Possible";
        GenJnlLine."Source Currency Amount" := GenJnlLine.Amount;
        CustLedgEntry.CalcFields(Amount);
        if CustLedgEntry.Amount = 0 then
            GenJnlLine."Amount (LCY)" := TotalRentalLineLCY2."Amount Including VAT"
        else
            GenJnlLine."Amount (LCY)" :=
              TotalRentalLineLCY2."Amount Including VAT" +
              Round(CustLedgEntry."Remaining Pmt. Disc. Possible" / CustLedgEntry."Adjusted Currency Factor");
        GenJnlLine."Allow Zero-Amount Posting" := true;

        PostingEvents.OnBeforePostBalancingEntry(GenJnlLine, RentalHeader, TotalRentalLine2, TotalRentalLineLCY2, SuppressCommit, PreviewMode);
        GenJnlPostLine.RunWithCheck(GenJnlLine);
        PostingEvents.OnAfterPostBalancingEntry(GenJnlLine, RentalHeader, TotalRentalLine2, TotalRentalLineLCY2, SuppressCommit, GenJnlPostLine);
    end;

    local procedure SetApplyToDocNo(RentalHeader: Record "TWE Rental Header"; var GenJnlLine: Record "Gen. Journal Line"; DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20])
    begin
        if RentalHeader."Bal. Account Type" = RentalHeader."Bal. Account Type"::"Bank Account" then
            GenJnlLine."Bal. Account Type" := GenJnlLine."Bal. Account Type"::"Bank Account";
        GenJnlLine."Bal. Account No." := RentalHeader."Bal. Account No.";
        GenJnlLine."Applies-to Doc. Type" := DocType;
        GenJnlLine."Applies-to Doc. No." := DocNo;

        PostingEvents.OnAfterSetApplyToDocNo(GenJnlLine, RentalHeader);
    end;

    local procedure FindCustLedgEntry(DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20]; var CustLedgEntry: Record "Cust. Ledger Entry")
    begin
        CustLedgEntry.SetRange("Document Type", DocType);
        CustLedgEntry.SetRange("Document No.", DocNo);
        CustLedgEntry.FindLast();
    end;

    local procedure ItemLedgerEntryExist(SalesLine2: Record "TWE Rental Line"; ShipOrReceive: Boolean): Boolean
    var
        HasItemLedgerEntry: Boolean;
    begin
        if ShipOrReceive then
            // item ledger entry will be created during posting in this transaction
            HasItemLedgerEntry :=
            ((SalesLine2."Qty. to Ship" + SalesLine2."Quantity Shipped") <> 0) or
            ((SalesLine2."Qty. to Invoice" + SalesLine2."Quantity Invoiced") <> 0) //or ((SalesLine2."Return Qty. to Receive" + SalesLine2."Return Qty. Received") <> 0)
        else
            // item ledger entry must already exist
            HasItemLedgerEntry :=
            (SalesLine2."Quantity Shipped" <> 0); //or (SalesLine2."Return Qty. Received" <> 0);

        exit(HasItemLedgerEntry);
    end;

    local procedure CheckPostRestrictions(RentalHeader: Record "TWE Rental Header")
    var
        Contact: Record Contact;
    begin
        if not PreviewMode then
            RentalHeader.CheckRentalPostRestrictions();

        CheckCustBlockage(RentalHeader, RentalHeader."Rented-to Customer No.", true);
        RentalHeader.ValidateSalesPersonOnTWERentalHeader(RentalHeader, true, true);

        if RentalHeader."Bill-to Customer No." <> RentalHeader."Rented-to Customer No." then
            CheckCustBlockage(RentalHeader, RentalHeader."Bill-to Customer No.", false);

        if RentalHeader."Rented-to Contact No." <> '' then
            if Contact.Get(RentalHeader."Rented-to Contact No.") then
                Contact.CheckIfPrivacyBlocked(true);
        if RentalHeader."Bill-to Contact No." <> '' then
            if Contact.Get(RentalHeader."Bill-to Contact No.") then
                Contact.CheckIfPrivacyBlocked(true);
    end;

    local procedure CheckCustBlockage(RentalHeader: Record "TWE Rental Header"; CustCode: Code[20]; ExecuteDocCheck: Boolean)
    var
        Cust: Record Customer;
        TempRentalLine: Record "TWE Rental Line" temporary;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        PostingEvents.OnBeforeCheckCustBlockage(RentalHeader, CustCode, ExecuteDocCheck, IsHandled);
        if IsHandled then
            exit;

        Cust.Get(CustCode);
        if RentalHeader.Receive then
            Cust.CheckBlockedCustOnDocs(Cust, RentalHeader."Document Type", false, true)
        else begin
            if RentalHeader.Ship and CheckDocumentType(RentalHeader, ExecuteDocCheck) then begin
                ResetTempLines(TempRentalLine);
                TempRentalLine.SetFilter("Qty. to Ship", '<>0');
                TempRentalLine.SetRange("Shipment No.", '');
                if not TempRentalLine.IsEmpty() then
                    Cust.CheckBlockedCustOnDocs(Cust, RentalHeader."Document Type", true, true);
            end else
                Cust.CheckBlockedCustOnDocs(Cust, RentalHeader."Document Type", false, true);
        end;
    end;

    local procedure CheckDocumentType(RentalHeader: Record "TWE Rental Header"; ExecuteDocCheck: Boolean): Boolean
    begin
        if ExecuteDocCheck then
            exit(
              (RentalHeader."Document Type" = RentalHeader."Document Type"::Contract) or
              ((RentalHeader."Document Type" = RentalHeader."Document Type"::Invoice) and RentalSetup."Shipment on Invoice"));
        exit(true);
    end;

    local procedure UpdateWonOpportunities(var RentalHeader: Record "TWE Rental Header")
    var
        Opp: Record Opportunity;
        OpportunityEntry: Record "Opportunity Entry";
    begin
        if RentalHeader."Document Type" = RentalHeader."Document Type"::Contract then begin
            Opp.Reset();
            Opp.SetCurrentKey("Sales Document Type", "Sales Document No.");
            Opp.SetRange("Sales Document Type", Opp."Sales Document Type"::Order);
            Opp.SetRange("Sales Document No.", RentalHeader."No.");
            Opp.SetRange(Status, Opp.Status::Won);
            if Opp.FindFirst() then begin
                Opp."Sales Document Type" := Opp."Sales Document Type"::"Posted Invoice";
                Opp."Sales Document No." := RentalInvHeader."No.";
                Opp.Modify();
                OpportunityEntry.Reset();
                OpportunityEntry.SetCurrentKey(Active, "Opportunity No.");
                OpportunityEntry.SetRange(Active, true);
                OpportunityEntry.SetRange("Opportunity No.", Opp."No.");
                /*  if OpportunityEntry.FindFirst() then begin
                     OpportunityEntry."Calcd. Current Value (LCY)" := OpportunityEntry.GetSalesDocValue(RentalHeader);
                     OpportunityEntry.Modify();
                 end; */
            end;
        end;
    end;

    local procedure UpdateQtyToBeInvoicedForShipment(var QtyToBeInvoiced: Decimal; var QtyToBeInvoicedBase: Decimal; TrackingSpecificationExists: Boolean; HasATOShippedNotInvoiced: Boolean; RentalLine: Record "TWE Rental Line"; RentalShptLine: Record "TWE Rental Shipment Line"; InvoicingTrackingSpecification: Record "Tracking Specification"; ItemLedgEntryNotInvoiced: Record "Item Ledger Entry")
    begin
        if TrackingSpecificationExists then begin
            QtyToBeInvoiced := InvoicingTrackingSpecification."Qty. to Invoice";
            QtyToBeInvoicedBase := InvoicingTrackingSpecification."Qty. to Invoice (Base)";
        end else
            if HasATOShippedNotInvoiced then begin
                QtyToBeInvoicedBase := ItemLedgEntryNotInvoiced.Quantity - ItemLedgEntryNotInvoiced."Invoiced Quantity";
                if Abs(QtyToBeInvoicedBase) > Abs(RemQtyToBeInvoicedBase) then
                    QtyToBeInvoicedBase := RemQtyToBeInvoicedBase - RentalLine."Qty. to Ship (Base)";
                QtyToBeInvoiced := Round(QtyToBeInvoicedBase / RentalShptLine."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision);
            end else begin
                QtyToBeInvoiced := RemQtyToBeInvoiced - RentalLine."Qty. to Ship";
                QtyToBeInvoicedBase := RemQtyToBeInvoicedBase - RentalLine."Qty. to Ship (Base)";
            end;

        if Abs(QtyToBeInvoiced) > Abs(RentalShptLine.Quantity - RentalShptLine."Quantity Invoiced") then begin
            QtyToBeInvoiced := -(RentalShptLine.Quantity - RentalShptLine."Quantity Invoiced");
            QtyToBeInvoicedBase := -(RentalShptLine."Quantity (Base)" - RentalShptLine."Qty. Invoiced (Base)");
        end;
    end;

    local procedure UpdateQtyToBeInvoicedForReturnReceipt(var QtyToBeInvoiced: Decimal; var QtyToBeInvoicedBase: Decimal; TrackingSpecificationExists: Boolean; RentalLine: Record "TWE Rental Line"; ReturnReceiptLine: Record "Return Receipt Line"; InvoicingTrackingSpecification: Record "Tracking Specification")
    begin
        if TrackingSpecificationExists then begin
            QtyToBeInvoiced := InvoicingTrackingSpecification."Qty. to Invoice";
            QtyToBeInvoicedBase := InvoicingTrackingSpecification."Qty. to Invoice (Base)";
            /* end else begin
                QtyToBeInvoiced := RemQtyToBeInvoiced - RentalLine."Return Qty. to Receive";
                QtyToBeInvoicedBase := RemQtyToBeInvoicedBase - RentalLine."Return Qty. to Receive (Base)"; */
        end;
        if Abs(QtyToBeInvoiced) >
           Abs(ReturnReceiptLine.Quantity - ReturnReceiptLine."Quantity Invoiced")
        then begin
            QtyToBeInvoiced := ReturnReceiptLine.Quantity - ReturnReceiptLine."Quantity Invoiced";
            QtyToBeInvoicedBase := ReturnReceiptLine."Quantity (Base)" - ReturnReceiptLine."Qty. Invoiced (Base)";
        end;
    end;

    local procedure UpdateRemainingQtyToBeInvoiced(RentalShptLine: Record "TWE Rental Shipment Line"; var RemQtyToInvoiceCurrLine: Decimal; var RemQtyToInvoiceCurrLineBase: Decimal)
    begin
        RemQtyToInvoiceCurrLine := -RentalShptLine.Quantity + RentalShptLine."Quantity Invoiced";
        RemQtyToInvoiceCurrLineBase := -RentalShptLine."Quantity (Base)" + RentalShptLine."Qty. Invoiced (Base)";
        if RemQtyToInvoiceCurrLine < RemQtyToBeInvoiced then begin
            RemQtyToInvoiceCurrLine := RemQtyToBeInvoiced;
            RemQtyToInvoiceCurrLineBase := RemQtyToBeInvoicedBase;
        end;
    end;

    local procedure IsEndLoopForShippedNotInvoiced(RemQtyToBeInvoiced: Decimal; TrackingSpecificationExists: Boolean; var HasATOShippedNotInvoiced: Boolean; var RentalShptLine: Record "TWE Rental Shipment Line"; var InvoicingTrackingSpecification: Record "Tracking Specification"; var ItemLedgEntryNotInvoiced: Record "Item Ledger Entry"; RentalLine: Record "TWE Rental Line"): Boolean
    begin
        if TrackingSpecificationExists then
            exit((InvoicingTrackingSpecification.Next() = 0) or (RemQtyToBeInvoiced = 0));

        if HasATOShippedNotInvoiced then begin
            HasATOShippedNotInvoiced := ItemLedgEntryNotInvoiced.Next() <> 0;
            if not HasATOShippedNotInvoiced then
                exit(not RentalShptLine.FindSet() or (Abs(RemQtyToBeInvoiced) <= Abs(RentalLine."Qty. to Ship")));
            exit(Abs(RemQtyToBeInvoiced) <= Abs(RentalLine."Qty. to Ship"));
        end;

        exit((RentalShptLine.Next() = 0) or (Abs(RemQtyToBeInvoiced) <= Abs(RentalLine."Qty. to Ship")));
    end;

    procedure SetItemEntryRelation(var ItemEntryRelation: Record "Item Entry Relation"; var RentalShptLine: Record "TWE Rental Shipment Line"; var InvoicingTrackingSpecification: Record "Tracking Specification"; var ItemLedgEntryNotInvoiced: Record "Item Ledger Entry"; TrackingSpecificationExists: Boolean; HasATOShippedNotInvoiced: Boolean)
    begin
        if TrackingSpecificationExists then begin
            ItemEntryRelation.Get(InvoicingTrackingSpecification."Item Ledger Entry No.");
            RentalShptLine.Get(ItemEntryRelation."Source ID", ItemEntryRelation."Source Ref. No.");
        end else
            if HasATOShippedNotInvoiced then begin
                ItemEntryRelation."Item Entry No." := ItemLedgEntryNotInvoiced."Entry No.";
                RentalShptLine.Get(ItemLedgEntryNotInvoiced."Document No.", ItemLedgEntryNotInvoiced."Document Line No.");
            end else
                ItemEntryRelation."Item Entry No." := RentalShptLine."Item Shpt. Entry No.";
    end;

    local procedure PostATOAssocItemJnlLine(RentalHeader: Record "TWE Rental Header"; RentalLine: Record "TWE Rental Line"; var PostedATOLink: Record "Posted Assemble-to-Order Link"; var RemQtyToBeInvoiced: Decimal; var RemQtyToBeInvoicedBase: Decimal)
    var
        DummyTrackingSpecification: Record "Tracking Specification";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        PostingEvents.OnBeforePostATOAssocItemJnlLine(RentalHeader, RentalLine, PostedATOLink, RemQtyToBeInvoiced, RemQtyToBeInvoicedBase, ItemLedgShptEntryNo, IsHandled);
        if IsHandled then
            exit;

        DummyTrackingSpecification.Init();
        if RentalLine."Document Type" = RentalLine."Document Type"::Contract then begin
            PostedATOLink."Assembled Quantity" := -PostedATOLink."Assembled Quantity";
            PostedATOLink."Assembled Quantity (Base)" := -PostedATOLink."Assembled Quantity (Base)";
            if Abs(RemQtyToBeInvoiced) >= Abs(PostedATOLink."Assembled Quantity") then begin
                ItemLedgShptEntryNo :=
                  PostItemJnlLine(
                    RentalHeader, RentalLine,
                    PostedATOLink."Assembled Quantity", PostedATOLink."Assembled Quantity (Base)",
                    PostedATOLink."Assembled Quantity", PostedATOLink."Assembled Quantity (Base)",
                    0, '', DummyTrackingSpecification, true);
                RemQtyToBeInvoiced -= PostedATOLink."Assembled Quantity";
                RemQtyToBeInvoicedBase -= PostedATOLink."Assembled Quantity (Base)";
            end else begin
                if RemQtyToBeInvoiced <> 0 then
                    ItemLedgShptEntryNo :=
                      PostItemJnlLine(
                        RentalHeader, RentalLine,
                        RemQtyToBeInvoiced,
                        RemQtyToBeInvoicedBase,
                        RemQtyToBeInvoiced,
                        RemQtyToBeInvoicedBase,
                        0, '', DummyTrackingSpecification, true);

                ItemLedgShptEntryNo :=
                  PostItemJnlLine(
                    RentalHeader, RentalLine,
                    PostedATOLink."Assembled Quantity" - RemQtyToBeInvoiced,
                    PostedATOLink."Assembled Quantity (Base)" - RemQtyToBeInvoicedBase,
                    0, 0,
                    0, '', DummyTrackingSpecification, true);

                RemQtyToBeInvoiced := 0;
                RemQtyToBeInvoicedBase := 0;
            end;
        end;
    end;

    local procedure GetOpenLinkedATOs(var TempAsmHeader: Record "Assembly Header" temporary)
    var
        TempRentalLine: Record "TWE Rental Line" temporary;
        AsmHeader: Record "Assembly Header";
    begin
        ResetTempLines(TempRentalLine);
        if TempRentalLine.FindSet() then
            repeat
                if TempRentalLine.AsmToOrderExists(AsmHeader) then
                    if AsmHeader.Status = AsmHeader.Status::Open then begin
                        TempAsmHeader.TransferFields(AsmHeader);
                        TempAsmHeader.Insert();
                    end;
            until TempRentalLine.Next() = 0;
    end;

    local procedure ReopenAsmOrders(var TempAsmHeader: Record "Assembly Header" temporary)
    var
        AsmHeader: Record "Assembly Header";
    begin
        if TempAsmHeader.Find('-') then
            repeat
                AsmHeader.Get(TempAsmHeader."Document Type", TempAsmHeader."No.");
                AsmHeader.Status := AsmHeader.Status::Open;
                AsmHeader.Modify();
            until TempAsmHeader.Next() = 0;
    end;

    local procedure InitPostATO(RentalHeader: Record "TWE Rental Header"; var RentalLine: Record "TWE Rental Line")
    var
        AsmHeader: Record "Assembly Header";
        Window: Dialog;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        PostingEvents.OnBeforeInitPostATO(RentalHeader, RentalLine, AsmPost, HideProgressWindow, IsHandled);
        if IsHandled then
            exit;

        if RentalLine.AsmToOrderExists(AsmHeader) then begin
            if not HideProgressWindow then begin
                Window.Open(AssemblyCheckProgressMsg);
                Window.Update(1,
                  StrSubstNo('%1 %2 %3 %4',
                    RentalLine."Document Type", RentalLine."Document No.", RentalLine.FieldCaption("Line No."), RentalLine."Line No."));
                Window.Update(2, StrSubstNo('%1 %2', AsmHeader."Document Type", AsmHeader."No."));
            end;

            RentalLine.CheckAsmToOrder(AsmHeader);
            if not HasQtyToAsm(RentalLine, AsmHeader) then
                exit;

            AsmPost.SetPostingDate(true, RentalHeader."Posting Date");
            AsmPost.InitPostATO(AsmHeader);

            if not HideProgressWindow then
                Window.Close();
        end;
    end;

    local procedure InitPostATOs(RentalHeader: Record "TWE Rental Header")
    var
        TempRentalLine: Record "TWE Rental Line" temporary;
    begin
        FindNotShippedLines(RentalHeader, TempRentalLine);
        TempRentalLine.SetFilter("Qty. to Assemble to Order", '<>0');
        if TempRentalLine.FindSet() then
            repeat
                InitPostATO(RentalHeader, TempRentalLine);
            until TempRentalLine.Next() = 0;
    end;

    local procedure PostATO(RentalHeader: Record "TWE Rental Header"; var RentalLine: Record "TWE Rental Line"; var TempPostedATOLink: Record "Posted Assemble-to-Order Link" temporary)
    var
        AsmHeader: Record "Assembly Header";
        PostedATOLink: Record "Posted Assemble-to-Order Link";
        Window: Dialog;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        PostingEvents.OnBeforePostATO(RentalHeader, RentalLine, TempPostedATOLink, AsmPost, RentalItemJnlPostLine, ResJnlPostLine, WhseJnlPostLine, HideProgressWindow, IsHandled);
        if IsHandled then
            exit;

        if RentalLine.AsmToOrderExists(AsmHeader) then begin
            if not HideProgressWindow then begin
                Window.Open(AssemblyPostProgressMsg);
                Window.Update(1,
                  StrSubstNo('%1 %2 %3 %4',
                    RentalLine."Document Type", RentalLine."Document No.", RentalLine.FieldCaption("Line No."), RentalLine."Line No."));
                Window.Update(2, StrSubstNo('%1 %2', AsmHeader."Document Type", AsmHeader."No."));
            end;

            RentalLine.CheckAsmToOrder(AsmHeader);
            if not HasQtyToAsm(RentalLine, AsmHeader) then
                exit;
            if AsmHeader."Remaining Quantity (Base)" = 0 then
                exit;

            PostedATOLink.Init();
            PostedATOLink."Assembly Document Type" := PostedATOLink."Assembly Document Type"::Assembly;
            PostedATOLink."Assembly Document No." := AsmHeader."Posting No.";
            PostedATOLink."Document Type" := PostedATOLink."Document Type"::"Sales Shipment";
            PostedATOLink."Document No." := RentalHeader."Shipping No.";
            PostedATOLink."Document Line No." := RentalLine."Line No.";

            PostedATOLink."Assembly Order No." := AsmHeader."No.";
            PostedATOLink."Order No." := RentalLine."Document No.";
            PostedATOLink."Order Line No." := RentalLine."Line No.";

            PostedATOLink."Assembled Quantity" := AsmHeader."Quantity to Assemble";
            PostedATOLink."Assembled Quantity (Base)" := AsmHeader."Quantity to Assemble (Base)";

            PostingEvents.OnPostATOOnBeforePostedATOLinkInsert(PostedATOLink, AsmHeader, RentalLine);
            PostedATOLink.Insert();

            TempPostedATOLink := PostedATOLink;
            TempPostedATOLink.Insert();

            //AsmPost.PostATO(AsmHeader, RentalItemJnlPostLine, ResJnlPostLine, WhseJnlPostLine);

            if not HideProgressWindow then
                Window.Close();
        end;
    end;

    local procedure FinalizePostATO(var RentalLine: Record "TWE Rental Line")
    var
        ATOLink: Record "Assemble-to-Order Link";
        AsmHeader: Record "Assembly Header";
        Window: Dialog;
    begin
        if RentalLine.AsmToOrderExists(AsmHeader) then begin
            if not HideProgressWindow then begin
                Window.Open(AssemblyFinalizeProgressMsg);
                Window.Update(1,
                  StrSubstNo('%1 %2 %3 %4',
                    RentalLine."Document Type", RentalLine."Document No.", RentalLine.FieldCaption("Line No."), RentalLine."Line No."));
                Window.Update(2, StrSubstNo('%1 %2', AsmHeader."Document Type", AsmHeader."No."));
            end;

            RentalLine.CheckAsmToOrder(AsmHeader);
            AsmHeader.TestField("Remaining Quantity (Base)", 0);
            AsmPost.FinalizePostATO(AsmHeader);
            ATOLink.Get(AsmHeader."Document Type", AsmHeader."No.");
            ATOLink.Delete();

            if not HideProgressWindow then
                Window.Close();
        end;
    end;

    local procedure CheckATOLink(RentalLine: Record "TWE Rental Line")
    var
        AsmHeader: Record "Assembly Header";
    begin
        if RentalLine."Qty. to Asm. to Order (Base)" = 0 then
            exit;
        if RentalLine.AsmToOrderExists(AsmHeader) then
            RentalLine.CheckAsmToOrder(AsmHeader);
    end;

    local procedure DeleteATOLinks(RentalHeader: Record "TWE Rental Header")
    var
        ATOLink: Record "Assemble-to-Order Link";
    begin
        ATOLink.SetCurrentKey(Type, "Document Type", "Document No.");
        ATOLink.SetRange(Type, ATOLink.Type::Sale);
        ATOLink.SetRange("Document Type", RentalHeader."Document Type");
        ATOLink.SetRange("Document No.", RentalHeader."No.");
        if not ATOLink.IsEmpty() then
            ATOLink.DeleteAll();
    end;

    local procedure HasQtyToAsm(RentalLine: Record "TWE Rental Line"; AsmHeader: Record "Assembly Header"): Boolean
    begin
        if RentalLine."Qty. to Asm. to Order (Base)" = 0 then
            exit(false);
        if RentalLine."Qty. to Ship (Base)" = 0 then
            exit(false);
        if AsmHeader."Quantity to Assemble (Base)" = 0 then
            exit(false);
        exit(true);
    end;

    local procedure GetATOItemLedgEntriesNotInvoiced(RentalLine: Record "TWE Rental Line"; var ItemLedgEntryNotInvoiced: Record "Item Ledger Entry"): Boolean
    var
        PostedATOLink: Record "Posted Assemble-to-Order Link";
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        ItemLedgEntryNotInvoiced.Reset();
        ItemLedgEntryNotInvoiced.DeleteAll();
        //if PostedATOLink.FindLinksFromSalesLine(RentalLine) then
        repeat
            ItemLedgEntry.SetCurrentKey("Document No.", "Document Type", "Document Line No.");
            ItemLedgEntry.SetRange("Document Type", ItemLedgEntry."Document Type"::"Sales Shipment");
            ItemLedgEntry.SetRange("Document No.", PostedATOLink."Document No.");
            ItemLedgEntry.SetRange("Document Line No.", PostedATOLink."Document Line No.");
            ItemLedgEntry.SetRange("Assemble to Order", true);
            ItemLedgEntry.SetRange("Completely Invoiced", false);
            if ItemLedgEntry.FindSet() then
                repeat
                    if ItemLedgEntry.Quantity <> ItemLedgEntry."Invoiced Quantity" then begin
                        ItemLedgEntryNotInvoiced := ItemLedgEntry;
                        ItemLedgEntryNotInvoiced.Insert();
                    end;
                until ItemLedgEntry.Next() = 0;
        until PostedATOLink.Next() = 0;

        exit(ItemLedgEntryNotInvoiced.FindSet());
    end;

    procedure SetWhseJnlRegisterCU(var WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line")
    begin
        WhseJnlPostLine := WhseJnlRegisterLine;
    end;

    local procedure PostWhseShptLines(var WhseShptLine2: Record "Warehouse Shipment Line"; RentalShptLine2: Record "TWE Rental Shipment Line"; var RentalLine2: Record "TWE Rental Line")
    var
        ATOWhseShptLine: Record "Warehouse Shipment Line";
        NonATOWhseShptLine: Record "Warehouse Shipment Line";
        ATOLineFound: Boolean;
        NonATOLineFound: Boolean;
        TotalSalesShptLineQty: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        PostingEvents.OnBeforePostWhseShptLines(WhseShptLine2, RentalShptLine2, RentalLine2, IsHandled);
        if IsHandled then
            exit;

        WhseShptLine2.GetATOAndNonATOLines(ATOWhseShptLine, NonATOWhseShptLine, ATOLineFound, NonATOLineFound);
        if ATOLineFound then
            TotalSalesShptLineQty += ATOWhseShptLine."Qty. to Ship";
        if NonATOLineFound then
            TotalSalesShptLineQty += NonATOWhseShptLine."Qty. to Ship";
        RentalShptLine2.TestField(Quantity, TotalSalesShptLineQty);

        SaveTempWhseSplitSpec(RentalLine2, TempATOTrackingSpecification);
        WhsePostShpt.SetWhseJnlRegisterCU(WhseJnlPostLine);
        if ATOLineFound and (ATOWhseShptLine."Qty. to Ship (Base)" > 0) then
            WhsePostShpt.CreatePostedShptLine(
              ATOWhseShptLine, PostedWhseShptHeader, PostedWhseShptLine, TempWhseSplitSpecification);

        SaveTempWhseSplitSpec(RentalLine2, TempHandlingSpecification);
        if NonATOLineFound and (NonATOWhseShptLine."Qty. to Ship (Base)" > 0) then
            WhsePostShpt.CreatePostedShptLine(
              NonATOWhseShptLine, PostedWhseShptHeader, PostedWhseShptLine, TempWhseSplitSpecification);
    end;

    local procedure GetCountryCode(RentalLine: Record "TWE Rental Line"; RentalHeader: Record "TWE Rental Header"): Code[10]
    var
        RentalShipmentHeader: Record "TWE Rental Shipment Header";
        CountryRegionCode: Code[10];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        PostingEvents.OnBeforeGetCountryCode(RentalHeader, RentalLine, CountryRegionCode, IsHandled);
        if IsHandled then
            exit(CountryRegionCode);

        if RentalLine."Shipment No." <> '' then begin
            RentalShipmentHeader.Get(RentalLine."Shipment No.");
            exit(
              GetCountryRegionCode(
                RentalLine."Rented-to Customer No.",
                RentalShipmentHeader."Ship-to Code",
                RentalShipmentHeader."Rented-to Country/Region Code"));
        end;
        exit(
          GetCountryRegionCode(
            RentalLine."Rented-to Customer No.",
            RentalHeader."Ship-to Code",
            RentalHeader."Rented-to Country/Region Code"));
    end;

    local procedure GetCountryRegionCode(CustNo: Code[20]; ShipToCode: Code[10]; SellToCountryRegionCode: Code[10]): Code[10]
    var
        ShipToAddress: Record "Ship-to Address";
    begin
        if ShipToCode <> '' then begin
            ShipToAddress.Get(CustNo, ShipToCode);
            exit(ShipToAddress."Country/Region Code");
        end;
        exit(SellToCountryRegionCode);
    end;

    local procedure UpdateIncomingDocument(IncomingDocNo: Integer; PostingDate: Date; GenJnlLineDocNo: Code[20])
    var
        IncomingDocument: Record "Incoming Document";
    begin
        IncomingDocument.UpdateIncomingDocumentFromPosting(IncomingDocNo, PostingDate, GenJnlLineDocNo);
    end;

    local procedure CheckItemCharge(ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)")
    var
        SalesLineForCharge: Record "TWE Rental Line";
    begin
        case ItemChargeAssgntSales."Applies-to Doc. Type" of
            ItemChargeAssgntSales."Applies-to Doc. Type"::Order,
          ItemChargeAssgntSales."Applies-to Doc. Type"::Invoice:
                if SalesLineForCharge.Get(
                     ItemChargeAssgntSales."Applies-to Doc. Type",
                     ItemChargeAssgntSales."Applies-to Doc. No.",
                     ItemChargeAssgntSales."Applies-to Doc. Line No.")
                then
                    if (SalesLineForCharge."Quantity (Base)" = SalesLineForCharge."Qty. Shipped (Base)") and
                       (SalesLineForCharge."Qty. Shipped Not Invd. (Base)" = 0)
                    then
                        Error(ReassignItemChargeErr);/* 
                "Applies-to Doc. Type"::"Return Order",
              "Applies-to Doc. Type"::"Credit Memo":
                    if SalesLineForCharge.Get(
                         "Applies-to Doc. Type",
                         "Applies-to Doc. No.",
                         "Applies-to Doc. Line No.")
                    then
                        if (SalesLineForCharge."Quantity (Base)" = SalesLineForCharge."Return Qty. Received (Base)") and
                           (SalesLineForCharge."Ret. Qty. Rcd. Not Invd.(Base)" = 0)
                        then
                            Error(ReassignItemChargeErr); */
        end;
    end;

    local procedure CheckItemReservDisruption(RentalLine: Record "TWE Rental Line")
    var
        ConfirmManagement: Codeunit "Confirm Management";
        AvailableQty: Decimal;
    begin
        if not (RentalLine."Document Type" in [RentalLine."Document Type"::Contract, RentalLine."Document Type"::Invoice]) or
           (RentalLine.Type <> RentalLine.Type::"Rental Item") or not (RentalLine."Qty. to Ship (Base)" > 0)
        then
            exit;
        if RentalLine.Nonstock or RentalLine."Special Order" or RentalLine."Drop Shipment" or RentalLine.FullQtyIsForAsmToOrder or
           TempSKU.Get(RentalLine."Location Code", RentalLine."No.", RentalLine."Variant Code") // Warn against item // IsNonInventoriableItem
        then
            exit;

        MainRentalItem.SetFilter("Location Filter", RentalLine."Location Code");
        //MainRentalItem.SetFilter("Variant Filter", RentalLine."Variant Code");
        MainRentalItem.CalcFields("Reserved Qty. on Inventory", "Net Change");
        RentalLine.CalcFields("Reserved Qty. (Base)");
        AvailableQty := MainRentalItem."Net Change" - (MainRentalItem."Reserved Qty. on Inventory" - RentalLine."Reserved Qty. (Base)");

        if (MainRentalItem."Reserved Qty. on Inventory" > 0) and
           (AvailableQty < RentalLine."Qty. to Ship (Base)") and
           (MainRentalItem."Reserved Qty. on Inventory" > RentalLine."Reserved Qty. (Base)")
        then begin
            InsertTempSKU(RentalLine."Location Code", RentalLine."No.", RentalLine."Variant Code");
            if not ConfirmManagement.GetResponseOrDefault(
                 StrSubstNo(
                   ReservationDisruptedQst, RentalLine.FieldCaption("No."), MainRentalItem."No.", RentalLine.FieldCaption("Location Code"),
                   RentalLine."Location Code", RentalLine.FieldCaption("Variant Code"), RentalLine."Variant Code"), true)
            then
                Error('');
        end;
    end;

    local procedure InsertTempSKU(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10])
    begin
        TempSKU.Init;
        TempSKU."Location Code" := LocationCode;
        TempSKU."Item No." := ItemNo;
        TempSKU."Variant Code" := VariantCode;
        TempSKU.Insert;
    end;

    procedure InitProgressWindow(RentalHeader: Record "TWE Rental Header")
    begin
        if RentalHeader.Invoice then
            Window.Open(
              '#1#################################\\' +
              PostingLinesMsg +
              PostingSalesAndVATMsg +
              PostingCustomersMsg +
              PostingBalAccountMsg)
        else
            Window.Open(
              '#1#################################\\' +
              PostingLines2Msg);

        Window.Update(1, StrSubstNo('%1 %2', RentalHeader."Document Type", RentalHeader."No."));
    end;

    local procedure CheckCertificateOfSupplyStatus(RentalShptHeader: Record "TWE Rental Shipment Header"; RentalShptLine: Record "TWE Rental Shipment Line")
    var
        CertificateOfSupply: Record "Certificate of Supply";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        /*  if RentalShptLine.Quantity <> 0 then
             if VATPostingSetup.Get(RentalShptHeader."VAT Bus. Posting Group", RentalShptLine."VAT Prod. Posting Group") and
                VATPostingSetup."Certificate of Supply Required"
             then //begin
                 CertificateOfSupply.InitFromSales(RentalShptHeader);
                 //CertificateOfSupply.SetRequired(RentalShptHeader."No.");
             //end; */
    end;

    local procedure HasSpecificTracking(ItemNo: Code[20]): Boolean
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        MainRentalItem.Get(ItemNo);
        if MainRentalItem."Item Tracking Code" <> '' then begin
            ItemTrackingCode.Get(MainRentalItem."Item Tracking Code");
            exit(ItemTrackingCode."SN Specific Tracking" or ItemTrackingCode."Lot Specific Tracking");
        end;
    end;

    local procedure HasInvtPickLine(RentalLine: Record "TWE Rental Line"): Boolean
    var
        WhseActivityLine: Record "Warehouse Activity Line";
    begin
        WhseActivityLine.SetRange("Activity Type", WhseActivityLine."Activity Type"::"Invt. Pick");
        WhseActivityLine.SetRange("Source Type", DATABASE::"TWE Rental Line");
        WhseActivityLine.SetRange("Source Subtype", RentalLine."Document Type");
        WhseActivityLine.SetRange("Source No.", RentalLine."Document No.");
        WhseActivityLine.SetRange("Source Line No.", RentalLine."Line No.");
        exit(not WhseActivityLine.IsEmpty);
    end;

    local procedure InsertPostedHeaders(var RentalHeader: Record "TWE Rental Header")
    var
        RentalShptLine: Record "TWE Rental Shipment Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        GenJnlLine: Record "Gen. Journal Line";
        PostingPreviewEventHandler: Codeunit "Posting Preview Event Handler";
        IsHandled: Boolean;
    begin
        if PreviewMode then
            PostingPreviewEventHandler.PreventCommit();

        PostingEvents.OnBeforeInsertPostedHeaders(RentalHeader, TempWhseShptHeader, TempWhseRcptHeader);

        // Insert shipment header
        if RentalHeader.Ship then begin
            if (RentalHeader."Document Type" = RentalHeader."Document Type"::Contract) or
               ((RentalHeader."Document Type" = RentalHeader."Document Type"::Invoice) and RentalSetup."Shipment on Invoice")
            then begin
                if DropShipOrder then begin
                    PurchRcptHeader.LockTable();
                    PurchRcptLine.LockTable();
                    RentalShptHeader.LockTable();
                    RentalShptLine.LockTable();
                end;
                InsertShipmentHeader(RentalHeader, RentalShptHeader);
            end;

            //ServItemMgt.CopyReservationEntry(RentalHeader);
            /*  if ("Document Type" = "Document Type"::Invoice) and
                (not RentalSetup."Shipment on Invoice")
             then
                 ServItemMgt.CreateServItemOnSalesInvoice(RentalHeader); */
        end;

        //ServItemMgt.DeleteServItemOnSaleCreditMemo(RentalHeader);

        // Insert return receipt header
        if RentalHeader.Receive then
            if (RentalHeader."Document Type" = RentalHeader."Document Type"::"Return Shipment") then
                InsertRentalRtnShipHeader(RentalHeader, RentalRtnShipHeader);

        IsHandled := false;
        PostingEvents.OnInsertPostedHeadersOnBeforeInsertInvoiceHeader(RentalHeader, IsHandled);
        if not IsHandled then
            // Insert invoice header or credit memo header
            if RentalHeader.Invoice then
                if RentalHeader."Document Type" in [RentalHeader."Document Type"::Contract, RentalHeader."Document Type"::Invoice] then begin
                    InsertInvoiceHeader(RentalHeader, RentalInvHeader);
                    GenJnlLineDocType := GenJnlLine."Document Type"::Invoice;
                    GenJnlLineDocNo := RentalInvHeader."No.";
                    GenJnlLineExtDocNo := RentalInvHeader."External Document No.";
                end else begin // Credit Memo
                    InsertCrMemoHeader(RentalHeader, RentalCrMemoHeader);
                    GenJnlLineDocType := GenJnlLine."Document Type"::"Credit Memo";
                    GenJnlLineDocNo := RentalCrMemoHeader."No.";
                    GenJnlLineExtDocNo := RentalCrMemoHeader."External Document No.";
                end;

        PostingEvents.OnAfterInsertPostedHeaders(RentalHeader, RentalShptHeader, RentalInvHeader, RentalCrMemoHeader, ReturnRcptHeader);
    end;

    local procedure InsertShipmentHeader(var RentalHeader: Record "TWE Rental Header"; var RentalShptHeader: Record "TWE Rental Shipment Header")
    var
        SalesCommentLine: Record "Sales Comment Line";
        RecordLinkManagement: Codeunit "Record Link Management";
    begin

        RentalShptHeader.Init();
        RentalHeader.CalcFields("Work Description");
        RentalShptHeader.TransferFields(RentalHeader);

        RentalShptHeader."No." := RentalHeader."Shipping No.";
        if RentalHeader."Document Type" = RentalHeader."Document Type"::Contract then begin
            RentalShptHeader."Order No. Series" := RentalHeader."No. Series";
            RentalShptHeader."Order No." := RentalHeader."No.";
            if RentalSetup."Ext. Doc. No. Mandatory" then
                RentalHeader.TestField("External Document No.");
        end;
        RentalShptHeader."Source Code" := SrcCode;
        RentalShptHeader."User ID" := UserId;
        RentalShptHeader."No. Printed" := 0;
        PostingEvents.OnBeforeSalesShptHeaderInsert(RentalShptHeader, RentalHeader, SuppressCommit);
        RentalShptHeader.Insert(true);
        PostingEvents.OnAfterRentalShptHeaderInsert(RentalShptHeader, RentalHeader, SuppressCommit);

        ApprovalsMgmt.PostApprovalEntries(RentalHeader.RecordId, RentalShptHeader.RecordId, RentalShptHeader."No.");

        if RentalSetup."Copy Comments Contr. to Shpt." then begin
            SalesCommentLine.CopyComments(
              RentalHeader."Document Type".AsInteger(), SalesCommentLine."Document Type"::Shipment.AsInteger(), RentalHeader."No.", RentalShptHeader."No.");
            RecordLinkManagement.CopyLinks(RentalHeader, RentalShptHeader);
        end;
        if WhseShip then begin
            WhseShptHeader.Get(TempWhseShptHeader."No.");
            PostingEvents.OnBeforeCreatePostedWhseShptHeader(PostedWhseShptHeader, WhseShptHeader, RentalHeader);
            WhsePostShpt.CreatePostedShptHeader(PostedWhseShptHeader, WhseShptHeader, RentalHeader."Shipping No.", RentalHeader."Posting Date");
        end;
        if WhseReceive then begin
            WhseRcptHeader.Get(TempWhseRcptHeader."No.");
            PostingEvents.OnBeforeCreatePostedWhseRcptHeader(PostedWhseRcptHeader, WhseRcptHeader, RentalHeader);
            WhsePostRcpt.CreatePostedRcptHeader(PostedWhseRcptHeader, WhseRcptHeader, RentalHeader."Shipping No.", RentalHeader."Posting Date");
        end;

    end;

    local procedure InsertRentalRtnShipHeader(var RentalHeader: Record "TWE Rental Header"; var RentalRtnShipHeader: Record "TWE Rental Return Ship. Header")
    var
        SalesCommentLine: Record "Sales Comment Line";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        RecordLinkManagement: Codeunit "Record Link Management";
        IsHandled: Boolean;
    begin
        PostingEvents.OnBeforeInsertReturnReceiptHeader(RentalHeader, RentalRtnShipHeader, IsHandled, SuppressCommit);

        if not IsHandled then begin
            RentalRtnShipHeader.Init();
            RentalRtnShipHeader.TransferFields(RentalHeader);
            RentalRtnShipHeader."No." := NoSeriesMgt.GetNextNo(RentalSetup."Post. Rent. Return Shipm. Nos.", RentalHeader."Posting Date", true);
            RentalRtnShipHeader."No. Series" := RentalSetup."Post. Rent. Return Shipm. Nos.";
            RentalRtnShipHeader."Source Code" := SrcCode;
            RentalRtnShipHeader."User ID" := UserId;
            RentalRtnShipHeader."No. Printed" := 0;
            PostingEvents.OnBeforeRentalRtnShipHeaderInsert(RentalRtnShipHeader, RentalHeader, SuppressCommit);
            RentalRtnShipHeader.Insert(true);
            PostingEvents.OnAfterRentalRtnShipHeaderInsert(RentalRtnShipHeader, RentalHeader, SuppressCommit);

            ApprovalsMgmt.PostApprovalEntries(RentalHeader.RecordId, RentalRtnShipHeader.RecordId, RentalRtnShipHeader."No.");

            /* if RentalSetup."Copy Cmts Ret.Ord. to Ret.Rcpt" then begin
                SalesCommentLine.CopyComments(
                  "Document Type".AsInteger(), SalesCommentLine."Document Type"::"Posted Return Receipt".AsInteger(), "No.", RentalRtnShipHeader."No.");
                RecordLinkManagement.CopyLinks(RentalHeader, RentalRtnShipHeader);
            end; */
        end;

        if WhseReceive then begin
            WhseRcptHeader.Get(TempWhseRcptHeader."No.");
            PostingEvents.OnBeforeCreatePostedWhseRcptHeader(PostedWhseRcptHeader, WhseRcptHeader, RentalHeader);
            WhsePostRcpt.CreatePostedRcptHeader(PostedWhseRcptHeader, WhseRcptHeader, RentalHeader."Return Receipt No.", RentalHeader."Posting Date");
        end;
        if WhseShip then begin
            WhseShptHeader.Get(TempWhseShptHeader."No.");
            PostingEvents.OnBeforeCreatePostedWhseShptHeader(PostedWhseShptHeader, WhseShptHeader, RentalHeader);
            WhsePostShpt.CreatePostedShptHeader(PostedWhseShptHeader, WhseShptHeader, RentalHeader."Return Receipt No.", RentalHeader."Posting Date");
        end;
    end;

    local procedure InsertInvoiceHeader(var RentalHeader: Record "TWE Rental Header"; var RentalInvHeader: Record "TWE Rental Invoice Header")
    var
        RentalCommentLine: Record "TWE Rental Comment Line";
        RecordLinkManagement: Codeunit "Record Link Management";
        SegManagement: Codeunit SegManagement;
    begin
        RentalInvHeader.Init();
        RentalHeader.CalcFields("Work Description");
        RentalInvHeader.TransferFields(RentalHeader);

        RentalInvHeader."No." := RentalHeader."Posting No.";
        if RentalHeader."Document Type" = RentalHeader."Document Type"::Contract then begin
            if RentalSetup."Ext. Doc. No. Mandatory" then
                RentalHeader.TestField("External Document No.");
            RentalInvHeader."Pre-Assigned No. Series" := '';
            RentalInvHeader."Order No. Series" := RentalHeader."No. Series";
            RentalInvHeader."Order No." := RentalHeader."No.";
        end else begin
            if RentalHeader."Posting No." = '' then
                RentalInvHeader."No." := RentalHeader."No.";
            RentalInvHeader."Pre-Assigned No. Series" := RentalHeader."No. Series";
            RentalInvHeader."Pre-Assigned No." := RentalHeader."No.";
        end;
        if GuiAllowed and not HideProgressWindow then
            Window.Update(1, StrSubstNo(InvoiceNoMsg, RentalHeader."Document Type", RentalHeader."No.", RentalInvHeader."No."));
        RentalInvHeader."Source Code" := SrcCode;
        RentalInvHeader."User ID" := UserId;
        RentalInvHeader."No. Printed" := 0;
        RentalInvHeader."Draft Invoice SystemId" := RentalHeader.SystemId;
        SetPaymentInstructions(RentalHeader);
        PostingEvents.OnBeforeSalesInvHeaderInsert(RentalInvHeader, RentalHeader, SuppressCommit);
        RentalInvHeader.Insert(true);
        PostingEvents.OnAfterRentalInvHeaderInsert(RentalInvHeader, RentalHeader, SuppressCommit);

        UpdateWonOpportunities(RentalHeader);
        //SegManagement.CreateCampaignEntryOnSalesInvoicePosting(RentalInvHeader);

        ApprovalsMgmt.PostApprovalEntries(RentalHeader.RecordId, RentalInvHeader.RecordId, RentalInvHeader."No.");

        if RentalSetup."Copy Comments Contract to Inv." then begin
            RentalCommentLine.CopyComments(
              RentalHeader."Document Type".AsInteger(), RentalCommentLine."Document Type"::"Posted Invoice".AsInteger(), RentalHeader."No.", RentalInvHeader."No.");
            RecordLinkManagement.CopyLinks(RentalHeader, RentalInvHeader);
        end;
    end;

    local procedure InsertCrMemoHeader(var RentalHeader: Record "TWE Rental Header"; var RentalCrMemoHeader: Record "TWE Rental Cr.Memo Header")
    var
        RentalCommentLine: Record "TWE Rental Comment Line";
        RecordLinkManagement: Codeunit "Record Link Management";
    begin
        RentalCrMemoHeader.Init();
        RentalHeader.CalcFields("Work Description");
        RentalCrMemoHeader.TransferFields(RentalHeader);
        /*             if "Document Type" = "Document Type"::"Return Order" then begin
                        RentalCrMemoHeader."No." := "Posting No.";
                        if RentalSetup."Ext. Doc. No. Mandatory" then
                            TestField("External Document No.");
                        RentalCrMemoHeader."Pre-Assigned No. Series" := '';
                        RentalCrMemoHeader."Return Order No. Series" := "No. Series";
                        RentalCrMemoHeader."Return Order No." := "No.";
                        if GuiAllowed and not HideProgressWindow then
                            Window.Update(1, StrSubstNo(CreditMemoNoMsg, "Document Type", "No.", RentalCrMemoHeader."No."));
                    end else begin
                        RentalCrMemoHeader."Pre-Assigned No. Series" := "No. Series";
                        RentalCrMemoHeader."Pre-Assigned No." := "No.";
                        if "Posting No." <> '' then begin
                            RentalCrMemoHeader."No." := "Posting No.";
                            if GuiAllowed and not HideProgressWindow then
                                Window.Update(1, StrSubstNo(CreditMemoNoMsg, "Document Type", "No.", RentalCrMemoHeader."No."));
                        end;
                    end; */
        RentalCrMemoHeader."Source Code" := SrcCode;
        RentalCrMemoHeader."User ID" := UserId;
        RentalCrMemoHeader."No. Printed" := 0;
        RentalCrMemoHeader."Draft Cr. Memo SystemId" := RentalCrMemoHeader.SystemId;
        PostingEvents.OnBeforeSalesCrMemoHeaderInsert(RentalCrMemoHeader, RentalHeader, SuppressCommit);
        RentalCrMemoHeader.Insert(true);
        PostingEvents.OnAfterRentalCrMemoHeaderInsert(RentalCrMemoHeader, RentalHeader, SuppressCommit);

        ApprovalsMgmt.PostApprovalEntries(RentalHeader.RecordId, RentalCrMemoHeader.RecordId, RentalCrMemoHeader."No.");

        /* if RentalSetup."Copy Cmts Ret.Ord. to Cr. Memo" then begin
            RentalCommentLine.CopyComments(
              "Document Type".AsInteger(), RentalCommentLine."Document Type"::"Posted Credit Memo".AsInteger(), "No.", RentalCrMemoHeader."No.");
            RecordLinkManagement.CopyLinks(RentalHeader, RentalCrMemoHeader);
        end; */
    end;

    local procedure InsertPurchRcptHeader(var PurchaseHeader: Record "Purchase Header"; var RentalHeader: Record "TWE Rental Header"; var PurchRcptHeader: Record "Purch. Rcpt. Header")
    begin
        PurchRcptHeader.Init;
        PurchRcptHeader.TransferFields(PurchaseHeader);
        PurchRcptHeader."No." := PurchaseHeader."Receiving No.";
        PurchRcptHeader."Order No." := PurchaseHeader."No.";
        PurchRcptHeader."Posting Date" := RentalHeader."Posting Date";
        PurchRcptHeader."Document Date" := RentalHeader."Document Date";
        PurchRcptHeader."No. Printed" := 0;
        PostingEvents.OnBeforePurchRcptHeaderInsert(PurchRcptHeader, PurchaseHeader, RentalHeader, SuppressCommit);
        PurchRcptHeader.Insert;
        PostingEvents.OnAfterPurchRcptHeaderInsert(PurchRcptHeader, PurchaseHeader, RentalHeader, SuppressCommit);
    end;

    local procedure InsertPurchRcptLine(PurchRcptHeader: Record "Purch. Rcpt. Header"; PurchOrderLine: Record "Purchase Line"; DropShptPostBuffer: Record "Drop Shpt. Post. Buffer")
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        PurchRcptLine.Init;
        PurchRcptLine.TransferFields(PurchOrderLine);
        PurchRcptLine."Posting Date" := PurchRcptHeader."Posting Date";
        PurchRcptLine."Document No." := PurchRcptHeader."No.";
        PurchRcptLine.Quantity := DropShptPostBuffer.Quantity;
        PurchRcptLine."Quantity (Base)" := DropShptPostBuffer."Quantity (Base)";
        PurchRcptLine."Quantity Invoiced" := 0;
        PurchRcptLine."Qty. Invoiced (Base)" := 0;
        PurchRcptLine."Order No." := PurchOrderLine."Document No.";
        PurchRcptLine."Order Line No." := PurchOrderLine."Line No.";
        PurchRcptLine."Qty. Rcd. Not Invoiced" := PurchRcptLine.Quantity - PurchRcptLine."Quantity Invoiced";
        if PurchRcptLine.Quantity <> 0 then begin
            PurchRcptLine."Item Rcpt. Entry No." := DropShptPostBuffer."Item Shpt. Entry No.";
            PurchRcptLine."Item Charge Base Amount" := PurchOrderLine."Line Amount"
        end;
        PostingEvents.OnBeforePurchRcptLineInsert(PurchRcptLine, PurchRcptHeader, PurchOrderLine, DropShptPostBuffer, SuppressCommit);
        PurchRcptLine.Insert;
        PostingEvents.OnAfterPurchRcptLineInsert(PurchRcptLine, PurchRcptHeader, PurchOrderLine, DropShptPostBuffer, SuppressCommit);
    end;

    local procedure InsertShipmentLine(RentalHeader: Record "TWE Rental Header"; RentalShptHeader: Record "TWE Rental Shipment Header"; RentalLine: Record "TWE Rental Line"; CostBaseAmount: Decimal; var TempServiceItem2: Record "Service Item" temporary; var TempServiceItemComp2: Record "Service Item Component" temporary)
    var
        RentalShptLine: Record "TWE Rental Shipment Line";
        WhseShptLine: Record "Warehouse Shipment Line";
        WhseRcptLine: Record "Warehouse Receipt Line";
        TempServiceItem1: Record "Service Item" temporary;
        TempServiceItemComp1: Record "Service Item Component" temporary;
        BusinessRentalMgt: Codeunit "TWE Business Rental Mgt.";
    begin
        RentalShptLine.InitFromRentalLine(RentalShptHeader, xRentalLine);
        RentalShptLine."Quantity Invoiced" := -RemQtyToBeInvoiced;
        RentalShptLine."Qty. Invoiced (Base)" := -RemQtyToBeInvoicedBase;
        RentalShptLine."Qty. Shipped Not Invoiced" := RentalShptLine.Quantity - RentalShptLine."Quantity Invoiced";

        if (RentalLine.Type = RentalLine.Type::"Rental Item") and (RentalLine."Qty. to Ship" <> 0) then begin
            if WhseShip then
                if WhseShptLine.GetWhseShptLine(
                     WhseShptHeader."No.", DATABASE::"TWE Rental Line", RentalLine."Document Type".AsInteger(), RentalLine."Document No.", RentalLine."Line No.")
                then
                    PostWhseShptLines(WhseShptLine, RentalShptLine, RentalLine);

            if WhseReceive then
                if WhseRcptLine.GetWhseRcptLine(
                     WhseRcptHeader."No.", DATABASE::"TWE Rental Line", RentalLine."Document Type".AsInteger(), RentalLine."Document No.", RentalLine."Line No.")
                then
                    PostWhseRcptLineFromShipmentLine(WhseRcptLine, RentalLine, RentalShptLine);

            if not RentalHeader.IsCreditDocType() then
                BusinessRentalMgt.ChangeRentItemRentedState(RentalLine."Rental Item", true);

            RentalShptLine."Item Shpt. Entry No." :=
              InsertShptEntryRelation(RentalShptLine); // ItemLedgShptEntryNo
            RentalShptLine."Item Charge Base Amount" :=
              Round(CostBaseAmount / RentalLine.Quantity * RentalShptLine.Quantity);
        end;
        PostingEvents.OnBeforeSalesShptLineInsert(
          RentalShptLine, RentalShptHeader, RentalLine, SuppressCommit, PostedWhseShptLine, RentalHeader, WhseShip, WhseReceive,
          ItemLedgShptEntryNo);
        RentalShptLine.Insert(true);
        PostingEvents.OnAfterRentalShptLineInsert(
          RentalShptLine, RentalLine, ItemLedgShptEntryNo, WhseShip, WhseReceive, SuppressCommit, RentalInvHeader);

        CheckCertificateOfSupplyStatus(RentalShptHeader, RentalShptLine);

        PostingEvents.OnInvoiceRentalShptLine(RentalShptLine, RentalShptHeader."No.", xRentalLine."Line No.", xRentalLine."Qty. to Invoice", SuppressCommit);

        //ServItemMgt.CreateServItemOnSalesLineShpt(RentalHeader, xRentalLine, RentalShptLine);
        if RentalLine."BOM Item No." <> '' then begin
            ServItemMgt.ReturnServItemComp(TempServiceItem1, TempServiceItemComp1);
            if TempServiceItem1.FindSet() then
                repeat
                    TempServiceItem2 := TempServiceItem1;
                    if TempServiceItem2.Insert() then;
                until TempServiceItem1.Next() = 0;
            if TempServiceItemComp1.FindSet() then
                repeat
                    TempServiceItemComp2 := TempServiceItemComp1;
                    if TempServiceItemComp2.Insert() then;
                until TempServiceItemComp1.Next() = 0;
        end;
    end;

    local procedure PostWhseRcptLineFromShipmentLine(var WhseRcptLine: Record "Warehouse Receipt Line"; var RentalLine: Record "TWE Rental Line"; var RentalShptLine: Record "TWE Rental Shipment Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        PostingEvents.OnBeforePostWhseRcptLineFromShipmentLine(WhseRcptLine, RentalShptLine, RentalLine, IsHandled);
        if IsHandled then
            exit;

        WhseRcptLine.TestField("Qty. to Receive", -RentalShptLine.Quantity);
        SaveTempWhseSplitSpec(RentalLine, TempHandlingSpecification);
        WhsePostRcpt.CreatePostedRcptLine(
          WhseRcptLine, PostedWhseRcptHeader, PostedWhseRcptLine, TempWhseSplitSpecification);
    end;

    local procedure InsertRentalRtnShipLine(RentalReturnShipHeader: Record "TWE Rental Return Ship. Header"; RentalLine: Record "TWE Rental Line"; CostBaseAmount: Decimal)
    var
        RentalRtnShipLine: Record "TWE Rental Return Ship. Line";
        WhseShptLine: Record "Warehouse Shipment Line";
        WhseRcptLine: Record "Warehouse Receipt Line";
        BusinessRentalMgt: Codeunit "TWE Business Rental Mgt.";
    begin
        PostingEvents.OnBeforeInsertRentalRtnShipLine(RentalLine, RentalRtnShipLine, RemQtyToBeInvoiced, RemQtyToBeInvoicedBase);
        RentalRtnShipLine.InitFromRentalLine(RentalReturnShipHeader, xRentalLine);

        if (RentalLine.Type = RentalLine.Type::"Rental Item") then begin //  and (RentalLine."Return Qty. to Receive" <> 0)
            if WhseReceive then
                if WhseRcptLine.GetWhseRcptLine(
                     WhseRcptHeader."No.", DATABASE::"TWE Rental Line", RentalLine."Document Type".AsInteger(), RentalLine."Document No.", RentalLine."Line No.")
                then begin
                    WhseRcptLine.TestField("Qty. to Receive", RentalRtnShipLine.Quantity);
                    SaveTempWhseSplitSpec(RentalLine, TempHandlingSpecification);
                    WhsePostRcpt.CreatePostedRcptLine(
                      WhseRcptLine, PostedWhseRcptHeader, PostedWhseRcptLine, TempWhseSplitSpecification);
                end;

            if WhseShip then
                if WhseShptLine.GetWhseShptLine(
                     WhseShptHeader."No.", DATABASE::"Sales Line", RentalLine."Document Type".AsInteger(), RentalLine."Document No.", RentalLine."Line No.")
                then begin
                    WhseShptLine.TestField("Qty. to Ship", -RentalRtnShipLine.Quantity);
                    SaveTempWhseSplitSpec(RentalLine, TempHandlingSpecification);
                    WhsePostShpt.SetWhseJnlRegisterCU(WhseJnlPostLine);
                    WhsePostShpt.CreatePostedShptLine(
                      WhseShptLine, PostedWhseShptHeader, PostedWhseShptLine, TempWhseSplitSpecification);
                end;


            BusinessRentalMgt.ChangeRentItemRentedState(RentalLine."Rental Item", false);
        end;

        PostingEvents.OnBeforeRentalRtnShipLineInsert(RentalRtnShipLine, RentalReturnShipHeader, RentalLine, SuppressCommit);
        RentalRtnShipLine.Insert(true);
        PostingEvents.OnAfterRentalRtnShipLineInsert(
          RentalRtnShipLine, RentalReturnShipHeader, RentalLine, ItemLedgShptEntryNo, WhseShip, WhseReceive, SuppressCommit, RentalCrMemoHeader);
    end;

    local procedure setQuanityReturnedInContract(rentalLine: Record "TWE Rental Line")
    var
        contractLine: Record "TWE Rental Line";
        rentalHeader: Record "TWE Rental Header";
    begin
        rentalHeader.Get(rentalLine."Document Type", rentalLine."Document No.");
        contractLine.SetRange("Document Type", contractLine."Document Type"::Contract);
        contractLine.SetRange("Document No.", rentalHeader."Belongs to Rental Contract");
        contractLine.SetRange("Rental Item", rentalLine."Rental Item");
        if contractLine.FindFirst() then begin
            contractLine."Quantity Returned" += 1;
            contractLine.Modify();
        end;
    end;


    local procedure CheckICPartnerBlocked(RentalHeader: Record "TWE Rental Header")
    var
        ICPartner: Record "IC Partner";
    begin
        if RentalHeader."Rented-to IC Partner Code" <> '' then
            if ICPartner.Get(RentalHeader."Rented-to IC Partner Code") then
                ICPartner.TestField(Blocked, false);
        if RentalHeader."Bill-to IC Partner Code" <> '' then
            if ICPartner.Get(RentalHeader."Bill-to IC Partner Code") then
                ICPartner.TestField(Blocked, false);
    end;

    local procedure SendICDocument(var RentalHeader: Record "TWE Rental Header"; var ModifyHeader: Boolean)
    var
        ICInboxOutboxMgt: Codeunit ICInboxOutboxMgt;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        PostingEvents.OnBeforeSendICDocument(RentalHeader, ModifyHeader, IsHandled);
        if IsHandled then
            exit;

        if RentalHeader."Send IC Document" and (RentalHeader."IC Status" = RentalHeader."IC Status"::New) and (RentalHeader."IC Direction" = RentalHeader."IC Direction"::Outgoing) and
           (RentalHeader."Document Type" in [RentalHeader."Document Type"::Contract])
        then begin
            //ICInboxOutboxMgt.SendSalesDoc(RentalHeader, true);
            IsHandled := false;
            PostingEvents.OnSendICDocumentOnBeforeSetICStatus(RentalHeader, IsHandled);
            if not IsHandled then
                RentalHeader."IC Status" := RentalHeader."IC Status"::Pending;
            ModifyHeader := true;
        end;
    end;

    local procedure UpdateHandledICInboxTransaction(RentalHeader: Record "TWE Rental Header")
    var
        HandledICInboxTrans: Record "Handled IC Inbox Trans.";
        Customer: Record Customer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        PostingEvents.OnBeforeUpdateHandledICInboxTransaction(RentalHeader, IsHandled);
        if IsHandled then
            exit;

        if RentalHeader."IC Direction" = RentalHeader."IC Direction"::Incoming then begin
            HandledICInboxTrans.SetRange("Document No.", RentalHeader."External Document No.");
            Customer.Get(RentalHeader."Rented-to Customer No.");
            HandledICInboxTrans.SetRange("IC Partner Code", Customer."IC Partner Code");
            HandledICInboxTrans.LockTable();
            if HandledICInboxTrans.FindFirst() then begin
                HandledICInboxTrans.Status := HandledICInboxTrans.Status::Posted;
                HandledICInboxTrans.Modify();
            end;
        end;
    end;

    procedure GetPostedDocumentRecord(RentalHeader: Record "TWE Rental Header"; var PostedSalesDocumentVariant: Variant)
    var
        RentalInvHeader: Record "TWE Rental Invoice Header";
        RentalCrMemoHeader: Record "TWE Rental Cr.Memo Header";
        IsHandled: Boolean;
    begin
        case RentalHeader."Document Type" of
            RentalHeader."Document Type"::Contract:
                if RentalHeader.Invoice then begin
                    RentalInvHeader.Get(RentalHeader."Last Posting No.");
                    RentalInvHeader.SetRecFilter();
                    PostedSalesDocumentVariant := RentalInvHeader;
                end;
            RentalHeader."Document Type"::Invoice:
                begin
                    if RentalHeader."Last Posting No." = '' then
                        RentalInvHeader.Get(RentalHeader."No.")
                    else
                        RentalInvHeader.Get(RentalHeader."Last Posting No.");

                    RentalInvHeader.SetRecFilter();
                    PostedSalesDocumentVariant := RentalInvHeader;
                end;
            RentalHeader."Document Type"::"Credit Memo":
                begin
                    if RentalHeader."Last Posting No." = '' then
                        RentalCrMemoHeader.Get(RentalHeader."No.")
                    else
                        RentalCrMemoHeader.Get(RentalHeader."Last Posting No.");
                    RentalCrMemoHeader.SetRecFilter();
                    PostedSalesDocumentVariant := RentalCrMemoHeader;
                end;
            /*                 "Document Type"::"Return Order":
                                if RentalHeader.Invoice then begin
                                    if "Last Posting No." = '' then
                                        RentalCrMemoHeader.Get(RentalHeader."No.")
                                    else
                                        RentalCrMemoHeader.Get("Last Posting No.");
                                    RentalCrMemoHeader.SetRecFilter();
                                    PostedSalesDocumentVariant := RentalCrMemoHeader;
                                end; */
            else begin
                    IsHandled := false;
                    PostingEvents.OnGetPostedDocumentRecordElseCase(RentalHeader, PostedSalesDocumentVariant, IsHandled);
                    if not IsHandled then
                        Error(NotSupportedDocumentTypeErr, RentalHeader."Document Type");
                end;
        end;
    end;

    local procedure MakeInventoryAdjustment()
    var
        InvtSetup: Record "Inventory Setup";
        InvtAdjmt: Codeunit "Inventory Adjustment";
    begin
        InvtSetup.Get();
        if InvtSetup."Automatic Cost Adjustment" <>
           InvtSetup."Automatic Cost Adjustment"::Never
        then begin
            InvtAdjmt.SetProperties(true, InvtSetup."Automatic Cost Posting");
            InvtAdjmt.SetJobUpdateProperties(true);
            InvtAdjmt.MakeMultiLevelAdjmt;
        end;
    end;

    local procedure FindNotShippedLines(RentalHeader: Record "TWE Rental Header"; var TempRentalLine: Record "TWE Rental Line" temporary)
    begin
        ResetTempLines(TempRentalLine);
        TempRentalLine.SetFilter(Quantity, '<>0');
        if RentalHeader."Document Type" = RentalHeader."Document Type"::Contract then
            TempRentalLine.SetFilter("Qty. to Ship", '<>0');
        TempRentalLine.SetRange("Shipment No.", '');
    end;

    local procedure CheckTrackingAndWarehouseForShip(RentalHeader: Record "TWE Rental Header") Ship: Boolean
    var
        TempRentalLine: Record "TWE Rental Line" temporary;
    begin
        FindNotShippedLines(RentalHeader, TempRentalLine);
        Ship := TempRentalLine.FindFirst;
        WhseShip := TempWhseShptHeader.FindFirst();
        WhseReceive := TempWhseRcptHeader.FindFirst();
        PostingEvents.OnCheckTrackingAndWarehouseForShipOnBeforeCheck(RentalHeader, TempWhseShptHeader, TempWhseRcptHeader, Ship, TempRentalLine);
        if Ship then begin
            CheckTrackingSpecification(RentalHeader, TempRentalLine);
            if not (WhseShip or WhseReceive or InvtPickPutaway) then
                CheckWarehouse(TempRentalLine);
        end;
        PostingEvents.OnAfterCheckTrackingAndWarehouseForShip(RentalHeader, Ship, SuppressCommit, TempWhseShptHeader, TempWhseRcptHeader, TempRentalLine);
        exit(Ship);
    end;

    local procedure CheckTrackingAndWarehouseForReceive(RentalHeader: Record "TWE Rental Header") Receive: Boolean
    var
        TempRentalLine: Record "TWE Rental Line" temporary;
    begin
        ResetTempLines(TempRentalLine);
        TempRentalLine.SetFilter(Quantity, '<>0');
        //TempRentalLine.SetFilter("Return Qty. to Receive", '<>0');
        TempRentalLine.SetRange("Return Receipt No.", '');
        Receive := TempRentalLine.FindFirst;
        WhseShip := TempWhseShptHeader.FindFirst();
        WhseReceive := TempWhseRcptHeader.FindFirst();
        PostingEvents.OnCheckTrackingAndWarehouseForReceiveOnBeforeCheck(RentalHeader, TempWhseShptHeader, TempWhseRcptHeader, Receive);
        if Receive then begin
            CheckTrackingSpecification(RentalHeader, TempRentalLine);
            if not (WhseReceive or WhseShip or InvtPickPutaway) then
                CheckWarehouse(TempRentalLine);
        end;
        PostingEvents.OnAfterCheckTrackingAndWarehouseForReceive(RentalHeader, Receive, SuppressCommit, TempWhseShptHeader, TempWhseRcptHeader);
        exit(Receive);
    end;

    local procedure CheckIfInvPickExists(RentalHeader: Record "TWE Rental Header"): Boolean
    var
        TempRentalLine: Record "TWE Rental Line" temporary;
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin

        FindNotShippedLines(RentalHeader, TempRentalLine);
        if TempRentalLine.IsEmpty() then
            exit(false);
        TempRentalLine.FindSet();
        repeat
            if WarehouseActivityLine.ActivityExists(
                 DATABASE::"Sales Line", TempRentalLine."Document Type".AsInteger(), TempRentalLine."Document No.", TempRentalLine."Line No.", 0,
                 WarehouseActivityLine."Activity Type"::"Invt. Pick")
            then
                exit(true);
        until TempRentalLine.Next() = 0;
        exit(false);

    end;

    local procedure CheckIfInvPutawayExists(): Boolean
    var
        TempRentalLine: Record "TWE Rental Line" temporary;
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        ResetTempLines(TempRentalLine);
        TempRentalLine.SetFilter(Quantity, '<>0');
        //SetFilter("Return Qty. to Receive", '<>0');
        TempRentalLine.SetRange("Return Receipt No.", '');
        if TempRentalLine.IsEmpty() then
            exit(false);
        TempRentalLine.FindSet();
        repeat
            if WarehouseActivityLine.ActivityExists(
                 DATABASE::"TWE Rental Line", TempRentalLine."Document Type".AsInteger(), TempRentalLine."Document No.", TempRentalLine."Line No.", 0,
                 WarehouseActivityLine."Activity Type"::"Invt. Put-away")
            then
                exit(true);
        until TempRentalLine.Next() = 0;
        exit(false);
    end;

    local procedure CalcInvoiceDiscountPosting(RentalHeader: Record "TWE Rental Header"; RentalLine: Record "TWE Rental Line"; RentalLineACY: Record "TWE Rental Line"; var InvoicePostBuffer: Record "Invoice Post. Buffer")
    begin
        if RentalLine."VAT Calculation Type" = RentalLine."VAT Calculation Type"::"Reverse Charge VAT" then
            InvoicePostBuffer.CalcDiscountNoVAT(-RentalLine."Inv. Discount Amount", -RentalLineACY."Inv. Discount Amount")
        else
            InvoicePostBuffer.CalcDiscount(
              RentalHeader."Prices Including VAT", -RentalLine."Inv. Discount Amount", -RentalLineACY."Inv. Discount Amount");
    end;

    local procedure CalcLineDiscountPosting(RentalHeader: Record "TWE Rental Header"; RentalLine: Record "TWE Rental Line"; RentalLineACY: Record "TWE Rental Line"; var InvoicePostBuffer: Record "Invoice Post. Buffer")
    begin
        if RentalLine."VAT Calculation Type" = RentalLine."VAT Calculation Type"::"Reverse Charge VAT" then
            InvoicePostBuffer.CalcDiscountNoVAT(-RentalLine."Line Discount Amount", -RentalLineACY."Line Discount Amount")
        else
            InvoicePostBuffer.CalcDiscount(
              RentalHeader."Prices Including VAT", -RentalLine."Line Discount Amount", -RentalLineACY."Line Discount Amount");
    end;

    local procedure FindTempItemChargeAssgntSales(SalesLineNo: Integer): Boolean
    begin
        ClearItemChargeAssgntFilter;
        TempItemChargeAssgntSales.SetCurrentKey("Applies-to Doc. Type");
        TempItemChargeAssgntSales.SetRange("Document Line No.", SalesLineNo);
        exit(TempItemChargeAssgntSales.FindSet());
    end;

    local procedure UpdateInvoicedQtyOnShipmentLine(var RentalShptLine: Record "TWE Rental Shipment Line"; QtyToBeInvoiced: Decimal; QtyToBeInvoicedBase: Decimal)
    begin
        RentalShptLine."Quantity Invoiced" := RentalShptLine."Quantity Invoiced" - QtyToBeInvoiced;
        RentalShptLine."Qty. Invoiced (Base)" := RentalShptLine."Qty. Invoiced (Base)" - QtyToBeInvoicedBase;
        RentalShptLine."Qty. Shipped Not Invoiced" := RentalShptLine.Quantity - RentalShptLine."Quantity Invoiced";
        RentalShptLine.Modify();
    end;

    procedure SetPreviewMode(NewPreviewMode: Boolean)
    begin
        PreviewMode := NewPreviewMode;
    end;

    local procedure PostDropOrderShipment(var RentalHeader: Record "TWE Rental Header"; var TempDropShptPostBuffer: Record "Drop Shpt. Post. Buffer" temporary)
    var
        PurchSetup: Record "Purchases & Payables Setup";
        PurchCommentLine: Record "Purch. Comment Line";
        PurchOrderHeader: Record "Purchase Header";
        PurchOrderLine: Record "Purchase Line";
        RecordLinkManagement: Codeunit "Record Link Management";
    begin
        PostingEvents.OnBeforePostDropOrderShipment(RentalHeader, TempDropShptPostBuffer);

        ArchivePurchaseOrders(TempDropShptPostBuffer);

        if TempDropShptPostBuffer.FindSet() then begin
            PurchSetup.Get();
            repeat
                PurchOrderHeader.Get(PurchOrderHeader."Document Type"::Order, TempDropShptPostBuffer."Order No.");
                InsertPurchRcptHeader(PurchOrderHeader, RentalHeader, PurchRcptHeader);
                ApprovalsMgmt.PostApprovalEntries(RentalHeader.RecordId, PurchRcptHeader.RecordId, PurchRcptHeader."No.");
                if PurchSetup."Copy Comments Order to Receipt" then begin
                    PurchCommentLine.CopyComments(
                      PurchOrderHeader."Document Type".AsInteger(), PurchCommentLine."Document Type"::Receipt.AsInteger(),
                      PurchOrderHeader."No.", PurchRcptHeader."No.");
                    RecordLinkManagement.CopyLinks(PurchOrderHeader, PurchRcptHeader);
                end;
                TempDropShptPostBuffer.SetRange("Order No.", TempDropShptPostBuffer."Order No.");
                repeat
                    PurchOrderLine.Get(
                      PurchOrderLine."Document Type"::Order,
                      TempDropShptPostBuffer."Order No.", TempDropShptPostBuffer."Order Line No.");
                    InsertPurchRcptLine(PurchRcptHeader, PurchOrderLine, TempDropShptPostBuffer);
                    PurchPost.UpdateBlanketOrderLine(PurchOrderLine, true, false, false);
                until TempDropShptPostBuffer.Next() = 0;
                TempDropShptPostBuffer.SetRange("Order No.");
                PostingEvents.OnAfterInsertDropOrderPurchRcptHeader(PurchRcptHeader);
            until TempDropShptPostBuffer.Next() = 0;
        end;
    end;

    local procedure PostInvoicePostBuffer(RentalHeader: Record "TWE Rental Header"; var TempInvoicePostBuffer: Record "Invoice Post. Buffer" temporary)
    var
        LineCount: Integer;
        GLEntryNo: Integer;
    begin
        PostingEvents.OnBeforePostInvoicePostBuffer(RentalHeader, TempInvoicePostBuffer, TotalRentalLine, TotalRentalLineLCY);

        LineCount := 0;
        if TempInvoicePostBuffer.Find('+') then
            repeat
                LineCount := LineCount + 1;
                if GuiAllowed and not HideProgressWindow then
                    Window.Update(3, LineCount);

                GLEntryNo := PostInvoicePostBufferLine(RentalHeader, TempInvoicePostBuffer);

                if (TempInvoicePostBuffer."Job No." <> '') and
                   (TempInvoicePostBuffer.Type = TempInvoicePostBuffer.Type::"G/L Account")
                then
                    JobPostLine.PostSalesGLAccounts(TempInvoicePostBuffer, GLEntryNo);

            until TempInvoicePostBuffer.Next(-1) = 0;

        TempInvoicePostBuffer.DeleteAll();
    end;

    local procedure PostInvoicePostBufferLine(RentalHeader: Record "TWE Rental Header"; InvoicePostBuffer: Record "Invoice Post. Buffer") GLEntryNo: Integer
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin

        GenJnlLine.InitNewLine(
            RentalHeader."Posting Date", RentalHeader."Document Date", InvoicePostBuffer."Entry Description",
            InvoicePostBuffer."Global Dimension 1 Code", InvoicePostBuffer."Global Dimension 2 Code",
            InvoicePostBuffer."Dimension Set ID", RentalHeader."Reason Code");

        GenJnlLine.CopyDocumentFields(GenJnlLineDocType, GenJnlLineDocNo, GenJnlLineExtDocNo, SrcCode, '');

        GenJnlLine.CopyFromRentalHeader(RentalHeader);

        GenJnlLine.CopyFromInvoicePostBuffer(InvoicePostBuffer);
        if InvoicePostBuffer.Type <> InvoicePostBuffer.Type::"Prepmt. Exch. Rate Difference" then
            GenJnlLine."Gen. Posting Type" := GenJnlLine."Gen. Posting Type"::Sale;
        if InvoicePostBuffer.Type = InvoicePostBuffer.Type::"Fixed Asset" then begin
            GenJnlLine."FA Posting Type" := GenJnlLine."FA Posting Type"::Disposal;
            GenJnlLine.CopyFromInvoicePostBufferFA(InvoicePostBuffer);
        end;

        PostingEvents.OnBeforePostInvPostBuffer(GenJnlLine, InvoicePostBuffer, RentalHeader, SuppressCommit, GenJnlPostLine, PreviewMode);
        GLEntryNo := RunGenJnlPostLine(GenJnlLine);
        PostingEvents.OnAfterPostInvPostBuffer(GenJnlLine, InvoicePostBuffer, RentalHeader, GLEntryNo, SuppressCommit, GenJnlPostLine);

    end;

    local procedure PostItemTracking(RentalHeader: Record "TWE Rental Header"; RentalLine: Record "TWE Rental Line"; TrackingSpecificationExists: Boolean; var TempTrackingSpecification: Record "Tracking Specification" temporary; var TempItemLedgEntryNotInvoiced: Record "Item Ledger Entry" temporary; HasATOShippedNotInvoiced: Boolean)
    var
        QtyToInvoiceBaseInTrackingSpec: Decimal;
    begin
        if TrackingSpecificationExists then begin
            TempTrackingSpecification.CalcSums("Qty. to Invoice (Base)");
            QtyToInvoiceBaseInTrackingSpec := TempTrackingSpecification."Qty. to Invoice (Base)";
            if not TempTrackingSpecification.FindFirst() then
                TempTrackingSpecification.Init();
        end;

        if not RentalLine.IsCreditDocType then begin
            if (Abs(RemQtyToBeInvoiced) > Abs(RentalLine."Qty. to Ship")) or
               (Abs(RemQtyToBeInvoiced) >= Abs(QtyToInvoiceBaseInTrackingSpec)) and (QtyToInvoiceBaseInTrackingSpec <> 0)
            then
                PostItemTrackingForShipment(
                  RentalHeader, RentalLine, TrackingSpecificationExists, TempTrackingSpecification,
                  TempItemLedgEntryNotInvoiced, HasATOShippedNotInvoiced);

            PostItemTrackingCheckShipment(RentalLine, RemQtyToBeInvoiced);
        end;
    end;

    local procedure PostItemTrackingCheckShipment(RentalLine: Record "TWE Rental Line"; RemQtyToBeInvoiced: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        PostingEvents.OnBeforePostItemTrackingCheckShipment(RentalLine, RemQtyToBeInvoiced, IsHandled);
        if IsHandled then
            exit;

        if Abs(RemQtyToBeInvoiced) > Abs(RentalLine."Qty. to Ship") then begin
            if RentalLine."Document Type" = RentalLine."Document Type"::Invoice then
                Error(QuantityToInvoiceGreaterErr, RentalLine."Shipment No.");
            Error(ShipmentLinesDeletedErr);
        end;
    end;

    local procedure PostItemTrackingForShipment(RentalHeader: Record "TWE Rental Header"; RentalLine: Record "TWE Rental Line"; TrackingSpecificationExists: Boolean; var TempTrackingSpecification: Record "Tracking Specification" temporary; var TempItemLedgEntryNotInvoiced: Record "Item Ledger Entry" temporary; HasATOShippedNotInvoiced: Boolean)
    var
        ItemEntryRelation: Record "Item Entry Relation";
        RentalShptLine: Record "TWE Rental Shipment Line";
        RemQtyToInvoiceCurrLine: Decimal;
        RemQtyToInvoiceCurrLineBase: Decimal;
        QtyToBeInvoiced: Decimal;
        QtyToBeInvoicedBase: Decimal;
        IsHandled: Boolean;
    begin
        RentalShptLine.Reset();
        case RentalHeader."Document Type" of
            RentalHeader."Document Type"::Contract:
                begin
                    RentalShptLine.SetCurrentKey("Order No.", "Order Line No.");
                    RentalShptLine.SetRange("Order No.", RentalLine."Document No.");
                    RentalShptLine.SetRange("Order Line No.", RentalLine."Line No.");
                end;
            RentalHeader."Document Type"::Invoice:
                begin
                    RentalShptLine.SetRange("Document No.", RentalLine."Shipment No.");
                    RentalShptLine.SetRange("Line No.", RentalLine."Shipment Line No.");
                end;
        end;

        if not TrackingSpecificationExists then
            HasATOShippedNotInvoiced := GetATOItemLedgEntriesNotInvoiced(RentalLine, TempItemLedgEntryNotInvoiced);

        RentalShptLine.SetFilter("Qty. Shipped Not Invoiced", '<>0');
        PostingEvents.OnPostItemTrackingForShipmentOnAfterSetFilters(RentalShptLine, RentalHeader, RentalLine);
        if RentalShptLine.FindFirst() then begin
            ItemJnlRollRndg := true;
            repeat
                SetItemEntryRelation(
                  ItemEntryRelation, RentalShptLine,
                  TempTrackingSpecification, TempItemLedgEntryNotInvoiced,
                  TrackingSpecificationExists, HasATOShippedNotInvoiced);

                UpdateRemainingQtyToBeInvoiced(RentalShptLine, RemQtyToInvoiceCurrLine, RemQtyToInvoiceCurrLineBase);

                RentalShptLine.TestField("Rented-to Customer No.", RentalLine."Rented-to Customer No.");
                RentalShptLine.TestField(Type, RentalLine.Type);
                RentalShptLine.TestField("No.", RentalLine."No.");
                RentalShptLine.TestField("Gen. Bus. Posting Group", RentalLine."Gen. Bus. Posting Group");
                RentalShptLine.TestField("Gen. Prod. Posting Group", RentalLine."Gen. Prod. Posting Group");
                //RentalShptLine.TestField("Job No.", RentalLine."Job No.");
                RentalShptLine.TestField("Unit of Measure Code", RentalLine."Unit of Measure Code");
                RentalShptLine.TestField("Variant Code", RentalLine."Variant Code");
                if -RentalLine."Qty. to Invoice" * RentalShptLine.Quantity < 0 then
                    RentalLine.FieldError("Qty. to Invoice", ShipmentSameSignErr);

                UpdateQtyToBeInvoicedForShipment(
                  QtyToBeInvoiced, QtyToBeInvoicedBase,
                  TrackingSpecificationExists, HasATOShippedNotInvoiced,
                  RentalLine, RentalShptLine,
                  TempTrackingSpecification, TempItemLedgEntryNotInvoiced);

                if TrackingSpecificationExists then begin
                    TempTrackingSpecification."Quantity actual Handled (Base)" := QtyToBeInvoicedBase;
                    TempTrackingSpecification.Modify();
                end;

                if TrackingSpecificationExists or HasATOShippedNotInvoiced then
                    ItemTrackingMgt.AdjustQuantityRounding(
                      RemQtyToInvoiceCurrLine, QtyToBeInvoiced,
                      RemQtyToInvoiceCurrLineBase, QtyToBeInvoicedBase);

                RemQtyToBeInvoiced := RemQtyToBeInvoiced - QtyToBeInvoiced;
                RemQtyToBeInvoicedBase := RemQtyToBeInvoicedBase - QtyToBeInvoicedBase;
                PostingEvents.OnBeforeUpdateInvoicedQtyOnShipmentLine(RentalShptLine, RentalLine, RentalHeader, RentalInvHeader, SuppressCommit);
                UpdateInvoicedQtyOnShipmentLine(RentalShptLine, QtyToBeInvoiced, QtyToBeInvoicedBase);
                PostingEvents.OnInvoiceRentalShptLine(RentalShptLine, RentalInvHeader."No.", RentalLine."Line No.", -QtyToBeInvoiced, SuppressCommit);

                PostingEvents.OnBeforePostItemTrackingForShipment(
                  RentalInvHeader, RentalShptLine, TempTrackingSpecification, TrackingSpecificationExists, RentalLine,
                  QtyToBeInvoiced, QtyToBeInvoicedBase);

                if PostItemTrackingForShipmentCondition(RentalLine, RentalShptLine) then
                    PostItemJnlLine(
                      RentalHeader, RentalLine, 0, 0, QtyToBeInvoiced, QtyToBeInvoicedBase,
                      ItemEntryRelation."Item Entry No.", '', TempTrackingSpecification, false);

                PostingEvents.OnAfterPostItemTrackingForShipment(
                  RentalInvHeader, RentalShptLine, TempTrackingSpecification, TrackingSpecificationExists, RentalLine,
                  QtyToBeInvoiced, QtyToBeInvoicedBase);
            until IsEndLoopForShippedNotInvoiced(
                    RemQtyToBeInvoiced, TrackingSpecificationExists, HasATOShippedNotInvoiced,
                    RentalShptLine, TempTrackingSpecification, TempItemLedgEntryNotInvoiced, RentalLine);
        end else begin
            IsHandled := false;
            PostingEvents.OnPostItemTrackingForShipmentOnBeforeShipmentInvoiceErr(RentalLine, IsHandled);
            if not IsHandled then
                Error(
                  ShipmentInvoiceErr, RentalLine."Shipment Line No.", RentalLine."Shipment No.");
        end;
    end;

    local procedure PostItemTrackingForShipmentCondition(RentalLine: Record "TWE Rental Line"; RentalShptLine: Record "TWE Rental Shipment Line"): Boolean
    var
        Condition: Boolean;
    begin
        Condition := RentalLine.Type = RentalLine.Type::"Rental Item";
        PostingEvents.OnBeforePostItemTrackingForShipmentCondition(RentalLine, RentalShptLine, Condition);
        exit(Condition);
    end;

    local procedure PostUpdateOrderLine(RentalHeader: Record "TWE Rental Header")
    var
        TempRentalLine: Record "TWE Rental Line" temporary;
        SetDefaultQtyBlank: Boolean;
        IsHandled: Boolean;
    begin
        PostingEvents.OnBeforePostUpdateOrderLine(RentalHeader, TempRentalLineGlobal, SuppressCommit, RentalSetup);

        ResetTempLines(TempRentalLine);
        TempRentalLine.SetRange("Prepayment Line", false);
        TempRentalLine.SetFilter(Quantity, '<>0');
        if TempRentalLine.FindSet() then
            repeat
                PostingEvents.OnPostUpdateOrderLineOnBeforeInitTempRentalLineQuantities(RentalHeader, TempRentalLine);
                if RentalHeader.Ship then begin
                    TempRentalLine."Quantity Shipped" += TempRentalLine."Qty. to Ship";
                    TempRentalLine."Qty. Shipped (Base)" += TempRentalLine."Qty. to Ship (Base)";
                end;
                /* if RentalHeader.Receive then begin
                    TempRentalLine."Return Qty. Received" += TempRentalLine."Return Qty. to Receive";
                    TempRentalLine."Return Qty. Received (Base)" += TempRentalLine."Return Qty. to Receive (Base)";
                end; */
                if RentalHeader.Invoice then begin
                    IsHandled := false;
                    PostingEvents.OnPostUpdateOrderLineOnBeforeUpdateInvoicedValues(RentalHeader, TempRentalLine, IsHandled);
                    if not IsHandled then begin
                        if TempRentalLine."Document Type" = TempRentalLine."Document Type"::Contract then begin
                            if Abs(TempRentalLine."Quantity Invoiced" + TempRentalLine."Qty. to Invoice") > Abs(TempRentalLine."Quantity Shipped") then begin
                                TempRentalLine.Validate("Qty. to Invoice", TempRentalLine."Quantity Shipped" - TempRentalLine."Quantity Invoiced");
                                TempRentalLine."Qty. to Invoice (Base)" := TempRentalLine."Qty. Shipped (Base)" - TempRentalLine."Qty. Invoiced (Base)";
                            end
                        end; /* else
                                if Abs(TempRentalLine."Quantity Invoiced" + TempRentalLine."Qty. to Invoice") > Abs(TempRentalLine."Return Qty. Received") then begin
                                    TempRentalLine.Validate("Qty. to Invoice", TempRentalLine."Return Qty. Received" - TempRentalLine."Quantity Invoiced");
                                    TempRentalLine."Qty. to Invoice (Base)" := TempRentalLine."Return Qty. Received (Base)" - TempRentalLine."Qty. Invoiced (Base)";
                                end; */

                        TempRentalLine."Quantity Invoiced" += TempRentalLine."Qty. to Invoice";
                        TempRentalLine."Qty. Invoiced (Base)" += TempRentalLine."Qty. to Invoice (Base)";
                        if TempRentalLine."Qty. to Invoice" <> 0 then begin
                            TempRentalLine."Prepmt Amt Deducted" += TempRentalLine."Prepmt Amt to Deduct";
                            TempRentalLine."Prepmt VAT Diff. Deducted" += TempRentalLine."Prepmt VAT Diff. to Deduct";
                            DecrementPrepmtAmtInvLCY(
                              TempRentalLine, TempRentalLine."Prepmt. Amount Inv. (LCY)", TempRentalLine."Prepmt. VAT Amount Inv. (LCY)");
                            TempRentalLine."Prepmt Amt to Deduct" := TempRentalLine."Prepmt. Amt. Inv." - TempRentalLine."Prepmt Amt Deducted";
                            TempRentalLine."Prepmt VAT Diff. to Deduct" := 0;
                        end;
                    end;
                end;

                PostingEvents.OnPostUpdateOrderLineOnBeforeInitOutstanding(RentalHeader, TempRentalLine);

                TempRentalLine.InitOutstanding();
                CheckATOLink(TempRentalLine);

                SetDefaultQtyBlank := RentalSetup."Default Quantity to Ship" = RentalSetup."Default Quantity to Ship"::Blank;
                PostingEvents.OnPostUpdateOrderLineOnSetDefaultQtyBlank(RentalHeader, TempRentalLine, RentalSetup, SetDefaultQtyBlank);
                if WhseHandlingRequiredExternal(TempRentalLine) or SetDefaultQtyBlank then begin
                    /*  if TempRentalLine."Document Type" = TempRentalLine."Document Type"::"Return Order" then begin
                         TempRentalLine."Return Qty. to Receive" := 0;
                         TempRentalLine."Return Qty. to Receive (Base)" := 0;
                     end else begin
                         TempRentalLine."Qty. to Ship" := 0;
                         TempRentalLine."Qty. to Ship (Base)" := 0;
                     end; */
                    TempRentalLine.InitQtyToInvoice;
                end else begin
                    /*                         if TempRentalLine."Document Type" = TempRentalLine."Document Type"::"Return Order" then
                                                TempRentalLine.InitQtyToReceive
                                            else */
                    TempRentalLine.InitQtyToShip2;
                end;

                if (TempRentalLine."Purch. Order Line No." <> 0) and (TempRentalLine.Quantity = TempRentalLine."Quantity Invoiced") then
                    UpdateAssocLines(TempRentalLine);

                TempRentalLine.SetDefaultQuantity;
                PostingEvents.OnBeforePostUpdateOrderLineModifyTempLine(TempRentalLine, WhseShip, WhseReceive, SuppressCommit);
                ModifyTempLine(TempRentalLine);
                PostingEvents.OnAfterPostUpdateOrderLineModifyTempLine(TempRentalLine, WhseShip, WhseReceive, SuppressCommit);
            until TempRentalLine.Next() = 0;
    end;

    local procedure PostUpdateInvoiceLine()
    var
        RentalOrderLine: Record "TWE Rental Line";
        RentalShptLine: Record "TWE Rental Shipment Line";
        TempRentalLine: Record "TWE Rental Line" temporary;
        TempRentalOrderHeader: Record "TWE Rental Header" temporary;
        CRMSalesDocumentPostingMgt: Codeunit "CRM Sales Document Posting Mgt";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        PostingEvents.OnBeforePostUpdateInvoiceLine(TempRentalLineGlobal, IsHandled);
        if IsHandled then
            exit;

        ResetTempLines(TempRentalLine);

        TempRentalLine.SetFilter(TempRentalLine."Shipment No.", '<>%1', '');
        TempRentalLine.SetFilter(TempRentalLine.Type, '<>%1', TempRentalLine.Type::" ");
        if TempRentalLine.FindSet() then
            repeat
                RentalShptLine.Get(TempRentalLine."Shipment No.", TempRentalLine."Shipment Line No.");
                RentalOrderLine.Get(
                  RentalOrderLine."Document Type"::Contract,
                  RentalShptLine."Order No.", RentalShptLine."Order Line No.");
                /* if TempRentalLine.Type = TempRentalLine.Type::"Charge (Item)" then
                    UpdateSalesOrderChargeAssgnt(TempRentalLine, RentalOrderLine); */
                RentalOrderLine."Quantity Invoiced" += TempRentalLine."Qty. to Invoice";
                RentalOrderLine."Qty. Invoiced (Base)" += TempRentalLine."Qty. to Invoice (Base)";
                if Abs(RentalOrderLine."Quantity Invoiced") > Abs(RentalOrderLine."Quantity Shipped") then
                    Error(InvoiceMoreThanShippedErr, RentalOrderLine."Document No.");
                PostingEvents.OnPostUpdateInvoiceLineOnBeforeInitQtyToInvoice(RentalOrderLine, TempRentalLine);
                RentalOrderLine.InitQtyToInvoice;
                if RentalOrderLine."Prepayment %" <> 0 then begin
                    RentalOrderLine."Prepmt Amt Deducted" += TempRentalLine."Prepmt Amt to Deduct";
                    RentalOrderLine."Prepmt VAT Diff. Deducted" += TempRentalLine."Prepmt VAT Diff. to Deduct";
                    DecrementPrepmtAmtInvLCY(
                      TempRentalLine, RentalOrderLine."Prepmt. Amount Inv. (LCY)", RentalOrderLine."Prepmt. VAT Amount Inv. (LCY)");
                    RentalOrderLine."Prepmt Amt to Deduct" :=
                      RentalOrderLine."Prepmt. Amt. Inv." - RentalOrderLine."Prepmt Amt Deducted";
                    RentalOrderLine."Prepmt VAT Diff. to Deduct" := 0;
                end;
                RentalOrderLine.InitOutstanding();
                RentalOrderLine.Modify();
                if not TempRentalOrderHeader.Get(RentalOrderLine."Document Type", RentalOrderLine."Document No.") then begin
                    TempRentalOrderHeader."Document Type" := RentalOrderLine."Document Type";
                    TempRentalOrderHeader."No." := RentalOrderLine."Document No.";
                    TempRentalOrderHeader.Insert();
                end;
            until TempRentalLine.Next() = 0;

        PostingEvents.OnAfterPostUpdateInvoiceLine(TempRentalLine);
    end;

    local procedure GetAmountsForDeferral(RentalLine: Record "TWE Rental Line"; var AmtToDefer: Decimal; var AmtToDeferACY: Decimal; var DeferralAccount: Code[20])
    var
        DeferralTemplate: Record "Deferral Template";
    begin
        DeferralTemplate.Get(RentalLine."Deferral Code");
        DeferralTemplate.TestField("Deferral Account");
        DeferralAccount := DeferralTemplate."Deferral Account";

        if TempDeferralHeader.Get(
            "Deferral Document Type"::Sales, '', '', RentalLine."Document Type", RentalLine."Document No.", RentalLine."Line No.")
        then begin
            AmtToDeferACY := TempDeferralHeader."Amount to Defer";
            AmtToDefer := TempDeferralHeader."Amount to Defer (LCY)";
        end;

        if not RentalLine.IsCreditDocType then begin
            AmtToDefer := -AmtToDefer;
            AmtToDeferACY := -AmtToDeferACY;
        end;
    end;

    local procedure CheckMandatoryHeaderFields(var RentalHeader: Record "TWE Rental Header")
    begin
        RentalHeader.TestField("Document Type");
        RentalHeader.TestField("Rented-to Customer No.");
        RentalHeader.TestField("Bill-to Customer No.");
        RentalHeader.TestField("Posting Date");
        RentalHeader.TestField("Document Date");

        PostingEvents.OnAfterCheckMandatoryFields(RentalHeader, SuppressCommit);
    end;

    local procedure ClearPostBuffers()
    begin
        Clear(WhsePostRcpt);
        Clear(WhsePostShpt);
        Clear(GenJnlPostLine);
        Clear(ResJnlPostLine);
        Clear(JobPostLine);
        Clear(RentalItemJnlPostLine);
        Clear(WhseJnlPostLine);
    end;

    procedure SetPostingFlags(var RentalHeader: Record "TWE Rental Header")
    begin
        case RentalHeader."Document Type" of
            RentalHeader."Document Type"::Contract:
                RentalHeader.Receive := false;
            RentalHeader."Document Type"::Invoice:
                begin
                    RentalHeader.Ship := true;
                    RentalHeader.Invoice := true;
                    RentalHeader.Receive := false;
                end;

            RentalHeader."Document Type"::"Credit Memo":
                begin
                    RentalHeader.Ship := false;
                    RentalHeader.Invoice := true;
                    RentalHeader.Receive := true;
                end;

            RentalHeader."Document Type"::"Return Shipment":
                begin
                    RentalHeader.Ship := false;
                    RentalHeader.Invoice := false;
                    RentalHeader.Receive := true;
                end;
        end;
        if not (RentalHeader.Ship or RentalHeader.Invoice or RentalHeader.Receive) then
            Error(ShipInvoiceReceiveErr);
    end;

    procedure SetSuppressCommit(NewSuppressCommit: Boolean)
    begin
        SuppressCommit := NewSuppressCommit;
    end;

    local procedure ClearAllVariables()
    begin
        ClearAll();
        TempRentalLineGlobal.DeleteAll();
        TempItemChargeAssgntSales.DeleteAll();
        TempHandlingSpecification.DeleteAll();
        TempATOTrackingSpecification.DeleteAll();
        TempTrackingSpecification.DeleteAll();
        TempTrackingSpecificationInv.DeleteAll();
        TempWhseSplitSpecification.DeleteAll();
        TempValueEntryRelation.DeleteAll();
        TempICGenJnlLine.DeleteAll();
        TempPrepmtDeductLCYRentalLine.DeleteAll();
        TempSKU.DeleteAll();
        TempDeferralHeader.DeleteAll();
        TempDeferralLine.DeleteAll();
    end;

    local procedure CheckAssosOrderLines(RentalHeader: Record "TWE Rental Header")
    var
        RentalLine: Record "TWE Rental Line";
        PurchaseOrderLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        TempPurchaseHeader: Record "Purchase Header" temporary;
        TempPurchaseLine: Record "Purchase Line" temporary;
        CheckDimensions: Codeunit "Check Dimensions";
    begin
        RentalLine.Reset();
        RentalLine.SetRange("Document Type", RentalHeader."Document Type");
        RentalLine.SetRange("Document No.", RentalHeader."No.");
        RentalLine.SetFilter("Purch. Order Line No.", '<>0');
        RentalLine.SetFilter("Qty. to Ship", '<>0');
        PostingEvents.OnCheckAssosOrderLinesOnAfterSetFilters(RentalLine, RentalHeader);
        if RentalLine.FindSet() then
            repeat
                PurchaseOrderLine.Get(
                  PurchaseOrderLine."Document Type"::Order, RentalLine."Purchase Order No.", RentalLine."Purch. Order Line No.");
                TempPurchaseLine := PurchaseOrderLine;
                TempPurchaseLine.Insert();

                TempPurchaseHeader."Document Type" := TempPurchaseHeader."Document Type"::Order;
                TempPurchaseHeader."No." := RentalLine."Purchase Order No.";
                if TempPurchaseHeader.Insert() then;
            until RentalLine.Next() = 0;

        if TempPurchaseHeader.FindSet() then
            repeat
                PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, TempPurchaseHeader."No.");
                TempPurchaseLine.SetRange("Document No.", TempPurchaseHeader."No.");
                CheckDimensions.CheckPurchDim(PurchaseHeader, TempPurchaseLine);
            until TempPurchaseHeader.Next() = 0;
    end;

    local procedure PostResJnlLine(var RentalHeader: Record "TWE Rental Header"; var RentalLine: Record "TWE Rental Line"; var JobTaskRentalLine: Record "TWE Rental Line")
    var
        ResJnlLine: Record "Res. Journal Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        PostingEvents.OnBeforePostResJnlLine(RentalHeader, RentalLine, JobTaskRentalLine, IsHandled);
        if IsHandled then
            exit;

        if RentalLine."Qty. to Invoice" = 0 then
            exit;

        ResJnlLine.Init;
        ResJnlLine.CopyFromRentalHeader(RentalHeader);
        ResJnlLine.CopyDocumentFields(GenJnlLineDocNo, GenJnlLineExtDocNo, SrcCode, RentalHeader."Posting No. Series");
        ResJnlLine.CopyFromRentalLine(RentalLine);

        ResJnlPostLine.RunWithCheck(ResJnlLine);

        PostingEvents.OnAfterPostResJnlLine(RentalHeader, RentalLine, JobTaskRentalLine, ResJnlLine);
    end;

    local procedure ValidatePostingAndDocumentDate(var RentalHeader: Record "TWE Rental Header")
    var
        BatchProcessingMgt: Codeunit "Batch Processing Mgt.";
        PostingDate: Date;
        ModifyHeader: Boolean;
        PostingDateExists: Boolean;
        ReplacePostingDate: Boolean;
        ReplaceDocumentDate: Boolean;
    begin
        PostingEvents.OnBeforeValidatePostingAndDocumentDate(RentalHeader, SuppressCommit);

        PostingDateExists :=
          BatchProcessingMgt.GetBooleanParameter(RentalHeader.RecordId, "Batch Posting Parameter Type"::"Replace Posting Date", ReplacePostingDate) and
          BatchProcessingMgt.GetBooleanParameter(
            RentalHeader.RecordId, "Batch Posting Parameter Type"::"Replace Document Date", ReplaceDocumentDate) and
          BatchProcessingMgt.GetDateParameter(RentalHeader.RecordId, "Batch Posting Parameter Type"::"Posting Date", PostingDate);

        if PostingDateExists and (ReplacePostingDate or (RentalHeader."Posting Date" = 0D)) then begin
            RentalHeader."Posting Date" := PostingDate;
            RentalHeader.SynchronizeAsmHeader;
            RentalHeader.Validate("Currency Code");
            ModifyHeader := true;
        end;

        if PostingDateExists and (ReplaceDocumentDate or (RentalHeader."Document Date" = 0D)) then begin
            RentalHeader.Validate("Document Date", PostingDate);
            ModifyHeader := true;
        end;

        if ModifyHeader then
            RentalHeader.Modify();

        PostingEvents.OnAfterValidatePostingAndDocumentDate(RentalHeader, SuppressCommit, PreviewMode);
    end;

    local procedure UpdateRentalLineDimSetIDFromAppliedEntry(var RentalLineToPost: Record "TWE Rental Line"; RentalLine: Record "TWE Rental Line")
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        DimensionMgt: Codeunit DimensionManagement;
        DimSetID: array[10] of Integer;
    begin
        DimSetID[1] := RentalLine."Dimension Set ID";

        if RentalLineToPost."Appl.-to Item Entry" <> 0 then begin
            ItemLedgEntry.Get(RentalLineToPost."Appl.-to Item Entry");
            DimSetID[2] := ItemLedgEntry."Dimension Set ID";
        end;
        RentalLineToPost."Dimension Set ID" :=
          DimensionMgt.GetCombinedDimensionSetID(DimSetID, RentalLineToPost."Shortcut Dimension 1 Code", RentalLineToPost."Shortcut Dimension 2 Code");
    end;

    local procedure GetAmountRoundingPrecisionInLCY(RentalDocType: Enum "TWE Rental Document Type"; DocNo: Code[20];
                                                                 CurrencyCode: Code[10]) AmountRoundingPrecision: Decimal
    var
        RentalHeader: Record "TWE Rental Header";
    begin
        if CurrencyCode = '' then
            exit(GLSetup."Amount Rounding Precision");
        RentalHeader.Get(RentalDocType, DocNo);
        AmountRoundingPrecision := Currency."Amount Rounding Precision" / RentalHeader."Currency Factor";
        if AmountRoundingPrecision < GLSetup."Amount Rounding Precision" then
            exit(GLSetup."Amount Rounding Precision");
        exit(AmountRoundingPrecision);
    end;

    local procedure UpdateEmailParameters(RentalHeader: Record "TWE Rental Header")
    var
        FindEmailParameter: Record "Email Parameter";
        RenameEmailParameter: Record "Email Parameter";
    begin
        if RentalHeader."Last Posting No." = '' then
            exit;
        FindEmailParameter.SetRange("Document No", RentalHeader."No.");
        FindEmailParameter.SetRange("Document Type", RentalHeader."Document Type");
        if FindEmailParameter.FindSet() then
            repeat
                RenameEmailParameter.Copy(FindEmailParameter);
                RenameEmailParameter.Rename(
                  RentalHeader."Last Posting No.", FindEmailParameter."Document Type", FindEmailParameter."Parameter Type");
            until FindEmailParameter.Next() = 0;
    end;

    local procedure ArchivePurchaseOrders(var TempDropShptPostBuffer: Record "Drop Shpt. Post. Buffer" temporary)
    var
        PurchOrderHeader: Record "Purchase Header";
        PurchOrderLine: Record "Purchase Line";
    begin
        if TempDropShptPostBuffer.FindSet() then begin
            repeat
                PurchOrderHeader.Get(PurchOrderHeader."Document Type"::Order, TempDropShptPostBuffer."Order No.");
                TempDropShptPostBuffer.SetRange("Order No.", TempDropShptPostBuffer."Order No.");
                repeat
                    PurchOrderLine.Get(
                      PurchOrderLine."Document Type"::Order,
                      TempDropShptPostBuffer."Order No.", TempDropShptPostBuffer."Order Line No.");
                    PurchOrderLine."Qty. to Receive" := TempDropShptPostBuffer.Quantity;
                    PurchOrderLine."Qty. to Receive (Base)" := TempDropShptPostBuffer."Quantity (Base)";
                    PostingEvents.OnArchivePurchaseOrdersOnBeforePurchOrderLineModify(PurchOrderLine, TempDropShptPostBuffer);
                    PurchOrderLine.Modify();
                until TempDropShptPostBuffer.Next() = 0;
                PurchPost.ArchiveUnpostedOrder(PurchOrderHeader);
                TempDropShptPostBuffer.SetRange("Order No.");
            until TempDropShptPostBuffer.Next() = 0;
        end;
    end;

    local procedure IsItemJnlPostLineHandled(var RentalItemJnlLine: Record "TWE Rental Item Journal Line"; var RentalLine: Record "TWE Rental Line"; var RentalHeader: Record "TWE Rental Header") IsHandled: Boolean
    begin
        IsHandled := false;
        PostingEvents.OnBeforeItemJnlPostLine(RentalItemJnlLine, RentalLine, RentalHeader, SuppressCommit, IsHandled);
        exit(IsHandled);
    end;

    local procedure CalcVATBaseAmount(RentalHeader: Record "TWE Rental Header"; var RentalLine: Record "TWE Rental Line"; var TempVATAmountLine: Record "VAT Amount Line" temporary; var TempVATAmountLineRemainder: Record "VAT Amount Line" temporary)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        PostingEvents.OnBeforeCalcVATBaseAmount(RentalHeader, RentalLine, TempVATAmountLine, TempVATAmountLineRemainder, Currency, IsHandled);
        if IsHandled then
            exit;

        RentalLine."VAT Base Amount" :=
          Round(
            RentalLine.Amount * (1 - RentalHeader."VAT Base Discount %" / 100), Currency."Amount Rounding Precision");
    end;

    local procedure UpdateRentalLineAfterPosting(RentalHeader: Record "TWE Rental Header")
    var
        RentalLine: Record "TWE Rental Line";
        ReturnRentalLine: Record "TWE Rental Line";
        BusinessRentalMgt: Codeunit "TWE Business Rental Mgt.";
    begin
        if RentalHeader."Document Type" = RentalHeader."Document Type"::"Return Shipment" then begin
            ReturnRentalLine.SetRange("Document Type", RentalHeader."Document Type"::"Return Shipment");
            ReturnRentalLine.SetRange("Document No.", RentalHeader."No.");

            RentalLine.SetRange("Document Type", RentalHeader."Document Type"::Contract);
            RentalLine.SetRange("Document No.", RentalHeader."Belongs to Rental Contract");

            if RentalLine.FindSet() then begin
                repeat
                    ReturnRentalLine.SetRange("Rental Item", RentalLine."Rental Item");
                    if ReturnRentalLine.FindFirst() then begin
                        RentalLine."Quantity Returned" += ReturnRentalLine."Return Quantity";
                        RentalLine.Modify();
                    end;
                until RentalLine.Next() = 0;
            end;
            exit;
        end;
        if RentalHeader."Document Type" = RentalHeader."Document Type"::Invoice then begin
            RentalLine.SetRange("Document Type", RentalHeader."Document Type"::Contract);
            RentalLine.SetRange("Document No.", RentalHeader."Belongs to Rental Contract");
        end else begin
            if RentalHeader."Document Type" = RentalHeader."Document Type"::Contract then begin
                RentalLine.SetRange("Document Type", RentalHeader."Document Type");
                RentalLine.SetRange("Document No.", RentalHeader."No.");
            end else
                exit;
        end;
        if RentalHeader.Invoice then
            if RentalLine.FindSet() then begin
                repeat
                    RentalLine."Invoiced Duration" += RentalLine."Duration to be billed";
                    BusinessRentalMgt.CalculateNextInvoiceDates(RentalLine);
                    if not RentalLine."Line Closed" then
                        RentalLine."Duration to be billed" := BusinessRentalMgt.CalculateDaysToInvoice(RentalLine."Rental Rate Code", RentalLine."Invoicing Period", RentalLine."Billing Start Date", RentalLine."Billing End Date");
                    RentalLine.Modify();
                until RentalLine.Next() = 0;
            end;
    end;

    procedure SendPostedDocumentRecord(RentalHeader: Record "TWE Rental Header"; var RentalDocumentSendingProfile: Record "TWE Rental Doc. Send. Profile")
    var
        RentalInvHeader: Record "TWE Rental Invoice Header";
        RentalCrMemoHeader: Record "TWE Rental Cr.Memo Header";
        RentalShipmentHeader: Record "TWE Rental Shipment Header";
        OfficeManagement: Codeunit "Office Management";
        ConfirmManagement: Codeunit "Confirm Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        //OnBeforeSendPostedDocumentRecord(RentalHeader, IsHandled);
        if IsHandled then
            exit;

        case RentalHeader."Document Type" of
            RentalHeader."Document Type"::Contract:
                begin
                    //OnSendSalesDocument(RentalHeader.Invoice and RentalHeader.Ship, SuppressCommit);
                    if RentalHeader.Invoice then begin
                        RentalInvHeader.Get(RentalHeader."Last Posting No.");
                        RentalInvHeader.SetRecFilter;
                        RentalInvHeader.SendProfile(RentalDocumentSendingProfile);
                    end;
                    if RentalHeader.Ship and RentalHeader.Invoice and not OfficeManagement.IsAvailable then
                        if not ConfirmManagement.GetResponseOrDefault(DownloadShipmentAlsoQst, true) then
                            exit;
                    if RentalHeader.Ship then begin
                        RentalShipmentHeader.Get(RentalHeader."Last Shipping No.");
                        RentalShipmentHeader.SetRecFilter;
                        RentalShipmentHeader.SendProfile(RentalDocumentSendingProfile);
                    end;
                end;
            RentalHeader."Document Type"::Invoice:
                begin
                    if RentalHeader."Last Posting No." = '' then
                        RentalInvHeader.Get(RentalHeader."No.")
                    else
                        RentalInvHeader.Get(RentalHeader."Last Posting No.");

                    RentalInvHeader.SetRecFilter;
                    RentalInvHeader.SendProfile(RentalDocumentSendingProfile);
                end;
            RentalHeader."Document Type"::"Credit Memo":
                begin
                    if RentalHeader."Last Posting No." = '' then
                        RentalCrMemoHeader.Get(RentalHeader."No.")
                    else
                        RentalCrMemoHeader.Get(RentalHeader."Last Posting No.");
                    RentalCrMemoHeader.SetRecFilter;
                    RentalCrMemoHeader.SendProfile(RentalDocumentSendingProfile);
                end;
            RentalHeader."Document Type"::"Return Shipment":
                if RentalHeader.Invoice then begin
                    if RentalHeader."Last Posting No." = '' then
                        RentalCrMemoHeader.Get(RentalHeader."No.")
                    else
                        RentalCrMemoHeader.Get(RentalHeader."Last Posting No.");
                    RentalCrMemoHeader.SetRecFilter;
                    RentalCrMemoHeader.SendProfile(RentalDocumentSendingProfile);
                end;
            else begin
                    IsHandled := false;
                    //OnSendPostedDocumentRecordElseCase(RentalHeader, DocumentSendingProfile, IsHandled);
                    if not IsHandled then
                        Error(NotSupportedDocumentTypeErr, RentalHeader."Document Type");
                end;
        end;
    end;
}
