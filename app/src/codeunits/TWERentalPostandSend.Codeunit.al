codeunit 50030 "TWE Rental-Post and Send"
{
    TableNo = "TWE Rental Header";

    trigger OnRun()
    begin
        if not Rec.Find() then
            Error(NothingToPostErr);

        RentalHeader.Copy(Rec);
        Code();
        Rec := RentalHeader;
    end;

    var
        RentalHeader: Record "TWE Rental Header";
        NotSupportedDocumentTypeErr: Label 'Document type %1 is not supported.', Comment = '%1=Document Type';
        NothingToPostErr: Label 'There is nothing to post.';

    local procedure "Code"()
    var
        TempRentalDocumentSendingProfile: Record "TWE Rental Doc. Send. Profile" temporary;
        RentalPost: Codeunit "TWE Rental-Post";
        RentalPostYesNo: Codeunit "TWE Rental-Post (Yes/No)";
        HideDialog: Boolean;
    begin
        HideDialog := false;

        OnBeforePostAndSend(RentalHeader, HideDialog, TempRentalDocumentSendingProfile);
        if not HideDialog then
            case RentalHeader."Document Type" of
                RentalHeader."Document Type"::Invoice,
              RentalHeader."Document Type"::"Credit Memo",
              RentalHeader."Document Type"::Contract:
                    if not ConfirmPostAndSend(RentalHeader, TempRentalDocumentSendingProfile) then
                        exit;
                else
                    Error(NotSupportedDocumentTypeErr, RentalHeader."Document Type");
            end;

        TempRentalDocumentSendingProfile.CheckElectronicSendingEnabled();
        ValidateElectronicFormats(TempRentalDocumentSendingProfile);

        if RentalHeader."Document Type" = RentalHeader."Document Type"::Contract then begin
            RentalPostYesNo.PostAndSend(RentalHeader);
            if not (RentalHeader.Ship or RentalHeader.Invoice) then
                exit;
        end else
            CODEUNIT.Run(CODEUNIT::"Sales-Post", RentalHeader);

        OnAfterPostAndBeforeSend(RentalHeader);

        Commit();

        RentalPost.SendPostedDocumentRecord(RentalHeader, TempRentalDocumentSendingProfile);

        OnAfterPostAndSend(RentalHeader);
    end;

    local procedure ConfirmPostAndSend(RentalHeader: Record "TWE Rental Header"; var TempRentalDocumentSendingProfile: Record "TWE Rental Doc. Send. Profile" temporary): Boolean
    var
        Customer: Record Customer;
        RentalDocumentSendingProfile: Record "TWE Rental Doc. Send. Profile";
        OfficeMgt: Codeunit "Office Management";
    begin
        Customer.Get(RentalHeader."Bill-to Customer No.");
        if OfficeMgt.IsAvailable() then
            RentalDocumentSendingProfile.GetOfficeAddinDefault(TempRentalDocumentSendingProfile, OfficeMgt.AttachAvailable())
        else begin
            if not RentalDocumentSendingProfile.Get(Customer."Document Sending Profile") then
                RentalDocumentSendingProfile.GetDefault(RentalDocumentSendingProfile);

            Commit();
            TempRentalDocumentSendingProfile.Copy(RentalDocumentSendingProfile);
            TempRentalDocumentSendingProfile.SetDocumentUsage(RentalHeader);
            TempRentalDocumentSendingProfile.Insert();

            OnBeforeConfirmAndSend(RentalHeader, TempRentalDocumentSendingProfile);
            if PAGE.RunModal(PAGE::"Post and Send Confirmation", TempRentalDocumentSendingProfile) <> ACTION::Yes then
                exit(false);
        end;

        exit(true);
    end;

    local procedure ValidateElectronicFormats(RentalDocumentSendingProfile: Record "TWE Rental Doc. Send. Profile")
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
    begin
        if (RentalDocumentSendingProfile."E-Mail" <> RentalDocumentSendingProfile."E-Mail"::No) and
           (RentalDocumentSendingProfile."E-Mail Attachment" <> RentalDocumentSendingProfile."E-Mail Attachment"::PDF)
        then begin
            ElectronicDocumentFormat.ValidateElectronicFormat(RentalDocumentSendingProfile."E-Mail Format");
            ElectronicDocumentFormat.ValidateElectronicRentalDocument(RentalHeader, RentalDocumentSendingProfile."E-Mail Format");
        end;

        if (RentalDocumentSendingProfile.Disk <> RentalDocumentSendingProfile.Disk::No) and
           (RentalDocumentSendingProfile.Disk <> RentalDocumentSendingProfile.Disk::PDF)
        then begin
            ElectronicDocumentFormat.ValidateElectronicFormat(RentalDocumentSendingProfile."Disk Format");
            ElectronicDocumentFormat.ValidateElectronicRentalDocument(RentalHeader, RentalDocumentSendingProfile."Disk Format");
        end;

        if RentalDocumentSendingProfile."Electronic Document" <> RentalDocumentSendingProfile."Electronic Document"::No then begin
            ElectronicDocumentFormat.ValidateElectronicFormat(RentalDocumentSendingProfile."Electronic Format");
            ElectronicDocumentFormat.ValidateElectronicRentalDocument(RentalHeader, RentalDocumentSendingProfile."Electronic Format");
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostAndBeforeSend(var RentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostAndSend(var RentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmAndSend(RentalHeader: Record "TWE Rental Header"; var TempRentalDocumentSendingProfile: Record "TWE Rental Doc. Send. Profile" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostAndSend(var RentalHeader: Record "TWE Rental Header"; var HideDialog: Boolean; var TempRentalDocumentSendingProfile: Record "TWE Rental Doc. Send. Profile" temporary)
    begin
    end;
}

