/// <summary>
/// Codeunit TWE Rent. Item Jnl.-Check Line (ID 50064).
/// </summary>
codeunit 50064 "TWE Rent. Item Jnl.-Check Line"
{
    TableNo = "TWE Rental Item Journal Line";

    trigger OnRun()
    begin
        RunCheck(Rec);
    end;

    var
        Location: Record Location;
        InvtSetup: Record "Inventory Setup";
        GLSetup: Record "General Ledger Setup";
        ItemLedgEntry: Record "Item Ledger Entry";
        RentalItemJnlLine2: Record "TWE Rental Item Journal Line";
        RentalItemJnlLine3: Record "TWE Rental Item Journal Line";
        ProdOrderLine: Record "Prod. Order Line";
        DimMgt: Codeunit DimensionManagement;
        CalledFromInvtPutawayPick: Boolean;
        CalledFromAdjustment: Boolean;
        UseInTransitLocationErr: Label 'You can use In-Transit location %1 for transfer orders only.', Comment = '%1 = Location Code';
        Text000Lbl: Label 'cannot be a closing date';
        Text003Lbl: Label 'must not be negative when %1 is %2', Comment = '%1 = FieldCaption Entry Type,%2 = "Entry Type"';
        Text004Lbl: Label 'must have the same value as %1', Comment = '%1 = FieldCaption Quantity';
        Text005Lbl: Label 'must be %1 or %2 when %3 is %4', Comment = '%1 = "Entry Type", %2 = "Entry Type", %3 = FieldCaption "Phys. Inventory",%4 = Boolean)';
        Text006Lbl: Label 'must equal %1 - %2 when %3 is %4 and %5 is %6', Comment = '%1 = FieldCaption "Qty. (Phys. Inventory)", %2 = FieldCaption "Qty. (Calculated),%3 = FieldCaption "Entry Type",%4 = "Entry Type",%5 = FieldCaption "Phys. Inventory",%6 = Boolean';
        Text007Lbl: Label 'You cannot post these lines because you have not entered a quantity on one or more of the lines. ';
        Text012Lbl: Label 'Warehouse handling is required for %1 = %2, %3 = %4, %5 = %6.', Comment = '%1 = FieldCaption "Entry Type",%2 = "Entry Type",%3 = FieldCaption "Order No.",%4 = "Order No.",%5 = FieldCaption "Order Line No.",%6 = "Order Line No."';
        DimCombBlockedErr: Label 'The combination of dimensions used in item journal line %1, %2, %3 is blocked. %4.', Comment = '%1 = Journal Template Name; %2 = Journal Batch Name; %3 = Line No., %4 = Dim Com. Text';
        DimCausedErr: Label 'A dimension used in item journal line %1, %2, %3 has caused an error. %4.', Comment = '%1 = Journal Template Name; %2 = Journal Batch Name; %3 = Line No., %4 = GetDimValuePostingErr';
        Text011Lbl: Label '%1 must not be equal to %2', Comment = '%1 = FieldCaption "Applies-to Entry",%2 = FieldCaption "Applies-from Entry"';

    procedure RunCheck(var RentalItemJnlLine: Record "TWE Rental Item Journal Line")
    var
        WorkCenter: Record "Work Center";
        Item: Record Item;
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        IsHandled: Boolean;
    begin
        GLSetup.Get();
        InvtSetup.Get();


        if RentalItemJnlLine.EmptyLine() then begin
            if not RentalItemJnlLine.IsValueEntryForDeletedItem() then
                exit;
        end else
            if not RentalItemJnlLine.OnlyStopTime() then
                RentalItemJnlLine.TestField("Item No.");

        if Item.Get(RentalItemJnlLine."Item No.") then
            Item.TestField("Base Unit of Measure");

        IsHandled := false;
        OnAfterGetItem(Item, RentalItemJnlLine, IsHandled);
        if IsHandled then
            exit;

        RentalItemJnlLine.TestField("Document No.");
        RentalItemJnlLine.TestField("Gen. Prod. Posting Group");

        CheckDates(RentalItemJnlLine);

        IsHandled := false;
        OnBeforeCheckLocation(RentalItemJnlLine, IsHandled);
        if not IsHandled then
            if InvtSetup."Location Mandatory" and
               (RentalItemJnlLine."Value Entry Type" = RentalItemJnlLine."Value Entry Type"::"Direct Cost") and
               (RentalItemJnlLine.Quantity <> 0) and
               not RentalItemJnlLine.Adjustment
            then begin
                if (RentalItemJnlLine.Type <> RentalItemJnlLine.Type::Resource) and (Item.Type = Item.Type::Inventory) and
                   (not RentalItemJnlLine."Direct Transfer" or (RentalItemJnlLine."Document Type" = RentalItemJnlLine."Document Type"::"Transfer Shipment"))
                then
                    RentalItemJnlLine.TestField("Location Code");
                if (RentalItemJnlLine."Entry Type" = RentalItemJnlLine."Entry Type"::Transfer) and
                   (not RentalItemJnlLine."Direct Transfer" or (RentalItemJnlLine."Document Type" = RentalItemJnlLine."Document Type"::"Transfer Receipt"))
                then
                    RentalItemJnlLine.TestField("New Location Code")
                else
                    RentalItemJnlLine.TestField("New Location Code", '');
            end;

        if ((RentalItemJnlLine."Entry Type" <> RentalItemJnlLine."Entry Type"::Transfer) or (RentalItemJnlLine."Order Type" <> RentalItemJnlLine."Order Type"::Transfer)) and
           not RentalItemJnlLine.Adjustment
        then begin
            CheckInTransitLocation(RentalItemJnlLine."Location Code");
            CheckInTransitLocation(RentalItemJnlLine."New Location Code");
        end;

        CheckBins(RentalItemJnlLine);

        if RentalItemJnlLine."Entry Type" in [RentalItemJnlLine."Entry Type"::"Positive Adjmt.", RentalItemJnlLine."Entry Type"::"Negative Adjmt."] then
            RentalItemJnlLine.TestField("Discount Amount", 0);

        if RentalItemJnlLine."Entry Type" = RentalItemJnlLine."Entry Type"::Transfer then begin
            if (RentalItemJnlLine."Value Entry Type" = RentalItemJnlLine."Value Entry Type"::"Direct Cost") and
               (RentalItemJnlLine."Item Charge No." = '') and
               not RentalItemJnlLine.Adjustment
            then
                RentalItemJnlLine.TestField(Amount, 0);
            RentalItemJnlLine.TestField("Discount Amount", 0);
            if RentalItemJnlLine.Quantity < 0 then
                RentalItemJnlLine.FieldError(Quantity, StrSubstNo(Text003Lbl, RentalItemJnlLine.FieldCaption("Entry Type"), RentalItemJnlLine."Entry Type"));
            if RentalItemJnlLine.Quantity <> RentalItemJnlLine."Invoiced Quantity" then
                RentalItemJnlLine.FieldError("Invoiced Quantity", StrSubstNo(Text004Lbl, RentalItemJnlLine.FieldCaption(Quantity)));
        end;

        if not RentalItemJnlLine."Phys. Inventory" then begin
            if RentalItemJnlLine."Entry Type" = RentalItemJnlLine."Entry Type"::Output then begin
                if (RentalItemJnlLine."Output Quantity (Base)" = 0) and (RentalItemJnlLine."Scrap Quantity (Base)" = 0) and
                   RentalItemJnlLine.TimeIsEmpty() and (RentalItemJnlLine."Invoiced Qty. (Base)" = 0)
                then
                    Error(Text007Lbl)
            end else
                if (RentalItemJnlLine."Quantity (Base)" = 0) and (RentalItemJnlLine."Invoiced Qty. (Base)" = 0) then
                    Error(Text007Lbl);
            RentalItemJnlLine.TestField("Qty. (Calculated)", 0);
            RentalItemJnlLine.TestField("Qty. (Phys. Inventory)", 0);
        end else
            CheckPhysInventory(RentalItemJnlLine);

        if RentalItemJnlLine."Entry Type" <> RentalItemJnlLine."Entry Type"::Output then begin
            RentalItemJnlLine.TestField("Run Time", 0);
            RentalItemJnlLine.TestField("Setup Time", 0);
            RentalItemJnlLine.TestField("Stop Time", 0);
            RentalItemJnlLine.TestField("Output Quantity", 0);
            RentalItemJnlLine.TestField("Scrap Quantity", 0);
        end;

        if RentalItemJnlLine."Applies-from Entry" <> 0 then begin
            ItemLedgEntry.Get(RentalItemJnlLine."Applies-from Entry");
            ItemLedgEntry.TestField("Item No.", RentalItemJnlLine."Item No.");
            ItemLedgEntry.TestField("Variant Code", RentalItemJnlLine."Variant Code");
            ItemLedgEntry.TestField(Positive, false);
            if RentalItemJnlLine."Applies-to Entry" = RentalItemJnlLine."Applies-from Entry" then
                Error(
                  Text011Lbl,
                  RentalItemJnlLine.FieldCaption("Applies-to Entry"),
                  RentalItemJnlLine.FieldCaption("Applies-from Entry"));
        end;

        if (RentalItemJnlLine."Entry Type" in [RentalItemJnlLine."Entry Type"::Consumption, RentalItemJnlLine."Entry Type"::Output]) and
           not (RentalItemJnlLine."Value Entry Type" = RentalItemJnlLine."Value Entry Type"::Revaluation) and
           not RentalItemJnlLine.OnlyStopTime()
        then begin
            RentalItemJnlLine.TestField("Source No.");
            RentalItemJnlLine.TestField("Order Type", RentalItemJnlLine."Order Type"::Production);
            if not CalledFromAdjustment and (RentalItemJnlLine."Entry Type" = RentalItemJnlLine."Entry Type"::Output) then
                if CheckFindProdOrderLine(ProdOrderLine, RentalItemJnlLine."Order No.", RentalItemJnlLine."Order Line No.") then begin
                    RentalItemJnlLine.TestField("Item No.", ProdOrderLine."Item No.");
                    OnAfterCheckFindProdOrderLine(RentalItemJnlLine, ProdOrderLine);
                end;

            if RentalItemJnlLine.Subcontracting then begin
                IsHandled := false;
                OnBeforeCheckSubcontracting(RentalItemJnlLine, IsHandled);
                if not IsHandled then begin
                    WorkCenter.Get(RentalItemJnlLine."Work Center No.");
                    WorkCenter.TestField("Subcontractor No.");
                end;
            end;
            if not CalledFromInvtPutawayPick then
                CheckWarehouse(RentalItemJnlLine);
        end;

        if RentalItemJnlLine."Entry Type" = RentalItemJnlLine."Entry Type"::"Assembly Consumption" then
            CheckWarehouse(RentalItemJnlLine);

        if (RentalItemJnlLine."Value Entry Type" <> RentalItemJnlLine."Value Entry Type"::"Direct Cost") or (RentalItemJnlLine."Item Charge No." <> '') then
            if RentalItemJnlLine."Inventory Value Per" = RentalItemJnlLine."Inventory Value Per"::" " then
                RentalItemJnlLine.TestField("Applies-to Entry");

        CheckDimensions(RentalItemJnlLine);

        if (RentalItemJnlLine."Entry Type" in
            [RentalItemJnlLine."Entry Type"::Purchase, RentalItemJnlLine."Entry Type"::Sale, RentalItemJnlLine."Entry Type"::"Positive Adjmt.", RentalItemJnlLine."Entry Type"::"Negative Adjmt."]) and
           (not GenJnlPostPreview.IsActive())
        then
            RentalItemJnlLine.CheckItemJournalLineRestriction();

        OnAfterCheckRentalItemJnlLine(RentalItemJnlLine, CalledFromInvtPutawayPick, CalledFromAdjustment);
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if LocationCode = '' then
            Clear(Location)
        else
            if Location.Code <> LocationCode then
                Location.Get(LocationCode);
    end;

    local procedure CheckFindProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ProdOrderNo: Code[20]; LineNo: Integer): Boolean
    begin
        ProdOrderLine.SetFilter(Status, '>=%1', ProdOrderLine.Status::Released);
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderLine.SetRange("Line No.", LineNo);
        exit(ProdOrderLine.FindFirst());
    end;

    procedure SetCalledFromInvtPutawayPick(NewCalledFromInvtPutawayPick: Boolean)
    begin
        CalledFromInvtPutawayPick := NewCalledFromInvtPutawayPick;
    end;

    local procedure CheckWarehouse(RentalItemJnlLine: Record "TWE Rental Item Journal Line")
    var
        AssemblyLine: Record "Assembly Line";
        ReservationEntry: Record "Reservation Entry";
        WhseValidateSourceLine: Codeunit "Whse. Validate Source Line";
        ShowError: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckWarehouse(RentalItemJnlLine, IsHandled);
        if IsHandled then
            exit;

        if (RentalItemJnlLine.Quantity = 0) or
           (RentalItemJnlLine."Item Charge No." <> '') or
           (RentalItemJnlLine."Value Entry Type" in
            [RentalItemJnlLine."Value Entry Type"::Revaluation, RentalItemJnlLine."Value Entry Type"::Rounding]) or
           RentalItemJnlLine.Adjustment
        then
            exit;

        GetLocation(RentalItemJnlLine."Location Code");
        if Location."Directed Put-away and Pick" then
            exit;

        case RentalItemJnlLine."Entry Type" of
            RentalItemJnlLine."Entry Type"::Output:
                if WhseOrderHandlingRequired(RentalItemJnlLine, Location) then begin
                    if (RentalItemJnlLine.Quantity < 0) and (RentalItemJnlLine."Applies-to Entry" = 0) then begin
                        ReservationEntry.InitSortingAndFilters(false);
                        RentalItemJnlLine.SetReservationFilters(ReservationEntry);
                        ReservationEntry.ClearTrackingFilter();
                        if ReservationEntry.FindSet() then
                            repeat
                                if ReservationEntry."Appl.-to Item Entry" = 0 then
                                    ShowError := true;
                            until (ReservationEntry.Next() = 0) or ShowError
                        else
                            ShowError := RentalItemJnlLine.LastOutputOperation(RentalItemJnlLine);
                    end;

                    if WhseValidateSourceLine.WhseLinesExist(
                         DATABASE::"Prod. Order Line", 3, RentalItemJnlLine."Order No.", RentalItemJnlLine."Order Line No.", 0, RentalItemJnlLine.Quantity)
                    then
                        ShowError := true;
                end;
            RentalItemJnlLine."Entry Type"::Consumption:
                if WhseOrderHandlingRequired(RentalItemJnlLine, Location) then
                    if WhseValidateSourceLine.WhseLinesExist(
                         DATABASE::"Prod. Order Component",
                         3,
                         RentalItemJnlLine."Order No.",
                         RentalItemJnlLine."Order Line No.",
                         RentalItemJnlLine."Prod. Order Comp. Line No.",
                         RentalItemJnlLine.Quantity)
                    then
                        ShowError := true;
            RentalItemJnlLine."Entry Type"::"Assembly Consumption":
                if WhseOrderHandlingRequired(RentalItemJnlLine, Location) then
                    if WhseValidateSourceLine.WhseLinesExist(
                         DATABASE::"Assembly Line",
                         AssemblyLine."Document Type"::Order.AsInteger(),
                         RentalItemJnlLine."Order No.",
                         RentalItemJnlLine."Order Line No.",
                         0,
                         RentalItemJnlLine.Quantity)
                    then
                        ShowError := true;
        end;
        if ShowError then
            Error(
              Text012Lbl,
              RentalItemJnlLine.FieldCaption("Entry Type"),
              RentalItemJnlLine."Entry Type",
              RentalItemJnlLine.FieldCaption("Order No."),
              RentalItemJnlLine."Order No.",
              RentalItemJnlLine.FieldCaption("Order Line No."),
              RentalItemJnlLine."Order Line No.");
    end;

    local procedure WhseOrderHandlingRequired(RentalItemJnlLine: Record "TWE Rental Item Journal Line"; Location: Record Location): Boolean
    var
        InvtPutAwayLocation: Boolean;
        InvtPickLocation: Boolean;
    begin
        InvtPutAwayLocation := not Location."Require Receive" and Location."Require Put-away";
        OnAfterAssignInvtPutAwayRequired(RentalItemJnlLine, Location, InvtPutAwayLocation);
        if InvtPutAwayLocation then
            case RentalItemJnlLine."Entry Type" of
                RentalItemJnlLine."Entry Type"::Output:
                    if RentalItemJnlLine.Quantity >= 0 then
                        exit(true);
                RentalItemJnlLine."Entry Type"::Consumption,
              RentalItemJnlLine."Entry Type"::"Assembly Consumption":
                    if RentalItemJnlLine.Quantity < 0 then
                        exit(true);
            end;

        InvtPickLocation := not Location."Require Shipment" and Location."Require Pick";
        OnAfterAssignInvtPickRequired(RentalItemJnlLine, Location, InvtPickLocation);
        if InvtPickLocation then
            case RentalItemJnlLine."Entry Type" of
                RentalItemJnlLine."Entry Type"::Output:
                    if RentalItemJnlLine.Quantity < 0 then
                        exit(true);
                RentalItemJnlLine."Entry Type"::Consumption,
              RentalItemJnlLine."Entry Type"::"Assembly Consumption":
                    if RentalItemJnlLine.Quantity >= 0 then
                        exit(true);
            end;

        exit(false);
    end;

    procedure SetCalledFromAdjustment(NewCalledFromAdjustment: Boolean)
    begin
        CalledFromAdjustment := NewCalledFromAdjustment;
    end;

    local procedure CheckBins(RentalItemJnlLine: Record "TWE Rental Item Journal Line")
    var
        WMSManagement: Codeunit "WMS Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckBins(RentalItemJnlLine, IsHandled);
        if IsHandled then
            exit;

        if (RentalItemJnlLine."Item Charge No." <> '') or (RentalItemJnlLine."Value Entry Type" <> RentalItemJnlLine."Value Entry Type"::"Direct Cost") or (RentalItemJnlLine.Quantity = 0) then
            exit;

        if RentalItemJnlLine."Entry Type" = RentalItemJnlLine."Entry Type"::Transfer then begin
            GetLocation(RentalItemJnlLine."New Location Code");
            if Location."Bin Mandatory" and not Location."Directed Put-away and Pick" then
                RentalItemJnlLine.TestField("New Bin Code");
        end else begin
            GetLocation(RentalItemJnlLine."Location Code");
            if not Location."Bin Mandatory" or Location."Directed Put-away and Pick" then
                exit;
        end;

        if RentalItemJnlLine."Drop Shipment" or RentalItemJnlLine.OnlyStopTime() or (RentalItemJnlLine."Quantity (Base)" = 0) or RentalItemJnlLine.Adjustment or CalledFromAdjustment then
            exit;

        if (RentalItemJnlLine."Entry Type" = RentalItemJnlLine."Entry Type"::Output) and not RentalItemJnlLine.LastOutputOperation(RentalItemJnlLine) then
            exit;

        if RentalItemJnlLine.Quantity <> 0 then
            case RentalItemJnlLine."Entry Type" of
                RentalItemJnlLine."Entry Type"::Purchase,
              RentalItemJnlLine."Entry Type"::"Positive Adjmt.",
              RentalItemJnlLine."Entry Type"::Output,
              RentalItemJnlLine."Entry Type"::"Assembly Output":
                    WMSManagement.CheckInbOutbBin(RentalItemJnlLine."Location Code", RentalItemJnlLine."Bin Code", RentalItemJnlLine.Quantity > 0);
                RentalItemJnlLine."Entry Type"::Sale,
              RentalItemJnlLine."Entry Type"::"Negative Adjmt.",
              RentalItemJnlLine."Entry Type"::Consumption,
              RentalItemJnlLine."Entry Type"::"Assembly Consumption":
                    WMSManagement.CheckInbOutbBin(RentalItemJnlLine."Location Code", RentalItemJnlLine."Bin Code", RentalItemJnlLine.Quantity < 0);
                RentalItemJnlLine."Entry Type"::Transfer:
                    begin
                        GetLocation(RentalItemJnlLine."Location Code");
                        if Location."Bin Mandatory" and not Location."Directed Put-away and Pick" then
                            WMSManagement.CheckInbOutbBin(RentalItemJnlLine."Location Code", RentalItemJnlLine."Bin Code", RentalItemJnlLine.Quantity < 0);
                        if (RentalItemJnlLine."New Location Code" <> '') and (RentalItemJnlLine."New Bin Code" <> '') then
                            WMSManagement.CheckInbOutbBin(RentalItemJnlLine."New Location Code", RentalItemJnlLine."New Bin Code", RentalItemJnlLine.Quantity > 0);
                    end;
            end;
    end;

    local procedure CheckDates(RentalItemJnlLine: Record "TWE Rental Item Journal Line")
    var
        InvtPeriod: Record "Inventory Period";
        UserSetupManagement: Codeunit "User Setup Management";
        DateCheckDone: Boolean;
    begin
        RentalItemJnlLine.TestField("Posting Date");
        if RentalItemJnlLine."Posting Date" <> NormalDate(RentalItemJnlLine."Posting Date") then
            RentalItemJnlLine.FieldError("Posting Date", Text000Lbl);

        OnBeforeDateNotAllowed(RentalItemJnlLine, DateCheckDone);
        if not DateCheckDone then
            UserSetupManagement.CheckAllowedPostingDate(RentalItemJnlLine."Posting Date");

        if not InvtPeriod.IsValidDate(RentalItemJnlLine."Posting Date") then
            InvtPeriod.ShowError(RentalItemJnlLine."Posting Date");

        if RentalItemJnlLine."Document Date" <> 0D then
            if RentalItemJnlLine."Document Date" <> NormalDate(RentalItemJnlLine."Document Date") then
                RentalItemJnlLine.FieldError("Document Date", Text000Lbl);
    end;

    local procedure CheckDimensions(RentalItemJnlLine: Record "TWE Rental Item Journal Line")
    var
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckDimensions(RentalItemJnlLine, CalledFromAdjustment, IsHandled);
        if IsHandled then
            exit;

        if not RentalItemJnlLine.IsValueEntryForDeletedItem() and not RentalItemJnlLine.Correction and not CalledFromAdjustment then begin
            if not DimMgt.CheckDimIDComb(RentalItemJnlLine."Dimension Set ID") then
                Error(DimCombBlockedErr, RentalItemJnlLine."Journal Template Name", RentalItemJnlLine."Journal Batch Name", RentalItemJnlLine."Line No.", DimMgt.GetDimCombErr());
            if RentalItemJnlLine."Item Charge No." = '' then begin
                TableID[1] := DATABASE::Item;
                No[1] := RentalItemJnlLine."Item No.";
            end else begin
                TableID[1] := DATABASE::"Item Charge";
                No[1] := RentalItemJnlLine."Item Charge No.";
            end;
            TableID[2] := DATABASE::"Salesperson/Purchaser";
            No[2] := RentalItemJnlLine."Salespers./Purch. Code";
            TableID[3] := DATABASE::"Work Center";
            No[3] := RentalItemJnlLine."Work Center No.";
            if not DimMgt.CheckDimValuePosting(TableID, No, RentalItemJnlLine."Dimension Set ID") then begin
                if RentalItemJnlLine."Line No." <> 0 then
                    Error(DimCausedErr, RentalItemJnlLine."Journal Template Name", RentalItemJnlLine."Journal Batch Name", RentalItemJnlLine."Line No.", DimMgt.GetDimValuePostingErr());
                Error(DimMgt.GetDimValuePostingErr());
            end;
            if (RentalItemJnlLine."Entry Type" = RentalItemJnlLine."Entry Type"::Transfer) and
               (RentalItemJnlLine."Value Entry Type" <> RentalItemJnlLine."Value Entry Type"::Revaluation)
            then
                if not DimMgt.CheckDimIDComb(RentalItemJnlLine."Dimension Set ID") then begin
                    if RentalItemJnlLine."Line No." <> 0 then
                        Error(DimCausedErr, RentalItemJnlLine."Journal Template Name", RentalItemJnlLine."Journal Batch Name", RentalItemJnlLine."Line No.", DimMgt.GetDimValuePostingErr());
                    Error(DimMgt.GetDimValuePostingErr());
                end;
        end;
    end;

    local procedure CheckPhysInventory(RentalItemJnlLine: Record "TWE Rental Item Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckPhysInventory(RentalItemJnlLine, IsHandled);
        if IsHandled then
            exit;

        if not
           (RentalItemJnlLine."Entry Type" in
            [RentalItemJnlLine."Entry Type"::"Positive Adjmt.", RentalItemJnlLine."Entry Type"::"Negative Adjmt."])
        then begin
            RentalItemJnlLine2."Entry Type" := RentalItemJnlLine2."Entry Type"::"Positive Adjmt.";
            RentalItemJnlLine3."Entry Type" := RentalItemJnlLine3."Entry Type"::"Negative Adjmt.";
            RentalItemJnlLine.FieldError(
              "Entry Type",
              StrSubstNo(
                Text005Lbl, RentalItemJnlLine2."Entry Type", RentalItemJnlLine3."Entry Type", RentalItemJnlLine.FieldCaption("Phys. Inventory"), true));
        end;
        if (RentalItemJnlLine."Entry Type" = RentalItemJnlLine."Entry Type"::"Positive Adjmt.") and
           (RentalItemJnlLine."Qty. (Phys. Inventory)" - RentalItemJnlLine."Qty. (Calculated)" <> RentalItemJnlLine.Quantity)
        then
            RentalItemJnlLine.FieldError(
              Quantity,
              StrSubstNo(
                Text006Lbl, RentalItemJnlLine.FieldCaption("Qty. (Phys. Inventory)"), RentalItemJnlLine.FieldCaption("Qty. (Calculated)"),
                RentalItemJnlLine.FieldCaption("Entry Type"), RentalItemJnlLine."Entry Type", RentalItemJnlLine.FieldCaption("Phys. Inventory"), true));
        if (RentalItemJnlLine."Entry Type" = RentalItemJnlLine."Entry Type"::"Negative Adjmt.") and
           (RentalItemJnlLine."Qty. (Calculated)" - RentalItemJnlLine."Qty. (Phys. Inventory)" <> RentalItemJnlLine.Quantity)
        then
            RentalItemJnlLine.FieldError(
              Quantity,
              StrSubstNo(
                Text006Lbl, RentalItemJnlLine.FieldCaption("Qty. (Calculated)"), RentalItemJnlLine.FieldCaption("Qty. (Phys. Inventory)"),
                RentalItemJnlLine.FieldCaption("Entry Type"), RentalItemJnlLine."Entry Type", RentalItemJnlLine.FieldCaption("Phys. Inventory"), true));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckRentalItemJnlLine(var RentalItemJnlLine: Record "TWE Rental Item Journal Line"; CalledFromInvtPutawayPick: Boolean; CalledFromAdjustment: Boolean)
    begin
    end;

    local procedure CheckInTransitLocation(LocationCode: Code[10])
    begin
        if Location.IsInTransit(LocationCode) then
            Error(UseInTransitLocationErr, LocationCode)
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignInvtPickRequired(RentalItemJournalLine: Record "TWE Rental Item Journal Line"; Location: Record Location; var InvtPickLocation: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignInvtPutAwayRequired(RentalItemJournalLine: Record "TWE Rental Item Journal Line"; Location: Record Location; var InvtPutAwayLocation: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckFindProdOrderLine(RentalItemJournalLine: Record "TWE Rental Item Journal Line"; ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetItem(Item: Record Item; var RentalItemJournalLine: Record "TWE Rental Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckBins(var RentalItemJournalLine: Record "TWE Rental Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckDimensions(var RentalItemJournalLine: Record "TWE Rental Item Journal Line"; CalledFromAdjustment: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckLocation(var RentalItemJournalLine: Record "TWE Rental Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckSubcontracting(var RentalItemJournalLine: Record "TWE Rental Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckWarehouse(var RentalItemJournalLine: Record "TWE Rental Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDateNotAllowed(RentalItemJnlLine: Record "TWE Rental Item Journal Line"; var DateCheckDone: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckPhysInventory(RentalItemJnlLine: Record "TWE Rental Item Journal Line"; var IsHandled: Boolean)
    begin
    end;
}

