/// <summary>
/// Codeunit TWE Rental Item Jnl.-Post Line (ID 50027).
/// </summary>

codeunit 50027 "TWE Rental Item Jnl.-Post Line"
{
    Permissions = TableData "TWE Main Rental Item" = imd,
                  TableData "Item Ledger Entry" = imd,
                  TableData "Item Register" = imd,
                  TableData "Phys. Inventory Ledger Entry" = imd,
                  TableData "Item Application Entry" = imd,
                  TableData "Prod. Order Capacity Need" = rimd,
                  TableData "Stockkeeping Unit" = imd,
                  TableData "Value Entry" = imd,
                  TableData "Avg. Cost Adjmt. Entry Point" = rim,
                  TableData "Post Value Entry to G/L" = ri,
                  TableData "Capacity Ledger Entry" = rimd,
                  TableData "Inventory Adjmt. Entry (Order)" = rim;
    TableNo = "TWE Rental Item Journal Line";

    trigger OnRun()
    begin
        GetGLSetup;
        RunWithCheck(Rec);
    end;

    var
        GLSetup: Record "General Ledger Setup";
        Currency: Record Currency;
        InvtSetup: Record "Inventory Setup";
        MfgSetup: Record "Manufacturing Setup";
        Location: Record Location;
        NewLocation: Record Location;
        MainRentalItem: Record "TWE Main Rental Item";
        GlobalItemLedgEntry: Record "Item Ledger Entry";
        OldItemLedgEntry: Record "Item Ledger Entry";
        ItemReg: Record "Item Register";
        RentalItemJnlLine: Record "TWE Rental Item Journal Line";
        RentalItemJnlLineOrigin: Record "TWE Rental Item Journal Line";
        SourceCodeSetup: Record "Source Code Setup";
        GenPostingSetup: Record "General Posting Setup";
        ItemApplnEntry: Record "Item Application Entry";
        GlobalValueEntry: Record "Value Entry";
        DirCostValueEntry: Record "Value Entry";
        SKU: Record "Stockkeeping Unit";
        CurrExchRate: Record "Currency Exchange Rate";
        ItemTrackingCode: Record "Item Tracking Code";
        ItemTrackingSetup: Record "Item Tracking Setup";
        TempSplitRentalItemJnlLine: Record "TWE Rental Item Journal Line" temporary;
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        TempValueEntryRelation: Record "Value Entry Relation" temporary;
        TempItemEntryRelation: Record "Item Entry Relation" temporary;
        WhseJnlLine: Record "Warehouse Journal Line";
        TempTouchedItemLedgerEntries: Record "Item Ledger Entry" temporary;
        TempItemApplnEntryHistory: Record "Item Application Entry History" temporary;
        PrevAppliedItemLedgEntry: Record "Item Ledger Entry";
        WMSMgmt: Codeunit "WMS Management";
        WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line";
        RentalItemJnlCheckLine: Codeunit "TWE Rent. Item Jnl.-Check Line";
        ReservEngineMgt: Codeunit "Reservation Engine Mgt.";
        ReserveItemJnlLine: Codeunit "Item Jnl. Line-Reserve";
        ReserveProdOrderComp: Codeunit "Prod. Order Comp.-Reserve";
        ReserveProdOrderLine: Codeunit "Prod. Order Line-Reserve";
        JobPlanningLineReserve: Codeunit "Job Planning Line-Reserve";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        InventoryPostingToGL: Codeunit "Inventory Posting To G/L";
        CostCalcMgt: Codeunit "Cost Calculation Management";
        ACYMgt: Codeunit "Additional-Currency Management";
        UOMMgt: Codeunit "Unit of Measure Management";
        ItemLedgEntryNo: Integer;
        PhysInvtEntryNo: Integer;
        CapLedgEntryNo: Integer;
        ValueEntryNo: Integer;
        ItemApplnEntryNo: Integer;
        TotalAppliedQty: Decimal;
        OverheadAmount: Decimal;
        VarianceAmount: Decimal;
        OverheadAmountACY: Decimal;
        VarianceAmountACY: Decimal;
        QtyPerUnitOfMeasure: Decimal;
        RoundingResidualAmount: Decimal;
        RoundingResidualAmountACY: Decimal;
        InvtSetupRead: Boolean;
        GLSetupRead: Boolean;
        MfgSetupRead: Boolean;
        SKUExists: Boolean;
        AverageTransfer: Boolean;
        PostponeReservationHandling: Boolean;
        VarianceRequired: Boolean;
        LastOperation: Boolean;
        DisableItemTracking: Boolean;
        CalledFromInvtPutawayPick: Boolean;
        CalledFromAdjustment: Boolean;
        PostToGL: Boolean;
        ProdOrderCompModified: Boolean;
        IsServUndoConsumption: Boolean;
        BlockRetrieveIT: Boolean;
        SkipApplicationCheck: Boolean;
        CalledFromApplicationWorksheet: Boolean;
        SkipSerialNoQtyValidation: Boolean;
        Text023Lbl: Label 'Entries applied to an Outbound Transfer cannot be unapplied.';
        Text024Lbl: Label 'Entries applied to a Drop Shipment Order cannot be unapplied.';
        CannotUnapplyCorrEntryErr: Label 'Entries applied to a Correction entry cannot be unapplied.';
        Text027Lbl: Label 'A fixed application was not unapplied and this prevented the reapplication. Use the Application Worksheet to remove the applications.';
        Text01Lbl: Label 'Checking for open entries.';
        Text029Lbl: Label '%1 %2 for %3 %4 is reserved for %5.', Comment = '%1 = ReservEntry FieldCaption Applies-to Entry, %2 = ApplicationEntry, %3 = MainRentalItem FieldCaption No., %4 = Item No., %5 = ReservEngineMgt CreateForText(ReservationEntries)';
        Text030Lbl: Label 'The quantity that you are trying to invoice is larger than the quantity in the item ledger with the entry number %1.', Comment = '%1 = Item Ledger Entry "Entry No."';
        Text031Lbl: Label 'You cannot invoice the item %1 with item tracking number %2 %3 in this purchase order before the associated sales order %4 has been invoiced.', Comment = '%1 = Item Ledger Entry "Item No.",%2 = Lot No. %3 = Serial No. Both are tracking numbers., %4 = Order No.';
        Text032Lbl: Label 'You cannot invoice item %1 in this purchase order before the associated rental order %2 has been invoiced.', Comment = '%1 = ItemLedgerEntry "Item No.",%2 = RentalShipmentHeader "Order No."';
        Text033Lbl: Label 'Quantity must be -1, 0 or 1 when Serial No. is stated.';
        Text000Lbl: Label 'cannot be less than zero';
        Text001Lbl: Label 'Item Tracking is signed wrongly.';
        Text003Lbl: Label 'Reserved item %1 is not on inventory.', Comment = '%1 ReservEntry "Item No."';
        Text004Lbl: Label 'is too low';
        TrackingSpecificationMissingErr: Label 'Tracking Specification is missing.';
        Text012Lbl: Label 'Item %1 must be reserved.', Comment = '%1 = ItemLedgerEntry "Item No."';
        Text014Lbl: Label 'Serial No. %1 is already on inventory.', Comment = '%1 RentalItemJnlLine "New Serial No."';
        SerialNoRequiredErr: Label 'You must assign a serial number for item %1.', Comment = '%1 - Item No.';
        LotNoRequiredErr: Label 'You must assign a lot number for item %1.', Comment = '%1 - Item No.';
        LineNoTxt: Label ' Line No. = ''%1''.', Comment = '%1 - Line No.';
        Text017Lbl: Label ' is before the posting date.';
        Text018Lbl: Label 'Item Tracking Serial No. %1 Lot No. %2 for Item No. %3 Variant %4 cannot be fully applied.', Comment = '%1 = "Serial No.",%2 = "Lot No.", %3 = "Item No.", %4 = "Variant Code"';
        Text021Lbl: Label 'You must not define item tracking on %1 %2.', Comment = '%1 = FieldCaption Operation No., %2 = "Operation No."';
        Text022Lbl: Label 'You cannot apply %1 to %2 on the same item %3 on Production Order %4.', Comment = '%1 = "Entry Type", %2 = "Entry Type", %3 = "Item No.", %4 = "Order No."';
        Text100Lbl: Label 'Fatal error when retrieving Tracking Specification.';
        Text990Lbl: Label 'must not be filled out when reservations exist';
        CannotUnapplyItemLedgEntryErr: Label 'You cannot proceed with the posting as it will result in negative inventory for item %1. \Item ledger entry %2 cannot be left unapplied.', Comment = '%1 - Item no., %2 - Item ledger entry no.';

    procedure RunWithCheck(var RentalItemJnlLine2: Record "TWE Rental Item Journal Line"): Boolean
    var
        TrackingSpecExists: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRunWithCheck(
          RentalItemJnlLine2, CalledFromAdjustment, CalledFromInvtPutawayPick, CalledFromApplicationWorksheet,
          PostponeReservationHandling, IsHandled);
        if IsHandled then
            exit;

        PrepareItem(RentalItemJnlLine2);
        //TrackingSpecExists := ItemTrackingMgt.RetrieveItemTracking(RentalItemJnlLine2, TempTrackingSpecification);
        exit(PostSplitJnlLine(RentalItemJnlLine2, TrackingSpecExists));
    end;

    procedure RunPostWithReservation(var RentalItemJnlLine2: Record "TWE Rental Item Journal Line"; var ReservationEntry: Record "Reservation Entry"): Boolean
    var
        TrackingSpecExists: Boolean;
    begin
        PrepareItem(RentalItemJnlLine2);

        ReservationEntry.Reset();

        exit(PostSplitJnlLine(RentalItemJnlLine2, TrackingSpecExists));
    end;

    local procedure "Code"()
    begin
        OnBeforePostItemJnlLine(RentalItemJnlLine, CalledFromAdjustment, CalledFromInvtPutawayPick);

        if RentalItemJnlLine.EmptyLine() and not RentalItemJnlLine.Correction and not RentalItemJnlLine.Adjustment then
            if not RentalItemJnlLine.IsValueEntryForDeletedItem then
                exit;

        RentalItemJnlCheckLine.SetCalledFromInvtPutawayPick(CalledFromInvtPutawayPick);
        RentalItemJnlCheckLine.SetCalledFromAdjustment(CalledFromAdjustment);

        RentalItemJnlCheckLine.RunCheck(RentalItemJnlLine);

        if RentalItemJnlLine."Document Date" = 0D then
            RentalItemJnlLine."Document Date" := RentalItemJnlLine."Posting Date";

        if ItemLedgEntryNo = 0 then begin
            GlobalItemLedgEntry.LockTable();
            ItemLedgEntryNo := GlobalItemLedgEntry.GetLastEntryNo();
            GlobalItemLedgEntry."Entry No." := ItemLedgEntryNo;
        end;
        InitValueEntryNo;

        GetInvtSetup;
        if not CalledFromAdjustment then
            PostToGL := InvtSetup."Automatic Cost Posting";
        OnCheckPostingCostToGL(PostToGL);

        if ItemTrackingSetup.TrackingRequired() and (RentalItemJnlLine."Quantity (Base)" <> 0) and
           (RentalItemJnlLine."Value Entry Type" = RentalItemJnlLine."Value Entry Type"::"Direct Cost") and
           not DisableItemTracking and not RentalItemJnlLine.Adjustment and
           not RentalItemJnlLine.Subcontracting and not RentalItemJnlLine.IsAssemblyResourceConsumpLine()
        then
            CheckItemTracking();

        if RentalItemJnlLine.Correction then
            UndoQuantityPosting();

        if (RentalItemJnlLine."Entry Type" in
            [RentalItemJnlLine."Entry Type"::Consumption, RentalItemJnlLine."Entry Type"::Output, RentalItemJnlLine."Entry Type"::"Assembly Consumption", RentalItemJnlLine."Entry Type"::"Assembly Output"]) and
           not (RentalItemJnlLine."Value Entry Type" = RentalItemJnlLine."Value Entry Type"::Revaluation) and
           not RentalItemJnlLine.OnlyStopTime()
        then begin
            case RentalItemJnlLine."Entry Type" of
                RentalItemJnlLine."Entry Type"::"Assembly Consumption", RentalItemJnlLine."Entry Type"::"Assembly Output":
                    RentalItemJnlLine.TestField("Order Type", RentalItemJnlLine."Order Type"::Assembly);
                RentalItemJnlLine."Entry Type"::Consumption, RentalItemJnlLine."Entry Type"::Output:
                    RentalItemJnlLine.TestField("Order Type", RentalItemJnlLine."Order Type"::Production);
            end;
            RentalItemJnlLine.TestField("Order No.");
            if RentalItemJnlLine.IsAssemblyOutputLine() then
                RentalItemJnlLine.TestField("Order Line No.", 0)
            else
                RentalItemJnlLine.TestField("Order Line No.");
        end;

        if (RentalItemJnlLine."Gen. Bus. Posting Group" <> GenPostingSetup."Gen. Bus. Posting Group") or
           (RentalItemJnlLine."Gen. Prod. Posting Group" <> GenPostingSetup."Gen. Prod. Posting Group")
        then
            GenPostingSetup.Get(RentalItemJnlLine."Gen. Bus. Posting Group", RentalItemJnlLine."Gen. Prod. Posting Group");

        if RentalItemJnlLine."Qty. per Unit of Measure" = 0 then
            RentalItemJnlLine."Qty. per Unit of Measure" := 1;
        if RentalItemJnlLine."Qty. per Cap. Unit of Measure" = 0 then
            RentalItemJnlLine."Qty. per Cap. Unit of Measure" := 1;

        RentalItemJnlLine.Quantity := RentalItemJnlLine."Quantity (Base)";
        RentalItemJnlLine."Invoiced Quantity" := RentalItemJnlLine."Invoiced Qty. (Base)";
        RentalItemJnlLine."Setup Time" := RentalItemJnlLine."Setup Time (Base)";
        RentalItemJnlLine."Run Time" := RentalItemJnlLine."Run Time (Base)";
        RentalItemJnlLine."Stop Time" := RentalItemJnlLine."Stop Time (Base)";
        RentalItemJnlLine."Output Quantity" := RentalItemJnlLine."Output Quantity (Base)";
        RentalItemJnlLine."Scrap Quantity" := RentalItemJnlLine."Scrap Quantity (Base)";

        if not RentalItemJnlLine.Subcontracting and
           ((RentalItemJnlLine."Entry Type" = RentalItemJnlLine."Entry Type"::Output) or
            RentalItemJnlLine.IsAssemblyResourceConsumpLine())
        then
            QtyPerUnitOfMeasure := RentalItemJnlLine."Qty. per Cap. Unit of Measure"
        else
            QtyPerUnitOfMeasure := RentalItemJnlLine."Qty. per Unit of Measure";

        RoundingResidualAmount := 0;
        RoundingResidualAmountACY := 0;
        if RentalItemJnlLine."Value Entry Type" = RentalItemJnlLine."Value Entry Type"::Revaluation then
            if GetItem(RentalItemJnlLine."Item No.", false) and (MainRentalItem."Costing Method" = MainRentalItem."Costing Method"::Average) then begin
                RoundingResidualAmount := RentalItemJnlLine.Quantity *
                  (RentalItemJnlLine."Unit Cost" - Round(RentalItemJnlLine."Unit Cost" / QtyPerUnitOfMeasure, GLSetup."Unit-Amount Rounding Precision"));
                RoundingResidualAmountACY := RentalItemJnlLine.Quantity *
                  (RentalItemJnlLine."Unit Cost (ACY)" - Round(RentalItemJnlLine."Unit Cost (ACY)" / QtyPerUnitOfMeasure, Currency."Unit-Amount Rounding Precision"));
                if Abs(RoundingResidualAmount) < GLSetup."Amount Rounding Precision" then
                    RoundingResidualAmount := 0;
                if Abs(RoundingResidualAmountACY) < Currency."Amount Rounding Precision" then
                    RoundingResidualAmountACY := 0;
            end;

        RentalItemJnlLine."Unit Amount" := Round(
            RentalItemJnlLine."Unit Amount" / QtyPerUnitOfMeasure, GLSetup."Unit-Amount Rounding Precision");
        RentalItemJnlLine."Unit Cost" := Round(
            RentalItemJnlLine."Unit Cost" / QtyPerUnitOfMeasure, GLSetup."Unit-Amount Rounding Precision");
        RentalItemJnlLine."Unit Cost (ACY)" := Round(
            RentalItemJnlLine."Unit Cost (ACY)" / QtyPerUnitOfMeasure, Currency."Unit-Amount Rounding Precision");

        OverheadAmount := 0;
        VarianceAmount := 0;
        OverheadAmountACY := 0;
        VarianceAmountACY := 0;
        VarianceRequired := false;
        LastOperation := false;

        OnBeforePostLineByEntryType(RentalItemJnlLine, CalledFromAdjustment, CalledFromInvtPutawayPick);

        case true of
            RentalItemJnlLine.IsAssemblyResourceConsumpLine():
                PostAssemblyResourceConsump();
            RentalItemJnlLine.Adjustment,
            RentalItemJnlLine."Value Entry Type" in [RentalItemJnlLine."Value Entry Type"::Rounding, RentalItemJnlLine."Value Entry Type"::Revaluation],
            RentalItemJnlLine."Entry Type" = RentalItemJnlLine."Entry Type"::"Assembly Consumption",
            RentalItemJnlLine."Entry Type" = RentalItemJnlLine."Entry Type"::"Assembly Output":
                PostItem();
            RentalItemJnlLine."Entry Type" = RentalItemJnlLine."Entry Type"::Consumption:
                PostConsumption();
            RentalItemJnlLine."Entry Type" = RentalItemJnlLine."Entry Type"::Output:
                PostOutput();
            not RentalItemJnlLine.Correction:
                PostItem();
        end;

        // Entry no. is returned to shipment/receipt
        if RentalItemJnlLine.Subcontracting then
            RentalItemJnlLine."Item Shpt. Entry No." := CapLedgEntryNo
        else
            RentalItemJnlLine."Item Shpt. Entry No." := GlobalItemLedgEntry."Entry No.";

        OnAfterPostItemJnlLine(RentalItemJnlLine, GlobalItemLedgEntry, ValueEntryNo, InventoryPostingToGL, CalledFromAdjustment, CalledFromInvtPutawayPick);
    end;

    local procedure PostSplitJnlLine(var RentalItemJnlLineToPost: Record "TWE Rental Item Journal Line"; TrackingSpecExists: Boolean): Boolean
    var
        PostItemJnlLine: Boolean;
    begin
        PostItemJnlLine := SetupSplitJnlLine(RentalItemJnlLineToPost, TrackingSpecExists);
        if not PostItemJnlLine then
            PostItemJnlLine := IsNotInternalWhseMovement(RentalItemJnlLineToPost);

        OnPostSplitJnlLineOnBeforeSplitJnlLine(RentalItemJnlLine, RentalItemJnlLineToPost, PostItemJnlLine);

        while SplitItemJnlLine(RentalItemJnlLine, PostItemJnlLine) do
            if PostItemJnlLine then
                Code();
        OnPostSplitJnlLineOnAfterCode(RentalItemJnlLine, RentalItemJnlLineToPost, PostItemJnlLine, TempTrackingSpecification);
        Clear(PrevAppliedItemLedgEntry);
        RentalItemJnlLineToPost := RentalItemJnlLine;
        CorrectOutputValuationDate(GlobalItemLedgEntry);
        RedoApplications;

        OnAfterPostSplitJnlLine(RentalItemJnlLineToPost, TempTrackingSpecification);

        exit(PostItemJnlLine);
    end;

    local procedure PostConsumption()
    var
        ProdOrderComp: Record "Prod. Order Component";
        TempHandlingSpecification: Record "Tracking Specification" temporary;
        RemQtyToPost: Decimal;
        RemQtyToPostThisLine: Decimal;
        QtyToPost: Decimal;
        UseItemTrackingApplication: Boolean;
        LastLoop: Boolean;
        EndLoop: Boolean;
        NewRemainingQty: Decimal;
    begin
        RentalItemJnlLine.TestField("Order Type", RentalItemJnlLine."Order Type"::Production);
        ProdOrderComp.SetCurrentKey(Status, "Prod. Order No.", "Prod. Order Line No.", "Item No.", "Line No.");
        ProdOrderComp.SetRange(Status, ProdOrderComp.Status::Released);
        ProdOrderComp.SetRange("Prod. Order No.", RentalItemJnlLine."Order No.");
        ProdOrderComp.SetRange("Prod. Order Line No.", RentalItemJnlLine."Order Line No.");
        ProdOrderComp.SetRange("Item No.", RentalItemJnlLine."Item No.");
        if RentalItemJnlLine."Prod. Order Comp. Line No." <> 0 then
            ProdOrderComp.SetRange("Line No.", RentalItemJnlLine."Prod. Order Comp. Line No.");
        ProdOrderComp.LockTable();

        RemQtyToPost := RentalItemJnlLine.Quantity;

        OnPostConsumptionOnBeforeFindSetProdOrderComp(ProdOrderComp, RentalItemJnlLine);

        if ProdOrderComp.FindSet() then begin
            /*             if RentalItemJnlLine.TrackingExists and not BlockRetrieveIT then
                            UseItemTrackingApplication :=
                              ItemTrackingMgt.RetrieveConsumpItemTracking(RentalItemJnlLine, TempHandlingSpecification);

                        if UseItemTrackingApplication then begin
                            TempHandlingSpecification.SetTrackingFilterFromItemJnlLine(RentalItemJnlLine);
                            LastLoop := false;
                        end else */
            if ReservationExists(RentalItemJnlLine) then begin
                if ItemTrackingSetup."Serial No. Required" and (RentalItemJnlLine."Serial No." = '') then
                    Error(SerialNoRequiredErr, RentalItemJnlLine."Item No.");
                if ItemTrackingSetup."Lot No. Required" and (RentalItemJnlLine."Lot No." = '') then
                    Error(LotNoRequiredErr, RentalItemJnlLine."Item No.");
            end;

            repeat
                if UseItemTrackingApplication then begin
                    TempHandlingSpecification.SetRange("Source Ref. No.", ProdOrderComp."Line No.");
                    if LastLoop then begin
                        RemQtyToPostThisLine := ProdOrderComp."Remaining Qty. (Base)";
                        if TempHandlingSpecification.FindSet() then
                            repeat
                                CheckItemTrackingOfComp(TempHandlingSpecification, RentalItemJnlLine);
                                RemQtyToPostThisLine += TempHandlingSpecification."Qty. to Handle (Base)";
                            until TempHandlingSpecification.Next() = 0;
                        if RemQtyToPostThisLine * RemQtyToPost < 0 then
                            Error(Text001Lbl); // Assertion: Test signing
                    end else
                        if TempHandlingSpecification.FindFirst() then begin
                            RemQtyToPostThisLine := -TempHandlingSpecification."Qty. to Handle (Base)";
                            TempHandlingSpecification.Delete();
                        end else begin
                            TempHandlingSpecification.ClearTrackingFilter();
                            TempHandlingSpecification.FindFirst();
                            CheckItemTrackingOfComp(TempHandlingSpecification, RentalItemJnlLine);
                            RemQtyToPostThisLine := 0;
                        end;
                    if RemQtyToPostThisLine > RemQtyToPost then
                        RemQtyToPostThisLine := RemQtyToPost;
                end else begin
                    RemQtyToPostThisLine := RemQtyToPost;
                    LastLoop := true;
                end;

                QtyToPost := RemQtyToPostThisLine;
                ProdOrderComp.CalcFields("Act. Consumption (Qty)");
                NewRemainingQty := ProdOrderComp."Expected Qty. (Base)" - ProdOrderComp."Act. Consumption (Qty)" - QtyToPost;
                NewRemainingQty := Round(NewRemainingQty, UOMMgt.QtyRndPrecision);
                if (NewRemainingQty * ProdOrderComp."Expected Qty. (Base)") <= 0 then begin
                    QtyToPost := ProdOrderComp."Remaining Qty. (Base)";
                    ProdOrderComp."Remaining Qty. (Base)" := 0;
                end else begin
                    if (ProdOrderComp."Remaining Qty. (Base)" * ProdOrderComp."Expected Qty. (Base)") >= 0 then
                        QtyToPost := ProdOrderComp."Remaining Qty. (Base)" - NewRemainingQty
                    else
                        QtyToPost := NewRemainingQty;
                    ProdOrderComp."Remaining Qty. (Base)" := NewRemainingQty;
                end;

                ProdOrderComp."Remaining Quantity" := Round(ProdOrderComp."Remaining Qty. (Base)" / ProdOrderComp."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision);

                if QtyToPost <> 0 then begin
                    RemQtyToPost := RemQtyToPost - QtyToPost;
                    ProdOrderComp.Modify();
                    if ProdOrderCompModified then
                        InsertConsumpEntry(ProdOrderComp, ProdOrderComp."Line No.", QtyToPost, false)
                    else
                        InsertConsumpEntry(ProdOrderComp, ProdOrderComp."Line No.", QtyToPost, true);
                    OnPostConsumptionOnAfterInsertEntry(ProdOrderComp);
                end;

                if UseItemTrackingApplication then begin
                    if ProdOrderComp.Next() = 0 then begin
                        EndLoop := LastLoop;
                        LastLoop := true;
                        ProdOrderComp.FindFirst();
                        TempHandlingSpecification.Reset();
                    end;
                end else
                    EndLoop := ProdOrderComp.Next() = 0;

            until EndLoop or (RemQtyToPost = 0);
        end;

        if RemQtyToPost <> 0 then
            InsertConsumpEntry(ProdOrderComp, RentalItemJnlLine."Prod. Order Comp. Line No.", RemQtyToPost, false);

        ProdOrderCompModified := false;

        OnAfterPostConsumption(ProdOrderComp, RentalItemJnlLine);
    end;

    local procedure PostOutput()
    var
        MfgMainRentalItem: Record "TWE Main Rental Item";
        MfgSKU: Record "Stockkeeping Unit";
        MachCenter: Record "Machine Center";
        WorkCenter: Record "Work Center";
        CapLedgEntry: Record "Capacity Ledger Entry";
        ProdOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        DirCostAmt: Decimal;
        IndirCostAmt: Decimal;
        ValuedQty: Decimal;
        MfgUnitCost: Decimal;
        ReTrack: Boolean;
        PostWhseJnlLine: Boolean;
        SkipPost: Boolean;
        ShouldFlushOperation: Boolean;
    begin
        if RentalItemJnlLine."Stop Time" <> 0 then begin
            InsertCapLedgEntry(CapLedgEntry, RentalItemJnlLine."Stop Time", RentalItemJnlLine."Stop Time");
            SkipPost := RentalItemJnlLine.OnlyStopTime();
            OnPostOutputOnAfterInsertCapLedgEntry(RentalItemJnlLine, SkipPost);
            if SkipPost then
                exit;
        end;

        if RentalItemJnlLine.OutputValuePosting() then begin
            PostItem;
            exit;
        end;

        if RentalItemJnlLine.Subcontracting then
            ValuedQty := RentalItemJnlLine."Invoiced Quantity"
        else
            ValuedQty := CalcCapQty;

        if GetItem(RentalItemJnlLine."Item No.", false) then
            /*                 if not CalledFromAdjustment then
                                MainRentalItem.TestField("Inventory Value Zero", false);
             */
            if RentalItemJnlLine."Item Shpt. Entry No." <> 0 then
                CapLedgEntry.Get(RentalItemJnlLine."Item Shpt. Entry No.")
            else begin
                RentalItemJnlLine.TestField("Order Type", RentalItemJnlLine."Order Type"::Production);
                ProdOrder.Get(ProdOrder.Status::Released, RentalItemJnlLine."Order No.");
                ProdOrder.TestField(Blocked, false);
                ProdOrderLine.LockTable();
                ProdOrderLine.Get(ProdOrder.Status::Released, RentalItemJnlLine."Order No.", RentalItemJnlLine."Order Line No.");

                RentalItemJnlLine."Inventory Posting Group" := ProdOrderLine."Inventory Posting Group";

                ProdOrderRtngLine.SetRange(Status, ProdOrderRtngLine.Status::Released);
                ProdOrderRtngLine.SetRange("Prod. Order No.", RentalItemJnlLine."Order No.");
                ProdOrderRtngLine.SetRange("Routing Reference No.", RentalItemJnlLine."Routing Reference No.");
                ProdOrderRtngLine.SetRange("Routing No.", RentalItemJnlLine."Routing No.");
                if ProdOrderRtngLine.FindFirst() then begin
                    RentalItemJnlLine.TestField("Operation No.");
                    RentalItemJnlLine.TestField("No.");

                    if RentalItemJnlLine.Type = RentalItemJnlLine.Type::"Machine Center" then begin
                        MachCenter.Get(RentalItemJnlLine."No.");
                        MachCenter.TestField(Blocked, false);
                    end;
                    WorkCenter.Get(RentalItemJnlLine."Work Center No.");
                    WorkCenter.TestField(Blocked, false);

                    ApplyCapNeed(RentalItemJnlLine."Setup Time (Base)", RentalItemJnlLine."Run Time (Base)");
                end;

                if RentalItemJnlLine."Operation No." <> '' then begin
                    ProdOrderRtngLine.Get(
                      ProdOrderRtngLine.Status::Released, RentalItemJnlLine."Order No.",
                      RentalItemJnlLine."Routing Reference No.", RentalItemJnlLine."Routing No.", RentalItemJnlLine."Operation No.");
                    if RentalItemJnlLine.Finished then
                        ProdOrderRtngLine."Routing Status" := ProdOrderRtngLine."Routing Status"::Finished
                    else
                        ProdOrderRtngLine."Routing Status" := ProdOrderRtngLine."Routing Status"::"In Progress";
                    LastOperation := (not NextOperationExist(ProdOrderRtngLine));
                    OnPostOutputOnBeforeProdOrderRtngLineModify(ProdOrderRtngLine, ProdOrderLine, RentalItemJnlLine);
                    ProdOrderRtngLine.Modify();
                end else
                    LastOperation := true;

                if RentalItemJnlLine.Subcontracting then
                    InsertCapLedgEntry(CapLedgEntry, RentalItemJnlLine.Quantity, RentalItemJnlLine."Invoiced Quantity")
                else
                    InsertCapLedgEntry(CapLedgEntry, ValuedQty, ValuedQty);

                ShouldFlushOperation := RentalItemJnlLine."Output Quantity" >= 0;
                OnBeforeCallFlushOperation(RentalItemJnlLine, ShouldFlushOperation);
                if ShouldFlushOperation then
                    FlushOperation(ProdOrder, ProdOrderLine);
            end;

        CalcDirAndIndirCostAmts(DirCostAmt, IndirCostAmt, ValuedQty, RentalItemJnlLine."Unit Cost", RentalItemJnlLine."Indirect Cost %", RentalItemJnlLine."Overhead Rate");

        InsertCapValueEntry(CapLedgEntry, RentalItemJnlLine."Value Entry Type"::"Direct Cost", ValuedQty, ValuedQty, DirCostAmt);
        InsertCapValueEntry(CapLedgEntry, RentalItemJnlLine."Value Entry Type"::"Indirect Cost", ValuedQty, 0, IndirCostAmt);

        OnPostOutputOnAfterInsertCostValueEntries(RentalItemJnlLine, CapLedgEntry, CalledFromAdjustment, PostToGL);

        if LastOperation and (RentalItemJnlLine."Output Quantity" <> 0) then begin
            CheckItemTracking();
            if (RentalItemJnlLine."Output Quantity" < 0) and not RentalItemJnlLine.Adjustment then begin
                if RentalItemJnlLine."Applies-to Entry" = 0 then
                    RentalItemJnlLine."Applies-to Entry" := FindOpenOutputEntryNoToApply(RentalItemJnlLine);
                RentalItemJnlLine.TestField("Applies-to Entry");
                ItemLedgerEntry.Get(RentalItemJnlLine."Applies-to Entry");
                RentalItemJnlLine.CheckTrackingEqualItemLedgEntry(ItemLedgerEntry);
            end;
            MfgMainRentalItem.Get(ProdOrderLine."Item No.");
            MfgMainRentalItem.TestField("Gen. Prod. Posting Group");

            if RentalItemJnlLine.Subcontracting then
                MfgUnitCost := ProdOrderLine."Unit Cost"
            else
                if MfgSKU.Get(ProdOrderLine."Location Code", ProdOrderLine."Item No.", ProdOrderLine."Variant Code") then
                    MfgUnitCost := MfgSKU."Unit Cost"
                else
                    MfgUnitCost := MfgMainRentalItem."Unit Cost";

            RentalItemJnlLine.Amount := RentalItemJnlLine."Output Quantity" * MfgUnitCost;
            RentalItemJnlLine."Amount (ACY)" := ACYMgt.CalcACYAmt(RentalItemJnlLine.Amount, RentalItemJnlLine."Posting Date", false);
            OnPostOutputOnAfterUpdateAmounts(RentalItemJnlLine);

            RentalItemJnlLine."Gen. Bus. Posting Group" := ProdOrder."Gen. Bus. Posting Group";
            RentalItemJnlLine."Gen. Prod. Posting Group" := MfgMainRentalItem."Gen. Prod. Posting Group";
            /*   if "Output Quantity (Base)" * ProdOrderLine."Remaining Qty. (Base)" <= 0 then
                  ReTrack := true
              else
                  if not CalledFromInvtPutawayPick then
                      ReserveProdOrderLine.TransferPOLineToItemJnlLine(
                        ProdOrderLine, RentalItemJnlLine, "Output Quantity (Base)"); */

            PostWhseJnlLine := true;
            OnPostOutputOnBeforeCreateWhseJnlLine(RentalItemJnlLine, PostWhseJnlLine);
            if PostWhseJnlLine then begin
                GetLocation(RentalItemJnlLine."Location Code");
                if Location."Bin Mandatory" and (not CalledFromInvtPutawayPick) then //begin
                                                                                     //WMSMgmt.CreateWhseJnlLineFromOutputJnl(RentalItemJnlLine, WhseJnlLine);
                    WMSMgmt.CheckWhseJnlLine(WhseJnlLine, 2, 0, false);
                //end;
            end;

            RentalItemJnlLine.Description := ProdOrderLine.Description;
            if RentalItemJnlLine.Subcontracting then begin
                RentalItemJnlLine."Document Type" := RentalItemJnlLine."Document Type"::" ";
                RentalItemJnlLine."Document No." := RentalItemJnlLine."Order No.";
                RentalItemJnlLine."Document Line No." := 0;
                RentalItemJnlLine."Invoiced Quantity" := 0;
            end;
            PostItem;
            UpdateProdOrderLine(ProdOrderLine, ReTrack);
            OnPostOutputOnAfterUpdateProdOrderLine(RentalItemJnlLine, WhseJnlLine, GlobalItemLedgEntry);

            if PostWhseJnlLine then
                if Location."Bin Mandatory" and (not CalledFromInvtPutawayPick) then
                    WhseJnlRegisterLine.RegisterWhseJnlLine(WhseJnlLine);
        end;

        OnAfterPostOutput(GlobalItemLedgEntry, ProdOrderLine, RentalItemJnlLine);
    end;

    procedure PostItem()
    var
        IsHandled: Boolean;
    begin
        OnBeforePostItem(RentalItemJnlLine, IsHandled);

        SKUExists := SKU.Get(RentalItemJnlLine."Location Code", RentalItemJnlLine."Item No.", RentalItemJnlLine."Variant Code");
        if RentalItemJnlLine."Item Shpt. Entry No." <> 0 then begin
            RentalItemJnlLine."Location Code" := '';
            RentalItemJnlLine."Variant Code" := '';
        end;

        if GetItem(RentalItemJnlLine."Item No.", false) then begin
            /*  if not CalledFromAdjustment then
                 DisplayErrorIfItemIsBlocked(Item); */
            //MainRentalItem.CheckBlockedByApplWorksheet;
        end;

        if (RentalItemJnlLine."Entry Type" = RentalItemJnlLine."Entry Type"::Transfer) and
           (MainRentalItem."Costing Method" = MainRentalItem."Costing Method"::Average) and
           (RentalItemJnlLine."Applies-to Entry" = 0)
        then begin
            AverageTransfer := true;
            TotalAppliedQty := 0;
        end else
            AverageTransfer := false;

        if RentalItemJnlLine."Job Contract Entry No." <> 0 then
            TransReserveFromJobPlanningLine(RentalItemJnlLine."Job Contract Entry No.", RentalItemJnlLine);

        if MainRentalItem."Costing Method" = MainRentalItem."Costing Method"::Standard then //begin
                                                                                            //"Overhead Rate" := MainRentalItem."Overhead Rate";
            RentalItemJnlLine."Indirect Cost %" := MainRentalItem."Indirect Cost %";
        //end;

        if (RentalItemJnlLine."Value Entry Type" <> RentalItemJnlLine."Value Entry Type"::"Direct Cost") or
           (RentalItemJnlLine."Item Charge No." <> '')
        then begin
            RentalItemJnlLine."Overhead Rate" := 0;
            RentalItemJnlLine."Indirect Cost %" := 0;
        end;

        if (RentalItemJnlLine.Quantity <> 0) and
           (RentalItemJnlLine."Item Charge No." = '') and
           not (RentalItemJnlLine."Value Entry Type" in [RentalItemJnlLine."Value Entry Type"::Revaluation, RentalItemJnlLine."Value Entry Type"::Rounding]) and
           not RentalItemJnlLine.Adjustment
        then
            ItemQtyPosting
        else
            if (RentalItemJnlLine."Invoiced Quantity" <> 0) or RentalItemJnlLine.Adjustment or
               IsInterimRevaluation
            then begin
                if RentalItemJnlLine."Value Entry Type" = RentalItemJnlLine."Value Entry Type"::"Direct Cost" then begin
                    if not GlobalItemLedgEntry.Get(RentalItemJnlLine."Item Shpt. Entry No.") then
                        exit;
                end else
                    GlobalItemLedgEntry.Get(RentalItemJnlLine."Applies-to Entry");
                CorrectOutputValuationDate(GlobalItemLedgEntry);
                InitValueEntry(GlobalValueEntry, GlobalItemLedgEntry);
            end;
        if ((RentalItemJnlLine.Quantity <> 0) or (RentalItemJnlLine."Invoiced Quantity" <> 0)) and
           not (RentalItemJnlLine.Adjustment and (RentalItemJnlLine.Amount = 0) and (RentalItemJnlLine."Amount (ACY)" = 0))
        then
            ItemValuePosting;

        OnPostItemOnBeforeUpdateUnitCost(RentalItemJnlLine, GlobalItemLedgEntry);

        UpdateUnitCost(GlobalValueEntry);

        OnAfterPostItem(RentalItemJnlLine);
    end;

    local procedure InsertConsumpEntry(var ProdOrderComp: Record "Prod. Order Component"; ProdOrderCompLineNo: Integer; QtyBase: Decimal; ModifyProdOrderComp: Boolean)
    var
        PostWhseJnlLine: Boolean;
    begin
        OnBeforeInsertConsumpEntry(ProdOrderComp, QtyBase, ModifyProdOrderComp);

        RentalItemJnlLine.Quantity := QtyBase;
        RentalItemJnlLine."Quantity (Base)" := QtyBase;
        RentalItemJnlLine."Invoiced Quantity" := QtyBase;
        RentalItemJnlLine."Invoiced Qty. (Base)" := QtyBase;
        RentalItemJnlLine."Prod. Order Comp. Line No." := ProdOrderCompLineNo;
        if ModifyProdOrderComp then begin
            /*   if not CalledFromInvtPutawayPick then
                  ReserveProdOrderComp.TransferPOCompToItemJnlLine(ProdOrderComp, RentalItemJnlLine, QtyBase); */
            OnBeforeProdOrderCompModify(ProdOrderComp, RentalItemJnlLine);
            ProdOrderComp.Modify();
        end;

        if RentalItemJnlLine."Value Entry Type" <> RentalItemJnlLine."Value Entry Type"::Revaluation then begin
            GetLocation(RentalItemJnlLine."Location Code");
            if Location."Bin Mandatory" and (not CalledFromInvtPutawayPick) then begin
                //WMSMgmt.CreateWhseJnlLineFromConsumJnl(RentalItemJnlLine, WhseJnlLine);
                WMSMgmt.CheckWhseJnlLine(WhseJnlLine, 3, 0, false);
                PostWhseJnlLine := true;
            end;
        end;

        OnInsertConsumpEntryOnBeforePostItem(RentalItemJnlLine, ProdOrderComp);

        PostItem;
        if PostWhseJnlLine then
            WhseJnlRegisterLine.RegisterWhseJnlLine(WhseJnlLine);

        OnAfterInsertConsumpEntry(WhseJnlLine, ProdOrderComp, QtyBase, PostWhseJnlLine);
    end;

    local procedure CalcCapQty() CapQty: Decimal
    begin
        GetMfgSetup;

        if RentalItemJnlLine."Unit Cost Calculation" = RentalItemJnlLine."Unit Cost Calculation"::Time then begin
            if MfgSetup."Cost Incl. Setup" then
                CapQty := RentalItemJnlLine."Setup Time" + RentalItemJnlLine."Run Time"
            else
                CapQty := RentalItemJnlLine."Run Time";
        end else
            CapQty := RentalItemJnlLine.Quantity + RentalItemJnlLine."Scrap Quantity";
    end;

    local procedure CalcDirAndIndirCostAmts(var DirCostAmt: Decimal; var IndirCostAmt: Decimal; CapQty: Decimal; UnitCost: Decimal; IndirCostPct: Decimal; OvhdRate: Decimal)
    var
        CostAmt: Decimal;
    begin
        CostAmt := Round(CapQty * UnitCost);
        DirCostAmt := Round((CostAmt - CapQty * OvhdRate) / (1 + IndirCostPct / 100));
        IndirCostAmt := CostAmt - DirCostAmt;
    end;

    local procedure ApplyCapNeed(PostedSetupTime: Decimal; PostedRunTime: Decimal)
    var
        ProdOrderCapNeed: Record "Prod. Order Capacity Need";
        TypeHelper: Codeunit "Type Helper";
        TimeToAllocate: Decimal;
        PrevSetupTime: Decimal;
        PrevRunTime: Decimal;
    begin
        ProdOrderCapNeed.LockTable();
        ProdOrderCapNeed.Reset();
        ProdOrderCapNeed.SetCurrentKey(
          Status, "Prod. Order No.", "Routing Reference No.", "Operation No.", Date, "Starting Time");
        ProdOrderCapNeed.SetRange(Status, ProdOrderCapNeed.Status::Released);
        ProdOrderCapNeed.SetRange("Prod. Order No.", RentalItemJnlLine."Order No.");
        ProdOrderCapNeed.SetRange("Requested Only", false);
        ProdOrderCapNeed.SetRange("Routing No.", RentalItemJnlLine."Routing No.");
        ProdOrderCapNeed.SetRange("Routing Reference No.", RentalItemJnlLine."Routing Reference No.");
        ProdOrderCapNeed.SetRange("Operation No.", RentalItemJnlLine."Operation No.");

        if RentalItemJnlLine.Finished then
            ProdOrderCapNeed.ModifyAll("Allocated Time", 0)
        else begin
            OnApplyCapNeedOnAfterSetFilters(ProdOrderCapNeed, RentalItemJnlLine);
            CalcCapLedgerEntriesSetupRunTime(RentalItemJnlLine, PrevSetupTime, PrevRunTime);

            if PostedSetupTime <> 0 then begin
                ProdOrderCapNeed.SetRange("Time Type", ProdOrderCapNeed."Time Type"::"Setup Time");
                PostedSetupTime += PrevSetupTime;
                if ProdOrderCapNeed.FindSet() then
                    repeat
                        TimeToAllocate := TypeHelper.Minimum(ProdOrderCapNeed."Needed Time", PostedSetupTime);
                        ProdOrderCapNeed."Allocated Time" := ProdOrderCapNeed."Needed Time" - TimeToAllocate;
                        ProdOrderCapNeed.Modify();
                        PostedSetupTime -= TimeToAllocate;
                    until ProdOrderCapNeed.Next() = 0;
            end;

            if PostedRunTime <> 0 then begin
                ProdOrderCapNeed.SetRange("Time Type", ProdOrderCapNeed."Time Type"::"Run Time");
                PostedRunTime += PrevRunTime;
                if ProdOrderCapNeed.FindSet() then
                    repeat
                        TimeToAllocate := TypeHelper.Minimum(ProdOrderCapNeed."Needed Time", PostedRunTime);
                        ProdOrderCapNeed."Allocated Time" := ProdOrderCapNeed."Needed Time" - TimeToAllocate;
                        ProdOrderCapNeed.Modify();
                        PostedRunTime -= TimeToAllocate;
                    until ProdOrderCapNeed.Next() = 0;
            end;
        end;
    end;

    local procedure CalcCapLedgerEntriesSetupRunTime(RentalItemJnlLine: Record "TWE Rental Item Journal Line"; var TotalSetupTime: Decimal; var TotalRunTime: Decimal)
    var
        CapLedgerEntry: Record "Capacity Ledger Entry";
    begin
        CapLedgerEntry.SetCurrentKey(
          "Order Type", "Order No.", "Order Line No.", "Routing No.", "Routing Reference No.", "Operation No.", "Last Output Line");
        CapLedgerEntry.SetRange("Order Type", CapLedgerEntry."Order Type"::Production);
        CapLedgerEntry.SetRange("Order No.", RentalItemJnlLine."Order No.");
        CapLedgerEntry.SetRange("Order Line No.", RentalItemJnlLine."Order Line No.");
        CapLedgerEntry.SetRange("Routing No.", RentalItemJnlLine."Routing No.");
        CapLedgerEntry.SetRange("Routing Reference No.", RentalItemJnlLine."Routing Reference No.");
        CapLedgerEntry.SetRange("Operation No.", RentalItemJnlLine."Operation No.");

        CapLedgerEntry.CalcSums("Setup Time", "Run Time");
        TotalSetupTime := CapLedgerEntry."Setup Time";
        TotalRunTime := CapLedgerEntry."Run Time";
    end;

    local procedure UpdateProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ReTrack: Boolean)
    var
        ReservMgt: Codeunit "Reservation Management";
    begin
        OnBeforeUpdateProdOrderLine(ProdOrderLine, RentalItemJnlLine, ReTrack);

        if RentalItemJnlLine."Output Quantity (Base)" > ProdOrderLine."Remaining Qty. (Base)" then
            ReserveProdOrderLine.AssignForPlanning(ProdOrderLine);
        ProdOrderLine."Finished Qty. (Base)" := ProdOrderLine."Finished Qty. (Base)" + RentalItemJnlLine."Output Quantity (Base)";
        ProdOrderLine."Finished Quantity" := ProdOrderLine."Finished Qty. (Base)" / ProdOrderLine."Qty. per Unit of Measure";
        if ProdOrderLine."Finished Qty. (Base)" < 0 then
            ProdOrderLine.FieldError("Finished Quantity", Text000Lbl);
        ProdOrderLine."Remaining Qty. (Base)" := ProdOrderLine."Quantity (Base)" - ProdOrderLine."Finished Qty. (Base)";
        if ProdOrderLine."Remaining Qty. (Base)" < 0 then
            ProdOrderLine."Remaining Qty. (Base)" := 0;
        ProdOrderLine."Remaining Quantity" := ProdOrderLine."Remaining Qty. (Base)" / ProdOrderLine."Qty. per Unit of Measure";
        OnBeforeProdOrderLineModify(ProdOrderLine, RentalItemJnlLine);
        ProdOrderLine.Modify();

        if ReTrack then begin
            ReservMgt.SetReservSource(ProdOrderLine);
            ReservMgt.ClearSurplus;
            ReservMgt.AutoTrack(ProdOrderLine."Remaining Qty. (Base)");
        end;

        OnAfterUpdateProdOrderLine(ProdOrderLine, ReTrack, RentalItemJnlLine);
    end;

    local procedure InsertCapLedgEntry(var CapLedgEntry: Record "Capacity Ledger Entry"; Qty: Decimal; InvdQty: Decimal)
    begin
        if CapLedgEntryNo = 0 then begin
            CapLedgEntry.LockTable();
            CapLedgEntryNo := CapLedgEntry.GetLastEntryNo();
        end;

        CapLedgEntryNo := CapLedgEntryNo + 1;

        CapLedgEntry.Init();
        CapLedgEntry."Entry No." := CapLedgEntryNo;

        CapLedgEntry."Operation No." := RentalItemJnlLine."Operation No.";
        CapLedgEntry.Type := RentalItemJnlLine.Type;
        CapLedgEntry."No." := RentalItemJnlLine."No.";
        CapLedgEntry.Description := RentalItemJnlLine.Description;
        CapLedgEntry."Work Center No." := RentalItemJnlLine."Work Center No.";
        CapLedgEntry."Work Center Group Code" := RentalItemJnlLine."Work Center Group Code";
        CapLedgEntry.Subcontracting := RentalItemJnlLine.Subcontracting;

        CapLedgEntry.Quantity := Qty;
        CapLedgEntry."Invoiced Quantity" := InvdQty;
        CapLedgEntry."Completely Invoiced" := CapLedgEntry."Invoiced Quantity" = CapLedgEntry.Quantity;

        CapLedgEntry."Setup Time" := RentalItemJnlLine."Setup Time";
        CapLedgEntry."Run Time" := RentalItemJnlLine."Run Time";
        CapLedgEntry."Stop Time" := RentalItemJnlLine."Stop Time";

        if RentalItemJnlLine."Unit Cost Calculation" = RentalItemJnlLine."Unit Cost Calculation"::Time then begin
            CapLedgEntry."Cap. Unit of Measure Code" := RentalItemJnlLine."Cap. Unit of Measure Code";
            CapLedgEntry."Qty. per Cap. Unit of Measure" := RentalItemJnlLine."Qty. per Cap. Unit of Measure";
        end;

        CapLedgEntry."Item No." := RentalItemJnlLine."Item No.";
        CapLedgEntry."Variant Code" := RentalItemJnlLine."Variant Code";
        CapLedgEntry."Output Quantity" := RentalItemJnlLine."Output Quantity";
        CapLedgEntry."Scrap Quantity" := RentalItemJnlLine."Scrap Quantity";
        CapLedgEntry."Unit of Measure Code" := RentalItemJnlLine."Unit of Measure Code";
        CapLedgEntry."Qty. per Unit of Measure" := RentalItemJnlLine."Qty. per Unit of Measure";

        CapLedgEntry."Order Type" := RentalItemJnlLine."Order Type";
        CapLedgEntry."Order No." := RentalItemJnlLine."Order No.";
        CapLedgEntry."Order Line No." := RentalItemJnlLine."Order Line No.";
        CapLedgEntry."Routing No." := RentalItemJnlLine."Routing No.";
        CapLedgEntry."Routing Reference No." := RentalItemJnlLine."Routing Reference No.";
        CapLedgEntry."Operation No." := RentalItemJnlLine."Operation No.";

        CapLedgEntry."Posting Date" := RentalItemJnlLine."Posting Date";
        CapLedgEntry."Document Date" := RentalItemJnlLine."Document Date";
        CapLedgEntry."Document No." := RentalItemJnlLine."Document No.";
        CapLedgEntry."External Document No." := RentalItemJnlLine."External Document No.";

        CapLedgEntry."Starting Time" := RentalItemJnlLine."Starting Time";
        CapLedgEntry."Ending Time" := RentalItemJnlLine."Ending Time";
        CapLedgEntry."Concurrent Capacity" := RentalItemJnlLine."Concurrent Capacity";
        CapLedgEntry."Work Shift Code" := RentalItemJnlLine."Work Shift Code";

        CapLedgEntry."Stop Code" := RentalItemJnlLine."Stop Code";
        CapLedgEntry."Scrap Code" := RentalItemJnlLine."Scrap Code";
        CapLedgEntry."Last Output Line" := LastOperation;

        CapLedgEntry."Global Dimension 1 Code" := RentalItemJnlLine."Shortcut Dimension 1 Code";
        CapLedgEntry."Global Dimension 2 Code" := RentalItemJnlLine."Shortcut Dimension 2 Code";
        CapLedgEntry."Dimension Set ID" := RentalItemJnlLine."Dimension Set ID";

        OnBeforeInsertCapLedgEntry(CapLedgEntry, RentalItemJnlLine);

        CapLedgEntry.Insert();

        OnAfterInsertCapLedgEntry(CapLedgEntry, RentalItemJnlLine);

        InsertItemReg(0, 0, 0, CapLedgEntry."Entry No.");
    end;

    local procedure InsertCapValueEntry(var CapLedgEntry: Record "Capacity Ledger Entry"; ValueEntryType: Enum "Cost Entry Type"; ValuedQty: Decimal; InvdQty: Decimal; AdjdCost: Decimal)
    var
        ValueEntry: Record "Value Entry";
    begin
        if (InvdQty = 0) and (AdjdCost = 0) then
            exit;

        ValueEntryNo := ValueEntryNo + 1;

        ValueEntry.Init();
        ValueEntry."Entry No." := ValueEntryNo;
        ValueEntry."Capacity Ledger Entry No." := CapLedgEntry."Entry No.";
        ValueEntry."Entry Type" := ValueEntryType;
        ValueEntry."Item Ledger Entry Type" := ValueEntry."Item Ledger Entry Type"::" ";

        ValueEntry.Type := RentalItemJnlLine.Type;
        ValueEntry."No." := RentalItemJnlLine."No.";
        ValueEntry.Description := RentalItemJnlLine.Description;
        ValueEntry."Order Type" := RentalItemJnlLine."Order Type";
        ValueEntry."Order No." := RentalItemJnlLine."Order No.";
        ValueEntry."Order Line No." := RentalItemJnlLine."Order Line No.";
        ValueEntry."Source Type" := RentalItemJnlLine."Source Type";
        ValueEntry."Source No." := GetSourceNo(RentalItemJnlLine);
        ValueEntry."Invoiced Quantity" := InvdQty;
        ValueEntry."Valued Quantity" := ValuedQty;

        ValueEntry."Cost Amount (Actual)" := AdjdCost;
        ValueEntry."Cost Amount (Actual) (ACY)" := ACYMgt.CalcACYAmt(AdjdCost, RentalItemJnlLine."Posting Date", false);
        OnInsertCapValueEntryOnAfterUpdateCostAmounts(ValueEntry, RentalItemJnlLine);

        ValueEntry."Cost per Unit" :=
          CalcCostPerUnit(ValueEntry."Cost Amount (Actual)", ValueEntry."Valued Quantity", false);
        ValueEntry."Cost per Unit (ACY)" :=
          CalcCostPerUnit(ValueEntry."Cost Amount (Actual) (ACY)", ValueEntry."Valued Quantity", true);
        ValueEntry.Inventoriable := true;

        if RentalItemJnlLine.Type = RentalItemJnlLine.Type::Resource then
            RentalItemJnlLine.TestField("Inventory Posting Group", '')
        else
            RentalItemJnlLine.TestField("Inventory Posting Group");
        ValueEntry."Inventory Posting Group" := RentalItemJnlLine."Inventory Posting Group";
        ValueEntry."Gen. Bus. Posting Group" := RentalItemJnlLine."Gen. Bus. Posting Group";
        ValueEntry."Gen. Prod. Posting Group" := RentalItemJnlLine."Gen. Prod. Posting Group";

        ValueEntry."Posting Date" := RentalItemJnlLine."Posting Date";
        ValueEntry."Valuation Date" := RentalItemJnlLine."Posting Date";
        ValueEntry."Source No." := GetSourceNo(RentalItemJnlLine);
        ValueEntry."Document Type" := RentalItemJnlLine."Document Type";
        if ValueEntry."Expected Cost" or (RentalItemJnlLine."Invoice No." = '') then
            ValueEntry."Document No." := RentalItemJnlLine."Document No."
        else begin
            ValueEntry."Document No." := RentalItemJnlLine."Invoice No.";
            if RentalItemJnlLine."Document Type" in
               [RentalItemJnlLine."Document Type"::"Purchase Receipt", RentalItemJnlLine."Document Type"::"Purchase Return Shipment",
                RentalItemJnlLine."Document Type"::"Sales Shipment", RentalItemJnlLine."Document Type"::"Sales Return Receipt",
                RentalItemJnlLine."Document Type"::"Service Shipment"]
            then
                ValueEntry."Document Type" := "Item Ledger Document Type".FromInteger(RentalItemJnlLine."Document Type".AsInteger() + 1);
        end;
        ValueEntry."Document Line No." := RentalItemJnlLine."Document Line No.";
        ValueEntry."Document Date" := RentalItemJnlLine."Document Date";
        ValueEntry."External Document No." := RentalItemJnlLine."External Document No.";
        ValueEntry."User ID" := UserId;
        ValueEntry."Source Code" := RentalItemJnlLine."Source Code";
        ValueEntry."Reason Code" := RentalItemJnlLine."Reason Code";
        ValueEntry."Journal Batch Name" := RentalItemJnlLine."Journal Batch Name";

        ValueEntry."Global Dimension 1 Code" := RentalItemJnlLine."Shortcut Dimension 1 Code";
        ValueEntry."Global Dimension 2 Code" := RentalItemJnlLine."Shortcut Dimension 2 Code";
        ValueEntry."Dimension Set ID" := RentalItemJnlLine."Dimension Set ID";

        OnBeforeInsertCapValueEntry(ValueEntry, RentalItemJnlLine);

        InventoryPostingToGL.SetRunOnlyCheck(true, not InvtSetup."Automatic Cost Posting", false);
        PostInvtBuffer(ValueEntry);

        ValueEntry.Insert(true);
        OnAfterInsertCapValueEntry(ValueEntry, RentalItemJnlLine);

        UpdateAdjmtProperties(ValueEntry, CapLedgEntry."Posting Date");

        InsertItemReg(0, 0, ValueEntry."Entry No.", 0);
        InsertPostValueEntryToGL(ValueEntry);
        if MainRentalItem."Item Tracking Code" <> '' then begin
            TempValueEntryRelation.Init();
            TempValueEntryRelation."Value Entry No." := ValueEntry."Entry No.";
            TempValueEntryRelation.Insert();
        end;
        if (RentalItemJnlLine."Item Shpt. Entry No." <> 0) and
           (ValueEntryType = RentalItemJnlLine."Value Entry Type"::"Direct Cost")
        then begin
            CapLedgEntry."Invoiced Quantity" := CapLedgEntry."Invoiced Quantity" + RentalItemJnlLine."Invoiced Quantity";
            if RentalItemJnlLine.Subcontracting then
                CapLedgEntry."Completely Invoiced" := CapLedgEntry."Invoiced Quantity" = CapLedgEntry."Output Quantity"
            else
                CapLedgEntry."Completely Invoiced" := CapLedgEntry."Invoiced Quantity" = CapLedgEntry.Quantity;
            CapLedgEntry.Modify();
        end;
    end;

    local procedure ItemQtyPosting()
    var
        IsReserved: Boolean;
    begin
        if RentalItemJnlLine.Quantity <> RentalItemJnlLine."Invoiced Quantity" then
            RentalItemJnlLine.TestField("Invoiced Quantity", 0);
        RentalItemJnlLine.TestField("Item Shpt. Entry No.", 0);

        InitItemLedgEntry(GlobalItemLedgEntry);
        InitValueEntry(GlobalValueEntry, GlobalItemLedgEntry);

        GlobalItemLedgEntry."Remaining Quantity" := 0;
        GlobalItemLedgEntry.Open := false;

        GlobalItemLedgEntry.Positive := GlobalItemLedgEntry.Quantity > 0;
        if GlobalItemLedgEntry."Entry Type" = GlobalItemLedgEntry."Entry Type"::Transfer then
            GlobalItemLedgEntry."Completely Invoiced" := true;

        /* if GlobalItemLedgEntry.Quantity > 0 then
            if GlobalItemLedgEntry."Entry Type" <> GlobalItemLedgEntry."Entry Type"::Transfer then
                IsReserved :=
                  ReserveItemJnlLine.TransferItemJnlToItemLedgEntry(
                    RentalItemJnlLine, GlobalItemLedgEntry, "Quantity (Base)", true); */

        OnItemQtyPostingOnBeforeApplyItemLedgEntry(RentalItemJnlLine, GlobalItemLedgEntry);
        ApplyItemLedgEntry(GlobalItemLedgEntry, OldItemLedgEntry, GlobalValueEntry, false);
        CheckApplFromInProduction(GlobalItemLedgEntry, RentalItemJnlLine."Applies-from Entry");
        AutoTrack(GlobalItemLedgEntry, IsReserved);

        if (RentalItemJnlLine."Entry Type" = RentalItemJnlLine."Entry Type"::Transfer) and AverageTransfer then
            InsertTransferEntry(GlobalItemLedgEntry, OldItemLedgEntry, TotalAppliedQty);

        if RentalItemJnlLine."Entry Type" in [RentalItemJnlLine."Entry Type"::"Assembly Output", RentalItemJnlLine."Entry Type"::"Assembly Consumption"] then
            InsertAsmItemEntryRelation(GlobalItemLedgEntry);

        if (not RentalItemJnlLine."Phys. Inventory") or (RentalItemJnlLine.Quantity <> 0) then begin
            InsertItemLedgEntry(GlobalItemLedgEntry, false);
            if GlobalItemLedgEntry.Positive then
                InsertApplEntry(
                  GlobalItemLedgEntry."Entry No.", GlobalItemLedgEntry."Entry No.",
                  RentalItemJnlLine."Applies-from Entry", 0, GlobalItemLedgEntry."Posting Date",
                  GlobalItemLedgEntry.Quantity, true);
        end;
    end;

    local procedure ItemValuePosting()
    begin
        /* if ("Value Entry Type" = "Value Entry Type"::"Direct Cost") and
           ("Item Charge No." = '') and
           not Adjustment
        then
            if (Quantity = 0) and ("Invoiced Quantity" <> 0) then begin
                if (GlobalValueEntry."Invoiced Quantity" < 0) and
                   (MainRentalItem."Costing Method" = MainRentalItem."Costing Method"::Average)
                then
                    ValuateAppliedAvgEntry(GlobalValueEntry, MainRentalItem);
            end else begin
                if (GlobalValueEntry."Valued Quantity" < 0) and ("Entry Type" <> "Entry Type"::Transfer) then
                    if MainRentalItem."Costing Method" = MainRentalItem."Costing Method"::Average then
                        ValuateAppliedAvgEntry(GlobalValueEntry, MainRentalItem);
            end; */

        InsertValueEntry(GlobalValueEntry, GlobalItemLedgEntry, false);

        OnItemValuePostingOnAfterInsertValueEntry(GlobalValueEntry, GlobalItemLedgEntry, ValueEntryNo);

        if (RentalItemJnlLine."Value Entry Type" <> RentalItemJnlLine."Value Entry Type"::"Direct Cost") or
           (RentalItemJnlLine."Item Charge No." <> '')
        then begin
            if (RentalItemJnlLine."Value Entry Type" <> RentalItemJnlLine."Value Entry Type"::Rounding) and (not RentalItemJnlLine.Adjustment) then begin
                if GlobalItemLedgEntry.Positive then
                    GlobalItemLedgEntry.Modify();
                if ((GlobalValueEntry."Valued Quantity" > 0) or
                    ((RentalItemJnlLine."Applies-to Entry" <> 0) and (RentalItemJnlLine."Entry Type" in [RentalItemJnlLine."Entry Type"::Purchase, RentalItemJnlLine."Entry Type"::"Assembly Output"]))) and
                   (OverheadAmount <> 0)
                then
                    InsertOHValueEntry(GlobalValueEntry, OverheadAmount, OverheadAmountACY);
                if (MainRentalItem."Costing Method" = MainRentalItem."Costing Method"::Standard) and
                   (RentalItemJnlLine."Entry Type" = RentalItemJnlLine."Entry Type"::Purchase) and
                   (GlobalValueEntry."Entry Type" <> GlobalValueEntry."Entry Type"::Revaluation)
                then
                    InsertVarValueEntry(
                      GlobalValueEntry,
                      -GlobalValueEntry."Cost Amount (Actual)" + OverheadAmount,
                      -(GlobalValueEntry."Cost Amount (Actual) (ACY)" + OverheadAmountACY));
            end;
        end else begin
            if IsBalanceExpectedCostFromRev(RentalItemJnlLine) then
                InsertBalanceExpCostRevEntry(GlobalValueEntry);

            if ((GlobalValueEntry."Valued Quantity" > 0) or
                ((RentalItemJnlLine."Applies-to Entry" <> 0) and (RentalItemJnlLine."Entry Type" in [RentalItemJnlLine."Entry Type"::Purchase, RentalItemJnlLine."Entry Type"::"Assembly Output"]))) and
               (OverheadAmount <> 0)
            then
                InsertOHValueEntry(GlobalValueEntry, OverheadAmount, OverheadAmountACY);

            if ((GlobalValueEntry."Valued Quantity" > 0) or (RentalItemJnlLine."Applies-to Entry" <> 0)) and
               (RentalItemJnlLine."Entry Type" = RentalItemJnlLine."Entry Type"::Purchase) and
               (MainRentalItem."Costing Method" = MainRentalItem."Costing Method"::Standard) and
               (Round(VarianceAmount, GLSetup."Amount Rounding Precision") <> 0) or
               VarianceRequired
            then
                InsertVarValueEntry(GlobalValueEntry, VarianceAmount, VarianceAmountACY);
        end;
        if (GlobalValueEntry."Valued Quantity" < 0) and
           (GlobalItemLedgEntry.Quantity = GlobalItemLedgEntry."Invoiced Quantity")
        then
            UpdateItemApplnEntry(GlobalValueEntry."Item Ledger Entry No.", RentalItemJnlLine."Posting Date");

        OnAfterItemValuePosting(GlobalValueEntry, RentalItemJnlLine, MainRentalItem);
    end;

    local procedure FlushOperation(ProdOrder: Record "Production Order"; ProdOrderLine: Record "Prod. Order Line")
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProdOrderComp: Record "Prod. Order Component";
        OldRentalItemJnlLine: Record "TWE Rental Item Journal Line";
        TempOldSplitRentalItemJnlLine: Record "TWE Rental Item Journal Line" temporary;
        OldItemTrackingCode: Record "Item Tracking Code";
        OldItemTrackingSetup: Record "Item Tracking Setup";
        xCalledFromInvtPutawayPick: Boolean;
    begin
        OnBeforeFlushOperation(ProdOrder, ProdOrderLine, RentalItemJnlLine);

        if RentalItemJnlLine."Operation No." = '' then
            exit;

        OldRentalItemJnlLine := RentalItemJnlLine;
        TempOldSplitRentalItemJnlLine.Reset();
        TempOldSplitRentalItemJnlLine.DeleteAll();
        TempSplitRentalItemJnlLine.Reset();
        if TempSplitRentalItemJnlLine.FindSet() then
            repeat
                TempOldSplitRentalItemJnlLine := TempSplitRentalItemJnlLine;
                TempOldSplitRentalItemJnlLine.Insert();
            until TempSplitRentalItemJnlLine.Next() = 0;

        OldItemTrackingSetup := ItemTrackingSetup;
        OldItemTrackingCode := ItemTrackingCode;
        xCalledFromInvtPutawayPick := CalledFromInvtPutawayPick;
        CalledFromInvtPutawayPick := false;

        ProdOrderRoutingLine.Get(
          ProdOrderRoutingLine.Status::Released, OldRentalItemJnlLine."Order No.",
          OldRentalItemJnlLine."Routing Reference No.", OldRentalItemJnlLine."Routing No.", OldRentalItemJnlLine."Operation No.");
        if ProdOrderRoutingLine."Routing Link Code" <> '' then
            ProdOrderComp.SetCurrentKey(Status, "Prod. Order No.", "Routing Link Code", "Flushing Method");

        ProdOrderComp.SetRange("Flushing Method", "Flushing Method"::Forward, "Flushing Method"::"Pick + Backward");
        ProdOrderComp.SetRange("Routing Link Code", ProdOrderRoutingLine."Routing Link Code");
        ProdOrderComp.SetRange(Status, ProdOrderComp.Status::Released);
        ProdOrderComp.SetRange("Prod. Order No.", OldRentalItemJnlLine."Order No.");
        ProdOrderComp.SetRange("Prod. Order Line No.", OldRentalItemJnlLine."Order Line No.");
        if ProdOrderComp.FindSet() then begin
            BlockRetrieveIT := true;
            repeat
                PostFlushedConsump(ProdOrder, ProdOrderLine, ProdOrderComp, ProdOrderRoutingLine, OldRentalItemJnlLine);
            until ProdOrderComp.Next() = 0;
            BlockRetrieveIT := false;
        end;

        RentalItemJnlLine := OldRentalItemJnlLine;
        TempSplitRentalItemJnlLine.Reset();
        TempSplitRentalItemJnlLine.DeleteAll();
        if TempOldSplitRentalItemJnlLine.FindSet() then
            repeat
                TempSplitRentalItemJnlLine := TempOldSplitRentalItemJnlLine;
                TempSplitRentalItemJnlLine.Insert();
            until TempOldSplitRentalItemJnlLine.Next() = 0;

        ItemTrackingSetup := OldItemTrackingSetup;
        ItemTrackingCode := OldItemTrackingCode;
        CalledFromInvtPutawayPick := xCalledFromInvtPutawayPick;

        OnAfterFlushOperation(ProdOrder, ProdOrderLine, RentalItemJnlLine);
    end;

    local procedure PostFlushedConsump(ProdOrder: Record "Production Order"; ProdOrderLine: Record "Prod. Order Line"; ProdOrderComp: Record "Prod. Order Component"; var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; OldRentalItemJnlLine: Record "TWE Rental Item Journal Line")
    var
        CompMainRentalItem: Record "TWE Main Rental Item";
        TempOldTrackingSpecification: Record "Tracking Specification" temporary;
        OutputQtyBase: Decimal;
        QtyToPost: Decimal;
        CalcBasedOn: Option "Actual Output","Expected Output";
        PostItemJnlLine: Boolean;
        DimsAreTaken: Boolean;
        TrackingSpecExists: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostFlushedConsump(ProdOrder, ProdOrderLine, ProdOrderComp, ProdOrderRoutingLine, OldRentalItemJnlLine, IsHandled);
        if IsHandled then
            exit;

        OutputQtyBase := OldRentalItemJnlLine."Output Quantity (Base)" + OldRentalItemJnlLine."Scrap Quantity (Base)";

        CompMainRentalItem.Get(ProdOrderComp."Item No.");
        CompMainRentalItem.TestField("Rounding Precision");

        if ProdOrderComp."Flushing Method" in
           [ProdOrderComp."Flushing Method"::Backward, ProdOrderComp."Flushing Method"::"Pick + Backward"]
        then begin
            QtyToPost :=
              CostCalcMgt.CalcActNeededQtyBase(ProdOrderLine, ProdOrderComp, OutputQtyBase) / ProdOrderComp."Qty. per Unit of Measure";
            if (ProdOrderLine."Remaining Qty. (Base)" = OutputQtyBase) and
               (Abs(QtyToPost - ProdOrderComp."Remaining Quantity") < CompMainRentalItem."Rounding Precision") and
               (ProdOrderComp."Remaining Quantity" <> 0)
            then
                QtyToPost := ProdOrderComp."Remaining Quantity";
        end else
            QtyToPost := ProdOrderComp.GetNeededQty(CalcBasedOn::"Expected Output", true);
        QtyToPost := UOMMgt.RoundToItemRndPrecision(QtyToPost, CompMainRentalItem."Rounding Precision");
        OnPostFlushedConsumpOnAfterCalcQtyToPost(ProdOrder, ProdOrderLine, ProdOrderComp, OutputQtyBase, QtyToPost);
        if QtyToPost = 0 then
            exit;

        RentalItemJnlLine.Init();
        RentalItemJnlLine."Line No." := 0;
        RentalItemJnlLine."Entry Type" := RentalItemJnlLine."Entry Type"::Consumption;
        RentalItemJnlLine.Validate("Posting Date", OldRentalItemJnlLine."Posting Date");
        RentalItemJnlLine."Document No." := OldRentalItemJnlLine."Document No.";
        RentalItemJnlLine."Source No." := ProdOrderLine."Item No.";
        RentalItemJnlLine."Order Type" := RentalItemJnlLine."Order Type"::Production;
        RentalItemJnlLine."Order No." := ProdOrderLine."Prod. Order No.";
        RentalItemJnlLine.Validate("Order Line No.", ProdOrderLine."Line No.");
        RentalItemJnlLine.Validate("Item No.", ProdOrderComp."Item No.");
        RentalItemJnlLine.Validate("Prod. Order Comp. Line No.", ProdOrderComp."Line No.");
        RentalItemJnlLine.Validate("Unit of Measure Code", ProdOrderComp."Unit of Measure Code");
        RentalItemJnlLine.Description := ProdOrderComp.Description;
        RentalItemJnlLine.Validate(Quantity, QtyToPost);
        RentalItemJnlLine.Validate("Unit Cost", ProdOrderComp."Unit Cost");
        RentalItemJnlLine."Location Code" := ProdOrderComp."Location Code";
        RentalItemJnlLine."Bin Code" := ProdOrderComp."Bin Code";
        RentalItemJnlLine."Variant Code" := ProdOrderComp."Variant Code";
        RentalItemJnlLine."Source Code" := SourceCodeSetup.Flushing;
        RentalItemJnlLine."Gen. Bus. Posting Group" := ProdOrder."Gen. Bus. Posting Group";
        RentalItemJnlLine."Gen. Prod. Posting Group" := CompMainRentalItem."Gen. Prod. Posting Group";

        TempOldTrackingSpecification.Reset();
        TempOldTrackingSpecification.DeleteAll();
        TempTrackingSpecification.Reset();
        if TempTrackingSpecification.FindSet() then
            repeat
                TempOldTrackingSpecification := TempTrackingSpecification;
                TempOldTrackingSpecification.Insert();
            until TempTrackingSpecification.Next() = 0;
        /*   ReserveProdOrderComp.TransferPOCompToItemJnlLine(
            ProdOrderComp, RentalItemJnlLine, Round(QtyToPost * ProdOrderComp."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision)); */

        OnBeforePostFlushedConsumpItemJnlLine(RentalItemJnlLine);

        PrepareItem(RentalItemJnlLine);
        //TrackingSpecExists := ItemTrackingMgt.RetrieveItemTracking(RentalItemJnlLine, TempTrackingSpecification);
        PostItemJnlLine := SetupSplitJnlLine(RentalItemJnlLine, TrackingSpecExists);

        while SplitItemJnlLine(RentalItemJnlLine, PostItemJnlLine) do begin
            if ItemTrackingSetup."Serial No. Required" and (RentalItemJnlLine."Serial No." = '') then
                Error(SerialNoRequiredErr, RentalItemJnlLine."Item No.");
            if ItemTrackingSetup."Lot No. Required" and (RentalItemJnlLine."Lot No." = '') then
                Error(LotNoRequiredErr, RentalItemJnlLine."Item No.");

            if not DimsAreTaken then begin
                RentalItemJnlLine."Dimension Set ID" := GetCombinedDimSetID(ProdOrderLine."Dimension Set ID", ProdOrderComp."Dimension Set ID");
                DimsAreTaken := true;
            end;
            RentalItemJnlCheckLine.RunCheck(RentalItemJnlLine);
            ProdOrderCompModified := true;
            RentalItemJnlLine.Quantity := RentalItemJnlLine."Quantity (Base)";
            RentalItemJnlLine."Invoiced Quantity" := RentalItemJnlLine."Invoiced Qty. (Base)";
            QtyPerUnitOfMeasure := RentalItemJnlLine."Qty. per Unit of Measure";

            RentalItemJnlLine."Unit Amount" := Round(
                RentalItemJnlLine."Unit Amount" / QtyPerUnitOfMeasure, GLSetup."Unit-Amount Rounding Precision");
            RentalItemJnlLine."Unit Cost" := Round(
                RentalItemJnlLine."Unit Cost" / QtyPerUnitOfMeasure, GLSetup."Unit-Amount Rounding Precision");
            RentalItemJnlLine."Unit Cost (ACY)" := Round(
                RentalItemJnlLine."Unit Cost (ACY)" / QtyPerUnitOfMeasure, Currency."Unit-Amount Rounding Precision");
            PostConsumption;
        end;

        TempTrackingSpecification.Reset();
        TempTrackingSpecification.DeleteAll();
        if TempOldTrackingSpecification.FindSet() then
            repeat
                TempTrackingSpecification := TempOldTrackingSpecification;
                TempTrackingSpecification.Insert();
            until TempOldTrackingSpecification.Next() = 0;

        OnAfterPostFlushedConsump(ProdOrderComp, ProdOrderRoutingLine, OldRentalItemJnlLine);
    end;

    local procedure UpdateUnitCost(ValueEntry: Record "Value Entry")
    var
        ItemCostMgt: Codeunit ItemCostManagement;
        LastDirectCost: Decimal;
        TotalAmount: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateUnitCost(ValueEntry, IsHandled, RentalItemJnlLine);
        if IsHandled then
            exit;

        if (ValueEntry."Valued Quantity" > 0) and not (ValueEntry."Expected Cost" or RentalItemJnlLine.Adjustment) then begin
            MainRentalItem.LockTable();
            if not MainRentalItem.Find() then
                exit;

            if ValueEntry.IsInbound() and
               ((ValueEntry."Cost Amount (Actual)" + ValueEntry."Discount Amount" > 0) or MainRentalItem.IsNonInventoriableType) and
               (RentalItemJnlLine."Value Entry Type" = RentalItemJnlLine."Value Entry Type"::"Direct Cost") and
               (RentalItemJnlLine."Item Charge No." = '') //and not MainRentalItem."Inventory Value Zero"
            then begin
                TotalAmount := RentalItemJnlLine.Amount + RentalItemJnlLine."Discount Amount";
                IsHandled := false;
                OnUpdateUnitCostOnBeforeCalculateLastDirectCost(TotalAmount, RentalItemJnlLine, ValueEntry, MainRentalItem, IsHandled);
                if not IsHandled then
                    LastDirectCost := Round(TotalAmount / ValueEntry."Valued Quantity", GLSetup."Unit-Amount Rounding Precision")
            end;

            if ValueEntry."Drop Shipment" then begin
                if LastDirectCost <> 0 then begin
                    MainRentalItem."Last Direct Cost" := LastDirectCost;
                    MainRentalItem.Modify();
                    ItemCostMgt.SetProperties(false, ValueEntry."Invoiced Quantity");
                    //ItemCostMgt.FindUpdateUnitCostSKU(MainRentalItem, "Location Code", "Variant Code", true, LastDirectCost);
                end;
            end else //begin
                ItemCostMgt.SetProperties(false, ValueEntry."Invoiced Quantity");
            //ItemCostMgt.UpdateUnitCost(MainRentalItem, "Location Code", "Variant Code", LastDirectCost, 0, true, true, false, 0);
            //end;
        end;
        OnAfterUpdateUnitCost(ValueEntry, LastDirectCost, RentalItemJnlLine);
    end;

    procedure UnApply(ItemApplnEntry: Record "Item Application Entry")
    var
        ItemLedgEntry1: Record "Item Ledger Entry";
        ItemLedgEntry2: Record "Item Ledger Entry";
        CostItemLedgEntry: Record "Item Ledger Entry";
        InventoryPeriod: Record "Inventory Period";
        Valuationdate: Date;
    begin
        if not InventoryPeriod.IsValidDate(ItemApplnEntry."Posting Date") then
            InventoryPeriod.ShowError(ItemApplnEntry."Posting Date");

        // If we can't get both entries then the application is not a real application or a date compression might have been done
        ItemLedgEntry1.Get(ItemApplnEntry."Inbound Item Entry No.");
        ItemLedgEntry2.Get(ItemApplnEntry."Outbound Item Entry No.");

        if ItemApplnEntry."Item Ledger Entry No." = ItemApplnEntry."Inbound Item Entry No." then
            CheckItemCorrection(ItemLedgEntry1);
        if ItemApplnEntry."Item Ledger Entry No." = ItemApplnEntry."Outbound Item Entry No." then
            CheckItemCorrection(ItemLedgEntry2);

        if ItemLedgEntry1."Drop Shipment" and ItemLedgEntry2."Drop Shipment" then
            Error(Text024Lbl);

        if ItemLedgEntry2."Entry Type" = ItemLedgEntry2."Entry Type"::Transfer then
            Error(Text023Lbl);

        ItemApplnEntry.TestField("Transferred-from Entry No.", 0);

        // We won't allow deletion of applications for deleted items
        GetItem(ItemLedgEntry1."Item No.", true);
        CostItemLedgEntry.Get(ItemApplnEntry.CostReceiver); // costreceiver

        OnUnApplyOnBeforeUpdateItemLedgerEntries(ItemLedgEntry1, ItemLedgEntry2);

        if ItemLedgEntry1."Applies-to Entry" = ItemLedgEntry2."Entry No." then
            ItemLedgEntry1."Applies-to Entry" := 0;

        if ItemLedgEntry2."Applies-to Entry" = ItemLedgEntry1."Entry No." then
            ItemLedgEntry2."Applies-to Entry" := 0;

        // only if real/quantity application
        if not ItemApplnEntry.CostApplication then begin
            ItemLedgEntry1."Remaining Quantity" := ItemLedgEntry1."Remaining Quantity" - ItemApplnEntry.Quantity;
            ItemLedgEntry1.Open := ItemLedgEntry1."Remaining Quantity" <> 0;
            ItemLedgEntry1.Modify();

            ItemLedgEntry2."Remaining Quantity" := ItemLedgEntry2."Remaining Quantity" + ItemApplnEntry.Quantity;
            ItemLedgEntry2.Open := ItemLedgEntry2."Remaining Quantity" <> 0;
            ItemLedgEntry2.Modify();
        end else begin
            ItemLedgEntry2."Shipped Qty. Not Returned" := ItemLedgEntry2."Shipped Qty. Not Returned" - Abs(ItemApplnEntry.Quantity);
            if Abs(ItemLedgEntry2."Shipped Qty. Not Returned") > Abs(ItemLedgEntry2.Quantity) then
                ItemLedgEntry2.FieldError("Shipped Qty. Not Returned", Text004Lbl); // Assert - should never happen
            ItemLedgEntry2.Modify();

            // If cost application we need to insert a 0 application instead if there is none before
            if ItemApplnEntry.Quantity > 0 then
                if not ZeroApplication(ItemApplnEntry."Item Ledger Entry No.") then
                    InsertApplEntry(
                      ItemApplnEntry."Item Ledger Entry No.", ItemApplnEntry."Inbound Item Entry No.",
                      0, 0, ItemApplnEntry."Posting Date", ItemApplnEntry.Quantity, true);
        end;

        if MainRentalItem."Costing Method" = MainRentalItem."Costing Method"::Average then
            if ItemApplnEntry.Fixed then
                UpdateValuedByAverageCost(CostItemLedgEntry."Entry No.", true);

        ItemApplnEntry.InsertHistory;
        TouchEntry(ItemApplnEntry."Inbound Item Entry No.");
        SaveTouchedEntry(ItemApplnEntry."Inbound Item Entry No.", true);
        if ItemApplnEntry."Outbound Item Entry No." <> 0 then begin
            TouchEntry(ItemApplnEntry."Outbound Item Entry No.");
            SaveTouchedEntry(ItemApplnEntry."Inbound Item Entry No.", false);
        end;

        OnUnApplyOnBeforeItemApplnEntryDelete(ItemApplnEntry);
        ItemApplnEntry.Delete();

        Valuationdate := GetMaxAppliedValuationdate(CostItemLedgEntry);
        if Valuationdate = 0D then
            Valuationdate := CostItemLedgEntry."Posting Date"
        else
            Valuationdate := Max(CostItemLedgEntry."Posting Date", Valuationdate);

        SetValuationDateAllValueEntrie(CostItemLedgEntry."Entry No.", Valuationdate, false);

        UpdateLinkedValuationUnapply(Valuationdate, CostItemLedgEntry."Entry No.", CostItemLedgEntry.Positive);
    end;

    procedure ReApply(ItemLedgEntry: Record "Item Ledger Entry"; ApplyWith: Integer)
    var
        ItemLedgEntry2: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        InventoryPeriod: Record "Inventory Period";
        CostApplication: Boolean;
    begin
        GetItem(ItemLedgEntry."Item No.", true);

        if not InventoryPeriod.IsValidDate(ItemLedgEntry."Posting Date") then
            InventoryPeriod.ShowError(ItemLedgEntry."Posting Date");

        /*   ItemTrackingCode.Code := MainRentalItem."Item Tracking Code";
          ItemTrackingMgt.GetItemTrackingSetup(
              ItemTrackingCode, RentalItemJnlLine."Entry Type".AsInteger(), RentalItemJnlLine.Signed(RentalItemJnlLine."Quantity (Base)") > 0, ItemTrackingSetup); */

        TotalAppliedQty := 0;
        CostApplication := false;
        if ApplyWith <> 0 then begin
            ItemLedgEntry2.Get(ApplyWith);
            if ItemLedgEntry2.Quantity > 0 then begin
                // Switch around so ItemLedgEntry is positive and ItemLedgEntry2 is negative
                OldItemLedgEntry := ItemLedgEntry;
                ItemLedgEntry := ItemLedgEntry2;
                ItemLedgEntry2 := OldItemLedgEntry;
            end;

            OnReApplyOnBeforeStartApply(ItemLedgEntry, ItemLedgEntry2);

            if not ((ItemLedgEntry.Quantity > 0) and // not(Costprovider(ItemLedgEntry))
                    ((ItemLedgEntry."Entry Type" = ItemLedgEntry2."Entry Type"::Purchase) or
                     (ItemLedgEntry."Entry Type" = ItemLedgEntry2."Entry Type"::"Positive Adjmt.") or
                     (ItemLedgEntry."Entry Type" = ItemLedgEntry2."Entry Type"::Output) or
                     (ItemLedgEntry."Entry Type" = ItemLedgEntry2."Entry Type"::"Assembly Output"))
                    )
            then
                CostApplication := true;
            if (ItemLedgEntry."Remaining Quantity" <> 0) and (ItemLedgEntry2."Remaining Quantity" <> 0) then
                CostApplication := false;
            if CostApplication then
                CostApply(ItemLedgEntry, ItemLedgEntry2)
            else begin
                CreateItemJnlLineFromEntry(ItemLedgEntry2, ItemLedgEntry2."Remaining Quantity", RentalItemJnlLine);
                if ApplyWith = ItemLedgEntry2."Entry No." then
                    ItemLedgEntry2."Applies-to Entry" := ItemLedgEntry."Entry No."
                else
                    ItemLedgEntry2."Applies-to Entry" := ApplyWith;
                RentalItemJnlLine."Applies-to Entry" := ItemLedgEntry2."Applies-to Entry";
                GlobalItemLedgEntry := ItemLedgEntry2;
                ApplyItemLedgEntry(ItemLedgEntry2, OldItemLedgEntry, ValueEntry, false);
                TouchItemEntryCost(ItemLedgEntry2, false);
                ItemLedgEntry2.Modify();
                EnsureValueEntryLoaded(ValueEntry, ItemLedgEntry2);
                GetValuationDate(ValueEntry, ItemLedgEntry);
                UpdateLinkedValuationDate(ValueEntry."Valuation Date", GlobalItemLedgEntry."Entry No.", GlobalItemLedgEntry.Positive);
            end;

            if ItemApplnEntry.Fixed and (ItemApplnEntry.CostReceiver <> 0) then
                if GetItem(ItemLedgEntry."Item No.", false) then
                    if MainRentalItem."Costing Method" = MainRentalItem."Costing Method"::Average then
                        UpdateValuedByAverageCost(ItemApplnEntry.CostReceiver, false);
        end else begin  // ApplyWith is 0
            ItemLedgEntry."Applies-to Entry" := ApplyWith;
            CreateItemJnlLineFromEntry(ItemLedgEntry, ItemLedgEntry."Remaining Quantity", RentalItemJnlLine);
            RentalItemJnlLine."Applies-to Entry" := ItemLedgEntry."Applies-to Entry";
            GlobalItemLedgEntry := ItemLedgEntry;
            ApplyItemLedgEntry(ItemLedgEntry, OldItemLedgEntry, ValueEntry, false);
            TouchItemEntryCost(ItemLedgEntry, false);
            ItemLedgEntry.Modify();
            EnsureValueEntryLoaded(ValueEntry, ItemLedgEntry);
            GetValuationDate(ValueEntry, ItemLedgEntry);
            UpdateLinkedValuationDate(ValueEntry."Valuation Date", GlobalItemLedgEntry."Entry No.", GlobalItemLedgEntry.Positive);
        end;
    end;

    local procedure CostApply(var ItemLedgEntry: Record "Item Ledger Entry"; ItemLedgEntry2: Record "Item Ledger Entry")
    var
        ApplyWithItemLedgEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
    begin
        if ItemLedgEntry.Quantity > 0 then begin
            GlobalItemLedgEntry := ItemLedgEntry;
            ApplyWithItemLedgEntry := ItemLedgEntry2;
        end
        else begin
            GlobalItemLedgEntry := ItemLedgEntry2;
            ApplyWithItemLedgEntry := ItemLedgEntry;
        end;
        if not ItemApplnEntry.CheckIsCyclicalLoop(ApplyWithItemLedgEntry, GlobalItemLedgEntry) then begin
            CreateItemJnlLineFromEntry(GlobalItemLedgEntry, GlobalItemLedgEntry.Quantity, RentalItemJnlLine);
            InsertApplEntry(
              GlobalItemLedgEntry."Entry No.", GlobalItemLedgEntry."Entry No.",
              ApplyWithItemLedgEntry."Entry No.", 0, GlobalItemLedgEntry."Posting Date",
              GlobalItemLedgEntry.Quantity, true);
            UpdateOutboundItemLedgEntry(ApplyWithItemLedgEntry."Entry No.");
            OldItemLedgEntry.Get(ApplyWithItemLedgEntry."Entry No.");
            EnsureValueEntryLoaded(ValueEntry, GlobalItemLedgEntry);
            RentalItemJnlLine."Applies-from Entry" := ApplyWithItemLedgEntry."Entry No.";
            GetAppliedFromValues(ValueEntry);
            SetValuationDateAllValueEntrie(GlobalItemLedgEntry."Entry No.", ValueEntry."Valuation Date", false);
            UpdateLinkedValuationDate(ValueEntry."Valuation Date", GlobalItemLedgEntry."Entry No.", GlobalItemLedgEntry.Positive);
            TouchItemEntryCost(ItemLedgEntry2, false);
        end;
    end;

    local procedure ZeroApplication(EntryNo: Integer): Boolean
    var
        Application: Record "Item Application Entry";
    begin
        Application.SetCurrentKey("Inbound Item Entry No.", "Item Ledger Entry No.");
        Application.SetRange("Item Ledger Entry No.", EntryNo);
        Application.SetRange("Inbound Item Entry No.", EntryNo);
        Application.SetRange("Outbound Item Entry No.", 0);
        exit(not Application.IsEmpty);
    end;

    local procedure ApplyItemLedgEntry(var ItemLedgEntry: Record "Item Ledger Entry"; var OldItemLedgEntry: Record "Item Ledger Entry"; var ValueEntry: Record "Value Entry"; CausedByTransfer: Boolean)
    var
        ItemLedgEntry2: Record "Item Ledger Entry";
        OldValueEntry: Record "Value Entry";
        ReservEntry: Record "Reservation Entry";
        ReservEntry2: Record "Reservation Entry";
        AppliesFromItemLedgEntry: Record "Item Ledger Entry";
        EntryFindMethod: Text[1];
        AppliedQty: Decimal;
        FirstReservation: Boolean;
        FirstApplication: Boolean;
        StartApplication: Boolean;
        UseReservationApplication: Boolean;
        Handled: Boolean;
    begin
        OnBeforeApplyItemLedgEntry(ItemLedgEntry, OldItemLedgEntry, ValueEntry, CausedByTransfer, Handled);
        if Handled then
            exit;

        if (ItemLedgEntry."Remaining Quantity" = 0) or
           (ItemLedgEntry."Drop Shipment" and (ItemLedgEntry."Applies-to Entry" = 0)) or
           ((MainRentalItem."Costing Method" = MainRentalItem."Costing Method"::Specific) and ItemLedgEntry.Positive) or
           (RentalItemJnlLine."Direct Transfer" and (ItemLedgEntry."Location Code" = '') and ItemLedgEntry.Positive)
        then
            exit;

        Clear(OldItemLedgEntry);
        FirstReservation := true;
        FirstApplication := true;
        StartApplication := false;
        repeat
            if RentalItemJnlLine."Assemble to Order" then
                VerifyItemJnlLineAsembleToOrder(RentalItemJnlLine)
            else
                VerifyItemJnlLineApplication(RentalItemJnlLine, ItemLedgEntry);

            if not CausedByTransfer and not PostponeReservationHandling then begin
                if MainRentalItem."Costing Method" = MainRentalItem."Costing Method"::Specific then
                    RentalItemJnlLine.TestField("Serial No.");

                if FirstReservation then begin
                    FirstReservation := false;
                    ReservEntry.Reset();
                    ReservEntry.SetCurrentKey(
                      "Source ID", "Source Ref. No.", "Source Type", "Source Subtype",
                      "Source Batch Name", "Source Prod. Order Line", "Reservation Status");
                    ReservEntry.SetRange("Reservation Status", ReservEntry."Reservation Status"::Reservation);
                    //ReserveItemJnlLine.FilterReservFor(ReservEntry, RentalItemJnlLine);
                end;

                UseReservationApplication := ReservEntry.FindFirst();

                if not UseReservationApplication then begin // No reservations exist
                    ReservEntry.SetRange(
                      "Reservation Status", ReservEntry."Reservation Status"::Tracking,
                      ReservEntry."Reservation Status"::Prospect);
                    if ReservEntry.FindSet() then
                        repeat
                            ReservEngineMgt.CloseSurplusTrackingEntry(ReservEntry);
                        until ReservEntry.Next() = 0;
                    StartApplication := true;
                end;

                if UseReservationApplication then begin
                    ReservEntry2.Get(ReservEntry."Entry No.", not ReservEntry.Positive);
                    if ReservEntry2."Source Type" <> DATABASE::"Item Ledger Entry" then
                        if ItemLedgEntry.Quantity < 0 then
                            Error(Text003Lbl, ReservEntry."Item No.");
                    OldItemLedgEntry.Get(ReservEntry2."Source Ref. No.");
                    if ItemLedgEntry.Quantity < 0 then
                        if OldItemLedgEntry."Remaining Quantity" < ReservEntry2."Quantity (Base)" then
                            Error(Text003Lbl, ReservEntry2."Item No.");

                    OldItemLedgEntry.TestField("Item No.", RentalItemJnlLine."Item No.");
                    OldItemLedgEntry.TestField("Variant Code", RentalItemJnlLine."Variant Code");
                    OldItemLedgEntry.TestField("Location Code", RentalItemJnlLine."Location Code");
                    OnApplyItemLedgEntryOnBeforeCloseReservEntry(OldItemLedgEntry, RentalItemJnlLine, ItemLedgEntry);
                    ReservEngineMgt.CloseReservEntry(ReservEntry, false, false);
                    OldItemLedgEntry.CalcFields("Reserved Quantity");
                    AppliedQty := -Abs(ReservEntry."Quantity (Base)");
                end;
            end else
                StartApplication := true;

            if StartApplication then begin
                ItemLedgEntry.CalcFields("Reserved Quantity");
                if ItemLedgEntry."Applies-to Entry" <> 0 then begin
                    if FirstApplication then begin
                        FirstApplication := false;
                        OldItemLedgEntry.Get(ItemLedgEntry."Applies-to Entry");
                        TestFirstApplyItemLedgEntry(OldItemLedgEntry, ItemLedgEntry);
                    end else
                        exit;
                end else begin
                    if FirstApplication then begin
                        FirstApplication := false;
                        ApplyItemLedgEntrySetFilters(ItemLedgEntry2, ItemLedgEntry, ItemTrackingCode);

                        if MainRentalItem."Costing Method" = MainRentalItem."Costing Method"::LIFO then
                            EntryFindMethod := '+'
                        else
                            EntryFindMethod := '-';
                        if not ItemLedgEntry2.Find(EntryFindMethod) then
                            exit;
                    end else
                        case EntryFindMethod of
                            '-':
                                if ItemLedgEntry2.Next() = 0 then
                                    exit;
                            '+':
                                if ItemLedgEntry2.Next(-1) = 0 then
                                    exit;
                        end;
                    OldItemLedgEntry.Copy(ItemLedgEntry2)
                end;

                OldItemLedgEntry.CalcFields("Reserved Quantity");
                OnAfterApplyItemLedgEntryOnBeforeCalcAppliedQty(OldItemLedgEntry, ItemLedgEntry);

                if Abs(OldItemLedgEntry."Remaining Quantity" - OldItemLedgEntry."Reserved Quantity") >
                   Abs(ItemLedgEntry."Remaining Quantity" - ItemLedgEntry."Reserved Quantity")
                then
                    AppliedQty := ItemLedgEntry."Remaining Quantity" - ItemLedgEntry."Reserved Quantity"
                else
                    AppliedQty := -(OldItemLedgEntry."Remaining Quantity" - OldItemLedgEntry."Reserved Quantity");

                OnApplyItemLedgEntryOnAfterCalcAppliedQty(OldItemLedgEntry, ItemLedgEntry, AppliedQty);

                if ItemLedgEntry."Entry Type" = ItemLedgEntry."Entry Type"::Transfer then
                    if (OldItemLedgEntry."Entry No." > ItemLedgEntry."Entry No.") and not ItemLedgEntry.Positive then
                        AppliedQty := 0;
                if (OldItemLedgEntry."Order Type" = OldItemLedgEntry."Order Type"::Production) and
                   (OldItemLedgEntry."Order No." <> '')
                then
                    if not AllowProdApplication(OldItemLedgEntry, ItemLedgEntry) then
                        AppliedQty := 0;
                if RentalItemJnlLine."Applies-from Entry" <> 0 then begin
                    AppliesFromItemLedgEntry.Get(RentalItemJnlLine."Applies-from Entry");
                    if ItemApplnEntry.CheckIsCyclicalLoop(AppliesFromItemLedgEntry, OldItemLedgEntry) then
                        AppliedQty := 0;
                end;
            end;

            CheckIsCyclicalLoop(ItemLedgEntry, OldItemLedgEntry, PrevAppliedItemLedgEntry, AppliedQty);

            if AppliedQty <> 0 then begin
                if not OldItemLedgEntry.Positive and
                   (OldItemLedgEntry."Remaining Quantity" = -AppliedQty) and
                   (OldItemLedgEntry."Entry No." = ItemLedgEntry."Applies-to Entry")
                then begin
                    OldValueEntry.SetCurrentKey("Item Ledger Entry No.");
                    OldValueEntry.SetRange("Item Ledger Entry No.", OldItemLedgEntry."Entry No.");
                    if OldValueEntry.Find('-') then
                        repeat
                            if OldValueEntry."Valued By Average Cost" then begin
                                OldValueEntry."Valued By Average Cost" := false;
                                OldValueEntry.Modify();
                            end;
                        until OldValueEntry.Next() = 0;
                end;

                OldItemLedgEntry."Remaining Quantity" := OldItemLedgEntry."Remaining Quantity" + AppliedQty;
                OldItemLedgEntry.Open := OldItemLedgEntry."Remaining Quantity" <> 0;

                if ItemLedgEntry.Positive then begin
                    if ItemLedgEntry."Posting Date" >= OldItemLedgEntry."Posting Date" then
                        InsertApplEntry(
                          OldItemLedgEntry."Entry No.", ItemLedgEntry."Entry No.",
                          OldItemLedgEntry."Entry No.", 0, ItemLedgEntry."Posting Date", -AppliedQty, false)
                    else
                        InsertApplEntry(
                          OldItemLedgEntry."Entry No.", ItemLedgEntry."Entry No.",
                          OldItemLedgEntry."Entry No.", 0, OldItemLedgEntry."Posting Date", -AppliedQty, false);

                    if ItemApplnEntry."Cost Application" then
                        ItemLedgEntry."Applied Entry to Adjust" := true;
                end else begin
                    OnApplyItemLedgEntryOnBeforeCheckApplyEntry(OldItemLedgEntry);

                    if ItemTrackingCode."Strict Expiration Posting" and (OldItemLedgEntry."Expiration Date" <> 0D) and
                       not ItemLedgEntry.Correction and
                       not (ItemLedgEntry."Document Type" in
                            [ItemLedgEntry."Document Type"::"Purchase Return Shipment", ItemLedgEntry."Document Type"::"Purchase Credit Memo"])
                    then
                        if ItemLedgEntry."Posting Date" > OldItemLedgEntry."Expiration Date" then
                            if (ItemLedgEntry."Entry Type" <> ItemLedgEntry."Entry Type"::"Negative Adjmt.") and
                               not RentalItemJnlLine.IsReclass(RentalItemJnlLine)
                            then
                                OldItemLedgEntry.FieldError("Expiration Date", Text017Lbl);

                    OnApplyItemLedgEntryOnBeforeInsertApplEntry(ItemLedgEntry, RentalItemJnlLine);

                    InsertApplEntry(
                      ItemLedgEntry."Entry No.", OldItemLedgEntry."Entry No.", ItemLedgEntry."Entry No.", 0,
                      ItemLedgEntry."Posting Date", AppliedQty, true);

                    if ItemApplnEntry."Cost Application" then
                        OldItemLedgEntry."Applied Entry to Adjust" := true;
                end;

                OnApplyItemLedgEntryOnBeforeOldItemLedgEntryModify(ItemLedgEntry, OldItemLedgEntry, RentalItemJnlLine);
                OldItemLedgEntry.Modify();
                AutoTrack(OldItemLedgEntry, true);

                EnsureValueEntryLoaded(ValueEntry, ItemLedgEntry);
                GetValuationDate(ValueEntry, OldItemLedgEntry);

                if (ItemLedgEntry."Entry Type" = ItemLedgEntry."Entry Type"::Transfer) and
                   (AppliedQty < 0) and
                   not CausedByTransfer
                then begin
                    if ItemLedgEntry."Completely Invoiced" then
                        ItemLedgEntry."Completely Invoiced" := OldItemLedgEntry."Completely Invoiced";
                    if AverageTransfer then
                        TotalAppliedQty := TotalAppliedQty + AppliedQty
                    else
                        InsertTransferEntry(ItemLedgEntry, OldItemLedgEntry, AppliedQty);
                end;

                ItemLedgEntry."Remaining Quantity" := ItemLedgEntry."Remaining Quantity" - AppliedQty;
                ItemLedgEntry.Open := ItemLedgEntry."Remaining Quantity" <> 0;

                ItemLedgEntry.CalcFields("Reserved Quantity");
                if ItemLedgEntry."Remaining Quantity" + ItemLedgEntry."Reserved Quantity" = 0 then
                    exit;
            end;
        until false;

        OnAfterApplyItemLedgEntry(GlobalItemLedgEntry, OldItemLedgEntry, RentalItemJnlLine);
    end;

    local procedure ApplyItemLedgEntrySetFilters(var ToItemLedgEntry: Record "Item Ledger Entry"; FromItemLedgEntry: Record "Item Ledger Entry"; ItemTrackingCode: Record "Item Tracking Code")
    var
        Location: Record Location;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeApplyItemLedgEntrySetFilters(ToItemLedgEntry, FromItemLedgEntry, ItemTrackingCode, IsHandled);
        if IsHandled then
            exit;

        ToItemLedgEntry.SetCurrentKey("Item No.", Open, "Variant Code", Positive, "Location Code", "Posting Date");
        ToItemLedgEntry.SetRange("Item No.", FromItemLedgEntry."Item No.");
        ToItemLedgEntry.SetRange(Open, true);
        ToItemLedgEntry.SetRange("Variant Code", FromItemLedgEntry."Variant Code");
        ToItemLedgEntry.SetRange(Positive, not FromItemLedgEntry.Positive);
        ToItemLedgEntry.SetRange("Location Code", FromItemLedgEntry."Location Code");
        if FromItemLedgEntry."Job Purchase" then begin
            ToItemLedgEntry.SetRange("Job No.", FromItemLedgEntry."Job No.");
            ToItemLedgEntry.SetRange("Job Task No.", FromItemLedgEntry."Job Task No.");
            ToItemLedgEntry.SetRange("Document Type", FromItemLedgEntry."Document Type");
            ToItemLedgEntry.SetRange("Document No.", FromItemLedgEntry."Document No.");
        end;
        if ItemTrackingCode."SN Specific Tracking" then
            ToItemLedgEntry.SetRange("Serial No.", FromItemLedgEntry."Serial No.");
        if ItemTrackingCode."Lot Specific Tracking" then
            ToItemLedgEntry.SetRange("Lot No.", FromItemLedgEntry."Lot No.");
        if Location.Get(FromItemLedgEntry."Location Code") then
            if Location."Use As In-Transit" then begin
                ToItemLedgEntry.SetRange("Order Type", FromItemLedgEntry."Order Type"::Transfer);
                ToItemLedgEntry.SetRange("Order No.", FromItemLedgEntry."Order No.");
            end;

        OnAfterApplyItemLedgEntrySetFilters(ToItemLedgEntry, FromItemLedgEntry, RentalItemJnlLine);
    end;

    local procedure TestFirstApplyItemLedgEntry(var OldItemLedgEntry: Record "Item Ledger Entry"; ItemLedgEntry: Record "Item Ledger Entry")
    begin
        OnBeforeTestFirstApplyItemLedgEntry(OldItemLedgEntry, ItemLedgEntry, RentalItemJnlLine);

        OldItemLedgEntry.TestField("Item No.", ItemLedgEntry."Item No.");
        OldItemLedgEntry.TestField("Variant Code", ItemLedgEntry."Variant Code");
        OldItemLedgEntry.TestField(Positive, not ItemLedgEntry.Positive);
        OldItemLedgEntry.TestField("Location Code", ItemLedgEntry."Location Code");
        if Location.Get(ItemLedgEntry."Location Code") then
            if Location."Use As In-Transit" then begin
                OldItemLedgEntry.TestField("Order Type", OldItemLedgEntry."Order Type"::Transfer);
                OldItemLedgEntry.TestField("Order No.", ItemLedgEntry."Order No.");
            end;

        if ItemTrackingCode."SN Specific Tracking" then
            OldItemLedgEntry.TestField("Serial No.", ItemLedgEntry."Serial No.");
        if ItemLedgEntry."Drop Shipment" and (OldItemLedgEntry."Serial No." <> '') then
            OldItemLedgEntry.TestField("Serial No.", ItemLedgEntry."Serial No.");

        if ItemTrackingCode."Lot Specific Tracking" then
            OldItemLedgEntry.TestField("Lot No.", ItemLedgEntry."Lot No.");
        if ItemLedgEntry."Drop Shipment" and (OldItemLedgEntry."Lot No." <> '') then
            OldItemLedgEntry.TestField("Lot No.", ItemLedgEntry."Lot No.");

        if not (OldItemLedgEntry.Open and
                (Abs(OldItemLedgEntry."Remaining Quantity" - OldItemLedgEntry."Reserved Quantity") >=
                 Abs(ItemLedgEntry."Remaining Quantity" - ItemLedgEntry."Reserved Quantity")))
        then
            if (Abs(OldItemLedgEntry."Remaining Quantity" - OldItemLedgEntry."Reserved Quantity") <=
                Abs(ItemLedgEntry."Remaining Quantity" - ItemLedgEntry."Reserved Quantity"))
            then begin
                if not MoveApplication(ItemLedgEntry, OldItemLedgEntry) then
                    OldItemLedgEntry.FieldError("Remaining Quantity", Text004Lbl);
            end else
                OldItemLedgEntry.TestField(Open, true);

        OnTestFirstApplyItemLedgEntryOnAfterTestFields(ItemLedgEntry, OldItemLedgEntry, RentalItemJnlLine);

        OldItemLedgEntry.CalcFields("Reserved Quantity");
        CheckApplication(ItemLedgEntry, OldItemLedgEntry);

        if Abs(OldItemLedgEntry."Remaining Quantity") <= Abs(OldItemLedgEntry."Reserved Quantity") then
            ReservationPreventsApplication(ItemLedgEntry."Applies-to Entry", ItemLedgEntry."Item No.", OldItemLedgEntry);

        if (OldItemLedgEntry."Order Type" = OldItemLedgEntry."Order Type"::Production) and
           (OldItemLedgEntry."Order No." <> '')
        then
            if not AllowProdApplication(OldItemLedgEntry, ItemLedgEntry) then
                Error(
                  Text022Lbl,
                  ItemLedgEntry."Entry Type", OldItemLedgEntry."Entry Type", OldItemLedgEntry."Item No.", OldItemLedgEntry."Order No.")
    end;

    local procedure EnsureValueEntryLoaded(var ValueEntry: Record "Value Entry"; ItemLedgEntry: Record "Item Ledger Entry")
    begin
        ValueEntry.SetCurrentKey("Item Ledger Entry No.");
        ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgEntry."Entry No.");
        if ValueEntry.Find('-') then;
    end;

    local procedure AllowProdApplication(OldItemLedgEntry: Record "Item Ledger Entry"; ItemLedgEntry: Record "Item Ledger Entry"): Boolean
    var
        AllowApplication: Boolean;
    begin
        AllowApplication :=
          (OldItemLedgEntry."Entry Type" = ItemLedgEntry."Entry Type") or
          (OldItemLedgEntry."Order No." <> ItemLedgEntry."Order No.") or
          ((OldItemLedgEntry."Order No." = ItemLedgEntry."Order No.") and
           (OldItemLedgEntry."Order Line No." <> ItemLedgEntry."Order Line No."));

        OnBeforeAllowProdApplication(OldItemLedgEntry, ItemLedgEntry, AllowApplication);
        exit(AllowApplication);
    end;

    local procedure InitValueEntryNo()
    begin
        if ValueEntryNo > 0 then
            exit;

        GlobalValueEntry.LockTable();
        ValueEntryNo := GlobalValueEntry.GetLastEntryNo();
    end;

    local procedure InsertTransferEntry(var ItemLedgEntry: Record "Item Ledger Entry"; var OldItemLedgEntry: Record "Item Ledger Entry"; AppliedQty: Decimal)
    var
        NewItemLedgEntry: Record "Item Ledger Entry";
        NewValueEntry: Record "Value Entry";
        ItemLedgEntry2: Record "Item Ledger Entry";
        IsReserved: Boolean;
    begin
        InitItemLedgEntry(NewItemLedgEntry);
        NewItemLedgEntry."Applies-to Entry" := 0;
        NewItemLedgEntry.Quantity := -AppliedQty;
        NewItemLedgEntry."Invoiced Quantity" := NewItemLedgEntry.Quantity;
        NewItemLedgEntry."Remaining Quantity" := NewItemLedgEntry.Quantity;
        NewItemLedgEntry.Open := NewItemLedgEntry."Remaining Quantity" <> 0;
        NewItemLedgEntry.Positive := NewItemLedgEntry."Remaining Quantity" > 0;
        NewItemLedgEntry."Location Code" := RentalItemJnlLine."New Location Code";
        NewItemLedgEntry."Country/Region Code" := RentalItemJnlLine."Country/Region Code";
        InsertCountryCode(NewItemLedgEntry, ItemLedgEntry);
        //NewItemLedgEntry.CopyTrackingFromNewItemJnlLine(RentalItemJnlLine);
        NewItemLedgEntry."Expiration Date" := RentalItemJnlLine."New Item Expiration Date";
        OnInsertTransferEntryOnTransferValues(NewItemLedgEntry, OldItemLedgEntry, ItemLedgEntry, RentalItemJnlLine);

        if MainRentalItem."Item Tracking Code" <> '' then begin
            TempItemEntryRelation."Item Entry No." := NewItemLedgEntry."Entry No."; // Save Entry No. in a global variable
            TempItemEntryRelation.CopyTrackingFromItemLedgEntry(NewItemLedgEntry);
            OnBeforeTempItemEntryRelationInsert(TempItemEntryRelation, NewItemLedgEntry);
            TempItemEntryRelation.Insert();
        end;
        InitTransValueEntry(NewValueEntry, NewItemLedgEntry);

        if AverageTransfer then begin
            InsertApplEntry(
              NewItemLedgEntry."Entry No.", NewItemLedgEntry."Entry No.", ItemLedgEntry."Entry No.",
              0, NewItemLedgEntry."Posting Date", NewItemLedgEntry.Quantity, true);
            NewItemLedgEntry."Completely Invoiced" := ItemLedgEntry."Completely Invoiced";
        end else begin
            InsertApplEntry(
              NewItemLedgEntry."Entry No.", NewItemLedgEntry."Entry No.", ItemLedgEntry."Entry No.",
              OldItemLedgEntry."Entry No.", NewItemLedgEntry."Posting Date", NewItemLedgEntry.Quantity, true);
            NewItemLedgEntry."Completely Invoiced" := OldItemLedgEntry."Completely Invoiced";
        end;
        /* 
                    if NewItemLedgEntry.Quantity > 0 then
                        IsReserved := */
        /*  ReserveItemJnlLine.TransferItemJnlToItemLedgEntry(
           RentalItemJnlLine, NewItemLedgEntry, NewItemLedgEntry."Remaining Quantity", true); */

        ApplyItemLedgEntry(NewItemLedgEntry, ItemLedgEntry2, NewValueEntry, true);
        AutoTrack(NewItemLedgEntry, IsReserved);

        OnBeforeInsertTransferEntry(NewItemLedgEntry, OldItemLedgEntry, RentalItemJnlLine);

        InsertItemLedgEntry(NewItemLedgEntry, true);
        InsertValueEntry(NewValueEntry, NewItemLedgEntry, true);

        UpdateUnitCost(NewValueEntry);
    end;

    local procedure InitItemLedgEntry(var ItemLedgEntry: Record "Item Ledger Entry")
    begin
        ItemLedgEntryNo := ItemLedgEntryNo + 1;

        ItemLedgEntry.Init();
        ItemLedgEntry."Entry No." := ItemLedgEntryNo;
        ItemLedgEntry."Item No." := RentalItemJnlLine."Item No.";
        ItemLedgEntry."Posting Date" := RentalItemJnlLine."Posting Date";
        ItemLedgEntry."Document Date" := RentalItemJnlLine."Document Date";
        ItemLedgEntry."Entry Type" := RentalItemJnlLine."Entry Type";
        ItemLedgEntry."Source No." := RentalItemJnlLine."Source No.";
        ItemLedgEntry."Document No." := RentalItemJnlLine."Document No.";
        ItemLedgEntry."Document Type" := RentalItemJnlLine."Document Type";
        ItemLedgEntry."Document Line No." := RentalItemJnlLine."Document Line No.";
        ItemLedgEntry."Order Type" := RentalItemJnlLine."Order Type";
        ItemLedgEntry."Order No." := RentalItemJnlLine."Order No.";
        ItemLedgEntry."Order Line No." := RentalItemJnlLine."Order Line No.";
        ItemLedgEntry."External Document No." := RentalItemJnlLine."External Document No.";
        ItemLedgEntry.Description := RentalItemJnlLine.Description;
        ItemLedgEntry."Location Code" := RentalItemJnlLine."Location Code";
        ItemLedgEntry."Applies-to Entry" := RentalItemJnlLine."Applies-to Entry";
        ItemLedgEntry."Source Type" := RentalItemJnlLine."Source Type";
        ItemLedgEntry."Transaction Type" := RentalItemJnlLine."Transaction Type";
        ItemLedgEntry."Transport Method" := RentalItemJnlLine."Transport Method";
        ItemLedgEntry."Country/Region Code" := RentalItemJnlLine."Country/Region Code";
        if (RentalItemJnlLine."Entry Type" = RentalItemJnlLine."Entry Type"::Transfer) and (RentalItemJnlLine."New Location Code" <> '') then begin
            if NewLocation.Code <> RentalItemJnlLine."New Location Code" then
                NewLocation.Get(RentalItemJnlLine."New Location Code");
            ItemLedgEntry."Country/Region Code" := NewLocation."Country/Region Code";
        end;
        ItemLedgEntry."Entry/Exit Point" := RentalItemJnlLine."Entry/Exit Point";
        ItemLedgEntry.Area := RentalItemJnlLine.Area;
        ItemLedgEntry."Transaction Specification" := RentalItemJnlLine."Transaction Specification";
        ItemLedgEntry."Drop Shipment" := RentalItemJnlLine."Drop Shipment";
        ItemLedgEntry."Assemble to Order" := RentalItemJnlLine."Assemble to Order";
        ItemLedgEntry."No. Series" := RentalItemJnlLine."Posting No. Series";
        GetInvtSetup;
        if (ItemLedgEntry.Description = MainRentalItem.Description) and not InvtSetup."Copy Item Descr. to Entries" then
            ItemLedgEntry.Description := '';
        ItemLedgEntry."Prod. Order Comp. Line No." := RentalItemJnlLine."Prod. Order Comp. Line No.";
        ItemLedgEntry."Variant Code" := RentalItemJnlLine."Variant Code";
        ItemLedgEntry."Unit of Measure Code" := RentalItemJnlLine."Unit of Measure Code";
        ItemLedgEntry."Qty. per Unit of Measure" := RentalItemJnlLine."Qty. per Unit of Measure";
        ItemLedgEntry."Derived from Blanket Order" := RentalItemJnlLine."Derived from Blanket Order";
        ItemLedgEntry."Item Reference No." := RentalItemJnlLine."Item Reference No.";
        ItemLedgEntry."Originally Ordered No." := RentalItemJnlLine."Originally Ordered No.";
        ItemLedgEntry."Originally Ordered Var. Code" := RentalItemJnlLine."Originally Ordered Var. Code";
        ItemLedgEntry."Out-of-Stock Substitution" := RentalItemJnlLine."Out-of-Stock Substitution";
        ItemLedgEntry."Item Category Code" := RentalItemJnlLine."Item Category Code";
        ItemLedgEntry.Nonstock := RentalItemJnlLine.Nonstock;
        ItemLedgEntry."Purchasing Code" := RentalItemJnlLine."Purchasing Code";
        ItemLedgEntry."Return Reason Code" := RentalItemJnlLine."Return Reason Code";
        ItemLedgEntry."Job No." := RentalItemJnlLine."Job No.";
        ItemLedgEntry."Job Task No." := RentalItemJnlLine."Job Task No.";
        ItemLedgEntry."Job Purchase" := RentalItemJnlLine."Job Purchase";
        //ItemLedgEntry.CopyTrackingFromItemJnlLine(RentalItemJnlLine);
        ItemLedgEntry."Warranty Date" := RentalItemJnlLine."Warranty Date";
        ItemLedgEntry."Expiration Date" := RentalItemJnlLine."Item Expiration Date";
        ItemLedgEntry."Shpt. Method Code" := RentalItemJnlLine."Shpt. Method Code";

        ItemLedgEntry.Correction := RentalItemJnlLine.Correction;

        if RentalItemJnlLine."Entry Type" in
           [RentalItemJnlLine."Entry Type"::Sale,
            RentalItemJnlLine."Entry Type"::"Negative Adjmt.",
            RentalItemJnlLine."Entry Type"::Transfer,
            RentalItemJnlLine."Entry Type"::Consumption,
            RentalItemJnlLine."Entry Type"::"Assembly Consumption"]
        then begin
            ItemLedgEntry.Quantity := -RentalItemJnlLine.Quantity;
            ItemLedgEntry."Invoiced Quantity" := -RentalItemJnlLine."Invoiced Quantity";
        end else begin
            ItemLedgEntry.Quantity := RentalItemJnlLine.Quantity;
            ItemLedgEntry."Invoiced Quantity" := RentalItemJnlLine."Invoiced Quantity";
        end;
        if (ItemLedgEntry.Quantity < 0) and (RentalItemJnlLine."Entry Type" <> RentalItemJnlLine."Entry Type"::Transfer) then
            ItemLedgEntry."Shipped Qty. Not Returned" := ItemLedgEntry.Quantity;

        OnAfterInitItemLedgEntry(ItemLedgEntry, RentalItemJnlLine, ItemLedgEntryNo);
    end;

    local procedure InsertItemLedgEntry(var ItemLedgEntry: Record "Item Ledger Entry"; TransferItem: Boolean)
    var
        IsHandled: Boolean;
    begin
        if ItemLedgEntry.Open then begin
            ItemLedgEntry.VerifyOnInventory;
            if not ((RentalItemJnlLine."Document Type" in [RentalItemJnlLine."Document Type"::"Purchase Return Shipment", RentalItemJnlLine."Document Type"::"Purchase Receipt"]) and
                    (RentalItemJnlLine."Job No." <> ''))
            then
                if (ItemLedgEntry.Quantity < 0) and
                   (ItemTrackingCode."SN Specific Tracking" or ItemTrackingCode."Lot Specific Tracking")
                then
                    Error(Text018Lbl, RentalItemJnlLine."Serial No.", RentalItemJnlLine."Lot No.", RentalItemJnlLine."Item No.", RentalItemJnlLine."Variant Code");

            if ItemTrackingCode."SN Specific Tracking" then begin
                if ItemLedgEntry.Quantity > 0 then
                    CheckItemSerialNo(RentalItemJnlLine);

                IsHandled := false;
                OnInsertItemLedgEntryOnBeforeSNQtyCheck(RentalItemJnlLine, IsHandled);
                if not IsHandled then
                    if not (ItemLedgEntry.Quantity in [-1, 0, 1]) then
                        Error(Text033Lbl);
            end;

            if (RentalItemJnlLine."Document Type" <> RentalItemJnlLine."Document Type"::"Purchase Return Shipment") and (RentalItemJnlLine."Job No." = '') then
                if (MainRentalItem.Reserve = MainRentalItem.Reserve::Always) and (ItemLedgEntry.Quantity < 0) then begin
                    IsHandled := false;
                    OnInsertItemLedgEntryOnBeforeReservationError(RentalItemJnlLine, ItemLedgEntry, IsHandled);
                    if not IsHandled then
                        Error(Text012Lbl, ItemLedgEntry."Item No.");
                end;
        end;

        if IsWarehouseReclassification(RentalItemJnlLine) then begin
            ItemLedgEntry."Global Dimension 1 Code" := OldItemLedgEntry."Global Dimension 1 Code";
            ItemLedgEntry."Global Dimension 2 Code" := OldItemLedgEntry."Global Dimension 2 Code";
            ItemLedgEntry."Dimension Set ID" := OldItemLedgEntry."Dimension Set ID"
        end else
            if TransferItem then begin
                ItemLedgEntry."Global Dimension 1 Code" := RentalItemJnlLine."New Shortcut Dimension 1 Code";
                ItemLedgEntry."Global Dimension 2 Code" := RentalItemJnlLine."New Shortcut Dimension 2 Code";
                ItemLedgEntry."Dimension Set ID" := RentalItemJnlLine."New Dimension Set ID";
            end else begin
                ItemLedgEntry."Global Dimension 1 Code" := RentalItemJnlLine."Shortcut Dimension 1 Code";
                ItemLedgEntry."Global Dimension 2 Code" := RentalItemJnlLine."Shortcut Dimension 2 Code";
                ItemLedgEntry."Dimension Set ID" := RentalItemJnlLine."Dimension Set ID";
            end;

        if not (RentalItemJnlLine."Entry Type" in [RentalItemJnlLine."Entry Type"::Transfer, RentalItemJnlLine."Entry Type"::Output]) and
           (ItemLedgEntry.Quantity = ItemLedgEntry."Invoiced Quantity")
        then
            ItemLedgEntry."Completely Invoiced" := true;

        if (RentalItemJnlLine."Value Entry Type" = RentalItemJnlLine."Value Entry Type"::"Direct Cost") and (RentalItemJnlLine."Item Charge No." = '') and
           (RentalItemJnlLine."Invoiced Quantity" <> 0) and (RentalItemJnlLine."Posting Date" > ItemLedgEntry."Last Invoice Date")
        then
            ItemLedgEntry."Last Invoice Date" := RentalItemJnlLine."Posting Date";

        if RentalItemJnlLine."Entry Type" = RentalItemJnlLine."Entry Type"::Consumption then
            ItemLedgEntry."Applied Entry to Adjust" := true;

        if RentalItemJnlLine."Job No." <> '' then begin
            ItemLedgEntry."Job No." := RentalItemJnlLine."Job No.";
            ItemLedgEntry."Job Task No." := RentalItemJnlLine."Job Task No.";
        end;

        ItemLedgEntry.UpdateItemTracking;

        OnBeforeInsertItemLedgEntry(ItemLedgEntry, RentalItemJnlLine, TransferItem, OldItemLedgEntry);
        ItemLedgEntry.Insert(true);
        OnAfterInsertItemLedgEntry(ItemLedgEntry, RentalItemJnlLine, ItemLedgEntryNo, ValueEntryNo, ItemApplnEntryNo);

        InsertItemReg(ItemLedgEntry."Entry No.", 0, 0, 0);
    end;

    local procedure InsertItemReg(ItemLedgEntryNo: Integer; PhysInvtEntryNo: Integer; ValueEntryNo: Integer; CapLedgEntryNo: Integer)
    begin
        if ItemReg."No." = 0 then begin
            ItemReg.LockTable();
            ItemReg."No." := ItemReg.GetLastEntryNo() + 1;
            ItemReg.Init();
            ItemReg."From Entry No." := ItemLedgEntryNo;
            ItemReg."To Entry No." := ItemLedgEntryNo;
            ItemReg."From Phys. Inventory Entry No." := PhysInvtEntryNo;
            ItemReg."To Phys. Inventory Entry No." := PhysInvtEntryNo;
            ItemReg."From Value Entry No." := ValueEntryNo;
            ItemReg."To Value Entry No." := ValueEntryNo;
            ItemReg."From Capacity Entry No." := CapLedgEntryNo;
            ItemReg."To Capacity Entry No." := CapLedgEntryNo;
            ItemReg."Creation Date" := Today;
            ItemReg."Creation Time" := Time;
            ItemReg."Source Code" := RentalItemJnlLine."Source Code";
            ItemReg."Journal Batch Name" := RentalItemJnlLine."Journal Batch Name";
            ItemReg."User ID" := UserId;
            ItemReg.Insert();
        end else begin
            if ((ItemLedgEntryNo < ItemReg."From Entry No.") and (ItemLedgEntryNo <> 0)) or
               ((ItemReg."From Entry No." = 0) and (ItemLedgEntryNo > 0))
            then
                ItemReg."From Entry No." := ItemLedgEntryNo;
            if ItemLedgEntryNo > ItemReg."To Entry No." then
                ItemReg."To Entry No." := ItemLedgEntryNo;

            if ((PhysInvtEntryNo < ItemReg."From Phys. Inventory Entry No.") and (PhysInvtEntryNo <> 0)) or
               ((ItemReg."From Phys. Inventory Entry No." = 0) and (PhysInvtEntryNo > 0))
            then
                ItemReg."From Phys. Inventory Entry No." := PhysInvtEntryNo;
            if PhysInvtEntryNo > ItemReg."To Phys. Inventory Entry No." then
                ItemReg."To Phys. Inventory Entry No." := PhysInvtEntryNo;

            if ((ValueEntryNo < ItemReg."From Value Entry No.") and (ValueEntryNo <> 0)) or
               ((ItemReg."From Value Entry No." = 0) and (ValueEntryNo > 0))
            then
                ItemReg."From Value Entry No." := ValueEntryNo;
            if ValueEntryNo > ItemReg."To Value Entry No." then
                ItemReg."To Value Entry No." := ValueEntryNo;
            if ((CapLedgEntryNo < ItemReg."From Capacity Entry No.") and (CapLedgEntryNo <> 0)) or
               ((ItemReg."From Capacity Entry No." = 0) and (CapLedgEntryNo > 0))
            then
                ItemReg."From Capacity Entry No." := CapLedgEntryNo;
            if CapLedgEntryNo > ItemReg."To Capacity Entry No." then
                ItemReg."To Capacity Entry No." := CapLedgEntryNo;

            ItemReg.Modify();
        end;
    end;

    local procedure InsertPhysInventoryEntry()
    var
        PhysInvtLedgEntry: Record "Phys. Inventory Ledger Entry";
    begin
        if PhysInvtEntryNo = 0 then begin
            PhysInvtLedgEntry.LockTable();
            PhysInvtEntryNo := PhysInvtLedgEntry.GetLastEntryNo();
        end;

        PhysInvtEntryNo := PhysInvtEntryNo + 1;

        PhysInvtLedgEntry.Init();
        PhysInvtLedgEntry."Entry No." := PhysInvtEntryNo;
        PhysInvtLedgEntry."Item No." := RentalItemJnlLineOrigin."Item No.";
        PhysInvtLedgEntry."Posting Date" := RentalItemJnlLineOrigin."Posting Date";
        PhysInvtLedgEntry."Document Date" := RentalItemJnlLineOrigin."Document Date";
        PhysInvtLedgEntry."Entry Type" := RentalItemJnlLineOrigin."Entry Type";
        PhysInvtLedgEntry."Document No." := RentalItemJnlLineOrigin."Document No.";
        PhysInvtLedgEntry."External Document No." := RentalItemJnlLineOrigin."External Document No.";
        PhysInvtLedgEntry.Description := RentalItemJnlLineOrigin.Description;
        PhysInvtLedgEntry."Location Code" := RentalItemJnlLineOrigin."Location Code";
        PhysInvtLedgEntry."Inventory Posting Group" := RentalItemJnlLineOrigin."Inventory Posting Group";
        PhysInvtLedgEntry."Unit Cost" := RentalItemJnlLineOrigin."Unit Cost";
        PhysInvtLedgEntry.Amount := RentalItemJnlLineOrigin.Amount;
        PhysInvtLedgEntry."Salespers./Purch. Code" := RentalItemJnlLineOrigin."Salespers./Purch. Code";
        PhysInvtLedgEntry."Source Code" := RentalItemJnlLineOrigin."Source Code";
        PhysInvtLedgEntry."Global Dimension 1 Code" := RentalItemJnlLineOrigin."Shortcut Dimension 1 Code";
        PhysInvtLedgEntry."Global Dimension 2 Code" := RentalItemJnlLineOrigin."Shortcut Dimension 2 Code";
        PhysInvtLedgEntry."Dimension Set ID" := RentalItemJnlLineOrigin."Dimension Set ID";
        PhysInvtLedgEntry."Journal Batch Name" := RentalItemJnlLineOrigin."Journal Batch Name";
        PhysInvtLedgEntry."Reason Code" := RentalItemJnlLineOrigin."Reason Code";
        PhysInvtLedgEntry."User ID" := UserId;
        PhysInvtLedgEntry."No. Series" := RentalItemJnlLineOrigin."Posting No. Series";
        GetInvtSetup;
        if (PhysInvtLedgEntry.Description = MainRentalItem.Description) and not InvtSetup."Copy Item Descr. to Entries" then
            PhysInvtLedgEntry.Description := '';
        PhysInvtLedgEntry."Variant Code" := RentalItemJnlLineOrigin."Variant Code";
        PhysInvtLedgEntry."Unit of Measure Code" := RentalItemJnlLineOrigin."Unit of Measure Code";

        PhysInvtLedgEntry.Quantity := RentalItemJnlLineOrigin.Quantity;
        PhysInvtLedgEntry."Unit Amount" := RentalItemJnlLineOrigin."Unit Amount";
        PhysInvtLedgEntry."Qty. (Calculated)" := RentalItemJnlLineOrigin."Qty. (Calculated)";
        PhysInvtLedgEntry."Qty. (Phys. Inventory)" := RentalItemJnlLineOrigin."Qty. (Phys. Inventory)";
        PhysInvtLedgEntry."Last Item Ledger Entry No." := RentalItemJnlLineOrigin."Last Item Ledger Entry No.";

        PhysInvtLedgEntry."Phys Invt Counting Period Code" :=
          RentalItemJnlLineOrigin."Phys Invt Counting Period Code";
        PhysInvtLedgEntry."Phys Invt Counting Period Type" :=
          RentalItemJnlLineOrigin."Phys Invt Counting Period Type";

        OnBeforeInsertPhysInvtLedgEntry(PhysInvtLedgEntry, RentalItemJnlLineOrigin);
        PhysInvtLedgEntry.Insert();

        InsertItemReg(0, PhysInvtLedgEntry."Entry No.", 0, 0);
    end;

    local procedure PostInventoryToGL(var ValueEntry: Record "Value Entry")
    begin
        if CalledFromAdjustment and not PostToGL then
            exit;

        OnBeforePostInventoryToGL(ValueEntry);

        InventoryPostingToGL.SetRunOnlyCheck(true, not PostToGL, false);
        PostInvtBuffer(ValueEntry);

        if ValueEntry."Expected Cost" then begin
            if (ValueEntry."Cost Amount (Expected)" = 0) and (ValueEntry."Cost Amount (Expected) (ACY)" = 0) then
                SetValueEntry(ValueEntry, 1, 1, false)
            else
                SetValueEntry(ValueEntry, ValueEntry."Cost Amount (Expected)", ValueEntry."Cost Amount (Expected) (ACY)", false);
            InventoryPostingToGL.SetRunOnlyCheck(true, true, false);
            PostInvtBuffer(ValueEntry);
            SetValueEntry(ValueEntry, 0, 0, true);
        end else
            if (ValueEntry."Cost Amount (Actual)" = 0) and (ValueEntry."Cost Amount (Actual) (ACY)" = 0) then begin
                SetValueEntry(ValueEntry, 1, 1, false);
                InventoryPostingToGL.SetRunOnlyCheck(true, true, false);
                PostInvtBuffer(ValueEntry);
                SetValueEntry(ValueEntry, 0, 0, false);
            end;

        OnAfterPostInventoryToGL(ValueEntry);
    end;

    local procedure SetValueEntry(var ValueEntry: Record "Value Entry"; CostAmtActual: Decimal; CostAmtActACY: Decimal; ExpectedCost: Boolean)
    begin
        ValueEntry."Cost Amount (Actual)" := CostAmtActual;
        ValueEntry."Cost Amount (Actual) (ACY)" := CostAmtActACY;
        ValueEntry."Expected Cost" := ExpectedCost;
    end;

    local procedure InsertApplEntry(ItemLedgEntryNo: Integer; InboundItemEntry: Integer; OutboundItemEntry: Integer; TransferedFromEntryNo: Integer; PostingDate: Date; Quantity: Decimal; CostToApply: Boolean)
    var
        ApplItemLedgEntry: Record "Item Ledger Entry";
        OldItemApplnEntry: Record "Item Application Entry";
        ItemApplHistoryEntry: Record "Item Application Entry History";
        ItemApplnEntryExists: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertApplEntry(
            ItemLedgEntryNo, InboundItemEntry, OutboundItemEntry, TransferedFromEntryNo, PostingDate, Quantity, CostToApply, IsHandled);
        if IsHandled then
            exit;

        if MainRentalItem.IsNonInventoriableType then
            exit;

        if ItemApplnEntryNo = 0 then begin
            ItemApplnEntry.Reset();
            ItemApplnEntry.LockTable();
            ItemApplnEntryNo := ItemApplnEntry.GetLastEntryNo();
            if ItemApplnEntryNo > 0 then begin
                ItemApplHistoryEntry.Reset();
                ItemApplHistoryEntry.LockTable();
                ItemApplHistoryEntry.SetCurrentKey("Entry No.");
                if ItemApplHistoryEntry.FindLast() then
                    if ItemApplHistoryEntry."Entry No." > ItemApplnEntryNo then
                        ItemApplnEntryNo := ItemApplHistoryEntry."Entry No.";
            end
            else
                ItemApplnEntryNo := 0;
        end;

        if Quantity < 0 then begin
            OldItemApplnEntry.SetCurrentKey("Inbound Item Entry No.", "Item Ledger Entry No.", "Outbound Item Entry No.");
            OldItemApplnEntry.SetRange("Inbound Item Entry No.", InboundItemEntry);
            OldItemApplnEntry.SetRange("Item Ledger Entry No.", ItemLedgEntryNo);
            OldItemApplnEntry.SetRange("Outbound Item Entry No.", OutboundItemEntry);
            if OldItemApplnEntry.FindFirst() then begin
                ItemApplnEntry := OldItemApplnEntry;
                ItemApplnEntry.Quantity := ItemApplnEntry.Quantity + Quantity;
                ItemApplnEntry."Last Modified Date" := CurrentDateTime;
                ItemApplnEntry."Last Modified By User" := UserId;
                ItemApplnEntry.Modify();
                ItemApplnEntryExists := true;
            end;
        end;

        if not ItemApplnEntryExists then begin
            ItemApplnEntryNo := ItemApplnEntryNo + 1;
            ItemApplnEntry.Init();
            ItemApplnEntry."Entry No." := ItemApplnEntryNo;
            ItemApplnEntry."Item Ledger Entry No." := ItemLedgEntryNo;
            ItemApplnEntry."Inbound Item Entry No." := InboundItemEntry;
            ItemApplnEntry."Outbound Item Entry No." := OutboundItemEntry;
            ItemApplnEntry."Transferred-from Entry No." := TransferedFromEntryNo;
            ItemApplnEntry.Quantity := Quantity;
            ItemApplnEntry."Posting Date" := PostingDate;
            ItemApplnEntry."Output Completely Invd. Date" := GetOutputComplInvcdDate(ItemApplnEntry);

            if AverageTransfer then begin
                if (Quantity > 0) or (RentalItemJnlLine."Document Type" = RentalItemJnlLine."Document Type"::"Transfer Receipt") then
                    ItemApplnEntry."Cost Application" := ItemApplnEntry.IsOutbndItemApplEntryCostApplication(ItemLedgEntryNo);
            end else
                case true of
                    MainRentalItem."Costing Method" <> MainRentalItem."Costing Method"::Average,
                  RentalItemJnlLine.Correction and (RentalItemJnlLine."Document Type" = RentalItemJnlLine."Document Type"::"Posted Assembly"):
                        ItemApplnEntry."Cost Application" := true;
                    RentalItemJnlLine.Correction:
                        begin
                            ApplItemLedgEntry.Get(ItemApplnEntry."Item Ledger Entry No.");
                            ItemApplnEntry."Cost Application" :=
                              (ApplItemLedgEntry.Quantity > 0) or (ApplItemLedgEntry."Applies-to Entry" <> 0);
                        end;
                    else
                        if (RentalItemJnlLine."Applies-to Entry" <> 0) or
                           (CostToApply and RentalItemJnlLine.IsInbound)
                        then
                            ItemApplnEntry."Cost Application" := true;
                end;

            ItemApplnEntry."Creation Date" := CurrentDateTime;
            ItemApplnEntry."Created By User" := UserId;
            OnBeforeItemApplnEntryInsert(ItemApplnEntry, GlobalItemLedgEntry, OldItemLedgEntry);
            ItemApplnEntry.Insert(true);
            OnAfterItemApplnEntryInsert(ItemApplnEntry, GlobalItemLedgEntry, OldItemLedgEntry);
        end;
    end;

    local procedure UpdateItemApplnEntry(ItemLedgEntryNo: Integer; PostingDate: Date)
    var
        ItemApplnEntry: Record "Item Application Entry";
    begin
        ItemApplnEntry.SetRange("Item Ledger Entry No.", ItemLedgEntryNo);
        ItemApplnEntry.SetRange("Output Completely Invd. Date", 0D);
        if not ItemApplnEntry.IsEmpty() then
            ItemApplnEntry.ModifyAll("Output Completely Invd. Date", PostingDate);
    end;

    local procedure GetOutputComplInvcdDate(ItemApplnEntry: Record "Item Application Entry"): Date
    var
        OutbndItemLedgEntry: Record "Item Ledger Entry";
    begin
        if ItemApplnEntry.Quantity > 0 then
            exit(ItemApplnEntry."Posting Date");
        if OutbndItemLedgEntry.Get(ItemApplnEntry."Outbound Item Entry No.") then
            if OutbndItemLedgEntry."Completely Invoiced" then
                exit(OutbndItemLedgEntry."Last Invoice Date");
    end;

    local procedure InitValueEntry(var ValueEntry: Record "Value Entry"; ItemLedgEntry: Record "Item Ledger Entry")
    var
        CalcUnitCost: Boolean;
        CostAmt: Decimal;
        CostAmtACY: Decimal;
    begin
        OnBeforeInitValueEntry(ValueEntry, ValueEntryNo, RentalItemJnlLine);

        ValueEntryNo := ValueEntryNo + 1;

        ValueEntry.Init();
        ValueEntry."Entry No." := ValueEntryNo;
        if RentalItemJnlLine."Value Entry Type" = RentalItemJnlLine."Value Entry Type"::Variance then
            ValueEntry."Variance Type" := RentalItemJnlLine."Variance Type";
        ValueEntry."Item Ledger Entry No." := ItemLedgEntry."Entry No.";
        ValueEntry."Item No." := RentalItemJnlLine."Item No.";
        ValueEntry."Item Charge No." := RentalItemJnlLine."Item Charge No.";
        ValueEntry."Order Type" := ItemLedgEntry."Order Type";
        ValueEntry."Order No." := ItemLedgEntry."Order No.";
        ValueEntry."Order Line No." := ItemLedgEntry."Order Line No.";
        ValueEntry."Item Ledger Entry Type" := RentalItemJnlLine."Entry Type";
        ValueEntry.Type := RentalItemJnlLine.Type;
        ValueEntry."Posting Date" := RentalItemJnlLine."Posting Date";
        if RentalItemJnlLine."Partial Revaluation" then
            ValueEntry."Partial Revaluation" := true;

        OnInitValueEntryOnAfterAssignFields(ValueEntry, ItemLedgEntry);

        if (ItemLedgEntry.Quantity > 0) or
           (ItemLedgEntry."Invoiced Quantity" > 0) or
           ((RentalItemJnlLine."Value Entry Type" = RentalItemJnlLine."Value Entry Type"::"Direct Cost") and (RentalItemJnlLine."Item Charge No." = '')) or
           (RentalItemJnlLine."Entry Type" in [RentalItemJnlLine."Entry Type"::Output, RentalItemJnlLine."Entry Type"::"Assembly Output"]) or
           RentalItemJnlLine.Adjustment
        then
            ValueEntry.Inventoriable := false;

        if ((RentalItemJnlLine.Quantity = 0) and (RentalItemJnlLine."Invoiced Quantity" <> 0)) or
           (RentalItemJnlLine."Value Entry Type" <> RentalItemJnlLine."Value Entry Type"::"Direct Cost") or
           (RentalItemJnlLine."Item Charge No." <> '') or RentalItemJnlLine.Adjustment
        then begin
            GetLastDirectCostValEntry(ValueEntry."Item Ledger Entry No.");
            if ValueEntry.Inventoriable and (RentalItemJnlLine."Item Charge No." = '') then
                ValueEntry."Valued By Average Cost" := DirCostValueEntry."Valued By Average Cost";
        end;

        case true of
            ((RentalItemJnlLine.Quantity = 0) and (RentalItemJnlLine."Invoiced Quantity" <> 0)) or
          ((RentalItemJnlLine."Value Entry Type" = RentalItemJnlLine."Value Entry Type"::"Direct Cost") and (RentalItemJnlLine."Item Charge No." <> '')) or
          RentalItemJnlLine.Adjustment or (RentalItemJnlLine."Value Entry Type" = RentalItemJnlLine."Value Entry Type"::Rounding):
                ValueEntry."Valuation Date" := DirCostValueEntry."Valuation Date";
            (RentalItemJnlLine."Value Entry Type" = RentalItemJnlLine."Value Entry Type"::Revaluation):
                if RentalItemJnlLine."Posting Date" < DirCostValueEntry."Valuation Date" then
                    ValueEntry."Valuation Date" := DirCostValueEntry."Valuation Date"
                else
                    ValueEntry."Valuation Date" := RentalItemJnlLine."Posting Date";
            (ItemLedgEntry.Quantity > 0) and (RentalItemJnlLine."Applies-from Entry" <> 0):
                GetAppliedFromValues(ValueEntry);
            else
                ValueEntry."Valuation Date" := RentalItemJnlLine."Posting Date";
        end;

        GetInvtSetup();
        if (RentalItemJnlLine.Description = MainRentalItem.Description) and not InvtSetup."Copy Item Descr. to Entries" then
            ValueEntry.Description := ''
        else
            ValueEntry.Description := RentalItemJnlLine.Description;

        ValueEntry."Source Code" := RentalItemJnlLine."Source Code";
        ValueEntry."Source Type" := RentalItemJnlLine."Source Type";
        ValueEntry."Source No." := GetSourceNo(RentalItemJnlLine);
        if (RentalItemJnlLine."Value Entry Type" = RentalItemJnlLine."Value Entry Type"::"Direct Cost") and (RentalItemJnlLine."Item Charge No." = '') then
            ValueEntry."Inventory Posting Group" := RentalItemJnlLine."Inventory Posting Group"
        else
            ValueEntry."Inventory Posting Group" := DirCostValueEntry."Inventory Posting Group";
        ValueEntry."Source Posting Group" := RentalItemJnlLine."Source Posting Group";
        ValueEntry."Salespers./Purch. Code" := RentalItemJnlLine."Salespers./Purch. Code";
        ValueEntry."Location Code" := ItemLedgEntry."Location Code";
        ValueEntry."Variant Code" := ItemLedgEntry."Variant Code";
        ValueEntry."Journal Batch Name" := RentalItemJnlLine."Journal Batch Name";
        ValueEntry."User ID" := UserId;
        ValueEntry."Drop Shipment" := RentalItemJnlLine."Drop Shipment";
        ValueEntry."Reason Code" := RentalItemJnlLine."Reason Code";
        ValueEntry."Return Reason Code" := RentalItemJnlLine."Return Reason Code";
        ValueEntry."External Document No." := RentalItemJnlLine."External Document No.";
        ValueEntry."Document Date" := RentalItemJnlLine."Document Date";
        ValueEntry."Gen. Bus. Posting Group" := RentalItemJnlLine."Gen. Bus. Posting Group";
        ValueEntry."Gen. Prod. Posting Group" := RentalItemJnlLine."Gen. Prod. Posting Group";
        ValueEntry."Discount Amount" := RentalItemJnlLine."Discount Amount";
        ValueEntry."Entry Type" := RentalItemJnlLine."Value Entry Type";
        if RentalItemJnlLine."Job No." <> '' then begin
            ValueEntry."Job No." := RentalItemJnlLine."Job No.";
            ValueEntry."Job Task No." := RentalItemJnlLine."Job Task No.";
        end;
        if RentalItemJnlLine."Invoiced Quantity" <> 0 then begin
            ValueEntry."Valued Quantity" := RentalItemJnlLine."Invoiced Quantity";
            if (RentalItemJnlLine."Value Entry Type" = RentalItemJnlLine."Value Entry Type"::"Direct Cost") and
               (RentalItemJnlLine."Item Charge No." = '')
            then
                if (RentalItemJnlLine."Entry Type" <> RentalItemJnlLine."Entry Type"::Output) or
                   (ItemLedgEntry."Invoiced Quantity" = 0)
                then
                    ValueEntry."Invoiced Quantity" := RentalItemJnlLine."Invoiced Quantity";
            ValueEntry."Expected Cost" := false;
        end else begin
            ValueEntry."Valued Quantity" := RentalItemJnlLine.Quantity;
            ValueEntry."Expected Cost" := RentalItemJnlLine."Value Entry Type" <> RentalItemJnlLine."Value Entry Type"::Revaluation;
        end;

        ValueEntry."Document Type" := RentalItemJnlLine."Document Type";
        if ValueEntry."Expected Cost" or (RentalItemJnlLine."Invoice No." = '') then
            ValueEntry."Document No." := RentalItemJnlLine."Document No."
        else begin
            ValueEntry."Document No." := RentalItemJnlLine."Invoice No.";
            if RentalItemJnlLine."Document Type" in [
                                   RentalItemJnlLine."Document Type"::"Purchase Receipt", RentalItemJnlLine."Document Type"::"Purchase Return Shipment",
                                   RentalItemJnlLine."Document Type"::"Sales Shipment", RentalItemJnlLine."Document Type"::"Sales Return Receipt",
                                   RentalItemJnlLine."Document Type"::"Service Shipment"]
            then
                ValueEntry."Document Type" := "Item Ledger Document Type".FromInteger(RentalItemJnlLine."Document Type".AsInteger() + 1);
        end;
        ValueEntry."Document Line No." := RentalItemJnlLine."Document Line No.";

        if RentalItemJnlLine.Adjustment then begin
            ValueEntry."Invoiced Quantity" := 0;
            ValueEntry."Applies-to Entry" := RentalItemJnlLine."Applies-to Value Entry";
            ValueEntry.Adjustment := true;
        end;

        if RentalItemJnlLine."Value Entry Type" <> RentalItemJnlLine."Value Entry Type"::Rounding then begin
            if (RentalItemJnlLine."Entry Type" = RentalItemJnlLine."Entry Type"::Output) and
               (RentalItemJnlLine."Value Entry Type" <> RentalItemJnlLine."Value Entry Type"::Revaluation)
            then begin
                CostAmt := RentalItemJnlLine.Amount;
                CostAmtACY := RentalItemJnlLine."Amount (ACY)";
            end else begin
                ValueEntry."Cost per Unit" := RetrieveCostPerUnit(RentalItemJnlLine, SKU, SKUExists);
                if GLSetup."Additional Reporting Currency" <> '' then
                    ValueEntry."Cost per Unit (ACY)" := RetrieveCostPerUnitACY(ValueEntry."Cost per Unit");

                if (ValueEntry."Valued Quantity" > 0) and
                   (ValueEntry."Item Ledger Entry Type" in [ValueEntry."Item Ledger Entry Type"::Purchase,
                                                            ValueEntry."Item Ledger Entry Type"::"Assembly Output"]) and
                   (ValueEntry."Entry Type" = ValueEntry."Entry Type"::"Direct Cost") and
                   not RentalItemJnlLine.Adjustment
                then begin
                    if MainRentalItem."Costing Method" = MainRentalItem."Costing Method"::Standard then
                        RentalItemJnlLine."Unit Cost" := ValueEntry."Cost per Unit";
                    CalcPosShares(
                      CostAmt, OverheadAmount, VarianceAmount, CostAmtACY, OverheadAmountACY, VarianceAmountACY,
                      CalcUnitCost, (MainRentalItem."Costing Method" = MainRentalItem."Costing Method"::Standard) and
                      (not ValueEntry."Expected Cost"), ValueEntry."Expected Cost");
                    if (OverheadAmount <> 0) or
                       (Round(VarianceAmount, GLSetup."Amount Rounding Precision") <> 0) or
                       CalcUnitCost or ValueEntry."Expected Cost"
                    then begin
                        ValueEntry."Cost per Unit" :=
                          CalcCostPerUnit(CostAmt, ValueEntry."Valued Quantity", false);

                        if GLSetup."Additional Reporting Currency" <> '' then
                            ValueEntry."Cost per Unit (ACY)" :=
                              CalcCostPerUnit(CostAmtACY, ValueEntry."Valued Quantity", true);
                    end;
                end else
                    if not RentalItemJnlLine.Adjustment then
                        CalcOutboundCostAmt(ValueEntry, CostAmt, CostAmtACY)
                    else begin
                        CostAmt := RentalItemJnlLine.Amount;
                        CostAmtACY := RentalItemJnlLine."Amount (ACY)";
                    end;

                if (RentalItemJnlLine."Invoiced Quantity" < 0) and (RentalItemJnlLine."Applies-to Entry" <> 0) and
                   (RentalItemJnlLine."Entry Type" = RentalItemJnlLine."Entry Type"::Purchase) and (RentalItemJnlLine."Item Charge No." = '') and
                   (ValueEntry."Entry Type" = ValueEntry."Entry Type"::"Direct Cost")
                then begin
                    CalcPurchCorrShares(OverheadAmount, OverheadAmountACY, VarianceAmount, VarianceAmountACY);
                    OnAfterCalcPurchCorrShares(
                      ValueEntry, RentalItemJnlLine, OverheadAmount, OverheadAmountACY, VarianceAmount, VarianceAmountACY);
                end;
            end
        end else begin
            CostAmt := RentalItemJnlLine."Unit Cost";
            CostAmtACY := RentalItemJnlLine."Unit Cost (ACY)";
        end;

        if (ValueEntry."Entry Type" <> ValueEntry."Entry Type"::Revaluation) and not RentalItemJnlLine.Adjustment then
            if (ValueEntry."Item Ledger Entry Type" in
                [ValueEntry."Item Ledger Entry Type"::Sale,
                 ValueEntry."Item Ledger Entry Type"::"Negative Adjmt.",
                 ValueEntry."Item Ledger Entry Type"::Consumption,
                 ValueEntry."Item Ledger Entry Type"::"Assembly Consumption"]) or
               ((ValueEntry."Item Ledger Entry Type" = ValueEntry."Item Ledger Entry Type"::Transfer) and
                (RentalItemJnlLine."Value Entry Type" = RentalItemJnlLine."Value Entry Type"::"Direct Cost") and (RentalItemJnlLine."Item Charge No." = ''))
            then begin
                ValueEntry."Valued Quantity" := -ValueEntry."Valued Quantity";
                ValueEntry."Invoiced Quantity" := -ValueEntry."Invoiced Quantity";
                if ValueEntry."Item Ledger Entry Type" = ValueEntry."Item Ledger Entry Type"::Transfer then
                    ValueEntry."Discount Amount" := 0
                else
                    ValueEntry."Discount Amount" := -ValueEntry."Discount Amount";

                if RentalItemJnlLine."Value Entry Type" <> RentalItemJnlLine."Value Entry Type"::Rounding then begin
                    CostAmt := -CostAmt;
                    CostAmtACY := -CostAmtACY;
                end;
            end;
        if not RentalItemJnlLine.Adjustment then
            if ((RentalItemJnlLine."Entry Type" = RentalItemJnlLine."Entry Type"::Transfer) and
                (ValueEntry."Valued Quantity" < 0) and not AverageTransfer) or
               ((RentalItemJnlLine."Entry Type" = RentalItemJnlLine."Entry Type"::Sale) and
                (RentalItemJnlLine."Item Charge No." <> ''))
            then begin //MainRentalItem."Inventory Value Zero" or
                CostAmt := 0;
                CostAmtACY := 0;
                ValueEntry."Cost per Unit" := 0;
                ValueEntry."Cost per Unit (ACY)" := 0;
            end;

        case true of
            (not ValueEntry."Expected Cost") and ValueEntry.Inventoriable and
            IsInterimRevaluation:
                begin
                    ValueEntry."Cost Amount (Expected)" := Round(CostAmt * RentalItemJnlLine."Applied Amount" / RentalItemJnlLine.Amount);
                    ValueEntry."Cost Amount (Expected) (ACY)" := Round(CostAmtACY * RentalItemJnlLine."Applied Amount" / RentalItemJnlLine.Amount,
                        Currency."Amount Rounding Precision");

                    CostAmt := Round(CostAmt);
                    CostAmtACY := Round(CostAmtACY, Currency."Amount Rounding Precision");
                    ValueEntry."Cost Amount (Actual)" := CostAmt - ValueEntry."Cost Amount (Expected)";
                    ValueEntry."Cost Amount (Actual) (ACY)" := CostAmtACY - ValueEntry."Cost Amount (Expected) (ACY)";
                end;
            (not ValueEntry."Expected Cost") and ValueEntry.Inventoriable:
                begin
                    if not RentalItemJnlLine.Adjustment and (RentalItemJnlLine."Value Entry Type" = RentalItemJnlLine."Value Entry Type"::"Direct Cost") then
                        case RentalItemJnlLine."Entry Type" of
                            RentalItemJnlLine."Entry Type"::Sale:
                                ValueEntry."Sales Amount (Actual)" := RentalItemJnlLine.Amount;
                            RentalItemJnlLine."Entry Type"::Purchase:
                                ValueEntry."Purchase Amount (Actual)" := RentalItemJnlLine.Amount;
                        end;
                    ValueEntry."Cost Amount (Actual)" := CostAmt;
                    ValueEntry."Cost Amount (Actual) (ACY)" := CostAmtACY;
                end;
            ValueEntry."Expected Cost" and ValueEntry.Inventoriable:
                begin
                    if not RentalItemJnlLine.Adjustment then
                        case RentalItemJnlLine."Entry Type" of
                            RentalItemJnlLine."Entry Type"::Sale:
                                ValueEntry."Sales Amount (Expected)" := RentalItemJnlLine.Amount;
                            RentalItemJnlLine."Entry Type"::Purchase:
                                ValueEntry."Purchase Amount (Expected)" := RentalItemJnlLine.Amount;
                        end;
                    ValueEntry."Cost Amount (Expected)" := CostAmt;
                    ValueEntry."Cost Amount (Expected) (ACY)" := CostAmtACY;
                end;
            (not ValueEntry."Expected Cost") and (not ValueEntry.Inventoriable):
                if RentalItemJnlLine."Entry Type" = RentalItemJnlLine."Entry Type"::Sale then begin
                    ValueEntry."Sales Amount (Actual)" := RentalItemJnlLine.Amount;
                    if MainRentalItem.IsNonInventoriableType then begin
                        ValueEntry."Cost Amount (Non-Invtbl.)" := CostAmt;
                        ValueEntry."Cost Amount (Non-Invtbl.)(ACY)" := CostAmtACY;
                    end else begin
                        ValueEntry."Cost per Unit" := 0;
                        ValueEntry."Cost per Unit (ACY)" := 0;
                    end;
                end else begin
                    if RentalItemJnlLine."Entry Type" = RentalItemJnlLine."Entry Type"::Purchase then
                        ValueEntry."Purchase Amount (Actual)" := RentalItemJnlLine.Amount;
                    ValueEntry."Cost Amount (Non-Invtbl.)" := CostAmt;
                    ValueEntry."Cost Amount (Non-Invtbl.)(ACY)" := CostAmtACY;
                end;
        end;

        RoundAmtValueEntry(ValueEntry);

        OnAfterInitValueEntry(ValueEntry, RentalItemJnlLine, ValueEntryNo);
    end;

    local procedure CalcOutboundCostAmt(ValueEntry: Record "Value Entry"; var CostAmt: Decimal; var CostAmtACY: Decimal)
    begin
        if RentalItemJnlLine."Item Charge No." <> '' then begin
            CostAmt := RentalItemJnlLine.Amount;
            if GLSetup."Additional Reporting Currency" <> '' then
                CostAmtACY := ACYMgt.CalcACYAmt(CostAmt, ValueEntry."Posting Date", false);
        end else begin
            CostAmt :=
              ValueEntry."Cost per Unit" * ValueEntry."Valued Quantity";
            CostAmtACY :=
              ValueEntry."Cost per Unit (ACY)" * ValueEntry."Valued Quantity";

            if (ValueEntry."Entry Type" = ValueEntry."Entry Type"::Revaluation) and
               (MainRentalItem."Costing Method" = MainRentalItem."Costing Method"::Average)
            then begin
                CostAmt += RoundingResidualAmount;
                CostAmtACY += RoundingResidualAmountACY;
            end;
        end;
    end;

    procedure InsertValueEntry(var ValueEntry: Record "Value Entry"; var ItemLedgEntry: Record "Item Ledger Entry"; TransferItem: Boolean)
    var
        InvdValueEntry: Record "Value Entry";
        InvoicedQty: Decimal;
    begin
        if IsWarehouseReclassification(RentalItemJnlLine) then begin
            ValueEntry."Dimension Set ID" := OldItemLedgEntry."Dimension Set ID";
            ValueEntry."Global Dimension 1 Code" := OldItemLedgEntry."Global Dimension 1 Code";
            ValueEntry."Global Dimension 2 Code" := OldItemLedgEntry."Global Dimension 2 Code";
        end else
            if TransferItem then begin
                ValueEntry."Global Dimension 1 Code" := RentalItemJnlLine."New Shortcut Dimension 1 Code";
                ValueEntry."Global Dimension 2 Code" := RentalItemJnlLine."New Shortcut Dimension 2 Code";
                ValueEntry."Dimension Set ID" := RentalItemJnlLine."New Dimension Set ID";
            end else
                if (GlobalValueEntry."Entry Type" = GlobalValueEntry."Entry Type"::"Direct Cost") and
                   (GlobalValueEntry."Item Charge No." <> '') and
                   (ValueEntry."Entry Type" = ValueEntry."Entry Type"::Variance)
                then begin
                    GetLastDirectCostValEntry(ValueEntry."Item Ledger Entry No.");
                    ValueEntry."Gen. Prod. Posting Group" := DirCostValueEntry."Gen. Prod. Posting Group";
                    MoveValEntryDimToValEntryDim(ValueEntry, DirCostValueEntry);
                end else begin
                    ValueEntry."Global Dimension 1 Code" := RentalItemJnlLine."Shortcut Dimension 1 Code";
                    ValueEntry."Global Dimension 2 Code" := RentalItemJnlLine."Shortcut Dimension 2 Code";
                    ValueEntry."Dimension Set ID" := RentalItemJnlLine."Dimension Set ID";
                end;
        RoundAmtValueEntry(ValueEntry);

        if ValueEntry."Entry Type" = ValueEntry."Entry Type"::Rounding then begin
            ValueEntry."Valued Quantity" := ItemLedgEntry.Quantity;
            ValueEntry."Invoiced Quantity" := 0;
            ValueEntry."Cost per Unit" := 0;
            ValueEntry."Sales Amount (Actual)" := 0;
            ValueEntry."Purchase Amount (Actual)" := 0;
            ValueEntry."Cost per Unit (ACY)" := 0;
            ValueEntry."Item Ledger Entry Quantity" := 0;
        end else begin
            if IsFirstValueEntry(ValueEntry."Item Ledger Entry No.") then
                ValueEntry."Item Ledger Entry Quantity" := ValueEntry."Valued Quantity"
            else
                ValueEntry."Item Ledger Entry Quantity" := 0;
            if ValueEntry."Cost per Unit" = 0 then begin
                ValueEntry."Cost per Unit" :=
                  CalcCostPerUnit(ValueEntry."Cost Amount (Actual)", ValueEntry."Valued Quantity", false);
                ValueEntry."Cost per Unit (ACY)" :=
                  CalcCostPerUnit(ValueEntry."Cost Amount (Actual) (ACY)", ValueEntry."Valued Quantity", true);
            end else begin
                ValueEntry."Cost per Unit" := Round(
                    ValueEntry."Cost per Unit", GLSetup."Unit-Amount Rounding Precision");
                ValueEntry."Cost per Unit (ACY)" := Round(
                    ValueEntry."Cost per Unit (ACY)", Currency."Unit-Amount Rounding Precision");
                if RentalItemJnlLine."Source Currency Code" = GLSetup."Additional Reporting Currency" then
                    if ValueEntry."Expected Cost" then
                        ValueEntry."Cost per Unit" :=
                          CalcCostPerUnit(ValueEntry."Cost Amount (Expected)", ValueEntry."Valued Quantity", false)
                    else
                        if ValueEntry."Entry Type" = ValueEntry."Entry Type"::Revaluation then
                            ValueEntry."Cost per Unit" :=
                              CalcCostPerUnit(ValueEntry."Cost Amount (Actual)" + ValueEntry."Cost Amount (Expected)",
                                ValueEntry."Valued Quantity", false)
                        else
                            ValueEntry."Cost per Unit" :=
                              CalcCostPerUnit(ValueEntry."Cost Amount (Actual)", ValueEntry."Valued Quantity", false);
            end;
            if UpdateItemLedgEntry(ValueEntry, ItemLedgEntry) then
                ItemLedgEntry.Modify();
        end;

        if ((ValueEntry."Entry Type" = ValueEntry."Entry Type"::"Direct Cost") and
            (ValueEntry."Item Charge No." = '')) and
           (((RentalItemJnlLine.Quantity = 0) and (RentalItemJnlLine."Invoiced Quantity" <> 0)) or
            (RentalItemJnlLine.Adjustment and not ValueEntry."Expected Cost")) and
           not ExpectedCostPosted(ValueEntry)
        then begin
            if ValueEntry."Invoiced Quantity" = 0 then begin
                if InvdValueEntry.Get(ValueEntry."Applies-to Entry") then
                    InvoicedQty := InvdValueEntry."Invoiced Quantity"
                else
                    InvoicedQty := ValueEntry."Valued Quantity";
            end else
                InvoicedQty := ValueEntry."Invoiced Quantity";
            CalcExpectedCost(
              ValueEntry,
              ItemLedgEntry."Entry No.",
              InvoicedQty,
              ItemLedgEntry.Quantity,
              ValueEntry."Cost Amount (Expected)",
              ValueEntry."Cost Amount (Expected) (ACY)",
              ValueEntry."Sales Amount (Expected)",
              ValueEntry."Purchase Amount (Expected)",
              ItemLedgEntry.Quantity = ItemLedgEntry."Invoiced Quantity");
        end;

        OnBeforeInsertValueEntry(ValueEntry, RentalItemJnlLine, ItemLedgEntry, ValueEntryNo, InventoryPostingToGL, CalledFromAdjustment);

        /*       if ValueEntry.Inventoriable and not MainRentalItem."Inventory Value Zero" then
                  PostInventoryToGL(ValueEntry); */

        ValueEntry.Insert();

        OnAfterInsertValueEntry(ValueEntry, RentalItemJnlLine, ItemLedgEntry, ValueEntryNo);

        ItemApplnEntry.SetOutboundsNotUpdated(ItemLedgEntry);

        UpdateAdjmtProperties(ValueEntry, ItemLedgEntry."Posting Date");

        InsertItemReg(0, 0, ValueEntry."Entry No.", 0);
        InsertPostValueEntryToGL(ValueEntry);
        if MainRentalItem."Item Tracking Code" <> '' then begin
            TempValueEntryRelation.Init();
            TempValueEntryRelation."Value Entry No." := ValueEntry."Entry No.";
            TempValueEntryRelation.Insert();
        end;
    end;

    local procedure InsertOHValueEntry(ValueEntry: Record "Value Entry"; OverheadAmount: Decimal; OverheadAmountACY: Decimal)
    begin
        OnBeforeInsertOHValueEntry(ValueEntry, MainRentalItem, OverheadAmount, OverheadAmountACY);

        /*  if MainRentalItem."Inventory Value Zero" or not ValueEntry.Inventoriable then
             exit;
  */
        ValueEntryNo := ValueEntryNo + 1;

        ValueEntry."Entry No." := ValueEntryNo;
        ValueEntry."Item Charge No." := '';
        ValueEntry."Entry Type" := ValueEntry."Entry Type"::"Indirect Cost";
        ValueEntry.Description := '';
        ValueEntry."Cost per Unit" := 0;
        ValueEntry."Cost per Unit (ACY)" := 0;
        ValueEntry."Cost Posted to G/L" := 0;
        ValueEntry."Cost Posted to G/L (ACY)" := 0;
        ValueEntry."Invoiced Quantity" := 0;
        ValueEntry."Sales Amount (Actual)" := 0;
        ValueEntry."Sales Amount (Expected)" := 0;
        ValueEntry."Purchase Amount (Actual)" := 0;
        ValueEntry."Purchase Amount (Expected)" := 0;
        ValueEntry."Discount Amount" := 0;
        ValueEntry."Cost Amount (Actual)" := OverheadAmount;
        ValueEntry."Cost Amount (Expected)" := 0;
        ValueEntry."Cost Amount (Expected) (ACY)" := 0;

        if GLSetup."Additional Reporting Currency" <> '' then
            ValueEntry."Cost Amount (Actual) (ACY)" :=
              Round(OverheadAmountACY, Currency."Amount Rounding Precision");

        InsertValueEntry(ValueEntry, GlobalItemLedgEntry, false);

        OnAfterInsertOHValueEntry(ValueEntry, MainRentalItem, OverheadAmount, OverheadAmountACY);
    end;

    local procedure InsertVarValueEntry(ValueEntry: Record "Value Entry"; VarianceAmount: Decimal; VarianceAmountACY: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertVarValueEntry(ValueEntry, MainRentalItem, VarianceAmount, VarianceAmountACY, IsHandled);
        if IsHandled then
            exit;

        /*       if (not ValueEntry.Inventoriable) or MainRentalItem."Inventory Value Zero" then
                  exit; */
        if (VarianceAmount = 0) and (VarianceAmountACY = 0) then
            exit;

        ValueEntryNo := ValueEntryNo + 1;

        ValueEntry."Entry No." := ValueEntryNo;
        ValueEntry."Item Charge No." := '';
        ValueEntry."Entry Type" := ValueEntry."Entry Type"::Variance;
        ValueEntry.Description := '';
        ValueEntry."Cost Posted to G/L" := 0;
        ValueEntry."Cost Posted to G/L (ACY)" := 0;
        ValueEntry."Invoiced Quantity" := 0;
        ValueEntry."Sales Amount (Actual)" := 0;
        ValueEntry."Sales Amount (Expected)" := 0;
        ValueEntry."Purchase Amount (Actual)" := 0;
        ValueEntry."Purchase Amount (Expected)" := 0;
        ValueEntry."Discount Amount" := 0;
        ValueEntry."Cost Amount (Actual)" := VarianceAmount;
        ValueEntry."Cost Amount (Expected)" := 0;
        ValueEntry."Cost Amount (Expected) (ACY)" := 0;
        ValueEntry."Variance Type" := ValueEntry."Variance Type"::Purchase;

        if GLSetup."Additional Reporting Currency" <> '' then begin
            if Round(VarianceAmount, GLSetup."Amount Rounding Precision") =
               Round(-GlobalValueEntry."Cost Amount (Actual)", GLSetup."Amount Rounding Precision")
            then
                ValueEntry."Cost Amount (Actual) (ACY)" := -GlobalValueEntry."Cost Amount (Actual) (ACY)"
            else
                ValueEntry."Cost Amount (Actual) (ACY)" :=
                  Round(VarianceAmountACY, Currency."Amount Rounding Precision");
        end;

        ValueEntry."Cost per Unit" :=
          CalcCostPerUnit(ValueEntry."Cost Amount (Actual)", ValueEntry."Valued Quantity", false);
        ValueEntry."Cost per Unit (ACY)" :=
          CalcCostPerUnit(ValueEntry."Cost Amount (Actual) (ACY)", ValueEntry."Valued Quantity", true);

        InsertValueEntry(ValueEntry, GlobalItemLedgEntry, false);
    end;

    local procedure UpdateItemLedgEntry(ValueEntry: Record "Value Entry"; var ItemLedgEntry: Record "Item Ledger Entry") ModifyEntry: Boolean
    begin
        if not (ValueEntry."Entry Type" in
                [ValueEntry."Entry Type"::Variance,
                 ValueEntry."Entry Type"::"Indirect Cost",
                 ValueEntry."Entry Type"::Rounding])
        then begin
            if ValueEntry.Inventoriable and (not RentalItemJnlLine.Adjustment or (ItemLedgEntry."Entry Type" = ItemLedgEntry."Entry Type"::"Assembly Output")) then
                UpdateAvgCostAdjmtEntryPoint(ItemLedgEntry, ValueEntry."Valuation Date");

            if (ValueEntry."Entry Type" = ValueEntry."Entry Type"::"Direct Cost") and
               (RentalItemJnlLine."Item Charge No." = '') and
               (RentalItemJnlLine.Quantity = 0) and (ValueEntry."Invoiced Quantity" <> 0)
            then begin
                if ValueEntry."Invoiced Quantity" <> 0 then begin
                    ItemLedgEntry."Invoiced Quantity" := ItemLedgEntry."Invoiced Quantity" + ValueEntry."Invoiced Quantity";
                    if Abs(ItemLedgEntry."Invoiced Quantity") > Abs(ItemLedgEntry.Quantity) then
                        Error(Text030Lbl, ItemLedgEntry."Entry No.");
                    VerifyInvoicedQty(ItemLedgEntry, ValueEntry);
                    ModifyEntry := true;
                end;

                if (ItemLedgEntry."Entry Type" <> ItemLedgEntry."Entry Type"::Output) and
                   (ItemLedgEntry."Invoiced Quantity" = ItemLedgEntry.Quantity) and
                   not ItemLedgEntry."Completely Invoiced"
                then begin
                    ItemLedgEntry."Completely Invoiced" := true;
                    ModifyEntry := true;
                end;

                if ItemLedgEntry."Last Invoice Date" < ValueEntry."Posting Date" then begin
                    ItemLedgEntry."Last Invoice Date" := ValueEntry."Posting Date";
                    ModifyEntry := true;
                end;
            end;
            if RentalItemJnlLine."Applies-from Entry" <> 0 then
                UpdateOutboundItemLedgEntry(RentalItemJnlLine."Applies-from Entry");
        end;

        exit(ModifyEntry);
    end;

    local procedure UpdateAvgCostAdjmtEntryPoint(OldItemLedgEntry: Record "Item Ledger Entry"; ValuationDate: Date)
    var
        AvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point";
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.Init();
        ValueEntry."Item No." := OldItemLedgEntry."Item No.";
        ValueEntry."Valuation Date" := ValuationDate;
        ValueEntry."Location Code" := OldItemLedgEntry."Location Code";
        ValueEntry."Variant Code" := OldItemLedgEntry."Variant Code";

        AvgCostAdjmtEntryPoint.LockTable();
        AvgCostAdjmtEntryPoint.UpdateValuationDate(ValueEntry);
    end;

    local procedure UpdateOutboundItemLedgEntry(OutboundItemEntryNo: Integer)
    var
        OutboundItemLedgEntry: Record "Item Ledger Entry";
    begin
        OutboundItemLedgEntry.Get(OutboundItemEntryNo);
        if OutboundItemLedgEntry.Quantity > 0 then
            OutboundItemLedgEntry.FieldError(Quantity);
        if GlobalItemLedgEntry.Quantity < 0 then
            GlobalItemLedgEntry.FieldError(Quantity);

        OutboundItemLedgEntry."Shipped Qty. Not Returned" := OutboundItemLedgEntry."Shipped Qty. Not Returned" + Abs(RentalItemJnlLine.Quantity);
        if OutboundItemLedgEntry."Shipped Qty. Not Returned" > 0 then
            OutboundItemLedgEntry.FieldError("Shipped Qty. Not Returned", Text004Lbl);
        OutboundItemLedgEntry."Applied Entry to Adjust" := true;
        OutboundItemLedgEntry.Modify();
    end;

    local procedure InitTransValueEntry(var ValueEntry: Record "Value Entry"; ItemLedgEntry: Record "Item Ledger Entry")
    var
        AdjCostInvoicedLCY: Decimal;
        AdjCostInvoicedACY: Decimal;
        DiscountAmount: Decimal;
    begin
        InitValueEntry(ValueEntry, ItemLedgEntry);
        ValueEntry."Valued Quantity" := ItemLedgEntry.Quantity;
        ValueEntry."Invoiced Quantity" := ValueEntry."Valued Quantity";
        ValueEntry."Location Code" := ItemLedgEntry."Location Code";
        ValueEntry."Valuation Date" := GlobalValueEntry."Valuation Date";
        if AverageTransfer then begin
            //ValuateAppliedAvgEntry(GlobalValueEntry, MainRentalItem);
            ValueEntry."Cost Amount (Actual)" := -GlobalValueEntry."Cost Amount (Actual)";
            ValueEntry."Cost Amount (Actual) (ACY)" := -GlobalValueEntry."Cost Amount (Actual) (ACY)";
            ValueEntry."Cost per Unit" := 0;
            ValueEntry."Cost per Unit (ACY)" := 0;
            ValueEntry."Valued By Average Cost" :=
              not (ItemLedgEntry.Positive or
                   (ValueEntry."Document Type" = ValueEntry."Document Type"::"Transfer Receipt"));
        end else begin
            CalcAdjustedCost(
              OldItemLedgEntry, ValueEntry."Valued Quantity",
              AdjCostInvoicedLCY, AdjCostInvoicedACY, DiscountAmount);
            ValueEntry."Cost Amount (Actual)" := AdjCostInvoicedLCY;
            ValueEntry."Cost Amount (Actual) (ACY)" := AdjCostInvoicedACY;
            ValueEntry."Cost per Unit" := 0;
            ValueEntry."Cost per Unit (ACY)" := 0;

            GlobalValueEntry."Cost Amount (Actual)" := GlobalValueEntry."Cost Amount (Actual)" - ValueEntry."Cost Amount (Actual)";
            if GLSetup."Additional Reporting Currency" <> '' then
                GlobalValueEntry."Cost Amount (Actual) (ACY)" :=
                  CurrExchRate.ExchangeAmtLCYToFCY(
                    ValueEntry."Posting Date", GLSetup."Additional Reporting Currency",
                    Round(GlobalValueEntry."Cost Amount (Actual)", GLSetup."Amount Rounding Precision"),
                    CurrExchRate.ExchangeRate(
                      ValueEntry."Posting Date", GLSetup."Additional Reporting Currency"));
        end;

        GlobalValueEntry."Discount Amount" := 0;
        ValueEntry."Discount Amount" := 0;
        GlobalValueEntry."Cost per Unit" := 0;
        GlobalValueEntry."Cost per Unit (ACY)" := 0;
    end;

    local procedure ValuateAppliedAvgEntry(var ValueEntry: Record "Value Entry"; MainRentalItem: Record "TWE Main Rental Item")
    begin
        if (RentalItemJnlLine."Applies-to Entry" = 0) and
           (ValueEntry."Item Ledger Entry Type" <> "Item Ledger Entry Type"::Output)
        then begin
            if (RentalItemJnlLine.Quantity = 0) and (RentalItemJnlLine."Invoiced Quantity" <> 0) then begin
                GetLastDirectCostValEntry(ValueEntry."Item Ledger Entry No.");
                ValueEntry."Valued By Average Cost" := DirCostValueEntry."Valued By Average Cost";
            end else
                ValueEntry."Valued By Average Cost" := not (ValueEntry."Document Type" = ValueEntry."Document Type"::"Transfer Receipt");

            /*                 if MainRentalItem."Inventory Value Zero" then begin
                                "Cost per Unit" := 0;
                                "Cost per Unit (ACY)" := 0;
                            end else begin
                                if "Item Ledger Entry Type" = "Item Ledger Entry Type"::Transfer then begin
                                    if SKUExists and (InvtSetup."Average Cost Calc. Type" <> InvtSetup."Average Cost Calc. Type"::Item) then
                                        "Cost per Unit" := SKU."Unit Cost"
                                    else
                                        "Cost per Unit" := MainRentalItem."Unit Cost";
                                end else
                                    "Cost per Unit" := RentalItemJnlLine."Unit Cost"; */

            OnValuateAppliedAvgEntryOnAfterSetCostPerUnit(ValueEntry, RentalItemJnlLine, InvtSetup, SKU, SKUExists);

            if GLSetup."Additional Reporting Currency" <> '' then begin
                if (RentalItemJnlLine."Source Currency Code" = GLSetup."Additional Reporting Currency") and
                   (ValueEntry."Item Ledger Entry Type" <> "Item Ledger Entry Type"::Transfer)
                then
                    ValueEntry."Cost per Unit (ACY)" := RentalItemJnlLine."Unit Cost (ACY)"
                else
                    ValueEntry."Cost per Unit (ACY)" :=
                      Round(
                        CurrExchRate.ExchangeAmtLCYToFCY(
                          ValueEntry."Posting Date", GLSetup."Additional Reporting Currency", ValueEntry."Cost per Unit",
                          CurrExchRate.ExchangeRate(
                            ValueEntry."Posting Date", GLSetup."Additional Reporting Currency")),
                        Currency."Unit-Amount Rounding Precision");
            end;
        end;

        OnValuateAppliedAvgEntryOnAfterUpdateCostAmounts(ValueEntry, RentalItemJnlLine);

        /*  if "Expected Cost" then begin
             "Cost Amount (Expected)" := "Valued Quantity" * "Cost per Unit";
             "Cost Amount (Expected) (ACY)" := "Valued Quantity" * "Cost per Unit (ACY)";
         end else begin
             "Cost Amount (Actual)" := "Valued Quantity" * "Cost per Unit";
             "Cost Amount (Actual) (ACY)" := "Valued Quantity" * "Cost per Unit (ACY)";
         end; */
        //end;
    end;

    local procedure CalcAdjustedCost(PosItemLedgEntry: Record "Item Ledger Entry"; AppliedQty: Decimal; var AdjustedCostLCY: Decimal; var AdjustedCostACY: Decimal; var DiscountAmount: Decimal)
    var
        PosValueEntry: Record "Value Entry";
    begin
        AdjustedCostLCY := 0;
        AdjustedCostACY := 0;
        DiscountAmount := 0;

        PosValueEntry.SetCurrentKey("Item Ledger Entry No.");
        PosValueEntry.SetRange("Item Ledger Entry No.", PosItemLedgEntry."Entry No.");
        PosValueEntry.FindSet();
        repeat
            if PosValueEntry."Partial Revaluation" then begin
                AdjustedCostLCY := AdjustedCostLCY +
                  PosValueEntry."Cost Amount (Actual)" / PosValueEntry."Valued Quantity" * PosItemLedgEntry.Quantity;
                AdjustedCostACY := AdjustedCostACY +
                  PosValueEntry."Cost Amount (Actual) (ACY)" / PosValueEntry."Valued Quantity" * PosItemLedgEntry.Quantity;
            end else begin
                AdjustedCostLCY := AdjustedCostLCY + PosValueEntry."Cost Amount (Actual)" + PosValueEntry."Cost Amount (Expected)";
                AdjustedCostACY := AdjustedCostACY + PosValueEntry."Cost Amount (Actual) (ACY)" + PosValueEntry."Cost Amount (Expected) (ACY)";
                DiscountAmount := DiscountAmount - PosValueEntry."Discount Amount";
            end;
        until PosValueEntry.Next() = 0;

        AdjustedCostLCY := AdjustedCostLCY * AppliedQty / PosItemLedgEntry.Quantity;
        AdjustedCostACY := AdjustedCostACY * AppliedQty / PosItemLedgEntry.Quantity;
        DiscountAmount := DiscountAmount * AppliedQty / PosItemLedgEntry.Quantity;
    end;

    local procedure GetMaxValuationDate(ItemLedgerEntry: Record "Item Ledger Entry"): Date
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetCurrentKey("Item Ledger Entry No.", "Entry Type");
        ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgerEntry."Entry No.");
        ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::Revaluation);
        if not ValueEntry.FindLast() then begin
            ValueEntry.SetRange("Entry Type");
            ValueEntry.FindLast();
        end;
        exit(ValueEntry."Valuation Date");
    end;

    local procedure GetValuationDate(var ValueEntry: Record "Value Entry"; OldItemLedgEntry: Record "Item Ledger Entry")
    var
        OldValueEntry: Record "Value Entry";
        IsHandled: Boolean;
    begin
        OldValueEntry.SetCurrentKey("Item Ledger Entry No.", "Entry Type");
        OldValueEntry.SetRange("Item Ledger Entry No.", OldItemLedgEntry."Entry No.");
        OldValueEntry.SetRange("Entry Type", OldValueEntry."Entry Type"::Revaluation);
        if not OldValueEntry.FindLast() then begin
            OldValueEntry.SetRange("Entry Type");
            IsHandled := false;
            OnGetValuationDateOnBeforeFindOldValueEntry(OldValueEntry, IsHandled);
            if IsHandled then
                exit;
            OldValueEntry.FindLast();
        end;
        if OldItemLedgEntry.Positive then begin
            if (ValueEntry."Posting Date" < OldValueEntry."Valuation Date") or
               (RentalItemJnlLine."Applies-to Entry" <> 0)
            then begin
                ValueEntry."Valuation Date" := OldValueEntry."Valuation Date";
                SetValuationDateAllValueEntrie(
                  ValueEntry."Item Ledger Entry No.",
                  OldValueEntry."Valuation Date",
                  RentalItemJnlLine."Applies-to Entry" <> 0)
            end else
                if ValueEntry."Valuation Date" <= ValueEntry."Posting Date" then begin
                    ValueEntry."Valuation Date" := ValueEntry."Posting Date";
                    SetValuationDateAllValueEntrie(
                      ValueEntry."Item Ledger Entry No.",
                      ValueEntry."Posting Date",
                      RentalItemJnlLine."Applies-to Entry" <> 0)
                end
        end else
            if OldValueEntry."Valuation Date" < ValueEntry."Valuation Date" then begin
                UpdateAvgCostAdjmtEntryPoint(OldItemLedgEntry, OldValueEntry."Valuation Date");
                OldValueEntry.ModifyAll("Valuation Date", ValueEntry."Valuation Date");
                UpdateLinkedValuationDate(ValueEntry."Valuation Date", OldItemLedgEntry."Entry No.", OldItemLedgEntry.Positive);
            end;
    end;

    local procedure UpdateLinkedValuationDate(FromValuationDate: Date; FromItemledgEntryNo: Integer; FromInbound: Boolean)
    var
        ToItemApplnEntry: Record "Item Application Entry";
    begin
        if FromInbound then begin
            ToItemApplnEntry.SetCurrentKey("Inbound Item Entry No.", "Item Ledger Entry No.", "Outbound Item Entry No.");
            ToItemApplnEntry.SetRange("Inbound Item Entry No.", FromItemledgEntryNo);
            ToItemApplnEntry.SetFilter("Outbound Item Entry No.", '<>%1', 0);
        end else begin
            ToItemApplnEntry.SetCurrentKey("Outbound Item Entry No.", "Item Ledger Entry No.");
            ToItemApplnEntry.SetRange("Outbound Item Entry No.", FromItemledgEntryNo);
        end;
        ToItemApplnEntry.SetFilter("Item Ledger Entry No.", '<>%1', FromItemledgEntryNo);
        if ToItemApplnEntry.FindSet() then
            repeat
                if FromInbound or (ToItemApplnEntry."Inbound Item Entry No." <> 0) then begin
                    GetLastDirectCostValEntry(ToItemApplnEntry."Inbound Item Entry No.");
                    if DirCostValueEntry."Valuation Date" < FromValuationDate then begin
                        UpdateValuationDate(FromValuationDate, ToItemApplnEntry."Item Ledger Entry No.", FromInbound);
                        UpdateLinkedValuationDate(FromValuationDate, ToItemApplnEntry."Item Ledger Entry No.", not FromInbound);
                    end;
                end;
            until ToItemApplnEntry.Next() = 0;
    end;

    local procedure UpdateLinkedValuationUnapply(FromValuationDate: Date; FromItemLedgEntryNo: Integer; FromInbound: Boolean)
    var
        ToItemApplnEntry: Record "Item Application Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        if FromInbound then begin
            ToItemApplnEntry.SetCurrentKey("Inbound Item Entry No.", "Item Ledger Entry No.", "Outbound Item Entry No.");
            ToItemApplnEntry.SetRange("Inbound Item Entry No.", FromItemLedgEntryNo);
            ToItemApplnEntry.SetFilter("Outbound Item Entry No.", '<>%1', 0);
        end else begin
            ToItemApplnEntry.SetCurrentKey("Outbound Item Entry No.", "Item Ledger Entry No.");
            ToItemApplnEntry.SetRange("Outbound Item Entry No.", FromItemLedgEntryNo);
        end;
        ToItemApplnEntry.SetFilter("Item Ledger Entry No.", '<>%1', FromItemLedgEntryNo);
        if ToItemApplnEntry.Find('-') then
            repeat
                if FromInbound or (ToItemApplnEntry."Inbound Item Entry No." <> 0) then begin
                    GetLastDirectCostValEntry(ToItemApplnEntry."Inbound Item Entry No.");
                    if DirCostValueEntry."Valuation Date" < FromValuationDate then begin
                        UpdateValuationDate(FromValuationDate, ToItemApplnEntry."Item Ledger Entry No.", FromInbound);
                        UpdateLinkedValuationUnapply(FromValuationDate, ToItemApplnEntry."Item Ledger Entry No.", not FromInbound);
                    end
                    else begin
                        ItemLedgerEntry.Get(ToItemApplnEntry."Inbound Item Entry No.");
                        FromValuationDate := GetMaxAppliedValuationdate(ItemLedgerEntry);
                        if FromValuationDate < DirCostValueEntry."Valuation Date" then begin
                            UpdateValuationDate(FromValuationDate, ItemLedgerEntry."Entry No.", FromInbound);
                            UpdateLinkedValuationUnapply(FromValuationDate, ItemLedgerEntry."Entry No.", not FromInbound);
                        end;
                    end;
                end;
            until ToItemApplnEntry.Next() = 0;
    end;

    local procedure UpdateValuationDate(FromValuationDate: Date; FromItemLedgEntryNo: Integer; FromInbound: Boolean)
    var
        ToValueEntry2: Record "Value Entry";
    begin
        ToValueEntry2.SetCurrentKey("Item Ledger Entry No.");
        ToValueEntry2.SetRange("Item Ledger Entry No.", FromItemLedgEntryNo);
        ToValueEntry2.Find('-');
        if FromInbound then begin
            if ToValueEntry2."Valuation Date" < FromValuationDate then
                ToValueEntry2.ModifyAll("Valuation Date", FromValuationDate);
        end else
            repeat
                if ToValueEntry2."Entry Type" = ToValueEntry2."Entry Type"::Revaluation then begin
                    if ToValueEntry2."Valuation Date" < FromValuationDate then begin
                        ToValueEntry2."Valuation Date" := FromValuationDate;
                        ToValueEntry2.Modify();
                    end;
                end else begin
                    ToValueEntry2."Valuation Date" := FromValuationDate;
                    ToValueEntry2.Modify();
                end;
            until ToValueEntry2.Next() = 0;
    end;

    local procedure CreateItemJnlLineFromEntry(ItemLedgEntry: Record "Item Ledger Entry"; NewQuantity: Decimal; var RentalItemJnlLine: Record "TWE Rental Item Journal Line")
    begin
        Clear(RentalItemJnlLine);
        RentalItemJnlLine."Entry Type" := ItemLedgEntry."Entry Type"; // no mapping needed
        RentalItemJnlLine.Quantity := RentalItemJnlLine.Signed(NewQuantity);
        RentalItemJnlLine."Item No." := ItemLedgEntry."Item No.";
        RentalItemJnlLine.CopyTrackingFromItemLedgEntry(ItemLedgEntry);

        OnAfterCreateItemJnlLineFromEntry(RentalItemJnlLine, ItemLedgEntry);
    end;

    local procedure GetAppliedFromValues(var ValueEntry: Record "Value Entry")
    var
        NegValueEntry: Record "Value Entry";
    begin
        NegValueEntry.SetCurrentKey("Item Ledger Entry No.", "Entry Type");
        NegValueEntry.SetRange("Item Ledger Entry No.", RentalItemJnlLine."Applies-from Entry");
        NegValueEntry.SetRange("Entry Type", NegValueEntry."Entry Type"::Revaluation);
        if not NegValueEntry.FindLast() then begin
            NegValueEntry.SetRange("Entry Type");
            NegValueEntry.FindLast();
        end;

        if NegValueEntry."Valuation Date" > ValueEntry."Posting Date" then
            ValueEntry."Valuation Date" := NegValueEntry."Valuation Date"
        else
            ValueEntry."Valuation Date" := RentalItemJnlLine."Posting Date";
    end;

    local procedure RoundAmtValueEntry(var ValueEntry: Record "Value Entry")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRoundAmtValueEntry(ValueEntry, IsHandled);
        if IsHandled then
            exit;

        ValueEntry."Sales Amount (Actual)" := Round(ValueEntry."Sales Amount (Actual)");
        ValueEntry."Sales Amount (Expected)" := Round(ValueEntry."Sales Amount (Expected)");
        ValueEntry."Purchase Amount (Actual)" := Round(ValueEntry."Purchase Amount (Actual)");
        ValueEntry."Purchase Amount (Expected)" := Round(ValueEntry."Purchase Amount (Expected)");
        ValueEntry."Discount Amount" := Round(ValueEntry."Discount Amount");
        ValueEntry."Cost Amount (Actual)" := Round(ValueEntry."Cost Amount (Actual)");
        ValueEntry."Cost Amount (Expected)" := Round(ValueEntry."Cost Amount (Expected)");
        ValueEntry."Cost Amount (Non-Invtbl.)" := Round(ValueEntry."Cost Amount (Non-Invtbl.)");
        ValueEntry."Cost Amount (Actual) (ACY)" := Round(ValueEntry."Cost Amount (Actual) (ACY)", Currency."Amount Rounding Precision");
        ValueEntry."Cost Amount (Expected) (ACY)" := Round(ValueEntry."Cost Amount (Expected) (ACY)", Currency."Amount Rounding Precision");
        ValueEntry."Cost Amount (Non-Invtbl.)(ACY)" := Round(ValueEntry."Cost Amount (Non-Invtbl.)(ACY)", Currency."Amount Rounding Precision");
    end;

    local procedure RetrieveCostPerUnit(RentalItemJnlLine: Record "TWE Rental Item Journal Line"; SKU: Record "Stockkeeping Unit"; SKUExists: Boolean): Decimal
    var
        UnitCost: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRetrieveCostPerUnit(RentalItemJnlLine, SKU, SKUExists, UnitCost, IsHandled);
        if IsHandled then
            exit(UnitCost);

        if (MainRentalItem."Costing Method" = MainRentalItem."Costing Method"::Standard) and
           (RentalItemJnlLine."Value Entry Type" = RentalItemJnlLine."Value Entry Type"::"Direct Cost") and
               (RentalItemJnlLine."Item Charge No." = '') and
               (RentalItemJnlLine."Applies-from Entry" = 0) and
               not RentalItemJnlLine.Adjustment
            then begin
            if SKUExists then
                exit(SKU."Unit Cost");
            exit(MainRentalItem."Unit Cost");
        end;
        exit(RentalItemJnlLine."Unit Cost");
    end;

    local procedure RetrieveCostPerUnitACY(CostPerUnit: Decimal): Decimal
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        PostingDate: Date;
    begin
        if RentalItemJnlLine.Adjustment or (RentalItemJnlLine."Source Currency Code" = GLSetup."Additional Reporting Currency") and
           ((MainRentalItem."Costing Method" <> MainRentalItem."Costing Method"::Standard) or
            ((RentalItemJnlLine."Discount Amount" = 0) and (RentalItemJnlLine."Indirect Cost %" = 0) and (RentalItemJnlLine."Overhead Rate" = 0)))
        then
            exit(RentalItemJnlLine."Unit Cost (ACY)");
        if (RentalItemJnlLine."Value Entry Type" = RentalItemJnlLine."Value Entry Type"::Revaluation) and ItemLedgerEntry.Get(RentalItemJnlLine."Applies-to Entry") then
            PostingDate := ItemLedgerEntry."Posting Date"
        else
            PostingDate := RentalItemJnlLine."Posting Date";
        exit(Round(CurrExchRate.ExchangeAmtLCYToFCY(
              PostingDate, GLSetup."Additional Reporting Currency",
              CostPerUnit, CurrExchRate.ExchangeRate(
                PostingDate, GLSetup."Additional Reporting Currency")),
            Currency."Unit-Amount Rounding Precision"));
    end;

    local procedure CalcCostPerUnit(Cost: Decimal; Quantity: Decimal; IsACY: Boolean): Decimal
    var
        RndgPrec: Decimal;
    begin
        GetGLSetup;

        if IsACY then
            RndgPrec := Currency."Unit-Amount Rounding Precision"
        else
            RndgPrec := GLSetup."Unit-Amount Rounding Precision";

        if Quantity <> 0 then
            exit(Round(Cost / Quantity, RndgPrec));
        exit(0);
    end;

    local procedure CalcPosShares(var DirCost: Decimal; var OvhdCost: Decimal; var PurchVar: Decimal; var DirCostACY: Decimal; var OvhdCostACY: Decimal; var PurchVarACY: Decimal; var CalcUnitCost: Boolean; CalcPurchVar: Boolean; Expected: Boolean)
    var
        CostCalcMgt: Codeunit "Cost Calculation Management";
    begin
        if Expected then begin
            DirCost := RentalItemJnlLine."Unit Cost" * RentalItemJnlLine.Quantity;
            PurchVar := 0;
            PurchVarACY := 0;
            OvhdCost := 0;
            OvhdCostACY := 0;
        end else begin
            OvhdCost :=
              Round(
                CostCalcMgt.CalcOvhdCost(
                  RentalItemJnlLine.Amount, RentalItemJnlLine."Indirect Cost %", RentalItemJnlLine."Overhead Rate", RentalItemJnlLine."Invoiced Quantity"),
                GLSetup."Amount Rounding Precision");
            DirCost := RentalItemJnlLine.Amount;
            if CalcPurchVar then
                PurchVar := RentalItemJnlLine."Unit Cost" * RentalItemJnlLine."Invoiced Quantity" - DirCost - OvhdCost
            else begin
                PurchVar := 0;
                PurchVarACY := 0;
            end;
        end;

        if GLSetup."Additional Reporting Currency" <> '' then begin
            DirCostACY := ACYMgt.CalcACYAmt(DirCost, RentalItemJnlLine."Posting Date", false);
            OvhdCostACY := ACYMgt.CalcACYAmt(OvhdCost, RentalItemJnlLine."Posting Date", false);
            RentalItemJnlLine."Unit Cost (ACY)" :=
              Round(
                CurrExchRate.ExchangeAmtLCYToFCY(
                  RentalItemJnlLine."Posting Date", GLSetup."Additional Reporting Currency", RentalItemJnlLine."Unit Cost",
                  CurrExchRate.ExchangeRate(
                    RentalItemJnlLine."Posting Date", GLSetup."Additional Reporting Currency")),
                Currency."Unit-Amount Rounding Precision");
            PurchVarACY := RentalItemJnlLine."Unit Cost (ACY)" * RentalItemJnlLine."Invoiced Quantity" - DirCostACY - OvhdCostACY;
        end;
        CalcUnitCost := (DirCost <> 0) and (RentalItemJnlLine."Unit Cost" = 0);

        OnAfterCalcPosShares(
          RentalItemJnlLine, DirCost, OvhdCost, PurchVar, DirCostACY, OvhdCostACY, PurchVarACY, CalcUnitCost, CalcPurchVar, Expected);
    end;

    local procedure CalcPurchCorrShares(var OverheadAmount: Decimal; var OverheadAmountACY: Decimal; var VarianceAmount: Decimal; var VarianceAmountACY: Decimal)
    var
        OldItemLedgEntry: Record "Item Ledger Entry";
        OldValueEntry: Record "Value Entry";
        CostAmt: Decimal;
        CostAmtACY: Decimal;
    begin
        OldValueEntry.SetCurrentKey("Item Ledger Entry No.", "Entry Type");
        OldValueEntry.SetRange("Item Ledger Entry No.", RentalItemJnlLine."Applies-to Entry");
        OldValueEntry.SetRange("Entry Type", OldValueEntry."Entry Type"::"Indirect Cost");
        if OldValueEntry.FindSet() then
            repeat
                if not OldValueEntry."Partial Revaluation" then begin
                    CostAmt := CostAmt + OldValueEntry."Cost Amount (Actual)";
                    CostAmtACY := CostAmtACY + OldValueEntry."Cost Amount (Actual) (ACY)";
                end;
            until OldValueEntry.Next() = 0;
        if (CostAmt <> 0) or (CostAmtACY <> 0) then begin
            OldItemLedgEntry.Get(RentalItemJnlLine."Applies-to Entry");
            OverheadAmount := Round(
                CostAmt / OldItemLedgEntry."Invoiced Quantity" * RentalItemJnlLine."Invoiced Quantity",
                GLSetup."Amount Rounding Precision");
            OverheadAmountACY := Round(
                CostAmtACY / OldItemLedgEntry."Invoiced Quantity" * RentalItemJnlLine."Invoiced Quantity",
                Currency."Unit-Amount Rounding Precision");
            if MainRentalItem."Costing Method" = MainRentalItem."Costing Method"::Standard then begin
                VarianceAmount := -OverheadAmount;
                VarianceAmountACY := -OverheadAmountACY;
            end else begin
                VarianceAmount := 0;
                VarianceAmountACY := 0;
            end;
        end else
            if MainRentalItem."Costing Method" = MainRentalItem."Costing Method"::Standard then begin
                OldValueEntry.SetRange("Entry Type", OldValueEntry."Entry Type"::Variance);
                VarianceRequired := OldValueEntry.FindFirst();
            end;
    end;

    local procedure GetLastDirectCostValEntry(ItemLedgEntryNo: Decimal)
    var
        Found: Boolean;
    begin
        if ItemLedgEntryNo = DirCostValueEntry."Item Ledger Entry No." then
            exit;
        DirCostValueEntry.Reset();
        DirCostValueEntry.SetCurrentKey("Item Ledger Entry No.", "Entry Type");
        DirCostValueEntry.SetRange("Item Ledger Entry No.", ItemLedgEntryNo);
        DirCostValueEntry.SetRange("Entry Type", DirCostValueEntry."Entry Type"::"Direct Cost");
        DirCostValueEntry.SetFilter("Item Charge No.", '%1', '');
        Found := DirCostValueEntry.FindLast();
        DirCostValueEntry.SetRange("Item Charge No.");
        if not Found then
            DirCostValueEntry.FindLast();
    end;

    local procedure IsFirstValueEntry(ItemLedgEntryNo: Integer): Boolean
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetCurrentKey("Item Ledger Entry No.");
        ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgEntryNo);
        exit(ValueEntry.IsEmpty);
    end;

    local procedure CalcExpectedCost(var InvdValueEntry: Record "Value Entry"; ItemLedgEntryNo: Integer; InvoicedQty: Decimal; Quantity: Decimal; var ExpectedCost: Decimal; var ExpectedCostACY: Decimal; var ExpectedSalesAmt: Decimal; var ExpectedPurchAmt: Decimal; CalcReminder: Boolean)
    var
        ValueEntry: Record "Value Entry";
    begin
        ExpectedCost := 0;
        ExpectedCostACY := 0;
        ExpectedSalesAmt := 0;
        ExpectedPurchAmt := 0;

        ValueEntry.SetCurrentKey("Item Ledger Entry No.", "Entry Type");
        ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgEntryNo);
        ValueEntry.SetFilter("Entry Type", '<>%1', ValueEntry."Entry Type"::Revaluation);
        OnCalcExpectedCostOnBeforeFindValueEntry(
          ValueEntry, ItemLedgEntryNo, InvoicedQty, Quantity, ExpectedCost, ExpectedCostACY, ExpectedSalesAmt, ExpectedPurchAmt, CalcReminder);
        if ValueEntry.FindSet() and ValueEntry."Expected Cost" then
            if CalcReminder then begin
                ValueEntry.CalcSums(
                  "Cost Amount (Expected)", "Cost Amount (Expected) (ACY)",
                  "Sales Amount (Expected)", "Purchase Amount (Expected)");
                ExpectedCost := -ValueEntry."Cost Amount (Expected)";
                ExpectedCostACY := -ValueEntry."Cost Amount (Expected) (ACY)";
                if not CalledFromAdjustment then begin
                    ExpectedSalesAmt := -ValueEntry."Sales Amount (Expected)";
                    ExpectedPurchAmt := -ValueEntry."Purchase Amount (Expected)";
                end
            end else
                if InvdValueEntry.Adjustment and
                   (InvdValueEntry."Entry Type" = InvdValueEntry."Entry Type"::"Direct Cost")
                then begin
                    ExpectedCost := -InvdValueEntry."Cost Amount (Actual)";
                    ExpectedCostACY := -InvdValueEntry."Cost Amount (Actual) (ACY)";
                    if not CalledFromAdjustment then begin
                        ExpectedSalesAmt := -InvdValueEntry."Sales Amount (Actual)";
                        ExpectedPurchAmt := -InvdValueEntry."Purchase Amount (Actual)";
                    end
                end else begin
                    repeat
                        if ValueEntry."Expected Cost" and not ValueEntry.Adjustment then begin
                            ExpectedCost := ExpectedCost + ValueEntry."Cost Amount (Expected)";
                            ExpectedCostACY := ExpectedCostACY + ValueEntry."Cost Amount (Expected) (ACY)";
                            if not CalledFromAdjustment then begin
                                ExpectedSalesAmt := ExpectedSalesAmt + ValueEntry."Sales Amount (Expected)";
                                ExpectedPurchAmt := ExpectedPurchAmt + ValueEntry."Purchase Amount (Expected)";
                            end;
                        end;
                    until ValueEntry.Next() = 0;
                    ExpectedCost :=
                      CalcExpCostToBalance(ExpectedCost, InvoicedQty, Quantity, GLSetup."Amount Rounding Precision");
                    ExpectedCostACY :=
                      CalcExpCostToBalance(ExpectedCostACY, InvoicedQty, Quantity, Currency."Amount Rounding Precision");
                    if not CalledFromAdjustment then begin
                        ExpectedSalesAmt :=
                          CalcExpCostToBalance(ExpectedSalesAmt, InvoicedQty, Quantity, GLSetup."Amount Rounding Precision");
                        ExpectedPurchAmt :=
                          CalcExpCostToBalance(ExpectedPurchAmt, InvoicedQty, Quantity, GLSetup."Amount Rounding Precision");
                    end;
                end;
    end;

    local procedure CalcExpCostToBalance(ExpectedCost: Decimal; InvoicedQty: Decimal; Quantity: Decimal; RoundPrecision: Decimal): Decimal
    begin
        exit(-Round(InvoicedQty / Quantity * ExpectedCost, RoundPrecision));
    end;

    local procedure MoveValEntryDimToValEntryDim(var ToValueEntry: Record "Value Entry"; FromValueEntry: Record "Value Entry")
    begin
        ToValueEntry."Global Dimension 1 Code" := FromValueEntry."Global Dimension 1 Code";
        ToValueEntry."Global Dimension 2 Code" := FromValueEntry."Global Dimension 2 Code";
        ToValueEntry."Dimension Set ID" := FromValueEntry."Dimension Set ID";
        OnAfterMoveValEntryDimToValEntryDim(ToValueEntry, FromValueEntry);
    end;

    local procedure AutoTrack(var ItemLedgEntryRec: Record "Item Ledger Entry"; IsReserved: Boolean)
    var
        ReservMgt: Codeunit "Reservation Management";
    begin
        /*         if MainRentalItem."Order Tracking Policy" = MainRentalItem."Order Tracking Policy"::None then begin
                    if not IsReserved then
                        exit;

                    // Ensure that Item Tracking is not left on the item ledger entry:
                    ReservMgt.SetReservSource(ItemLedgEntryRec);
                    ReservMgt.SetItemTrackingHandling(1);
                    ReservMgt.ClearSurplus;
                    exit;
                end; */

        /*         ReservMgt.SetReservSource(ItemLedgEntryRec);
                ReservMgt.SetItemTrackingHandling(1);
                ReservMgt.DeleteReservEntries(false, ItemLedgEntryRec."Remaining Quantity");
                ReservMgt.ClearSurplus;
                ReservMgt.AutoTrack(ItemLedgEntryRec."Remaining Quantity"); */
    end;

    procedure SetPostponeReservationHandling(Postpone: Boolean)
    begin
        // Used when posting Transfer Order receipts
        PostponeReservationHandling := Postpone;
    end;

    local procedure SetupSplitJnlLine(var RentalItemJnlLine2: Record "TWE Rental Item Journal Line"; TrackingSpecExists: Boolean): Boolean
    var
        LateBindingMgt: Codeunit "Late Binding Management";
        UOMMgt: Codeunit "Unit of Measure Management";
        NonDistrQuantity: Decimal;
        NonDistrAmount: Decimal;
        NonDistrAmountACY: Decimal;
        NonDistrDiscountAmount: Decimal;
        SignFactor: Integer;
        CalcWarrantyDate: Date;
        CalcExpirationDate: Date;
        Invoice: Boolean;
        ExpirationDateChecked: Boolean;
        PostItemJnlLine: Boolean;
        IsHandled: Boolean;
    begin
        RentalItemJnlLineOrigin := RentalItemJnlLine2;
        TempSplitRentalItemJnlLine.Reset();
        TempSplitRentalItemJnlLine.DeleteAll();

        DisableItemTracking := not RentalItemJnlLine2.ItemPosting;
        Invoice := RentalItemJnlLine2."Invoiced Qty. (Base)" <> 0;

        if (RentalItemJnlLine2."Entry Type" = RentalItemJnlLine2."Entry Type"::Transfer) and PostponeReservationHandling then
            SignFactor := 1
        else
            SignFactor := RentalItemJnlLine2.Signed(1);

        /*         ItemTrackingCode.Code := MainRentalItem."Item Tracking Code";
                ItemTrackingMgt.GetItemTrackingSetup(
                    ItemTrackingCode, RentalItemJnlLine."Entry Type".AsInteger(), RentalItemJnlLine.Signed(RentalItemJnlLine."Quantity (Base)") > 0, ItemTrackingSetup); */

        if MainRentalItem."Costing Method" = MainRentalItem."Costing Method"::Specific then begin
            MainRentalItem.TestField("Item Tracking Code");
            ItemTrackingCode.TestField("SN Specific Tracking", true);
        end;

        OnBeforeSetupSplitJnlLine(RentalItemJnlLine2, TrackingSpecExists, TempTrackingSpecification);

        if not RentalItemJnlLine2.Correction and (RentalItemJnlLine2."Quantity (Base)" <> 0) and TrackingSpecExists then begin
            if DisableItemTracking then begin
                if not TempTrackingSpecification.IsEmpty then
                    Error(Text021Lbl, RentalItemJnlLine2.FieldCaption("Operation No."), RentalItemJnlLine2."Operation No.");
            end else begin
                if TempTrackingSpecification.IsEmpty() then
                    Error(Text100Lbl);

                CheckItemTrackingIsEmpty(RentalItemJnlLine2);

                if Format(ItemTrackingCode."Warranty Date Formula") <> '' then
                    CalcWarrantyDate := CalcDate(ItemTrackingCode."Warranty Date Formula", RentalItemJnlLine2."Document Date");

                IsHandled := false;
                OnBeforeCalcExpirationDate(RentalItemJnlLine2, CalcExpirationDate, IsHandled);
                if not IsHandled then
                    if Format(MainRentalItem."Expiration Calculation") <> '' then
                        CalcExpirationDate := CalcDate(MainRentalItem."Expiration Calculation", RentalItemJnlLine2."Document Date");

                OnSetupSplitJnlLineOnBeforeReallocateTrkgSpecification(ItemTrackingCode, TempTrackingSpecification, RentalItemJnlLine2, SignFactor, IsHandled);
                if not IsHandled then
                    if SignFactor * RentalItemJnlLine2.Quantity < 0 then // Demand
                        if ItemTrackingCode."SN Specific Tracking" or ItemTrackingCode."Lot Specific Tracking" then
                            LateBindingMgt.ReallocateTrkgSpecification(TempTrackingSpecification);

                TempTrackingSpecification.CalcSums(
                  "Qty. to Handle (Base)", "Qty. to Invoice (Base)", "Qty. to Handle", "Qty. to Invoice");
                TempTrackingSpecification.TestFieldError(TempTrackingSpecification.FieldCaption("Qty. to Handle (Base)"),
                  TempTrackingSpecification."Qty. to Handle (Base)", SignFactor * RentalItemJnlLine2."Quantity (Base)");

                if Invoice then
                    TempTrackingSpecification.TestFieldError(TempTrackingSpecification.FieldCaption("Qty. to Invoice (Base)"),
                      TempTrackingSpecification."Qty. to Invoice (Base)", SignFactor * RentalItemJnlLine2."Invoiced Qty. (Base)");

                NonDistrQuantity :=
                    UOMMgt.CalcQtyFromBase(
                        RentalItemJnlLine2."Item No.", RentalItemJnlLine2."Variant Code", RentalItemJnlLine2."Unit of Measure Code",
                        UOMMgt.RoundQty(
                            UOMMgt.CalcBaseQty(
                                RentalItemJnlLine2."Item No.", RentalItemJnlLine2."Variant Code", RentalItemJnlLine2."Unit of Measure Code",
                                RentalItemJnlLine2.Quantity, RentalItemJnlLine2."Qty. per Unit of Measure")),
                    RentalItemJnlLine2."Qty. per Unit of Measure");
                NonDistrAmount := RentalItemJnlLine2.Amount;
                NonDistrAmountACY := RentalItemJnlLine2."Amount (ACY)";
                NonDistrDiscountAmount := RentalItemJnlLine2."Discount Amount";

                OnSetupSplitJnlLineOnBeforeSplitTempLines(TempSplitRentalItemJnlLine, TempTrackingSpecification);

                TempTrackingSpecification.FindSet();
                repeat
                    if ItemTrackingCode."Man. Warranty Date Entry Reqd." then
                        TempTrackingSpecification.TestField("Warranty Date");

                    if ItemTrackingCode."Use Expiration Dates" then
                        CheckExpirationDate(RentalItemJnlLine2, SignFactor, CalcExpirationDate, ExpirationDateChecked);

                    CheckItemTrackingInformation(RentalItemJnlLine2, TempTrackingSpecification, SignFactor, ItemTrackingCode, ItemTrackingSetup);

                    if TempTrackingSpecification."Warranty Date" = 0D then
                        TempTrackingSpecification."Warranty Date" := CalcWarrantyDate;

                    TempTrackingSpecification.Modify();
                    TempSplitRentalItemJnlLine := RentalItemJnlLine2;
                    PostItemJnlLine :=
                      PostItemJnlLine or
                      SetupTempSplitItemJnlLine(
                        RentalItemJnlLine2, SignFactor, NonDistrQuantity, NonDistrAmount,
                        NonDistrAmountACY, NonDistrDiscountAmount, Invoice);
                until TempTrackingSpecification.Next() = 0;
            end;
        end else
            InsertTempSplitItemJnlLine(RentalItemJnlLine2);

        exit(PostItemJnlLine);
    end;

    local procedure InsertTempSplitItemJnlLine(RentalItemJnlLine2: Record "TWE Rental Item Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertTempSplitItemJnlLine(RentalItemJnlLine2, IsServUndoConsumption, PostponeReservationHandling, TempSplitRentalItemJnlLine, IsHandled);
        if IsHandled then
            exit;

        TempSplitRentalItemJnlLine := RentalItemJnlLine2;
        TempSplitRentalItemJnlLine.Insert();
    end;

    local procedure SplitItemJnlLine(var RentalItemJnlLine2: Record "TWE Rental Item Journal Line"; PostItemJnlLine: Boolean): Boolean
    var
        FreeEntryNo: Integer;
        JnlLineNo: Integer;
        SignFactor: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnSplitItemJnlLineOnBeforeTracking(
            RentalItemJnlLine2, PostItemJnlLine, TempTrackingSpecification, GlobalItemLedgEntry, TempItemEntryRelation,
            PostponeReservationHandling, SignFactor, IsHandled);
        if not IsHandled then
            if (RentalItemJnlLine2."Quantity (Base)" <> 0) and RentalItemJnlLine2.TrackingExists then begin
                if (RentalItemJnlLine2."Entry Type" in
                    [RentalItemJnlLine2."Entry Type"::Sale,
                    RentalItemJnlLine2."Entry Type"::"Negative Adjmt.",
                    RentalItemJnlLine2."Entry Type"::Consumption,
                    RentalItemJnlLine2."Entry Type"::"Assembly Consumption"]) or
                ((RentalItemJnlLine2."Entry Type" = RentalItemJnlLine2."Entry Type"::Transfer) and
                    not PostponeReservationHandling)
                then
                    SignFactor := -1
                else
                    SignFactor := 1;

                //TempTrackingSpecification.SetTrackingFilterFromItemJnlLine(RentalItemJnlLine2);
                if TempTrackingSpecification.FindFirst() then begin
                    FreeEntryNo := TempTrackingSpecification."Entry No.";
                    TempTrackingSpecification.Delete();
                    RentalItemJnlLine2.CheckTrackingEqualTrackingSpecification(TempTrackingSpecification);
                    TempTrackingSpecification."Quantity (Base)" := SignFactor * RentalItemJnlLine2."Quantity (Base)";
                    TempTrackingSpecification."Quantity Handled (Base)" := SignFactor * RentalItemJnlLine2."Quantity (Base)";
                    TempTrackingSpecification."Quantity actual Handled (Base)" := SignFactor * RentalItemJnlLine2."Quantity (Base)";
                    TempTrackingSpecification."Quantity Invoiced (Base)" := SignFactor * RentalItemJnlLine2."Invoiced Qty. (Base)";
                    TempTrackingSpecification."Qty. to Invoice (Base)" :=
                    SignFactor * (RentalItemJnlLine2."Quantity (Base)" - RentalItemJnlLine2."Invoiced Qty. (Base)");
                    TempTrackingSpecification."Qty. to Handle (Base)" := 0;
                    TempTrackingSpecification."Qty. to Handle" := 0;
                    TempTrackingSpecification."Qty. to Invoice" :=
                    SignFactor * (RentalItemJnlLine2.Quantity - RentalItemJnlLine2."Invoiced Quantity");
                    TempTrackingSpecification."Item Ledger Entry No." := GlobalItemLedgEntry."Entry No.";
                    TempTrackingSpecification."Transfer Item Entry No." := TempItemEntryRelation."Item Entry No.";
                    if PostItemJnlLine then
                        TempTrackingSpecification."Entry No." := TempTrackingSpecification."Item Ledger Entry No.";
                    InsertTempTrkgSpecification(FreeEntryNo);
                end else
                    if (RentalItemJnlLine2."Item Charge No." = '') and (RentalItemJnlLine2."Job No." = '') then
                        if not RentalItemJnlLine2.Correction then begin // Undo quantity posting
                            IsHandled := false;
                            OnBeforeTrackingSpecificationMissingErr(RentalItemJnlLine2, IsHandled);
                            if not IsHandled then
                                Error(TrackingSpecificationMissingErr);
                        end;
            end;

        if TempSplitRentalItemJnlLine.FindFirst() then begin
            JnlLineNo := RentalItemJnlLine2."Line No.";
            RentalItemJnlLine2 := TempSplitRentalItemJnlLine;
            RentalItemJnlLine2."Line No." := JnlLineNo;
            TempSplitRentalItemJnlLine.Delete();
            exit(true);
        end;
        if RentalItemJnlLine."Phys. Inventory" then
            InsertPhysInventoryEntry;
        exit(false);
    end;

    procedure CollectTrackingSpecification(var TargetTrackingSpecification: Record "Tracking Specification" temporary) Result: Boolean
    var
        IsHandled: Boolean;
    begin
        OnBeforeCollectTrackingSpecification(TempTrackingSpecification, TargetTrackingSpecification, Result, IsHandled);
        if IsHandled then
            exit(Result);

        TempTrackingSpecification.Reset();
        TargetTrackingSpecification.Reset();
        TargetTrackingSpecification.DeleteAll();

        if TempTrackingSpecification.FindSet() then
            repeat
                TargetTrackingSpecification := TempTrackingSpecification;
                TargetTrackingSpecification.Insert();
            until TempTrackingSpecification.Next() = 0
        else
            exit(false);

        TempTrackingSpecification.DeleteAll();

        exit(true);
    end;

    procedure CollectValueEntryRelation(var TargetValueEntryRelation: Record "Value Entry Relation" temporary; RowId: Text[250]): Boolean
    begin
        TempValueEntryRelation.Reset();
        TargetValueEntryRelation.Reset();

        if TempValueEntryRelation.FindSet() then
            repeat
                TargetValueEntryRelation := TempValueEntryRelation;
                TargetValueEntryRelation."Source RowId" := RowId;
                TargetValueEntryRelation.Insert();
            until TempValueEntryRelation.Next() = 0
        else
            exit(false);

        TempValueEntryRelation.DeleteAll();

        exit(true);
    end;

    procedure CollectItemEntryRelation(var TargetItemEntryRelation: Record "Item Entry Relation" temporary): Boolean
    begin
        TempItemEntryRelation.Reset();
        TargetItemEntryRelation.Reset();

        if TempItemEntryRelation.FindSet() then
            repeat
                TargetItemEntryRelation := TempItemEntryRelation;
                TargetItemEntryRelation.Insert();
            until TempItemEntryRelation.Next() = 0
        else
            exit(false);

        TempItemEntryRelation.DeleteAll();

        exit(true);
    end;

    local procedure CheckExpirationDate(var RentalItemJnlLine2: Record "TWE Rental Item Journal Line"; SignFactor: Integer; CalcExpirationDate: Date; var ExpirationDateChecked: Boolean)
    var
        ExistingExpirationDate: Date;
        EntriesExist: Boolean;
        SumOfEntries: Decimal;
        SumLot: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckExpirationDate(
          RentalItemJnlLine2, TempTrackingSpecification, SignFactor, CalcExpirationDate, ExpirationDateChecked, IsHandled);
        if IsHandled then
            exit;

        ExistingExpirationDate :=
          ItemTrackingMgt.ExistingExpirationDate(
            TempTrackingSpecification."Item No.",
            TempTrackingSpecification."Variant Code",
            TempTrackingSpecification."Lot No.",
            TempTrackingSpecification."Serial No.",
            true,
            EntriesExist);

        if not (EntriesExist or ExpirationDateChecked) then begin
            ItemTrackingMgt.TestExpDateOnTrackingSpec(TempTrackingSpecification);
            ExpirationDateChecked := true;
        end;
        if RentalItemJnlLine2."Entry Type" = RentalItemJnlLine2."Entry Type"::Transfer then
            if TempTrackingSpecification."Expiration Date" = 0D then
                TempTrackingSpecification."Expiration Date" := ExistingExpirationDate;

        // Supply
        if SignFactor * RentalItemJnlLine2.Quantity > 0 then begin        // Only expiration dates on supply.
            if not (RentalItemJnlLine2."Entry Type" = RentalItemJnlLine2."Entry Type"::Transfer) then
                if ItemTrackingCode."Man. Expir. Date Entry Reqd." then begin
                    if RentalItemJnlLine2."Phys. Inventory" and (ExistingExpirationDate <> 0D) then
                        TempTrackingSpecification."Expiration Date" := ExistingExpirationDate;
                    if not TempTrackingSpecification.Correction then
                        TempTrackingSpecification.TestField("Expiration Date");
                end;

            if CalcExpirationDate <> 0D then
                if ExistingExpirationDate <> 0D then
                    CalcExpirationDate := ExistingExpirationDate;

            if RentalItemJnlLine2."Entry Type" = RentalItemJnlLine2."Entry Type"::Transfer then
                if TempTrackingSpecification."New Expiration Date" = 0D then
                    TempTrackingSpecification."New Expiration Date" := ExistingExpirationDate;

            if TempTrackingSpecification."Expiration Date" = 0D then
                TempTrackingSpecification."Expiration Date" := CalcExpirationDate;

            if EntriesExist then
                TempTrackingSpecification.TestField("Expiration Date", ExistingExpirationDate);
        end else   // Demand
            if RentalItemJnlLine2."Entry Type" = RentalItemJnlLine2."Entry Type"::Transfer then begin
                ExistingExpirationDate :=
                  ItemTrackingMgt.ExistingExpirationDateAndQty(
                    TempTrackingSpecification."Item No.",
                    TempTrackingSpecification."Variant Code",
                    TempTrackingSpecification."New Lot No.",
                    TempTrackingSpecification."New Serial No.",
                    SumOfEntries);

                if (RentalItemJnlLine2."Order Type" = RentalItemJnlLine2."Order Type"::Transfer) and
                   (RentalItemJnlLine2."Order No." <> '')
                then
                    if TempTrackingSpecification."New Expiration Date" = 0D then
                        TempTrackingSpecification."New Expiration Date" := ExistingExpirationDate;

                if (TempTrackingSpecification."New Lot No." <> '') and
                   ((RentalItemJnlLine2."Order Type" <> RentalItemJnlLine2."Order Type"::Transfer) or
                    (RentalItemJnlLine2."Order No." = ''))
                then begin
                    if TempTrackingSpecification."New Serial No." <> '' then
                        SumLot := SignFactor * ItemTrackingMgt.SumNewLotOnTrackingSpec(TempTrackingSpecification)
                    else
                        SumLot := SignFactor * TempTrackingSpecification."Quantity (Base)";
                    if (SumOfEntries > 0) and
                       ((SumOfEntries <> SumLot) or (TempTrackingSpecification."New Lot No." <> TempTrackingSpecification."Lot No."))
                    then
                        TempTrackingSpecification.TestField("New Expiration Date", ExistingExpirationDate);
                    ItemTrackingMgt.TestExpDateOnTrackingSpecNew(TempTrackingSpecification);
                end;
            end;

        if (RentalItemJnlLine2."Entry Type" = RentalItemJnlLine2."Entry Type"::Transfer) and
           ((RentalItemJnlLine2."Order Type" <> RentalItemJnlLine2."Order Type"::Transfer) or
            (RentalItemJnlLine2."Order No." = ''))
        then
            if ItemTrackingCode."Man. Expir. Date Entry Reqd." then
                TempTrackingSpecification.TestField("New Expiration Date");
    end;

    local procedure GetGLSetup()
    begin
        if not GLSetupRead then begin
            GLSetup.Get();
            if GLSetup."Additional Reporting Currency" <> '' then begin
                Currency.Get(GLSetup."Additional Reporting Currency");
                Currency.TestField("Unit-Amount Rounding Precision");
                Currency.TestField("Amount Rounding Precision");
            end;
        end;
        GLSetupRead := true;

        OnAfterGetGLSetup(GLSetup);
    end;

    local procedure GetMfgSetup()
    begin
        if not MfgSetupRead then
            MfgSetup.Get();
        MfgSetupRead := true;
    end;

    local procedure GetInvtSetup()
    begin
        if not InvtSetupRead then begin
            InvtSetup.Get();
            SourceCodeSetup.Get();
        end;
        InvtSetupRead := true;
    end;

    local procedure UndoQuantityPosting()
    var
        OldItemLedgEntry: Record "Item Ledger Entry";
        OldItemLedgEntry2: Record "Item Ledger Entry";
        NewItemLedgEntry: Record "Item Ledger Entry";
        OldValueEntry: Record "Value Entry";
        NewValueEntry: Record "Value Entry";
        AvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point";
        IsReserved: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUndoQuantityPosting(RentalItemJnlLine, IsHandled);
        if IsHandled then
            exit;

        if RentalItemJnlLine."Entry Type" in [RentalItemJnlLine."Entry Type"::"Assembly Consumption",
                                        RentalItemJnlLine."Entry Type"::"Assembly Output"]
        then
            exit;

        if RentalItemJnlLine."Applies-to Entry" <> 0 then begin
            OldItemLedgEntry.Get(RentalItemJnlLine."Applies-to Entry");
            if not OldItemLedgEntry.Positive then
                RentalItemJnlLine."Applies-from Entry" := RentalItemJnlLine."Applies-to Entry";
        end else
            OldItemLedgEntry.Get(RentalItemJnlLine."Applies-from Entry");

        if GetItem(OldItemLedgEntry."Item No.", false) then //begin
            MainRentalItem.TestField(Blocked, false);
        //MainRentalItem.CheckBlockedByApplWorksheet;
        //end;

        RentalItemJnlLine."Item No." := OldItemLedgEntry."Item No.";

        InitCorrItemLedgEntry(OldItemLedgEntry, NewItemLedgEntry);

        if MainRentalItem.IsNonInventoriableType then begin
            NewItemLedgEntry."Remaining Quantity" := 0;
            NewItemLedgEntry.Open := false;
        end;

        InsertItemReg(NewItemLedgEntry."Entry No.", 0, 0, 0);
        GlobalItemLedgEntry := NewItemLedgEntry;

        CalcILEExpectedAmount(OldValueEntry, OldItemLedgEntry."Entry No.");
        if OldValueEntry.Inventoriable then
            AvgCostAdjmtEntryPoint.UpdateValuationDate(OldValueEntry);
        if OldItemLedgEntry."Invoiced Quantity" = 0 then begin
            InsertCorrValueEntry(
              OldValueEntry, NewValueEntry, OldItemLedgEntry, OldValueEntry."Document Line No.", 1,
              0, OldItemLedgEntry.Quantity);
            InsertCorrValueEntry(
              OldValueEntry, NewValueEntry, NewItemLedgEntry, RentalItemJnlLine."Document Line No.", -1,
              NewItemLedgEntry.Quantity, 0);
            InsertCorrValueEntry(
              OldValueEntry, NewValueEntry, NewItemLedgEntry, RentalItemJnlLine."Document Line No.", -1,
              0, NewItemLedgEntry.Quantity);
        end else
            InsertCorrValueEntry(
              OldValueEntry, NewValueEntry, NewItemLedgEntry, RentalItemJnlLine."Document Line No.", -1,
              NewItemLedgEntry.Quantity, NewItemLedgEntry.Quantity);

        UpdateOldItemLedgEntry(OldItemLedgEntry, NewItemLedgEntry."Posting Date");
        UpdateItemApplnEntry(OldItemLedgEntry."Entry No.", NewItemLedgEntry."Posting Date");

        /*  if GlobalItemLedgEntry.Quantity > 0 then
             IsReserved :=
               ReserveItemJnlLine.TransferItemJnlToItemLedgEntry(
                 RentalItemJnlLine, GlobalItemLedgEntry, RentalItemJnlLine."Quantity (Base)", true); */

        if not RentalItemJnlLine.IsATOCorrection then begin
            ApplyItemLedgEntry(NewItemLedgEntry, OldItemLedgEntry2, NewValueEntry, false);
            AutoTrack(NewItemLedgEntry, IsReserved);
        end;

        NewItemLedgEntry.Modify();
        UpdateAdjmtProperties(NewValueEntry, NewItemLedgEntry."Posting Date");

        if NewItemLedgEntry.Positive then begin
            UpdateOrigAppliedFromEntry(OldItemLedgEntry."Entry No.");
            InsertApplEntry(
              NewItemLedgEntry."Entry No.", NewItemLedgEntry."Entry No.",
              OldItemLedgEntry."Entry No.", 0, NewItemLedgEntry."Posting Date",
              -OldItemLedgEntry.Quantity, false);
        end;
        OnAfterUndoQuantityPosting(NewItemLedgEntry, RentalItemJnlLine);
    end;

    procedure UndoValuePostingWithJob(OldItemLedgEntryNo: Integer; NewItemLedgEntryNo: Integer)
    var
        OldItemLedgEntry: Record "Item Ledger Entry";
        NewItemLedgEntry: Record "Item Ledger Entry";
        OldValueEntry: Record "Value Entry";
        NewValueEntry: Record "Value Entry";
    begin
        OldItemLedgEntry.Get(OldItemLedgEntryNo);
        NewItemLedgEntry.Get(NewItemLedgEntryNo);
        InitValueEntryNo;

        if OldItemLedgEntry."Invoiced Quantity" = 0 then begin
            CalcILEExpectedAmount(OldValueEntry, OldItemLedgEntry."Entry No.");
            InsertCorrValueEntry(
              OldValueEntry, NewValueEntry, OldItemLedgEntry, OldValueEntry."Document Line No.", 1,
              0, OldItemLedgEntry.Quantity);

            CalcILEExpectedAmount(OldValueEntry, NewItemLedgEntry."Entry No.");
            InsertCorrValueEntry(
              OldValueEntry, NewValueEntry, NewItemLedgEntry, NewItemLedgEntry."Document Line No.", 1,
              0, NewItemLedgEntry.Quantity);
        end else
            InsertCorrValueEntry(
              OldValueEntry, NewValueEntry, NewItemLedgEntry, NewItemLedgEntry."Document Line No.", -1,
              NewItemLedgEntry.Quantity, NewItemLedgEntry.Quantity);

        UpdateOldItemLedgEntry(OldItemLedgEntry, NewItemLedgEntry."Posting Date");
        UpdateOldItemLedgEntry(NewItemLedgEntry, NewItemLedgEntry."Posting Date");
        UpdateItemApplnEntry(OldItemLedgEntry."Entry No.", NewItemLedgEntry."Posting Date");

        NewItemLedgEntry.Modify();
        UpdateAdjmtProperties(NewValueEntry, NewItemLedgEntry."Posting Date");

        if NewItemLedgEntry.Positive then
            UpdateOrigAppliedFromEntry(OldItemLedgEntry."Entry No.");
    end;

    local procedure InitCorrItemLedgEntry(var OldItemLedgEntry: Record "Item Ledger Entry"; var NewItemLedgEntry: Record "Item Ledger Entry")
    var
        EntriesExist: Boolean;
    begin
        if ItemLedgEntryNo = 0 then
            ItemLedgEntryNo := GlobalItemLedgEntry."Entry No.";

        ItemLedgEntryNo := ItemLedgEntryNo + 1;
        NewItemLedgEntry := OldItemLedgEntry;
        ItemTrackingMgt.RetrieveAppliedExpirationDate(NewItemLedgEntry);
        NewItemLedgEntry."Entry No." := ItemLedgEntryNo;
        NewItemLedgEntry.Quantity := -OldItemLedgEntry.Quantity;
        NewItemLedgEntry."Remaining Quantity" := -OldItemLedgEntry.Quantity;
        if NewItemLedgEntry.Quantity > 0 then
            NewItemLedgEntry."Shipped Qty. Not Returned" := 0
        else
            NewItemLedgEntry."Shipped Qty. Not Returned" := NewItemLedgEntry.Quantity;
        NewItemLedgEntry."Invoiced Quantity" := NewItemLedgEntry.Quantity;
        NewItemLedgEntry.Positive := NewItemLedgEntry."Remaining Quantity" > 0;
        NewItemLedgEntry.Open := NewItemLedgEntry."Remaining Quantity" <> 0;
        NewItemLedgEntry."Completely Invoiced" := true;
        NewItemLedgEntry."Last Invoice Date" := NewItemLedgEntry."Posting Date";
        NewItemLedgEntry.Correction := true;
        NewItemLedgEntry."Document Line No." := RentalItemJnlLine."Document Line No.";
        if OldItemLedgEntry.Positive then
            NewItemLedgEntry."Applies-to Entry" := OldItemLedgEntry."Entry No."
        else
            NewItemLedgEntry."Applies-to Entry" := 0;

        OnBeforeInsertCorrItemLedgEntry(NewItemLedgEntry, OldItemLedgEntry, RentalItemJnlLine);
        NewItemLedgEntry.Insert();
        OnAfterInsertCorrItemLedgEntry(NewItemLedgEntry, RentalItemJnlLine, OldItemLedgEntry);

        if NewItemLedgEntry."Item Tracking" <> NewItemLedgEntry."Item Tracking"::None then
            ItemTrackingMgt.ExistingExpirationDate(
              NewItemLedgEntry."Item No.",
              NewItemLedgEntry."Variant Code",
              NewItemLedgEntry."Lot No.",
              NewItemLedgEntry."Serial No.",
              true,
              EntriesExist);
    end;

    local procedure UpdateOldItemLedgEntry(var OldItemLedgEntry: Record "Item Ledger Entry"; LastInvoiceDate: Date)
    begin
        OldItemLedgEntry."Completely Invoiced" := true;
        OldItemLedgEntry."Last Invoice Date" := LastInvoiceDate;
        OldItemLedgEntry."Invoiced Quantity" := OldItemLedgEntry.Quantity;
        OldItemLedgEntry."Shipped Qty. Not Returned" := 0;
        OnBeforeOldItemLedgEntryModify(OldItemLedgEntry);
        OldItemLedgEntry.Modify();
    end;

    local procedure InsertCorrValueEntry(OldValueEntry: Record "Value Entry"; var NewValueEntry: Record "Value Entry"; ItemLedgEntry: Record "Item Ledger Entry"; DocumentLineNo: Integer; Sign: Integer; QtyToShip: Decimal; QtyToInvoice: Decimal)
    begin
        ValueEntryNo := ValueEntryNo + 1;

        NewValueEntry := OldValueEntry;
        NewValueEntry."Entry No." := ValueEntryNo;
        NewValueEntry."Item Ledger Entry No." := ItemLedgEntry."Entry No.";
        NewValueEntry."User ID" := UserId;
        NewValueEntry."Valued Quantity" := Sign * OldValueEntry."Valued Quantity";
        NewValueEntry."Document Line No." := DocumentLineNo;
        NewValueEntry."Item Ledger Entry Quantity" := QtyToShip;
        NewValueEntry."Invoiced Quantity" := QtyToInvoice;
        NewValueEntry."Expected Cost" := QtyToInvoice = 0;
        if not NewValueEntry."Expected Cost" then begin
            NewValueEntry."Cost Amount (Expected)" := -Sign * OldValueEntry."Cost Amount (Expected)";
            NewValueEntry."Cost Amount (Expected) (ACY)" := -Sign * OldValueEntry."Cost Amount (Expected) (ACY)";
            if QtyToShip = 0 then begin
                NewValueEntry."Cost Amount (Actual)" := Sign * OldValueEntry."Cost Amount (Expected)";
                NewValueEntry."Cost Amount (Actual) (ACY)" := Sign * OldValueEntry."Cost Amount (Expected) (ACY)";
            end else begin
                NewValueEntry."Cost Amount (Actual)" := -NewValueEntry."Cost Amount (Actual)";
                NewValueEntry."Cost Amount (Actual) (ACY)" := -NewValueEntry."Cost Amount (Actual) (ACY)";
            end;
            NewValueEntry."Purchase Amount (Expected)" := -Sign * OldValueEntry."Purchase Amount (Expected)";
            NewValueEntry."Sales Amount (Expected)" := -Sign * OldValueEntry."Sales Amount (Expected)";
        end else begin
            NewValueEntry."Cost Amount (Expected)" := -OldValueEntry."Cost Amount (Expected)";
            NewValueEntry."Cost Amount (Expected) (ACY)" := -OldValueEntry."Cost Amount (Expected) (ACY)";
            NewValueEntry."Cost Amount (Actual)" := 0;
            NewValueEntry."Cost Amount (Actual) (ACY)" := 0;
            NewValueEntry."Sales Amount (Expected)" := -OldValueEntry."Sales Amount (Expected)";
            NewValueEntry."Purchase Amount (Expected)" := -OldValueEntry."Purchase Amount (Expected)";
        end;

        NewValueEntry."Purchase Amount (Actual)" := 0;
        NewValueEntry."Sales Amount (Actual)" := 0;
        NewValueEntry."Cost Amount (Non-Invtbl.)" := Sign * OldValueEntry."Cost Amount (Non-Invtbl.)";
        NewValueEntry."Cost Amount (Non-Invtbl.)(ACY)" := Sign * OldValueEntry."Cost Amount (Non-Invtbl.)(ACY)";
        NewValueEntry."Cost Posted to G/L" := 0;
        NewValueEntry."Cost Posted to G/L (ACY)" := 0;
        NewValueEntry."Expected Cost Posted to G/L" := 0;
        NewValueEntry."Exp. Cost Posted to G/L (ACY)" := 0;

        OnBeforeInsertCorrValueEntry(
          NewValueEntry, OldValueEntry, RentalItemJnlLine, Sign, CalledFromAdjustment, ItemLedgEntry, ValueEntryNo, InventoryPostingToGL);
        /* 
                if NewValueEntry.Inventoriable and not MainRentalItem."Inventory Value Zero" then
                    PostInventoryToGL(NewValueEntry); */

        NewValueEntry.Insert();

        OnAfterInsertCorrValueEntry(NewValueEntry, RentalItemJnlLine, ItemLedgEntry, ValueEntryNo);

        ItemApplnEntry.SetOutboundsNotUpdated(ItemLedgEntry);

        UpdateAdjmtProperties(NewValueEntry, ItemLedgEntry."Posting Date");

        InsertItemReg(0, 0, NewValueEntry."Entry No.", 0);
        InsertPostValueEntryToGL(NewValueEntry);
    end;

    local procedure UpdateOrigAppliedFromEntry(OldItemLedgEntryNo: Integer)
    var
        ItemApplEntry: Record "Item Application Entry";
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        ItemApplEntry.SetCurrentKey("Outbound Item Entry No.", "Item Ledger Entry No.");
        ItemApplEntry.SetRange("Outbound Item Entry No.", OldItemLedgEntryNo);
        ItemApplEntry.SetFilter("Item Ledger Entry No.", '<>%1', OldItemLedgEntryNo);
        if ItemApplEntry.FindSet() then
            repeat
                if ItemLedgEntry.Get(ItemApplEntry."Inbound Item Entry No.") and
                   not ItemLedgEntry."Applied Entry to Adjust"
                then begin
                    ItemLedgEntry."Applied Entry to Adjust" := true;
                    ItemLedgEntry.Modify();
                end;
            until ItemApplEntry.Next() = 0;
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if LocationCode = '' then
            Clear(Location)
        else
            if Location.Code <> LocationCode then
                Location.Get(LocationCode);
    end;

    local procedure GetItem(ItemNo: Code[20]; Unconditionally: Boolean): Boolean
    var
        HasGotItem: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetItem(MainRentalItem, ItemNo, Unconditionally, HasGotItem, IsHandled);
        if IsHandled then
            exit(HasGotItem);

        if not Unconditionally then
            exit(MainRentalItem.Get(ItemNo))
        else
            MainRentalItem.Get(ItemNo);
        exit(true);
    end;

    local procedure CheckItem(ItemNo: Code[20])
    begin
        if GetItem(ItemNo, false) then begin
            if not CalledFromAdjustment then
                MainRentalItem.TestField(Blocked, false);
        end else
            MainRentalItem.Init();
    end;

    procedure CheckItemTracking()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckItemTracking(RentalItemJnlLine, ItemTrackingSetup, IsHandled, TempTrackingSpecification);
        if IsHandled then
            exit;

        if ItemTrackingSetup."Serial No. Required" and (RentalItemJnlLine."Serial No." = '') then
            Error(GetTextStringWithLineNo(SerialNoRequiredErr, RentalItemJnlLine."Item No.", RentalItemJnlLine."Line No."));
        if ItemTrackingSetup."Lot No. Required" and (RentalItemJnlLine."Lot No." = '') then
            Error(GetTextStringWithLineNo(LotNoRequiredErr, RentalItemJnlLine."Item No.", RentalItemJnlLine."Line No."));
        if RentalItemJnlLine."Entry Type" = RentalItemJnlLine."Entry Type"::Transfer then begin
            if ItemTrackingSetup."Serial No. Required" then
                RentalItemJnlLine.TestField("New Serial No.");
            if ItemTrackingSetup."Lot No. Required" then
                RentalItemJnlLine.TestField("New Lot No.");
        end;

        OnAfterCheckItemTracking(RentalItemJnlLine);
    end;

    local procedure CheckItemTrackingInformation(var RentalItemJnlLine2: Record "TWE Rental Item Journal Line"; var TrackingSpecification: Record "Tracking Specification"; SignFactor: Decimal; ItemTrackingCode: Record "Item Tracking Code"; ItemTrackingSetup: Record "Item Tracking Setup")
    var
        SerialNoInfo: Record "Serial No. Information";
        LotNoInfo: Record "Lot No. Information";
    begin
        OnBeforeCheckItemTrackingInformation(RentalItemJnlLine2, TrackingSpecification, ItemTrackingSetup, SignFactor, ItemTrackingCode);

        if ItemTrackingSetup."Serial No. Info Required" then begin
            SerialNoInfo.Get(RentalItemJnlLine2."Item No.", RentalItemJnlLine2."Variant Code", TrackingSpecification."Serial No.");
            SerialNoInfo.TestField(Blocked, false);
            if TrackingSpecification."New Serial No." <> '' then begin
                SerialNoInfo.Get(RentalItemJnlLine2."Item No.", RentalItemJnlLine2."Variant Code", TrackingSpecification."New Serial No.");
                SerialNoInfo.TestField(Blocked, false);
            end;
        end else begin
            if SerialNoInfo.Get(RentalItemJnlLine2."Item No.", RentalItemJnlLine2."Variant Code", TrackingSpecification."Serial No.") then
                SerialNoInfo.TestField(Blocked, false);
            if TrackingSpecification."New Serial No." <> '' then begin
                if SerialNoInfo.Get(RentalItemJnlLine2."Item No.", RentalItemJnlLine2."Variant Code", TrackingSpecification."New Serial No.") then
                    SerialNoInfo.TestField(Blocked, false);
            end;
        end;

        if ItemTrackingSetup."Lot No. Info Required" then begin
            LotNoInfo.Get(RentalItemJnlLine2."Item No.", RentalItemJnlLine2."Variant Code", TrackingSpecification."Lot No.");
            LotNoInfo.TestField(Blocked, false);
            if TrackingSpecification."New Lot No." <> '' then begin
                LotNoInfo.Get(RentalItemJnlLine2."Item No.", RentalItemJnlLine2."Variant Code", TrackingSpecification."New Lot No.");
                LotNoInfo.TestField(Blocked, false);
            end;
        end else begin
            if LotNoInfo.Get(RentalItemJnlLine2."Item No.", RentalItemJnlLine2."Variant Code", TrackingSpecification."Lot No.") then
                LotNoInfo.TestField(Blocked, false);
            if TrackingSpecification."New Lot No." <> '' then begin
                if LotNoInfo.Get(RentalItemJnlLine2."Item No.", RentalItemJnlLine2."Variant Code", TrackingSpecification."New Lot No.") then
                    LotNoInfo.TestField(Blocked, false);
            end;
        end;

        OnAfterCheckItemTrackingInformation(RentalItemJnlLine2, TrackingSpecification, ItemTrackingSetup);
    end;

    local procedure CheckItemTrackingIsEmpty(RentalItemJnlLine: Record "TWE Rental Item Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckItemTrackingIsEmpty(RentalItemJnlLine, IsHandled);
        if IsHandled then
            exit;

        RentalItemJnlLine.CheckTrackingIsEmpty();
        RentalItemJnlLine.CheckNewTrackingIsEmpty();
    end;

    local procedure CheckItemSerialNo(RentalItemJnlLine: Record "TWE Rental Item Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckSerialNo(RentalItemJnlLine, IsHandled);
        if IsHandled then
            exit;

        if SkipSerialNoQtyValidation then
            exit;

        if RentalItemJnlLine."Entry Type" = RentalItemJnlLine."Entry Type"::Transfer then begin
            if ItemTrackingMgt.FindInInventory(RentalItemJnlLine."Item No.", RentalItemJnlLine."Variant Code", RentalItemJnlLine."New Serial No.") then
                Error(Text014Lbl, RentalItemJnlLine."New Serial No.")
        end else
            if ItemTrackingMgt.FindInInventory(RentalItemJnlLine."Item No.", RentalItemJnlLine."Variant Code", RentalItemJnlLine."Serial No.") then
                Error(Text014Lbl, RentalItemJnlLine."Serial No.");
    end;

    local procedure CheckItemCorrection(ItemLedgerEntry: Record "Item Ledger Entry")
    var
        RaiseError: Boolean;
    begin
        RaiseError := ItemLedgerEntry.Correction;
        OnBeforeCheckItemCorrection(ItemLedgerEntry, RaiseError);
        if RaiseError then
            Error(CannotUnapplyCorrEntryErr);
    end;

    local procedure InsertTempTrkgSpecification(FreeEntryNo: Integer)
    var
        TempTrackingSpecification2: Record "Tracking Specification" temporary;
    begin
        if not TempTrackingSpecification.Insert() then begin
            TempTrackingSpecification2 := TempTrackingSpecification;
            TempTrackingSpecification.Get(TempTrackingSpecification2."Item Ledger Entry No.");
            TempTrackingSpecification.Delete();
            TempTrackingSpecification."Entry No." := FreeEntryNo;
            TempTrackingSpecification.Insert();
            TempTrackingSpecification := TempTrackingSpecification2;
            TempTrackingSpecification.Insert();
        end;
    end;

    local procedure IsNotInternalWhseMovement(RentalItemJnlLine: Record "TWE Rental Item Journal Line"): Boolean
    begin
        if (RentalItemJnlLine."Entry Type" = RentalItemJnlLine."Entry Type"::Transfer) and
           (RentalItemJnlLine."Location Code" = RentalItemJnlLine."New Location Code") and
           (RentalItemJnlLine."Dimension Set ID" = RentalItemJnlLine."New Dimension Set ID") and
           (RentalItemJnlLine."Value Entry Type" = RentalItemJnlLine."Value Entry Type"::"Direct Cost") and
           not RentalItemJnlLine.Adjustment
        then
            exit(false);
        exit(true)
    end;

    procedure SetCalledFromInvtPutawayPick(NewCalledFromInvtPutawayPick: Boolean)
    begin
        CalledFromInvtPutawayPick := NewCalledFromInvtPutawayPick;
    end;

    procedure SetCalledFromAdjustment(NewCalledFromAdjustment: Boolean; NewPostToGL: Boolean)
    begin
        CalledFromAdjustment := NewCalledFromAdjustment;
        PostToGL := NewPostToGL;
    end;

    procedure NextOperationExist(var ProdOrderRtngLine: Record "Prod. Order Routing Line"): Boolean
    begin
        OnBeforeNextOperationExist(ProdOrderRtngLine);
        exit(ProdOrderRtngLine."Next Operation No." <> '');
    end;

    local procedure UpdateAdjmtProperties(ValueEntry: Record "Value Entry"; OriginalPostingDate: Date)
    begin
        SetAdjmtProperties(
          ValueEntry."Item No.", ValueEntry."Item Ledger Entry Type", ValueEntry.Adjustment,
          ValueEntry."Order Type", ValueEntry."Order No.", ValueEntry."Order Line No.", OriginalPostingDate, ValueEntry."Valuation Date");

        OnAfterUpdateAdjmtProp(ValueEntry, OriginalPostingDate);
    end;

    local procedure SetAdjmtProperties(ItemNo: Code[20]; ItemLedgEntryType: Enum "Item Ledger Entry Type"; Adjustment: Boolean; OrderType: Enum "Inventory Order Type"; OrderNo: Code[20]; OrderLineNo: Integer; OriginalPostingDate: Date; ValuationDate: Date)
    begin
        SetItemAdjmtProperties(ItemNo, ItemLedgEntryType, Adjustment, OriginalPostingDate, ValuationDate);
        SetOrderAdjmtProperties(ItemLedgEntryType, OrderType, OrderNo, OrderLineNo, OriginalPostingDate, ValuationDate);
    end;

    local procedure SetItemAdjmtProperties(ItemNo: Code[20]; ItemLedgEntryType: Enum "Item Ledger Entry Type"; Adjustment: Boolean; OriginalPostingDate: Date; ValuationDate: Date)
    var
        MainRentalItem: Record "TWE Main Rental Item";
        ValueEntry: Record "Value Entry";
        ModifyItem: Boolean;
    begin
        if ItemLedgEntryType = ValueEntry."Item Ledger Entry Type"::" " then
            exit;
        if Adjustment then
            if not (ItemLedgEntryType in [ValueEntry."Item Ledger Entry Type"::Output,
                                          ValueEntry."Item Ledger Entry Type"::"Assembly Output"])
            then
                exit;

        /* with MainRentalItem do
            if Get(ItemNo) and ("Allow Online Adjustment" or "Cost is Adjusted") and (Type = Type::Inventory) then begin
                LockTable();
                if "Cost is Adjusted" then begin
                    "Cost is Adjusted" := false;
                    ModifyItem := true;
                end;
                if "Allow Online Adjustment" then begin
                    if "Costing Method" = "Costing Method"::Average then
                        "Allow Online Adjustment" := AllowAdjmtOnPosting(ValuationDate)
                    else
                        "Allow Online Adjustment" := AllowAdjmtOnPosting(OriginalPostingDate);
                    ModifyItem := ModifyItem or not "Allow Online Adjustment";
                end;
                if ModifyItem then
                    Modify();
            end; */
    end;

    local procedure SetOrderAdjmtProperties(ItemLedgEntryType: Enum "Item Ledger Entry Type"; OrderType: Enum "Inventory Order Type"; OrderNo: Code[20]; OrderLineNo: Integer; OriginalPostingDate: Date; ValuationDate: Date)
    var
        ValueEntry: Record "Value Entry";
        InvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
        ProdOrderLine: Record "Prod. Order Line";
        AssemblyHeader: Record "Assembly Header";
        ModifyOrderAdjmt: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetOrderAdjmtProperties(
            ItemLedgEntryType.AsInteger(), OrderType.AsInteger(), OrderNo, OrderLineNo, OriginalPostingDate, ValuationDate, IsHandled);
        if IsHandled then
            exit;

        if not (OrderType in [ValueEntry."Order Type"::Production,
                              ValueEntry."Order Type"::Assembly])
        then
            exit;

        if ItemLedgEntryType in [ValueEntry."Item Ledger Entry Type"::Output,
                                 ValueEntry."Item Ledger Entry Type"::"Assembly Output"]
        then
            exit;

        if not InvtAdjmtEntryOrder.Get(OrderType, OrderNo, OrderLineNo) then
            case OrderType of
                InvtAdjmtEntryOrder."Order Type"::Production:
                    begin
                        ProdOrderLine.Get(ProdOrderLine.Status::Released, OrderNo, OrderLineNo);
                        InvtAdjmtEntryOrder.SetProdOrderLine(ProdOrderLine);
                        SetOrderAdjmtProperties(ItemLedgEntryType, OrderType, OrderNo, OrderLineNo, OriginalPostingDate, ValuationDate);
                    end;
                InvtAdjmtEntryOrder."Order Type"::Assembly:
                    begin
                        if OrderLineNo = 0 then begin
                            AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, OrderNo);
                            InvtAdjmtEntryOrder.SetAsmOrder(AssemblyHeader);
                        end;
                        SetOrderAdjmtProperties(ItemLedgEntryType, OrderType, OrderNo, 0, OriginalPostingDate, ValuationDate);
                    end;
            end
        else
            if InvtAdjmtEntryOrder."Allow Online Adjustment" or InvtAdjmtEntryOrder."Cost is Adjusted" then begin
                InvtAdjmtEntryOrder.LockTable();
                IsHandled := false;
                OnSetOrderAdjmtPropertiesOnBeforeSetCostIsAdjusted(InvtAdjmtEntryOrder, ModifyOrderAdjmt, IsHandled);
                if not IsHandled then
                    if InvtAdjmtEntryOrder."Cost is Adjusted" then begin
                        InvtAdjmtEntryOrder."Cost is Adjusted" := false;
                        ModifyOrderAdjmt := true;
                    end;
                IsHandled := false;
                OnSetOrderAdjmtPropertiesOnBeforeSetAllowOnlineAdjustment(InvtAdjmtEntryOrder, ModifyOrderAdjmt, IsHandled);
                if not IsHandled then
                    if InvtAdjmtEntryOrder."Allow Online Adjustment" then begin
                        InvtAdjmtEntryOrder."Allow Online Adjustment" := AllowAdjmtOnPosting(OriginalPostingDate);
                        ModifyOrderAdjmt := ModifyOrderAdjmt or not InvtAdjmtEntryOrder."Allow Online Adjustment";
                    end;
                if ModifyOrderAdjmt then
                    InvtAdjmtEntryOrder.Modify();
            end;
    end;

    procedure AllowAdjmtOnPosting(TheDate: Date): Boolean
    begin
        GetInvtSetup;

        case InvtSetup."Automatic Cost Adjustment" of
            InvtSetup."Automatic Cost Adjustment"::Never:
                exit(false);
            InvtSetup."Automatic Cost Adjustment"::Day:
                exit(TheDate >= CalcDate('<-1D>', WorkDate()));
            InvtSetup."Automatic Cost Adjustment"::Week:
                exit(TheDate >= CalcDate('<-1W>', WorkDate()));
            InvtSetup."Automatic Cost Adjustment"::Month:
                exit(TheDate >= CalcDate('<-1M>', WorkDate()));
            InvtSetup."Automatic Cost Adjustment"::Quarter:
                exit(TheDate >= CalcDate('<-1Q>', WorkDate()));
            InvtSetup."Automatic Cost Adjustment"::Year:
                exit(TheDate >= CalcDate('<-1Y>', WorkDate()));
            else
                exit(true);
        end;
    end;

    local procedure InsertBalanceExpCostRevEntry(ValueEntry: Record "Value Entry")
    var
        ValueEntry2: Record "Value Entry";
        ValueEntry3: Record "Value Entry";
        RevExpCostToBalance: Decimal;
        RevExpCostToBalanceACY: Decimal;
    begin
        if GlobalItemLedgEntry.Quantity - (GlobalItemLedgEntry."Invoiced Quantity" - ValueEntry."Invoiced Quantity") = 0 then
            exit;
        ValueEntry2.SetCurrentKey("Item Ledger Entry No.", "Entry Type");
        ValueEntry2.SetRange("Item Ledger Entry No.", ValueEntry."Item Ledger Entry No.");
        ValueEntry2.SetRange("Entry Type", ValueEntry2."Entry Type"::Revaluation);
        ValueEntry2.SetRange("Applies-to Entry", 0);
        if ValueEntry2.FindSet() then
            repeat
                CalcRevExpCostToBalance(ValueEntry2, ValueEntry."Invoiced Quantity", RevExpCostToBalance, RevExpCostToBalanceACY);
                if (RevExpCostToBalance <> 0) or (RevExpCostToBalanceACY <> 0) then begin
                    ValueEntryNo := ValueEntryNo + 1;
                    ValueEntry3 := ValueEntry;
                    ValueEntry3."Entry No." := ValueEntryNo;
                    ValueEntry3."Item Charge No." := '';
                    ValueEntry3."Entry Type" := ValueEntry."Entry Type"::Revaluation;
                    ValueEntry3."Valuation Date" := ValueEntry2."Valuation Date";
                    ValueEntry3.Description := '';
                    ValueEntry3."Applies-to Entry" := ValueEntry2."Entry No.";
                    ValueEntry3."Cost Amount (Expected)" := RevExpCostToBalance;
                    ValueEntry3."Cost Amount (Expected) (ACY)" := RevExpCostToBalanceACY;
                    ValueEntry3."Valued Quantity" := ValueEntry2."Valued Quantity";
                    ValueEntry3."Cost per Unit" := CalcCostPerUnit(RevExpCostToBalance, ValueEntry."Valued Quantity", false);
                    ValueEntry3."Cost per Unit (ACY)" := CalcCostPerUnit(RevExpCostToBalanceACY, ValueEntry."Valued Quantity", true);
                    ValueEntry3."Cost Posted to G/L" := 0;
                    ValueEntry3."Cost Posted to G/L (ACY)" := 0;
                    ValueEntry3."Expected Cost Posted to G/L" := 0;
                    ValueEntry3."Exp. Cost Posted to G/L (ACY)" := 0;
                    ValueEntry3."Invoiced Quantity" := 0;
                    ValueEntry3."Sales Amount (Actual)" := 0;
                    ValueEntry3."Purchase Amount (Actual)" := 0;
                    ValueEntry3."Discount Amount" := 0;
                    ValueEntry3."Cost Amount (Actual)" := 0;
                    ValueEntry3."Cost Amount (Actual) (ACY)" := 0;
                    ValueEntry3."Sales Amount (Expected)" := 0;
                    ValueEntry3."Purchase Amount (Expected)" := 0;
                    InsertValueEntry(ValueEntry3, GlobalItemLedgEntry, false);
                end;
            until ValueEntry2.Next() = 0;
    end;

    local procedure IsBalanceExpectedCostFromRev(RentalItemJnlLine2: Record "TWE Rental Item Journal Line"): Boolean
    begin
        exit((MainRentalItem."Costing Method" = MainRentalItem."Costing Method"::Standard) and
          (((RentalItemJnlLine2.Quantity = 0) and (RentalItemJnlLine2."Invoiced Quantity" <> 0)) or
           (RentalItemJnlLine2.Adjustment and not GlobalValueEntry."Expected Cost")));
    end;

    local procedure CalcRevExpCostToBalance(ValueEntry: Record "Value Entry"; InvdQty: Decimal; var RevExpCostToBalance: Decimal; var RevExpCostToBalanceACY: Decimal)
    var
        ValueEntry2: Record "Value Entry";
        OldExpectedQty: Decimal;
    begin
        RevExpCostToBalance := -ValueEntry."Cost Amount (Expected)";
        RevExpCostToBalanceACY := -ValueEntry."Cost Amount (Expected) (ACY)";
        OldExpectedQty := GlobalItemLedgEntry.Quantity;
        ValueEntry2.SetCurrentKey("Item Ledger Entry No.", ValueEntry2."Entry Type");
        ValueEntry2.SetRange("Item Ledger Entry No.", ValueEntry."Item Ledger Entry No.");
        if GlobalItemLedgEntry.Quantity <> GlobalItemLedgEntry."Invoiced Quantity" then begin
            ValueEntry2.SetRange("Entry Type", ValueEntry2."Entry Type"::"Direct Cost");
            ValueEntry2.SetFilter("Entry No.", '<%1', ValueEntry."Entry No.");
            ValueEntry2.SetRange("Item Charge No.", '');
            if ValueEntry2.FindSet() then
                repeat
                    OldExpectedQty := OldExpectedQty - ValueEntry2."Invoiced Quantity";
                until ValueEntry2.Next() = 0;

            RevExpCostToBalance := Round(RevExpCostToBalance * InvdQty / OldExpectedQty, GLSetup."Amount Rounding Precision");
            RevExpCostToBalanceACY := Round(RevExpCostToBalanceACY * InvdQty / OldExpectedQty, Currency."Amount Rounding Precision");
        end else begin
            ValueEntry2.SetRange("Entry Type", ValueEntry2."Entry Type"::Revaluation);
            ValueEntry2.SetRange("Applies-to Entry", ValueEntry."Entry No.");
            if ValueEntry2.FindSet() then
                repeat
                    RevExpCostToBalance := RevExpCostToBalance - ValueEntry2."Cost Amount (Expected)";
                    RevExpCostToBalanceACY := RevExpCostToBalanceACY - ValueEntry2."Cost Amount (Expected) (ACY)";
                until ValueEntry2.Next() = 0;
        end;
    end;

    local procedure IsInterimRevaluation(): Boolean
    begin
        exit((RentalItemJnlLine."Value Entry Type" = RentalItemJnlLine."Value Entry Type"::Revaluation) and (RentalItemJnlLine.Quantity <> 0));
    end;

    local procedure InsertPostValueEntryToGL(ValueEntry: Record "Value Entry")
    var
        PostValueEntryToGL: Record "Post Value Entry to G/L";
    begin
        if IsPostToGL(ValueEntry) then begin
            PostValueEntryToGL.Init();
            PostValueEntryToGL."Value Entry No." := ValueEntry."Entry No.";
            PostValueEntryToGL."Item No." := ValueEntry."Item No.";
            PostValueEntryToGL."Posting Date" := ValueEntry."Posting Date";
            OnInsertPostValueEntryToGLOnAfterTransferFields(PostValueEntryToGL, ValueEntry);
            PostValueEntryToGL.Insert();
        end;
    end;

    local procedure IsPostToGL(ValueEntry: Record "Value Entry"): Boolean
    begin
        GetInvtSetup;
        exit(
          ValueEntry.Inventoriable and not PostToGL and
          (((not ValueEntry."Expected Cost") and ((ValueEntry."Cost Amount (Actual)" <> 0) or (ValueEntry."Cost Amount (Actual) (ACY)" <> 0))) or
           (InvtSetup."Expected Cost Posting to G/L" and ((ValueEntry."Cost Amount (Expected)" <> 0) or (ValueEntry."Cost Amount (Expected) (ACY)" <> 0)))));
    end;

    local procedure IsWarehouseReclassification(RentalItemJournalLine: Record "TWE Rental Item Journal Line"): Boolean
    begin
        exit(RentalItemJournalLine."Warehouse Adjustment" and (RentalItemJournalLine."Entry Type" = RentalItemJournalLine."Entry Type"::Transfer));
    end;

    local procedure MoveApplication(var ItemLedgEntry: Record "Item Ledger Entry"; var OldItemLedgEntry: Record "Item Ledger Entry"): Boolean
    var
        Application: Record "Item Application Entry";
        Enough: Boolean;
        FixedApplication: Boolean;
    begin
        OnBeforeMoveApplication(ItemLedgEntry, OldItemLedgEntry);

        FixedApplication := false;
        OldItemLedgEntry.TestField(Positive, true);

        if (OldItemLedgEntry."Remaining Quantity" < Abs(ItemLedgEntry.Quantity)) and
           (OldItemLedgEntry."Remaining Quantity" < OldItemLedgEntry.Quantity)
        then begin
            Enough := false;
            Application.Reset();
            Application.SetCurrentKey("Inbound Item Entry No.");
            Application.SetRange("Inbound Item Entry No.", ItemLedgEntry."Applies-to Entry");
            Application.SetFilter("Outbound Item Entry No.", '<>0');

            if Application.FindSet() then begin
                repeat
                    if not Application.Fixed then begin
                        UnApply(Application);
                        OldItemLedgEntry.Get(OldItemLedgEntry."Entry No.");
                        OldItemLedgEntry.CalcFields("Reserved Quantity");
                        Enough :=
                          Abs(OldItemLedgEntry."Remaining Quantity" - OldItemLedgEntry."Reserved Quantity") >=
                          Abs(ItemLedgEntry."Remaining Quantity");
                    end else
                        FixedApplication := true;
                until (Application.Next() = 0) or Enough;
            end else
                exit(false); // no applications found that could be undone
            if not Enough and FixedApplication then
                Error(Text027Lbl);
            exit(Enough);
        end;
        exit(true);
    end;

    local procedure CheckApplication(ItemLedgEntry: Record "Item Ledger Entry"; OldItemLedgEntry: Record "Item Ledger Entry")
    begin
        if SkipApplicationCheck then begin
            SkipApplicationCheck := false;
            exit;
        end;

        if Abs(OldItemLedgEntry."Remaining Quantity" - OldItemLedgEntry."Reserved Quantity") <
           Abs(ItemLedgEntry."Remaining Quantity" - ItemLedgEntry."Reserved Quantity")
        then
            OldItemLedgEntry.FieldError("Remaining Quantity", Text004Lbl)
    end;

    local procedure CheckApplFromInProduction(var GlobalItemLedgerEntry: Record "Item Ledger Entry"; AppliesFRomEntryNo: Integer)
    var
        OldItemLedgerEntry: Record "Item Ledger Entry";
    begin
        if AppliesFRomEntryNo = 0 then
            exit;

        if (GlobalItemLedgerEntry."Order Type" = GlobalItemLedgerEntry."Order Type"::Production) and (GlobalItemLedgerEntry."Order No." <> '') then begin
            OldItemLedgerEntry.Get(AppliesFRomEntryNo);
            if not AllowProdApplication(OldItemLedgerEntry, GlobalItemLedgEntry) then
                Error(
                  Text022Lbl,
                  OldItemLedgerEntry."Entry Type",
                  GlobalItemLedgerEntry."Entry Type",
                  GlobalItemLedgerEntry."Item No.",
                  GlobalItemLedgerEntry."Order No.");

            if ItemApplnEntry.CheckIsCyclicalLoop(GlobalItemLedgerEntry, OldItemLedgerEntry) then
                Error(
                  Text022Lbl,
                  OldItemLedgerEntry."Entry Type",
                  GlobalItemLedgerEntry."Entry Type",
                  GlobalItemLedgerEntry."Item No.",
                  GlobalItemLedgerEntry."Order No.");
        end;
    end;

    procedure RedoApplications()
    var
        TouchedItemLedgEntry: Record "Item Ledger Entry";
        DialogWindow: Dialog;
        "Count": Integer;
        t: Integer;
    begin
        TempTouchedItemLedgerEntries.SetCurrentKey("Item No.", Open, "Variant Code", Positive, "Location Code", "Posting Date");
        if TempTouchedItemLedgerEntries.Find('-') then begin
            DialogWindow.Open(Text01Lbl +
              '@1@@@@@@@@@@@@@@@@@@@@@@@');
            Count := TempTouchedItemLedgerEntries.Count();
            t := 0;

            repeat
                t := t + 1;
                DialogWindow.Update(1, Round(t * 10000 / Count, 1));
                TouchedItemLedgEntry.Get(TempTouchedItemLedgerEntries."Entry No.");
                if TouchedItemLedgEntry."Remaining Quantity" <> 0 then begin
                    ReApply(TouchedItemLedgEntry, 0);
                    TouchedItemLedgEntry.Get(TempTouchedItemLedgerEntries."Entry No.");
                end;
            until TempTouchedItemLedgerEntries.Next() = 0;
            if AnyTouchedEntries then
                VerifyTouchedOnInventory;
            TempTouchedItemLedgerEntries.DeleteAll();
            DeleteTouchedEntries;
            DialogWindow.Close();
        end;
    end;

    local procedure UpdateValuedByAverageCost(CostItemLedgEntryNo: Integer; ValuedByAverage: Boolean)
    var
        ValueEntry: Record "Value Entry";
    begin
        if CostItemLedgEntryNo = 0 then
            exit;

        ValueEntry.SetCurrentKey("Item Ledger Entry No.");
        ValueEntry.SetRange("Item Ledger Entry No.", CostItemLedgEntryNo);
        ValueEntry.SetRange("Valued By Average Cost", not ValuedByAverage);
        ValueEntry.ModifyAll("Valued By Average Cost", ValuedByAverage);
    end;

    procedure CostAdjust()
    var
        InvtSetup: Record "Inventory Setup";
        InventoryPeriod: Record "Inventory Period";
        InvtAdjmt: Codeunit "Inventory Adjustment";
        Opendate: Date;
    begin
        InvtSetup.Get();
        InventoryPeriod.IsValidDate(Opendate);
        if InvtSetup."Automatic Cost Adjustment" <>
           InvtSetup."Automatic Cost Adjustment"::Never
        then begin
            if Opendate <> 0D then
                Opendate := CalcDate('<+1D>', Opendate);
            InvtAdjmt.SetProperties(true, InvtSetup."Automatic Cost Posting");
            InvtAdjmt.MakeMultiLevelAdjmt;
        end;
    end;

    local procedure TouchEntry(EntryNo: Integer)
    var
        TouchedItemLedgEntry: Record "Item Ledger Entry";
    begin
        TouchedItemLedgEntry.Get(EntryNo);
        TempTouchedItemLedgerEntries := TouchedItemLedgEntry;
        if not TempTouchedItemLedgerEntries.Insert() then;
    end;

    local procedure TouchItemEntryCost(var ItemLedgerEntry: Record "Item Ledger Entry"; IsAdjustment: Boolean)
    var
        ValueEntry: Record "Value Entry";
        AvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point";
    begin
        ItemLedgerEntry."Applied Entry to Adjust" := true;
        SetAdjmtProperties(
          ItemLedgerEntry."Item No.", ItemLedgerEntry."Entry Type", IsAdjustment, ItemLedgerEntry."Order Type", ItemLedgerEntry."Order No.", ItemLedgerEntry."Order Line No.", ItemLedgerEntry."Posting Date", ItemLedgerEntry."Posting Date");

        OnTouchItemEntryCostOnAfterAfterSetAdjmtProp(ItemLedgerEntry, IsAdjustment);

        if not IsAdjustment then begin
            EnsureValueEntryLoaded(ValueEntry, ItemLedgerEntry);
            AvgCostAdjmtEntryPoint.UpdateValuationDate(ValueEntry);
        end;
    end;

    procedure AnyTouchedEntries(): Boolean
    begin
        exit(TempTouchedItemLedgerEntries.Find('-'))
    end;

    local procedure GetMaxAppliedValuationdate(ItemLedgerEntry: Record "Item Ledger Entry"): Date
    var
        ToItemApplnEntry: Record "Item Application Entry";
        FromItemledgEntryNo: Integer;
        FromInbound: Boolean;
        MaxDate: Date;
        NewDate: Date;
    begin
        FromInbound := ItemLedgerEntry.Positive;
        FromItemledgEntryNo := ItemLedgerEntry."Entry No.";
        if FromInbound then begin
            ToItemApplnEntry.SetCurrentKey("Inbound Item Entry No.", "Item Ledger Entry No.", "Outbound Item Entry No.");
            ToItemApplnEntry.SetRange("Inbound Item Entry No.", FromItemledgEntryNo);
            ToItemApplnEntry.SetFilter("Outbound Item Entry No.", '<>%1', 0);
            ToItemApplnEntry.SetFilter(Quantity, '>%1', 0);
        end else begin
            ToItemApplnEntry.SetCurrentKey("Outbound Item Entry No.", "Item Ledger Entry No.");
            ToItemApplnEntry.SetRange("Outbound Item Entry No.", FromItemledgEntryNo);
            ToItemApplnEntry.SetFilter(Quantity, '<%1', 0);
        end;
        if ToItemApplnEntry.FindSet() then begin
            MaxDate := 0D;
            repeat
                if FromInbound then
                    ItemLedgerEntry.Get(ToItemApplnEntry."Outbound Item Entry No.")
                else
                    ItemLedgerEntry.Get(ToItemApplnEntry."Inbound Item Entry No.");
                NewDate := GetMaxValuationDate(ItemLedgerEntry);
                MaxDate := Max(NewDate, MaxDate);
            until ToItemApplnEntry.Next() = 0
        end;
        exit(MaxDate);
    end;

    local procedure "Max"(Date1: Date; Date2: Date): Date
    begin
        if Date1 > Date2 then
            exit(Date1);
        exit(Date2);
    end;

    procedure SetValuationDateAllValueEntrie(ItemLedgerEntryNo: Integer; ValuationDate: Date; FixedApplication: Boolean)
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.Reset();
        ValueEntry.SetCurrentKey("Item Ledger Entry No.");
        ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgerEntryNo);
        if ValueEntry.FindSet() then
            repeat
                if (ValueEntry."Valuation Date" <> ValueEntry."Posting Date") or
                   (ValueEntry."Valuation Date" < ValuationDate) or
                   ((ValueEntry."Valuation Date" > ValuationDate) and FixedApplication)
                then begin
                    ValueEntry."Valuation Date" := ValuationDate;
                    ValueEntry.Modify();
                end;
            until ValueEntry.Next() = 0;
    end;

    procedure SetServUndoConsumption(Value: Boolean)
    begin
        IsServUndoConsumption := Value;
    end;

    procedure SetProdOrderCompModified(ProdOrderCompIsModified: Boolean)
    begin
        ProdOrderCompModified := ProdOrderCompIsModified;
    end;

    local procedure InsertCountryCode(var NewItemLedgEntry: Record "Item Ledger Entry"; ItemLedgEntry: Record "Item Ledger Entry")
    begin
        if ItemLedgEntry."Location Code" = '' then
            exit;
        if NewItemLedgEntry."Location Code" = '' then begin
            Location.Get(ItemLedgEntry."Location Code");
            NewItemLedgEntry."Country/Region Code" := Location."Country/Region Code";
        end else begin
            Location.Get(NewItemLedgEntry."Location Code");
            if not Location."Use As In-Transit" then begin
                Location.Get(ItemLedgEntry."Location Code");
                if not Location."Use As In-Transit" then
                    NewItemLedgEntry."Country/Region Code" := Location."Country/Region Code";
            end;
        end;
    end;

    local procedure ReservationPreventsApplication(ApplicationEntry: Integer; ItemNo: Code[20]; ReservationsEntry: Record "Item Ledger Entry")
    var
        ReservationEntries: Record "Reservation Entry";
        ReservEngineMgt: Codeunit "Reservation Engine Mgt.";
        ReserveItemLedgEntry: Codeunit "Item Ledger Entry-Reserve";
    begin
        ReservEngineMgt.InitFilterAndSortingLookupFor(ReservationEntries, true);
        ReserveItemLedgEntry.FilterReservFor(ReservationEntries, ReservationsEntry);
        if ReservationEntries.FindFirst() then;
        Error(
          Text029Lbl,
          ReservationsEntry.FieldCaption("Applies-to Entry"),
          ApplicationEntry,
          MainRentalItem.FieldCaption("No."),
          ItemNo,
          ReservEngineMgt.CreateForText(ReservationEntries));
    end;

    local procedure CheckItemTrackingOfComp(TempHandlingSpecification: Record "Tracking Specification"; RentalItemJnlLine: Record "TWE Rental Item Journal Line")
    begin
        if ItemTrackingSetup."Serial No. Required" then
            RentalItemJnlLine.TestField("Serial No.", TempHandlingSpecification."Serial No.");
        if ItemTrackingSetup."Lot No. Required" then
            RentalItemJnlLine.TestField("Lot No.", TempHandlingSpecification."Lot No.");
    end;

    local procedure MaxConsumptionValuationDate(ItemLedgerEntry: Record "Item Ledger Entry"): Date
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetCurrentKey("Item Ledger Entry Type", "Order No.", "Valuation Date");
        ValueEntry.SetRange("Order Type", ValueEntry."Order Type"::Production);
        ValueEntry.SetRange("Order No.", ItemLedgerEntry."Order No.");
        ValueEntry.SetRange("Order Line No.", ItemLedgerEntry."Order Line No.");
        ValueEntry.SetRange("Item Ledger Entry Type", "Item Ledger Entry Type"::Consumption);
        ValueEntry.SetFilter("Entry Type", '<>%1', ValueEntry."Entry Type"::Revaluation);
        if ValueEntry.FindLast() then
            exit(ValueEntry."Valuation Date");
    end;

    local procedure CorrectOutputValuationDate(ItemLedgerEntry: Record "Item Ledger Entry")
    var
        ValueEntry: Record "Value Entry";
        TempValueEntry: Record "Value Entry" temporary;
        ProductionOrder: Record "Production Order";
        ValuationDate: Date;
        IsHandled: Boolean;
    begin
        if not (ItemLedgerEntry."Entry Type" in [ItemLedgerEntry."Entry Type"::Consumption, ItemLedgerEntry."Entry Type"::Output]) then
            exit;

        IsHandled := false;
        OnCorrectOutputValuationDateOnBeforeCheckProdOrder(ItemLedgerEntry, IsHandled);
        if not IsHandled then
            if not ProductionOrder.Get(ProductionOrder.Status::Released, ItemLedgerEntry."Order No.") then
                exit;

        ValuationDate := MaxConsumptionValuationDate(ItemLedgerEntry);

        ValueEntry.SetCurrentKey("Order Type", "Order No.");
        ValueEntry.SetFilter("Valuation Date", '<%1', ValuationDate);
        ValueEntry.SetRange("Order No.", ItemLedgerEntry."Order No.");
        ValueEntry.SetRange("Order Line No.", ItemLedgerEntry."Order Line No.");
        ValueEntry.SetRange("Item Ledger Entry Type", ValueEntry."Item Ledger Entry Type"::Output);
        if ValueEntry.FindSet() then
            repeat
                TempValueEntry := ValueEntry;
                TempValueEntry.Insert();
            until ValueEntry.Next() = 0;

        UpdateOutputEntryAndChain(TempValueEntry, ValuationDate);
    end;

    local procedure UpdateOutputEntryAndChain(var TempValueEntry: Record "Value Entry" temporary; ValuationDate: Date)
    var
        ValueEntry: Record "Value Entry";
        ItemLedgerEntryNo: Integer;
    begin
        TempValueEntry.SetCurrentKey("Item Ledger Entry No.", "Entry Type");
        if TempValueEntry.Find('-') then
            repeat
                ValueEntry.Get(TempValueEntry."Entry No.");
                if ValueEntry."Valuation Date" < ValuationDate then begin
                    if ItemLedgerEntryNo <> TempValueEntry."Item Ledger Entry No." then begin
                        ItemLedgerEntryNo := TempValueEntry."Item Ledger Entry No.";
                        UpdateLinkedValuationDate(ValuationDate, ItemLedgerEntryNo, true);
                    end;

                    ValueEntry."Valuation Date" := ValuationDate;
                    ValueEntry.Modify();
                    if ValueEntry."Entry No." = DirCostValueEntry."Entry No." then
                        DirCostValueEntry := ValueEntry;
                end;
            until TempValueEntry.Next() = 0;
    end;

    local procedure GetSourceNo(RentalItemJnlLine: Record "TWE Rental Item Journal Line"): Code[20]
    begin
        if RentalItemJnlLine."Invoice-to Source No." <> '' then
            exit(RentalItemJnlLine."Invoice-to Source No.");
        exit(RentalItemJnlLine."Source No.");
    end;

    local procedure PostAssemblyResourceConsump()
    var
        CapLedgEntry: Record "Capacity Ledger Entry";
        DirCostAmt: Decimal;
        IndirCostAmt: Decimal;
    begin
        InsertCapLedgEntry(CapLedgEntry, RentalItemJnlLine.Quantity, RentalItemJnlLine.Quantity);
        CalcDirAndIndirCostAmts(DirCostAmt, IndirCostAmt, RentalItemJnlLine.Quantity, RentalItemJnlLine."Unit Cost", RentalItemJnlLine."Indirect Cost %", RentalItemJnlLine."Overhead Rate");

        InsertCapValueEntry(CapLedgEntry, RentalItemJnlLine."Value Entry Type"::"Direct Cost", RentalItemJnlLine.Quantity, RentalItemJnlLine.Quantity, DirCostAmt);
        InsertCapValueEntry(CapLedgEntry, RentalItemJnlLine."Value Entry Type"::"Indirect Cost", RentalItemJnlLine.Quantity, 0, IndirCostAmt);
    end;

    local procedure InsertAsmItemEntryRelation(ItemLedgerEntry: Record "Item Ledger Entry")
    begin
        GetItem(ItemLedgerEntry."Item No.", true);
        if MainRentalItem."Item Tracking Code" <> '' then begin
            TempItemEntryRelation."Item Entry No." := ItemLedgerEntry."Entry No.";
            TempItemEntryRelation.CopyTrackingFromItemLedgEntry(ItemLedgerEntry);
            OnBeforeTempItemEntryRelationInsert(TempItemEntryRelation, ItemLedgerEntry);
            TempItemEntryRelation.Insert();
        end;
    end;

    local procedure VerifyInvoicedQty(ItemLedgerEntry: Record "Item Ledger Entry"; ValueEntry: Record "Value Entry")
    var
        ItemLedgEntry2: Record "Item Ledger Entry";
        ItemApplnEntry: Record "Item Application Entry";
        RentalShipmentHeader: Record "TWE Rental Shipment Header";
        TotalInvoicedQty: Decimal;
        IsHandled: Boolean;
    begin
        if not (ItemLedgerEntry."Drop Shipment" and (ItemLedgerEntry."Entry Type" = ItemLedgerEntry."Entry Type"::Purchase)) then
            exit;

        IsHandled := false;
        OnBeforeVerifyInvoicedQty(ItemLedgerEntry, IsHandled, ValueEntry);
        if IsHandled then
            exit;

        ItemApplnEntry.SetCurrentKey("Inbound Item Entry No.", "Item Ledger Entry No.", "Outbound Item Entry No.");
        ItemApplnEntry.SetRange("Inbound Item Entry No.", ItemLedgerEntry."Entry No.");
        ItemApplnEntry.SetFilter("Item Ledger Entry No.", '<>%1', ItemLedgerEntry."Entry No.");
        if ItemApplnEntry.FindSet() then begin
            repeat
                ItemLedgEntry2.Get(ItemApplnEntry."Item Ledger Entry No.");
                TotalInvoicedQty += ItemLedgEntry2."Invoiced Quantity";
            until ItemApplnEntry.Next() = 0;
            if ItemLedgerEntry."Invoiced Quantity" > Abs(TotalInvoicedQty) then begin
                RentalShipmentHeader.Get(ItemLedgEntry2."Document No.");
                if ItemLedgerEntry."Item Tracking" = ItemLedgerEntry."Item Tracking"::None then
                    Error(Text032Lbl, ItemLedgerEntry."Item No.", RentalShipmentHeader."Order No.");
                Error(
                  Text031Lbl, ItemLedgerEntry."Item No.", ItemLedgerEntry."Lot No.", ItemLedgerEntry."Serial No.", RentalShipmentHeader."Order No.")
            end;
        end;
    end;

    local procedure TransReserveFromJobPlanningLine(FromJobContractEntryNo: Integer; ToRentalItemJnlLine: Record "TWE Rental Item Journal Line")
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        JobPlanningLine.SetCurrentKey("Job Contract Entry No.");
        JobPlanningLine.SetRange("Job Contract Entry No.", FromJobContractEntryNo);
        JobPlanningLine.FindFirst();

        if JobPlanningLine."Remaining Qty. (Base)" >= ToRentalItemJnlLine."Quantity (Base)" then
            JobPlanningLine."Remaining Qty. (Base)" := JobPlanningLine."Remaining Qty. (Base)" - ToRentalItemJnlLine."Quantity (Base)"
        else
            JobPlanningLine."Remaining Qty. (Base)" := 0;
        //JobPlanningLineReserve.TransferJobLineToItemJnlLine(JobPlanningLine, ToRentalItemJnlLine, ToRentalItemJnlLine."Quantity (Base)");
    end;

    procedure SetupTempSplitItemJnlLine(RentalItemJnlLine2: Record "TWE Rental Item Journal Line"; SignFactor: Integer; var NonDistrQuantity: Decimal; var NonDistrAmount: Decimal; var NonDistrAmountACY: Decimal; var NonDistrDiscountAmount: Decimal; Invoice: Boolean): Boolean
    var
        FloatingFactor: Decimal;
        PostItemJnlLine: Boolean;
    begin
        TempSplitRentalItemJnlLine."Quantity (Base)" := SignFactor * TempTrackingSpecification."Qty. to Handle (Base)";
        TempSplitRentalItemJnlLine.Quantity := SignFactor * TempTrackingSpecification."Qty. to Handle";
        if Invoice then begin
            TempSplitRentalItemJnlLine."Invoiced Quantity" := SignFactor * TempTrackingSpecification."Qty. to Invoice";
            TempSplitRentalItemJnlLine."Invoiced Qty. (Base)" := SignFactor * TempTrackingSpecification."Qty. to Invoice (Base)";
        end;

        if RentalItemJnlLine2."Output Quantity" <> 0 then begin
            TempSplitRentalItemJnlLine."Output Quantity (Base)" := TempSplitRentalItemJnlLine."Quantity (Base)";
            TempSplitRentalItemJnlLine."Output Quantity" := TempSplitRentalItemJnlLine.Quantity;
        end;

        if RentalItemJnlLine2."Phys. Inventory" then
            TempSplitRentalItemJnlLine."Qty. (Phys. Inventory)" := TempSplitRentalItemJnlLine."Qty. (Calculated)" + SignFactor * TempSplitRentalItemJnlLine."Quantity (Base)";

        OnAfterSetupTempSplitItemJnlLineSetQty(TempSplitRentalItemJnlLine, RentalItemJnlLine2, SignFactor, TempTrackingSpecification);

        FloatingFactor := TempSplitRentalItemJnlLine.Quantity / NonDistrQuantity;
        if FloatingFactor < 1 then begin
            TempSplitRentalItemJnlLine.Amount := Round(NonDistrAmount * FloatingFactor, GLSetup."Amount Rounding Precision");
            TempSplitRentalItemJnlLine."Amount (ACY)" := Round(NonDistrAmountACY * FloatingFactor, Currency."Amount Rounding Precision");
            TempSplitRentalItemJnlLine."Discount Amount" := Round(NonDistrDiscountAmount * FloatingFactor, GLSetup."Amount Rounding Precision");
            NonDistrAmount := NonDistrAmount - TempSplitRentalItemJnlLine.Amount;
            NonDistrAmountACY := NonDistrAmountACY - TempSplitRentalItemJnlLine."Amount (ACY)";
            NonDistrDiscountAmount := NonDistrDiscountAmount - TempSplitRentalItemJnlLine."Discount Amount";
            NonDistrQuantity := NonDistrQuantity - TempSplitRentalItemJnlLine.Quantity;
            TempSplitRentalItemJnlLine."Setup Time" := 0;
            TempSplitRentalItemJnlLine."Run Time" := 0;
            TempSplitRentalItemJnlLine."Stop Time" := 0;
            TempSplitRentalItemJnlLine."Setup Time (Base)" := 0;
            TempSplitRentalItemJnlLine."Run Time (Base)" := 0;
            TempSplitRentalItemJnlLine."Stop Time (Base)" := 0;
            TempSplitRentalItemJnlLine."Starting Time" := 0T;
            TempSplitRentalItemJnlLine."Ending Time" := 0T;
            TempSplitRentalItemJnlLine."Scrap Quantity" := 0;
            TempSplitRentalItemJnlLine."Scrap Quantity (Base)" := 0;
            TempSplitRentalItemJnlLine."Concurrent Capacity" := 0;
        end else begin // the last record
            TempSplitRentalItemJnlLine.Amount := NonDistrAmount;
            TempSplitRentalItemJnlLine."Amount (ACY)" := NonDistrAmountACY;
            TempSplitRentalItemJnlLine."Discount Amount" := NonDistrDiscountAmount;
        end;

        if Round(TempSplitRentalItemJnlLine."Unit Amount" * TempSplitRentalItemJnlLine.Quantity, GLSetup."Amount Rounding Precision") <> TempSplitRentalItemJnlLine.Amount then
            if (TempSplitRentalItemJnlLine."Unit Amount" = TempSplitRentalItemJnlLine."Unit Cost") and (TempSplitRentalItemJnlLine."Unit Cost" <> 0) then begin
                TempSplitRentalItemJnlLine."Unit Amount" := Round(TempSplitRentalItemJnlLine.Amount / TempSplitRentalItemJnlLine.Quantity, 0.00001);
                TempSplitRentalItemJnlLine."Unit Cost" := Round(TempSplitRentalItemJnlLine.Amount / TempSplitRentalItemJnlLine.Quantity, 0.00001);
                TempSplitRentalItemJnlLine."Unit Cost (ACY)" := Round(TempSplitRentalItemJnlLine."Amount (ACY)" / TempSplitRentalItemJnlLine.Quantity, 0.00001);
            end else
                TempSplitRentalItemJnlLine."Unit Amount" := Round(TempSplitRentalItemJnlLine.Amount / TempSplitRentalItemJnlLine.Quantity, 0.00001);

        TempSplitRentalItemJnlLine.CopyTrackingFromSpec(TempTrackingSpecification);
        TempSplitRentalItemJnlLine."Item Expiration Date" := TempTrackingSpecification."Expiration Date";
        TempSplitRentalItemJnlLine.CopyNewTrackingFromNewSpec(TempTrackingSpecification);
        TempSplitRentalItemJnlLine."New Item Expiration Date" := TempTrackingSpecification."New Expiration Date";

        PostItemJnlLine := not TempSplitRentalItemJnlLine.HasSameNewTracking() or (TempSplitRentalItemJnlLine."Item Expiration Date" <> TempSplitRentalItemJnlLine."New Item Expiration Date");

        TempSplitRentalItemJnlLine."Warranty Date" := TempTrackingSpecification."Warranty Date";

        TempSplitRentalItemJnlLine."Line No." := TempTrackingSpecification."Entry No.";

        if TempTrackingSpecification.Correction or TempSplitRentalItemJnlLine."Drop Shipment" or IsServUndoConsumption then
            TempSplitRentalItemJnlLine."Applies-to Entry" := TempTrackingSpecification."Item Ledger Entry No."
        else
            TempSplitRentalItemJnlLine."Applies-to Entry" := TempTrackingSpecification."Appl.-to Item Entry";
        TempSplitRentalItemJnlLine."Applies-from Entry" := TempTrackingSpecification."Appl.-from Item Entry";

        OnBeforeInsertSetupTempSplitItemJnlLine(TempTrackingSpecification, TempSplitRentalItemJnlLine, PostItemJnlLine, RentalItemJnlLine2);

        TempSplitRentalItemJnlLine.Insert();

        exit(PostItemJnlLine);
    end;

    local procedure ReservationExists(RentalItemJnlLine: Record "TWE Rental Item Journal Line"): Boolean
    var
        ReservEntry: Record "Reservation Entry";
        ProductionOrder: Record "Production Order";
    begin
        ReservEntry.SetRange("Source ID", RentalItemJnlLine."Order No.");
        if RentalItemJnlLine."Prod. Order Comp. Line No." <> 0 then
            ReservEntry.SetRange("Source Ref. No.", RentalItemJnlLine."Prod. Order Comp. Line No.");
        ReservEntry.SetRange("Source Type", DATABASE::"Prod. Order Component");
        ReservEntry.SetRange("Source Subtype", ProductionOrder.Status::Released);
        ReservEntry.SetRange("Source Batch Name", '');
        ReservEntry.SetRange("Source Prod. Order Line", RentalItemJnlLine."Order Line No.");
        ReservEntry.SetFilter("Qty. to Handle (Base)", '<>0');
        exit(not ReservEntry.IsEmpty());
    end;

    local procedure PostInvtBuffer(var ValueEntry: Record "Value Entry")
    begin
        if InventoryPostingToGL.BufferInvtPosting(ValueEntry) then
            InventoryPostingToGL.PostInvtPostBufPerEntry(ValueEntry);
    end;

    local procedure VerifyTouchedOnInventory()
    var
        ItemLedgEntryApplied: Record "Item Ledger Entry";
    begin
        TempTouchedItemLedgerEntries.FindSet();
        repeat
            ItemLedgEntryApplied.Get(TempTouchedItemLedgerEntries."Entry No.");
            ItemLedgEntryApplied.VerifyOnInventory(
                StrSubstNo(CannotUnapplyItemLedgEntryErr, ItemLedgEntryApplied."Item No.", ItemLedgEntryApplied."Entry No."));
        until TempTouchedItemLedgerEntries.Next() = 0;
    end;

    local procedure CheckIsCyclicalLoop(ItemLedgEntry: Record "Item Ledger Entry"; OldItemLedgEntry: Record "Item Ledger Entry"; var PrevAppliedItemLedgEntry: Record "Item Ledger Entry"; var AppliedQty: Decimal)
    var
        PrevProcessedProdOrder: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckIsCyclicalLoop(ItemLedgEntry, OldItemLedgEntry, PrevAppliedItemLedgEntry, AppliedQty, IsHandled);
        if IsHandled then
            exit;

        PrevProcessedProdOrder :=
          (ItemLedgEntry."Entry Type" = ItemLedgEntry."Entry Type"::Consumption) and
          (OldItemLedgEntry."Entry Type" = OldItemLedgEntry."Entry Type"::Output) and
          (ItemLedgEntry."Order Type" = ItemLedgEntry."Order Type"::Production) and
          EntriesInTheSameOrder(OldItemLedgEntry, PrevAppliedItemLedgEntry);

        if not PrevProcessedProdOrder then
            if AppliedQty <> 0 then
                if ItemLedgEntry.Positive then begin
                    if ItemApplnEntry.CheckIsCyclicalLoop(ItemLedgEntry, OldItemLedgEntry) then
                        AppliedQty := 0;
                end else
                    if ItemApplnEntry.CheckIsCyclicalLoop(OldItemLedgEntry, ItemLedgEntry) then
                        AppliedQty := 0;

        if AppliedQty <> 0 then
            PrevAppliedItemLedgEntry := OldItemLedgEntry;
    end;

    local procedure EntriesInTheSameOrder(OldItemLedgEntry: Record "Item Ledger Entry"; PrevAppliedItemLedgEntry: Record "Item Ledger Entry"): Boolean
    begin
        exit(
          (PrevAppliedItemLedgEntry."Order Type" = PrevAppliedItemLedgEntry."Order Type"::Production) and
          (OldItemLedgEntry."Order Type" = OldItemLedgEntry."Order Type"::Production) and
          (OldItemLedgEntry."Order No." = PrevAppliedItemLedgEntry."Order No.") and
          (OldItemLedgEntry."Order Line No." = PrevAppliedItemLedgEntry."Order Line No."));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAllowProdApplication(OldItemLedgerEntry: Record "Item Ledger Entry"; ItemLedgerEntry: Record "Item Ledger Entry"; var AllowApplication: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeApplyItemLedgEntry(var ItemLedgEntry: Record "Item Ledger Entry"; var OldItemLedgEntry: Record "Item Ledger Entry"; var ValueEntry: Record "Value Entry"; CausedByTransfer: Boolean; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeApplyItemLedgEntrySetFilters(var ToItemLedgEntry: Record "Item Ledger Entry"; FromItemLedgEntry: Record "Item Ledger Entry"; ItemTrackingCode: Record "Item Tracking Code"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckExpirationDate(var RentalItemJournalLine: Record "TWE Rental Item Journal Line"; var TrackingSpecification: Record "Tracking Specification"; SignFactor: Integer; CalcExpirationDate: Date; var ExpirationDateChecked: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckItemCorrection(ItemLedgerEntry: Record "Item Ledger Entry"; var RaiseError: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckItemTracking(RentalItemJournalLine: Record "TWE Rental Item Journal Line"; ItemTrackingSetup: Record "Item Tracking Setup"; var IsHandled: Boolean; var TempTrackingSpecification: Record "Tracking Specification" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckItemTrackingInformation(var RentalItemJnlLine2: Record "TWE Rental Item Journal Line"; var TrackingSpecification: Record "Tracking Specification"; var ItemTrackingSetup: Record "Item Tracking Setup"; var SignFactor: Decimal; var ItemTrackingCode: Record "Item Tracking Code")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAppliedEntriesToReadjust(ItemLedgEntry: Record "Item Ledger Entry"; var Readjust: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckItemTracking(RentalItemJournalLine: Record "TWE Rental Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckItemTrackingInformation(var RentalItemJnlLine2: Record "TWE Rental Item Journal Line"; var TrackingSpecification: Record "Tracking Specification"; ItemTrackingSetup: Record "Item Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateItemJnlLineFromEntry(var RentalItemJournalLine: Record "TWE Rental Item Journal Line"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertApplEntry(ItemLedgEntryNo: Integer; InboundItemEntry: Integer; OutboundItemEntry: Integer; TransferedFromEntryNo: Integer; PostingDate: Date; Quantity: Decimal; CostToApply: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertTransferEntry(var NewItemLedgerEntry: Record "Item Ledger Entry"; var OldItemLedgerEntry: Record "Item Ledger Entry"; var RentalItemJournalLine: Record "TWE Rental Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFlushOperation(var ProdOrder: Record "Production Order"; var ProdOrderLine: Record "Prod. Order Line"; var RentalItemJnlLine: Record "TWE Rental Item Journal Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetItem(var MainRentalItem: Record "TWE Main Rental Item"; ItemNo: Code[20]; Unconditionally: Boolean; var HasGotItem: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostFlushedConsump(var ProdOrderComp: Record "Prod. Order Component"; var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; OldRentalItemJnlLine: Record "TWE Rental Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostConsumption(var ProdOrderComp: Record "Prod. Order Component"; var RentalItemJnlLine: Record "TWE Rental Item Journal Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertPhysInvtLedgEntry(var PhysInventoryLedgerEntry: Record "Phys. Inventory Ledger Entry"; RentalItemJournalLine: Record "TWE Rental Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitItemLedgEntry(var NewItemLedgEntry: Record "Item Ledger Entry"; RentalItemJournalLine: Record "TWE Rental Item Journal Line"; var ItemLedgEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertItemLedgEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; RentalItemJournalLine: Record "TWE Rental Item Journal Line"; var ItemLedgEntryNo: Integer; var ValueEntryNo: Integer; var ItemApplnEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertItemLedgEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; RentalItemJournalLine: Record "TWE Rental Item Journal Line"; TransferItem: Boolean; OldItemLedgEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertValueEntry(var ValueEntry: Record "Value Entry"; RentalItemJournalLine: Record "TWE Rental Item Journal Line"; var ItemLedgerEntry: Record "Item Ledger Entry"; var ValueEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertValueEntry(var ValueEntry: Record "Value Entry"; RentalItemJournalLine: Record "TWE Rental Item Journal Line"; var ItemLedgerEntry: Record "Item Ledger Entry"; var ValueEntryNo: Integer; var InventoryPostingToGL: Codeunit "Inventory Posting To G/L"; CalledFromAdjustment: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitValueEntry(var ValueEntry: Record "Value Entry"; RentalItemJournalLine: Record "TWE Rental Item Journal Line"; var ValueEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertCapLedgEntry(var CapLedgEntry: Record "Capacity Ledger Entry"; RentalItemJournalLine: Record "TWE Rental Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertCapLedgEntry(var CapLedgEntry: Record "Capacity Ledger Entry"; RentalItemJournalLine: Record "TWE Rental Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertCapValueEntry(var ValueEntry: Record "Value Entry"; RentalItemJnlLine: Record "TWE Rental Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertCapValueEntry(var ValueEntry: Record "Value Entry"; RentalItemJnlLine: Record "TWE Rental Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertCorrItemLedgEntry(var NewItemLedgerEntry: Record "Item Ledger Entry"; var OldItemLedgerEntry: Record "Item Ledger Entry"; var RentalItemJournalLine: Record "TWE Rental Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertCorrItemLedgEntry(var NewItemLedgerEntry: Record "Item Ledger Entry"; var RentalItemJournalLine: Record "TWE Rental Item Journal Line"; var OldItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertCorrValueEntry(var NewValueEntry: Record "Value Entry"; OldValueEntry: Record "Value Entry"; var RentalItemJournalLine: Record "TWE Rental Item Journal Line"; Sign: Integer; CalledFromAdjustment: Boolean; var ItemLedgerEntry: Record "Item Ledger Entry"; var ValueEntryNo: Integer; var InventoryPostingToGL: Codeunit "Inventory Posting To G/L")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertCorrValueEntry(var NewValueEntry: Record "Value Entry"; var RentalItemJournalLine: Record "TWE Rental Item Journal Line"; var ItemLedgerEntry: Record "Item Ledger Entry"; var ValueEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertConsumpEntry(var ProdOrderComponent: Record "Prod. Order Component"; QtyBase: Decimal; var ModifyProdOrderComp: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterItemApplnEntryInsert(var ItemApplicationEntry: Record "Item Application Entry"; GlobalItemLedgerEntry: Record "Item Ledger Entry"; OldItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeItemApplnEntryInsert(var ItemApplicationEntry: Record "Item Application Entry"; GlobalItemLedgerEntry: Record "Item Ledger Entry"; OldItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeNextOperationExist(var ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostItem(var RentalItemJournalLine: Record "TWE Rental Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostItemJnlLine(var RentalItemJournalLine: Record "TWE Rental Item Journal Line"; CalledFromAdjustment: Boolean; CalledFromInvtPutawayPick: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostItemJnlLine(var RentalItemJournalLine: Record "TWE Rental Item Journal Line"; ItemLedgerEntry: Record "Item Ledger Entry"; var ValueEntryNo: Integer; var InventoryPostingToGL: Codeunit "Inventory Posting To G/L"; CalledFromAdjustment: Boolean; CalledFromInvtPutawayPick: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostOutput(var ItemLedgerEntry: Record "Item Ledger Entry"; var ProdOrderLine: Record "Prod. Order Line"; var RentalItemJournalLine: Record "TWE Rental Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostOutputOnBeforeProdOrderRtngLineModify(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var ProdOrderLine: Record "Prod. Order Line"; var RentalItemJournalLine: Record "TWE Rental Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckPostingCostToGL(var PostCostToGL: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertSetupTempSplitItemJnlLine(var TempTrackingSpecification: Record "Tracking Specification" temporary; var TempRentalItemJournalLine: Record "TWE Rental Item Journal Line" temporary; var PostItemJnlLine: Boolean; var RentalItemJournalLine2: Record "TWE Rental Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFlushOperation(var ProdOrder: Record "Production Order"; var ProdOrderLine: Record "Prod. Order Line"; var RentalItemJnlLine: Record "TWE Rental Item Journal Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostFlushedConsumpItemJnlLine(var RentalItemJournalLine: Record "TWE Rental Item Journal Line")
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnAfterItemValuePosting(var ValueEntry: Record "Value Entry"; var RentalItemJournalLine: Record "TWE Rental Item Journal Line"; var MainRentalItem: Record "TWE Main Rental Item")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetupSplitJnlLineOnBeforeSplitTempLines(var TempSplitRentalItemJournalLine: Record "TWE Rental Item Journal Line" temporary; var TempTrackingSpecification: Record "Tracking Specification" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcPurchCorrShares(var ValueEntry: Record "Value Entry"; var RentalItemJournalLine: Record "TWE Rental Item Journal Line"; var OverheadAmount: Decimal; var OverheadAmountACY: Decimal; var VarianceAmount: Decimal; var VarianceAmountACY: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcPosShares(var RentalItemJournalLine: Record "TWE Rental Item Journal Line"; var DirCost: Decimal; var OvhdCost: Decimal; var PurchVar: Decimal; var DirCostACY: Decimal; var OvhdCostACY: Decimal; var PurchVarACY: Decimal; var CalcUnitCost: Boolean; CalcPurchVar: Boolean; Expected: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertOHValueEntry(var ValueEntry: Record "Value Entry"; var MainRentalItem: Record "TWE Main Rental Item"; var OverheadAmount: Decimal; var OverheadAmountACY: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetupTempSplitItemJnlLineSetQty(var TempSplitRentalItemJnlLine: Record "TWE Rental Item Journal Line" temporary; RentalItemJournalLine: Record "TWE Rental Item Journal Line"; SignFactor: Integer; var TempTrackingSpecification: Record "Tracking Specification" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateAdjmtProp(var ValueEntry: Record "Value Entry"; OriginalPostingDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateUnitCost(ValueEntry: Record "Value Entry"; LastDirectCost: Decimal; RentalItemJournalLine: Record "TWE Rental Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcExpirationDate(var RentalItemJnlLine: Record "TWE Rental Item Journal Line"; var ExpirationDate: Date; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCallFlushOperation(var RentalItemJnlLine: Record "TWE Rental Item Journal Line"; var ShouldFlushOperation: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckSerialNo(RentalItemJournalLine: Record "TWE Rental Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckItemTrackingIsEmpty(RentalItemJournalLine: Record "TWE Rental Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckIsCyclicalLoop(ItemLedgEntry: Record "Item Ledger Entry"; OldItemLedgEntry: Record "Item Ledger Entry"; var PrevAppliedItemLedgEntry: Record "Item Ledger Entry"; var AppliedQty: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostFlushedConsump(ProdOrder: Record "Production Order"; ProdOrderLine: Record "Prod. Order Line"; ProdOrderComp: Record "Prod. Order Component"; ProdOrderRoutingLine: Record "Prod. Order Routing Line"; OldRentalItemJnlLine: Record "TWE Rental Item Journal Line"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitValueEntry(var ValueEntry: Record "Value Entry"; var ValueEntryNo: Integer; var RentalItemJournalLine: Record "TWE Rental Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertOHValueEntry(var ValueEntry: Record "Value Entry"; var MainRentalItem: Record "TWE Main Rental Item"; var OverheadAmount: Decimal; var OverheadAmountACY: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertVarValueEntry(var ValueEntry: Record "Value Entry"; var MainRentalItem: Record "TWE Main Rental Item"; var VarianceAmount: Decimal; var VarianceAmountACY: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertTempSplitItemJnlLine(RentalItemJournalLine: Record "TWE Rental Item Journal Line"; IsServUndoConsumption: Boolean; PostponeReservationHandling: Boolean; var TempSplitRentalItemJnlLine: Record "TWE Rental Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMoveApplication(var ItemLedgEntry: Record "Item Ledger Entry"; var OldItemLedgEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOldItemLedgEntryModify(var OldItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostLineByEntryType(var RentalItemJournalLine: Record "TWE Rental Item Journal Line"; CalledFromAdjustment: Boolean; CalledFromInvtPutawayPick: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeProdOrderCompModify(var ProdOrderComponent: Record "Prod. Order Component"; RentalItemJournalLine: Record "TWE Rental Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeProdOrderLineModify(var ProdOrderLine: Record "Prod. Order Line"; RentalItemJournalLine: Record "TWE Rental Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRoundAmtValueEntry(var ValueEntry: Record "Value Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRetrieveCostPerUnit(RentalItemJournalLine: Record "TWE Rental Item Journal Line"; SKU: Record "Stockkeeping Unit"; SKUExists: Boolean; var UnitCost: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnBeforeRunWithCheck(var RentalItemJournalLine: Record "TWE Rental Item Journal Line"; CalledFromAdjustment: Boolean; CalledFromInvtPutawayPick: Boolean; CalledFromApplicationWorksheet: Boolean; PostponeReservationHandling: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTempItemEntryRelationInsert(var TempItemEntryRelation: Record "Item Entry Relation" temporary; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestFirstApplyItemLedgEntry(var OldItemLedgerEntry: Record "Item Ledger Entry"; ItemLedgerEntry: Record "Item Ledger Entry"; RentalItemJournalLine: Record "TWE Rental Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTrackingSpecificationMissingErr(RentalItemJournalLine: Record "TWE Rental Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetOrderAdjmtProperties(ItemLedgEntryType: Option; OrderType: Option; OrderNo: Code[20]; OrderLineNo: Integer; OriginalPostingDate: Date; ValuationDate: Date; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetupSplitJnlLine(var RentalItemJnlLine2: Record "TWE Rental Item Journal Line"; TrackingSpecExists: Boolean; var TempTrackingSpecification: Record "Tracking Specification" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVerifyInvoicedQty(ItemLedgerEntry: Record "Item Ledger Entry"; var IsHandled: Boolean; ValueEntry: Record "Value Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUndoQuantityPosting(var RentalItemJournalLine: Record "TWE Rental Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; var RentalItemJournalLine: Record "TWE Rental Item Journal Line"; ReTrack: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateUnitCost(var ValueEntry: Record "Value Entry"; var IsHandled: Boolean; RentalItemJournalLine: Record "TWE Rental Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyItemLedgEntryOnBeforeCloseReservEntry(var OldItemLedgEntry: Record "Item Ledger Entry"; RentalItemJournalLine: Record "TWE Rental Item Journal Line"; var ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterApplyItemLedgEntry(var GlobalItemLedgerEntry: Record "Item Ledger Entry"; var OldItemLedgerEntry: Record "Item Ledger Entry"; RentalItemJournalLine: Record "TWE Rental Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterApplyItemLedgEntrySetFilters(var ItemLedgerEntry2: Record "Item Ledger Entry"; ItemLedgerEntry: Record "Item Ledger Entry"; RentalItemJournalLine: Record "TWE Rental Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterApplyItemLedgEntryOnBeforeCalcAppliedQty(OldItemLedgerEntry: Record "Item Ledger Entry"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetGLSetup(var GeneralLedgerSetup: Record "General Ledger Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMoveValEntryDimToValEntryDim(var ToValueEntry: Record "Value Entry"; FromValueEntry: Record "Value Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostItem(var RentalItemJournalLine: Record "TWE Rental Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostSplitJnlLine(var RentalItemJournalLine: Record "TWE Rental Item Journal Line"; var TempTrackingSpecification: Record "Tracking Specification" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPrepareItem(var RentalItemJnlLineToPost: Record "TWE Rental Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUndoQuantityPosting(var ItemLedgerEntry: Record "Item Ledger Entry"; RentalItemJournalLine: Record "TWE Rental Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ReTrack: Boolean; var RentalItemJournalLine: Record "TWE Rental Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertConsumpEntry(var WarehouseJournalLine: Record "Warehouse Journal Line"; ProdOrderComponent: Record "Prod. Order Component"; QtyBase: Decimal; PostWhseJnlLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyCapNeedOnAfterSetFilters(var ProdOrderCapNeed: Record "Prod. Order Capacity Need"; RentalItemJnlLine: Record "TWE Rental Item Journal Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyItemLedgEntryOnAfterCalcAppliedQty(OldItemLedgEntry: Record "Item Ledger Entry"; ItemLedgEntry: Record "Item Ledger Entry"; var AppliedQty: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyItemLedgEntryOnBeforeCheckApplyEntry(var OldItemLedgEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyItemLedgEntryOnBeforeInsertApplEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; RentalItemJournalLine: Record "TWE Rental Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyItemLedgEntryOnBeforeOldItemLedgEntryModify(var ItemLedgerEntry: Record "Item Ledger Entry"; var OldItemLedgerEntry: Record "Item Ledger Entry"; RentalItemJournalLine: Record "TWE Rental Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCollectTrackingSpecification(var TempTrackingSpecification: Record "Tracking Specification" temporary; var TargetTrackingSpecification: Record "Tracking Specification" temporary; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcExpectedCostOnBeforeFindValueEntry(var ValueEntry: Record "Value Entry"; ItemLedgEntryNo: Integer; InvoicedQty: Decimal; Quantity: Decimal; var ExpectedCost: Decimal; var ExpectedCostACY: Decimal; var ExpectedSalesAmt: Decimal; var ExpectedPurchAmt: Decimal; CalcReminder: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcILEExpectedAmountOnBeforeCalcCostAmounts(var OldValueEntry2: Record "Value Entry"; var OldValueEntry: Record "Value Entry"; ItemLedgEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCorrectOutputValuationDateOnBeforeCheckProdOrder(ItemLedgerEntry: Record "Item Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetValuationDateOnBeforeFindOldValueEntry(var OldValueEntry: Record "Value Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitValueEntryOnAfterAssignFields(var ValueEntry: Record "Value Entry"; ItemLedgEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertPostValueEntryToGLOnAfterTransferFields(var PostValueEntryToGL: Record "Post Value Entry to G/L"; ValueEntry: Record "Value Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertTransferEntryOnTransferValues(var NewItemLedgerEntry: Record "Item Ledger Entry"; OldItemLedgerEntry: Record "Item Ledger Entry"; ItemLedgerEntry: Record "Item Ledger Entry"; RentalItemJournalLine: Record "TWE Rental Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertCapValueEntryOnAfterUpdateCostAmounts(var ValueEntry: Record "Value Entry"; var RentalItemJournalLine: Record "TWE Rental Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertConsumpEntryOnBeforePostItem(var RentalItemJournalLine: Record "TWE Rental Item Journal Line"; ProdOrderComponent: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnItemQtyPostingOnBeforeApplyItemLedgEntry(var RentalItemJournalLine: Record "TWE Rental Item Journal Line"; var ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnItemValuePostingOnAfterInsertValueEntry(var ValueEntry: Record "Value Entry"; var ItemLedgerEntry: Record "Item Ledger Entry"; var ValueEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertItemLedgEntryOnBeforeReservationError(var RentalItemJournalLine: Record "TWE Rental Item Journal Line"; var ItemLedgerEntry: Record "Item Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertItemLedgEntryOnBeforeSNQtyCheck(RentalItemJournalLine: Record "TWE Rental Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValuateAppliedAvgEntryOnAfterSetCostPerUnit(var ValueEntry: Record "Value Entry"; RentalItemJournalLine: Record "TWE Rental Item Journal Line"; InventorySetup: Record "Inventory Setup"; SKU: Record "Stockkeeping Unit"; SKUExists: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValuateAppliedAvgEntryOnAfterUpdateCostAmounts(var ValueEntry: Record "Value Entry"; var RentalItemJournalLine: Record "TWE Rental Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostFlushedConsumpOnAfterCalcQtyToPost(ProductionOrder: Record "Production Order"; ProdOrderLine: Record "Prod. Order Line"; ProdOrderComponent: Record "Prod. Order Component"; ActOutputQtyBase: Decimal; var QtyToPost: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostConsumptionOnAfterInsertEntry(var ProdOrderComponent: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostConsumptionOnBeforeFindSetProdOrderComp(var ProdOrderComponent: Record "Prod. Order Component"; var RentalItemJournalLine: Record "TWE Rental Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemOnBeforeUpdateUnitCost(var RentalItemJnlLine: Record "TWE Rental Item Journal Line"; GlobalItemLedgEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostOutputOnAfterInsertCapLedgEntry(RentalItemJournalLine: Record "TWE Rental Item Journal Line"; var SkipPost: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostOutputOnAfterInsertCostValueEntries(RentalItemJournalLine: Record "TWE Rental Item Journal Line"; var CapLedgEntry: Record "Capacity Ledger Entry"; CalledFromAdjustment: Boolean; PostToGL: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostOutputOnAfterUpdateAmounts(var RentalItemJournalLine: Record "TWE Rental Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostOutputOnAfterUpdateProdOrderLine(var RentalItemJournalLine: Record "TWE Rental Item Journal Line"; var WhseJnlLine: Record "Warehouse Journal Line"; var GlobalItemLedgEntry: Record "Item Ledger Entry");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostOutputOnBeforeCreateWhseJnlLine(var RentalItemJournalLine: Record "TWE Rental Item Journal Line"; var PostWhseJnlLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostSplitJnlLineOnBeforeSplitJnlLine(var RentalItemJournalLine: Record "TWE Rental Item Journal Line"; var RentalItemJournalLineToPost: Record "TWE Rental Item Journal Line"; var PostItemJournalLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReApplyOnBeforeStartApply(var ItemLedgerEntry: Record "Item Ledger Entry"; var ItemLedgerEntry2: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetOrderAdjmtPropertiesOnBeforeSetCostIsAdjusted(var InvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; var ModifyOrderAdjmt: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetOrderAdjmtPropertiesOnBeforeSetAllowOnlineAdjustment(var InvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; var ModifyOrderAdjmt: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetupSplitJnlLineOnBeforeReallocateTrkgSpecification(var ItemTrackingCode: Record "Item Tracking Code"; var TempTrackingSpecification: Record "Tracking Specification" temporary; var RentalItemJnlLine: Record "TWE Rental Item Journal Line"; var SignFactor: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSplitItemJnlLineOnBeforeTracking(
        var RentalItemJnlLine2: Record "TWE Rental Item Journal Line"; var PostItemJnlLine: Boolean; var TempTrackingSpecification: Record "Tracking Specification" temporary;
        var GlobalItemLedgEntry: Record "Item Ledger Entry"; var TempItemEntryRelation: Record "Item Entry Relation" temporary;
        var PostponeReservationHandling: Boolean; var SignFactor: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTestFirstApplyItemLedgEntryOnAfterTestFields(ItemLedgerEntry: Record "Item Ledger Entry"; OldItemLedgerEntry: Record "Item Ledger Entry"; RentalItemJournalLine: Record "TWE Rental Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTouchItemEntryCostOnAfterAfterSetAdjmtProp(var ItemLedgerEntry: Record "Item Ledger Entry"; IsAdjustment: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUnApplyOnBeforeUpdateItemLedgerEntries(var ItemLedgerEntry1: Record "Item Ledger Entry"; var ItemLedgerEntry2: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUnApplyOnBeforeItemApplnEntryDelete(var ItemApplicationEntry: Record "Item Application Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateUnitCostOnBeforeCalculateLastDirectCost(var TotalAmount: Decimal; RentalItemJournalLine: Record "TWE Rental Item Journal Line"; ValueEntry: Record "Value Entry"; MainRentalItem: Record "TWE Main Rental Item"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostInventoryToGL(var ValueEntry: Record "Value Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostInventoryToGL(var ValueEntry: Record "Value Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostSplitJnlLineOnAfterCode(var RentalItemJournalLine: Record "TWE Rental Item Journal Line"; var RentalItemJournalLineToPost: Record "TWE Rental Item Journal Line"; var PostItemJournalLine: Boolean; var TempTrackingSpecification: Record "Tracking Specification" temporary)
    begin
    end;

    local procedure PrepareItem(var RentalItemJnlLineToPost: Record "TWE Rental Item Journal Line")
    begin
        RentalItemJnlLine.Copy(RentalItemJnlLineToPost);

        GetGLSetup;
        GetInvtSetup;
        CheckItem(RentalItemJnlLineToPost."Item No.");

        OnAfterPrepareItem(RentalItemJnlLineToPost);
    end;

    procedure SetSkipApplicationCheck(NewValue: Boolean)
    begin
        SkipApplicationCheck := NewValue;
    end;

    procedure LogApply(ApplyItemLedgEntry: Record "Item Ledger Entry"; AppliedItemLedgEntry: Record "Item Ledger Entry")
    var
        ItemApplnEntry: Record "Item Application Entry";
    begin
        ItemApplnEntry.Init();
        if AppliedItemLedgEntry.Quantity > 0 then begin
            ItemApplnEntry."Item Ledger Entry No." := ApplyItemLedgEntry."Entry No.";
            ItemApplnEntry."Inbound Item Entry No." := AppliedItemLedgEntry."Entry No.";
            ItemApplnEntry."Outbound Item Entry No." := ApplyItemLedgEntry."Entry No.";
        end else begin
            ItemApplnEntry."Item Ledger Entry No." := AppliedItemLedgEntry."Entry No.";
            ItemApplnEntry."Inbound Item Entry No." := ApplyItemLedgEntry."Entry No.";
            ItemApplnEntry."Outbound Item Entry No." := AppliedItemLedgEntry."Entry No.";
        end;
        AddToApplicationLog(ItemApplnEntry, true);
    end;

    procedure LogUnapply(ItemApplnEntry: Record "Item Application Entry")
    begin
        AddToApplicationLog(ItemApplnEntry, false);
    end;

    local procedure AddToApplicationLog(ItemApplnEntry: Record "Item Application Entry"; IsApplication: Boolean)
    begin
        if TempItemApplnEntryHistory.FindLast() then;
        TempItemApplnEntryHistory."Primary Entry No." += 1;

        TempItemApplnEntryHistory."Item Ledger Entry No." := ItemApplnEntry."Item Ledger Entry No.";
        TempItemApplnEntryHistory."Inbound Item Entry No." := ItemApplnEntry."Inbound Item Entry No.";
        TempItemApplnEntryHistory."Outbound Item Entry No." := ItemApplnEntry."Outbound Item Entry No.";

        TempItemApplnEntryHistory."Cost Application" := IsApplication;
        TempItemApplnEntryHistory.Insert();
    end;

    procedure ClearApplicationLog()
    begin
        TempItemApplnEntryHistory.DeleteAll();
    end;

    procedure UndoApplications()
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        ItemApplnEntry: Record "Item Application Entry";
    begin
        TempItemApplnEntryHistory.Ascending(false);
        if TempItemApplnEntryHistory.FindSet() then
            repeat
                if TempItemApplnEntryHistory."Cost Application" then begin
                    ItemApplnEntry.SetRange("Inbound Item Entry No.", TempItemApplnEntryHistory."Inbound Item Entry No.");
                    ItemApplnEntry.SetRange("Outbound Item Entry No.", TempItemApplnEntryHistory."Outbound Item Entry No.");
                    ItemApplnEntry.FindFirst();
                    UnApply(ItemApplnEntry);
                end else begin
                    ItemLedgEntry.Get(TempItemApplnEntryHistory."Item Ledger Entry No.");
                    SetSkipApplicationCheck(true);
                    ReApply(ItemLedgEntry, TempItemApplnEntryHistory."Inbound Item Entry No.");
                end;
            until TempItemApplnEntryHistory.Next() = 0;
        ClearApplicationLog;
        TempItemApplnEntryHistory.Ascending(true);
    end;

    procedure ApplicationLogIsEmpty(): Boolean
    begin
        exit(TempItemApplnEntryHistory.IsEmpty);
    end;

    local procedure AppliedEntriesToReadjust(ItemLedgEntry: Record "Item Ledger Entry") Readjust: Boolean
    begin
        Readjust := ItemLedgEntry."Entry Type" in [ItemLedgEntry."Entry Type"::Output, ItemLedgEntry."Entry Type"::"Assembly Output"];

        OnAfterAppliedEntriesToReadjust(ItemLedgEntry, Readjust);
    end;

    local procedure GetTextStringWithLineNo(BasicTextString: Text; ItemNo: Code[20]; LineNo: Integer): Text
    begin
        if LineNo = 0 then
            exit(StrSubstNo(BasicTextString, ItemNo));
        exit(StrSubstNo(BasicTextString, ItemNo) + StrSubstNo(LineNoTxt, LineNo));
    end;

    procedure SetCalledFromApplicationWorksheet(IsCalledFromApplicationWorksheet: Boolean)
    begin
        CalledFromApplicationWorksheet := IsCalledFromApplicationWorksheet;
    end;

    local procedure SaveTouchedEntry(ItemLedgerEntryNo: Integer; IsInbound: Boolean)
    var
        ItemApplicationEntryHistory: Record "Item Application Entry History";
        NextEntryNo: Integer;
    begin
        if not CalledFromApplicationWorksheet then
            exit;

        NextEntryNo := ItemApplicationEntryHistory.GetLastEntryNo() + 1;

        ItemApplicationEntryHistory.Init();
        ItemApplicationEntryHistory."Primary Entry No." := NextEntryNo;
        ItemApplicationEntryHistory."Entry No." := 0;
        ItemApplicationEntryHistory."Item Ledger Entry No." := ItemLedgerEntryNo;
        if IsInbound then
            ItemApplicationEntryHistory."Inbound Item Entry No." := ItemLedgerEntryNo
        else
            ItemApplicationEntryHistory."Outbound Item Entry No." := ItemLedgerEntryNo;
        ItemApplicationEntryHistory."Creation Date" := CurrentDateTime;
        ItemApplicationEntryHistory."Created By User" := UserId;
        ItemApplicationEntryHistory.Insert();
    end;

    procedure RestoreTouchedEntries(var TempMainRentalItem: Record "TWE Main Rental Item" temporary)
    var
        ItemApplicationEntryHistory: Record "Item Application Entry History";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemApplicationEntryHistory.SetRange("Entry No.", 0);
        ItemApplicationEntryHistory.SetRange("Created By User", UpperCase(UserId));
        if ItemApplicationEntryHistory.FindSet() then
            repeat
                TouchEntry(ItemApplicationEntryHistory."Item Ledger Entry No.");

                ItemLedgerEntry.Get(ItemApplicationEntryHistory."Item Ledger Entry No.");
                TempMainRentalItem."No." := ItemLedgerEntry."Item No.";
                if TempMainRentalItem.Insert() then;
            until ItemApplicationEntryHistory.Next() = 0;
    end;

    local procedure DeleteTouchedEntries()
    var
        ItemApplicationEntryHistory: Record "Item Application Entry History";
    begin
        if not CalledFromApplicationWorksheet then
            exit;

        ItemApplicationEntryHistory.SetRange("Entry No.", 0);
        ItemApplicationEntryHistory.SetRange("Created By User", UpperCase(UserId));
        ItemApplicationEntryHistory.DeleteAll();
    end;

    local procedure VerifyItemJnlLineAsembleToOrder(var RentalItemJournalLine: Record "TWE Rental Item Journal Line")
    begin
        RentalItemJournalLine.TestField("Applies-to Entry");

        RentalItemJournalLine.CalcFields("Reserved Qty. (Base)");
        RentalItemJournalLine.TestField("Reserved Qty. (Base)");
    end;

    local procedure VerifyItemJnlLineApplication(var RentalItemJournalLine: Record "TWE Rental Item Journal Line"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
        if RentalItemJournalLine."Applies-to Entry" = 0 then
            exit;

        RentalItemJournalLine.CalcFields("Reserved Qty. (Base)");
        if RentalItemJournalLine."Reserved Qty. (Base)" <> 0 then
            ItemLedgerEntry.FieldError("Applies-to Entry", Text990Lbl);
    end;

    local procedure GetCombinedDimSetID(DimSetID1: Integer; DimSetID2: Integer): Integer
    var
        DimMgt: Codeunit DimensionManagement;
        DummyGlobalDimCode: array[2] of Code[20];
        DimID: array[10] of Integer;
    begin
        DimID[1] := DimSetID1;
        DimID[2] := DimSetID2;
        exit(DimMgt.GetCombinedDimensionSetID(DimID, DummyGlobalDimCode[1], DummyGlobalDimCode[2]));
    end;

    local procedure CalcILEExpectedAmount(var OldValueEntry: Record "Value Entry"; ItemLedgerEntryNo: Integer)
    var
        OldValueEntry2: Record "Value Entry";
    begin
        OldValueEntry.FindFirstValueEntryByItemLedgerEntryNo(ItemLedgerEntryNo);
        OldValueEntry2.Copy(OldValueEntry);
        OldValueEntry2.SetFilter("Entry No.", '<>%1', OldValueEntry."Entry No.");
        OnCalcILEExpectedAmountOnBeforeCalcCostAmounts(OldValueEntry2, OldValueEntry, ItemLedgEntryNo);
        OldValueEntry2.CalcSums("Cost Amount (Expected)", "Cost Amount (Expected) (ACY)");
        OldValueEntry."Cost Amount (Expected)" += OldValueEntry2."Cost Amount (Expected)";
        OldValueEntry."Cost Amount (Expected) (ACY)" += OldValueEntry2."Cost Amount (Expected) (ACY)";
    end;

    local procedure FindOpenOutputEntryNoToApply(RentalItemJournalLine: Record "TWE Rental Item Journal Line"): Integer
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        if not RentalItemJournalLine.TrackingExists() then
            exit(0);

        ItemLedgerEntry.SetCurrentKey("Order Type", "Order No.", "Order Line No.", "Entry Type", "Prod. Order Comp. Line No.");
        ItemLedgerEntry.SetRange("Order Type", ItemLedgerEntry."Order Type"::Production);
        ItemLedgerEntry.SetRange("Order No.", RentalItemJournalLine."Order No.");
        ItemLedgerEntry.SetRange("Order Line No.", RentalItemJournalLine."Order Line No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Output);
        ItemLedgerEntry.SetRange("Prod. Order Comp. Line No.", 0);
        ItemLedgerEntry.SetRange("Item No.", RentalItemJournalLine."Item No.");
        ItemLedgerEntry.SetRange("Location Code", RentalItemJournalLine."Location Code");
        //SetTrackingFilterFromItemJournalLine(RentalItemJournalLine);
        ItemLedgerEntry.SetRange(Positive, true);
        ItemLedgerEntry.SetRange(Open, true);
        ItemLedgerEntry.SetFilter("Remaining Quantity", '>=%1', -RentalItemJournalLine."Output Quantity (Base)");
        if not ItemLedgerEntry.IsEmpty() then
            if ItemLedgerEntry.Count() = 1 then begin
                ItemLedgerEntry.FindFirst();
                exit(ItemLedgerEntry."Entry No.");
            end;

        exit(0);
    end;

    local procedure ExpectedCostPosted(ValueEntry: Record "Value Entry"): Boolean
    var
        PostedExpCostValueEntry: Record "Value Entry";
    begin
        if not ValueEntry.Adjustment or (ValueEntry."Applies-to Entry" = 0) then
            exit(false);
        PostedExpCostValueEntry.SetRange("Item Ledger Entry No.", ValueEntry."Item Ledger Entry No.");
        PostedExpCostValueEntry.SetRange("Applies-to Entry", ValueEntry."Applies-to Entry");
        PostedExpCostValueEntry.SetRange("Expected Cost", true);
        exit(not PostedExpCostValueEntry.IsEmpty);
    end;

    procedure SetSkipSerialNoQtyValidation(NewSkipSerialNoQtyValidation: Boolean)
    begin
        SkipSerialNoQtyValidation := NewSkipSerialNoQtyValidation;
    end;
}

