/// <summary>
/// Codeunit TWE Rental-Quote to Contract (ID 50055).
/// </summary>
codeunit 50055 "TWE Rental-Quote to Contract"
{
    TableNo = "TWE Rental Header";

    trigger OnRun()
    var
        Cust: Record Customer;
        RentalCommentLine: Record "TWE Rental Comment Line";
        RentalApprovalsMgmt: Codeunit "TWE Rental Approvals Mgmt.";
        RentalCalcDiscountByType: Codeunit "TWE Rental-Calc Disc. By Type";
        RecordLinkManagement: Codeunit "Record Link Management";
        ShouldRedistributeInvoiceAmount: Boolean;
        IsHandled: Boolean;
    begin
        OnBeforeOnRun(Rec);

        Rec.TestField("Document Type", Rec."Document Type"::Quote);
        ShouldRedistributeInvoiceAmount := RentalCalcDiscountByType.ShouldRedistributeInvoiceDiscountAmount(Rec);

        Rec.CheckRentalPostRestrictions();

        Cust.Get(Rec."Rented-to Customer No.");
        Cust.CheckBlockedCustOnDocs(Cust, Rec."Document Type"::Contract, true, false);
        if Rec."Rented-to Customer No." <> Rec."Bill-to Customer No." then begin
            Cust.Get(Rec."Bill-to Customer No.");
            Cust.CheckBlockedCustOnDocs(Cust, Rec."Document Type"::Contract, true, false);
        end;
        Rec.CalcFields("Amount Including VAT", "Work Description");

        Rec.ValidateSalesPersonOnTWERentalHeader(Rec, true, false);

        Rec.CheckForBlockedLines();

        CheckInProgressOpportunities(Rec);

        CreateRentalHeader(Rec, Cust."Prepayment %");

        TransferQuoteToContractLines(TWERentalQuoteLine, Rec, TWERentalContractLine, TWERentalContractHeader, Cust);
        OnAfterInsertAllRentalContractLines(TWERentalContractLine, Rec);

        RentalSetup.Get();
        ArchiveRentalQuote(Rec);

        if RentalSetup."Default Posting Date" = RentalSetup."Default Posting Date"::"No Date" then begin
            TWERentalContractHeader."Posting Date" := 0D;
            TWERentalContractHeader.Modify();
        end;

        RentalCommentLine.CopyComments(Rec."Document Type".AsInteger(), TWERentalContractHeader."Document Type".AsInteger(), Rec."No.", TWERentalContractHeader."No.");
        RecordLinkManagement.CopyLinks(Rec, TWERentalContractHeader);

        //MoveWonLostOpportunites(Rec, TWERentalContractHeader);

        CopyApprovalEntryQuoteToOrder(Rec, TWERentalContractHeader);

        IsHandled := false;
        OnBeforeDeleteRentalQuote(Rec, TWERentalContractHeader, IsHandled, TWERentalQuoteLine);
        if not IsHandled then begin
            RentalApprovalsMgmt.DeleteApprovalEntries(Rec.RecordId);
            Rec.DeleteLinks();
            Rec.Delete();
            TWERentalQuoteLine.DeleteAll();
        end;

        if not ShouldRedistributeInvoiceAmount then
            RentalCalcDiscountByType.ResetRecalculateInvoiceDisc(TWERentalContractHeader);

        OnAfterOnRun(Rec, TWERentalContractHeader);
    end;

    var
        TWERentalQuoteLine: Record "TWE Rental Line";
        TWERentalContractHeader: Record "TWE Rental Header";
        TWERentalContractLine: Record "TWE Rental Line";
        RentalSetup: Record "TWE Rental Setup";
        Text000Lbl: Label 'An open %1 is linked to this %2. The %1 has to be closed before the %2 can be converted to an %3. Do you want to close the %1 now and continue the conversion?', Comment = 'An open Opportunity is linked to this Quote. The Opportunity has to be closed before the Quote can be converted to an Order. Do you want to close the Opportunity now and continue the conversion? %1 = Opportunity TableCaption, %2 = From Document Type, %3 = To Document Type';
        Text001Lbl: Label 'An open %1 is still linked to this %2. The conversion to an %3 was aborted.', Comment = 'An open Opportunity is still linked to this Quote. The conversion to an Order was aborted. %1 = Opportunity TableCaption, %2 = Opportunity From Document Type, %3 = Opportunity To Document Type';

    local procedure CopyApprovalEntryQuoteToOrder(TWERentalHeader: Record "TWE Rental Header"; TWERentalContractHeader: Record "TWE Rental Header")
    var
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyApprovalEntryQuoteToContract(TWERentalHeader, TWERentalContractHeader, IsHandled);
        if not IsHandled then
            ApprovalsMgmt.CopyApprovalEntryQuoteToOrder(TWERentalHeader.RecordId, TWERentalContractHeader."No.", TWERentalContractHeader.RecordId);
    end;

    local procedure CreateRentalHeader(TWERentalHeader: Record "TWE Rental Header"; PrepmtPercent: Decimal)
    begin
        OnBeforeCreateRentalHeader(TWERentalHeader);

        TWERentalContractHeader := TWERentalHeader;
        TWERentalContractHeader."Document Type" := TWERentalContractHeader."Document Type"::Contract;

        TWERentalContractHeader."No. Printed" := 0;
        TWERentalContractHeader.Status := TWERentalContractHeader.Status::Open;
        TWERentalContractHeader."No." := '';
        TWERentalContractHeader."Quote No." := TWERentalHeader."No.";
        TWERentalContractLine.LockTable();
        OnBeforeInsertRentalContractHeader(TWERentalHeader, TWERentalHeader);
        TWERentalContractHeader.Insert(true);
        OnAfterInsertRentalContractHeader(TWERentalHeader, TWERentalHeader);

        TWERentalContractHeader."Order Date" := TWERentalHeader."Order Date";
        if TWERentalHeader."Posting Date" <> 0D then
            TWERentalContractHeader."Posting Date" := TWERentalHeader."Posting Date";

        TWERentalContractHeader.InitFromTWERentalHeader(TWERentalHeader);
        TWERentalContractHeader."Outbound Whse. Handling Time" := TWERentalHeader."Outbound Whse. Handling Time";
        TWERentalContractHeader.Reserve := TWERentalHeader.Reserve;

        TWERentalContractHeader."Prepayment %" := PrepmtPercent;
        if TWERentalContractHeader."Posting Date" = 0D then
            TWERentalContractHeader."Posting Date" := WorkDate();
        OnBeforeModifyRentalContractHeader(TWERentalHeader, TWERentalHeader);
        TWERentalContractHeader.Modify();

        OnAfterCreateRentalHeader(TWERentalHeader, TWERentalHeader);
    end;

    local procedure ArchiveRentalQuote(var TWERentalHeader: Record "TWE Rental Header")
    var
        RentalArchiveManagement: Codeunit "TWE Rental Archive Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeArchiveRentalQuote(TWERentalHeader, TWERentalHeader, IsHandled);
        if IsHandled then
            exit;

        case RentalSetup."Archive Quotes" of
            RentalSetup."Archive Quotes"::Always:
                RentalArchiveManagement.ArchRentalDocumentNoConfirm(TWERentalHeader);
            RentalSetup."Archive Quotes"::Question:
                RentalArchiveManagement.ArchiveRentalDocument(TWERentalHeader);
        end;
    end;

    procedure GetRentalContractHeader(var TWERentalHeader2: Record "TWE Rental Header")
    begin
        TWERentalHeader2 := TWERentalContractHeader;
    end;

    /// <summary>
    /// SetHideValidationDialog.
    /// </summary>
    /// <param name="NewHideValidationDialog">Boolean.</param>
    procedure SetHideValidationDialog(NewHideValidationDialog: Boolean)
    begin
        if NewHideValidationDialog then
            exit;
    end;

    local procedure CheckInProgressOpportunities(var TWERentalHeader: Record "TWE Rental Header")
    var
        Opp: Record Opportunity;
        TempOpportunityEntry: Record "Opportunity Entry" temporary;
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        Opp.Reset();
        Opp.SetCurrentKey("Sales Document Type", "Sales Document No.");
        Opp.SetRange("Sales Document Type", Opp."Sales Document Type"::Quote);
        Opp.SetRange("Sales Document No.", TWERentalHeader."No.");
        Opp.SetRange(Status, Opp.Status::"In Progress");
        if Opp.FindFirst() then begin
            if not ConfirmManagement.GetResponseOrDefault(
                 StrSubstNo(
                   Text000Lbl, Opp.TableCaption, Opp."Sales Document Type"::Quote,
                   Opp."Sales Document Type"::Order), true)
            then
                Error('');
            TempOpportunityEntry.DeleteAll();
            TempOpportunityEntry.Init();
            TempOpportunityEntry.Validate("Opportunity No.", Opp."No.");
            TempOpportunityEntry."Sales Cycle Code" := Opp."Sales Cycle Code";
            TempOpportunityEntry."Contact No." := Opp."Contact No.";
            TempOpportunityEntry."Contact Company No." := Opp."Contact Company No.";
            TempOpportunityEntry."Salesperson Code" := Opp."Salesperson Code";
            TempOpportunityEntry."Campaign No." := Opp."Campaign No.";
            TempOpportunityEntry."Action Taken" := TempOpportunityEntry."Action Taken"::Won;
            // TempOpportunityEntry."Calcd. Current Value (LCY)" := TempOpportunityEntry.GetSalesDocValue(TWERentalHeader);
            TempOpportunityEntry."Cancel Old To Do" := true;
            TempOpportunityEntry."Wizard Step" := 1;
            OnBeforeTempOpportunityEntryInsert(TempOpportunityEntry);
            TempOpportunityEntry.Insert();
            TempOpportunityEntry.SetRange("Action Taken", TempOpportunityEntry."Action Taken"::Won);
            PAGE.RunModal(PAGE::"Close Opportunity", TempOpportunityEntry);
            Opp.Reset();
            Opp.SetCurrentKey("Sales Document Type", "Sales Document No.");
            Opp.SetRange("Sales Document Type", Opp."Sales Document Type"::Quote);
            Opp.SetRange("Sales Document No.", TWERentalHeader."No.");
            Opp.SetRange(Status, Opp.Status::"In Progress");
            if Opp.FindFirst() then
                Error(Text001Lbl, Opp.TableCaption, Opp."Sales Document Type"::Quote, Opp."Sales Document Type"::Order);
            Commit();
            TWERentalHeader.Get(TWERentalHeader."Document Type", TWERentalHeader."No.");
        end;
    end;

    /*     local procedure MoveWonLostOpportunites(var TWERentalQuoteHeader: Record "TWE Rental Header"; var TWERentalContractHeader: Record "TWE Rental Header")
        var
            Opp: Record Opportunity;
            OpportunityEntry: Record "Opportunity Entry";
        begin
            Opp.Reset();
            Opp.SetCurrentKey("Sales Document Type", "Sales Document No.");
            Opp.SetRange("Sales Document Type", Opp."Sales Document Type"::Quote);
            Opp.SetRange("Sales Document No.", TWERentalQuoteHeader."No.");
            if Opp.FindFirst() then
                if Opp.Status = Opp.Status::Won then begin
                    Opp."Sales Document Type" := Opp."Sales Document Type"::Order;
                    Opp."Sales Document No." := TWERentalContractHeader."No.";
                    Opp.Modify();
                    OpportunityEntry.Reset();
                    OpportunityEntry.SetCurrentKey(Active, "Opportunity No.");
                    OpportunityEntry.SetRange(Active, true);
                    OpportunityEntry.SetRange("Opportunity No.", Opp."No.");
                    if OpportunityEntry.FindFirst() then //begin
                        //    OpportunityEntry."Calcd. Current Value (LCY)" := OpportunityEntry.GetSalesDocValue(TWERentalContractHeader);
                        OpportunityEntry.Modify();
                    // end;
                end else
                    if Opp.Status = Opp.Status::Lost then begin
                        Opp."Sales Document Type" := Opp."Sales Document Type"::" ";
                        Opp."Sales Document No." := '';
                        Opp.Modify();
                    end;
        end; */

    local procedure TransferQuoteToContractLines(var TWERentalQuoteLine: Record "TWE Rental Line"; var TWERentalQuoteHeader: Record "TWE Rental Header"; var TWERentalContractLine: Record "TWE Rental Line"; var TWERentalContractHeader: Record "TWE Rental Header"; Customer: Record Customer)
    var
        RentalPrepmtMgt: Codeunit "TWE Rental Prepayment Mgt.";
        IsHandled: Boolean;
    begin
        TWERentalQuoteLine.Reset();
        TWERentalQuoteLine.SetRange("Document Type", TWERentalQuoteHeader."Document Type");
        TWERentalQuoteLine.SetRange("Document No.", TWERentalQuoteHeader."No.");
        OnTransferQuoteToContractLinesOnAfterSetFilters(TWERentalQuoteLine, TWERentalQuoteHeader);
        if TWERentalQuoteLine.FindSet() then
            repeat
                IsHandled := false;
                OnBeforeTransferQuoteLineToContractLineLoop(TWERentalQuoteLine, TWERentalQuoteHeader, TWERentalContractHeader, IsHandled);
                if not IsHandled then begin
                    TWERentalContractLine := TWERentalQuoteLine;
                    TWERentalContractLine."Document Type" := TWERentalContractHeader."Document Type";
                    TWERentalContractLine."Document No." := TWERentalContractHeader."No.";
                    TWERentalContractLine."Shortcut Dimension 1 Code" := TWERentalQuoteLine."Shortcut Dimension 1 Code";
                    TWERentalContractLine."Shortcut Dimension 2 Code" := TWERentalQuoteLine."Shortcut Dimension 2 Code";
                    TWERentalContractLine."Dimension Set ID" := TWERentalQuoteLine."Dimension Set ID";
                    if Customer."Prepayment %" <> 0 then
                        TWERentalContractLine."Prepayment %" := Customer."Prepayment %";
                    RentalPrepmtMgt.SetRentalPrepaymentPct(TWERentalContractLine, TWERentalContractHeader."Posting Date");
                    TWERentalContractLine.Validate("Prepayment %");
                    if TWERentalContractLine."No." <> '' then
                        TWERentalContractLine.DefaultDeferralCode();
                    OnBeforeInsertRentalContractLine(TWERentalContractLine, TWERentalContractHeader, TWERentalQuoteLine, TWERentalQuoteHeader);
                    TWERentalContractLine.Insert();
                    OnAfterInsertRentalContractLine(TWERentalContractLine, TWERentalContractHeader, TWERentalQuoteLine, TWERentalQuoteHeader);
                    if TWERentalContractLine.Reserve = TWERentalContractLine.Reserve::Always then
                        TWERentalContractLine.AutoReserve();
                end;
            until TWERentalQuoteLine.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateRentalHeader(var TWERentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteRentalQuote(var TWERentalQuoteHeader: Record "TWE Rental Header"; var TWERentalContractHeader: Record "TWE Rental Header"; var IsHandled: Boolean; var TWERentalQuoteLine: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertRentalContractHeader(var TWERentalContractHeader: Record "TWE Rental Header"; TWERentalQuoteHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyRentalContractHeader(var TWERentalContractHeader: Record "TWE Rental Header"; TWERentalQuoteHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertRentalContractLine(var TWERentalContractLine: Record "TWE Rental Line"; TWERentalContractHeader: Record "TWE Rental Header"; TWERentalQuoteLine: Record "TWE Rental Line"; TWERentalQuoteHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertRentalContractHeader(var TWERentalContractHeader: Record "TWE Rental Header"; TWERentalQuoteHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertAllRentalContractLines(var TWERentalContractLine: Record "TWE Rental Line"; TWERentalQuoteHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnRun(var TWERentalHeader: Record "TWE Rental Header"; var TWERentalContractHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeArchiveRentalQuote(var TWERentalQuoteHeader: Record "TWE Rental Header"; var TWERentalContractHeader: Record "TWE Rental Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyApprovalEntryQuoteToContract(var TWERentalQuoteHeader: Record "TWE Rental Header"; var TWERentalContractHeader: Record "TWE Rental Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertRentalContractLine(var TWERentalContractLine: Record "TWE Rental Line"; TWERentalContractHeader: Record "TWE Rental Header"; TWERentalQuoteLine: Record "TWE Rental Line"; TWERentalQuoteHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var TWERentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTempOpportunityEntryInsert(var TempOpportunityEntry: Record "Opportunity Entry" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferQuoteLineToContractLineLoop(var TWERentalQuoteLine: Record "TWE Rental Line"; var TWERentalQuoteHeader: Record "TWE Rental Header"; var TWERentalContractHeader: Record "TWE Rental Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferQuoteToContractLinesOnAfterSetFilters(var TWERentalQuoteLine: Record "TWE Rental Line"; var TWERentalQuoteHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateRentalHeader(var TWERentalContractHeader: Record "TWE Rental Header"; TWERentalHeader: Record "TWE Rental Header")
    begin
    end;
}

