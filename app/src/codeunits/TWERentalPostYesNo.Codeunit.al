/// <summary>
/// Codeunit TWE Rental-Post (Yes/No) (ID 50036).
/// </summary>
codeunit 50036 "TWE Rental-Post (Yes/No)"
{
    EventSubscriberInstance = Manual;
    TableNo = "TWE Rental Header";

    trigger OnRun()
    var
        RentalHeader: Record "TWE Rental Header";
    begin
        if not Rec.Find() then
            Error(NothingToPostErr);

        RentalHeader.Copy(Rec);
        Code(RentalHeader, false);
        Rec := RentalHeader;
    end;

    var
        ShipInvoiceQst: Label '&Ship,&Invoice,Ship &and Invoice';
        PostConfirmQst: Label 'Do you want to post the %1?', Comment = '%1 = Document Type';
        NothingToPostErr: Label 'There is nothing to post.';

    /// <summary>
    /// PostAndSend.
    /// </summary>
    /// <param name="RentalHeader">VAR Record "TWE Rental Header".</param>
    procedure PostAndSend(var RentalHeader: Record "TWE Rental Header")
    var
        RentalHeaderToPost: Record "TWE Rental Header";
    begin
        RentalHeaderToPost.Copy(RentalHeader);
        Code(RentalHeaderToPost, true);
        RentalHeader := RentalHeaderToPost;
    end;

    local procedure "Code"(var RentalHeader: Record "TWE Rental Header"; PostAndSend: Boolean)
    var
        RentalSetup: Record "TWE Rental Setup";
        //SalesPostViaJobQueue: Codeunit "Sales Post via Job Queue";
        HideDialog: Boolean;
        IsHandled: Boolean;
        DefaultOption: Integer;
    begin
        HideDialog := false;
        IsHandled := false;
        DefaultOption := 3;
        OnBeforeConfirmRentalPost(RentalHeader, HideDialog, IsHandled, DefaultOption, PostAndSend);
        if IsHandled then
            exit;

        if not HideDialog then
            if not ConfirmPost(RentalHeader, DefaultOption) then
                exit;

        OnAfterConfirmPost(RentalHeader);

        RentalSetup.Get();
        /*      if RentalSetup."Post with Job Queue" and not PostAndSend then
                 SalesPostViaJobQueue.EnqueueSalesDoc(RentalHeader) */
        //else
        CODEUNIT.Run(CODEUNIT::"TWE Rental-Post", RentalHeader);

        OnAfterPost(RentalHeader);
    end;

    local procedure ConfirmPost(var RentalHeader: Record "TWE Rental Header"; DefaultOption: Integer): Boolean
    var
        ConfirmManagement: Codeunit "Confirm Management";
        Selection: Integer;
    begin
        if DefaultOption > 3 then
            DefaultOption := 3;
        if DefaultOption <= 0 then
            DefaultOption := 1;

        case RentalHeader."Document Type" of
            RentalHeader."Document Type"::Contract:
                begin
                    Selection := StrMenu(ShipInvoiceQst, DefaultOption);
                    RentalHeader.Ship := Selection in [1, 3];
                    RentalHeader.Invoice := Selection in [2, 3];
                    if Selection = 0 then
                        exit(false);
                end;
            else
                if not ConfirmManagement.GetResponseOrDefault(
                     StrSubstNo(PostConfirmQst, Format(RentalHeader."Document Type")), true)
                then
                    exit(false);
        end;

        RentalHeader."Print Posted Documents" := false;
        exit(true);
    end;

    /// <summary>
    /// Preview.
    /// </summary>
    /// <param name="RentalHeader">VAR Record "TWE Rental Header".</param>
    procedure Preview(var RentalHeader: Record "TWE Rental Header")
    var
        RentalPostYesNo: Codeunit "TWE Rental-Post (Yes/No)";
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
    begin
        BindSubscription(RentalPostYesNo);
        GenJnlPostPreview.Preview(RentalPostYesNo, RentalHeader);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPost(var RentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterConfirmPost(var RentalHeader: Record "TWE Rental Header")
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, 19, 'OnRunPreview', '', false, false)]
    local procedure OnRunPreview(var Result: Boolean; Subscriber: Variant; RecVar: Variant)
    var
        RentalHeader: Record "TWE Rental Header";
        RentalPost: Codeunit "TWE Rental-Post";
    begin
        RentalHeader.Copy(RecVar);
        //Receive := "Document Type" = "Document Type"::"Return Order";
        RentalHeader.Ship := RentalHeader."Document Type" = RentalHeader."Document Type"::Contract;
        RentalHeader.Invoice := true;

        OnRunPreviewOnAfterSetPostingFlags(RentalHeader);

        RentalPost.SetPreviewMode(true);
        Result := RentalPost.Run(RentalHeader);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunPreviewOnAfterSetPostingFlags(var RentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmRentalPost(var RentalHeader: Record "TWE Rental Header"; var HideDialog: Boolean; var IsHandled: Boolean; var DefaultOption: Integer; var PostAndSend: Boolean)
    begin
    end;
}

