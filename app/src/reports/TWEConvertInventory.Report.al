/// <summary>
/// Report TWE Convert Inventory (ID 50003).
/// </summary>
report 50003 "TWE Convert Inventory"
{
    UsageCategory = Tasks;
    ApplicationArea = All;
    ProcessingOnly = true;

    dataset
    {
        dataitem(Integer; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = CONST(1));

            trigger OnPreDataItem()
            begin
                InventoryQuantity := 0;
                RentalSetup.Get();
            end;

            trigger OnAfterGetRecord()
            var
                postingQuantity: Integer;
                i: Integer;
            begin
                InventoryQuantity := GetInventoryQuantity(ItemNoCode);
                if DesiredQuantityInt > InventoryQuantity then
                    Error(QtyErr, DesiredQuantityInt, InventoryQuantity);

                ItemLedgerEntry.SetCurrentKey("Entry No.");
                ItemLedgerEntry.SetRange("Item No.", ItemNoCode);
                ItemLedgerEntry.SetFilter("Remaining Quantity", '<>%1', 0);
                ItemLedgerEntry.SetRange(Open, true);
                if ItemLedgerEntry.FindSet() then begin
                    repeat
                        if ItemLedgerEntry."Remaining Quantity" <= (DesiredQuantityInt - DesiredQtyCounter) then
                            postingQuantity := ItemLedgerEntry."Remaining Quantity"
                        else
                            postingQuantity := DesiredQuantityInt - DesiredQtyCounter;

                        if not PostWarehouseOutflow(ItemNoCode, ItemLedgerEntry."Location Code", postingQuantity) then
                            Error(CouldNotBePostedErr);
                        DesiredQtyCounter += postingQuantity;
                    until (DesiredQtyCounter = DesiredQuantityInt) or (ItemLedgerEntry.Next() = 0);

                    for i := 1 to DesiredQuantityInt do
                        InsertNewRentalItem(MainRentalItemNo);

                end;
            end;

        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                group(Options)
                {
                    field(DesiredQuantity; DesiredQuantityInt)
                    {
                        ApplicationArea = All;
                        Caption = 'Quantity';
                        ToolTip = 'Defines the desired amount.';
                    }
                    field(ItemNo; ItemNoCode)
                    {
                        ApplicationArea = All;
                        Caption = 'Item No.';
                        TableRelation = Item."No.";
                        ToolTip = 'Defines the actual item no.';
                    }
                }
            }
        }
    }

    var
        RentalSetup: Record "TWE Rental Setup";
        ItemLedgerEntry: Record "Item Ledger Entry";
        DesiredQuantityInt: Integer;
        InventoryQuantity: Integer;
        DesiredQtyCounter: Integer;
        ItemNoCode: Code[20];
        MainRentalItemNo: Code[20];
        QtyErr: Label 'The desired quantity (%1) exceeds the currently available quantity (%2).', Comment = '%1 desired quantity, %2 available quantity.';
        CouldNotBePostedErr: Label 'No posting could be made. Please check the item journal.';

    local procedure GetInventoryQuantity(ItemNoPar: Code[20]) QtyR: Integer;

    var
        localItemLedgEntries: Record "Item Ledger Entry";
        localQty: Integer;
    begin
        QtyR := 0;
        localItemLedgEntries.SetRange("Item No.", ItemNoPar);
        localItemLedgEntries.SetFilter("Remaining Quantity", '<>%1', 0);
        localItemLedgEntries.SetRange(Open, true);
        if localItemLedgEntries.FindSet() then
            repeat
                localQty += localItemLedgEntries."Remaining Quantity";
            until localItemLedgEntries.Next() = 0;

        exit(localQty);
    end;

    local procedure InsertNewRentalItem(MainRentalItemNoPar: Code[20])
    var
        RentalItem: Record "Service Item";
        MainRentalItem: Record "TWE Main Rental Item";
        RentalSetup: Record "TWE Rental Setup";
        FixedAsset: Record "Fixed Asset";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        MainRentalItemNotFoundErr: Label 'Main Rental Item not found.';
    begin
        RentalSetup.Get();
        if MainRentalItem.Get(MainRentalItemNoPar) then begin
            RentalItem.Init();
            RentalItem."No." := NoSeriesMgt.GetNextNo(RentalSetup."Rental Item Nos.", WorkDate(), true);
            RentalItem.Insert(true);
            RentalItem.Validate("TWE Rental Item", true);
            RentalItem.Validate("TWE Main Rental Item", MainRentalItem."No.");
            RentalItem.Validate("TWE Main Rental Item Desc.", MainRentalItem.Description);
            RentalItem.Validate("Sales Unit Price", MainRentalItem."Unit Price");
            RentalItem.Validate("Sales Unit Cost", MainRentalItem."Unit Cost");
            RentalItem.Validate(Description, MainRentalItem.Description);
            RentalItem.Validate("Description 2", MainRentalItem.Description);
            RentalItem.Modify();

            if RentalSetup."Auto. Creation of Assets" then begin
                FixedAsset.Init();
                FixedAsset."No." := '';
                FixedAsset.Insert(true);
                FixedAsset.Validate(Description, RentalItem.Description);
                FixedAsset.Validate("TWE Rental Item No.", RentalItem."No.");
                //FixedAsset.Validate("FA Posting Group", RentalSetup."Standard Asset Posting Group");
                FixedAsset.Validate("FA Location Code", RentalSetup."Stand. Asset Location Code");
                FixedAsset.Validate("FA Subclass Code", RentalSetup."Stand. Asset Subclass Code");
                //FixedAsset.Validate("FA Class Code", RentalSetup."Stand. Asset Class Code");
                FixedAsset.Modify();
            end;
        end else
            Error(MainRentalItemNotFoundErr);
    end;

    local procedure PostWarehouseOutflow(ItemNoPar: Code[20]; LocationCodePar: Code[20]; QtyPar: Integer) Success: Boolean
    var
        ItemJnlLine: Record "Item Journal Line";
        LastItemJnlLine: Record "Item Journal Line";
        ItemJnlBatch: Record "Item Journal Batch";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        ItemJnlPost: Codeunit "Item Jnl.-Post";
        LastLineNo: Integer;
        DocumentNo: Code[20];
    begin
        LastItemJnlLine.SetRange("Journal Batch Name", 'STANDARD');
        LastItemJnlLine.SetRange("Journal Template Name", 'ARTIKEL');
        if LastItemJnlLine.FindLast() then
            LastLineNo := LastItemJnlLine."Line No.";

        if ItemJnlBatch.Get('ARTIKEL', 'STANDARD') then
            DocumentNo := NoSeriesMgt.GetNextNo(ItemJnlBatch."No. Series", WorkDate(), false);

        ItemJnlLine.Init();
        ItemJnlLine.Validate("Journal Template Name", 'ARTIKEL');
        ItemJnlLine.Validate("Journal Batch Name", 'STANDARD');
        ItemJnlLine.Validate("Line No.", LastLineNo + 10000);
        ItemJnlLine.Insert();
        ItemJnlLine.Validate("Posting Date", WorkDate());
        ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::"Negative Adjmt.");
        ItemJnlLine.Validate("Gen. Bus. Posting Group", RentalSetup."Stand. Gen. Bus. Posting Group");
        ItemJnlLine.Validate("Document No.", DocumentNo);
        ItemJnlLine.Validate("Item No.", ItemNoPar);
        ItemJnlLine.Validate("Location Code", LocationCodePar);
        ItemJnlLine.Validate(Quantity, QtyPar);
        ItemJnlLine.Modify();
        Commit();
        Success := ItemJnlPost.Run(ItemJnlLine);
        //Success := CODEUNIT.Run(CODEUNIT::"Item Jnl.-Post Batch", ItemJnlLine);
        exit(Success);
    end;

    /// <summary>
    /// SetMainRentalItemNo.
    /// </summary>
    /// <param name="MainRentalItemNoPar">Code[20].</param>
    procedure SetMainRentalItemNo(MainRentalItemNoPar: Code[20])
    begin
        MainRentalItemNo := MainRentalItemNoPar;
    end;

    /// <summary>
    /// SetItemNo.
    /// </summary>
    /// <param name="ItemNoPar">Code[20].</param>
    procedure SetItemNo(ItemNoPar: Code[20])
    begin
        ItemNoCode := ItemNoPar;
    end;

    /// <summary>
    /// SetQty.
    /// </summary>
    /// <param name="QuantityPar">Integer.</param>
    procedure SetQty(QuantityPar: Integer)
    begin
        DesiredQuantityInt := QuantityPar;
    end;

}
