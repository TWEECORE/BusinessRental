/// <summary>
/// Codeunit TWE Rental Document-Print (ID 50019).
/// </summary>
codeunit 50019 "TWE Rental Document-Print"
{

    trigger OnRun()
    begin
    end;

    var
        RentalSetup: Record "TWE Rental Setup";

    /// <summary>
    /// EmailRentalHeader.
    /// </summary>
    /// <param name="RentalHeader">Record "TWE Rental Header".</param>
    procedure EmailRentalHeader(RentalHeader: Record "TWE Rental Header")
    begin
        DoPrintRentalHeader(RentalHeader, true);
    end;

    /// <summary>
    /// PrintRentalHeader.
    /// </summary>
    /// <param name="RentalHeader">Record "TWE Rental Header".</param>
    procedure PrintRentalHeader(RentalHeader: Record "TWE Rental Header")
    begin
        DoPrintRentalHeader(RentalHeader, false);
    end;

    /// <summary>
    /// PrintRentalHeaderToDocumentAttachment.
    /// </summary>
    /// <param name="RentalHeader">VAR Record "TWE Rental Header".</param>
    procedure PrintRentalHeaderToDocumentAttachment(var RentalHeader: Record "TWE Rental Header");
    var
        ShowNotificationAction: Boolean;
    begin
        ShowNotificationAction := RentalHeader.Count() = 1;
        if RentalHeader.FindSet() then
            repeat
                DoPrintRentalHeaderToDocumentAttachment(RentalHeader, ShowNotificationAction);
            until RentalHeader.Next() = 0;
    end;

    local procedure DoPrintRentalHeaderToDocumentAttachment(RentalHeader: Record "TWE Rental Header"; ShowNotificationAction: Boolean);
    var
        RentalReportSelections: Record "TWE Rental Report Selections";
        RentalReportUsage: Enum "TWE Rent. Report Sel. Usage";
    begin
        RentalReportUsage := GetRentalDocTypeUsage(RentalHeader);

        RentalHeader.SetRecFilter();
        CalcRentalDisc(RentalHeader);
        RentalReportSelections.SaveAsDocumentAttachment(RentalReportUsage.AsInteger(), RentalHeader, RentalHeader."No.", RentalHeader.GetBillToNo(), ShowNotificationAction);
    end;

    /// <summary>
    /// PrintRentalInvoiceToDocumentAttachment.
    /// </summary>
    /// <param name="RentalHeader">VAR Record "TWE Rental Header".</param>
    /// <param name="RentalInvoicePrintToAttachmentOption">Integer.</param>
    procedure PrintRentalInvoiceToDocumentAttachment(var RentalHeader: Record "TWE Rental Header"; RentalInvoicePrintToAttachmentOption: Integer)
    begin
        case "TWE Rental Inv. Print Option".FromInteger(RentalInvoicePrintToAttachmentOption) of
            "TWE Rental Inv. Print Option"::"Draft Invoice":
                PrintRentalHeaderToDocumentAttachment(RentalHeader);
            "TWE Rental Inv. Print Option"::"Pro Forma Invoice":
                PrintProformaRentalInvoiceToDocumentAttachment(RentalHeader);
        end;
        OnAfterPrintRentalInvoiceToDocumentAttachment(RentalHeader, RentalInvoicePrintToAttachmentOption);
    end;

    /// <summary>
    /// GetRentalInvoicePrintToAttachmentOption.
    /// </summary>
    /// <param name="RentalHeader">Record "TWE Rental Header".</param>
    /// <returns>Return value of type Integer.</returns>
    procedure GetRentalInvoicePrintToAttachmentOption(RentalHeader: Record "TWE Rental Header"): Integer
    var
        StrMenuText: Text;
        PrintOptionCaption: Text;
        i: Integer;
    begin
        foreach i in "TWE Rental Inv. Print Option".Ordinals() do begin
            PrintOptionCaption := Format("TWE Rental Inv. Print Option".FromInteger(i));
            if StrMenuText = '' then
                StrMenuText := PrintOptionCaption
            else
                StrMenuText := StrMenuText + ',' + PrintOptionCaption;
        end;
        exit(StrMenu(StrMenuText));
    end;

    /// <summary>
    /// PrintRentalOrderToDocumentAttachment.
    /// </summary>
    /// <param name="RentalHeader">VAR Record "TWE Rental Header".</param>
    /// <param name="SalesOrderPrintToAttachmentOption">Integer.</param>
    procedure PrintRentalOrderToDocumentAttachment(var RentalHeader: Record "TWE Rental Header"; SalesOrderPrintToAttachmentOption: Integer)
    var
        Usage: Option "Order Confirmation","Work Order","Pick Instruction";
    begin
        case "Sales Order Print Option".FromInteger(SalesOrderPrintToAttachmentOption) of
            "Sales Order Print Option"::"Order Confirmation":
                PrintRentalContractToAttachment(RentalHeader, Usage::"Order Confirmation");
            /*             "Sales Order Print Option"::"Pro Forma Invoice":
                            PrintProformaRentalInvoiceToDocumentAttachment(RentalHeader); */
            "Sales Order Print Option"::"Work Order":
                PrintRentalContractToAttachment(RentalHeader, Usage::"Work Order");
            "Sales Order Print Option"::"Pick Instruction":
                PrintRentalContractToAttachment(RentalHeader, Usage::"Pick Instruction");
        end;
        OnAfterPrintRentalContractToDocumentAttachment(RentalHeader, SalesOrderPrintToAttachmentOption);
    end;

    /// <summary>
    /// GetRentalContractPrintToAttachmentOption.
    /// </summary>
    /// <param name="RentalHeader">Record "TWE Rental Header".</param>
    /// <returns>Return value of type Integer.</returns>
    procedure GetRentalContractPrintToAttachmentOption(RentalHeader: Record "TWE Rental Header"): Integer
    var
        StrMenuText: Text;
        PrintOptionCaption: Text;
        i: Integer;
    begin
        foreach i in "Sales Order Print Option".Ordinals() do begin
            PrintOptionCaption := Format("Sales Order Print Option".FromInteger(i));
            if StrMenuText = '' then
                StrMenuText := PrintOptionCaption
            else
                StrMenuText := StrMenuText + ',' + PrintOptionCaption;
        end;
        exit(StrMenu(StrMenuText));
    end;

    /// <summary>
    /// PrintProformaRentalInvoiceToDocumentAttachment.
    /// </summary>
    /// <param name="RentalHeader">VAR Record "TWE Rental Header".</param>
    procedure PrintProformaRentalInvoiceToDocumentAttachment(var RentalHeader: Record "TWE Rental Header")
    begin
        if RentalHeader.FindSet() then
            repeat
                DoPrintProformaRentalInvoiceToDocumentAttachment(RentalHeader, RentalHeader.Count() = 1)
            until RentalHeader.Next() = 0;
    end;

    local procedure DoPrintProformaRentalInvoiceToDocumentAttachment(RentalHeader: Record "TWE Rental Header"; ShowNotificationAction: Boolean)
    var
        RentalReportSelections: Record "TWE Rental Report Selections";
    begin
        RentalHeader.SetRecFilter();
        CalcRentalDisc(RentalHeader);
        RentalReportSelections.SaveAsDocumentAttachment(
            RentalReportSelections.Usage::"Pro Forma R. Invoice".AsInteger(), RentalHeader, RentalHeader."No.", RentalHeader.GetBillToNo(), ShowNotificationAction);
    end;

    /// <summary>
    /// PrintRentalContractToAttachment.
    /// </summary>
    /// <param name="RentalHeader">VAR Record "TWE Rental Header".</param>
    /// <param name="Usage">Option "Order Confirmation","Work Order","Pick Instruction".</param>
    procedure PrintRentalContractToAttachment(var RentalHeader: Record "TWE Rental Header"; Usage: Option "Order Confirmation","Work Order","Pick Instruction")
    var
        ShowNotificationAction: Boolean;
    begin
        ShowNotificationAction := RentalHeader.Count() = 1;
        if RentalHeader.FindSet() then
            repeat
                DoPrintRentalContractToAttachment(RentalHeader, Usage, ShowNotificationAction);
            until RentalHeader.Next() = 0;
    end;

    local procedure DoPrintRentalContractToAttachment(RentalHeader: Record "TWE Rental Header"; Usage: Option "Order Confirmation","Work Order","Pick Instruction"; ShowNotificationAction: Boolean)
    var
        RentalReportSelections: Record "TWE Rental Report Selections";
        RentalReportUsage: Enum "TWE Rent. Report Sel. Usage";
    begin
        if RentalHeader."Document Type" <> RentalHeader."Document Type"::Contract then
            exit;

        RentalReportUsage := GetRentalOrderUsage(Usage);

        RentalHeader.SetRange("No.", RentalHeader."No.");
        CalcRentalDisc(RentalHeader);

        RentalReportSelections.SaveAsDocumentAttachment(
            RentalReportUsage.AsInteger(), RentalHeader, RentalHeader."No.", RentalHeader.GetBillToNo(), ShowNotificationAction);
    end;

    local procedure DoPrintRentalHeader(RentalHeader: Record "TWE Rental Header"; SendAsEmail: Boolean)
    var
        RentalReportSelections: Record "TWE Rental Report Selections";
        RentalReportUsage: Enum "TWE Rent. Report Sel. Usage";
        IsPrinted: Boolean;
    begin
        RentalReportUsage := GetRentalDocTypeUsage(RentalHeader);

        RentalHeader.SetRange("Document Type", RentalHeader."Document Type");
        RentalHeader.SetRange("No.", RentalHeader."No.");
        CalcRentalDisc(RentalHeader);
        OnBeforeDoPrintRentalHeader(RentalHeader, RentalReportUsage.AsInteger(), SendAsEmail, IsPrinted);
        if IsPrinted then
            exit;

        if SendAsEmail then
            RentalReportSelections.SendEmailToCust(
                RentalReportUsage.AsInteger(), RentalHeader, RentalHeader."No.", RentalHeader.GetDocTypeTxt(), true, RentalHeader.GetBillToNo())
        else
            RentalReportSelections.PrintForCust(RentalReportUsage, RentalHeader, RentalHeader.FieldNo("Bill-to Customer No."));
    end;

    /// <summary>
    /// PrintRentalContract.
    /// </summary>
    /// <param name="RentalHeader">Record "TWE Rental Header".</param>
    /// <param name="Usage">Option "Order Confirmation","Work Order","Pick Instruction".</param>
    procedure PrintRentalContract(RentalHeader: Record "TWE Rental Header"; Usage: Option "Contract")
    var
        RentalReportSelection: Record "TWE Rental Report Selections";
        RentalReportUsage: Enum "TWE Rent. Report Sel. Usage";
        IsPrinted: Boolean;
    begin
        if RentalHeader."Document Type" <> RentalHeader."Document Type"::Contract then
            exit;

        RentalReportUsage := GetRentalOrderUsage(Usage);

        RentalHeader.SetRange("No.", RentalHeader."No.");
        CalcRentalDisc(RentalHeader);
        OnBeforePrintRentalContract(RentalHeader, RentalReportUsage.AsInteger(), IsPrinted);
        if IsPrinted then
            exit;

        RentalReportSelection.PrintWithDialogForCust(
            RentalReportUsage, RentalHeader, GuiAllowed, RentalHeader.FieldNo("Bill-to Customer No."));
    end;

    /// <summary>
    /// PrintRentalHeaderArch.
    /// </summary>
    /// <param name="RentalHeaderArch">Record "TWE Rental Header Archive".</param>
    procedure PrintRentalHeaderArch(RentalHeaderArch: Record "TWE Rental Header Archive")
    var
        RentalReportSelection: Record "TWE Rental Report Selections";
        RentalReportUsage: Enum "TWE Rent. Report Sel. Usage";
        IsPrinted: Boolean;
    begin
        RentalReportUsage := GetRentalArchDocTypeUsage(RentalHeaderArch);

        RentalHeaderArch.SetRecFilter();
        OnBeforePrintRentalHeaderArch(RentalHeaderArch, RentalReportUsage.AsInteger(), IsPrinted);
        if IsPrinted then
            exit;

        RentalReportSelection.PrintForCust(
            RentalReportUsage, RentalHeaderArch, RentalHeaderArch.FieldNo("Bill-to Customer No."));
    end;

    /// <summary>
    /// PrintProformaRentalInvoice.
    /// </summary>
    /// <param name="RentalHeader">Record "TWE Rental Header".</param>
    procedure PrintProformaRentalInvoice(RentalHeader: Record "TWE Rental Header")
    var
        RentalReportSelections: Record "TWE Rental Report Selections";
        IsPrinted: Boolean;
    begin
        RentalHeader.SetRecFilter();
        OnBeforePrintProformaRentalInvoice(RentalHeader, RentalReportSelections.Usage::"Pro Forma R. Invoice".AsInteger(), IsPrinted);
        if IsPrinted then
            exit;

        RentalReportSelections.PrintForCust(
            RentalReportSelections.Usage::"Pro Forma R. Invoice", RentalHeader, RentalHeader.FieldNo("Bill-to Customer No."));
    end;

    local procedure GetRentalDocTypeUsage(RentalHeader: Record "TWE Rental Header") ReportSelectionUsage: Enum "Report Selection Usage"
    var
        RentalReportSelections: Record "TWE Rental Report Selections";
        TypeUsage: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetRentalDocTypeUsage(RentalHeader, ReportSelectionUsage, IsHandled);
        if IsHandled then
            exit(ReportSelectionUsage);

        case RentalHeader."Document Type" of
            RentalHeader."Document Type"::Quote:
                exit(RentalReportSelections.Usage::"R.Quote");
            RentalHeader."Document Type"::Contract:
                exit(RentalReportSelections.Usage::"R.Contract");
            /*             RentalHeader."Document Type"::"Return Shipment":
                            exit(RentalReportSelections.Usage::"R.Return Shipment"); */
            else begin
                    IsHandled := false;
                    OnGetRentalDocTypeUsageElseCase(RentalHeader, TypeUsage, IsHandled);
                    if IsHandled then
                        exit("Report Selection Usage".FromInteger(TypeUsage));
                    Error('');
                end;
        end;
    end;

    local procedure GetRentalOrderUsage(Usage: Option "Order Confirmation","Work Order","Pick Instruction"): Enum "Report Selection Usage"
    var
        RentalReportSelections: Record "TWE Rental Report Selections";
    begin
        case Usage of
            Usage::"Order Confirmation":
                exit(RentalReportSelections.Usage::"R.Contract");
            else
                Error('');
        end;
    end;

    local procedure GetRentalArchDocTypeUsage(RentalHeaderArch: Record "TWE Rental Header Archive"): Enum "Report Selection Usage"
    var
        RentalReportSelections: Record "TWE Rental Report Selections";
        TypeUsage: Integer;
        IsHandled: Boolean;
    begin
        case RentalHeaderArch."Document Type" of
            RentalHeaderArch."Document Type"::Quote:
                exit(RentalReportSelections.Usage::"R.Arch.Quote");
            RentalHeaderArch."Document Type"::Contract:
                exit(RentalReportSelections.Usage::"R.Arch.Contract");
            else begin
                    IsHandled := false;
                    OnGetRentalArchDocTypeUsageElseCase(RentalHeaderArch, TypeUsage, IsHandled);
                    if IsHandled then
                        exit("Report Selection Usage".FromInteger(TypeUsage));
                    Error('');
                end;
        end
    end;

    local procedure CalcRentalDisc(var RentalHeader: Record "TWE Rental Header")
    var
        RentalLine: Record "TWE Rental Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcRentalDisc(RentalHeader, IsHandled);
        if IsHandled then
            exit;

        RentalSetup.Get();
        if RentalSetup."Calc. Inv. Discount" then begin
            RentalLine.Reset();
            RentalLine.SetRange("Document Type", RentalHeader."Document Type");
            RentalLine.SetRange("Document No.", RentalHeader."No.");
            RentalLine.FindFirst();
            CODEUNIT.Run(CODEUNIT::"TWE Rental-Calc. Discount", RentalLine);
            RentalHeader.Get(RentalHeader."Document Type", RentalHeader."No.");
            Commit();
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPrintRentalInvoiceToDocumentAttachment(var RentalHeader: Record "TWE Rental Header"; RentalInvoicePrintToAttachmentOption: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPrintRentalContractToDocumentAttachment(var RentalHeader: Record "TWE Rental Header"; RentalContractPrintToAttachmentOption: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcRentalDisc(var RentalHeader: Record "TWE Rental Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetRentalDocTypeUsage(RentalHeader: Record "TWE Rental Header"; var ReportSelectionUsage: Enum "Report Selection Usage"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDoPrintRentalHeader(var RentalHeader: Record "TWE Rental Header"; ReportUsage: Integer; SendAsEmail: Boolean; var IsPrinted: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintRentalContract(var RentalHeader: Record "TWE Rental Header"; ReportUsage: Integer; var IsPrinted: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintRentalHeaderArch(var RentalHeaderArch: Record "TWE Rental Header Archive"; ReportUsage: Integer; var IsPrinted: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintProformaRentalInvoice(var RentalHeader: Record "TWE Rental Header"; ReportUsage: Integer; var IsPrinted: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetRentalDocTypeUsageElseCase(RentalHeader: Record "TWE Rental Header"; var TypeUsage: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetRentalArchDocTypeUsageElseCase(RentalHeaderArchive: Record "TWE Rental Header Archive"; var TypeUsage: Integer; var IsHandled: Boolean)
    begin
    end;
}

