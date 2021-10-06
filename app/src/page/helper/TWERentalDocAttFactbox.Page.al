/// <summary>
/// Page TWE Rental Doc. Att. Factbox (ID 50005).
/// </summary>
page 50005 "TWE Rental Doc. Att. Factbox"
{
    Caption = 'Rental Documents Attached';
    PageType = CardPart;
    SourceTable = "Document Attachment";

    layout
    {
        area(content)
        {
            group(Control2)
            {
                ShowCaption = false;
                field(Documents; NumberOfRecords)
                {
                    ApplicationArea = All;
                    Caption = 'Documents';
                    StyleExpr = TRUE;
                    ToolTip = 'Specifies the number of attachments.';

                    trigger OnDrillDown()
                    var
                        Customer: Record Customer;
                        Vendor: Record Vendor;
                        MainRentalItem: Record "TWE Main Rental Item";
                        Resource: Record Resource;
                        RentalHeader: Record "TWE Rental Header";
                        PurchaseHeader: Record "Purchase Header";
                        RentalCrMemoHeader: Record "TWE Rental Cr.Memo Header";
                        RentalInvoiceHeader: Record "TWE Rental Invoice Header";
                        PurchInvHeader: Record "Purch. Inv. Header";
                        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
                        DocumentAttachmentDetails: Page "Document Attachment Details";
                        RecRef: RecordRef;
                    begin
                        case Rec."Table ID" of
                            0:
                                exit;
                            DATABASE::Customer:
                                begin
                                    RecRef.Open(DATABASE::Customer);
                                    if Customer.Get(Rec."No.") then
                                        RecRef.GetTable(Customer);
                                end;
                            DATABASE::Vendor:
                                begin
                                    RecRef.Open(DATABASE::Vendor);
                                    if Vendor.Get(Rec."No.") then
                                        RecRef.GetTable(Vendor);
                                end;
                            DATABASE::"TWE Main Rental Item":
                                begin
                                    RecRef.Open(DATABASE::"TWE Main Rental Item");
                                    if MainRentalItem.Get(Rec."No.") then
                                        RecRef.GetTable(MainRentalItem);
                                end;
                            DATABASE::Resource:
                                begin
                                    RecRef.Open(DATABASE::Resource);
                                    if Resource.Get(Rec."No.") then
                                        RecRef.GetTable(Resource);
                                end;
                            DATABASE::"TWE Rental Header":
                                begin
                                    RecRef.Open(DATABASE::"TWE Rental Header");
                                    if RentalHeader.Get(Rec."Document Type", Rec."No.") then
                                        RecRef.GetTable(RentalHeader);
                                end;
                            DATABASE::"TWE Rental Invoice Header":
                                begin
                                    RecRef.Open(DATABASE::"TWE Rental Invoice Header");
                                    if RentalInvoiceHeader.Get(Rec."No.") then
                                        RecRef.GetTable(RentalInvoiceHeader);
                                end;
                            DATABASE::"TWE Rental Cr.Memo Header":
                                begin
                                    RecRef.Open(DATABASE::"TWE Rental Cr.Memo Header");
                                    if RentalCrMemoHeader.Get(Rec."No.") then
                                        RecRef.GetTable(RentalCrMemoHeader);
                                end;
                            DATABASE::"Purchase Header":
                                begin
                                    RecRef.Open(DATABASE::"Purchase Header");
                                    if PurchaseHeader.Get(Rec."Document Type", Rec."No.") then
                                        RecRef.GetTable(PurchaseHeader);
                                end;
                            DATABASE::"Purch. Inv. Header":
                                begin
                                    RecRef.Open(DATABASE::"Purch. Inv. Header");
                                    if PurchInvHeader.Get(Rec."No.") then
                                        RecRef.GetTable(PurchInvHeader);
                                end;
                            DATABASE::"Purch. Cr. Memo Hdr.":
                                begin
                                    RecRef.Open(DATABASE::"Purch. Cr. Memo Hdr.");
                                    if PurchCrMemoHdr.Get(Rec."No.") then
                                        RecRef.GetTable(PurchCrMemoHdr);
                                end;
                            else
                                OnBeforeDrillDown(Rec, RecRef);
                        end;

                        DocumentAttachmentDetails.OpenForRecRef(RecRef);
                        DocumentAttachmentDetails.RunModal();
                    end;
                }
            }
        }
    }

    actions
    {
    }

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDrillDown(DocumentAttachment: Record "Document Attachment"; var RecRef: RecordRef)
    begin
    end;

    trigger OnAfterGetCurrRecord()
    var
        currentFilterGroup: Integer;
    begin
        currentFilterGroup := Rec.FilterGroup;
        Rec.FilterGroup := 4;

        NumberOfRecords := 0;
        if Rec.GetFilters() <> '' then
            NumberOfRecords := Rec.Count();
        Rec.FilterGroup := currentFilterGroup;
    end;

    var
        NumberOfRecords: Integer;
}

