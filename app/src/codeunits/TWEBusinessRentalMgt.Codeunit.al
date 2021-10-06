/// <summary>
/// Codeunit TWE Business Rental Mgt. (ID 50002).
/// </summary>
codeunit 50002 "TWE Business Rental Mgt."
{
    trigger OnRun()
    begin

    end;

    //HELPER FUNCTIONS

    var
        DateRec: Record Date;


    /// <summary>
    /// CalculateDaysToInvoice.
    /// </summary>
    /// <param name="ActualRentalRateCode">Code[20].</param>
    /// <param name="StartDate">Date.</param>
    /// <param name="EndDate">Date.</param>
    /// <returns>Return variable calculatedDays of type Decimal.</returns>
    procedure CalculateTotalDaysToInvoice(ActualRentalRateCode: Code[20]; StartDate: Date; EndDate: Date) calculatedDays: Decimal
    var
        CustomizedCalendarChange: Record "Customized Calendar Change";
        tweRentalRatesRec: Record "TWE Rental Rates";
        CalendarManagement: Codeunit "Calendar Management";
        ActualCalendarCode: Code[10];
        TotalQtyDays: Decimal;
        ProofDate: Date;
        EndDateEarlierThanStartDateErr: Label 'End date cannot be earlier than the start date.';
    begin
        if (StartDate = 0D) and (EndDate = 0D) then
            exit;
        if StartDate > EndDate then
            Error(EndDateEarlierThanStartDateErr);

        TotalQtyDays := EndDate - StartDate + 1;

        ProofDate := StartDate;

        CustomizedCalendarChange.CalcCalendarCode();

        if tweRentalRatesRec.Get(ActualRentalRateCode) then
            ActualCalendarCode := tweRentalRatesRec."Rental Calendar";


        case tweRentalRatesRec."Rental Rate Type" of
            "TWE Rental Rate Type"::" ",
            "TWE Rental Rate Type"::"By Hour",
            "TWE Rental Rate Type"::"Daily Basis":
                begin
                    GetDate(StartDate, CustomizedCalendarChange, ActualCalendarCode);

                    CustomizedCalendarChange.SetRange("Source Type", 0);
                    CustomizedCalendarChange.SetRange("Base Calendar Code", ActualCalendarCode);
                    CustomizedCalendarChange.SetFilter(Date, '%1..%2', StartDate, EndDate);
                    if CustomizedCalendarChange.FindSet() then
                        repeat
                            if CalendarManagement.IsNonworkingDay(ProofDate, CustomizedCalendarChange) then
                                TotalQtyDays := TotalQtyDays - 1;
                            ProofDate := CalcDate('<+1D>', ProofDate);
                        until ProofDate > EndDate;
                end;

            "TWE Rental Rate Type"::"Flat Rate":
                begin
                    EndDate := CalcDate(tweRentalRatesRec."DateFormular for Flat Rate", StartDate);
                    TotalQtyDays := EndDate - StartDate;
                end;
        end;

        exit(TotalQtyDays);
    end;

    /// <summary>
    /// CalculateDaysToInvoice.
    /// </summary>
    /// <param name="ActualRentalRateCode">Code[20].</param>
    /// <param name="InvoicingPeriodCode">Code[20].</param>
    /// <param name="StartDate">Date.</param>
    /// <param name="EndDate">Date.</param>
    /// <returns>Return variable calculatedDays of type Decimal.</returns>
    procedure CalculateDaysToInvoice(ActualRentalRateCode: Code[20]; InvoicingPeriodCode: Code[20]; StartDate: Date; EndDate: Date) calculatedDays: Decimal
    var
        CustomizedCalendarChange: Record "Customized Calendar Change";
        TWERentalRatesRec: Record "TWE Rental Rates";
        InvoicingPeriod: Record "TWE Rental Invoicing Period";
        CalendarManagement: Codeunit "Calendar Management";
        ActualCalendarCode: Code[10];
        CalcDate: Date;
        TotalQtyDays: Decimal;
        ProofDate: Date;
        EndDateEarlierThanStartDateErr: Label 'End date cannot be earlier than the start date.';
    begin
        if ((StartDate = 0D) and (EndDate = 0D)) or (InvoicingPeriodCode = '') then
            exit;

        if StartDate > EndDate then
            Error(EndDateEarlierThanStartDateErr);

        if not InvoicingPeriod.Get(InvoicingPeriodCode) then
            exit;

        CalcDate := CalcDate(InvoicingPeriod.DateFormular, StartDate);
        if CalcDate > EndDate then
            CalcDate := EndDate;

        TotalQtyDays := EndDate - StartDate + 1;

        ProofDate := StartDate;

        CustomizedCalendarChange.CalcCalendarCode();

        if TWERentalRatesRec.Get(ActualRentalRateCode) then
            ActualCalendarCode := TWERentalRatesRec."Rental Calendar";

        GetDate(StartDate, CustomizedCalendarChange, ActualCalendarCode);

        CustomizedCalendarChange.SetRange("Source Type", 0);
        CustomizedCalendarChange.SetRange("Base Calendar Code", ActualCalendarCode);
        CustomizedCalendarChange.SetFilter(Date, '%1..%2', StartDate, EndDate);
        if CustomizedCalendarChange.FindSet() then begin
            repeat
                if CalendarManagement.IsNonworkingDay(ProofDate, CustomizedCalendarChange) then
                    TotalQtyDays := TotalQtyDays - 1;
                ProofDate := CalcDate('<+1D>', ProofDate);
            until ProofDate > EndDate;

            exit(TotalQtyDays);
        end;
    end;

    /// <summary>
    /// CalculateNextInvoiceDates.
    /// </summary>
    /// <param name="tweRentalLine">Record "TWE Rental Line".</param>
    procedure CalculateNextInvoiceDates(var tweRentalLine: Record "TWE Rental Line")
    var
        tweRentalHeaderRec: Record "TWE Rental Header";
        tweRentalInvoicingPeriod: Record "TWE Rental Invoicing Period";
        nextBillingStartDate: Date;
        nextBillingEndDate: Date;
    begin
        if tweRentalHeaderRec.Get(tweRentalLine."Document Type", tweRentalLine."Document No.") then
            if tweRentalInvoicingPeriod.Get(tweRentalLine."Invoicing Period") then begin
                if tweRentalLine."Billing Start Date" = 0D then begin
                    nextBillingStartDate := tweRentalHeaderRec."Rental Start";
                    nextBillingEndDate := CALCDATE(tweRentalInvoicingPeriod.DateFormular, tweRentalHeaderRec."Rental Start");
                end else begin
                    nextBillingStartDate := CALCDATE(tweRentalInvoicingPeriod.DateFormular, tweRentalLine."Billing Start Date");
                    nextBillingEndDate := CALCDATE(tweRentalInvoicingPeriod.DateFormular, nextBillingStartDate);

                    if nextBillingStartDate >= tweRentalHeaderRec."Rental End" then begin
                        tweRentalLine."Line Closed" := true;
                        tweRentalLine."Billing Start Date" := 0D;
                        tweRentalLine."Billing End Date" := 0D;
                        tweRentalLine."Duration to be billed" := 0;
                        exit;
                    end;
                end;

                if nextBillingEndDate > tweRentalHeaderRec."Rental End" then
                    nextBillingEndDate := tweRentalHeaderRec."Rental End";

                if (nextBillingStartDate = 0D) then
                    exit;

                tweRentalLine."Billing Start Date" := nextBillingStartDate;
                tweRentalLine."Billing End Date" := nextBillingEndDate;

                case tweRentalInvoicingPeriod."Period Delimitation" of
                    "TWE Rental Invoicing Period Type"::"First Day of Period":
                        tweRentalLine."Invoicing Date" := CALCDATE('<+1D>', nextBillingStartDate);

                    "TWE Rental Invoicing Period Type"::"Last Day of Period":
                        tweRentalLine."Invoicing Date" := CALCDATE('<+1D>', nextBillingEndDate);

                    "TWE Rental Invoicing Period Type"::"Fixed Day":
                        tweRentalLine."Invoicing Date" := CALCDATE('<+1D>', nextBillingStartDate);
                end;
            end;
    end;

    //END HELPER FUNCTIONS

    /// <summary>
    /// GetDataForRentalUnbookedInvoice.
    /// </summary>
    /// <param name="RentalHeader">VAR Record "TWE Rental Header".</param>
    procedure GetDataForRentalUnbookedInvoice(var RentalHeader: Record "TWE Rental Header")
    var
        RentalInvHeader: Record "TWE Rental Header";
        RentalInvLine: Record "TWE Rental Line";
        RentalLine: Record "TWE Rental Line";
        RentalSetup: Record "TWE Rental Setup";
        TWERentalInvoice: Page "TWE Rental Invoice";
        OpenPage: Boolean;
        OpenNewInvoiceQst: Label 'The contract has been converted to invoice %1. Do you want to open the new invoice?', Comment = '%1 = No. of the new rental invoice document.';
    begin
        RentalSetup.Get();
        if RentalSetup."Create an unbooked Invoice" = false then
            exit;

        RentalInvHeader.Init();
        RentalInvHeader."Document Type" := RentalInvHeader."Document Type"::Invoice;
        RentalInvHeader."No." := '';
        RentalInvHeader.Insert(true);
        RentalInvHeader.TransferFields(RentalHeader, false);
        RentalInvHeader."Belongs to Rental Contract" := RentalHeader."No.";
        RentalInvHeader.Modify(true);

        RentalLine.SetRange("Document Type", RentalHeader."Document Type");
        RentalLine.SetRange("Document No.", RentalHeader."No.");
        if RentalLine.FindSet() then
            repeat
                RentalInvLine.Init();
                RentalInvLine."Document Type" := RentalInvHeader."Document Type";
                RentalInvLine."Document No." := RentalInvHeader."No.";
                RentalInvLine."Line No." := RentalLine."Line No.";
                RentalInvLine.Insert(true);
                RentalInvLine.TransferFields(RentalLine, false);
                RentalInvLine.Modify(true);
            until RentalLine.Next() = 0;

        if GuiAllowed then
            OpenPage := Confirm(StrSubstNo(OpenNewInvoiceQst, RentalInvHeader."No."), true);
        if OpenPage then begin
            Clear(TWERentalInvoice);
            TWERentalInvoice.SetRecord(RentalInvHeader);
            TWERentalInvoice.Run();
        end;
    end;

    /// <summary>
    /// GetDataForRentalUnbookedReturnShipment.
    /// </summary>
    /// <param name="RentalHeader">VAR Record "TWE Rental Header".</param>
    procedure GetDataForRentalUnbookedReturnShipment(var RentalHeader: Record "TWE Rental Header")
    var
        RentalRetShipHeader: Record "TWE Rental Header";
        RentalRetShipLine: Record "TWE Rental Line";
        RentalLine: Record "TWE Rental Line";
        TWERentalRetShipPag: Page "TWE Rental Return Shipment";
        OpenPage: Boolean;
        OpenNewInvoiceQst: Label 'The return shipment has been created to %1. Do you want to open the new return shipment?', Comment = '%1 = No. of the new rental return shipment document.';
        NoLinesFoundErr: Label 'No Lines were found to create return shipment for contract %1!', Comment = '%1 = No. of the rental contract document.';
    begin
        RentalRetShipHeader.Init();
        RentalRetShipHeader."Document Type" := RentalRetShipHeader."Document Type"::"Return Shipment";
        RentalRetShipHeader."No." := '';
        RentalRetShipHeader.Insert(true);
        RentalRetShipHeader.TransferFields(RentalHeader, false);
        RentalRetShipHeader."Belongs to Rental Contract" := RentalHeader."No.";
        RentalRetShipHeader.Modify(true);

        RentalLine.SetRange("Document Type", RentalHeader."Document Type");
        RentalLine.SetRange("Document No.", RentalHeader."No.");
        RentalLine.SetRange("Quantity Returned", 0);
        RentalLine.SetFilter("Quantity Shipped", '>%1', 0);
        if RentalLine.FindSet() then begin
            repeat
                RentalRetShipLine.Init();
                RentalRetShipLine."Document Type" := RentalRetShipHeader."Document Type";
                RentalRetShipLine."Document No." := RentalRetShipHeader."No.";
                RentalRetShipLine."Line No." := RentalLine."Line No.";
                RentalRetShipLine.Insert(true);
                RentalRetShipLine.TransferFields(RentalLine, false);
                RentalRetShipLine.Modify(true);
            until RentalLine.Next() = 0;

            if GuiAllowed then
                OpenPage := Confirm(StrSubstNo(OpenNewInvoiceQst, RentalRetShipHeader."No."), true);
            if OpenPage then begin
                Clear(TWERentalRetShipPag);
                TWERentalRetShipPag.SetRecord(RentalRetShipHeader);
                TWERentalRetShipPag.Run();
            end;
        end else
            Error(NoLinesFoundErr, RentalHeader."No.");
    end;

    /// <summary>
    /// CreateMainRentalItemFromItem.
    /// </summary>
    /// <param name="Item">Record Item.</param>
    procedure CreateMainRentalItemFromItem(Item: Record Item)
    var
        MainRentalItem: Record "TWE Main Rental Item";
        RentalSetup: Record "TWE Rental Setup";
        ReportConvertInventory: Report "TWE Convert Inventory";
        PageMainRentalItemCard: Page "TWE Main Rental Item Card";
        Success: Boolean;
        Confirm001Lbl: Label 'Do you really want to turn item %1 into a rental item?', Comment = '%1 = No. of the item.';
        Confirm002Lbl: Label 'Do you want to open main rental item card?';
        Confirm003Lbl: Label 'Do you want to convert the entire inventory (Quantity %1)?', Comment = '%1 - entire inventory.';
        Error001Lbl: Label 'Something went wrong. Please try again later.';
    begin
        Success := false;
        RentalSetup.Get();
        if Confirm(StrSubstNo(Confirm001Lbl, Item."No."), true) then begin
            MainRentalItem.Init();
            MainRentalItem."No." := '';
            Success := MainRentalItem.Insert(true);
            MainRentalItem.Validate(Description, Item.Description);
            MainRentalItem.Validate("Description 2", Item."Description 2");
            MainRentalItem.Validate("VAT Prod. Posting Group", Item."VAT Prod. Posting Group");
            MainRentalItem.Validate("VAT Bus. Posting Gr. (Price)", Item."VAT Bus. Posting Gr. (Price)");
            MainRentalItem.Validate("Unit Price", Item."Unit Price");
            MainRentalItem.Validate("Base Unit of Measure", RentalSetup."Base Unit for new Rental Item");
            MainRentalItem.Validate("Gen. Prod. Posting Group", Item."Gen. Prod. Posting Group");
            MainRentalItem.Validate("Inventory Posting Group", Item."Inventory Posting Group");
            MainRentalItem.Validate("Orginal Item No.", Item."No.");
            Success := MainRentalItem.Modify(true);

            Commit();

            Item.CalcFields(Inventory);

            if Confirm((StrSubstNo(Confirm003Lbl, Item.Inventory)), true) then begin
                ReportConvertInventory.SetItemNo(Item."No.");
                ReportConvertInventory.SetQty(Item.Inventory);
                ReportConvertInventory.SetMainRentalItemNo(MainRentalItem."No.");
                ReportConvertInventory.UseRequestPage(false);
                ReportConvertInventory.Run();
            end else begin
                ReportConvertInventory.SetItemNo(Item."No.");
                ReportConvertInventory.SetMainRentalItemNo(MainRentalItem."No.");
                ReportConvertInventory.Run();
            end;

            if Success then begin
                if Confirm(Confirm002Lbl, true) then begin
                    PageMainRentalItemCard.SetRecord(MainRentalItem);
                    PageMainRentalItemCard.Run();
                end;
            end else
                Error(Error001Lbl);
        end;
    end;

    /// <summary>
    /// CreateItemFromRentalItem.
    /// </summary>
    /// <param name="RentalItem">Record Service Item.</param>
    procedure CreateItemFromRentalItem(RentalItem: Record "Service Item")
    var
        Item: Record Item;
        MainRentalItem: Record "TWE Main Rental Item";
        deleteRentalItem: Record "Service Item";
        FixedAsset: Record "Fixed Asset";
        ReportConvertRentalItemIntoItem: Report "TWE Conv. Rent. Item into Item";
        PageItemCard: Page "Item Card";
        Success: Boolean;
        Confirm001Lbl: Label 'Do you really want to turn rental item %1 into a item?', Comment = '%1 = No. of the rental item.';
        Confirm002Lbl: Label 'Do you want to open item card?';
        Error001Lbl: Label 'Something went wrong. Please try again later.';
        RentalItemIsRentedErr: Label 'Rental Item %1 is actually rented.', Comment = '%1 = No. of the rental item.';
        NoOriginalItemNoErr: Label 'No original item no. in main rental item found.';
    begin
        if RentalItem."TWE Rented" then
            Error(RentalItemIsRentedErr, RentalItem."No.");

        Success := false;
        if Confirm(StrSubstNo(Confirm001Lbl, RentalItem."No."), true) then begin
            MainRentalItem.Get(RentalItem."TWE Main Rental Item");

            if Item.Get(MainRentalItem."Orginal Item No.") then begin
                Item.Validate(Description, RentalItem.Description);
                Item.Validate("Description 2", RentalItem."Description 2");
                Item.Validate("VAT Prod. Posting Group", MainRentalItem."VAT Prod. Posting Group");
                Item.Validate("VAT Bus. Posting Gr. (Price)", MainRentalItem."VAT Bus. Posting Gr. (Price)");
                Item.Validate("Unit Price", MainRentalItem."Unit Price");
                Item.Validate("Gen. Prod. Posting Group", MainRentalItem."Gen. Prod. Posting Group");
                Item.Validate("Inventory Posting Group", MainRentalItem."Inventory Posting Group");
                Success := Item.Modify(true);

                FixedAsset.SetRange("TWE Rental Item No.", RentalItem."No.");
                if FixedAsset.FindFirst() then begin
                    FixedAsset.Inactive := true;
                    FixedAsset."TWE Item No." := '';
                    FixedAsset."TWE Item Description" := '';
                    FixedAsset."TWE Main Rental Item No." := '';
                    FixedAsset."TWE Main Rental Item Desc." := '';
                    FixedAsset."TWE Rental Item No." := '';
                    FixedAsset."TWE Rental Item Description" := '';
                    FixedAsset."TWE Rental Item Serial No." := '';
                    FixedAsset.Modify();
                end;

                if deleteRentalItem.Get(RentalItem."No.") then
                    deleteRentalItem.Delete(true);

                Commit();

                ReportConvertRentalItemIntoItem.SetRentalItemNo(MainRentalItem."Orginal Item No.");
                ReportConvertRentalItemIntoItem.Run();

                if Success then begin
                    if Confirm(Confirm002Lbl, true) then begin
                        PageItemCard.SetRecord(Item);
                        PageItemCard.Run();
                    end;
                end else
                    Error(Error001Lbl);
            end else
                Error(NoOriginalItemNoErr);
        end;
    end;

    /// <summary>
    /// ChangeRentItemRentedState.
    /// </summary>
    /// <param name="rentalItemNo">Rental Item No.</param>
    /// <param name="newState">changes rented to a new state.</param>
    procedure ChangeRentItemRentedState(rentalItemNo: Code[20]; newState: Boolean)
    var
        rentalItem: Record "Service Item";
        notFoundErr: Label 'Rental Item %1 could not be found.', Comment = '%1 displays the item no.';
    begin
        if not rentalItem.Get(rentalItemNo) then
            Error(notFoundErr, rentalItemNo);

        rentalItem."TWE Rented" := newState;
        rentalItem.Modify();
    end;

    local procedure GetDate(StartDate: Date; var customizedCalendarChange: Record "Customized Calendar Change"; ActualCalendarCode: Code[10])
    var
        CalendarManagement: Codeunit "Calendar Management";
    begin
        customizedCalendarChange.DeleteAll();

        if DateRec.Get(DateRec."Period Type"::Date, StartDate) then;

        customizedCalendarChange.SetRange(Date, StartDate);

        customizedCalendarChange.Date := DateRec."Period Start";
        customizedCalendarChange.Day := DateRec."Period No.";
        customizedCalendarChange."Base Calendar Code" := ActualCalendarCode;

        CalendarManagement.CheckDateStatus(customizedCalendarChange);

        customizedCalendarChange.Insert();

    end;

    procedure ReactivateRentalContract(var RentalHeader: Record "TWE Rental Header")
    begin
        if not RentalHeader."Rental Contract closed" then
            exit;

        RentalHeader."Rental Contract closed" := false;
        RentalHeader.Modify(true);
    end;

    procedure CheckRentalHeaderBeforeLineIsInserted(rentalLine: Record "TWE Rental Line") LastErrorText: Text
    var
        rentalHeader: Record "TWE Rental Header";
        FoundMistake: Boolean;
        ErrorRentalStartLbl: Label 'Please insert rental start in rental header first.';
        ErrorRentalEndLbl: Label 'Please insert rental end in rental header first.';
        ErrorRentalRateCodeLbl: Label 'Please insert rental rate code in rental header first.';
        ErrorRentalInvoicePeriodLbl: Label 'Please insert rental invoice period in rental header first.';
    begin
        FoundMistake := false;
        if rentalHeader.Get(rentalLine."Document Type", rentalLine."Document No.") then
            if rentalHeader."Rental Start" = 0D then begin
                FoundMistake := true;
                exit(ErrorRentalStartLbl);
            end;

        if rentalHeader."Rental End" = 0D then begin
            FoundMistake := true;
            exit(ErrorRentalEndLbl);
        end;

        if rentalHeader."Rental Rate Code" = '' then begin
            FoundMistake := true;
            exit(ErrorRentalRateCodeLbl);
        end;

        if rentalHeader."Invoicing Period" = '' then begin
            FoundMistake := true;
            exit(ErrorRentalInvoicePeriodLbl);
        end;

        if FoundMistake = false then
            exit('');
    end;
}
