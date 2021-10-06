/// <summary>
/// Codeunit TWE Undo Rental Shipment Line (ID 50069).
/// </summary>
codeunit 50069 "TWE Undo Rental Shipment Line"
{
    Permissions = TableData "TWE Rental Line" = imd,
                  TableData "TWE Rental Shipment Line" = imd,
                  TableData "Item Application Entry" = rmd,
                  TableData "Item Entry Relation" = ri;
    TableNo = "TWE Rental Shipment Line";

    trigger OnRun()
    var
        UpdateItemAnalysisView: Codeunit "Update Item Analysis View";
        IsHandled: Boolean;
        SkipTypeCheck: Boolean;
    begin
        IsHandled := false;
        SkipTypeCheck := false;
        OnBeforeOnRun(Rec, IsHandled, SkipTypeCheck);
        if IsHandled then
            exit;

        if not HideDialog then
            if not Confirm(Text000Lbl) then
                exit;

        RentalShptLine.Copy(Rec);
        Code();
        UpdateItemAnalysisView.UpdateAll(0, true);
        Rec := RentalShptLine;
    end;

    var
        RentalShptLine: Record "TWE Rental Shipment Line";
        TempWhseJnlLine: Record "Warehouse Journal Line" temporary;
        TempGlobalItemLedgEntry: Record "Item Ledger Entry" temporary;
        TempGlobalItemEntryRelation: Record "Item Entry Relation" temporary;
        InvtSetup: Record "Inventory Setup";
        UndoRentalPostingMgt: Codeunit "TWE Undo Rental Posting Mgt.";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        WhseUndoQty: Codeunit "Whse. Undo Quantity";
        InvtAdjmt: Codeunit "Inventory Adjustment";
        ResJnlPostLine: Codeunit "Res. Jnl.-Post Line";
        AsmPost: Codeunit "Assembly-Post";
        ATOWindow: Dialog;
        HideDialog: Boolean;
        NextLineNo: Integer;
        Text000Lbl: Label 'Do you really want to undo the selected Shipment lines?';
        Text001Lbl: Label 'Undo quantity posting...';
        Text002Lbl: Label 'There is not enough space to insert correction lines.';
        Text003Lbl: Label 'Checking lines...';
        Text004Lbl: Label 'Some shipment lines may have unused service items. Do you want to delete them?';
        Text005Lbl: Label 'This shipment has already been invoiced. Undo Shipment can be applied only to posted, but not invoiced shipments.';
        Text055Lbl: Label '#1#################################\\Checking Undo Assembly #2###########.', Comment = '%1 %2 Update Window';
        Text056Lbl: Label '#1#################################\\Posting Undo Assembly #2###########.', Comment = '%1 %2 Update Window';
        Text057Lbl: Label '#1#################################\\Finalizing Undo Assembly #2###########.', Comment = '%1 %2 Update Window';
        Text059Lbl: Label '%1 %2 %3', Comment = '%1 = RentalShipmentLine."Document No.". %2 = RentalShipmentLine.FIELDCAPTION("Line No."). %3 = RentalShipmentLine."Line No.". This is used in a progress window.';
        AlreadyReversedErr: Label 'This shipment has already been reversed.';

    /// <summary>
    /// SetHideDialog.
    /// </summary>
    /// <param name="NewHideDialog">Boolean.</param>
    procedure SetHideDialog(NewHideDialog: Boolean)
    begin
        HideDialog := NewHideDialog;
    end;

    local procedure "Code"()
    var
        PostedWhseShptLine: Record "Posted Whse. Shipment Line";
        RentalLine: Record "TWE Rental Line";
        ServItem: Record "Service Item";
        WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line";
        Window: Dialog;
        ItemShptEntryNo: Integer;
        DocLineNo: Integer;
        DeleteServItems: Boolean;
        PostedWhseShptLineFound: Boolean;
    begin
        Clear(ItemJnlPostLine);
        RentalShptLine.SetCurrentKey("Item Shpt. Entry No.");
        RentalShptLine.SetFilter(Quantity, '<>0');
        RentalShptLine.SetRange(Correction, false);
        if RentalShptLine.IsEmpty then
            Error(AlreadyReversedErr);
        RentalShptLine.FindFirst();
        repeat
            if not HideDialog then
                Window.Open(Text003Lbl);
            CheckRentalShptLine(RentalShptLine);
        until RentalShptLine.Next() = 0;

        ServItem.SetCurrentKey("Sales/Serv. Shpt. Document No.");
        ServItem.SetRange("Sales/Serv. Shpt. Document No.", RentalShptLine."Document No.");
        if not ServItem.IsEmpty() then
            if not HideDialog then
                DeleteServItems := Confirm(Text004Lbl, true)
            else
                DeleteServItems := true;

        RentalShptLine.Find('-');
        repeat
            TempGlobalItemLedgEntry.Reset();
            if not TempGlobalItemLedgEntry.IsEmpty then
                TempGlobalItemLedgEntry.DeleteAll();
            TempGlobalItemEntryRelation.Reset();
            if not TempGlobalItemEntryRelation.IsEmpty then
                TempGlobalItemEntryRelation.DeleteAll();

            if not HideDialog then
                Window.Open(Text001Lbl);

            if RentalShptLine.Type = RentalShptLine.Type::"Rental Item" then begin
                PostedWhseShptLineFound :=
                WhseUndoQty.FindPostedWhseShptLine(
                    PostedWhseShptLine, DATABASE::"TWE Rental Shipment Line", RentalShptLine."Document No.",
                    DATABASE::"TWE REntal Line", RentalLine."Document Type"::Contract.AsInteger(), RentalShptLine."Order No.", RentalShptLine."Order Line No.");

                Clear(ItemJnlPostLine);
                ItemShptEntryNo := PostItemJnlLine(RentalShptLine, DocLineNo);
            end else
                DocLineNo := GetCorrectionLineNo(RentalShptLine);

            InsertNewShipmentLine(RentalShptLine, ItemShptEntryNo, DocLineNo);
            OnAfterInsertNewShipmentLine(RentalShptLine, PostedWhseShptLine, PostedWhseShptLineFound, DocLineNo);

            if PostedWhseShptLineFound then
                WhseUndoQty.UndoPostedWhseShptLine(PostedWhseShptLine);

            TempWhseJnlLine.SetRange("Source Line No.", RentalShptLine."Line No.");
            WhseUndoQty.PostTempWhseJnlLineCache(TempWhseJnlLine, WhseJnlRegisterLine);

            UndoPostATO(RentalShptLine, WhseJnlRegisterLine);

            UpdateOrderLine(RentalShptLine);
            if PostedWhseShptLineFound then
                WhseUndoQty.UpdateShptSourceDocLines(PostedWhseShptLine);

            if DeleteServItems then
                DeleteSalesShptLineServItems(RentalShptLine);

            RentalShptLine."Quantity Invoiced" := RentalShptLine.Quantity;
            RentalShptLine."Qty. Invoiced (Base)" := RentalShptLine."Quantity (Base)";
            RentalShptLine."Qty. Shipped Not Invoiced" := 0;
            RentalShptLine.Correction := true;

            OnBeforeRentalShptLineModify(RentalShptLine);
            RentalShptLine.Modify();
            OnAfterRentalShptLineModify(RentalShptLine);

            UndoFinalizePostATO(RentalShptLine);
        until RentalShptLine.Next() = 0;

        InvtSetup.Get();
        if InvtSetup."Automatic Cost Adjustment" <>
           InvtSetup."Automatic Cost Adjustment"::Never
        then begin
            InvtAdjmt.SetProperties(true, InvtSetup."Automatic Cost Posting");
            InvtAdjmt.SetJobUpdateProperties(true);
            InvtAdjmt.MakeMultiLevelAdjmt();
        end;

        OnAfterCode(RentalShptLine);
    end;

    local procedure CheckRentalShptLine(RentalShptLinePar: Record "TWE Rental Shipment Line")
    var
        TempItemLedgEntry: Record "Item Ledger Entry" temporary;
        IsHandled: Boolean;
        SkipTestFields: Boolean;
        SkipUndoPosting: Boolean;
        SkipUndoInitPostATO: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckRentalShptLine(RentalShptLine, IsHandled, SkipTestFields, SkipUndoPosting, SkipUndoInitPostATO);
        if IsHandled then
            exit;

        if not SkipTestFields then begin
            if RentalShptLinePar.Correction then
                Error(AlreadyReversedErr);
            if RentalShptLinePar."Qty. Shipped Not Invoiced" <> RentalShptLinePar.Quantity then
                if HasInvoicedNotReturnedQuantity() then
                    Error(Text005Lbl);
        end;
        if RentalShptLinePar.Type = RentalShptLinePar.Type::"Rental Item" then begin
            if not SkipTestFields then
                RentalShptLinePar.TestField("Drop Shipment", false);

            if not SkipUndoPosting then begin
                UndoRentalPostingMgt.TestRentalShptLine(RentalShptLine);
                UndoRentalPostingMgt.CollectItemLedgEntries(
                    TempItemLedgEntry, DATABASE::"TWE Rental Shipment Line", RentalShptLinePar."Document No.", RentalShptLinePar."Line No.",
                    RentalShptLinePar."Quantity (Base)", RentalShptLinePar."Item Shpt. Entry No.");
                UndoRentalPostingMgt.CheckItemLedgEntries(TempItemLedgEntry, RentalShptLinePar."Line No.",
                RentalShptLinePar."Qty. Shipped Not Invoiced" <> RentalShptLinePar.Quantity);
            end;
            if not SkipUndoInitPostATO then
                UndoInitPostATO(RentalShptLine);
        end;
    end;

    local procedure GetCorrectionLineNo(RentalShptLinePar: Record "TWE Rental Shipment Line"): Integer;
    var
        RentalShptLine2: Record "TWE Rental Shipment Line";
        LineSpacing: Integer;
    begin
        RentalShptLine2.SetRange("Document No.", RentalShptLinePar."Document No.");
        RentalShptLine2."Document No." := RentalShptLinePar."Document No.";
        RentalShptLine2."Line No." := RentalShptLinePar."Line No.";

        if RentalShptLine2.FindLast() then begin
            LineSpacing := (RentalShptLine2."Line No." - RentalShptLinePar."Line No.") div 2;
            if LineSpacing = 0 then
                Error(Text002Lbl);
        end else
            LineSpacing := 10000;

        exit(RentalShptLinePar."Line No." + LineSpacing);
    end;

    local procedure PostItemJnlLine(RentalShptLinePar: Record "TWE Rental Shipment Line"; var DocLineNo: Integer): Integer
    var
        ItemJnlLine: Record "Item Journal Line";
        RentalLine: Record "TWE Rental Line";
        RentalShptHeader: Record "TWE Rental Shipment Header";
        SourceCodeSetup: Record "Source Code Setup";
        TempApplyToEntryList: Record "Item Ledger Entry" temporary;
        ItemLedgEntryNotInvoiced: Record "Item Ledger Entry";
        ItemLedgEntryNo: Integer;
        RemQtyBase: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostItemJnlLine(RentalShptLine, DocLineNo, ItemLedgEntryNo, IsHandled);
        if IsHandled then
            exit(ItemLedgEntryNo);

        DocLineNo := GetCorrectionLineNo(RentalShptLine);

        SourceCodeSetup.Get();
        RentalShptLine.Get(RentalShptLinePar."Document No.");

        ItemJnlLine.Init();
        ItemJnlLine."Entry Type" := ItemJnlLine."Entry Type"::Sale;
        ItemJnlLine."Item No." := RentalShptLinePar."No.";
        ItemJnlLine."Posting Date" := RentalShptLine."Posting Date";
        ItemJnlLine."Document No." := RentalShptLinePar."Document No.";
        ItemJnlLine."Document Line No." := DocLineNo;
        ItemJnlLine."Gen. Bus. Posting Group" := RentalShptLinePar."Gen. Bus. Posting Group";
        ItemJnlLine."Gen. Prod. Posting Group" := RentalShptLinePar."Gen. Prod. Posting Group";
        ItemJnlLine."Location Code" := RentalShptLinePar."Location Code";
        ItemJnlLine."Source Code" := SourceCodeSetup.Sales;
        ItemJnlLine.Correction := true;
        ItemJnlLine."Variant Code" := RentalShptLinePar."Variant Code";
        ItemJnlLine."Bin Code" := RentalShptLinePar."Bin Code";
        ItemJnlLine."Document Date" := RentalShptHeader."Document Date";

        OnAfterCopyItemJnlLineFromRentalShpt(ItemJnlLine, RentalShptHeader, RentalShptLine, TempWhseJnlLine);

        WhseUndoQty.InsertTempWhseJnlLine(
            ItemJnlLine,
            DATABASE::"TWE Rental Line", RentalLine."Document Type"::Contract.AsInteger(), RentalShptLinePar."Order No.", RentalShptLinePar."Order Line No.",
            TempWhseJnlLine."Reference Document"::"Posted Shipment", TempWhseJnlLine, NextLineNo);

        if GetUnvoicedShptEntries(RentalShptLine, ItemLedgEntryNotInvoiced) then begin
            RemQtyBase := -(RentalShptLinePar."Quantity (Base)" - RentalShptLinePar."Qty. Invoiced (Base)");
            repeat
                ItemJnlLine."Applies-to Entry" := ItemLedgEntryNotInvoiced."Entry No.";
                ItemJnlLine.Quantity := ItemLedgEntryNotInvoiced.Quantity;
                ItemJnlLine."Quantity (Base)" := ItemLedgEntryNotInvoiced.Quantity;
                OnPostItemJnlLineOnBeforeRunItemJnlPostLine(ItemJnlLine, ItemLedgEntryNotInvoiced, RentalShptLine, RentalShptHeader);
                ItemJnlPostLine.Run(ItemJnlLine);
                RemQtyBase -= ItemJnlLine.Quantity;
                if ItemLedgEntryNotInvoiced.Next() = 0 then;
            until (RemQtyBase = 0);
            exit(ItemJnlLine."Item Shpt. Entry No.");
        end;

        UndoRentalPostingMgt.CollectItemLedgEntries(
            TempApplyToEntryList, DATABASE::"TWE Rental Shipment Line", RentalShptLinePar."Document No.", RentalShptLinePar."Line No.",
            RentalShptLinePar."Quantity (Base)", RentalShptLinePar."Item Shpt. Entry No.");

        UndoRentalPostingMgt.PostItemJnlLineAppliedToList(
            ItemJnlLine, TempApplyToEntryList, RentalShptLinePar.Quantity - RentalShptLinePar."Quantity Invoiced",
            RentalShptLinePar."Quantity (Base)" - RentalShptLinePar."Qty. Invoiced (Base)", TempGlobalItemLedgEntry, TempGlobalItemEntryRelation,
            RentalShptLinePar."Qty. Shipped Not Invoiced" <> RentalShptLinePar.Quantity);

        exit(0); // "Item Shpt. Entry No."
    end;

    local procedure InsertNewShipmentLine(OldRentalShptLine: Record "TWE Rental Shipment Line"; ItemShptEntryNo: Integer; DocLineNo: Integer)
    var
        NewRentalShptLine: Record "TWE Rental Shipment Line";
    begin
        NewRentalShptLine.Init();
        NewRentalShptLine.Copy(OldRentalShptLine);
        NewRentalShptLine."Line No." := DocLineNo;
        NewRentalShptLine."Appl.-from Item Entry" := OldRentalShptLine."Item Shpt. Entry No.";
        NewRentalShptLine."Item Shpt. Entry No." := ItemShptEntryNo;
        NewRentalShptLine.Quantity := -OldRentalShptLine.Quantity;
        NewRentalShptLine."Qty. Shipped Not Invoiced" := 0;
        NewRentalShptLine."Quantity (Base)" := -OldRentalShptLine."Quantity (Base)";
        NewRentalShptLine."Quantity Invoiced" := NewRentalShptLine.Quantity;
        NewRentalShptLine."Qty. Invoiced (Base)" := NewRentalShptLine."Quantity (Base)";
        NewRentalShptLine.Correction := true;
        NewRentalShptLine."Dimension Set ID" := OldRentalShptLine."Dimension Set ID";
        OnBeforeNewRentalShptLineInsert(NewRentalShptLine, OldRentalShptLine);
        NewRentalShptLine.Insert();
        OnAfterNewRentalShptLineInsert(NewRentalShptLine, OldRentalShptLine);

        InsertItemEntryRelation(TempGlobalItemEntryRelation); //NewRentalShptLine
    end;

    /// <summary>
    /// UpdateOrderLine.
    /// </summary>
    /// <param name="RentalShptLine">Record "TWE Rental Shipment Line".</param>
    procedure UpdateOrderLine(RentalShptLine: Record "TWE Rental Shipment Line")
    var
        RentalLine: Record "TWE Rental Line";
    begin
        RentalLine.Get(RentalLine."Document Type"::Contract, RentalShptLine."Order No.", RentalShptLine."Order Line No.");
        UndoRentalPostingMgt.UpdateRentalLine(RentalLine, RentalShptLine.Quantity - RentalShptLine."Quantity Invoiced", RentalShptLine."Quantity (Base)" - RentalShptLine."Qty. Invoiced (Base)", TempGlobalItemLedgEntry);
        OnAfterUpdateRentalLine(RentalLine, RentalShptLine);
    end;

    local procedure InsertItemEntryRelation(var TempItemEntryRelation: Record "Item Entry Relation" temporary) // ; NewRentalShptLine: Record "TWE Rental Shipment Line"
    var
        ItemEntryRelation: Record "Item Entry Relation";
    begin
        if TempItemEntryRelation.Find('-') then
            repeat
                ItemEntryRelation := TempItemEntryRelation;
                //ItemEntryRelation.TransferFieldsSalesShptLine(NewRentalShptLine);
                ItemEntryRelation.Insert();
            until TempItemEntryRelation.Next() = 0;
    end;

    local procedure DeleteSalesShptLineServItems(RentalShptLine: Record "TWE Rental Shipment Line")
    var
        ServItem: Record "Service Item";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDeleteRentalShptLineServItems(RentalShptLine, IsHandled);
        if IsHandled then
            exit;

        ServItem.SetCurrentKey("Sales/Serv. Shpt. Document No.", "Sales/Serv. Shpt. Line No.");
        ServItem.SetRange("Sales/Serv. Shpt. Document No.", RentalShptLine."Document No.");
        ServItem.SetRange("Sales/Serv. Shpt. Line No.", RentalShptLine."Line No.");
        ServItem.SetRange("Shipment Type", ServItem."Shipment Type"::Sales);
        if ServItem.Find('-') then
            repeat
                if ServItem.CheckIfCanBeDeleted() = '' then
                    if ServItem.Delete(true) then;
            until ServItem.Next() = 0;
    end;

    local procedure UndoInitPostATO(var RentalShptLine: Record "TWE Rental Shipment Line")
    var
        PostedAsmHeader: Record "Posted Assembly Header";
    begin
        if RentalShptLine.AsmToShipmentExists(PostedAsmHeader) then begin
            OpenATOProgressWindow(Text055Lbl, RentalShptLine, PostedAsmHeader);

            AsmPost.UndoInitPostATO(PostedAsmHeader);

            ATOWindow.Close();
        end;
    end;

    local procedure UndoPostATO(var RentalShptLine: Record "TWE Rental Shipment Line"; var WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line")
    var
        PostedAsmHeader: Record "Posted Assembly Header";
    begin
        if RentalShptLine.AsmToShipmentExists(PostedAsmHeader) then begin
            OpenATOProgressWindow(Text056Lbl, RentalShptLine, PostedAsmHeader);

            AsmPost.UndoPostATO(PostedAsmHeader, ItemJnlPostLine, ResJnlPostLine, WhseJnlRegisterLine);

            ATOWindow.Close();
        end;
    end;

    local procedure UndoFinalizePostATO(var RentalShptLine: Record "TWE Rental Shipment Line")
    var
        PostedAsmHeader: Record "Posted Assembly Header";
    begin
        if RentalShptLine.AsmToShipmentExists(PostedAsmHeader) then begin
            OpenATOProgressWindow(Text057Lbl, RentalShptLine, PostedAsmHeader);

            AsmPost.UndoFinalizePostATO(PostedAsmHeader);
            SynchronizeATO(RentalShptLine);

            ATOWindow.Close();
        end;
    end;

    local procedure SynchronizeATO(var RentalShptLine: Record "TWE Rental Shipment Line")
    var
        RentalLine: Record "TWE Rental Line";
        AsmHeader: Record "Assembly Header";
    begin
        RentalLine.Get(RentalLine."Document Type"::Contract, RentalShptLine."Order No.", RentalShptLine."Order Line No.");

        if RentalLine.AsmToOrderExists(AsmHeader) and (AsmHeader.Status = AsmHeader.Status::Released) then begin
            AsmHeader.Status := AsmHeader.Status::Open;
            AsmHeader.Modify();
            RentalLine.AutoAsmToOrder();
            AsmHeader.Status := AsmHeader.Status::Released;
            AsmHeader.Modify();
        end else
            RentalLine.AutoAsmToOrder();

        RentalLine.Modify(true);
    end;

    local procedure OpenATOProgressWindow(State: Text[250]; RentalShptLine: Record "TWE Rental Shipment Line"; PostedAsmHeader: Record "Posted Assembly Header")
    begin
        ATOWindow.Open(State);
        ATOWindow.Update(1,
          StrSubstNo(Text059Lbl,
            RentalShptLine."Document No.", RentalShptLine.FieldCaption("Line No."), RentalShptLine."Line No."));
        ATOWindow.Update(2, PostedAsmHeader."No.");
    end;

    local procedure GetUnvoicedShptEntries(RentalShptLine: Record "TWE Rental Shipment Line"; var ItemLedgEntry: Record "Item Ledger Entry"): Boolean
    begin
        ItemLedgEntry.SetCurrentKey("Document No.", "Document Type", "Document Line No.");
        ItemLedgEntry.SetRange("Document Type", ItemLedgEntry."Document Type"::"Sales Shipment");
        ItemLedgEntry.SetRange("Document No.", RentalShptLine."Document No.");
        ItemLedgEntry.SetRange("Document Line No.", RentalShptLine."Line No.");
        ItemLedgEntry.SetRange("Serial No.", '');
        ItemLedgEntry.SetRange("Lot No.", '');
        ItemLedgEntry.SetRange("Completely Invoiced", false);
        exit(ItemLedgEntry.FindSet())
    end;

    local procedure HasInvoicedNotReturnedQuantity(): Boolean
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ReturnedInvoicedItemLedgerEntry: Record "Item Ledger Entry";
        ItemApplicationEntry: Record "Item Application Entry";
        RentalInvoiceHeader: Record "TWE Rental Invoice Header";
        RentalInvoiceLine: Record "TWE Rental Invoice Line";
        InvoicedQuantity: Decimal;
        ReturnedInvoicedQuantity: Decimal;
    begin
        if RentalShptLine.Type = RentalShptLine.Type::"Rental Item" then begin
            ItemLedgerEntry.SetRange("Document Type", ItemLedgerEntry."Document Type"::"Sales Shipment");
            ItemLedgerEntry.SetRange("Document No.", RentalShptLine."Document No.");
            ItemLedgerEntry.SetRange("Document Line No.", RentalShptLine."Line No.");
            ItemLedgerEntry.FindSet();
            repeat
                InvoicedQuantity += ItemLedgerEntry."Invoiced Quantity";
                if ItemApplicationEntry.AppliedInbndEntryExists(ItemLedgerEntry."Entry No.", false) then
                    repeat
                        if ItemApplicationEntry."Item Ledger Entry No." = ItemApplicationEntry."Inbound Item Entry No." then begin
                            ReturnedInvoicedItemLedgerEntry.Get(ItemApplicationEntry."Item Ledger Entry No.");
                            if IsCancelled(ReturnedInvoicedItemLedgerEntry) then
                                ReturnedInvoicedQuantity += ReturnedInvoicedItemLedgerEntry."Invoiced Quantity";
                        end;
                    until ItemApplicationEntry.Next() = 0;
            until ItemLedgerEntry.Next() = 0;
            exit(InvoicedQuantity + ReturnedInvoicedQuantity <> 0);
        end else begin
            RentalInvoiceLine.SetRange("Order No.", RentalShptLine."Order No.");
            RentalInvoiceLine.SetRange("Order Line No.", RentalShptLine."Order Line No.");
            if RentalInvoiceLine.FindSet() then
                repeat
                    RentalInvoiceHeader.Get(RentalInvoiceLine."Document No.");
                    RentalInvoiceHeader.CalcFields(Cancelled);
                    if not RentalInvoiceHeader.Cancelled then
                        exit(true);
                until RentalInvoiceLine.Next() = 0;

            exit(false);
        end;
    end;

    local procedure IsCancelled(ItemLedgerEntry: Record "Item Ledger Entry"): Boolean
    var
        CancelledDocument: Record "Cancelled Document";
        ReturnReceiptHeader: Record "Return Receipt Header";
        RentalCrMemoHeader: Record "TWE Rental Cr.Memo Header";
    begin
        case ItemLedgerEntry."Document Type" of
            ItemLedgerEntry."Document Type"::"Sales Return Receipt":
                begin
                    ReturnReceiptHeader.Get(ItemLedgerEntry."Document No.");
                    if ReturnReceiptHeader."Applies-to Doc. Type" = ReturnReceiptHeader."Applies-to Doc. Type"::Invoice then
                        exit(CancelledDocument.Get(Database::"TWE Rental Invoice Header", ReturnReceiptHeader."Applies-to Doc. No."));
                end;
            ItemLedgerEntry."Document Type"::"Sales Credit Memo":
                begin
                    RentalCrMemoHeader.Get(ItemLedgerEntry."Document No.");
                    if RentalCrMemoHeader."Applies-to Doc. Type" = RentalCrMemoHeader."Applies-to Doc. Type"::Invoice then
                        exit(CancelledDocument.Get(Database::"TWE Rental Invoice Header", RentalCrMemoHeader."Applies-to Doc. No."));
                end;
        end;

        exit(false);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCode(var RentalShipmentLine: Record "TWE Rental Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyItemJnlLineFromRentalShpt(var ItemJournalLine: Record "Item Journal Line"; RentalShipmentHeader: Record "TWE Rental Shipment Header"; RentalShipmentLine: Record "TWE Rental Shipment Line"; var TempWhseJnlLine: Record "Warehouse Journal Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterNewRentalShptLineInsert(var NewRentalShipmentLine: Record "TWE Rental Shipment Line"; OldRentalShipmentLine: Record "TWE Rental Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRentalShptLineModify(var RentalShptLine: Record "TWE Rental Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateRentalLine(var RentalLine: Record "TWE Rental Line"; var RentalShptLine: Record "TWE Rental Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckRentalShptLine(var RentalShipmentLine: Record "TWE Rental Shipment Line"; var IsHandled: Boolean; var SkipTestFields: Boolean; var SkipUndoPosting: Boolean; var SkipUndoInitPostATO: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteRentalShptLineServItems(var RentalShipmentLine: Record "TWE Rental Shipment Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertNewShipmentLine(var RentalShipmentLine: Record "TWE Rental Shipment Line"; PostedWhseShipmentLine: Record "Posted Whse. Shipment Line"; var PostedWhseShptLineFound: Boolean; DocLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var RentalShipmentLine: Record "TWE Rental Shipment Line"; var IsHandled: Boolean; var SkipTypeCheck: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeNewRentalShptLineInsert(var NewRentalShipmentLine: Record "TWE Rental Shipment Line"; OldRentalShipmentLine: Record "TWE Rental Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostItemJnlLine(var RentalShipmentLine: Record "TWE Rental Shipment Line"; DocLineNo: Integer; var ItemLedgEntryNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRentalShptLineModify(var RentalShptLine: Record "TWE Rental Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemJnlLineOnBeforeRunItemJnlPostLine(var ItemJnlLine: Record "Item Journal Line"; ItemLedgEntryNotInvoiced: Record "Item Ledger Entry"; RentalShptLine: Record "TWE Rental Shipment Line"; RentalShptHeader: Record "TWE Rental Shipment Header")
    begin
    end;
}

