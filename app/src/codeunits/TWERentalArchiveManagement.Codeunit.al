/// <summary>
/// Codeunit TWE Rental Archive Management (ID 50012).
/// </summary>
codeunit 50012 "TWE Rental Archive Management"
{

    trigger OnRun()
    begin
    end;

    var

        ReleaseRentalDoc: Codeunit "TWE Release Rental Document";
        RecordLinkManagement: Codeunit "Record Link Management";
        Text009Lbl: Label 'Unposted %1 %2 does not exist anymore.\It is not possible to restore the %1.', Comment = '%1 = Document Type, %2 = Document No.';
        Text001Lbl: Label 'Document %1 has been archived.', Comment = '%1 = Document No.';
        Text002Lbl: Label 'Do you want to Restore %1 %2 Version %3?', Comment = '%1 = Document Type, %2 = Document No., %3 = Document Version';
        Text003Lbl: Label '%1 %2 has been restored.', Comment = '%1 = Document Type, %2 = Document No.';
        Text004Lbl: Label 'Document restored from Version %1.', Comment = '%1 = Document Version';
        Text005Lbl: Label '%1 %2 has been partly posted.\Restore not possible.', Comment = '%1 = Document Type, %2 = Document No.';
        Text006Lbl: Label 'Entries exist for on or more of the following:\  - %1\  - %2\  - %3.\Restoration of document will delete these entries.\Continue with restore?',
                    Comment = '%1 = ReservEntry TableCaption, %2 = ItemChargeAssgntSales TableCaption,%3 = Text008Lbl';
        Text007Lbl: Label 'Archive %1 no.: %2?', Comment = '%1 = Document Type, %2 = Document No.';
        Text008Lbl: Label 'Item Tracking Line';

    /// <summary>
    /// AutoArchiveRentalDocument.
    /// </summary>
    /// <param name="RentalHeader">VAR Record "TWE Rental Header".</param>
    procedure AutoArchiveRentalDocument(var RentalHeader: Record "TWE Rental Header")
    var
        RentalSetup: Record "TWE Rental Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAutoArchiveRentalDocument(RentalHeader, IsHandled);
        if IsHandled then
            exit;

        RentalSetup.Get();
        case RentalHeader."Document Type" of
            RentalHeader."Document Type"::Quote:
                case RentalSetup."Archive Quotes" of
                    RentalSetup."Archive Quotes"::Always:
                        ArchRentalDocumentNoConfirm(RentalHeader);
                    RentalSetup."Archive Quotes"::Question:
                        ArchiveRentalDocument(RentalHeader);
                end;
            RentalHeader."Document Type"::Contract:
                if RentalSetup."Archive Contracts" then
                    ArchRentalDocumentNoConfirm(RentalHeader);
        end;
        OnAfterAutoArchiveRentalDocument(RentalHeader);
    end;

    /// <summary>
    /// ArchiveRentalDocument.
    /// </summary>
    /// <param name="RentalHeader">VAR Record "TWE Rental Header".</param>
    procedure ArchiveRentalDocument(var RentalHeader: Record "TWE Rental Header")
    var
        ConfirmManagement: Codeunit "Confirm Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeArchiveSalesDocument(RentalHeader, IsHandled);
        if IsHandled then
            exit;

        if ConfirmManagement.GetResponseOrDefault(
             StrSubstNo(Text007Lbl, RentalHeader."Document Type", RentalHeader."No."), true)
        then begin
            StoreRentalDocument(RentalHeader, false);
            Message(Text001Lbl, RentalHeader."No.");
        end;
    end;

    /// <summary>
    /// StoreRentalDocument.
    /// </summary>
    /// <param name="RentalHeader">VAR Record "TWE Rental Header".</param>
    /// <param name="InteractionExist">Boolean.</param>
    procedure StoreRentalDocument(var RentalHeader: Record "TWE Rental Header"; InteractionExist: Boolean)
    var
        RentalLine: Record "TWE Rental Line";
        RentalHeaderArchive: Record "TWE Rental Header Archive";
        RentalLineArchive: Record "TWE Rental Line Archive";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeStoreRentalDocument(RentalHeader, IsHandled);
        if IsHandled then
            exit;

        RentalHeaderArchive.Init();
        RentalHeaderArchive.TransferFields(RentalHeader);
        RentalHeaderArchive."Archived By" := CopyStr(UserId, 1, MaxStrLen(RentalHeaderArchive."Archived By"));
        RentalHeaderArchive."Date Archived" := WorkDate();
        RentalHeaderArchive."Time Archived" := Time;
        RentalHeaderArchive."Version No." :=
            GetNextVersionNo(
                DATABASE::"Sales Header", RentalHeader."Document Type".AsInteger(), RentalHeader."No.", RentalHeader."Doc. No. Occurrence");
        RecordLinkManagement.CopyLinks(RentalHeader, RentalHeaderArchive);
        OnBeforeSalesHeaderArchiveInsert(RentalHeaderArchive, RentalHeader);
        RentalHeaderArchive.Insert();
        OnAfterSalesHeaderArchiveInsert(RentalHeaderArchive, RentalHeader);

        StoreRentalDocumentComments(
            RentalHeader."Document Type".AsInteger(), RentalHeader."No.", RentalHeader."Doc. No. Occurrence", RentalHeaderArchive."Version No.");

        RentalLine.SetRange("Document Type", RentalHeader."Document Type");
        RentalLine.SetRange("Document No.", RentalHeader."No.");
        if RentalLine.FindSet() then
            repeat
                RentalLineArchive.Init();
                RentalLineArchive.TransferFields(RentalLine);
                RentalLineArchive."Doc. No. Occurrence" := RentalHeader."Doc. No. Occurrence";
                RentalLineArchive."Version No." := RentalHeaderArchive."Version No.";
                RecordLinkManagement.CopyLinks(RentalLine, RentalLineArchive);
                OnBeforeRentalLineArchiveInsert(RentalLineArchive, RentalLine);
                RentalLineArchive.Insert();

                OnAfterStoreRentalLineArchive(RentalHeader, RentalLine, RentalHeaderArchive, RentalLineArchive);
            until RentalLine.Next() = 0;

        OnAfterStoreRentalDocument(RentalHeader, RentalHeaderArchive);
    end;

    /// <summary>
    /// RestoreRentalDocument.
    /// </summary>
    /// <param name="RentalHeaderArchive">VAR Record "TWE Rental Header Archive".</param>
    procedure RestoreRentalDocument(var RentalHeaderArchive: Record "TWE Rental Header Archive")
    var
        RentalHeader: Record "TWE Rental Header";
        RentalShptHeader: Record "TWE Rental Shipment Header";
        RentalInvHeader: Record "TWE Rental Invoice Header";
        ReservEntry: Record "Reservation Entry";
        ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)";
        ConfirmManagement: Codeunit "Confirm Management";
        ConfirmRequired: Boolean;
        RestoreDocument: Boolean;
        OldOpportunityNo: Code[20];
        IsHandled: Boolean;
        DoCheck: Boolean;
    begin
        OnBeforeRestoreRentalDocument(RentalHeaderArchive, IsHandled);
        if IsHandled then
            exit;

        if not RentalHeader.Get(RentalHeaderArchive."Document Type", RentalHeaderArchive."No.") then
            Error(Text009Lbl, RentalHeaderArchive."Document Type", RentalHeaderArchive."No.");

        RentalHeader.TestField(Status, RentalHeader.Status::Open);

        DoCheck := true;
        OnBeforeCheckIfDocumentIsPartiallyPosted(RentalHeaderArchive, DoCheck);

        if (RentalHeader."Document Type" = RentalHeader."Document Type"::Contract) and DoCheck then begin
            RentalShptHeader.Reset();
            RentalShptHeader.SetCurrentKey("Order No.");
            RentalShptHeader.SetRange("Order No.", RentalHeader."No.");
            if not RentalShptHeader.IsEmpty then
                Error(Text005Lbl, RentalHeader."Document Type", RentalHeader."No.");
            RentalInvHeader.Reset();
            RentalInvHeader.SetCurrentKey("Order No.");
            RentalInvHeader.SetRange("Order No.", RentalHeader."No.");
            if not RentalInvHeader.IsEmpty then
                Error(Text005Lbl, RentalHeader."Document Type", RentalHeader."No.");
        end;

        ConfirmRequired := false;
        ReservEntry.Reset();
        ReservEntry.SetCurrentKey("Source ID", "Source Ref. No.", "Source Type", "Source Subtype");
        ReservEntry.SetRange("Source ID", RentalHeader."No.");
        ReservEntry.SetRange("Source Type", DATABASE::"Sales Line");
        ReservEntry.SetRange("Source Subtype", RentalHeader."Document Type");
        if ReservEntry.FindFirst() then
            ConfirmRequired := true;

        ItemChargeAssgntSales.Reset();
        ItemChargeAssgntSales.SetRange("Document Type", RentalHeader."Document Type");
        ItemChargeAssgntSales.SetRange("Document No.", RentalHeader."No.");
        if ItemChargeAssgntSales.FindFirst() then
            ConfirmRequired := true;

        RestoreDocument := false;
        if ConfirmRequired then begin
            if ConfirmManagement.GetResponseOrDefault(
                 StrSubstNo(
                   Text006Lbl, ReservEntry.TableCaption, ItemChargeAssgntSales.TableCaption, Text008Lbl), true)
            then
                RestoreDocument := true;
        end else
            if ConfirmManagement.GetResponseOrDefault(
                 StrSubstNo(
                   Text002Lbl, RentalHeaderArchive."Document Type",
                   RentalHeaderArchive."No.", RentalHeaderArchive."Version No."), true)
            then
                RestoreDocument := true;
        if RestoreDocument then begin
            RentalHeader.TestField("Doc. No. Occurrence", RentalHeaderArchive."Doc. No. Occurrence");
            RentalHeaderArchive.CalcFields("Work Description");
            if RentalHeader."Opportunity No." <> '' then begin
                OldOpportunityNo := RentalHeader."Opportunity No.";
                RentalHeader."Opportunity No." := '';
            end;
            OnRestoreDocumentOnBeforeDeleteRentalHeader(RentalHeader);
            RentalHeader.DeleteLinks();
            RentalHeader.Delete(true);
            OnRestoreDocumentOnAfterDeleteRentalHeader(RentalHeader);

            RentalHeader.Init();
            RentalHeader.SetHideValidationDialog(true);
            RentalHeader."Document Type" := RentalHeaderArchive."Document Type";
            RentalHeader."No." := RentalHeaderArchive."No.";
            OnBeforeSalesHeaderInsert(RentalHeader, RentalHeaderArchive);
            RentalHeader.Insert(true);
            OnRestoreSalesDocumentOnAfterRentalHeaderInsert(RentalHeader, RentalHeaderArchive);
            RentalHeader.TransferFields(RentalHeaderArchive);
            RentalHeader.Status := RentalHeader.Status::Open;
            if RentalHeaderArchive."Rented-to Contact No." <> '' then
                RentalHeader.Validate("Rented-to Contact No.", RentalHeaderArchive."Rented-to Contact No.")
            else
                RentalHeader.Validate("Rented-to Customer No.", RentalHeaderArchive."Rented-to Customer No.");
            if RentalHeaderArchive."Bill-to Contact No." <> '' then
                RentalHeader.Validate("Bill-to Contact No.", RentalHeaderArchive."Bill-to Contact No.")
            else
                RentalHeader.Validate("Bill-to Customer No.", RentalHeaderArchive."Bill-to Customer No.");
            RentalHeader.Validate("Salesperson Code", RentalHeaderArchive."Salesperson Code");
            RentalHeader.Validate("Payment Terms Code", RentalHeaderArchive."Payment Terms Code");
            RentalHeader.Validate("Payment Discount %", RentalHeaderArchive."Payment Discount %");
            RentalHeader."Shortcut Dimension 1 Code" := RentalHeaderArchive."Shortcut Dimension 1 Code";
            RentalHeader."Shortcut Dimension 2 Code" := RentalHeaderArchive."Shortcut Dimension 2 Code";
            RentalHeader."Dimension Set ID" := RentalHeaderArchive."Dimension Set ID";
            RecordLinkManagement.CopyLinks(RentalHeaderArchive, RentalHeader);
            RentalHeader.LinkSalesDocWithOpportunity(OldOpportunityNo);
            OnAfterTransferFromArchToRentalHeader(RentalHeader, RentalHeaderArchive);
            RentalHeader.Modify(true);
            RestoreRentalLines(RentalHeaderArchive, RentalHeader);
            RentalHeader.Status := RentalHeader.Status::Released;
            ReleaseRentalDoc.Reopen(RentalHeader);
            OnAfterRestoreRentalDocument(RentalHeader, RentalHeaderArchive);

            Message(Text003Lbl, RentalHeader."Document Type", RentalHeader."No.");
        end;
    end;

    local procedure RestoreRentalLines(var RentalHeaderArchive: Record "TWE Rental Header Archive"; RentalHeader: Record "TWE Rental Header")
    var
        RentalLine: Record "TWE Rental Line";
        RentalLineArchive: Record "TWE Rental Line Archive";
    begin
        RestoreSalesLineComments(RentalHeaderArchive, RentalHeader);

        RentalLineArchive.SetRange("Document Type", RentalHeaderArchive."Document Type");
        RentalLineArchive.SetRange("Document No.", RentalHeaderArchive."No.");
        RentalLineArchive.SetRange("Doc. No. Occurrence", RentalHeaderArchive."Doc. No. Occurrence");
        RentalLineArchive.SetRange("Version No.", RentalHeaderArchive."Version No.");
        OnRestoreRentalLinesOnAfterRentalLineArchiveSetFilters(RentalLineArchive, RentalHeaderArchive, RentalHeader);
        if RentalLineArchive.FindSet() then
            repeat
                RentalLine.Init();
                RentalLine.TransferFields(RentalLineArchive);
                OnRestoreRentalLinesOnBeforeRentalLineInsert(RentalLine, RentalLineArchive);
                RentalLine.Insert(true);
                OnRestoreRentalLinesOnAfterRentalLineInsert(RentalLine, RentalLineArchive);
                if RentalLine.Type <> RentalLine.Type::" " then begin
                    RentalLine.Validate("No.");
                    if RentalLineArchive."Variant Code" <> '' then
                        RentalLine.Validate("Variant Code", RentalLineArchive."Variant Code");
                    if RentalLineArchive."Unit of Measure Code" <> '' then
                        RentalLine.Validate("Unit of Measure Code", RentalLineArchive."Unit of Measure Code");
                    RentalLine.Validate("Location Code", RentalLineArchive."Location Code");
                    if RentalLine.Quantity <> 0 then
                        RentalLine.Validate(Quantity, RentalLineArchive.Quantity);
                    OnRestoreRentalLinesOnAfterValidateQuantity(RentalLine, RentalLineArchive);
                    RentalLine.Validate("Unit Price", RentalLineArchive."Unit Price");
                    RentalLine.Validate("Unit Cost (LCY)", RentalLineArchive."Unit Cost (LCY)");
                    RentalLine.Validate("Line Discount %", RentalLineArchive."Line Discount %");
                    if RentalLineArchive."Inv. Discount Amount" <> 0 then
                        RentalLine.Validate("Inv. Discount Amount", RentalLineArchive."Inv. Discount Amount");
                    if RentalLine.Amount <> RentalLineArchive.Amount then
                        RentalLine.Validate(Amount, RentalLineArchive.Amount);
                    RentalLine.Validate(Description, RentalLineArchive.Description);
                end;
                RentalLine."Shortcut Dimension 1 Code" := RentalLineArchive."Shortcut Dimension 1 Code";
                RentalLine."Shortcut Dimension 2 Code" := RentalLineArchive."Shortcut Dimension 2 Code";
                RentalLine."Dimension Set ID" := RentalLineArchive."Dimension Set ID";
                RentalLine."Deferral Code" := RentalLineArchive."Deferral Code";
                RecordLinkManagement.CopyLinks(RentalLineArchive, RentalLine);
                OnAfterTransferFromArchToRentalLine(RentalLine, RentalLineArchive);
                RentalLine.Modify(true);


                OnAfterRestoreRentalLine(RentalHeader, RentalLine, RentalHeaderArchive, RentalLineArchive);
            until RentalLineArchive.Next() = 0;

        OnAfterRestoreRentalLines(RentalHeader, RentalLine, RentalHeaderArchive, RentalLineArchive);
    end;

    /// <summary>
    /// GetNextOccurrenceNo.
    /// </summary>
    /// <param name="TableId">Integer.</param>
    /// <param name="DocType">Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order".</param>
    /// <param name="DocNo">Code[20].</param>
    /// <returns>Return variable OccurenceNo of type Integer.</returns>
    procedure GetNextOccurrenceNo(TableId: Integer; DocType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order"; DocNo: Code[20]) OccurenceNo: Integer
    var
        RentalHeaderArchive: Record "TWE Rental Header Archive";
    begin
        case TableId of
            DATABASE::"TWE Rental Header":
                begin
                    RentalHeaderArchive.LockTable();
                    RentalHeaderArchive.SetRange("Document Type", DocType);
                    RentalHeaderArchive.SetRange("No.", DocNo);
                    if RentalHeaderArchive.FindLast() then
                        exit(RentalHeaderArchive."Doc. No. Occurrence" + 1);

                    exit(1);
                end;
            else begin
                    OnGetNextOccurrenceNo(TableId, DocType, DocNo, OccurenceNo);
                    exit(OccurenceNo)
                end;
        end;
    end;

    /// <summary>
    /// GetNextVersionNo.
    /// </summary>
    /// <param name="TableId">Integer.</param>
    /// <param name="DocType">Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order".</param>
    /// <param name="DocNo">Code[20].</param>
    /// <param name="DocNoOccurrence">Integer.</param>
    /// <returns>Return variable VersionNo of type Integer.</returns>
    procedure GetNextVersionNo(TableId: Integer; DocType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order"; DocNo: Code[20]; DocNoOccurrence: Integer) VersionNo: Integer
    var
        RentalHeaderArchive: Record "TWE Rental Header Archive";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetNextVersionNo(TableId, DocType, DocNo, DocNoOccurrence, VersionNo, IsHandled);
        if IsHandled then
            exit(VersionNo);

        case TableId of
            DATABASE::"TWE Rental Header":
                begin
                    RentalHeaderArchive.LockTable();
                    RentalHeaderArchive.SetRange("Document Type", DocType);
                    RentalHeaderArchive.SetRange("No.", DocNo);
                    RentalHeaderArchive.SetRange("Doc. No. Occurrence", DocNoOccurrence);
                    if RentalHeaderArchive.FindLast() then
                        exit(RentalHeaderArchive."Version No." + 1);

                    exit(1);
                end;
            else begin
                    OnGetNextVersionNo(TableId, DocType, DocNo, DocNoOccurrence, VersionNo);
                    exit(VersionNo)
                end;
        end;
    end;

    /// <summary>
    /// SalesDocArchiveGranule.
    /// </summary>
    /// <returns>Return value of type Boolean.</returns>
    procedure SalesDocArchiveGranule(): Boolean
    var
        RentalHeaderArchive: Record "TWE Rental Header Archive";
    begin
        exit(RentalHeaderArchive.WritePermission);
    end;

    local procedure StoreRentalDocumentComments(DocType: Option; DocNo: Code[20]; DocNoOccurrence: Integer; VersionNo: Integer)
    var
        RentalCommentLine: Record "TWE Rental Comment Line";
        RentalCommentLineArch: Record "TWE Rental Comment Line Arch.";
    begin
        RentalCommentLine.SetRange("Document Type", DocType);
        RentalCommentLine.SetRange("No.", DocNo);
        if RentalCommentLine.FindSet() then
            repeat
                RentalCommentLineArch.Init();
                RentalCommentLineArch.TransferFields(RentalCommentLine);
                RentalCommentLineArch."Doc. No. Occurrence" := DocNoOccurrence;
                RentalCommentLineArch."Version No." := VersionNo;
                RentalCommentLineArch.Insert();
            until RentalCommentLine.Next() = 0;
    end;

    /// <summary>
    /// ArchRentalDocumentNoConfirm.
    /// </summary>
    /// <param name="RentalHeader">VAR Record "TWE Rental Header".</param>
    procedure ArchRentalDocumentNoConfirm(var RentalHeader: Record "TWE Rental Header")
    begin
        StoreRentalDocument(RentalHeader, false);
    end;

    local procedure RestoreSalesLineComments(RentalHeaderArchive: Record "TWE Rental Header Archive"; RentalHeader: Record "TWE Rental Header")
    var
        RentalCommentLineArchive: Record "TWE Rental Comment Line Arch.";
        RentalCommentLine: Record "TWE Rental Comment Line";
        NextLine: Integer;
    begin
        RentalCommentLineArchive.SetRange("Document Type", RentalHeaderArchive."Document Type");
        RentalCommentLineArchive.SetRange("No.", RentalHeaderArchive."No.");
        RentalCommentLineArchive.SetRange("Doc. No. Occurrence", RentalHeaderArchive."Doc. No. Occurrence");
        RentalCommentLineArchive.SetRange("Version No.", RentalHeaderArchive."Version No.");
        if RentalCommentLineArchive.FindSet() then
            repeat
                RentalCommentLine.Init();
                RentalCommentLine.TransferFields(RentalCommentLineArchive);
                RentalCommentLine.Insert();
            until RentalCommentLineArchive.Next() = 0;

        RentalCommentLine.SetRange("Document Type", RentalHeader."Document Type");
        RentalCommentLine.SetRange("No.", RentalHeader."No.");
        RentalCommentLine.SetRange("Document Line No.", 0);
        if RentalCommentLine.FindLast() then
            NextLine := RentalCommentLine."Line No.";
        NextLine += 10000;
        RentalCommentLine.Init();
        RentalCommentLine."Document Type" := RentalHeader."Document Type";
        RentalCommentLine."No." := RentalHeader."No.";
        RentalCommentLine."Document Line No." := 0;
        RentalCommentLine."Line No." := NextLine;
        RentalCommentLine.Date := WorkDate();
        RentalCommentLine.Comment := StrSubstNo(Text004Lbl, Format(RentalHeaderArchive."Version No."));
        RentalCommentLine.Insert();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAutoArchiveRentalDocument(var RentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterStoreRentalDocument(var RentalHeader: Record "TWE Rental Header"; var RentalHeaderArchive: Record "TWE Rental Header Archive")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterStoreRentalLineArchive(var RentalHeader: Record "TWE Rental Header"; var RentalLine: Record "TWE Rental Line"; var RentalHeaderArchive: Record "TWE Rental Header Archive"; var RentalLineArchive: Record "TWE Rental Line Archive")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRestoreRentalDocument(var RentalHeader: Record "TWE Rental Header"; var RentalHeaderArchive: Record "TWE Rental Header Archive")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRestoreRentalLine(var RentalHeader: Record "TWE Rental Header"; var RentalLine: Record "TWE Rental Line"; var RentalHeaderArchive: Record "TWE Rental Header Archive"; var RentalLineArchive: Record "TWE Rental Line Archive")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRestoreRentalLines(var RentalHeader: Record "TWE Rental Header"; var RentalLine: Record "TWE Rental Line"; var RentalHeaderArchive: Record "TWE Rental Header Archive"; var RentalLineArchive: Record "TWE Rental Line Archive")
    begin
    end;


    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesHeaderArchiveInsert(var RentalHeaderArchive: Record "TWE Rental Header Archive"; RentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromArchToRentalHeader(var RentalHeader: Record "TWE Rental Header"; var RentalHeaderArchive: Record "TWE Rental Header Archive")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromArchToRentalLine(var RentalLine: Record "TWE Rental Line"; var RentalLineArchive: Record "TWE Rental Line Archive")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAutoArchiveRentalDocument(var RentalHeader: Record "TWE Rental Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesHeaderInsert(var RentalHeader: Record "TWE Rental Header"; RentalHeaderArchive: Record "TWE Rental Header Archive");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRestoreRentalDocument(var RentalHeaderArchive: Record "TWE Rental Header Archive"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckIfDocumentIsPartiallyPosted(var RentalHeaderArchive: Record "TWE Rental Header Archive"; var DoCheck: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetNextVersionNo(TableId: Integer; DocType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order"; DocNo: Code[20]; DocNoOccurrence: Integer; var VersionNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesHeaderArchiveInsert(var RentalHeaderArchive: Record "TWE Rental Header Archive"; RentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRentalLineArchiveInsert(var RentalLineArchive: Record "TWE Rental Line Archive"; RentalLine: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeStoreRentalDocument(var RentalHeader: Record "TWE Rental Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetNextOccurrenceNo(TableId: Integer; DocType: Option; DocNo: Code[20]; var OccurenceNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetNextVersionNo(TableId: Integer; DocType: Option; DocNo: Code[20]; DocNoOccurrence: Integer; var VersionNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRestoreDocumentOnAfterDeleteRentalHeader(var RentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRestoreDocumentOnBeforeDeleteRentalHeader(var RentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRestoreSalesDocumentOnAfterRentalHeaderInsert(var RentalHeader: Record "TWE Rental Header"; RentalHeaderArchive: Record "TWE Rental Header Archive");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRestoreRentalLinesOnAfterRentalLineInsert(var RentalLine: Record "TWE Rental Line"; var RentalLineArchive: Record "TWE Rental Line Archive")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRestoreRentalLinesOnAfterRentalLineArchiveSetFilters(var RentalLineArchive: Record "TWE Rental Line Archive"; var RentalHeaderArchive: Record "TWE Rental Header Archive"; RentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRestoreRentalLinesOnBeforeRentalLineInsert(var RentalLine: Record "TWE Rental Line"; var RentalLineArchive: Record "TWE Rental Line Archive")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRestoreRentalLinesOnAfterValidateQuantity(var RentalLine: Record "TWE Rental Line"; var RentalLineArchive: Record "TWE Rental Line Archive")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeArchiveSalesDocument(var RentalHeader: Record "TWE Rental Header"; var IsHandled: Boolean)
    begin
    end;
}

