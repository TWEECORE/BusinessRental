/// <summary>
/// Codeunit TWE Release Rental Document (ID 50010).
/// </summary>
codeunit 50010 "TWE Release Rental Document"
{
    TableNo = "TWE Rental Header";
    Permissions = TableData "TWE Rental Header" = rm;

    trigger OnRun()
    begin
        TWERentalHeader.Copy(Rec);
        Code();
        Rec := TWERentalHeader;
    end;

    var
        SalesSetup: Record "Sales & Receivables Setup";
        InvtSetup: Record "Inventory Setup";
        TWERentalHeader: Record "TWE Rental Header";
        //WhseSalesRelease: Codeunit "Whse.-Sales Release";
        Text001Lbl: Label 'There is nothing to release for the document of type %1 with the number %2.', Comment = '%1 = Document Type, %2 = Document No.';
        Text002Lbl: Label 'This document can only be released when the approval process is complete.';
        Text003Lbl: Label 'The approval process must be cancelled or completed to reopen this document.';
        Text005Lbl: Label 'There are unpaid prepayment invoices that are related to the document of type %1 with the number %2.', Comment = '%1 = Document Type, %2 = Document No.';
        UnpostedPrepaymentAmountsErr: Label 'There are unposted prepayment amounts on the document of type %1 with the number %2.', Comment = '%1 - Document Type; %2 - Document No.';
        PreviewMode: Boolean;
        SkipCheckReleaseRestrictions: Boolean;

    local procedure "Code"() LinesWereModified: Boolean
    var
        TWERentalLine: Record "TWE Rental Line";
        RentalPrepaymentMgt: Codeunit "TWE Rental Prepayment Mgt.";
        PostingDate: Date;
        PrintPostedDocuments: Boolean;
        IsHandled: Boolean;
    begin
        if TWERentalHeader.Status = TWERentalHeader.Status::Released then
            exit;

        IsHandled := false;
        OnBeforeReleaseRentalDoc(TWERentalHeader, PreviewMode, IsHandled);
        if IsHandled then
            exit;
        if not (PreviewMode or SkipCheckReleaseRestrictions) then
            TWERentalHeader.CheckSalesReleaseRestrictions();

        IsHandled := false;
        OnBeforeCheckCustomerCreated(TWERentalHeader, IsHandled);
        if not IsHandled then
            if TWERentalHeader."Document Type" = TWERentalHeader."Document Type"::Quote then
                if TWERentalHeader.CheckCustomerCreated(true) then
                    TWERentalHeader.Get(TWERentalHeader."Document Type"::Quote, TWERentalHeader."No.")
                else
                    exit;

        TWERentalHeader.TestField("Rented-to Customer No.");

        TWERentalLine.SetRange("Document Type", TWERentalHeader."Document Type");
        TWERentalLine.SetRange("Document No.", TWERentalHeader."No.");
        TWERentalLine.SetFilter(Type, '>0');
        TWERentalLine.SetFilter(Quantity, '<>0');
        OnBeforeRentalLineFind(TWERentalLine, TWERentalHeader);
        if not TWERentalLine.Find('-') then
            Error(Text001Lbl, TWERentalHeader."Document Type", TWERentalHeader."No.");
        InvtSetup.Get();
        if InvtSetup."Location Mandatory" then begin
            TWERentalLine.SetRange(Type, TWERentalLine.Type::"Rental Item");
            if TWERentalLine.FindSet() then
                repeat
                    //  if TWERentalLine.IsInventoriableItem then
                    TWERentalLine.TestField("Location Code");
                    OnCodeOnAfterRentalLineCheck(TWERentalLine);
                until TWERentalLine.Next() = 0;
            TWERentalLine.SetFilter(Type, '>0');
        end;

        OnCodeOnAfterCheck(TWERentalHeader, TWERentalLine, LinesWereModified);

        TWERentalLine.SetRange("Drop Shipment", false);
        TWERentalLine.Reset();

        OnBeforeCalcInvDiscount(TWERentalHeader, PreviewMode);

        SalesSetup.Get();
        if SalesSetup."Calc. Inv. Discount" then begin
            PostingDate := TWERentalHeader."Posting Date";
            PrintPostedDocuments := TWERentalHeader."Print Posted Documents";
            CODEUNIT.Run(CODEUNIT::"TWE Rental-Calc. Discount", TWERentalLine);
            LinesWereModified := true;
            TWERentalHeader.Get(TWERentalHeader."Document Type", TWERentalHeader."No.");
            TWERentalHeader."Print Posted Documents" := PrintPostedDocuments;
            if PostingDate <> TWERentalHeader."Posting Date" then
                TWERentalHeader.Validate("Posting Date", PostingDate);
        end;

        IsHandled := false;
        OnBeforeModifyRentalDoc(TWERentalHeader, PreviewMode, IsHandled);
        if IsHandled then
            exit;

        if RentalPrepaymentMgt.TestRentalPrepayment(TWERentalHeader) and (TWERentalHeader."Document Type" = TWERentalHeader."Document Type"::Contract) then begin
            TWERentalHeader.Status := TWERentalHeader.Status::"Pending Prepayment";
            TWERentalHeader.Modify(true);
            OnAfterReleaseRentalDoc(TWERentalHeader, PreviewMode, LinesWereModified);
            exit;
        end;
        TWERentalHeader.Status := TWERentalHeader.Status::Released;

        LinesWereModified := LinesWereModified or CalcAndUpdateVATOnLines(TWERentalHeader, TWERentalLine);

        OnAfterUpdateRentalDocLines(TWERentalHeader, LinesWereModified, PreviewMode);

        ReleaseATOs(TWERentalHeader);
        OnAfterReleaseATOs(TWERentalHeader, TWERentalLine, PreviewMode);

        TWERentalHeader.Modify(true);

        //if NotOnlyDropShipment then
        // if "Document Type" in ["Document Type"::Contract, "Document Type"::"Return Shipment"] then
        //    WhseSalesRelease.Release(TWERentalHeader);

        OnAfterReleaseRentalDoc(TWERentalHeader, PreviewMode, LinesWereModified);
    end;

    procedure Reopen(var TWERentalHeader: Record "TWE Rental Header")
    begin
        OnBeforeReopenRentalDoc(TWERentalHeader, PreviewMode);

        if TWERentalHeader.Status = TWERentalHeader.Status::Open then
            exit;
        TWERentalHeader.Status := TWERentalHeader.Status::Open;

        if TWERentalHeader."Document Type" <> TWERentalHeader."Document Type"::Contract then
            ReopenATOs(TWERentalHeader);

        OnReopenOnBeforeRentalHeaderModify(TWERentalHeader);
        TWERentalHeader.Modify(true);
        // if TWERentalHeader."Document Type" in [TWERentalHeader."Document Type"::Contract, TWERentalHeader."Document Type"::"Return Shipment"] then
        //    WhseSalesRelease.Reopen(TWERentalHeader);

        OnAfterReopenRentalDoc(TWERentalHeader, PreviewMode);
    end;

    /// <summary>
    /// PerformManualRelease.
    /// </summary>
    /// <param name="TWERentalHeader">VAR Record "TWE Rental Header".</param>
    procedure PerformManualRelease(var TWERentalHeader: Record "TWE Rental Header")
    var
        RentalPrepaymentMgt: Codeunit "TWE Rental Prepayment Mgt.";
    begin
        OnPerformManualReleaseOnBeforeTestSalesPrepayment(TWERentalHeader, PreviewMode);
        if RentalPrepaymentMgt.TestRentalPrepayment(TWERentalHeader) then
            Error(UnpostedPrepaymentAmountsErr, TWERentalHeader."Document Type", TWERentalHeader."No.");

        OnBeforeManualReleaseRentalDoc(TWERentalHeader, PreviewMode);
        PerformManualCheckAndRelease(TWERentalHeader);
        OnAfterManualReleaseRentalDoc(TWERentalHeader, PreviewMode);
    end;

    /// <summary>
    /// PerformManualCheckAndRelease.
    /// </summary>
    /// <param name="TWERentalHeader">VAR Record "TWE Rental Header".</param>
    procedure PerformManualCheckAndRelease(var TWERentalHeader: Record "TWE Rental Header")
    var
        RentalPrepaymentMgt: Codeunit "TWE Rental Prepayment Mgt.";
        RentalApprovalsMgmt: Codeunit "TWE Rental Approvals Mgmt.";
        IsHandled: Boolean;
    begin
        OnBeforePerformManualCheckAndRelease(TWERentalHeader, PreviewMode);

        if (TWERentalHeader."Document Type" = TWERentalHeader."Document Type"::Contract) and RentalPrepaymentMgt.TestRentalPayment(TWERentalHeader) then begin
            if TWERentalHeader.TestStatusIsNotPendingPrepayment() then begin
                TWERentalHeader.Status := TWERentalHeader.Status::"Pending Prepayment";
                TWERentalHeader.Modify();
                Commit();
            end;
            Error(Text005Lbl, TWERentalHeader."Document Type", TWERentalHeader."No.");
        end;

        if RentalApprovalsMgmt.IsRentalHeaderPendingApproval(TWERentalHeader) then
            Error(Text002Lbl);

        IsHandled := false;
        OnBeforePerformManualRelease(TWERentalHeader, PreviewMode, IsHandled);
        if IsHandled then
            exit;

        CODEUNIT.Run(CODEUNIT::"TWE Release Rental Document", TWERentalHeader);

        OnAfterPerformManualCheckAndRelease(TWERentalHeader, PreviewMode);
    end;

    procedure PerformManualReopen(var TWERentalHeader: Record "TWE Rental Header")
    begin
        if TWERentalHeader.Status = TWERentalHeader.Status::"Pending Approval" then
            Error(Text003Lbl);

        OnBeforeManualReOpenRentalDoc(TWERentalHeader, PreviewMode);
        Reopen(TWERentalHeader);
        OnAfterManualReOpenRentalDoc(TWERentalHeader, PreviewMode);
    end;

    local procedure ReleaseATOs(TWERentalHeader: Record "TWE Rental Header")
    var
        TWERentalLine: Record "TWE Rental Line";
        AsmHeader: Record "Assembly Header";
    begin
        TWERentalLine.SetRange("Document Type", TWERentalHeader."Document Type");
        TWERentalLine.SetRange("Document No.", TWERentalHeader."No.");
        if TWERentalLine.FindSet() then
            repeat
                if TWERentalLine.AsmToOrderExists(AsmHeader) then
                    CODEUNIT.Run(CODEUNIT::"Release Assembly Document", AsmHeader);
            until TWERentalLine.Next() = 0;
    end;

    local procedure ReopenATOs(TWERentalHeader: Record "TWE Rental Header")
    var
        TWERentalLine: Record "TWE Rental Line";
        AsmHeader: Record "Assembly Header";
        ReleaseAssemblyDocument: Codeunit "Release Assembly Document";
    begin
        TWERentalLine.SetRange("Document Type", TWERentalHeader."Document Type");
        TWERentalLine.SetRange("Document No.", TWERentalHeader."No.");
        if TWERentalLine.FindSet() then
            repeat
                if TWERentalLine.AsmToOrderExists(AsmHeader) then
                    ReleaseAssemblyDocument.Reopen(AsmHeader);
            until TWERentalLine.Next() = 0;
    end;

    /// <summary>
    /// ReleaseTWERentalHeader.
    /// </summary>
    /// <param name="TWERentalHeader">VAR Record "TWE Rental Header".</param>
    /// <param name="Preview">Boolean.</param>
    /// <returns>Return variable LinesWereModified of type Boolean.</returns>
    procedure ReleaseTWERentalHeader(var rentalHeader: Record "TWE Rental Header"; Preview: Boolean) LinesWereModified: Boolean
    begin
        PreviewMode := Preview;
        TWERentalHeader.Copy(rentalHeader);
        LinesWereModified := Code();
        rentalHeader := TWERentalHeader;
    end;

    /// <summary>
    /// SetSkipCheckReleaseRestrictions.
    /// </summary>
    procedure SetSkipCheckReleaseRestrictions()
    begin
        SkipCheckReleaseRestrictions := true;
    end;

    /// <summary>
    /// CalcAndUpdateVATOnLines.
    /// </summary>
    /// <param name="TWERentalHeader">VAR Record "TWE Rental Header".</param>
    /// <param name="TWERentalLine">VAR Record "TWE Rental Line".</param>
    /// <returns>Return variable LinesWereModified of type Boolean.</returns>
    procedure CalcAndUpdateVATOnLines(var TWERentalHeader: Record "TWE Rental Header"; var TWERentalLine: Record "TWE Rental Line") LinesWereModified: Boolean
    var
        TempVATAmountLine0: Record "VAT Amount Line" temporary;
        TempVATAmountLine1: Record "VAT Amount Line" temporary;
    begin
        TWERentalLine.SetRentalHeader(TWERentalHeader);
        // 0 = General, 1 = Invoicing, 2 = Shipping
        TWERentalLine.CalcVATAmountLines(0, TWERentalHeader, TWERentalLine, TempVATAmountLine0, false);
        TWERentalLine.CalcVATAmountLines(1, TWERentalHeader, TWERentalLine, TempVATAmountLine1, false);
        LinesWereModified :=
          TWERentalLine.UpdateVATOnLines(0, TWERentalHeader, TWERentalLine, TempVATAmountLine0) or
          TWERentalLine.UpdateVATOnLines(1, TWERentalHeader, TWERentalLine, TempVATAmountLine1);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcInvDiscount(var TWERentalHeader: Record "TWE Rental Header"; PreviewMode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeManualReleaseRentalDoc(var TWERentalHeader: Record "TWE Rental Header"; PreviewMode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReleaseRentalDoc(var TWERentalHeader: Record "TWE Rental Header"; PreviewMode: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReleaseRentalDoc(var TWERentalHeader: Record "TWE Rental Header"; PreviewMode: Boolean; var LinesWereModified: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterManualReleaseRentalDoc(var TWERentalHeader: Record "TWE Rental Header"; PreviewMode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeManualReOpenRentalDoc(var TWERentalHeader: Record "TWE Rental Header"; PreviewMode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReopenRentalDoc(var TWERentalHeader: Record "TWE Rental Header"; PreviewMode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyRentalDoc(var TWERentalHeader: Record "TWE Rental Header"; PreviewMode: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePerformManualRelease(var TWERentalHeader: Record "TWE Rental Header"; PreviewMode: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRentalLineFind(var TWERentalLine: Record "TWE Rental Line"; var TWERentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReopenRentalDoc(var TWERentalHeader: Record "TWE Rental Header"; PreviewMode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterManualReOpenRentalDoc(var TWERentalHeader: Record "TWE Rental Header"; PreviewMode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPerformManualCheckAndRelease(var TWERentalHeader: Record "TWE Rental Header"; PreviewMode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReleaseATOs(var TWERentalHeader: Record "TWE Rental Header"; var TWERentalLine: Record "TWE Rental Line"; PreviewMode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateRentalDocLines(var TWERentalHeader: Record "TWE Rental Header"; var LinesWereModified: Boolean; PreviewMode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterCheck(TWERentalHeader: Record "TWE Rental Header"; var TWERentalLine: Record "TWE Rental Line"; var LinesWereModified: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterRentalLineCheck(var TWERentalLine: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckCustomerCreated(var TWERentalHeader: Record "TWE Rental Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePerformManualCheckAndRelease(var TWERentalHeader: Record "TWE Rental Header"; PreviewMode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReopenOnBeforeRentalHeaderModify(var TWERentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPerformManualReleaseOnBeforeTestSalesPrepayment(var TWERentalHeader: Record "TWE Rental Header"; PreviewMode: Boolean)
    begin
    end;
}

