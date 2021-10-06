/// <summary>
/// Codeunit TWE Rental Item Jnl. Mgt. (ID 50026).
/// </summary>
codeunit 50026 "TWE Rental Item Jnl. Mgt."
{
    Permissions = TableData "Item Journal Template" = imd,
                  TableData "TWE Rental Item Journal Batch" = imd;

    var
        Text000Lbl: Label '%1 journal', Comment = '%1 journal type';
        Text001Lbl: Label 'RECURRING';
        Text002Lbl: Label 'Recurring Item Journal';
        Text003Lbl: Label 'DEFAULT';
        Text004Lbl: Label 'Default Journal';
        OldItemNo: Code[20];
        OldCapNo: Code[20];
        OldCapType: Enum "Capacity Type";
        OldProdOrderNo: Code[20];
        OldOperationNo: Code[20];
        Text005Lbl: Label 'REC-';
        Text006Lbl: Label 'Recurring ';
        OpenFromBatch: Boolean;

    /// <summary>
    /// TemplateSelection.
    /// </summary>
    /// <param name="PageID">Integer.</param>
    /// <param name="PageTemplate">Option Item,Transfer,"Phys. Inventory",Revaluation,Consumption,Output,Capacity,"Prod. Order".</param>
    /// <param name="RecurringJnl">Boolean.</param>
    /// <param name="RentalItemJnlLine">VAR Record "TWE Rental Item Journal Line".</param>
    /// <param name="JnlSelected">VAR Boolean.</param>
    procedure TemplateSelection(PageID: Integer; PageTemplate: Option Item,Transfer,"Phys. Inventory",Revaluation,Consumption,Output,Capacity,"Prod. Order"; RecurringJnl: Boolean; var RentalItemJnlLine: Record "TWE Rental Item Journal Line"; var JnlSelected: Boolean)
    var
        ItemJnlTemplate: Record "Item Journal Template";
    begin
        JnlSelected := true;

        ItemJnlTemplate.Reset();
        ItemJnlTemplate.SetRange("Page ID", PageID);
        ItemJnlTemplate.SetRange(Recurring, RecurringJnl);
        ItemJnlTemplate.SetRange(Type, PageTemplate);
        OnTemplateSelectionSetFilter(ItemJnlTemplate, PageTemplate);

        case ItemJnlTemplate.Count of
            0:
                begin
                    ItemJnlTemplate.Init();
                    ItemJnlTemplate.Recurring := RecurringJnl;
                    ItemJnlTemplate.Validate(Type, PageTemplate);
                    ItemJnlTemplate.Validate("Page ID");
                    if not RecurringJnl then begin
                        ItemJnlTemplate.Name := Format(ItemJnlTemplate.Type, MaxStrLen(ItemJnlTemplate.Name));
                        ItemJnlTemplate.Description := StrSubstNo(Text000Lbl, ItemJnlTemplate.Type);
                    end else
                        if ItemJnlTemplate.Type = ItemJnlTemplate.Type::Item then begin
                            ItemJnlTemplate.Name := Text001Lbl;
                            ItemJnlTemplate.Description := Text002Lbl;
                        end else begin
                            ItemJnlTemplate.Name :=
                              Text005Lbl + Format(ItemJnlTemplate.Type, MaxStrLen(ItemJnlTemplate.Name) - StrLen(Text005Lbl));
                            ItemJnlTemplate.Description := Text006Lbl + StrSubstNo(Text000Lbl, ItemJnlTemplate.Type);
                        end;
                    ItemJnlTemplate.Insert();
                    Commit();
                end;
            1:
                ItemJnlTemplate.FindFirst();
            else
                JnlSelected := PAGE.RunModal(0, ItemJnlTemplate) = ACTION::LookupOK;
        end;
        if JnlSelected then begin
            RentalItemJnlLine.FilterGroup := 2;
            RentalItemJnlLine.SetRange("Journal Template Name", ItemJnlTemplate.Name);
            RentalItemJnlLine.FilterGroup := 0;
            if OpenFromBatch then begin
                RentalItemJnlLine."Journal Template Name" := '';
                PAGE.Run(ItemJnlTemplate."Page ID", RentalItemJnlLine);
            end;
        end;
    end;

    /// <summary>
    /// TemplateSelectionFromBatch.
    /// </summary>
    /// <param name="RentalItemJnlBatch">VAR Record "TWE Rental Item Journal Batch".</param>
    procedure TemplateSelectionFromBatch(var RentalItemJnlBatch: Record "TWE Rental Item Journal Batch")
    var
        RentalItemJnlLine: Record "TWE Rental Item Journal Line";
        ItemJnlTemplate: Record "Item Journal Template";
    begin
        OpenFromBatch := true;
        ItemJnlTemplate.Get(RentalItemJnlBatch."Journal Template Name");
        ItemJnlTemplate.TestField("Page ID");
        RentalItemJnlBatch.TestField(Name);

        RentalItemJnlLine.FilterGroup := 2;
        RentalItemJnlLine.SetRange("Journal Template Name", ItemJnlTemplate.Name);
        RentalItemJnlLine.FilterGroup := 0;

        RentalItemJnlLine."Journal Template Name" := '';
        RentalItemJnlLine."Journal Batch Name" := RentalItemJnlBatch.Name;
        PAGE.Run(ItemJnlTemplate."Page ID", RentalItemJnlLine);
    end;

    /// <summary>
    /// OpenJnl.
    /// </summary>
    /// <param name="CurrentJnlBatchName">VAR Code[10].</param>
    /// <param name="RentalItemJnlLine">VAR Record "TWE Rental Item Journal Line".</param>
    procedure OpenJnl(var CurrentJnlBatchName: Code[10]; var RentalItemJnlLine: Record "TWE Rental Item Journal Line")
    begin
        OnBeforeOpenJnl(CurrentJnlBatchName, RentalItemJnlLine);

        CheckTemplateName(RentalItemJnlLine.GetRangeMax("Journal Template Name"), CurrentJnlBatchName);
        RentalItemJnlLine.FilterGroup := 2;
        RentalItemJnlLine.SetRange("Journal Batch Name", CurrentJnlBatchName);
        RentalItemJnlLine.FilterGroup := 0;
    end;

    /// <summary>
    /// OpenJnlBatch.
    /// </summary>
    /// <param name="RentalItemJnlBatch">VAR Record "TWE Rental Item Journal Batch".</param>
    procedure OpenJnlBatch(var RentalItemJnlBatch: Record "TWE Rental Item Journal Batch")
    var
        ItemJnlTemplate: Record "Item Journal Template";
        RentalItemJnlLine: Record "TWE Rental Item Journal Line";
        JnlSelected: Boolean;
    begin
        if RentalItemJnlBatch.GetFilter("Journal Template Name") <> '' then
            exit;
        RentalItemJnlBatch.FilterGroup(2);
        if RentalItemJnlBatch.GetFilter("Journal Template Name") <> '' then begin
            RentalItemJnlBatch.FilterGroup(0);
            exit;
        end;
        RentalItemJnlBatch.FilterGroup(0);

        if not RentalItemJnlBatch.Find('-') then
            for ItemJnlTemplate.Type := ItemJnlTemplate.Type::Item to ItemJnlTemplate.Type::"Prod. Order" do begin
                ItemJnlTemplate.SetRange(Type, ItemJnlTemplate.Type);
                if not ItemJnlTemplate.FindFirst() then
                    TemplateSelection(0, ItemJnlTemplate.Type.AsInteger(), false, RentalItemJnlLine, JnlSelected);
                if ItemJnlTemplate.FindFirst() then
                    CheckTemplateName(ItemJnlTemplate.Name, RentalItemJnlBatch.Name);
                if ItemJnlTemplate.Type in [ItemJnlTemplate.Type::Item,
                                            ItemJnlTemplate.Type::Consumption,
                                            ItemJnlTemplate.Type::Output,
                                            ItemJnlTemplate.Type::Capacity]
                then begin
                    ItemJnlTemplate.SetRange(Recurring, true);
                    if not ItemJnlTemplate.FindFirst() then
                        TemplateSelection(0, ItemJnlTemplate.Type.AsInteger(), true, RentalItemJnlLine, JnlSelected);
                    if ItemJnlTemplate.FindFirst() then
                        CheckTemplateName(ItemJnlTemplate.Name, RentalItemJnlBatch.Name);
                    ItemJnlTemplate.SetRange(Recurring);
                end;
            end;

        RentalItemJnlBatch.Find('-');
        JnlSelected := true;
        RentalItemJnlBatch.CalcFields("Template Type", Recurring);
        ItemJnlTemplate.SetRange(Recurring, RentalItemJnlBatch.Recurring);
        if not RentalItemJnlBatch.Recurring then
            ItemJnlTemplate.SetRange(Type, RentalItemJnlBatch."Template Type");
        if RentalItemJnlBatch.GetFilter("Journal Template Name") <> '' then
            ItemJnlTemplate.SetRange(Name, RentalItemJnlBatch.GetFilter("Journal Template Name"));
        OnOpenJnlBatchOnBeforeCaseSelectItemJnlTemplate(ItemJnlTemplate, RentalItemJnlBatch);
        case ItemJnlTemplate.Count of
            1:
                ItemJnlTemplate.FindFirst();
            else
                JnlSelected := PAGE.RunModal(0, ItemJnlTemplate) = ACTION::LookupOK;
        end;
        if not JnlSelected then
            Error('');

        RentalItemJnlBatch.FilterGroup(0);
        RentalItemJnlBatch.SetRange("Journal Template Name", ItemJnlTemplate.Name);
        RentalItemJnlBatch.FilterGroup(2);
    end;

    procedure CheckTemplateName(CurrentJnlTemplateName: Code[10]; var CurrentJnlBatchName: Code[10])
    var
        ItemJnlBatch: Record "Item Journal Batch";
    begin
        OnBeforeCheckTemplateName(CurrentJnlTemplateName, CurrentJnlBatchName);
        ItemJnlBatch.SetRange("Journal Template Name", CurrentJnlTemplateName);
        if not ItemJnlBatch.Get(CurrentJnlTemplateName, CurrentJnlBatchName) then begin
            if not ItemJnlBatch.FindFirst() then begin
                ItemJnlBatch.Init();
                ItemJnlBatch."Journal Template Name" := CurrentJnlTemplateName;
                ItemJnlBatch.SetupNewBatch();
                ItemJnlBatch.Name := Text003Lbl;
                ItemJnlBatch.Description := Text004Lbl;
                ItemJnlBatch.Insert(true);
                Commit();
            end;
            CurrentJnlBatchName := ItemJnlBatch.Name
        end;
    end;

    /// <summary>
    /// CheckName.
    /// </summary>
    /// <param name="CurrentJnlBatchName">Code[10].</param>
    /// <param name="RentalItemJnlLine">VAR Record "TWE Rental Item Journal Line".</param>
    procedure CheckName(CurrentJnlBatchName: Code[10]; var RentalItemJnlLine: Record "TWE Rental Item Journal Line")
    var
        RentalItemJnlBatch: Record "TWE Rental Item Journal Batch";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckName(CurrentJnlBatchName, RentalItemJnlLine, IsHandled);
        if IsHandled then
            exit;

        RentalItemJnlBatch.Get(RentalItemJnlLine.GetRangeMax("Journal Template Name"), CurrentJnlBatchName);
    end;

    /// <summary>
    /// SetName.
    /// </summary>
    /// <param name="CurrentJnlBatchName">Code[10].</param>
    /// <param name="RentalItemJnlLine">VAR Record "TWE Rental Item Journal Line".</param>
    procedure SetName(CurrentJnlBatchName: Code[10]; var RentalItemJnlLine: Record "TWE Rental Item Journal Line")
    begin
        RentalItemJnlLine.FilterGroup := 2;
        RentalItemJnlLine.SetRange("Journal Batch Name", CurrentJnlBatchName);
        RentalItemJnlLine.FilterGroup := 0;
        if RentalItemJnlLine.Find('-') then;
    end;

    /// <summary>
    /// LookupName.
    /// </summary>
    /// <param name="CurrentJnlBatchName">VAR Code[10].</param>
    /// <param name="RentalItemJnlLine">VAR Record "TWE Rental Item Journal Line".</param>
    procedure LookupName(var CurrentJnlBatchName: Code[10]; var RentalItemJnlLine: Record "TWE Rental Item Journal Line")
    var
        RentalItemJnlBatch: Record "TWE Rental Item Journal Batch";
    begin
        Commit();
        RentalItemJnlBatch."Journal Template Name" := RentalItemJnlLine.GetRangeMax("Journal Template Name");
        RentalItemJnlBatch.Name := RentalItemJnlLine.GetRangeMax("Journal Batch Name");
        RentalItemJnlBatch.FilterGroup(2);
        RentalItemJnlBatch.SetRange("Journal Template Name", RentalItemJnlBatch."Journal Template Name");
        RentalItemJnlBatch.FilterGroup(0);
        OnBeforeLookupName(RentalItemJnlBatch);
        if PAGE.RunModal(0, RentalItemJnlBatch) = ACTION::LookupOK then begin
            CurrentJnlBatchName := RentalItemJnlBatch.Name;
            SetName(CurrentJnlBatchName, RentalItemJnlLine);
        end;
    end;

    /// <summary>
    /// GetItem.
    /// </summary>
    /// <param name="ItemNo">Code[20].</param>
    /// <param name="ItemDescription">VAR Text[100].</param>
    procedure GetItem(ItemNo: Code[20]; var ItemDescription: Text[100])
    var
        Item: Record Item;
    begin
        if ItemNo <> OldItemNo then begin
            ItemDescription := '';
            if ItemNo <> '' then
                if Item.Get(ItemNo) then
                    ItemDescription := Item.Description;
            OldItemNo := ItemNo;
        end;
    end;

    procedure GetConsump(var RentalItemJnlLine: Record "TWE Rental Item Journal Line"; var ProdOrderDescription: Text[100])
    var
        ProdOrder: Record "Production Order";
    begin
        if (RentalItemJnlLine."Order Type" = RentalItemJnlLine."Order Type"::Production) and (RentalItemJnlLine."Order No." <> OldProdOrderNo) then begin
            ProdOrderDescription := '';
            if ProdOrder.Get(ProdOrder.Status::Released, RentalItemJnlLine."Order No.") then
                ProdOrderDescription := ProdOrder.Description;
            OldProdOrderNo := ProdOrder."No.";
        end;
    end;

    /// <summary>
    /// GetOutput.
    /// </summary>
    /// <param name="RentalItemJnlLine">VAR Record "TWE Rental Item Journal Line".</param>
    /// <param name="ProdOrderDescription">VAR Text[100].</param>
    /// <param name="OperationDescription">VAR Text[100].</param>
    procedure GetOutput(var RentalItemJnlLine: Record "TWE Rental Item Journal Line"; var ProdOrderDescription: Text[100]; var OperationDescription: Text[100])
    var
        ProdOrder: Record "Production Order";
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
    begin
        if (RentalItemJnlLine."Operation No." <> OldOperationNo) or
           ((RentalItemJnlLine."Order Type" = RentalItemJnlLine."Order Type"::Production) and (RentalItemJnlLine."Order No." <> OldProdOrderNo))
        then begin
            OperationDescription := '';
            if ProdOrderRtngLine.Get(
                 ProdOrder.Status::Released,
                 RentalItemJnlLine."Order No.",
                 RentalItemJnlLine."Routing Reference No.",
                 RentalItemJnlLine."Routing No.",
                 RentalItemJnlLine."Operation No.")
            then
                OperationDescription := ProdOrderRtngLine.Description;
            OldOperationNo := ProdOrderRtngLine."Operation No.";
        end;

        if (RentalItemJnlLine."Order Type" = RentalItemJnlLine."Order Type"::Production) and (RentalItemJnlLine."Order No." <> OldProdOrderNo) then begin
            ProdOrderDescription := '';
            if ProdOrder.Get(ProdOrder.Status::Released, RentalItemJnlLine."Order No.") then
                ProdOrderDescription := ProdOrder.Description;
            OldProdOrderNo := ProdOrder."No.";
        end;
    end;

    /// <summary>
    /// GetCapacity.
    /// </summary>
    /// <param name="CapType">Enum "Capacity Type".</param>
    /// <param name="CapNo">Code[20].</param>
    /// <param name="CapDescription">VAR Text[100].</param>
    procedure GetCapacity(CapType: Enum "Capacity Type"; CapNo: Code[20]; var CapDescription: Text[100])
    var
        WorkCenter: Record "Work Center";
        MachineCenter: Record "Machine Center";
    begin
        if (CapNo <> OldCapNo) or (CapType <> OldCapType) then begin
            CapDescription := '';
            if CapNo <> '' then
                case CapType of
                    CapType::"Work Center":
                        if WorkCenter.Get(CapNo) then
                            CapDescription := WorkCenter.Name;
                    CapType::"Machine Center":
                        if MachineCenter.Get(CapNo) then
                            CapDescription := MachineCenter.Name;
                end;
            OldCapNo := CapNo;
            OldCapType := CapType;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckName(CurrentJnlBatchName: Code[10]; var RentalItemJnlLine: Record "TWE Rental Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckTemplateName(CurrentJnlTemplateName: Code[10]; var CurrentJnlBatchName: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupName(var RentalItemJnlBatch: Record "TWE Rental Item Journal Batch")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOpenJnl(var CurrentJnlBatchName: Code[10]; var RentalItemJnlLine: Record "TWE Rental Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOpenJnlBatchOnBeforeCaseSelectItemJnlTemplate(var ItemJnlTemplate: Record "Item Journal Template"; var RentalItemJnlBatch: Record "TWE Rental Item Journal Batch")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTemplateSelectionSetFilter(var ItemJnlTemplate: Record "Item Journal Template"; var PageTemplate: Option)
    begin
    end;
}

