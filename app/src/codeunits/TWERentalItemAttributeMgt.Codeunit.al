codeunit 50025 "TWE Rental Item Attribute Mgt."
{

    trigger OnRun()
    begin
    end;

    var
        DeleteAttributesInheritedFromOldCategoryQst: Label 'Do you want to delete the attributes that are inherited from item category ''%1''?', Comment = '%1 - item category code';
        DeleteItemInheritedParentCategoryAttributesQst: Label 'One or more items belong to item category ''''%1'''', which is a child of item category ''''%2''''.\\Do you want to delete the inherited item attributes for the items in question?', Comment = '%1 - item category code,%2 - item category code';

    procedure FindItemsByAttribute(var FilterItemAttributesBuffer: Record "Filter Item Attributes Buffer") ItemFilter: Text
    var
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        ItemAttribute: Record "Item Attribute";
        AttributeValueIDFilter: Text;
        CurrentItemFilter: Text;
    begin
        if not FilterItemAttributesBuffer.FindSet() then
            exit;

        ItemFilter := '<>*';

        ItemAttributeValueMapping.SetRange("Table ID", DATABASE::"TWE Main Rental Item");
        CurrentItemFilter := '*';

        repeat
            ItemAttribute.SetRange(Name, FilterItemAttributesBuffer.Attribute);
            if ItemAttribute.FindFirst() then begin
                ItemAttributeValueMapping.SetRange("Item Attribute ID", ItemAttribute.ID);
                AttributeValueIDFilter := GetItemAttributeValueFilter(FilterItemAttributesBuffer, ItemAttribute);
                if AttributeValueIDFilter = '' then
                    exit;

                CurrentItemFilter := GetItemNoFilter(ItemAttributeValueMapping, CurrentItemFilter, AttributeValueIDFilter);
                if CurrentItemFilter = '' then
                    exit;
            end;
        until FilterItemAttributesBuffer.Next() = 0;

        ItemFilter := CurrentItemFilter;
    end;

    procedure FindItemsByAttributes(var FilterItemAttributesBuffer: Record "Filter Item Attributes Buffer"; var TempFilteredMainRentalItem: Record "TWE Main Rental Item" temporary)
    var
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        ItemAttribute: Record "Item Attribute";
        AttributeValueIDFilter: Text;
    begin
        if not FilterItemAttributesBuffer.FindSet() then
            exit;

        ItemAttributeValueMapping.SetRange("Table ID", DATABASE::"TWE Main Rental Item");

        repeat
            ItemAttribute.SetRange(Name, FilterItemAttributesBuffer.Attribute);
            if ItemAttribute.FindFirst() then begin
                ItemAttributeValueMapping.SetRange("Item Attribute ID", ItemAttribute.ID);
                AttributeValueIDFilter := GetItemAttributeValueFilter(FilterItemAttributesBuffer, ItemAttribute);
                if AttributeValueIDFilter = '' then begin
                    TempFilteredMainRentalItem.DeleteAll();
                    exit;
                end;

                GetFilteredItems(ItemAttributeValueMapping, TempFilteredMainRentalItem, AttributeValueIDFilter);
                if TempFilteredMainRentalItem.IsEmpty() then
                    exit;
            end;
        until FilterItemAttributesBuffer.Next() = 0;
    end;

    local procedure GetItemAttributeValueFilter(var FilterItemAttributesBuffer: Record "Filter Item Attributes Buffer"; var ItemAttribute: Record "Item Attribute") AttributeFilter: Text
    var
        ItemAttributeValue: Record "Item Attribute Value";
        Placeholder001Lbl: Label '%1|', Comment = '%1 = ItemAttributeValue ID';
    begin
        ItemAttributeValue.SetRange("Attribute ID", ItemAttribute.ID);
        ItemAttributeValue.SetValueFilter(ItemAttribute, FilterItemAttributesBuffer.Value);

        if not ItemAttributeValue.FindSet() then
            exit;

        repeat
            AttributeFilter += StrSubstNo(Placeholder001Lbl, ItemAttributeValue.ID);
        until ItemAttributeValue.Next() = 0;

        exit(CopyStr(AttributeFilter, 1, StrLen(AttributeFilter) - 1));
    end;

    local procedure GetItemNoFilter(var ItemAttributeValueMapping: Record "Item Attribute Value Mapping"; PreviousItemNoFilter: Text; AttributeValueIDFilter: Text) ItemNoFilter: Text
    var
        Placeholder001Lbl: Label '%1|', Comment = '%1 = ItemAttributeValueMapping No.';
    begin
        ItemAttributeValueMapping.SetFilter("No.", PreviousItemNoFilter);
        ItemAttributeValueMapping.SetFilter("Item Attribute Value ID", AttributeValueIDFilter);

        if not ItemAttributeValueMapping.FindSet() then
            exit;

        repeat
            ItemNoFilter += StrSubstNo(Placeholder001Lbl, ItemAttributeValueMapping."No.");
        until ItemAttributeValueMapping.Next() = 0;

        exit(CopyStr(ItemNoFilter, 1, StrLen(ItemNoFilter) - 1));
    end;

    local procedure GetFilteredItems(var ItemAttributeValueMapping: Record "Item Attribute Value Mapping"; var TempFilteredMainRentalItem: Record "TWE Main Rental Item" temporary; AttributeValueIDFilter: Text)
    var
        MainRentalItem: Record "TWE Main Rental Item";
    begin
        ItemAttributeValueMapping.SetFilter("Item Attribute Value ID", AttributeValueIDFilter);

        if ItemAttributeValueMapping.IsEmpty() then begin
            TempFilteredMainRentalItem.Reset();
            TempFilteredMainRentalItem.DeleteAll();
            exit;
        end;

        if not TempFilteredMainRentalItem.FindSet() then begin
            if ItemAttributeValueMapping.FindSet() then
                repeat
                    MainRentalItem.Get(ItemAttributeValueMapping."No.");
                    TempFilteredMainRentalItem.TransferFields(MainRentalItem);
                    TempFilteredMainRentalItem.Insert();
                until ItemAttributeValueMapping.Next() = 0;
            exit;
        end;

        repeat
            ItemAttributeValueMapping.SetRange("No.", TempFilteredMainRentalItem."No.");
            if ItemAttributeValueMapping.IsEmpty() then
                TempFilteredMainRentalItem.Delete();
        until TempFilteredMainRentalItem.Next() = 0;
        ItemAttributeValueMapping.SetRange("No.");
    end;

    procedure GetItemNoFilterText(var TempFilteredMainRentalItem: Record "TWE Main Rental Item" temporary; var ParameterCount: Integer) FilterText: Text
    var
        NextMainRentalItem: Record "TWE Main Rental Item";
        PreviousNo: Code[20];
        FilterRangeStarted: Boolean;
        Placeholder001Lbl: Label '|%1', Comment = '%1= TempFilteredMainRentalItem "No."';
        Placeholder002Lbl: Label '%1|%2', Comment = '%1= PreviousNo,%2= TempFilteredMainRentalItem."No."';
        Placeholder003Lbl: Label '%1', Comment = '%1= PreviousNo';
    begin
        PreviousNo := '';
        if not TempFilteredMainRentalItem.FindSet() then begin
            FilterText := '<>*';
            exit;
        end;

        repeat
            if FilterText = '' then begin
                FilterText := TempFilteredMainRentalItem."No.";
                NextMainRentalItem."No." := TempFilteredMainRentalItem."No.";
                ParameterCount += 1;
            end else begin
                if NextMainRentalItem.Next() = 0 then
                    NextMainRentalItem."No." := '';
                if TempFilteredMainRentalItem."No." = NextMainRentalItem."No." then begin
                    if not FilterRangeStarted then
                        FilterText += '..';
                    FilterRangeStarted := true;
                end else begin
                    if not FilterRangeStarted then begin
                        FilterText += StrSubstNo(Placeholder001Lbl, TempFilteredMainRentalItem."No.");
                        ParameterCount += 1;
                    end else begin
                        FilterText += StrSubstNo(Placeholder002Lbl, PreviousNo, TempFilteredMainRentalItem."No.");
                        FilterRangeStarted := false;
                        ParameterCount += 2;
                    end;
                    NextMainRentalItem := TempFilteredMainRentalItem;
                end;
            end;
            PreviousNo := TempFilteredMainRentalItem."No.";
        until TempFilteredMainRentalItem.Next() = 0;

        // close range if needed
        if FilterRangeStarted then begin
            FilterText += StrSubstNo(Placeholder003Lbl, PreviousNo);
            ParameterCount += 1;
        end;
    end;

    procedure InheritAttributesFromItemCategory(MainRentalItem: Record "TWE Main Rental Item"; NewItemCategoryCode: Code[20]; OldItemCategoryCode: Code[20])
    var
        TempItemAttributeValueToInsert: Record "Item Attribute Value" temporary;
        TempItemAttributeValueToDelete: Record "Item Attribute Value" temporary;
    begin
        GenerateAttributesToInsertAndToDelete(
          TempItemAttributeValueToInsert, TempItemAttributeValueToDelete, NewItemCategoryCode, OldItemCategoryCode);

        if not TempItemAttributeValueToDelete.IsEmpty() then
            if not GuiAllowed then
                DeleteItemAttributeValueMapping(MainRentalItem, TempItemAttributeValueToDelete)
            else
                if Confirm(StrSubstNo(DeleteAttributesInheritedFromOldCategoryQst, OldItemCategoryCode)) then
                    DeleteItemAttributeValueMapping(MainRentalItem, TempItemAttributeValueToDelete);

        if not TempItemAttributeValueToInsert.IsEmpty() then
            InsertItemAttributeValueMapping(MainRentalItem, TempItemAttributeValueToInsert);
    end;

    procedure UpdateCategoryAttributesAfterChangingParentCategory(ItemCategoryCode: Code[20]; NewParentItemCategory: Code[20]; OldParentItemCategory: Code[20])
    var
        TempNewParentItemAttributeValue: Record "Item Attribute Value" temporary;
        TempOldParentItemAttributeValue: Record "Item Attribute Value" temporary;
    begin
        TempNewParentItemAttributeValue.LoadCategoryAttributesFactBoxData(NewParentItemCategory);
        TempOldParentItemAttributeValue.LoadCategoryAttributesFactBoxData(OldParentItemCategory);
        UpdateCategoryItemsAttributeValueMapping(
          TempNewParentItemAttributeValue, TempOldParentItemAttributeValue, ItemCategoryCode, OldParentItemCategory);
    end;

    local procedure GenerateAttributesToInsertAndToDelete(var TempItemAttributeValueToInsert: Record "Item Attribute Value" temporary; var TempItemAttributeValueToDelete: Record "Item Attribute Value" temporary; NewItemCategoryCode: Code[20]; OldItemCategoryCode: Code[20])
    var
        TempNewCategItemAttributeValue: Record "Item Attribute Value" temporary;
        TempOldCategItemAttributeValue: Record "Item Attribute Value" temporary;
    begin
        TempNewCategItemAttributeValue.LoadCategoryAttributesFactBoxData(NewItemCategoryCode);
        TempOldCategItemAttributeValue.LoadCategoryAttributesFactBoxData(OldItemCategoryCode);
        GenerateAttributeDifference(TempNewCategItemAttributeValue, TempOldCategItemAttributeValue, TempItemAttributeValueToInsert);
        GenerateAttributeDifference(TempOldCategItemAttributeValue, TempNewCategItemAttributeValue, TempItemAttributeValueToDelete);
    end;

    local procedure GenerateAttributeDifference(var TempFirstItemAttributeValue: Record "Item Attribute Value" temporary; var TempSecondItemAttributeValue: Record "Item Attribute Value" temporary; var TempResultingItemAttributeValue: Record "Item Attribute Value" temporary)
    begin
        if TempFirstItemAttributeValue.FindFirst() then
            repeat
                if not TempSecondItemAttributeValue.Get(TempFirstItemAttributeValue."Attribute ID", TempFirstItemAttributeValue.ID) then begin
                    TempResultingItemAttributeValue.TransferFields(TempFirstItemAttributeValue);
                    TempResultingItemAttributeValue.Insert();
                end;
            until TempFirstItemAttributeValue.Next() = 0;
    end;

    procedure DeleteItemAttributeValueMapping(MainRentalItem: Record "TWE Main Rental Item"; var TempItemAttributeValueToRemove: Record "Item Attribute Value" temporary)
    begin
        DeleteItemAttributeValueMappingWithTriggerOption(MainRentalItem, TempItemAttributeValueToRemove, true);
    end;

    local procedure DeleteItemAttributeValueMappingWithTriggerOption(MainRentalItem: Record "TWE Main Rental Item"; var TempItemAttributeValueToRemove: Record "Item Attribute Value" temporary; RunTrigger: Boolean)
    var
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        ItemAttributeValuesToRemoveTxt: Text;
        Placeholder001Lbl: Label '|%1', Comment = '%1= TempItemAttributeValueToRemove "Attribute ID"';
    begin
        ItemAttributeValueMapping.SetRange("Table ID", DATABASE::"TWE Main Rental Item");
        ItemAttributeValueMapping.SetRange("No.", MainRentalItem."No.");
        if TempItemAttributeValueToRemove.FindFirst() then begin
            repeat
                if ItemAttributeValuesToRemoveTxt <> '' then
                    ItemAttributeValuesToRemoveTxt += StrSubstNo(Placeholder001Lbl, TempItemAttributeValueToRemove."Attribute ID")
                else
                    ItemAttributeValuesToRemoveTxt := Format(TempItemAttributeValueToRemove."Attribute ID");
            until TempItemAttributeValueToRemove.Next() = 0;
            ItemAttributeValueMapping.SetFilter("Item Attribute ID", ItemAttributeValuesToRemoveTxt);
            ItemAttributeValueMapping.DeleteAll(RunTrigger);
        end;
    end;

    local procedure InsertItemAttributeValueMapping(MainRentalItem: Record "TWE Main Rental Item"; var TempItemAttributeValueToInsert: Record "Item Attribute Value" temporary)
    var
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
    begin
        if TempItemAttributeValueToInsert.FindFirst() then
            repeat
                ItemAttributeValueMapping."Table ID" := DATABASE::"TWE Main Rental Item";
                ItemAttributeValueMapping."No." := MainRentalItem."No.";
                ItemAttributeValueMapping."Item Attribute ID" := TempItemAttributeValueToInsert."Attribute ID";
                ItemAttributeValueMapping."Item Attribute Value ID" := TempItemAttributeValueToInsert.ID;
                OnBeforeItemAttributeValueMappingInsert(ItemAttributeValueMapping, TempItemAttributeValueToInsert);
                if ItemAttributeValueMapping.Insert(true) then;
            until TempItemAttributeValueToInsert.Next() = 0;
    end;

    procedure UpdateCategoryItemsAttributeValueMapping(var TempNewItemAttributeValue: Record "Item Attribute Value" temporary; var TempOldItemAttributeValue: Record "Item Attribute Value" temporary; ItemCategoryCode: Code[20]; OldItemCategoryCode: Code[20])
    var
        TempItemAttributeValueToInsert: Record "Item Attribute Value" temporary;
        TempItemAttributeValueToDelete: Record "Item Attribute Value" temporary;
    begin
        GenerateAttributeDifference(TempNewItemAttributeValue, TempOldItemAttributeValue, TempItemAttributeValueToInsert);
        GenerateAttributeDifference(TempOldItemAttributeValue, TempNewItemAttributeValue, TempItemAttributeValueToDelete);

        if not TempItemAttributeValueToDelete.IsEmpty() then
            if not GuiAllowed then
                DeleteCategoryItemsAttributeValueMapping(TempItemAttributeValueToDelete, ItemCategoryCode)
            else
                if Confirm(StrSubstNo(DeleteItemInheritedParentCategoryAttributesQst, ItemCategoryCode, OldItemCategoryCode)) then
                    DeleteCategoryItemsAttributeValueMapping(TempItemAttributeValueToDelete, ItemCategoryCode);

        if not TempItemAttributeValueToInsert.IsEmpty() then
            InsertCategoryItemsAttributeValueMapping(TempItemAttributeValueToInsert, ItemCategoryCode);
    end;

    procedure DeleteCategoryItemsAttributeValueMapping(var TempItemAttributeValueToRemove: Record "Item Attribute Value" temporary; CategoryCode: Code[20])
    var
        MainRentalItem: Record "TWE Main Rental Item";
        ItemCategory: Record "Item Category";
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        ItemAttributeValue: Record "Item Attribute Value";
    begin
        MainRentalItem.SetRange("Item Category Code", CategoryCode);
        if MainRentalItem.FindSet() then
            repeat
                DeleteItemAttributeValueMappingWithTriggerOption(MainRentalItem, TempItemAttributeValueToRemove, false);
            until MainRentalItem.Next() = 0;

        ItemCategory.SetRange("Parent Category", CategoryCode);
        if ItemCategory.FindSet() then
            repeat
                DeleteCategoryItemsAttributeValueMapping(TempItemAttributeValueToRemove, ItemCategory.Code);
            until ItemCategory.Next() = 0;

        if TempItemAttributeValueToRemove.FindSet() then
            repeat
                ItemAttributeValueMapping.SetRange("Item Attribute ID", TempItemAttributeValueToRemove."Attribute ID");
                ItemAttributeValueMapping.SetRange("Item Attribute Value ID", TempItemAttributeValueToRemove.ID);
                if ItemAttributeValueMapping.IsEmpty() then
                    if ItemAttributeValue.Get(TempItemAttributeValueToRemove."Attribute ID", TempItemAttributeValueToRemove.ID) then
                        ItemAttributeValue.Delete();
            until TempItemAttributeValueToRemove.Next() = 0;
    end;

    procedure InsertCategoryItemsAttributeValueMapping(var TempItemAttributeValueToInsert: Record "Item Attribute Value" temporary; CategoryCode: Code[20])
    var
        MainRentalItem: Record "TWE Main Rental Item";
        ItemCategory: Record "Item Category";
    begin
        MainRentalItem.SetRange("Item Category Code", CategoryCode);
        if MainRentalItem.FindSet() then
            repeat
                InsertItemAttributeValueMapping(MainRentalItem, TempItemAttributeValueToInsert);
            until MainRentalItem.Next() = 0;

        ItemCategory.SetRange("Parent Category", CategoryCode);
        if ItemCategory.FindSet() then
            repeat
                InsertCategoryItemsAttributeValueMapping(TempItemAttributeValueToInsert, ItemCategory.Code);
            until ItemCategory.Next() = 0;
    end;

    procedure InsertCategoryItemsBufferedAttributeValueMapping(var TempItemAttributeValueToInsert: Record "Item Attribute Value" temporary; var TempInsertedItemAttributeValueMapping: Record "Item Attribute Value Mapping" temporary; CategoryCode: Code[20])
    var
        MainRentalItem: Record "TWE Main Rental Item";
        ItemCategory: Record "Item Category";
    begin
        MainRentalItem.SetRange("Item Category Code", CategoryCode);
        if MainRentalItem.FindSet() then
            repeat
                InsertBufferedItemAttributeValueMapping(MainRentalItem, TempItemAttributeValueToInsert, TempInsertedItemAttributeValueMapping);
            until MainRentalItem.Next() = 0;

        ItemCategory.SetRange("Parent Category", CategoryCode);
        if ItemCategory.FindSet() then
            repeat
                InsertCategoryItemsBufferedAttributeValueMapping(
                  TempItemAttributeValueToInsert, TempInsertedItemAttributeValueMapping, ItemCategory.Code);
            until ItemCategory.Next() = 0;
    end;

    local procedure InsertBufferedItemAttributeValueMapping(MainRentalItem: Record "TWE Main Rental Item"; var TempItemAttributeValueToInsert: Record "Item Attribute Value" temporary; var TempInsertedItemAttributeValueMapping: Record "Item Attribute Value Mapping" temporary)
    var
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
    begin
        if TempItemAttributeValueToInsert.FindFirst() then
            repeat
                ItemAttributeValueMapping."Table ID" := DATABASE::"TWE Main Rental Item";
                ItemAttributeValueMapping."No." := MainRentalItem."No.";
                ItemAttributeValueMapping."Item Attribute ID" := TempItemAttributeValueToInsert."Attribute ID";
                ItemAttributeValueMapping."Item Attribute Value ID" := TempItemAttributeValueToInsert.ID;
                OnInsertBufferedItemAttributeValueMappingOnBeforeItemAttributeValueMappingInsert(TempItemAttributeValueToInsert, ItemAttributeValueMapping);
                if ItemAttributeValueMapping.Insert(true) then begin
                    TempInsertedItemAttributeValueMapping.TransferFields(ItemAttributeValueMapping);
                    OnBeforeBufferedItemAttributeValueMappingInsert(ItemAttributeValueMapping, TempInsertedItemAttributeValueMapping);
                    TempInsertedItemAttributeValueMapping.Insert();
                end;
            until TempItemAttributeValueToInsert.Next() = 0;
    end;

    procedure SearchCategoryItemsForAttribute(CategoryCode: Code[20]; AttributeID: Integer): Boolean
    var
        MainRentalItem: Record "TWE Main Rental Item";
        ItemCategory: Record "Item Category";
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        IsHandled: Boolean;
    begin
        MainRentalItem.SetRange("Item Category Code", CategoryCode);
        if MainRentalItem.FindSet() then
            repeat
                ItemAttributeValueMapping.SetRange("Table ID", DATABASE::"TWE Main Rental Item");
                ItemAttributeValueMapping.SetRange("No.", MainRentalItem."No.");
                ItemAttributeValueMapping.SetRange("Item Attribute ID", AttributeID);
                if not ItemAttributeValueMapping.IsEmpty() then
                    exit(true);
            until MainRentalItem.Next() = 0;

        IsHandled := false;
        OnSearchCategoryItemsForAttributeOnBeforeSearchByParentCategory(CategoryCode, AttributeID, IsHandled);
        if IsHandled then
            exit;
        ItemCategory.SetRange("Parent Category", CategoryCode);
        if ItemCategory.FindSet() then
            repeat
                if SearchCategoryItemsForAttribute(ItemCategory.Code, AttributeID) then
                    exit(true);
            until ItemCategory.Next() = 0;
    end;

    procedure DoesValueExistInItemAttributeValues(Text: Text[250]; var ItemAttributeValue: Record "Item Attribute Value"): Boolean
    begin
        ItemAttributeValue.Reset();
        ItemAttributeValue.SetFilter(Value, '@' + Text);
        exit(ItemAttributeValue.FindSet());
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeItemAttributeValueMappingInsert(var ItemAttributeValueMapping: Record "Item Attribute Value Mapping"; var TempItemAttributeValue: Record "Item Attribute Value" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeBufferedItemAttributeValueMappingInsert(var ItemAttributeValueMapping: Record "Item Attribute Value Mapping"; var TempItemAttributeValueMapping: Record "Item Attribute Value Mapping" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertBufferedItemAttributeValueMappingOnBeforeItemAttributeValueMappingInsert(var TempItemAttributeValueToInsert: Record "Item Attribute Value" temporary; var ItemAttributeValueMapping: Record "Item Attribute Value Mapping")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSearchCategoryItemsForAttributeOnBeforeSearchByParentCategory(CategoryCode: Code[20]; AttributeID: Integer; var IsHandled: Boolean)
    begin
    end;
}

