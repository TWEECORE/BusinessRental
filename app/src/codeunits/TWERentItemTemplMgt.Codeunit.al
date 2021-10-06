/// <summary>
/// Codeunit TWE Rent. Item Templ. Mgt. (ID 50065).
/// </summary>
codeunit 50065 "TWE Rent. Item Templ. Mgt."
{
    trigger OnRun()
    begin
    end;

    var
        VATPostingSetupErr: Label 'VAT Posting Setup does not exist. "VAT Bus. Posting Group" = %1, "VAT Prod. Posting Group" = %2.', Comment = '%1 - vat bus. posting group code; %2 - vat prod. posting group code';

    /// <summary>
    /// CreateItemFromTemplate.
    /// </summary>
    /// <param name="TWEMainRentalItem">VAR Record TWE Main Rental Item.</param>
    /// <param name="IsHandled">VAR Boolean.</param>
    /// <returns>Return value of type Boolean.</returns>
    procedure CreateItemFromTemplate(var TWEMainRentalItem: Record "TWE Main Rental Item"; var IsHandled: Boolean): Boolean
    var
        ItemTempl: Record "Item Templ.";
    begin
        if not IsEnabled() then
            exit(false);

        IsHandled := true;

        if not SelectItemTemplate(ItemTempl) then
            exit(false);

        TWEMainRentalItem.Init();
        TWEMainRentalItem.Insert(true);

        ApplyItemTemplate(TWEMainRentalItem, ItemTempl);

        exit(true);
    end;

    /// <summary>
    /// ApplyItemTemplate.
    /// </summary>
    /// <param name="TWEMainRentalItem">VAR Record "TWE Main Rental Item".</param>
    /// <param name="ItemTempl">Record "Item Templ.".</param>
    procedure ApplyItemTemplate(var TWEMainRentalItem: Record "TWE Main Rental Item"; ItemTempl: Record "Item Templ.")
    begin
        ApplyTemplate(TWEMainRentalItem, ItemTempl);
        InsertDimensions(TWEMainRentalItem."No.", ItemTempl.Code);
    end;

    local procedure ApplyTemplate(var TWEMainRentalItem: Record "TWE Main Rental Item"; ItemTempl: Record "Item Templ.")
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        TWEMainRentalItem."Inventory Posting Group" := ItemTempl."Inventory Posting Group";
        //TWEMainRentalItem."Item Disc. Group" := ItemTempl."Item Disc. Group";
        TWEMainRentalItem."Allow Invoice Disc." := ItemTempl."Allow Invoice Disc.";
        TWEMainRentalItem."Price/Profit Calculation" := ItemTempl."Price/Profit Calculation";
        TWEMainRentalItem."Profit %" := ItemTempl."Profit %";
        TWEMainRentalItem."Costing Method" := ItemTempl."Costing Method";
        TWEMainRentalItem."Indirect Cost %" := ItemTempl."Indirect Cost %";
        TWEMainRentalItem."Gen. Prod. Posting Group" := ItemTempl."Gen. Prod. Posting Group";
        TWEMainRentalItem."Automatic Ext. Texts" := ItemTempl."Automatic Ext. Texts";
        TWEMainRentalItem."Tax Group Code" := ItemTempl."Tax Group Code";
        TWEMainRentalItem."VAT Prod. Posting Group" := ItemTempl."VAT Prod. Posting Group";
        TWEMainRentalItem."Item Category Code" := ItemTempl."Item Category Code";
        TWEMainRentalItem."Service Item Group" := ItemTempl."Service Item Group";
        //TWEMainRentalItem."Warehouse Class Code" := ItemTempl."Warehouse Class Code";
        TWEMainRentalItem.Blocked := ItemTempl.Blocked;
        TWEMainRentalItem."Sales Blocked" := ItemTempl."Sales Blocked";
        TWEMainRentalItem."Purchasing Blocked" := ItemTempl."Purchasing Blocked";
        TWEMainRentalItem.Validate("Base Unit of Measure", ItemTempl."Base Unit of Measure");
        if ItemTempl."Price Includes VAT" then begin
            SalesReceivablesSetup.Get();
            if not VATPostingSetup.Get(SalesReceivablesSetup."VAT Bus. Posting Gr. (Price)", ItemTempl."VAT Prod. Posting Group") then
                Error(VATPostingSetupErr, SalesReceivablesSetup."VAT Bus. Posting Gr. (Price)", ItemTempl."VAT Prod. Posting Group");
            TWEMainRentalItem.Validate("Price Includes VAT", ItemTempl."Price Includes VAT");
        end;
        OnApplyTemplateOnBeforeItemModify(TWEMainRentalItem, ItemTempl);
        TWEMainRentalItem.Modify(true);
    end;

    local procedure SelectItemTemplate(var ItemTempl: Record "Item Templ."): Boolean
    var
        SelectItemTemplList: Page "Select Item Templ. List";
    begin
        if ItemTempl.Count = 1 then begin
            ItemTempl.FindFirst();
            exit(true);
        end;

        if (ItemTempl.Count > 1) and GuiAllowed then begin
            SelectItemTemplList.SetTableView(ItemTempl);
            SelectItemTemplList.LookupMode(true);
            if SelectItemTemplList.RunModal() = Action::LookupOK then begin
                SelectItemTemplList.GetRecord(ItemTempl);
                exit(true);
            end;
        end;

        exit(false);
    end;

    local procedure InsertDimensions(ItemNo: Code[20]; ItemTemplCode: Code[20])
    var
        SourceDefaultDimension: Record "Default Dimension";
        DestDefaultDimension: Record "Default Dimension";
    begin
        SourceDefaultDimension.SetRange("Table ID", Database::"Item Templ.");
        SourceDefaultDimension.SetRange("No.", ItemTemplCode);
        if SourceDefaultDimension.FindSet() then
            repeat
                DestDefaultDimension.Init();
                DestDefaultDimension.Validate("Table ID", Database::Item);
                DestDefaultDimension.Validate("No.", ItemNo);
                DestDefaultDimension.Validate("Dimension Code", SourceDefaultDimension."Dimension Code");
                DestDefaultDimension.Validate("Dimension Value Code", SourceDefaultDimension."Dimension Value Code");
                DestDefaultDimension.Validate("Value Posting", SourceDefaultDimension."Value Posting");
                if not DestDefaultDimension.Get(DestDefaultDimension."Table ID", DestDefaultDimension."No.", DestDefaultDimension."Dimension Code") then
                    DestDefaultDimension.Insert(true);
            until SourceDefaultDimension.Next() = 0;
    end;

    /// <summary>
    /// ItemTemplatesAreNotEmpty.
    /// </summary>
    /// <param name="IsHandled">VAR Boolean.</param>
    /// <returns>Return value of type Boolean.</returns>
    procedure ItemTemplatesAreNotEmpty(var IsHandled: Boolean): Boolean
    var
        ItemTempl: Record "Item Templ.";
        TemplateFeatureMgt: Codeunit "Template Feature Mgt.";
    begin
        if not TemplateFeatureMgt.IsEnabled() then
            exit(false);

        IsHandled := true;
        exit(not ItemTempl.IsEmpty);
    end;

    /// <summary>
    /// InsertItemFromTemplate.
    /// </summary>
    /// <param name="TWEMainRentalItem">VAR Record TWE Main Rental Item.</param>
    /// <returns>Return variable Result of type Boolean.</returns>
    procedure InsertItemFromTemplate(var TWEMainRentalItem: Record "TWE Main Rental Item") Result: Boolean
    var
        IsHandled: Boolean;
    begin
        OnInsertItemFromTemplate(TWEMainRentalItem, Result, IsHandled);
    end;

    /// <summary>
    /// TemplatesAreNotEmpty.
    /// </summary>
    /// <returns>Return variable Result of type Boolean.</returns>
    procedure TemplatesAreNotEmpty() Result: Boolean
    var
        IsHandled: Boolean;
    begin
        OnTemplatesAreNotEmpty(Result, IsHandled);
    end;

    /// <summary>
    /// IsEnabled.
    /// </summary>
    /// <returns>Return variable Result of type Boolean.</returns>
    procedure IsEnabled() Result: Boolean
    var
        TemplateFeatureMgt: Codeunit "Template Feature Mgt.";
    begin
        Result := TemplateFeatureMgt.IsEnabled();

        OnAfterIsEnabled(Result);
    end;

    /// <summary>
    /// UpdateItemFromTemplate.
    /// </summary>
    /// <param name="TWEMainRentalItem">VAR Record "TWE Main Rental Item".</param>
    procedure UpdateItemFromTemplate(var TWEMainRentalItem: Record "TWE Main Rental Item")
    var
        IsHandled: Boolean;
    begin
        OnUpdateItemFromTemplate(TWEMainRentalItem, IsHandled);
    end;

    local procedure UpdateFromTemplate(var TWEMainRentalItem: Record "TWE Main Rental Item"; var IsHandled: Boolean)
    var
        ItemTempl: Record "Item Templ.";
    begin
        if not CanBeUpdatedFromTemplate(ItemTempl, IsHandled) then
            exit;

        ApplyItemTemplate(TWEMainRentalItem, ItemTempl);
    end;

    /// <summary>
    /// UpdateItemsFromTemplate.
    /// </summary>
    /// <param name="TWEMainRentalItem">VAR Record "TWE Main Rental Item".</param>
    procedure UpdateItemsFromTemplate(var TWEMainRentalItem: Record "TWE Main Rental Item")
    var
        IsHandled: Boolean;
    begin
        OnUpdateItemsFromTemplate(TWEMainRentalItem, IsHandled);
    end;

    local procedure UpdateMultipleFromTemplate(var TWEMainRentalItem: Record "TWE Main Rental Item"; var IsHandled: Boolean)
    var
        ItemTempl: Record "Item Templ.";
    begin
        if not CanBeUpdatedFromTemplate(ItemTempl, IsHandled) then
            exit;

        if TWEMainRentalItem.FindSet() then
            repeat
                ApplyItemTemplate(TWEMainRentalItem, ItemTempl);
            until TWEMainRentalItem.Next() = 0;
    end;

    local procedure CanBeUpdatedFromTemplate(var ItemTempl: Record "Item Templ."; var IsHandled: Boolean): Boolean
    begin
        if not IsEnabled() then
            exit(false);

        IsHandled := true;

        if not SelectItemTemplate(ItemTempl) then
            exit(false);

        exit(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsEnabled(var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyTemplateOnBeforeItemModify(var TWEMainRentalItem: Record "TWE Main Rental Item"; ItemTempl: Record "Item Templ.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertItemFromTemplate(var TWEMainRentalItem: Record "TWE Main Rental Item"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTemplatesAreNotEmpty(var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateItemFromTemplate(var TWEMainRentalItem: Record "TWE Main Rental Item"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateItemsFromTemplate(var TWEMainRentalItem: Record "TWE Main Rental Item"; var IsHandled: Boolean)
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TWE Rent. Item Templ. Mgt.", 'OnInsertItemFromTemplate', '', false, false)]
    local procedure OnInsertItemFromTemplateHandler(var TWEMainRentalItem: Record "TWE Main Rental Item"; var Result: Boolean; var IsHandled: Boolean)
    begin
        if IsHandled then
            exit;

        Result := CreateItemFromTemplate(TWEMainRentalItem, IsHandled);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TWE Rent. Item Templ. Mgt.", 'OnTemplatesAreNotEmpty', '', false, false)]
    local procedure OnTemplatesAreNotEmptyHandler(var Result: Boolean; var IsHandled: Boolean)
    begin
        if IsHandled then
            exit;

        Result := ItemTemplatesAreNotEmpty(IsHandled);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TWE Rent. Item Templ. Mgt.", 'OnUpdateItemFromTemplate', '', false, false)]
    local procedure OnUpdateItemFromTemplateHandler(var TWEMainRentalItem: Record "TWE Main Rental Item"; var IsHandled: Boolean)
    begin
        if IsHandled then
            exit;

        UpdateFromTemplate(TWEMainRentalItem, IsHandled);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TWE Rent. Item Templ. Mgt.", 'OnUpdateItemsFromTemplate', '', false, false)]
    local procedure OnUpdateItemsFromTemplateHandler(var TWEMainRentalItem: Record "TWE Main Rental Item"; var IsHandled: Boolean)
    begin
        if IsHandled then
            exit;

        UpdateMultipleFromTemplate(TWEMainRentalItem, IsHandled);
    end;
}
