/// <summary>
/// Page TWE Rental Check Credit Limit (ID 50003).
/// </summary>
page 50003 "TWE Rental Check Credit Limit"
{
    Caption = 'Check Credit Limit';
    DataCaptionExpression = '';
    DeleteAllowed = false;
    Editable = true;
    InsertAllowed = false;
    InstructionalText = 'An action is requested regarding the Credit Limit check.';
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = ConfirmationDialog;
    PromotedActionCategories = 'New,Process,Report,Manage,Create';
    SourceTable = Customer;

    layout
    {
        area(content)
        {
            label(Control2)
            {
                ApplicationArea = Basic, Suite;
                CaptionClass = Format(StrSubstNo(Text000Lbl, Heading));
                MultiLine = true;
                ShowCaption = false;
            }
            field(HideMessage; HideMessage)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Do not show this message again.';
                ToolTip = 'Specifies to no longer show this message when working with this document while the customer is over credit limit';
                Visible = HideMessageVisible;
            }
            part(CreditLimitDetails; "Credit Limit Details")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "No." = FIELD("No.");
                UpdatePropagation = Both;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Customer")
            {
                Caption = '&Customer';
                Image = Customer;
                action(Card)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Card';
                    Image = EditLines;
                    RunObject = Page "Customer Card";
                    RunPageLink = "No." = FIELD("No."),
                                  "Date Filter" = FIELD("Date Filter"),
                                  "Global Dimension 1 Filter" = FIELD("Global Dimension 1 Filter"),
                                  "Global Dimension 2 Filter" = FIELD("Global Dimension 2 Filter");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View details for the selected record.';
                }
                action(Statistics)
                {
                    ApplicationArea = Suite;
                    Caption = 'Statistics';
                    Image = Statistics;
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Customer Statistics";
                    RunPageLink = "No." = FIELD("No."),
                                  "Date Filter" = FIELD("Date Filter"),
                                  "Global Dimension 1 Filter" = FIELD("Global Dimension 1 Filter"),
                                  "Global Dimension 2 Filter" = FIELD("Global Dimension 2 Filter");
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistics for credit limit entries.';
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        CalcCreditLimitLCY();
        CalcOverdueBalanceLCY();

        SetParametersOnDetails();
    end;

    trigger OnOpenPage()
    begin
        Rec.Copy(Cust2);
    end;

    var
        CurrExchRate: Record "Currency Exchange Rate";
        RentalHeader: Record "TWE Rental Header";
        RentalLine: Record "TWE Rental Line";
        // ServHeader: Record "Service Header";
        ServLine: Record "Service Line";
        Cust2: Record Customer;
        RentalSetup: Record "TWE Rental Setup";
        CustNo: Code[20];
        Heading: Text[250];
        SecondHeading: Text[250];
        NotificationId: Guid;
        NewOrderAmountLCY: Decimal;
        OldOrderAmountLCY: Decimal;
        OrderAmountThisOrderLCY: Decimal;
        OrderAmountTotalLCY: Decimal;
        CustCreditAmountLCY: Decimal;
        ShippedRetRcdNotIndLCY: Decimal;
        OutstandingRetOrdersLCY: Decimal;
        RcdNotInvdRetOrdersLCY: Decimal;
        DeltaAmount: Decimal;
        HideMessage: Boolean;
        HideMessageVisible: Boolean;

        ExtensionAmounts: List of [Decimal];
        Text000Lbl: Label '%1 Do you still want to record the amount?', Comment = '%1 = Header Text';

    /// <summary>
    /// GenJnlLineShowWarning.
    /// </summary>
    /// <param name="GenJnlLine">Record "Gen. Journal Line".</param>
    /// <returns>Return value of type Boolean.</returns>
    procedure GenJnlLineShowWarning(GenJnlLine: Record "Gen. Journal Line"): Boolean
    var
        IsHandled: Boolean;
        Result: Boolean;
    begin
        OnBeforeGenJnlLineShowWarning(GenJnlLine, IsHandled, Result);
        if IsHandled then
            exit(Result);

        RentalSetup.Get();
        if RentalSetup."Credit Warnings" =
           RentalSetup."Credit Warnings"::"No Warning"
        then
            exit(false);
        if GenJnlLine."Account Type" = GenJnlLine."Account Type"::Customer then
            exit(ShowWarning(GenJnlLine."Account No.", GenJnlLine."Amount (LCY)", 0, true));
        exit(ShowWarning(GenJnlLine."Bal. Account No.", -GenJnlLine.Amount, 0, true));
    end;

    /// <summary>
    /// GenJnlLineShowWarningAndGetCause.
    /// </summary>
    /// <param name="GenJnlLine">Record "Gen. Journal Line".</param>
    /// <param name="NotificationContextGuidOut">VAR Guid.</param>
    /// <returns>Return value of type Boolean.</returns>
    procedure GenJnlLineShowWarningAndGetCause(GenJnlLine: Record "Gen. Journal Line"; var NotificationContextGuidOut: Guid): Boolean
    var
        Result: Boolean;
    begin
        Result := GenJnlLineShowWarning(GenJnlLine);
        NotificationContextGuidOut := NotificationId;
        exit(Result);
    end;

    /// <summary>
    /// RentalHeaderShowWarning.
    /// </summary>
    /// <param name="RentalHeader">Record "TWE Rental Header".</param>
    /// <returns>Return value of type Boolean.</returns>
    procedure RentalHeaderShowWarning(RentalHeader: Record "TWE Rental Header"): Boolean
    var
        OldRentalHeader: Record "TWE Rental Header";
        AssignDeltaAmount: Boolean;
    begin
        // Used when additional lines are inserted
        RentalSetup.Get();
        if RentalSetup."Credit Warnings" =
           RentalSetup."Credit Warnings"::"No Warning"
        then
            exit(false);
        if RentalHeader."Currency Code" = '' then
            NewOrderAmountLCY := RentalHeader."Amount Including VAT"
        else
            NewOrderAmountLCY :=
              Round(
                CurrExchRate.ExchangeAmtFCYToLCY(
                WorkDate(), RentalHeader."Currency Code",
                  RentalHeader."Amount Including VAT", RentalHeader."Currency Factor"));

        if not (RentalHeader."Document Type" in
                [RentalHeader."Document Type"::Quote,
                 RentalHeader."Document Type"::Contract])
        then
            NewOrderAmountLCY := NewOrderAmountLCY + RentalLineAmount(RentalHeader."Document Type", RentalHeader."No.");
        OldRentalHeader := RentalHeader;
        if OldRentalHeader.FindFirst() then
            AssignDeltaAmount := OldRentalHeader."Bill-to Customer No." <> RentalHeader."Bill-to Customer No."
        else
            AssignDeltaAmount := true;
        if AssignDeltaAmount then
            DeltaAmount := NewOrderAmountLCY;
        exit(ShowWarning(RentalHeader."Bill-to Customer No.", NewOrderAmountLCY, 0, true));
    end;

    /// <summary>
    /// RentalHeaderShowWarningAndGetCause.
    /// </summary>
    /// <param name="RentalHeader">Record "TWE Rental Header".</param>
    /// <param name="NotificationContextGuidOut">VAR Guid.</param>
    /// <returns>Return value of type Boolean.</returns>
    procedure RentalHeaderShowWarningAndGetCause(RentalHeader: Record "TWE Rental Header"; var NotificationContextGuidOut: Guid): Boolean
    var
        Result: Boolean;
    begin
        Result := RentalHeaderShowWarning(RentalHeader);
        NotificationContextGuidOut := NotificationId;
        exit(Result);
    end;
    /// <summary>
    /// RentalLineShowWarning.
    /// </summary>
    /// <param name="RentalLine">Record "TWE Rental Line".</param>
    /// <returns>Return value of type Boolean.</returns>
    procedure RentalLineShowWarning(RentalLine: Record "TWE Rental Line"): Boolean
    begin
        RentalSetup.Get();
        if RentalSetup."Credit Warnings" =
           RentalSetup."Credit Warnings"::"No Warning"
        then
            exit(false);
        if (RentalHeader."Document Type" <> RentalLine."Document Type") or
           (RentalHeader."No." <> RentalLine."Document No.")
        then
            RentalHeader.Get(RentalLine."Document Type", RentalLine."Document No.");
        NewOrderAmountLCY := RentalLine."Outstanding Amount (LCY)" + RentalLine."Shipped Not Invoiced (LCY)";

        if RentalLine.FindFirst() then
            OldOrderAmountLCY := RentalLine."Outstanding Amount (LCY)" + RentalLine."Shipped Not Invoiced (LCY)"
        else
            OldOrderAmountLCY := 0;

        DeltaAmount := NewOrderAmountLCY - OldOrderAmountLCY;
        NewOrderAmountLCY :=
          DeltaAmount + RentalLineAmount(RentalLine."Document Type", RentalLine."Document No.");

        if RentalHeader."Document Type" = RentalHeader."Document Type"::Quote then
            DeltaAmount := NewOrderAmountLCY;

        exit(ShowWarning(RentalHeader."Bill-to Customer No.", NewOrderAmountLCY, OldOrderAmountLCY, false))
    end;
    /// <summary>
    /// RentalLineShowWarningAndGetCause.
    /// </summary>
    /// <param name="RentalLine">Record "TWE Rental Line".</param>
    /// <param name="NotificationContextGuidOut">VAR Guid.</param>
    /// <returns>Return value of type Boolean.</returns>
    procedure RentalLineShowWarningAndGetCause(RentalLine: Record "TWE Rental Line"; var NotificationContextGuidOut: Guid): Boolean
    var
        Result: Boolean;
    begin
        Result := RentalLineShowWarning(RentalLine);
        NotificationContextGuidOut := NotificationId;
        exit(Result);
    end;

    local procedure RentalLineAmount(DocType: Enum "TWE Rental Document Type"; DocNo: Code[20]): Decimal
    begin
        RentalLine.Reset();
        RentalLine.SetRange("Document Type", DocType);
        RentalLine.SetRange("Document No.", DocNo);
        RentalLine.CalcSums("Outstanding Amount (LCY)", "Shipped Not Invoiced (LCY)");
        exit(RentalLine."Outstanding Amount (LCY)" + RentalLine."Shipped Not Invoiced (LCY)");
    end;

    /// <summary>
    /// ShowWarning.
    /// </summary>
    /// <param name="NewCustNo">Code[20].</param>
    /// <param name="NewOrderAmountLCY2">Decimal.</param>
    /// <param name="OldOrderAmountLCY2">Decimal.</param>
    /// <param name="CheckOverDueBalance">Boolean.</param>
    /// <returns>Return value of type Boolean.</returns>
    procedure ShowWarning(NewCustNo: Code[20]; NewOrderAmountLCY2: Decimal; OldOrderAmountLCY2: Decimal; CheckOverDueBalance: Boolean): Boolean
    var
        RentalCustCheckCrLimit: Codeunit "TWE Rent. Cust-Check Cr. Limit";
        ExitValue: Integer;
    begin
        if NewCustNo = '' then
            exit;
        CustNo := NewCustNo;
        NewOrderAmountLCY := NewOrderAmountLCY2;
        OldOrderAmountLCY := OldOrderAmountLCY2;
        Rec.Get(CustNo);
        Rec.SetRange("No.", Rec."No.");
        Cust2.Copy(Rec);

        if (RentalSetup."Credit Warnings" in
            [RentalSetup."Credit Warnings"::"Both Warnings",
             RentalSetup."Credit Warnings"::"Credit Limit"]) and
           RentalCustCheckCrLimit.IsCreditLimitNotificationEnabled(Rec)
        then begin
            CalcCreditLimitLCY();
            if (CustCreditAmountLCY > Rec."Credit Limit (LCY)") and (Rec."Credit Limit (LCY)" <> 0) then
                ExitValue := 1;
        end;
        if CheckOverDueBalance and
           (RentalSetup."Credit Warnings" in
            [RentalSetup."Credit Warnings"::"Both Warnings",
             RentalSetup."Credit Warnings"::"Overdue Balance"]) and
           RentalCustCheckCrLimit.IsOverdueBalanceNotificationEnabled(Rec)
        then begin
            CalcOverdueBalanceLCY();
            if Rec."Balance Due (LCY)" > 0 then
                ExitValue := ExitValue + 2;
        end;

        if ExitValue > 0 then begin
            case ExitValue of
                1:
                    begin
                        Heading := CopyStr(RentalCustCheckCrLimit.GetCreditLimitNotificationMsg(), 1, 250);
                        NotificationId := RentalCustCheckCrLimit.GetCreditLimitNotificationId();
                    end;
                2:
                    begin
                        Heading := CopyStr(RentalCustCheckCrLimit.GetOverdueBalanceNotificationMsg(), 1, 250);
                        NotificationId := RentalCustCheckCrLimit.GetOverdueBalanceNotificationId();
                    end;
                3:
                    begin
                        Heading := CopyStr(RentalCustCheckCrLimit.GetCreditLimitNotificationMsg(), 1, 250);
                        SecondHeading := CopyStr(RentalCustCheckCrLimit.GetOverdueBalanceNotificationMsg(), 1, 250);
                        NotificationId := RentalCustCheckCrLimit.GetBothNotificationsId();
                    end;
            end;
            exit(true);
        end;
    end;

    local procedure CalcCreditLimitLCY()
    begin
        OutstandingRetOrdersLCY := 0;
        RcdNotInvdRetOrdersLCY := 0;

        if Rec.GetFilter("Date Filter") = '' then
            Rec.SetFilter("Date Filter", '..%1', WorkDate());
        Rec.CalcFields("Balance (LCY)", "Shipped Not Invoiced (LCY)", "Serv Shipped Not Invoiced(LCY)");

        OrderAmountTotalLCY := CalcTotalOutstandingAmt() - OutstandingRetOrdersLCY + DeltaAmount;
        ShippedRetRcdNotIndLCY := Rec."Shipped Not Invoiced (LCY)" + Rec."Serv Shipped Not Invoiced(LCY)" - RcdNotInvdRetOrdersLCY;
        if Rec."No." = CustNo then
            OrderAmountThisOrderLCY := NewOrderAmountLCY
        else
            OrderAmountThisOrderLCY := 0;

        CustCreditAmountLCY :=
          Rec."Balance (LCY)" + Rec."Shipped Not Invoiced (LCY)" + Rec."Serv Shipped Not Invoiced(LCY)" - RcdNotInvdRetOrdersLCY +
          OrderAmountTotalLCY - Rec.GetInvoicedPrepmtAmountLCY();

        OnAfterCalcCreditLimitLCY(Rec, CustCreditAmountLCY, ExtensionAmounts);
    end;

    local procedure CalcOverdueBalanceLCY()
    begin
        if Rec.GetFilter("Date Filter") = '' then
            Rec.SetFilter("Date Filter", '..%1', WorkDate());
        Rec.CalcFields("Balance Due (LCY)");
    end;

    local procedure CalcTotalOutstandingAmt(): Decimal
    var
        recRentalLine: Record "TWE Rental Line";
        RentalOutstandingAmountFromShipment: Decimal;
        ServOutstandingAmountFromShipment: Decimal;
    begin
        Rec.CalcFields(
          "Outstanding Invoices (LCY)", "Outstanding Orders (LCY)", "Outstanding Serv.Invoices(LCY)", "Outstanding Serv. Orders (LCY)");
        RentalOutstandingAmountFromShipment := recRentalLine.OutstandingInvoiceAmountFromShipment(Rec."No.");
        ServOutstandingAmountFromShipment := ServLine.OutstandingInvoiceAmountFromShipment(Rec."No.");

        exit(
          Rec."Outstanding Orders (LCY)" + Rec."Outstanding Invoices (LCY)" + Rec."Outstanding Serv. Orders (LCY)" +
          Rec."Outstanding Serv.Invoices(LCY)" - RentalOutstandingAmountFromShipment - ServOutstandingAmountFromShipment);
    end;

    /// <summary>
    /// SetHideMessageVisible.
    /// </summary>
    /// <param name="HideMsgVisible">Boolean.</param>
    procedure SetHideMessageVisible(HideMsgVisible: Boolean)
    begin
        HideMessageVisible := HideMsgVisible;
    end;

    /// <summary>
    /// SetHideMessage.
    /// </summary>
    /// <param name="HideMsg">Boolean.</param>
    procedure SetHideMessage(HideMsg: Boolean)
    begin
        HideMessage := HideMsg;
    end;

    /// <summary>
    /// GetHideMessage.
    /// </summary>
    /// <returns>Return value of type Boolean.</returns>
    procedure GetHideMessage(): Boolean
    begin
        exit(HideMessage);
    end;

    /// <summary>
    /// GetHeading.
    /// </summary>
    /// <returns>Return value of type Text[250].</returns>
    procedure GetHeading(): Text[250]
    begin
        exit(Heading);
    end;

    /// <summary>
    /// GetSecondHeading.
    /// </summary>
    /// <returns>Return value of type Text[250].</returns>
    procedure GetSecondHeading(): Text[250]
    begin
        exit(SecondHeading);
    end;

    /// <summary>
    /// GetNotificationId.
    /// </summary>
    /// <returns>Return value of type Guid.</returns>
    procedure GetNotificationId(): Guid
    begin
        exit(NotificationId);
    end;

    /// <summary>
    /// PopulateDataOnNotification.
    /// </summary>
    /// <param name="CreditLimitNotification">Notification.</param>
    procedure PopulateDataOnNotification(CreditLimitNotification: Notification)
    begin
        CurrPage.CreditLimitDetails.PAGE.SetCustomerNumber(Rec."No.");
        SetParametersOnDetails();
        CurrPage.CreditLimitDetails.PAGE.PopulateDataOnNotification(CreditLimitNotification);
    end;

    local procedure SetParametersOnDetails()
    begin
        CurrPage.CreditLimitDetails.PAGE.SetOrderAmountTotalLCY(OrderAmountTotalLCY);
        CurrPage.CreditLimitDetails.PAGE.SetShippedRetRcdNotIndLCY(ShippedRetRcdNotIndLCY);
        CurrPage.CreditLimitDetails.PAGE.SetOrderAmountThisOrderLCY(OrderAmountThisOrderLCY);
        CurrPage.CreditLimitDetails.PAGE.SetCustCreditAmountLCY(CustCreditAmountLCY);
        CurrPage.CreditLimitDetails.Page.SetExtensionAmounts(ExtensionAmounts);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcCreditLimitLCY(var Customer: Record Customer; var CustCreditAmountLCY: Decimal; var ExtensionAmounts: List of [Decimal])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGenJnlLineShowWarning(GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean; var Result: Boolean);
    begin
    end;
}

