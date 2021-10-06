tableextension 50007 "TWE RentalItemAttributeValue" extends "Item Attribute Value"
{
    procedure LoadItemAttributesFactBoxDataForRental(KeyValue: Code[20])
    var
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        ItemAttributeValue: Record "Item Attribute Value";
    begin
        Rec.Reset();
        Rec.DeleteAll();
        ItemAttributeValueMapping.SetRange("Table ID", DATABASE::"TWE Main Rental Item");
        ItemAttributeValueMapping.SetRange("No.", KeyValue);
        if ItemAttributeValueMapping.FindSet() then
            repeat
                if ItemAttributeValue.Get(ItemAttributeValueMapping."Item Attribute ID", ItemAttributeValueMapping."Item Attribute Value ID") then begin
                    TransferFields(ItemAttributeValue);
                    OnLoadItemAttributesFactBoxDataForRentalOnBeforeInsert(ItemAttributeValueMapping, Rec);
                    Rec.Insert();
                end
            until ItemAttributeValueMapping.Next() = 0;
    end;


    [IntegrationEvent(false, false)]
    local procedure OnLoadItemAttributesFactBoxDataForRentalOnBeforeInsert(var ItemAttributeValueMapping: Record "Item Attribute Value Mapping"; var ItemAttributeValue: Record "Item Attribute Value")
    begin
    end;
}
