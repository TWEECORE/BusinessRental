/// <summary>
/// Codeunit TWE Undo Rental Posting Mgt. (ID 50068).
/// </summary>
codeunit 50068 "TWE Undo Rental Posting Mgt."
{

    trigger OnRun()
    begin
    end;

    var
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        Text001Lbl: Label 'You cannot undo line %1 because there is not sufficient content in the receiving bins.', Comment = '%1 defines the line no.';
        Text002Lbl: Label 'You cannot undo line %1 because warehouse put-away lines have already been created.', Comment = '%1 defines the line no.';
        Text003Lbl: Label 'You cannot undo line %1 because warehouse activity lines have already been posted.', Comment = '%1 defines the line no.';
        Text004Lbl: Label 'You must delete the related %1 before you undo line %2.', Comment = '%1 Warehouse Worksheet Line, %2 defines the line no.';
        Text005Lbl: Label 'You cannot undo line %1 because warehouse receipt lines have already been created.', Comment = '%1 defines the line no.';
        Text006Lbl: Label 'You cannot undo line %1 because warehouse shipment lines have already been created.', Comment = '%1 defines the line no.';
        Text007Lbl: Label 'The items have been picked. If you undo line %1, the items will remain in the shipping area until you put them away.\Do you still want to undo the shipment?', Comment = '%1 defines the line no.';
        Text008Lbl: Label 'You cannot undo line %1 because warehouse receipt lines have already been posted.', Comment = '%1 defines the line no.';
        Text009Lbl: Label 'You cannot undo line %1 because warehouse put-away lines have already been posted.', Comment = '%1 defines the line no.';
        Text010Lbl: Label 'You cannot undo line %1 because inventory pick lines have already been posted.', Comment = '%1 defines the line no.';
        Text011Lbl: Label 'You cannot undo line %1 because there is an item charge assigned to it on %2 Doc No. %3 Line %4.', Comment = '%1 defines the undo line no., %2 defines Document Type, %3 defines document no. and %4 defines source line no.';
        Text012Lbl: Label 'You cannot undo line %1 because an item charge has already been invoiced.', Comment = '%1 defines the line no.';
        Text013Lbl: Label 'Item ledger entries are missing for line %1.', Comment = '%1 defines the line no.';
        Text014Lbl: Label 'You cannot undo line %1, because a revaluation has already been posted.', Comment = '%1 defines the line no.';
        Text015Lbl: Label 'You cannot undo posting of item %1 with variant ''%2'' and unit of measure %3 because it is not available at location %4, bin code %5. The required quantity is %6. The available quantity is %7.'
                          , Comment = '%1 defines item no., %2 defines variant code, %3 defines unit of measure code, %4 defines location, %5 defines bin code, %6 defines the required quantity, %7 defines the available quantity.';

    /// <summary>
    /// TestRentalShptLine.
    /// </summary>
    /// <param name="RentalShptLine">Record "TWE Rental Shipment Line".</param>
    procedure TestRentalShptLine(RentalShptLine: Record "TWE Rental Shipment Line")
    var
        RentalLine: Record "TWE Rental Line";
    begin
        TestAllTransactions(
            DATABASE::"TWE Rental Shipment Line", RentalShptLine."Document No.", RentalShptLine."Line No.",
            DATABASE::"TWE Rental Line", RentalLine."Document Type"::Contract.AsInteger(), RentalShptLine."Order No.", RentalShptLine."Order Line No.");
    end;

    /// <summary>
    /// TestServShptLine.
    /// </summary>
    /// <param name="ServShptLine">Record "Service Shipment Line".</param>
    procedure TestServShptLine(ServShptLine: Record "Service Shipment Line")
    var
        ServLine: Record "Service Line";
    begin
        TestAllTransactions(
            DATABASE::"Service Shipment Line", ServShptLine."Document No.", ServShptLine."Line No.",
            DATABASE::"Service Line", ServLine."Document Type"::Order.AsInteger(), ServShptLine."Order No.", ServShptLine."Order Line No.");
    end;

    /// <summary>
    /// TestPurchRcptLine.
    /// </summary>
    /// <param name="PurchRcptLine">Record "Purch. Rcpt. Line".</param>
    procedure TestPurchRcptLine(PurchRcptLine: Record "Purch. Rcpt. Line")
    var
        PurchLine: Record "Purchase Line";
    begin
        TestAllTransactions(
            DATABASE::"Purch. Rcpt. Line", PurchRcptLine."Document No.", PurchRcptLine."Line No.",
            DATABASE::"Purchase Line", PurchLine."Document Type"::Order.AsInteger(), PurchRcptLine."Order No.", PurchRcptLine."Order Line No.");
    end;

    /// <summary>
    /// TestReturnRcptLine.
    /// </summary>
    /// <param name="RentalReturnShptLine">Record "TWE Rental Return Ship. Line".</param>
    procedure TestReturnRcptLine(RentalReturnShptLine: Record "TWE Rental Return Ship. Line")
    var
        RentalLine: Record "TWE Rental Line";
    begin
        TestAllTransactions(
            DATABASE::"Return Receipt Line", RentalReturnShptLine."Document No.", RentalReturnShptLine."Line No.",
            DATABASE::"TWE Rental Line", RentalLine."Document Type"::"Return Shipment".AsInteger(), '', 0);
    end;

    /// <summary>
    /// RunTestAllTransactions.
    /// </summary>
    /// <param name="UndoType">Integer.</param>
    /// <param name="UndoID">Code[20].</param>
    /// <param name="UndoLineNo">Integer.</param>
    /// <param name="SourceType">Integer.</param>
    /// <param name="SourceSubtype">Integer.</param>
    /// <param name="SourceID">Code[20].</param>
    /// <param name="SourceRefNo">Integer.</param>
    procedure RunTestAllTransactions(UndoType: Integer; UndoID: Code[20]; UndoLineNo: Integer; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer)
    begin
        TestAllTransactions(UndoType, UndoID, UndoLineNo, SourceType, SourceSubtype, SourceID, SourceRefNo);
    end;

    local procedure TestAllTransactions(UndoType: Integer; UndoID: Code[20]; UndoLineNo: Integer; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer)
    begin
        OnBeforeTestAllTransactions(UndoType, UndoID, UndoLineNo, SourceType, SourceSubtype, SourceID, SourceRefNo);
        if not TestPostedWhseReceiptLine(
             UndoType, UndoID, UndoLineNo, SourceType, SourceSubtype, SourceID, SourceRefNo)
        then begin
            TestWarehouseActivityLine(UndoType, UndoLineNo, SourceType, SourceSubtype, SourceID, SourceRefNo);
            TestRgstrdWhseActivityLine(UndoLineNo, SourceType, SourceSubtype, SourceID, SourceRefNo);
            TestWhseWorksheetLine(UndoLineNo, SourceType, SourceSubtype, SourceID, SourceRefNo);
        end;

        if not (UndoType in [DATABASE::"Purch. Rcpt. Line", DATABASE::"Return Receipt Line"]) then
            TestWarehouseReceiptLine(UndoLineNo, SourceType, SourceSubtype, SourceID, SourceRefNo);
        if not (UndoType in [DATABASE::"TWE Rental Shipment Line", DATABASE::"Return Shipment Line", DATABASE::"Service Shipment Line"]) then
            TestWarehouseShipmentLine(UndoLineNo, SourceType, SourceSubtype, SourceID, SourceRefNo);
        TestPostedWhseShipmentLine(UndoLineNo, SourceType, SourceSubtype, SourceID, SourceRefNo);
        TestPostedInvtPutAwayLine(UndoLineNo, SourceType, SourceSubtype, SourceID, SourceRefNo);
        TestPostedInvtPickLine(UndoLineNo, SourceType, SourceSubtype, SourceID, SourceRefNo);

        TestItemChargeAssignmentPurch(UndoType, UndoLineNo, SourceID, SourceRefNo);
        TestItemChargeAssignmentRental(UndoType, UndoLineNo, SourceID, SourceRefNo);
    end;

    local procedure TestPostedWhseReceiptLine(UndoType: Integer; UndoID: Code[20]; UndoLineNo: Integer; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer): Boolean
    var
        PostedWhseReceiptLine: Record "Posted Whse. Receipt Line";
        PostedAsmHeader: Record "Posted Assembly Header";
        WhseUndoQty: Codeunit "Whse. Undo Quantity";
    begin
        case UndoType of
            DATABASE::"Posted Assembly Line":
                begin
                    TestWarehouseActivityLine(UndoType, UndoLineNo, SourceType, SourceSubtype, SourceID, SourceRefNo);
                    exit(true);
                end;
            DATABASE::"Posted Assembly Header":
                begin
                    PostedAsmHeader.Get(UndoID);
                    if not (PostedAsmHeader.IsAsmToOrder()) then
                        TestWarehouseBinContent(SourceType, SourceSubtype, SourceID, SourceRefNo, PostedAsmHeader."Quantity (Base)");
                    exit(true);
                end;
        end;

        if not WhseUndoQty.FindPostedWhseRcptLine(
             PostedWhseReceiptLine, UndoType, UndoID, SourceType, SourceSubtype, SourceID, SourceRefNo)
        then
            exit(false);

        TestWarehouseEntry(UndoLineNo, PostedWhseReceiptLine);
        TestWarehouseActivityLine2(UndoLineNo, PostedWhseReceiptLine);
        TestRgstrdWhseActivityLine2(UndoLineNo, PostedWhseReceiptLine);
        TestWhseWorksheetLine2(UndoLineNo, PostedWhseReceiptLine);
        exit(true);
    end;

    local procedure TestWarehouseEntry(UndoLineNo: Integer; var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line")
    var
        WarehouseEntry: Record "Warehouse Entry";
        Location: Record Location;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestWarehouseEntry(UndoLineNo, PostedWhseReceiptLine, IsHandled);
        if IsHandled then
            exit;

        if PostedWhseReceiptLine."Location Code" = '' then
            exit;
        Location.Get(PostedWhseReceiptLine."Location Code");
        if Location."Bin Mandatory" then begin
            WarehouseEntry.SetCurrentKey("Item No.", "Location Code", "Variant Code", "Bin Type Code");
            WarehouseEntry.SetRange("Item No.", PostedWhseReceiptLine."Item No.");
            WarehouseEntry.SetRange("Location Code", PostedWhseReceiptLine."Location Code");
            WarehouseEntry.SetRange("Variant Code", PostedWhseReceiptLine."Variant Code");
            if Location."Directed Put-away and Pick" then
                WarehouseEntry.SetFilter("Bin Type Code", GetBinTypeFilter(0)); // Receiving area
            WarehouseEntry.CalcSums("Qty. (Base)");
            if WarehouseEntry."Qty. (Base)" < PostedWhseReceiptLine."Qty. (Base)" then
                Error(Text001Lbl, UndoLineNo);
        end;
    end;

    local procedure TestWarehouseBinContent(SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer; UndoQtyBase: Decimal)
    var
        WhseEntry: Record "Warehouse Entry";
        BinContent: Record "Bin Content";
        QtyAvailToTake: Decimal;
    begin
        WhseEntry.SetSourceFilter(SourceType, SourceSubtype, SourceID, SourceRefNo, true);
        if not WhseEntry.FindFirst() then
            exit;

        BinContent.Get(WhseEntry."Location Code", WhseEntry."Bin Code", WhseEntry."Item No.", WhseEntry."Variant Code", WhseEntry."Unit of Measure Code");
        QtyAvailToTake := BinContent.CalcQtyAvailToTake(0);
        if QtyAvailToTake < UndoQtyBase then
            Error(Text015Lbl,
              WhseEntry."Item No.",
              WhseEntry."Variant Code",
              WhseEntry."Unit of Measure Code",
              WhseEntry."Location Code",
              WhseEntry."Bin Code",
              UndoQtyBase,
              QtyAvailToTake);
    end;

    local procedure TestWarehouseActivityLine2(UndoLineNo: Integer; var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line")
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetCurrentKey("Whse. Document No.", "Whse. Document Type", "Activity Type", "Whse. Document Line No.");
        WarehouseActivityLine.SetRange("Whse. Document No.", PostedWhseReceiptLine."No.");
        WarehouseActivityLine.SetRange("Whse. Document Type", WarehouseActivityLine."Whse. Document Type"::Receipt);
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::"Put-away");
        WarehouseActivityLine.SetRange("Whse. Document Line No.", PostedWhseReceiptLine."Line No.");
        if not WarehouseActivityLine.IsEmpty then
            Error(Text002Lbl, UndoLineNo);
    end;

    local procedure TestRgstrdWhseActivityLine2(UndoLineNo: Integer; var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line")
    var
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
    begin
        RegisteredWhseActivityLine.SetCurrentKey("Whse. Document Type", "Whse. Document No.", "Whse. Document Line No.");
        RegisteredWhseActivityLine.SetRange("Whse. Document Type", RegisteredWhseActivityLine."Whse. Document Type"::Receipt);
        RegisteredWhseActivityLine.SetRange("Whse. Document No.", PostedWhseReceiptLine."No.");
        RegisteredWhseActivityLine.SetRange("Whse. Document Line No.", PostedWhseReceiptLine."Line No.");
        if not RegisteredWhseActivityLine.IsEmpty then
            Error(Text003Lbl, UndoLineNo);

    end;

    local procedure TestWhseWorksheetLine2(UndoLineNo: Integer; var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line")
    var
        WhseWorksheetLine: Record "Whse. Worksheet Line";
    begin
        WhseWorksheetLine.SetCurrentKey("Whse. Document Type", "Whse. Document No.", "Whse. Document Line No.");
        WhseWorksheetLine.SetRange("Whse. Document Type", WhseWorksheetLine."Whse. Document Type"::Receipt);
        WhseWorksheetLine.SetRange("Whse. Document No.", PostedWhseReceiptLine."No.");
        WhseWorksheetLine.SetRange("Whse. Document Line No.", PostedWhseReceiptLine."Line No.");
        if not WhseWorksheetLine.IsEmpty then
            Error(Text004Lbl, WhseWorksheetLine.TableCaption, UndoLineNo);
    end;

    local procedure TestWarehouseActivityLine(UndoType: Integer; UndoLineNo: Integer; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestWarehouseActivityLine(UndoType, UndoLineNo, SourceType, SourceSubtype, SourceID, SourceRefNo, IsHandled);
        if IsHandled then
            exit;

        WarehouseActivityLine.SetSourceFilter(SourceType, SourceSubtype, SourceID, SourceRefNo, -1, true);
        if not WarehouseActivityLine.IsEmpty then begin
            if UndoType = DATABASE::"Assembly Line" then
                Error(Text002Lbl, UndoLineNo);
            Error(Text003Lbl, UndoLineNo);
        end;
    end;

    local procedure TestRgstrdWhseActivityLine(UndoLineNo: Integer; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer)
    var
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestRgstrdWhseActivityLine(UndoLineNo, SourceType, SourceSubtype, SourceID, SourceRefNo, IsHandled);
        if IsHandled then
            exit;

        RegisteredWhseActivityLine.SetSourceFilter(SourceType, SourceSubtype, SourceID, SourceRefNo, -1, true);
        RegisteredWhseActivityLine.SetRange("Activity Type", RegisteredWhseActivityLine."Activity Type"::"Put-away");
        if not RegisteredWhseActivityLine.IsEmpty then
            Error(Text002Lbl, UndoLineNo);

    end;

    local procedure TestWarehouseReceiptLine(UndoLineNo: Integer; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer)
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WhseManagement: Codeunit "Whse. Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestWarehouseReceiptLine(UndoLineNo, SourceType, SourceSubtype, SourceID, SourceRefNo, IsHandled);
        if IsHandled then
            exit;

        WhseManagement.SetSourceFilterForWhseRcptLine(WarehouseReceiptLine, SourceType, SourceSubtype, SourceID, SourceRefNo, true);
        if not WarehouseReceiptLine.IsEmpty then
            Error(Text005Lbl, UndoLineNo);
    end;

    local procedure TestWarehouseShipmentLine(UndoLineNo: Integer; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer)
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestWarehouseShipmentLine(UndoLineNo, SourceType, SourceSubtype, SourceID, SourceRefNo, IsHandled);
        if IsHandled then
            exit;

        WarehouseShipmentLine.SetSourceFilter(SourceType, SourceSubtype, SourceID, SourceRefNo, true);
        if not WarehouseShipmentLine.IsEmpty then
            Error(Text006Lbl, UndoLineNo);
    end;

    local procedure TestPostedWhseShipmentLine(UndoLineNo: Integer; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer)
    var
        PostedWhseShipmentLine: Record "Posted Whse. Shipment Line";
        WhseManagement: Codeunit "Whse. Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestPostedWhseShipmentLine(UndoLineNo, SourceType, SourceSubtype, SourceID, SourceRefNo, IsHandled);
        if IsHandled then
            exit;

        WhseManagement.SetSourceFilterForPostedWhseShptLine(PostedWhseShipmentLine, SourceType, SourceSubtype, SourceID, SourceRefNo, true);
        if not PostedWhseShipmentLine.IsEmpty then
            if not Confirm(Text007Lbl, true, UndoLineNo) then
                Error('');
    end;

    local procedure TestWhseWorksheetLine(UndoLineNo: Integer; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer)
    var
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestWhseWorksheetLine(UndoLineNo, SourceType, SourceSubtype, SourceID, SourceRefNo, IsHandled);
        if IsHandled then
            exit;

        WhseWorksheetLine.SetSourceFilter(SourceType, SourceSubtype, SourceID, SourceRefNo, true);
        if not WhseWorksheetLine.IsEmpty then
            Error(Text008Lbl, UndoLineNo);
    end;

    local procedure TestPostedInvtPutAwayLine(UndoLineNo: Integer; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer)
    var
        PostedInvtPutAwayLine: Record "Posted Invt. Put-away Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestPostedInvtPutAwayLine(UndoLineNo, SourceType, SourceSubtype, SourceID, SourceRefNo, IsHandled);
        if IsHandled then
            exit;

        PostedInvtPutAwayLine.SetSourceFilter(SourceType, SourceSubtype, SourceID, SourceRefNo, true);
        if not PostedInvtPutAwayLine.IsEmpty then
            Error(Text009Lbl, UndoLineNo);
    end;

    local procedure TestPostedInvtPickLine(UndoLineNo: Integer; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer)
    var
        PostedInvtPickLine: Record "Posted Invt. Pick Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestPostedInvtPickLine(UndoLineNo, SourceType, SourceSubtype, SourceID, SourceRefNo, IsHandled);
        if IsHandled then
            exit;

        PostedInvtPickLine.SetSourceFilter(SourceType, SourceSubtype, SourceID, SourceRefNo, true);
        if not PostedInvtPickLine.IsEmpty then
            Error(Text010Lbl, UndoLineNo);

    end;

    local procedure TestItemChargeAssignmentPurch(UndoType: Integer; UndoLineNo: Integer; SourceID: Code[20]; SourceRefNo: Integer)
    var
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
    begin
        ItemChargeAssignmentPurch.SetCurrentKey("Applies-to Doc. Type", "Applies-to Doc. No.", "Applies-to Doc. Line No.");
        case UndoType of
            DATABASE::"Purch. Rcpt. Line":
                ItemChargeAssignmentPurch.SetRange("Applies-to Doc. Type", ItemChargeAssignmentPurch."Applies-to Doc. Type"::Receipt);
            DATABASE::"Return Shipment Line":
                ItemChargeAssignmentPurch.SetRange("Applies-to Doc. Type", ItemChargeAssignmentPurch."Applies-to Doc. Type"::"Return Shipment");
            else
                exit;
        end;
        ItemChargeAssignmentPurch.SetRange("Applies-to Doc. No.", SourceID);
        ItemChargeAssignmentPurch.SetRange("Applies-to Doc. Line No.", SourceRefNo);
        if not ItemChargeAssignmentPurch.IsEmpty then
            if ItemChargeAssignmentPurch.FindFirst() then
                Error(Text011Lbl, UndoLineNo, ItemChargeAssignmentPurch."Document Type", ItemChargeAssignmentPurch."Document No.",
                      ItemChargeAssignmentPurch."Line No.");
    end;

    local procedure TestItemChargeAssignmentRental(UndoType: Integer; UndoLineNo: Integer; SourceID: Code[20]; SourceRefNo: Integer)
    var
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
    begin
        ItemChargeAssignmentSales.SetCurrentKey("Applies-to Doc. Type", "Applies-to Doc. No.", "Applies-to Doc. Line No.");
        case UndoType of
            DATABASE::"TWE Rental Shipment Line":
                ItemChargeAssignmentSales.SetRange("Applies-to Doc. Type", ItemChargeAssignmentSales."Applies-to Doc. Type"::Shipment);
            DATABASE::"Return Receipt Line":
                ItemChargeAssignmentSales.SetRange("Applies-to Doc. Type", ItemChargeAssignmentSales."Applies-to Doc. Type"::"Return Receipt");
            else
                exit;
        end;
        ItemChargeAssignmentSales.SetRange("Applies-to Doc. No.", SourceID);
        ItemChargeAssignmentSales.SetRange("Applies-to Doc. Line No.", SourceRefNo);
        if not ItemChargeAssignmentSales.IsEmpty then
            if ItemChargeAssignmentSales.FindFirst() then
                Error(Text011Lbl, UndoLineNo, ItemChargeAssignmentSales."Document Type", ItemChargeAssignmentSales."Document No.",
                      ItemChargeAssignmentSales."Line No.");
    end;

    local procedure GetBinTypeFilter(Type: Option Receive,Ship,"Put Away",Pick): Text[1024]
    var
        BinType: Record "Bin Type";
        "Filter": Text[1024];
        Placeholder001Lbl: Label '%1|%2', Comment = '%1 defines Filter text, %2 defines Bin Type Code';
    begin
        case Type of
            Type::Receive:
                BinType.SetRange(Receive, true);
            Type::Ship:
                BinType.SetRange(Ship, true);
            Type::"Put Away":
                BinType.SetRange("Put Away", true);
            Type::Pick:
                BinType.SetRange(Pick, true);
        end;
        if BinType.Find('-') then
            repeat
                Filter := CopyStr(StrSubstNo(Placeholder001Lbl, Filter, BinType.Code), 1, MaxStrLen(Filter));
            until BinType.Next() = 0;
        if Filter <> '' then
            Filter := CopyStr(CopyStr(Filter, 2), 1, MaxStrLen(Filter));
        exit(Filter);
    end;

    procedure CheckItemLedgEntries(var TempItemLedgEntry: Record "Item Ledger Entry" temporary; LineRef: Integer)
    begin
        CheckItemLedgEntries(TempItemLedgEntry, LineRef, false);
    end;

    procedure CheckItemLedgEntries(var TempItemLedgEntry: Record "Item Ledger Entry" temporary; LineRef: Integer; InvoicedEntry: Boolean)
    var
        ValueEntry: Record "Value Entry";
        ItemRec: Record Item;
        PostedATOLink: Record "Posted Assemble-to-Order Link";
    begin
        TempItemLedgEntry.Find('-'); // Assertion: will fail if not found.
        ValueEntry.SetCurrentKey("Item Ledger Entry No.");
        ItemRec.Get(TempItemLedgEntry."Item No.");
        if ItemRec.IsNonInventoriableType() then
            exit;

        repeat
            OnCheckItemLedgEntriesOnBeforeCheckTempItemLedgEntry(TempItemLedgEntry);
            if TempItemLedgEntry.Positive then begin
                if (TempItemLedgEntry."Job No." = '') and
                   not ((TempItemLedgEntry."Order Type" = TempItemLedgEntry."Order Type"::Assembly) and
                        PostedATOLink.Get(PostedATOLink."Assembly Document Type"::Assembly, TempItemLedgEntry."Document No."))
                then
                    if InvoicedEntry then
                        TempItemLedgEntry.TestField("Remaining Quantity", TempItemLedgEntry.Quantity - TempItemLedgEntry."Invoiced Quantity")
                    else
                        TempItemLedgEntry.TestField("Remaining Quantity", TempItemLedgEntry.Quantity);
            end else
                if InvoicedEntry then
                    TempItemLedgEntry.TestField("Shipped Qty. Not Returned", TempItemLedgEntry.Quantity - TempItemLedgEntry."Invoiced Quantity")
                else
                    TempItemLedgEntry.TestField("Shipped Qty. Not Returned", TempItemLedgEntry.Quantity);

            TempItemLedgEntry.CalcFields("Reserved Quantity");
            TempItemLedgEntry.TestField("Reserved Quantity", 0);

            ValueEntry.SetRange("Item Ledger Entry No.", TempItemLedgEntry."Entry No.");
            if ValueEntry.Find('-') then
                repeat
                    if ValueEntry."Item Charge No." <> '' then
                        Error(Text012Lbl, LineRef);
                    if ValueEntry."Entry Type" = ValueEntry."Entry Type"::Revaluation then
                        Error(Text014Lbl, LineRef);
                until ValueEntry.Next() = 0;

            if ItemRec."Costing Method" = ItemRec."Costing Method"::Specific then
                TempItemLedgEntry.TestField("Serial No.");
        until TempItemLedgEntry.Next() = 0;
    end;

    procedure PostItemJnlLineAppliedToList(ItemJnlLine: Record "Item Journal Line"; var TempApplyToItemLedgEntry: Record "Item Ledger Entry" temporary; UndoQty: Decimal; UndoQtyBase: Decimal; var TempItemLedgEntry: Record "Item Ledger Entry" temporary; var TempItemEntryRelation: Record "Item Entry Relation" temporary)
    begin
        PostItemJnlLineAppliedToList(ItemJnlLine, TempApplyToItemLedgEntry, UndoQty, UndoQtyBase, TempItemLedgEntry, TempItemEntryRelation, false);
    end;

    procedure PostItemJnlLineAppliedToList(ItemJnlLine: Record "Item Journal Line"; var TempApplyToItemLedgEntry: Record "Item Ledger Entry" temporary; UndoQty: Decimal; UndoQtyBase: Decimal; var TempItemLedgEntry: Record "Item Ledger Entry" temporary; var TempItemEntryRelation: Record "Item Entry Relation" temporary; InvoicedEntry: Boolean)
    var
        ItemApplicationEntry: Record "Item Application Entry";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        NonDistrQuantity: Decimal;
        NonDistrQuantityBase: Decimal;
    begin
        if InvoicedEntry then begin
            TempApplyToItemLedgEntry.SetRange("Completely Invoiced", false);
            if TempApplyToItemLedgEntry.IsEmpty then begin
                TempApplyToItemLedgEntry.SetRange("Completely Invoiced");
                exit;
            end;
        end;
        TempApplyToItemLedgEntry.Find('-'); // Assertion: will fail if not found.
        if ItemJnlLine."Job No." = '' then
            ItemJnlLine.TestField(Correction, true);
        NonDistrQuantity := -UndoQty;
        NonDistrQuantityBase := -UndoQtyBase;
        repeat
            if ItemJnlLine."Job No." = '' then
                ItemJnlLine."Applies-to Entry" := TempApplyToItemLedgEntry."Entry No."
            else
                ItemJnlLine."Applies-to Entry" := 0;

            ItemJnlLine."Item Shpt. Entry No." := 0;
            ItemJnlLine."Quantity (Base)" := -TempApplyToItemLedgEntry.Quantity;
            ItemJnlLine.CopyTrackingFromItemLedgEntry(TempApplyToItemLedgEntry);

            // Quantity is filled in according to UOM:
            ItemTrackingMgt.AdjustQuantityRounding(
              NonDistrQuantity, ItemJnlLine.Quantity,
              NonDistrQuantityBase, ItemJnlLine."Quantity (Base)");

            NonDistrQuantity := NonDistrQuantity - ItemJnlLine.Quantity;
            NonDistrQuantityBase := NonDistrQuantityBase - ItemJnlLine."Quantity (Base)";

            OnBeforePostItemJnlLine(ItemJnlLine, TempApplyToItemLedgEntry);
            PostItemJnlLine(ItemJnlLine);

            UndoValuePostingFromJob(ItemJnlLine, ItemApplicationEntry, TempApplyToItemLedgEntry);

            TempItemEntryRelation."Item Entry No." := ItemJnlLine."Item Shpt. Entry No.";
            TempItemEntryRelation.CopyTrackingFromItemJnlLine(ItemJnlLine);
            OnPostItemJnlLineAppliedToListOnBeforeTempItemEntryRelationInsert(TempItemEntryRelation, ItemJnlLine);
            TempItemEntryRelation.Insert();
            TempItemLedgEntry := TempApplyToItemLedgEntry;
            TempItemLedgEntry.Insert();
        until TempApplyToItemLedgEntry.Next() = 0;
    end;

    procedure CollectItemLedgEntries(var TempItemLedgEntry: Record "Item Ledger Entry" temporary; SourceType: Integer; DocumentNo: Code[20]; LineNo: Integer; BaseQty: Decimal; EntryRef: Integer)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
    begin
        TempItemLedgEntry.Reset();
        if not TempItemLedgEntry.IsEmpty then
            TempItemLedgEntry.DeleteAll();
        if EntryRef <> 0 then begin
            ItemLedgEntry.Get(EntryRef); // Assertion: will fail if no entry exists.
            TempItemLedgEntry := ItemLedgEntry;
            TempItemLedgEntry.Insert();
        end else begin
            if SourceType in [DATABASE::"Sales Shipment Line",
                              DATABASE::"Return Shipment Line",
                              DATABASE::"Service Shipment Line",
                              DATABASE::"Posted Assembly Line"]
            then
                BaseQty := BaseQty * -1;
            if not
               ItemTrackingMgt.CollectItemEntryRelation(
                 TempItemLedgEntry, SourceType, 0, DocumentNo, '', 0, LineNo, BaseQty)
            then
                Error(Text013Lbl, LineNo);
        end;
    end;

    local procedure UndoValuePostingFromJob(ItemJnlLine: Record "Item Journal Line"; ItemApplicationEntry: Record "Item Application Entry"; var TempApplyToItemLedgEntry: Record "Item Ledger Entry" temporary)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUndoValuePostingFromJob(ItemJnlLine, IsHandled);
        if IsHandled then
            exit;

        if ItemJnlLine."Job No." <> '' then begin
            Clear(ItemJnlPostLine);
            FindItemReceiptApplication(ItemApplicationEntry, TempApplyToItemLedgEntry."Entry No.");
            ItemJnlPostLine.UndoValuePostingWithJob(TempApplyToItemLedgEntry."Entry No.", ItemApplicationEntry."Outbound Item Entry No.");
            FindItemShipmentApplication(ItemApplicationEntry, ItemJnlLine."Item Shpt. Entry No.");
            ItemJnlPostLine.UndoValuePostingWithJob(ItemApplicationEntry."Inbound Item Entry No.", ItemJnlLine."Item Shpt. Entry No.");
        end;
    end;

    procedure UpdatePurchLine(PurchLine: Record "Purchase Line"; UndoQty: Decimal; UndoQtyBase: Decimal; var TempUndoneItemLedgEntry: Record "Item Ledger Entry" temporary)
    var
        xPurchLine: Record "Purchase Line";
        PurchSetup: Record "Purchases & Payables Setup";
        ReservePurchLine: Codeunit "Purch. Line-Reserve";
    begin
        PurchSetup.Get();
        xPurchLine := PurchLine;
        case PurchLine."Document Type" of
            PurchLine."Document Type"::"Return Order":
                begin
                    PurchLine."Return Qty. Shipped" := PurchLine."Return Qty. Shipped" - UndoQty;
                    PurchLine."Return Qty. Shipped (Base)" := PurchLine."Return Qty. Shipped (Base)" - UndoQtyBase;
                    PurchLine.InitOutstanding();
                    if PurchSetup."Default Qty. to Receive" = PurchSetup."Default Qty. to Receive"::Blank then
                        PurchLine."Qty. to Receive" := 0
                    else
                        PurchLine.InitQtyToShip();
                    PurchLine.UpdateWithWarehouseReceive();
                end;
            PurchLine."Document Type"::Order:
                begin
                    PurchLine."Quantity Received" := PurchLine."Quantity Received" - UndoQty;
                    PurchLine."Qty. Received (Base)" := PurchLine."Qty. Received (Base)" - UndoQtyBase;
                    PurchLine.InitOutstanding();
                    if PurchSetup."Default Qty. to Receive" = PurchSetup."Default Qty. to Receive"::Blank then
                        PurchLine."Qty. to Receive" := 0
                    else
                        PurchLine.InitQtyToReceive();
                    PurchLine.UpdateWithWarehouseReceive();
                end;
            else
                PurchLine.FieldError("Document Type");
        end;
        PurchLine.Modify();
        RevertPostedItemTracking(TempUndoneItemLedgEntry, PurchLine."Expected Receipt Date");
        xPurchLine."Quantity (Base)" := 0;
        ReservePurchLine.VerifyQuantity(PurchLine, xPurchLine);

        OnAfterUpdatePurchline(PurchLine);
    end;

    /// <summary>
    /// UpdateRentalLine.
    /// </summary>
    /// <param name="RentalLine">Record "TWE Rental Line".</param>
    /// <param name="UndoQty">Decimal.</param>
    /// <param name="UndoQtyBase">Decimal.</param>
    /// <param name="TempUndoneItemLedgEntry">Temporary VAR Record "Item Ledger Entry".</param>
    procedure UpdateRentalLine(RentalLine: Record "TWE Rental Line"; UndoQty: Decimal; UndoQtyBase: Decimal; var TempUndoneItemLedgEntry: Record "Item Ledger Entry" temporary)
    var
        xRentalLine: Record "TWE Rental Line";
    //ReserveSalesLine: Codeunit "Sales Line-Reserve";
    begin
        xRentalLine := RentalLine;
        case RentalLine."Document Type" of
            /*                 "Document Type"::"Return Order":
                                begin
                                    "Return Qty. Received" := "Return Qty. Received" - UndoQty;
                                    "Return Qty. Received (Base)" := "Return Qty. Received (Base)" - UndoQtyBase;
                                    OnUpdateSalesLineOnBeforeInitOustanding(SalesLine, UndoQty, UndoQtyBase);
                                    InitOutstanding();
                                    if SalesSetup."Default Quantity to Ship" = SalesSetup."Default Quantity to Ship"::Blank then
                                        "Qty. to Ship" := 0
                                    else
                                        InitQtyToReceive();
                                    UpdateWithWarehouseShip();
                                end; */
            RentalLine."Document Type"::Contract:
                begin
                    RentalLine."Quantity Shipped" := RentalLine."Quantity Shipped" - UndoQty;
                    RentalLine."Qty. Shipped (Base)" := RentalLine."Qty. Shipped (Base)" - UndoQtyBase;
                    OnUpdateRentalLineOnBeforeInitOustanding(RentalLine, UndoQty, UndoQtyBase);
                    RentalLine.InitOutstanding();
                    RentalLine.InitQtyToShip();
                    RentalLine.UpdateWithWarehouseShip();
                end;
            else
                RentalLine.FieldError("Document Type");
        end;
        RentalLine.Modify();
        RevertPostedItemTracking(TempUndoneItemLedgEntry, RentalLine."Shipment Date");
        xRentalLine."Quantity (Base)" := 0;
        //ReserveSalesLine.VerifyQuantity(RentalLine, xRentalLine);

        OnAfterUpdateRentalLine(RentalLine);
    end;

    local procedure RevertPostedItemTracking(var TempItemLedgEntry: Record "Item Ledger Entry" temporary; AvailabilityDate: Date)
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservEntry: Record "Reservation Entry";
        TempReservEntry: Record "Reservation Entry" temporary;
        ReservEngineMgt: Codeunit "Reservation Engine Mgt.";
    begin
        if TempItemLedgEntry.Find('-') then begin
            repeat
                TrackingSpecification.Get(TempItemLedgEntry."Entry No.");

                ReservEntry.Init();
                ReservEntry.TransferFields(TrackingSpecification);
                ReservEntry.Validate("Quantity (Base)");
                ReservEntry."Reservation Status" := ReservEntry."Reservation Status"::Surplus;
                if ReservEntry.Positive then
                    ReservEntry."Expected Receipt Date" := AvailabilityDate
                else
                    ReservEntry."Shipment Date" := AvailabilityDate;
                ReservEntry."Entry No." := 0;
                ReservEntry.UpdateItemTracking();
                ReservEntry.Insert();

                TempReservEntry := ReservEntry;
                TempReservEntry.Insert();

                TrackingSpecification.Delete();
            until TempItemLedgEntry.Next() = 0;
            ReservEngineMgt.UpdateOrderTracking(TempReservEntry);
        end;
        OnAfterRevertPostedItemTracking(TempReservEntry);
    end;

    /// <summary>
    /// PostItemJnlLine.
    /// </summary>
    /// <param name="ItemJnlLine">VAR Record "Item Journal Line".</param>
    procedure PostItemJnlLine(var ItemJnlLine: Record "Item Journal Line")
    var
        ItemJnlLine2: Record "Item Journal Line";
        PostJobConsumptionBeforePurch: Boolean;
        IsHandled: Boolean;
    begin
        Clear(ItemJnlLine2);
        ItemJnlLine2 := ItemJnlLine;

        if ItemJnlLine2."Job No." <> '' then begin
            IsHandled := false;
            OnPostItemJnlLineOnBeforePostItemJnlLineForJob(ItemJnlLine2, IsHandled);
            if not IsHandled then
                PostJobConsumptionBeforePurch := PostItemJnlLineForJob(ItemJnlLine, ItemJnlLine2);
        end;

        ItemJnlPostLine.Run(ItemJnlLine);

        IsHandled := false;
        OnPostItemJnlLineOnBeforePostJobConsumption(ItemJnlLine2, IsHandled);
        if not IsHandled then
            if ItemJnlLine2."Job No." <> '' then
                if not PostJobConsumptionBeforePurch then begin
                    SetItemJnlLineAppliesToEntry(ItemJnlLine2, ItemJnlLine."Item Shpt. Entry No.");
                    ItemJnlPostLine.Run(ItemJnlLine2);
                end;
    end;

    local procedure PostItemJnlLineForJob(var ItemJnlLine: Record "Item Journal Line"; var ItemJnlLine2: Record "Item Journal Line"): Boolean
    var
        Job: Record Job;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostItemJnlLineForJob(ItemJnlLine, IsHandled);
        if IsHandled then
            exit;

        ItemJnlLine2."Entry Type" := ItemJnlLine2."Entry Type"::"Negative Adjmt.";
        Job.Get(ItemJnlLine2."Job No.");
        ItemJnlLine2."Source No." := Job."Bill-to Customer No.";
        ItemJnlLine2."Source Type" := ItemJnlLine2."Source Type"::Customer;
        ItemJnlLine2."Discount Amount" := 0;
        if ItemJnlLine2.IsPurchaseReturn() then begin
            ItemJnlPostLine.Run(ItemJnlLine2);
            SetItemJnlLineAppliesToEntry(ItemJnlLine, ItemJnlLine2."Item Shpt. Entry No.");
            exit(true);
        end;
        exit(false);
    end;

    local procedure SetItemJnlLineAppliesToEntry(var ItemJnlLine: Record "Item Journal Line"; AppliesToEntry: Integer)
    var
        Item: Record Item;
    begin
        Item.Get(ItemJnlLine."Item No.");
        if Item.Type = Item.Type::Inventory then
            ItemJnlLine."Applies-to Entry" := AppliesToEntry;
    end;

    /// <summary>
    /// TransferSourceValues.
    /// </summary>
    /// <param name="ItemJnlLine">VAR Record "Item Journal Line".</param>
    /// <param name="EntryNo">Integer.</param>
    procedure TransferSourceValues(var ItemJnlLine: Record "Item Journal Line"; EntryNo: Integer)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
    begin
        ItemLedgEntry.Get(EntryNo);
        ItemJnlLine."Source Type" := ItemLedgEntry."Source Type";
        ItemJnlLine."Source No." := ItemLedgEntry."Source No.";
        ItemJnlLine."Country/Region Code" := ItemLedgEntry."Country/Region Code";

        ValueEntry.SetRange("Item Ledger Entry No.", EntryNo);
        ValueEntry.FindFirst();
        ItemJnlLine."Source Posting Group" := ValueEntry."Source Posting Group";
        ItemJnlLine."Salespers./Purch. Code" := ValueEntry."Salespers./Purch. Code";
    end;

    /// <summary>
    /// ReapplyJobConsumption.
    /// </summary>
    /// <param name="ItemRcptEntryNo">Integer.</param>
    procedure ReapplyJobConsumption(ItemRcptEntryNo: Integer)
    var
        ItemApplnEntry: Record "Item Application Entry";
        ItemLedgEntry: Record "Item Ledger Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeReapplyJobConsumption(ItemRcptEntryNo, IsHandled);
        if IsHandled then
            exit;

        // Purchase receipt and job consumption are reapplied with with fixed cost application
        FindItemReceiptApplication(ItemApplnEntry, ItemRcptEntryNo);
        ItemJnlPostLine.UnApply(ItemApplnEntry);
        ItemLedgEntry.Get(ItemApplnEntry."Inbound Item Entry No.");
        ItemJnlPostLine.ReApply(ItemLedgEntry, ItemApplnEntry."Outbound Item Entry No.");
    end;

    /// <summary>
    /// FindItemReceiptApplication.
    /// </summary>
    /// <param name="ItemApplnEntry">VAR Record "Item Application Entry".</param>
    /// <param name="ItemRcptEntryNo">Integer.</param>
    procedure FindItemReceiptApplication(var ItemApplnEntry: Record "Item Application Entry"; ItemRcptEntryNo: Integer)
    begin
        ItemApplnEntry.Reset();
        ItemApplnEntry.SetRange("Inbound Item Entry No.", ItemRcptEntryNo);
        ItemApplnEntry.SetFilter("Item Ledger Entry No.", '<>%1', ItemRcptEntryNo);
        ItemApplnEntry.FindFirst();
    end;

    /// <summary>
    /// FindItemShipmentApplication.
    /// </summary>
    /// <param name="ItemApplnEntry">VAR Record "Item Application Entry".</param>
    /// <param name="ItemShipmentEntryNo">Integer.</param>
    procedure FindItemShipmentApplication(var ItemApplnEntry: Record "Item Application Entry"; ItemShipmentEntryNo: Integer)
    begin
        ItemApplnEntry.Reset();
        ItemApplnEntry.SetRange("Item Ledger Entry No.", ItemShipmentEntryNo);
        ItemApplnEntry.FindFirst();
    end;

    /// <summary>
    /// UpdatePurchaseLineOverRcptQty.
    /// </summary>
    /// <param name="PurchaseLine">Record "Purchase Line".</param>
    /// <param name="OverRcptQty">Decimal.</param>
    [Scope('OnPrem')]
    procedure UpdatePurchaseLineOverRcptQty(PurchaseLine: Record "Purchase Line"; OverRcptQty: Decimal)
    begin
        PurchaseLine.Get(PurchaseLine."Document Type"::Order, PurchaseLine."Document No.", PurchaseLine."Line No.");
        PurchaseLine."Over-Receipt Quantity" += OverRcptQty;
        PurchaseLine.Modify();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRevertPostedItemTracking(var TempReservEntry: Record "Reservation Entry" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateRentalLine(var RentalLine: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdatePurchline(var PurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostItemJnlLine(var ItemJournalLine: Record "Item Journal Line"; TempApplyToItemLedgEntry: Record "Item Ledger Entry" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostItemJnlLineForJob(var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReapplyJobConsumption(ItemRcptEntryNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestAllTransactions(UndoType: Integer; UndoID: Code[20]; UndoLineNo: Integer; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestPostedInvtPickLine(UndoLineNo: Integer; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestPostedInvtPutAwayLine(UndoLineNo: Integer; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestPostedWhseShipmentLine(UndoLineNo: Integer; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestRgstrdWhseActivityLine(UndoLineNo: Integer; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestWarehouseActivityLine(UndoType: Option; UndoLineNo: Integer; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestWarehouseEntry(UndoLineNo: Integer; var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestWarehouseReceiptLine(UndoLineNo: Integer; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestWarehouseShipmentLine(UndoLineNo: Integer; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestWhseWorksheetLine(UndoLineNo: Integer; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUndoValuePostingFromJob(var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckItemLedgEntriesOnBeforeCheckTempItemLedgEntry(var TempItemLedgEntry: Record "Item Ledger Entry" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemJnlLineAppliedToListOnBeforeTempItemEntryRelationInsert(var TempItemEntryRelation: Record "Item Entry Relation" temporary; ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateRentalLineOnBeforeInitOustanding(var RentalLine: Record "TWE Rental Line"; var UndoQty: Decimal; var UndoQtyBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemJnlLineOnBeforePostJobConsumption(var ItemJnlLine2: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemJnlLineOnBeforePostItemJnlLineForJob(var ItemJnlLine2: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;
}

