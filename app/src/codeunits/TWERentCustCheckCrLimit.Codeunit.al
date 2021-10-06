/// <summary>
/// Codeunit TWE Rent. Cust-Check Cr. Limit (ID 70704615).
/// </summary>
codeunit 50063 "TWE Rent. Cust-Check Cr. Limit"
{
    Permissions = TableData "My Notifications" = rimd;

    trigger OnRun()
    begin
    end;

    var
        InstructionMgt: Codeunit "Instruction Mgt.";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        RentalCustCheckCreditLimit: Page "TWE Rental Check Credit Limit";
        InstructionTypeTxt: Label 'Check Cr. Limit';
        GetDetailsTxt: Label 'Show details';
        CreditLimitNotificationMsg: Label 'The customer''s credit limit has been exceeded.';
        CreditLimitNotificationDescriptionTxt: Label 'Show warning when a sales document will exceed the customer''s credit limit.';
        OverdueBalanceNotificationMsg: Label 'This customer has an overdue balance.';
        OverdueBalanceNotificationDescriptionTxt: Label 'Show warning when a sales document is for a customer with an overdue balance.';

    /// <summary>
    /// GenJnlLineCheck.
    /// </summary>
    /// <param name="GenJnlLine">Record "Gen. Journal Line".</param>
    procedure GenJnlLineCheck(GenJnlLine: Record "Gen. Journal Line")
    var
        RentalHeader: Record "TWE Rental Header";
        AdditionalContextId: Guid;
    begin
        if not GuiAllowed then
            exit;

        if not RentalHeader.Get(GenJnlLine."Document Type", GenJnlLine."Document No.") then
            RentalHeader.Init();
        OnNewCheckRemoveCustomerNotifications(RentalHeader.RecordId, true);

        if RentalCustCheckCreditLimit.GenJnlLineShowWarningAndGetCause(GenJnlLine, AdditionalContextId) then
            CreateAndSendNotification(RentalHeader.RecordId, AdditionalContextId, '');
    end;

    /// <summary>
    /// RentalHeaderCheck.
    /// </summary>
    /// <param name="RentalHeader">VAR Record "TWE Rental Header".</param>
    /// <returns>Return variable CreditLimitExceeded of type Boolean.</returns>
    procedure RentalHeaderCheck(var RentalHeader: Record "TWE Rental Header") CreditLimitExceeded: Boolean
    var
        AdditionalContextId: Guid;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRentalHeaderCheck(RentalHeader, IsHandled);
        if IsHandled then
            exit;

        if GuiAllowed then begin
            OnNewCheckRemoveCustomerNotifications(RentalHeader.RecordId, true);

            if not RentalCustCheckCreditLimit.RentalHeaderShowWarningAndGetCause(RentalHeader, AdditionalContextId) then
                RentalHeader.CustomerCreditLimitNotExceeded()
            else begin
                CreditLimitExceeded := true;

                if InstructionMgt.IsEnabled(GetInstructionType(Format(RentalHeader."Document Type"), RentalHeader."No.")) then
                    CreateAndSendNotification(RentalHeader.RecordId, AdditionalContextId, '');

                RentalHeader.CustomerCreditLimitExceeded(RentalCustCheckCreditLimit.GetNotificationId());
            end;
        end;
    end;

    /// <summary>
    /// RentalLineCheck.
    /// </summary>
    /// <param name="RentalLine">Record "TWE Rental Line".</param>
    procedure RentalLineCheck(RentalLine: Record "TWE Rental Line")
    var
        RentalHeader: Record "TWE Rental Header";
        AdditionalContextId: Guid;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRentalLineCheck(RentalLine, IsHandled);
        if IsHandled then
            exit;

        if not RentalHeader.Get(RentalLine."Document Type", RentalLine."Document No.") then
            RentalHeader.Init();

        if GuiAllowed then
            OnNewCheckRemoveCustomerNotifications(RentalHeader.RecordId, false);

        if not RentalCustCheckCreditLimit.RentalLineShowWarningAndGetCause(RentalLine, AdditionalContextId) then
            RentalHeader.CustomerCreditLimitNotExceeded()
        else begin
            if GuiAllowed then
                if InstructionMgt.IsEnabled(GetInstructionType(Format(RentalLine."Document Type"), RentalLine."Document No.")) then
                    CreateAndSendNotification(RentalHeader.RecordId, AdditionalContextId, '');

            RentalHeader.CustomerCreditLimitExceeded(RentalCustCheckCreditLimit.GetNotificationId());
        end;
    end;

    /// <summary>
    /// GetInstructionType.
    /// </summary>
    /// <param name="DocumentType">Code[30].</param>
    /// <param name="DocumentNumber">Code[20].</param>
    /// <returns>Return value of type Code[50].</returns>
    procedure GetInstructionType(DocumentType: Code[30]; DocumentNumber: Code[20]): Code[50]
    var
        Placeholder001Lbl: Label '%1 %2 %3', Comment = '%1 = Document Type, %2 = Document No., %3 = InstructionTypeTxt';
    begin
        exit(CopyStr(StrSubstNo(Placeholder001Lbl, DocumentType, DocumentNumber, InstructionTypeTxt), 1, 50));
    end;

    /// <summary>
    /// ShowNotificationDetails.
    /// </summary>
    /// <param name="CreditLimitNotification">Notification.</param>
    procedure ShowNotificationDetails(CreditLimitNotification: Notification)
    var
        CreditLimitNotificationPage: Page "Credit Limit Notification";
    begin
        CreditLimitNotificationPage.SetHeading(CopyStr(CreditLimitNotification.Message(), 1, 250));
        CreditLimitNotificationPage.InitializeFromNotificationVar(CreditLimitNotification);
        CreditLimitNotificationPage.RunModal();
    end;

    local procedure CreateAndSendNotification(RecordId: RecordID; AdditionalContextId: Guid; Heading: Text[250])
    var
        NotificationToSend: Notification;
    begin
        if AdditionalContextId = GetBothNotificationsId() then begin
            CreateAndSendNotification(RecordId, GetCreditLimitNotificationId(), RentalCustCheckCreditLimit.GetHeading());
            CreateAndSendNotification(RecordId, GetOverdueBalanceNotificationId(), RentalCustCheckCreditLimit.GetSecondHeading());
            exit;
        end;

        if Heading = '' then
            Heading := RentalCustCheckCreditLimit.GetHeading();

        case Heading of
            CreditLimitNotificationMsg:
                NotificationToSend.Id(GetCreditLimitNotificationId());
            OverdueBalanceNotificationMsg:
                NotificationToSend.Id(GetOverdueBalanceNotificationId());
            else
                NotificationToSend.Id(CreateGuid());
        end;

        NotificationToSend.Message(Heading);
        NotificationToSend.Scope(NOTIFICATIONSCOPE::LocalScope);
        NotificationToSend.AddAction(GetDetailsTxt, CODEUNIT::"TWE Rent. Cust-Check Cr. Limit", 'ShowNotificationDetails');
        RentalCustCheckCreditLimit.PopulateDataOnNotification(NotificationToSend);
        NotificationLifecycleMgt.SendNotificationWithAdditionalContext(NotificationToSend, RecordId, AdditionalContextId);
    end;

    /// <summary>
    /// GetCreditLimitNotificationId.
    /// </summary>
    /// <returns>Return value of type Guid.</returns>
    procedure GetCreditLimitNotificationId(): Guid
    begin
        exit('C80FEEDA-802C-4879-B826-34A10FB77087');
    end;

    /// <summary>
    /// GetOverdueBalanceNotificationId.
    /// </summary>
    /// <returns>Return value of type Guid.</returns>
    procedure GetOverdueBalanceNotificationId(): Guid
    begin
        exit('EC8348CB-07C1-499A-9B70-B3B081A33C99');
    end;

    /// <summary>
    /// GetBothNotificationsId.
    /// </summary>
    /// <returns>Return value of type Guid.</returns>
    procedure GetBothNotificationsId(): Guid
    begin
        exit('EC8348CB-07C1-499A-9B70-B3B081A33D00');
    end;

    /// <summary>
    /// IsCreditLimitNotificationEnabled.
    /// </summary>
    /// <param name="Customer">Record Customer.</param>
    /// <returns>Return value of type Boolean.</returns>
    procedure IsCreditLimitNotificationEnabled(Customer: Record Customer): Boolean
    var
        MyNotifications: Record "My Notifications";
    begin
        exit(MyNotifications.IsEnabledForRecord(GetCreditLimitNotificationId(), Customer));
    end;

    /// <summary>
    /// IsOverdueBalanceNotificationEnabled.
    /// </summary>
    /// <param name="Customer">Record Customer.</param>
    /// <returns>Return value of type Boolean.</returns>
    procedure IsOverdueBalanceNotificationEnabled(Customer: Record Customer): Boolean
    var
        MyNotifications: Record "My Notifications";
    begin
        exit(MyNotifications.IsEnabledForRecord(GetOverdueBalanceNotificationId(), Customer));
    end;

    [EventSubscriber(ObjectType::Page, 1518, 'OnInitializingNotificationWithDefaultState', '', false, false)]
    local procedure OnInitializingNotificationWithDefaultState()
    var
        MyNotifications: Record "My Notifications";
    begin
        MyNotifications.InsertDefaultWithTableNum(GetCreditLimitNotificationId(),
          CreditLimitNotificationMsg,
          CreditLimitNotificationDescriptionTxt,
          DATABASE::Customer);
        MyNotifications.InsertDefaultWithTableNum(GetOverdueBalanceNotificationId(),
          OverdueBalanceNotificationMsg,
          OverdueBalanceNotificationDescriptionTxt,
          DATABASE::Customer);
    end;

    /// <summary>
    /// OnNewCheckRemoveCustomerNotifications.
    /// </summary>
    /// <param name="RecId">RecordID.</param>
    /// <param name="RecallCreditOverdueNotif">Boolean.</param>
    [IntegrationEvent(false, false)]
    procedure OnNewCheckRemoveCustomerNotifications(RecId: RecordID; RecallCreditOverdueNotif: Boolean)
    begin
    end;

    /// <summary>
    /// GetCreditLimitNotificationMsg.
    /// </summary>
    /// <returns>Return value of type Text.</returns>
    procedure GetCreditLimitNotificationMsg(): Text
    begin
        exit(CreditLimitNotificationMsg);
    end;

    /// <summary>
    /// GetOverdueBalanceNotificationMsg.
    /// </summary>
    /// <returns>Return value of type Text.</returns>
    procedure GetOverdueBalanceNotificationMsg(): Text
    begin
        exit(OverdueBalanceNotificationMsg);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRentalHeaderCheck(var RentalHeader: Record "TWE Rental Header"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRentalLineCheck(var RentalLine: Record "TWE Rental Line"; var IsHandled: Boolean)
    begin
    end;
}

