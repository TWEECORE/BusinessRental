/// <summary>
/// Report TWE Conv. Rent. Item into Item (ID 50004).
/// </summary>
report 50004 "TWE Conv. Rent. Item into Item"
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
                RentalSetup.Get();
            end;

            trigger OnAfterGetRecord()
            var
                postingQuantity: Integer;
            begin
                postingQuantity := 1;

                if not PostWarehouseAccess(ItemNoCode, LocationCodeGlobal, postingQuantity) then
                    Error(CouldNotBePostedErr);
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
                    field(LocationCode; LocationCodeGlobal)
                    {
                        ApplicationArea = All;
                        Caption = 'Location Code';
                        TableRelation = Location.Code;
                        ToolTip = 'Defines the location code.';
                    }
                }
            }
        }
    }

    var
        RentalSetup: Record "TWE Rental Setup";
        ItemNoCode: Code[20];
        LocationCodeGlobal: Code[20];
        CouldNotBePostedErr: Label 'No posting could be made. Please check the item journal.';

    local procedure PostWarehouseAccess(ItemNoPar: Code[20]; LocationCodePar: Code[20]; QtyPar: Integer) Success: Boolean
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
        ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::"Positive Adjmt.");
        ItemJnlLine.Validate("Document No.", DocumentNo);
        ItemJnlLine.Validate("Item No.", ItemNoPar);
        ItemJnlLine.Validate("Location Code", LocationCodePar);
        ItemJnlLine.Validate(Quantity, QtyPar);
        ItemJnlLine.Validate("Gen. Bus. Posting Group", RentalSetup."Stand. Gen. Bus. Posting Group");
        ItemJnlLine.Modify();
        Commit();
        Success := ItemJnlPost.Run(ItemJnlLine);
        //Success := CODEUNIT.Run(CODEUNIT::"Item Jnl.-Post", ItemJnlLine);
        exit(Success);
    end;

    /// <summary>
    /// SetItemNo.
    /// </summary>
    /// <param name="ItemNoPar">Code[20].</param>
    procedure SetRentalItemNo(RentalItemNoPar: Code[20])
    begin
        ItemNoCode := RentalItemNoPar;
    end;
}
