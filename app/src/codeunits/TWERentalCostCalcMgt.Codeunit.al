/// <summary>
/// Codeunit TWE Rental Cost Calc. Mgt. (ID 50016).
/// </summary>
codeunit 50016 "TWE Rental Cost Calc. Mgt."
{
    Permissions = TableData "Item Ledger Entry" = r,
                  TableData "Prod. Order Capacity Need" = r,
                  TableData "Value Entry" = r;

    trigger OnRun()
    begin
    end;

    var
        UOMMgt: Codeunit "Unit of Measure Management";

    /// <summary>
    /// CalcRentalLineCostLCY.
    /// </summary>
    /// <param name="RentalLine">Record "TWE Rental Line".</param>
    /// <param name="QtyType">Option General,Invoicing.</param>
    /// <returns>Return variable TotalAdjCostLCY of type Decimal.</returns>
    procedure CalcRentalLineCostLCY(RentalLine: Record "TWE Rental Line"; QtyType: Option General,Invoicing) TotalAdjCostLCY: Decimal
    var
        PostedQtyBase: Decimal;
        RemQtyToCalcBase: Decimal;
    begin
        case RentalLine."Document Type" of
            RentalLine."Document Type"::Contract, RentalLine."Document Type"::Invoice:
                if ((RentalLine."Quantity Shipped" <> 0) or (RentalLine."Shipment No." <> '')) and
                   ((QtyType = QtyType::General) or (RentalLine."Qty. to Invoice" > RentalLine."Qty. to Ship"))
                then
                    CalcRentalLineShptAdjCostLCY(RentalLine, QtyType, TotalAdjCostLCY, PostedQtyBase, RemQtyToCalcBase);
        end;
    end;

    local procedure CalcRentalLineShptAdjCostLCY(RentalLine: Record "TWE Rental Line"; QtyType: Option General,Invoicing; var TotalAdjCostLCY: Decimal; var PostedQtyBase: Decimal; var RemQtyToCalcBase: Decimal)
    var
        RentalShptLine: Record "TWE Rental Shipment Line";
        QtyShippedNotInvcdBase: Decimal;
        AdjCostLCY: Decimal;
    begin
        if RentalLine."Shipment No." <> '' then begin
            RentalShptLine.SetRange("Document No.", RentalLine."Shipment No.");
            RentalShptLine.SetRange("Line No.", RentalLine."Shipment Line No.");
        end else begin
            RentalShptLine.SetCurrentKey("Order No.", "Order Line No.");
            RentalShptLine.SetRange("Order No.", RentalLine."Document No.");
            RentalShptLine.SetRange("Order Line No.", RentalLine."Line No.");
        end;
        RentalShptLine.SetRange(Correction, false);
        if QtyType = QtyType::Invoicing then begin
            RentalShptLine.SetFilter("Qty. Shipped Not Invoiced", '<>0');
            RemQtyToCalcBase := RentalLine."Qty. to Invoice (Base)" - RentalLine."Qty. to Ship (Base)";
        end else
            RemQtyToCalcBase := RentalLine."Quantity (Base)";

        if RentalShptLine.FindSet() then
            repeat
                if RentalShptLine."Qty. per Unit of Measure" = 0 then
                    QtyShippedNotInvcdBase := RentalShptLine."Qty. Shipped Not Invoiced"
                else
                    QtyShippedNotInvcdBase :=
                      Round(RentalShptLine."Qty. Shipped Not Invoiced" * RentalShptLine."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision());

                AdjCostLCY := CalcRentalShptLineCostLCY(RentalShptLine, QtyType);

                case true of
                    QtyType = QtyType::Invoicing:
                        if RemQtyToCalcBase > QtyShippedNotInvcdBase then begin
                            TotalAdjCostLCY := TotalAdjCostLCY + AdjCostLCY;
                            RemQtyToCalcBase := RemQtyToCalcBase - QtyShippedNotInvcdBase;
                            PostedQtyBase := PostedQtyBase + QtyShippedNotInvcdBase;
                        end else begin
                            PostedQtyBase := PostedQtyBase + RemQtyToCalcBase;
                            TotalAdjCostLCY :=
                              TotalAdjCostLCY + AdjCostLCY / QtyShippedNotInvcdBase * RemQtyToCalcBase;
                            RemQtyToCalcBase := 0;
                        end;
                    RentalLine."Shipment No." <> '':
                        begin
                            PostedQtyBase := PostedQtyBase + QtyShippedNotInvcdBase;
                            TotalAdjCostLCY :=
                              TotalAdjCostLCY + AdjCostLCY / RentalShptLine."Quantity (Base)" * RemQtyToCalcBase;
                            RemQtyToCalcBase := 0;
                        end;
                    else begin
                            PostedQtyBase := PostedQtyBase + RentalShptLine."Quantity (Base)";
                            TotalAdjCostLCY := TotalAdjCostLCY + AdjCostLCY;
                        end;
                end;
            until (RentalShptLine.Next() = 0) or (RemQtyToCalcBase = 0);
    end;

    local procedure CalcRentalShptLineCostLCY(RentalShptLine: Record "TWE Rental Shipment Line"; QtyType: Option General,Invoicing,Shipping) AdjCostLCY: Decimal
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        if RentalShptLine.Type = RentalShptLine.Type::"Rental Item" then begin
            RentalShptLine.FilterPstdDocLnItemLedgEntries(ItemLedgEntry);
            if ItemLedgEntry.IsEmpty then
                exit(0);
            AdjCostLCY := CalcPostedDocLineCostLCY(ItemLedgEntry, QtyType);
        end else
            if QtyType = QtyType::Invoicing then
                AdjCostLCY := -RentalShptLine."Qty. Shipped Not Invoiced" * RentalShptLine."Unit Cost (LCY)"
            else
                AdjCostLCY := -RentalShptLine.Quantity * RentalShptLine."Unit Cost (LCY)";
    end;

    local procedure CalcPostedDocLineCostLCY(var ItemLedgEntry: Record "Item Ledger Entry"; QtyType: Option General,Invoicing,Shipping,Consuming) AdjCostLCY: Decimal
    var
        ValueEntry: Record "Value Entry";
    begin
        ItemLedgEntry.FindSet();
        repeat
            if (QtyType = QtyType::Invoicing) or (QtyType = QtyType::Consuming) then begin
                ItemLedgEntry.CalcFields("Cost Amount (Expected)");
                AdjCostLCY := AdjCostLCY + ItemLedgEntry."Cost Amount (Expected)";
            end else begin
                ValueEntry.SetCurrentKey("Item Ledger Entry No.");
                ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgEntry."Entry No.");
                if ValueEntry.FindSet() then
                    repeat
                        if (ValueEntry."Entry Type" <> ValueEntry."Entry Type"::Revaluation) and
                           (ValueEntry."Item Charge No." = '')
                        then
                            AdjCostLCY :=
                              AdjCostLCY + ValueEntry."Cost Amount (Expected)" + ValueEntry."Cost Amount (Actual)";
                    until ValueEntry.Next() = 0;
            end;
        until ItemLedgEntry.Next() = 0;
    end;

    /// <summary>
    /// CalcRentalInvLineCostLCY.
    /// </summary>
    /// <param name="RentalInvLine">Record "TWE Rental Invoice Line".</param>
    /// <returns>Return variable AdjCostLCY of type Decimal.</returns>
    procedure CalcRentalInvLineCostLCY(RentalInvLine: Record "TWE Rental Invoice Line") AdjCostLCY: Decimal
    begin
        if RentalInvLine.Quantity = 0 then
            exit(0);
        AdjCostLCY := RentalInvLine.Quantity * RentalInvLine."Unit Cost (LCY)";
    end;

    /// <summary>
    /// CalcRentalInvLineNonInvtblCostAmt.
    /// </summary>
    /// <param name="RentalInvLine">Record "TWE Rental Invoice Line".</param>
    /// <returns>Return value of type Decimal.</returns>
    procedure CalcRentalInvLineNonInvtblCostAmt(RentalInvLine: Record "TWE Rental Invoice Line"): Decimal
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Document No.", RentalInvLine."Document No.");
        ValueEntry.SetRange("Document Type", ValueEntry."Document Type"::"Rental Invoice");
        ValueEntry.SetRange("Document Line No.", RentalInvLine."Line No.");
        ValueEntry.CalcSums("Cost Amount (Non-Invtbl.)");
        exit(-ValueEntry."Cost Amount (Non-Invtbl.)");
    end;

    /// <summary>
    /// CalcRentalCrMemoLineCostLCY.
    /// </summary>
    /// <param name="RentalCrMemoLine">Record "TWE Rental Cr.Memo Line".</param>
    /// <returns>Return variable AdjCostLCY of type Decimal.</returns>
    procedure CalcRentalCrMemoLineCostLCY(RentalCrMemoLine: Record "TWE Rental Cr.Memo Line") AdjCostLCY: Decimal
    begin
        if RentalCrMemoLine.Quantity = 0 then
            exit(0);

        AdjCostLCY := RentalCrMemoLine.Quantity * RentalCrMemoLine."Unit Cost (LCY)";
    end;

    /// <summary>
    /// CalcRentalCrMemoLineNonInvtblCostAmt.
    /// </summary>
    /// <param name="RentalCrMemoLine">Record "TWE Rental Cr.Memo Line".</param>
    /// <returns>Return value of type Decimal.</returns>
    procedure CalcRentalCrMemoLineNonInvtblCostAmt(RentalCrMemoLine: Record "TWE Rental Cr.Memo Line"): Decimal
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Document No.", RentalCrMemoLine."Document No.");
        ValueEntry.SetRange("Document Type", ValueEntry."Document Type"::"Rental Credit Memo");
        ValueEntry.SetRange("Document Line No.", RentalCrMemoLine."Line No.");
        ValueEntry.CalcSums("Cost Amount (Non-Invtbl.)");
        exit(ValueEntry."Cost Amount (Non-Invtbl.)");
    end;

    /// <summary>
    /// GetDocType.
    /// </summary>
    /// <param name="TableNo">Integer.</param>
    /// <returns>Return value of type Integer.</returns>
    procedure GetDocType(TableNo: Integer): Integer
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        case TableNo of
            DATABASE::"Purch. Rcpt. Header":
                exit(ItemLedgEntry."Document Type"::"Purchase Receipt".AsInteger());
            DATABASE::"Purch. Inv. Header":
                exit(ItemLedgEntry."Document Type"::"Purchase Invoice".AsInteger());
            DATABASE::"Purch. Cr. Memo Hdr.":
                exit(ItemLedgEntry."Document Type"::"Purchase Credit Memo".AsInteger());
            DATABASE::"Return Shipment Header":
                exit(ItemLedgEntry."Document Type"::"Purchase Return Shipment".AsInteger());
            DATABASE::"Sales Shipment Header":
                exit(ItemLedgEntry."Document Type"::"Sales Shipment".AsInteger());
            DATABASE::"Sales Invoice Header":
                exit(ItemLedgEntry."Document Type"::"Sales Invoice".AsInteger());
            DATABASE::"Sales Cr.Memo Header":
                exit(ItemLedgEntry."Document Type"::"Sales Credit Memo".AsInteger());
            DATABASE::"Return Receipt Header":
                exit(ItemLedgEntry."Document Type"::"Sales Return Receipt".AsInteger());
            DATABASE::"Transfer Shipment Header":
                exit(ItemLedgEntry."Document Type"::"Transfer Shipment".AsInteger());
            DATABASE::"Transfer Receipt Header":
                exit(ItemLedgEntry."Document Type"::"Transfer Receipt".AsInteger());
            DATABASE::"Posted Assembly Header":
                exit(ItemLedgEntry."Document Type"::"Posted Assembly".AsInteger());
        end;
    end;
}

