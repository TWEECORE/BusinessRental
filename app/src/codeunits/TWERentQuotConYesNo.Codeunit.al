/// <summary>
/// Codeunit TWE Rent.-Quot. - Contract(Yes/No) (ID 50067).
/// </summary>
codeunit 50067 "TWE Rent.-Quot. - Con.(Yes/No)"
{
    TableNo = "TWE Rental Header";

    trigger OnRun()
    var
        OfficeMgt: Codeunit "Office Management";
        TWERentalContract: Page "TWE Rental Contract";
        OpenPage: Boolean;
    begin
        if IsOnRunHandled(Rec) then
            exit;

        Rec.TestField("Document Type", Rec."Document Type"::Quote);
        if GuiAllowed then
            if not Confirm(ConfirmConvertToOrderQst, false) then
                exit;

        if Rec.CheckCustomerCreated(true) then
            Rec.Get(Rec."Document Type"::Quote, Rec."No.")
        else
            exit;

        TWERentalQuotetoContract.Run(Rec);
        TWERentalQuotetoContract.GetRentalContractHeader(TWERentalHeader2);
        Commit();

        OnAfterRentalQuoteToContractRun(TWERentalHeader2);

        if GuiAllowed then
            if OfficeMgt.AttachAvailable() then
                OpenPage := true
            else
                OpenPage := Confirm(StrSubstNo(OpenNewInvoiceQst, TWERentalHeader2."No."), true);
        if OpenPage then begin
            Clear(TWERentalContract);
            TWERentalContract.CheckNotificationsOnce();
            TWERentalContract.SetRecord(TWERentalHeader2);
            TWERentalContract.Run();
        end;
    end;

    var
        TWERentalHeader2: Record "TWE Rental Header";

        TWERentalQuotetoContract: Codeunit "TWE Rental-Quote to Contract";
        ConfirmConvertToOrderQst: Label 'Do you want to convert the quote to an contract?';
        OpenNewInvoiceQst: Label 'The quote has been converted to order %1. Do you want to open the new contract?', Comment = '%1 = No. of the new rental contract document.';

    local procedure IsOnRunHandled(var TWERentalHeader: Record "TWE Rental Header") IsHandled: Boolean
    begin
        IsHandled := false;
        OnBeforeRun(TWERentalHeader, IsHandled);
        exit(IsHandled);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRentalQuoteToContractRun(var TWERentalHeader2: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRun(var TWERentalHeader: Record "TWE Rental Header"; var IsHandled: Boolean)
    begin
    end;
}

