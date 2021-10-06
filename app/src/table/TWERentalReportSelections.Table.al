/// <summary>
/// Table TWE Rental Report Selections (ID 50027).
/// </summary>
table 50027 "TWE Rental Report Selections"
{
    Caption = 'Rental Report Selections';

    fields
    {
        field(1; Usage; Enum "TWE Rent. Report Sel. Usage")
        {
            Caption = 'Usage';
            DataClassification = CustomerContent;
        }
        field(2; Sequence; Code[10])
        {
            Caption = 'Sequence';
            DataClassification = CustomerContent;
            Numeric = true;
        }
        field(3; "Report ID"; Integer)
        {
            Caption = 'Report ID';
            DataClassification = CustomerContent;
            TableRelation = AllObjWithCaption."Object ID" WHERE("Object Type" = CONST(Report));

            trigger OnValidate()
            begin
                CalcFields("Report Caption");
                Validate("Use for Email Body", false);
            end;
        }
        field(4; "Report Caption"; Text[250])
        {
            CalcFormula = Lookup(AllObjWithCaption."Object Caption" WHERE("Object Type" = CONST(Report),
                                                                           "Object ID" = FIELD("Report ID")));
            Caption = 'Report Caption';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7; "Custom Report Layout Code"; Code[20])
        {
            Caption = 'Custom Report Layout Code';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "Custom Report Layout".Code WHERE(Code = FIELD("Custom Report Layout Code"));
        }
        field(19; "Use for Email Attachment"; Boolean)
        {
            Caption = 'Use for Email Attachment';
            DataClassification = CustomerContent;
            InitValue = true;

            trigger OnValidate()
            begin
                if not "Use for Email Body" then
                    Validate("Email Body Layout Code", '');
            end;
        }
        field(20; "Use for Email Body"; Boolean)
        {
            Caption = 'Use for Email Body';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if not "Use for Email Body" then
                    Validate("Email Body Layout Code", '');
            end;
        }
        field(21; "Email Body Layout Code"; Code[20])
        {
            Caption = 'Email Body Layout Code';
            DataClassification = CustomerContent;
            TableRelation = IF ("Email Body Layout Type" = CONST("Custom Report Layout")) "Custom Report Layout".Code WHERE(Code = FIELD("Email Body Layout Code"),
                                                                                                                           "Report ID" = FIELD("Report ID"))
            ELSE
            IF ("Email Body Layout Type" = CONST("HTML Layout")) "O365 HTML Template".Code;

            trigger OnValidate()
            begin
                if "Email Body Layout Code" <> '' then
                    TestField("Use for Email Body", true);
                CalcFields("Email Body Layout Description");
            end;
        }
        field(22; "Email Body Layout Description"; Text[250])
        {
            CalcFormula = Lookup("Custom Report Layout".Description WHERE(Code = FIELD("Email Body Layout Code")));
            Caption = 'Email Body Layout Description';
            Editable = false;
            FieldClass = FlowField;

            trigger OnLookup()
            var
                CustomReportLayout: Record "Custom Report Layout";
            begin
                if "Email Body Layout Type" = "Email Body Layout Type"::"Custom Report Layout" then
                    if CustomReportLayout.LookupLayoutOK("Report ID") then
                        Validate("Email Body Layout Code", CustomReportLayout.Code);
            end;
        }
        field(25; "Email Body Layout Type"; Option)
        {
            Caption = 'Email Body Layout Type';
            DataClassification = CustomerContent;
            OptionCaption = 'Custom Report Layout,HTML Layout';
            OptionMembers = "Custom Report Layout","HTML Layout";
        }
    }

    keys
    {
        key(Key1; Usage, Sequence)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        TestField("Report ID");
        CheckEmailBodyUsage();
    end;

    trigger OnModify()
    begin
        TestField("Report ID");
        CheckEmailBodyUsage();
    end;

    var
        ReportSelection2: Record "Report Selections";
        ReportLayoutSelection: Record "Report Layout Selection";
        FileManagement: Codeunit "File Management";
        OneRecordWillBeSentQst: Label 'Only the first of the selected documents can be scheduled in the job queue.\\Do you want to continue?';
        AccountNoTok: Label '''%1''', Locked = true;
        MailingJobCategoryTok: Label 'Sending invoices via email';
        MailingJobCategoryCodeTok: Label 'SENDINV', Comment = 'Must be max. 10 chars and no spacing. (Send Invoice)';

        MustSelectAndEmailBodyOrAttahmentErr: Label 'You must select an email body or attachment in report selection for %1.', Comment = '%1 = Usage, for example Sales Invoice';
        EmailBodyIsAlreadyDefinedErr: Label 'An email body is already defined for %1.', Comment = '%1 = Usage, for example Sales Invoice';
        CannotBeUsedAsAnEmailBodyErr: Label 'Report %1 uses the %2 which cannot be used as an email body.', Comment = '%1 = Report ID,%2 = Type';

    procedure NewRecord()
    begin
        ReportSelection2.SetRange(Usage, Usage);
        if ReportSelection2.FindLast() and (ReportSelection2.Sequence <> '') then
            Sequence := IncStr(ReportSelection2.Sequence)
        else
            Sequence := '1';
    end;

    /// <summary>
    /// InsertRecord.
    /// </summary>
    /// <param name="NewUsage">Enum "TWE Rent. Report Sel. Usage".</param>
    /// <param name="NewSequence">Code[10].</param>
    /// <param name="NewReportID">Integer.</param>
    procedure InsertRecord(NewUsage: Enum "TWE Rent. Report Sel. Usage"; NewSequence: Code[10]; NewReportID: Integer)
    begin
        Init();
        Usage := NewUsage;
        Sequence := NewSequence;
        "Report ID" := NewReportID;
        Insert();
    end;


    local procedure CheckEmailBodyUsage()
    var
        RentalReportSelections: Record "TWE Rental Report Selections";
        localReportLayoutSelection: Record "Report Layout Selection";
    begin
        if "Use for Email Body" then begin
            RentalReportSelections.SetEmailBodyUsageFilters(Usage);
            RentalReportSelections.SetFilter(Sequence, '<>%1', Sequence);
            if not RentalReportSelections.IsEmpty then
                Error(EmailBodyIsAlreadyDefinedErr, Usage);

            if "Email Body Layout Code" = '' then
                if localReportLayoutSelection.GetDefaultType("Report ID") =
                   localReportLayoutSelection.Type::"RDLC (built-in)"
                then
                    Error(CannotBeUsedAsAnEmailBodyErr, "Report ID", localReportLayoutSelection.Type);
        end;
    end;

    /// <summary>
    /// SetEmailUsageFilters.
    /// </summary>
    /// <param name="RentalReportUsage">Enum "TWE Rent. Report Sel. Usage".</param>
    procedure SetEmailUsageFilters(RentalReportUsage: Enum "TWE Rent. Report Sel. Usage")
    begin
        Reset();
        SetRange(Usage, RentalReportUsage);
        SetRange("Use for Email Body", true);
    end;

    procedure SetEmailBodyUsageFilters(RentalReportUsage: Enum "TWE Rent. Report Sel. Usage")
    begin
        Reset();
        SetRange(Usage, RentalReportUsage);
        SetRange("Use for Email Body", true);
    end;

    procedure SetEmailAttachmentUsageFilters(RentalReportUsage: Enum "TWE Rent. Report Sel. Usage")
    begin
        Reset();
        SetRange(Usage, RentalReportUsage);
        SetRange("Use for Email Attachment", true);
    end;

    /// <summary>
    /// FindRentalReportUsageForCust.
    /// </summary>
    /// <param name="RentalReportUsage">Enum "TWE Rent. Report Sel. Usage".</param>
    /// <param name="CustNo">Code[20].</param>
    /// <param name="RentalReportSelections">VAR Record "TWE Rental Report Selections".</param>
    procedure FindRentalReportUsageForCust(RentalReportUsage: Enum "TWE Rent. Report Sel. Usage"; CustNo: Code[20]; var RentalReportSelections: Record "TWE Rental Report Selections")
    begin
        FindPrintUsageInternal(RentalReportUsage, CustNo, RentalReportSelections, DATABASE::Customer);
    end;


    local procedure FindPrintUsageInternal(RentalReportUsage: Enum "TWE Rent. Report Sel. Usage"; AccountNo: Code[20]; var RentalReportSelections: Record "TWE Rental Report Selections"; TableNo: Integer)
    begin
        Reset();
        SetRange(Usage, RentalReportUsage);
        SetFilter("Report ID", '<>0');
        FindReportSelections(RentalReportSelections, AccountNo, TableNo);
        RentalReportSelections.FindSet();
    end;

    procedure FindEmailAttachmentUsageForCust(RentalReportUsage: Enum "TWE Rent. Report Sel. Usage"; CustNo: Code[20]; var RentalReportSelections: Record "TWE Rental Report Selections"): Boolean
    begin
        SetEmailAttachmentUsageFilters(RentalReportUsage);
        SetFilter("Report ID", '<>0');
        SetRange("Use for Email Attachment", true);
        FindReportSelections(RentalReportSelections, CustNo, DATABASE::Customer);
        exit(RentalReportSelections.FindSet());
    end;

    procedure FindEmailBodyUsageForCust(RentalReportUsage: Enum "TWE Rent. Report Sel. Usage"; CustNo: Code[20]; var RentalReportSelections: Record "TWE Rental Report Selections"): Boolean
    begin
        SetEmailBodyUsageFilters(RentalReportUsage);
        SetFilter("Report ID", '<>0');
        FindReportSelections(RentalReportSelections, CustNo, DATABASE::Customer);
        exit(RentalReportSelections.FindSet());
    end;

    procedure PrintWithCheckForCust(RentalReportUsage: Enum "TWE Rent. Report Sel. Usage"; RecordVariant: Variant; CustomerNoFieldNo: Integer)
    var
        Handled: Boolean;
    begin
        OnBeforePrintWithCheck(RentalReportUsage.AsInteger(), RecordVariant, CustomerNoFieldNo, Handled);
        if Handled then
            exit;

        PrintWithDialogWithCheckForCust(RentalReportUsage, RecordVariant, true, CustomerNoFieldNo);
    end;

    procedure PrintWithDialogWithCheckForCust(RentalReportUsage: Enum "TWE Rent. Report Sel. Usage"; RecordVariant: Variant; IsGUI: Boolean; CustomerNoFieldNo: Integer)
    var
        Handled: Boolean;
    begin
        OnBeforePrintWithGUIYesNoWithCheck(RentalReportUsage.AsInteger(), RecordVariant, IsGUI, CustomerNoFieldNo, Handled);
        if Handled then
            exit;

        PrintDocumentsWithCheckDialogCommon(
          RentalReportUsage, RecordVariant, IsGUI, CustomerNoFieldNo, true, DATABASE::Customer);
    end;

    procedure PrintReport(RentalReportUsage: Enum "TWE Rent. Report Sel. Usage"; RecordVariant: Variant)
    begin
        PrintForCust(RentalReportUsage, RecordVariant, 0);
    end;

    procedure PrintForCust(RentalReportUsage: Enum "TWE Rent. Report Sel. Usage"; RecordVariant: Variant; CustomerNoFieldNo: Integer)
    var
        Handled: Boolean;
    begin
        OnBeforePrint(RentalReportUsage.AsInteger(), RecordVariant, CustomerNoFieldNo, Handled);
        if Handled then
            exit;

        PrintWithDialogForCust(RentalReportUsage, RecordVariant, true, CustomerNoFieldNo);
    end;

    procedure PrintWithDialogForCust(RentalReportUsage: Enum "TWE Rent. Report Sel. Usage"; RecordVariant: Variant; IsGUI: Boolean; CustomerNoFieldNo: Integer)
    var
        Handled: Boolean;
    begin
        OnBeforePrintWithGUIYesNo(RentalReportUsage.AsInteger(), RecordVariant, IsGUI, CustomerNoFieldNo, Handled);
        if Handled then
            exit;

        PrintWithDialogWithCheckForCust("Report Selection Usage".FromInteger(RentalReportUsage), RecordVariant, IsGUI, CustomerNoFieldNo);
        // PrintDocumentsWithCheckDialogCommon(
        //   RentalReportUsage, RecordVariant, IsGUI, CustomerNoFieldNo, true, DATABASE::Customer);
    end;

    local procedure PrintDocumentsWithCheckDialogCommon(RentalReportUsage: Enum "TWE Rent. Report Sel. Usage"; RecordVariant: Variant; IsGUI: Boolean; AccountNoFieldNo: Integer; WithCheck: Boolean; TableNo: Integer)
    var
        TempRentalReportSelections: Record "TWE Rental Report Selections" temporary;
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
        RecRef: RecordRef;
        RecRefToPrint: RecordRef;
        RecVarToPrint: Variant;
        AccountNoFilter: Text;
        IsHandled: Boolean;
    begin
        OnBeforeSetReportLayout(RecordVariant, RentalReportUsage.AsInteger());

        RecRef.GetTable(RecordVariant);
        GetUniqueAccountNos(TempNameValueBuffer, RecRef, AccountNoFieldNo);

        SelectTempReportSelectionsToPrint(TempRentalReportSelections, TempNameValueBuffer, WithCheck, RentalReportUsage, TableNo);
        OnPrintDocumentsOnAfterSelectTempReportSelectionsToPrint(
          RecordVariant, TempRentalReportSelections, TempNameValueBuffer, WithCheck, RentalReportUsage.AsInteger(), TableNo);
        if TempRentalReportSelections.FindSet() then
            repeat
                if TempRentalReportSelections."Custom Report Layout Code" <> '' then
                    ReportLayoutSelection.SetTempLayoutSelected(TempRentalReportSelections."Custom Report Layout Code")
                else
                    ReportLayoutSelection.SetTempLayoutSelected('');

                TempNameValueBuffer.FindSet();
                AccountNoFilter := GetAccountNoFilterForCustomReportLayout(TempRentalReportSelections, TempNameValueBuffer, TableNo);
                GetFilteredRecordRef(RecRefToPrint, RecRef, AccountNoFieldNo, AccountNoFilter);
                RecVarToPrint := RecRefToPrint;

                IsHandled := false;
                OnBeforePrintDocument(TempRentalReportSelections, IsGUI, RecVarToPrint, IsHandled);
                if not IsHandled then
                    REPORT.RunModal(TempRentalReportSelections."Report ID", IsGUI, false, RecVarToPrint);

                OnAfterPrintDocument(TempRentalReportSelections, IsGUI, RecVarToPrint);

                ReportLayoutSelection.SetTempLayoutSelected('');
            until TempRentalReportSelections.Next() = 0;

        OnAfterPrintDocumentsWithCheckGUIYesNoCommon(RentalReportUsage.AsInteger(), RecVarToPrint);
    end;

    local procedure GetFilteredRecordRef(var RecRefToPrint: RecordRef; RecRefSource: RecordRef; AccountNoFieldNo: Integer; AccountNoFilter: Text)
    var
        AccountNoFieldRef: FieldRef;
    begin
        RecRefToPrint := RecRefSource.Duplicate();

        if (AccountNoFieldNo <> 0) and (AccountNoFilter <> '') then begin
            AccountNoFieldRef := RecRefToPrint.Field(AccountNoFieldNo);
            AccountNoFieldRef.SetFilter(AccountNoFilter);
        end;

        if RecRefToPrint.FindSet() then;
    end;

    local procedure GetAccountNoFilterForCustomReportLayout(var TempRentalReportSelections: Record "TWE Rental Report Selections" temporary; var TempNameValueBuffer: Record "Name/Value Buffer" temporary; TableNo: Integer): Text
    var
        CustomReportSelection: Record "Custom Report Selection";
        AccountNo: Code[20];
        AccountNoFilter: Text;
        AccountHasCustomSelection: Boolean;
        ReportInvolvedInCustomSelection: Boolean;
    begin
        CustomReportSelection.SetRange("Source Type", TableNo);
        CustomReportSelection.SetRange(Usage, TempRentalReportSelections.Usage);
        CustomReportSelection.SetRange("Report ID", TempRentalReportSelections."Report ID");

        ReportInvolvedInCustomSelection := not CustomReportSelection.IsEmpty;

        AccountNoFilter := '';

        TempNameValueBuffer.FindSet();
        repeat
            AccountNo := CopyStr(TempNameValueBuffer.Name, 1, MaxStrLen(AccountNo));
            CustomReportSelection.SetRange("Source No.", AccountNo);

            if ReportInvolvedInCustomSelection then begin
                CustomReportSelection.SetRange("Custom Report Layout Code", TempRentalReportSelections."Custom Report Layout Code");

                AccountHasCustomSelection := not CustomReportSelection.IsEmpty;
                if AccountHasCustomSelection then
                    AccountNoFilter += StrSubstNo(AccountNoTok, AccountNo) + '|';

                CustomReportSelection.SetRange("Custom Report Layout Code");
            end else begin
                CustomReportSelection.SetRange("Report ID");

                AccountHasCustomSelection := not CustomReportSelection.IsEmpty;
                if not AccountHasCustomSelection then
                    AccountNoFilter += StrSubstNo(AccountNoTok, AccountNo) + '|';

                CustomReportSelection.SetRange("Report ID", TempRentalReportSelections."Report ID");
            end;

        until TempNameValueBuffer.Next() = 0;

        AccountNoFilter := DelChr(AccountNoFilter, '>', '|');
        exit(AccountNoFilter);
    end;

    local procedure SelectTempReportSelections(var TempRentalReportSelections: Record "TWE Rental Report Selections" temporary; AccountNo: Code[20]; WithCheck: Boolean; RentalReportUsage: Enum "TWE Rent. Report Sel. Usage"; TableNo: Integer)
    begin
        if WithCheck then begin
            Reset();
            SetRange(Usage, RentalReportUsage);
            FindReportSelections(TempRentalReportSelections, AccountNo, TableNo);
            if not TempRentalReportSelections.FindSet() then
                FindSet();
        end else
            FindPrintUsageInternal(RentalReportUsage, AccountNo, TempRentalReportSelections, TableNo);
    end;

    local procedure SelectTempReportSelectionsToPrint(var TempRentalReportSelections: Record "TWE Rental Report Selections" temporary; var TempNameValueBuffer: Record "Name/Value Buffer" temporary; WithCheck: Boolean; RentalReportUsage: Enum "TWE Rent. Report Sel. Usage"; TableNo: Integer)
    var
        rentalReportSelectionsAccount: Record "TWE Rental Report Selections";
        accountNo: Code[20];
        lastSequence: Code[10];
    begin
        if TempNameValueBuffer.FindSet() then
            repeat
                accountNo := CopyStr(TempNameValueBuffer.Name, 1, MaxStrLen(accountNo));
                rentalReportSelectionsAccount.SetRange(Usage, RentalReportUsage);
                if rentalReportSelectionsAccount.FindSet() then
                    repeat
                        lastSequence := GetLastSequenceNo(rentalReportSelectionsAccount, RentalReportUsage);
                        if not HasReportWithUsage(TempRentalReportSelections, RentalReportUsage, rentalReportSelectionsAccount."Report ID") then begin
                            TempRentalReportSelections := rentalReportSelectionsAccount;
                            if lastSequence = '' then
                                TempRentalReportSelections.Sequence := '1'
                            else
                                TempRentalReportSelections.Sequence := IncStr(lastSequence);
                            TempRentalReportSelections.Insert();
                        end;
                    until rentalReportSelectionsAccount.Next() = 0;
            until TempNameValueBuffer.Next() = 0;
    end;

    /// <summary>
    /// GetHtmlReportForCust.
    /// </summary>
    /// <param name="DocumentContent">VAR Text.</param>
    /// <param name="RentalReportUsage">Enum "Report Selection Usage".</param>
    /// <param name="RecordVariant">Variant.</param>
    /// <param name="CustNo">Code[20].</param>
    procedure GetHtmlReportForCust(var DocumentContent: Text; RentalReportUsage: Enum "TWE Rent. Report Sel. Usage"; RecordVariant: Variant; CustNo: Code[20])
    var
        TempBodyRentalReportSelections: Record "TWE Rental Report Selections" temporary;
        ServerEmailBodyFilePath: Text[250];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetHtmlReport(DocumentContent, RentalReportUsage.AsInteger(), RecordVariant, CustNo, IsHandled);
        if IsHandled then
            exit;

        FindRentalReportUsageForCust(RentalReportUsage, CustNo, TempBodyRentalReportSelections);

        ServerEmailBodyFilePath :=
            SaveReportAsHTML(TempBodyRentalReportSelections."Report ID", RecordVariant, TempBodyRentalReportSelections."Custom Report Layout Code", RentalReportUsage);

        DocumentContent := '';
        /*         if ServerEmailBodyFilePath <> '' then
                    DocumentContent := FileManagement.GetFileContents(ServerEmailBodyFilePath); */
    end;

    /// <summary>
    /// GetPdfReportForCust.
    /// </summary>
    /// <param name="ServerEmailBodyFilePath">VAR Text[250].</param>
    /// <param name="RentalReportUsage">Enum "Report Selection Usage".</param>
    /// <param name="RecordVariant">Variant.</param>
    /// <param name="CustNo">Code[20].</param>
    procedure GetPdfReportForCust(var ServerEmailBodyFilePath: Text[250]; RentalReportUsage: Enum "TWE Rent. Report Sel. Usage"; RecordVariant: Variant; CustNo: Code[20])
    var
        TempBodyRentalReportSelections: Record "TWE Rental Report Selections" temporary;
    begin
        ServerEmailBodyFilePath := '';

        FindRentalReportUsageForCust(RentalReportUsage, CustNo, TempBodyRentalReportSelections);

        ServerEmailBodyFilePath :=
            SaveReportAsPDF(TempBodyRentalReportSelections."Report ID", RecordVariant, TempBodyRentalReportSelections."Custom Report Layout Code", RentalReportUsage);
    end;

    /// <summary>
    /// GetPdfReportForCust.
    /// </summary>
    /// <param name="TempBlob">VAR Codeunit "Temp Blob".</param>
    /// <param name="RentalReportUsage">Enum "TWE Rent. Report Sel. Usage".</param>
    /// <param name="RecordVariant">Variant.</param>
    /// <param name="CustNo">Code[20].</param>
    procedure GetPdfReportForCust(var TempBlob: Codeunit "Temp Blob"; RentalReportUsage: Enum "TWE Rent. Report Sel. Usage"; RecordVariant: Variant; CustNo: Code[20])
    var
        TempBodyRentalReportSelections: Record "TWE Rental Report Selections" temporary;
    begin
        FindRentalReportUsageForCust(RentalReportUsage, CustNo, TempBodyRentalReportSelections);

        SaveReportAsPDFInTempBlob(TempBlob, TempBodyRentalReportSelections."Report ID", RecordVariant, TempBodyRentalReportSelections."Custom Report Layout Code", RentalReportUsage);
    end;

    /// <summary>
    /// GetEmailBodyForCust.
    /// </summary>
    /// <param name="ServerEmailBodyFilePath">VAR Text[250].</param>
    /// <param name="RentalReportUsage">Enum "TWE Rent. Report Sel. Usage".</param>
    /// <param name="RecordVariant">Variant.</param>
    /// <param name="CustNo">Code[20].</param>
    /// <param name="CustEmailAddress">VAR Text[250].</param>
    /// <returns>Return value of type Boolean.</returns>
    procedure GetEmailBodyForCust(var ServerEmailBodyFilePath: Text[250]; RentalReportUsage: Enum "TWE Rent. Report Sel. Usage"; RecordVariant: Variant; CustNo: Code[20]; var CustEmailAddress: Text): Boolean
    begin
        exit(
            GetEmailBodyTextForCust(
                ServerEmailBodyFilePath, RentalReportUsage, RecordVariant, CustNo, CustEmailAddress, ''));
    end;

    /// <summary>
    /// GetEmailBodyTextForCust.
    /// </summary>
    /// <param name="ServerEmailBodyFilePath">VAR Text[250].</param>
    /// <param name="RentalReportUsage">Enum "TWE Rent. Report Sel. Usage".</param>
    /// <param name="RecordVariant">Variant.</param>
    /// <param name="CustNo">Code[20].</param>
    /// <param name="CustEmailAddress">VAR Text[250].</param>
    /// <param name="EmailBodyText">Text.</param>
    /// <returns>Return variable Result of type Boolean.</returns>
    procedure GetEmailBodyTextForCust(var ServerEmailBodyFilePath: Text[250]; RentalReportUsage: Enum "TWE Rent. Report Sel. Usage"; RecordVariant: Variant; CustNo: Code[20]; var CustEmailAddress: Text; EmailBodyText: Text) Result: Boolean
    var
        TempBodyRentalReportSelections: Record "TWE Rental Report Selections" temporary;
        //O365HTMLTemplMgt: Codeunit "O365 HTML Templ. Mgt.";
        IsHandled: Boolean;
    begin
        ServerEmailBodyFilePath := '';

        IsHandled := false;
        OnBeforeGetEmailBodyCustomer(
            RentalReportUsage.AsInteger(), RecordVariant, TempBodyRentalReportSelections, CustNo, CustEmailAddress, EmailBodyText, IsHandled);
        if IsHandled then
            exit;

        if CustEmailAddress = '' then
            CustEmailAddress := GetEmailAddressIgnoringLayout(RentalReportUsage, RecordVariant, CustNo);

        if not FindEmailBodyUsageForCust(RentalReportUsage, CustNo, TempBodyRentalReportSelections) then begin
            IsHandled := false;
            OnGetEmailBodyCustomerTextOnAfterNotFindEmailBodyUsage(
                RentalReportUsage.AsInteger(), RecordVariant, CustNo, TempBodyRentalReportSelections, IsHandled);
            if IsHandled then
                exit(true);
            exit(false);
        end;

        case "Email Body Layout Type" of
            "Email Body Layout Type"::"Custom Report Layout":
                ServerEmailBodyFilePath :=
                    SaveReportAsHTML(TempBodyRentalReportSelections."Report ID", RecordVariant, TempBodyRentalReportSelections."Email Body Layout Code", RentalReportUsage);
        /*             "Email Body Layout Type"::"HTML Layout":
                        ServerEmailBodyFilePath :=
                            O365HTMLTemplMgt.CreateEmailBodyFromReportSelections(Rec, RecordVariant, CustEmailAddress, EmailBodyText); */
        end;

        CustEmailAddress := GetEmailAddress(RentalReportUsage, RecordVariant, CustNo, TempBodyRentalReportSelections);

        IsHandled := false;
        OnAfterGetEmailBodyCustomer(CustEmailAddress, ServerEmailBodyFilePath, RecordVariant, Result, IsHandled);
        if IsHandled then
            exit(Result);

        exit(true);
    end;

    local procedure GetEmailAddressIgnoringLayout(RentalReportUsage: Enum "TWE Rent. Report Sel. Usage"; RecordVariant: Variant; CustNo: Code[20]): Text
    var
        TempBodyRentalReportSelections: Record "TWE Rental Report Selections" temporary;
        EmailAddress: Text;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetEmailAddressIgnoringLayout(RentalReportUsage, RecordVariant, TempBodyRentalReportSelections, CustNo, EmailAddress, IsHandled);
        if IsHandled then
            exit(EmailAddress);

        EmailAddress := GetEmailAddress(RentalReportUsage, RecordVariant, CustNo, TempBodyRentalReportSelections);
        exit(EmailAddress);
    end;

    /// <summary>
    /// GetEmailAddressExt.
    /// </summary>
    /// <param name="RentalReportUsage">Integer.</param>
    /// <param name="RecordVariant">Variant.</param>
    /// <param name="CustNo">Code[20].</param>
    /// <param name="TempBodyRentalReportSelections">Temporary VAR Record "TWE Rental Report Selections".</param>
    /// <returns>Return value of type Text[250].</returns>
    procedure GetEmailAddressExt(RentalReportUsage: Integer; RecordVariant: Variant; CustNo: Code[20]; var TempBodyRentalReportSelections: Record "TWE Rental Report Selections" temporary): Text
    begin
        exit(GetEmailAddress("Report Selection Usage".FromInteger(RentalReportUsage), RecordVariant, CustNo, TempBodyRentalReportSelections));
    end;

    local procedure GetEmailAddress(RentalReportUsage: Enum "TWE Rent. Report Sel. Usage"; RecordVariant: Variant; CustNo: Code[20]; var TempBodyRentalReportSelections: Record "TWE Rental Report Selections" temporary): Text
    var
        DataTypeManagement: Codeunit "Data Type Management";
        RecordRef: RecordRef;
        FieldRef: FieldRef;
        DocumentNo: Code[20];
        EmailAddress: Text;
        IsHandled: Boolean;
    begin
        OnBeforeGetEmailAddress(RentalReportUsage.AsInteger(), RecordVariant, TempBodyRentalReportSelections, EmailAddress, IsHandled, CustNo);
        if IsHandled then
            exit(EmailAddress);

        RecordRef.GetTable(RecordVariant);
        if not RecordRef.IsEmpty then
            if DataTypeManagement.FindFieldByName(RecordRef, FieldRef, 'No.') then begin
                DocumentNo := FieldRef.Value;
                EmailAddress := GetEmailAddressForDoc(DocumentNo, RentalReportUsage);
                if EmailAddress <> '' then
                    exit(EmailAddress);
            end;

        if not TempBodyRentalReportSelections.IsEmpty then begin
            EmailAddress :=
              FindEmailAddressForEmailLayout(TempBodyRentalReportSelections."Email Body Layout Code", CustNo, RentalReportUsage, DATABASE::Customer);
            if EmailAddress <> '' then
                exit(EmailAddress);
        end;

        if not RecordRef.IsEmpty then
            if IsRentalDocument(RecordRef) then
                if DataTypeManagement.FindFieldByName(RecordRef, FieldRef, 'Rented-to E-Mail') then begin
                    EmailAddress := FieldRef.Value;
                    if EmailAddress <> '' then
                        exit(EmailAddress);
                end;

        EmailAddress := GetEmailAddressForCust(CustNo, RentalReportUsage);
        OnGetEmailAddressOnAfterGetEmailAddressForCust(RentalReportUsage, RecordVariant, TempBodyRentalReportSelections, EmailAddress, CustNo);
        if EmailAddress <> '' then
            exit(EmailAddress);

        exit(EmailAddress);
    end;

    /// <summary>
    /// SendEmailInBackground.
    /// </summary>
    /// <param name="JobQueueEntry">Record "Job Queue Entry".</param>
    procedure SendEmailInBackground(JobQueueEntry: Record "Job Queue Entry")
    var
        RecRef: RecordRef;
        RentalReportUsage: Integer;
        DocNo: Code[20];
        DocName: Text[150];
        No: Code[20];
        ParamString: Text;
    begin
        // Called from codeunit 260 OnRun trigger - in a background process.
        RecRef.Get(JobQueueEntry."Record ID to Process");
        RecRef.LockTable();
        RecRef.Find();
        RecRef.SetRecFilter();
        ParamString := JobQueueEntry."Parameter String";  // Are set in function SendEmailToCust
        GetJobQueueParameters(ParamString, RentalReportUsage, DocNo, DocName, No);
        OnSendEmailInBackgroundOnAfterGetJobQueueParameters(RecRef, ParamString);

        SendEmailToCustDirectly("Report Selection Usage".FromInteger(RentalReportUsage), RecRef, DocNo, DocName, false, No);
    end;

    /// <summary>
    /// GetJobQueueParameters.
    /// </summary>
    /// <param name="ParameterString">VAR Text.</param>
    /// <param name="RentalReportUsage">VAR Integer.</param>
    /// <param name="DocNo">VAR Code[20].</param>
    /// <param name="DocName">VAR Text[150].</param>
    /// <param name="CustNo">VAR Code[20].</param>
    /// <returns>Return variable WasSuccessful of type Boolean.</returns>
    procedure GetJobQueueParameters(var ParameterString: Text; var RentalReportUsage: Integer; var DocNo: Code[20]; var DocName: Text[150]; var CustNo: Code[20]) WasSuccessful: Boolean
    begin
        WasSuccessful := Evaluate(RentalReportUsage, GetNextJobQueueParam(ParameterString));
        WasSuccessful := WasSuccessful and Evaluate(DocNo, GetNextJobQueueParam(ParameterString));
        WasSuccessful := WasSuccessful and Evaluate(DocName, GetNextJobQueueParam(ParameterString));
        WasSuccessful := WasSuccessful and Evaluate(CustNo, GetNextJobQueueParam(ParameterString));
    end;

    /// <summary>
    /// RunGetNextJobQueueParam.
    /// </summary>
    /// <param name="Parameter">VAR Text.</param>
    /// <returns>Return value of type Text.</returns>
    procedure RunGetNextJobQueueParam(var Parameter: Text): Text
    begin
        exit(GetNextJobQueueParam(Parameter));
    end;

    local procedure GetNextJobQueueParam(var Parameter: Text): Text
    var
        i: Integer;
        Result: Text;
    begin
        i := StrPos(Parameter, '|');
        if i > 0 then
            Result := CopyStr(Parameter, 1, i - 1);
        if (i + 1) < StrLen(Parameter) then
            Parameter := CopyStr(Parameter, i + 1);
        exit(Result);
    end;

    local procedure EnqueueMailingJob(RecordIdToProcess: RecordID; ParameterString: Text; Description: Text)
    var
        JobQueueEntry: Record "Job Queue Entry";
        EmailFeature: Codeunit "Email Feature";
        MaxNumberOfRetries: Integer;
    begin
        MaxNumberOfRetries := 3;
        if EmailFeature.IsEnabled() then // Avoid multiple failed entries in the Email Outbox if the JQ fails
            MaxNumberOfRetries := 0; // So that the job runs only once

        JobQueueEntry.Init();
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := CODEUNIT::"Document-Mailing";
        JobQueueEntry."Job Queue Category Code" := GetMailingJobCategory();
        JobQueueEntry."Maximum No. of Attempts to Run" := MaxNumberOfRetries;
        JobQueueEntry."Record ID to Process" := RecordIdToProcess;
        JobQueueEntry."Parameter String" := CopyStr(ParameterString, 1, MaxStrLen(JobQueueEntry."Parameter String"));
        JobQueueEntry.Description := CopyStr(Description, 1, MaxStrLen(JobQueueEntry.Description));
        CODEUNIT.Run(CODEUNIT::"Job Queue - Enqueue", JobQueueEntry);
    end;

    /// <summary>
    /// GetMailingJobCategory.
    /// </summary>
    /// <returns>Return value of type Code[10].</returns>
    procedure GetMailingJobCategory(): Code[10]
    var
        JobQueueCategory: Record "Job Queue Category";
        MailingJobCategoryCode: Code[10];
    begin
        MailingJobCategoryCode := GetMailingJobCategoryCode();
        if not JobQueueCategory.Get(MailingJobCategoryCode) then begin
            JobQueueCategory.Init();
            JobQueueCategory.Code := MailingJobCategoryCode;
            JobQueueCategory.Description := CopyStr(MailingJobCategoryTok, 1, MaxStrLen(JobQueueCategory.Description));
            JobQueueCategory.Insert();
        end;

        exit(JobQueueCategory.Code);
    end;

    local procedure GetMailingJobCategoryCode(): Code[10]
    begin
        exit(CopyStr(MailingJobCategoryCodeTok, 1, 10));
    end;

    /// <summary>
    /// SaveAsDocumentAttachment.
    /// </summary>
    /// <param name="RentalReportUsage">Integer.</param>
    /// <param name="RecordVariant">Variant.</param>
    /// <param name="DocumentNo">Code[20].</param>
    /// <param name="AccountNo">Code[20].</param>
    /// <param name="ShowNotificationAction">Boolean.</param>
    procedure SaveAsDocumentAttachment(RentalReportUsage: Integer; RecordVariant: Variant; DocumentNo: Code[20]; AccountNo: Code[20]; ShowNotificationAction: Boolean)
    var
        TempAttachRentalReportSelections: Record "TWE Rental Report Selections" temporary;
        DocumentAttachment: Record "Document Attachment";
        DocumentAttachmentMgmt: Codeunit "Document Attachment Mgmt";
        //TempBlob: Codeunit "Temp Blob";
        RecRef: RecordRef;
        FileName: Text[250];
        NumberOfReportsAttached: Integer;
        Placeholder001Lbl: Label '%1 %2 %3', Comment = '%1= TempAttachRentalReportSelections."Report ID",%2= TempAttachRentalReportSelections."Report Caption",%3= DocumentNo';
    begin
        RecRef.GETTABLE(RecordVariant);
        if not RecRef.Find() then
            exit;

        FindPrintUsageInternal(
            "Report Selection Usage".FromInteger(RentalReportUsage), AccountNo, TempAttachRentalReportSelections, GetAccountTableId(RecRef.Number()));
        repeat
            /* if CanSaveReportAsPDF(TempAttachRentalReportSelections."Report ID") then begin
                FileManagement.BLOBImportFromServerFile(
                    TempBlob,
                    SaveReportAsPDF(
                        "Report ID", RecordVariant, "Custom Report Layout Code", "Report Selection Usage".FromInteger(RentalReportUsage))); */

            CLEAR(DocumentAttachment);
            DocumentAttachment.InitFieldsFromRecRef(RecRef);
            DocumentAttachment."Document Flow Sales" := RecRef.Number() = Database::"Sales Header";
            DocumentAttachment."Document Flow Purchase" := RecRef.Number() = Database::"Purchase Header";
            TempAttachRentalReportSelections.CalcFields("Report Caption");
            FileName :=
                DocumentAttachment.FindUniqueFileName(
                    STRSUBSTNO(Placeholder001Lbl, TempAttachRentalReportSelections."Report ID", TempAttachRentalReportSelections."Report Caption", DocumentNo), 'pdf');
            //DocumentAttachment.SaveAttachment(RecRef, FileName, TempBlob);
            NumberOfReportsAttached += 1;
        //end;
        until TempAttachRentalReportSelections.Next() = 0;

        DocumentAttachmentMgmt.ShowNotification(RecordVariant, NumberOfReportsAttached, ShowNotificationAction)
    end;

    local procedure GetAccountTableId(DocumentTableId: Integer): Integer
    begin
        case DocumentTableId of
            Database::"TWE Rental Header",
            Database::"TWE Rental Invoice Header",
            Database::"TWE Rental Cr.Memo Header",
            Database::"TWE Rental Shipment Header",
            Database::"Return Receipt Header":
                exit(Database::Customer);
        end;
    end;

    /*     local procedure CanSaveReportAsPDF(ReportId: Integer): Boolean
        var
            DummyInStream: InStream;
        begin
            exit(Report.RdlcLayout(ReportId, DummyInStream) or Report.WordLayout(ReportId, DummyInStream));
        end; */

    /// <summary>
    /// SendEmailToCust.
    /// </summary>
    /// <param name="RentalReportUsage">Integer.</param>
    /// <param name="RecordVariant">Variant.</param>
    /// <param name="DocNo">Code[20].</param>
    /// <param name="DocName">Text[150].</param>
    /// <param name="ShowDialog">Boolean.</param>
    /// <param name="CustNo">Code[20].</param>
    procedure SendEmailToCust(RentalReportUsage: Integer; RecordVariant: Variant; DocNo: Code[20]; DocName: Text[150]; ShowDialog: Boolean; CustNo: Code[20])
    var
        //O365DocumentSentHistory: Record "O365 Document Sent History";
        //GraphMail: Codeunit "Graph Mail";
        MailManagement: Codeunit "Mail Management";
        OfficeMgt: Codeunit "Office Management";
        RecRef: RecordRef;
        RentalReportUsageEnum: Enum "Report Selection Usage";
        // UpdateDocumentSentHistory: Boolean;
        Handled: Boolean;
        ParameterString: Text;
        Placeholder001Lbl: Label '%1|%2|%3|%4|', Comment = '%1= RentalReportUsage,%2= DocNo,%3= DocName,%4= CustNo';
    begin
        OnBeforeSendEmailToCust(RentalReportUsage, RecordVariant, DocNo, DocName, ShowDialog, CustNo, Handled);
        if Handled then
            exit;

        RecRef.GetTable(RecordVariant);
        RentalReportUsageEnum := "Report Selection Usage".FromInteger(RentalReportUsage);

        /*  if GraphMail.IsEnabled and GraphMail.HasConfiguration then begin
             if O365DocumentSentHistory.NewInProgressFromRecRef(RecRef) then begin
                 O365DocumentSentHistory.SetStatusAsFailed();
                 UpdateDocumentSentHistory := true;
             end;

             if SendEmailToCustDirectly(RentalReportUsageEnum, RecordVariant, DocNo, DocName, ShowDialog, CustNo) and UpdateDocumentSentHistory then
                 O365DocumentSentHistory.SetStatusAsSuccessfullyFinished;

             exit;
         end; */

        if ShowDialog or
           (not MailManagement.IsEnabled()) or
           (GetEmailAddressIgnoringLayout(RentalReportUsageEnum, RecordVariant, CustNo) = '') or
           OfficeMgt.IsAvailable()
        then begin
            SendEmailToCustDirectly(RentalReportUsageEnum, RecordVariant, DocNo, DocName, true, CustNo);
            exit;
        end;

        RecRef.GetTable(RecordVariant);
        if RecRef.FindSet() then
            repeat
                ParameterString := StrSubstNo(Placeholder001Lbl, RentalReportUsage, DocNo, DocName, CustNo);
                OnSendEmailToCustOnAfterSetParameterString(RecRef, ParameterString);
                EnqueueMailingJob(RecRef.RecordId, ParameterString, DocName);
            until RecRef.Next() = 0;
    end;

    local procedure SendEmailToCustDirectly(RentalReportUsage: Enum "TWE Rent. Report Sel. Usage"; RecordVariant: Variant; DocNo: Code[20]; DocName: Text[150]; ShowDialog: Boolean; CustNo: Code[20]): Boolean
    var
        //TempAttachRentalReportSelections: Record "TWE Rental Report Selections" temporary;
        CustomReportSelection: Record "Custom Report Selection";
        EmailParameter: Record "Email Parameter";
        MailManagement: Codeunit "Mail Management";
        //FoundBody: Boolean;
        // FoundAttachment: Boolean;
        // ServerEmailBodyFilePath: Text[250];
        //EmailAddress: Text[250];
        EmailBodyText: Text;
    begin
        if EmailParameter.GetParameterWithReportUsage(DocNo, RentalReportUsage, EmailParameter."Parameter Type"::Body) then
            EmailBodyText := EmailParameter.GetParameterValue();

        OnBeforeSetReportLayout(RecordVariant, RentalReportUsage.AsInteger());
        BindSubscription(MailManagement);
        //FoundBody := GetEmailBodyTextForCust(ServerEmailBodyFilePath, RentalReportUsage, RecordVariant, CustNo, EmailAddress, EmailBodyText);
        UnbindSubscription(MailManagement);
        //FoundAttachment := FindEmailAttachmentUsageForCust(RentalReportUsage, CustNo, TempAttachRentalReportSelections);

        CustomReportSelection.SetRange("Source Type", DATABASE::Customer);
        CustomReportSelection.SetRange("Source No.", CustNo);
        /* exit(SendEmailDirectly(
            RentalReportUsage, RecordVariant, DocNo, DocName, FoundBody, FoundAttachment, ServerEmailBodyFilePath, EmailAddress, ShowDialog,
            TempAttachRentalReportSelections, CustomReportSelection)); */
    end;

    /*local procedure SendEmailDirectly(RentalReportUsage: Enum "TWE Rent. Report Sel. Usage"; RecordVariant: Variant; DocNo: Code[20]; DocName: Text[150]; FoundBody: Boolean; FoundAttachment: Boolean; ServerEmailBodyFilePath: Text[250]; var DefaultEmailAddress: Text[250]; ShowDialog: Boolean; var TempAttachRentalReportSelections: Record "TWE Rental Report Selections" temporary; var CustomReportSelection: Record "Custom Report Selection") AllEmailsWereSuccessful: Boolean
    var
        DocumentMailing: Codeunit "Document-Mailing";
        OfficeAttachmentManager: Codeunit "Office Attachment Manager";
        ServerAttachmentFilePath: Text[250];
        EmailAddress: Text[250];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSendEmailDirectly(Rec, RentalReportUsage, RecordVariant, DocNo, DocName, FoundBody, FoundAttachment, ServerEmailBodyFilePath, DefaultEmailAddress, ShowDialog, TempAttachRentalReportSelections, CustomReportSelection, AllEmailsWereSuccessful, IsHandled);
        if IsHandled then
            exit(AllEmailsWereSuccessful);

        AllEmailsWereSuccessful := true;

        ShowNoBodyNoAttachmentError(RentalReportUsage, FoundBody, FoundAttachment);

        if FoundBody and not FoundAttachment then begin
            EmailAddress := CopyStr(
                GetNextEmailAddressFromCustomReportSelection(CustomReportSelection, DefaultEmailAddress, Usage, Sequence), 1, MaxStrLen(EmailAddress));
            AllEmailsWereSuccessful := DocumentMailing.EmailFile('', '', ServerEmailBodyFilePath, DocNo, EmailAddress, DocName, not ShowDialog, RentalReportUsage.AsInteger());
        end;

        if FoundAttachment then begin
            if RentalReportUsage = Usage::JQ then begin
                Usage := RentalReportUsage;
                CustomReportSelection.SetFilter(Usage, GetFilter(Usage));
                if CustomReportSelection.FindFirst() then
                    if CustomReportSelection.GetSendToEmail(true) <> '' then
                        DefaultEmailAddress := CustomReportSelection."Send To Email";
            end;

            OnSendEmailDirectlyOnBeforeSendFiles(
              RentalReportUsage.AsInteger(), RecordVariant, DefaultEmailAddress, TempAttachRentalReportSelections, CustomReportSelection);
            with TempAttachRentalReportSelections do begin
                OfficeAttachmentManager.IncrementCount(Count - 1);
                repeat
                    EmailAddress := CopyStr(
                        GetNextEmailAddressFromCustomReportSelection(CustomReportSelection, DefaultEmailAddress, Usage, Sequence),
                        1, MaxStrLen(EmailAddress));
                    ServerAttachmentFilePath := SaveReportAsPDF("Report ID", RecordVariant, "Custom Report Layout Code", RentalReportUsage);
                    AllEmailsWereSuccessful :=
                        AllEmailsWereSuccessful and
                        DocumentMailing.EmailFile(
                            ServerAttachmentFilePath, '', ServerEmailBodyFilePath,
                            DocNo, EmailAddress, DocName, not ShowDialog, RentalReportUsage.AsInteger());
                until Next() = 0;
            end;
        end;

        OnAfterSendEmailDirectly(RentalReportUsage.AsInteger(), RecordVariant, AllEmailsWereSuccessful);
        exit(AllEmailsWereSuccessful);
    end; */

    /// <summary>
    /// SendToDiskForCust.
    /// </summary>
    /// <param name="RentalReportUsage">Enum "TWE Rent. Report Sel. Usage".</param>
    /// <param name="RecordVariant">Variant.</param>
    /// <param name="DocNo">Code[20].</param>
    /// <param name="DocName">Text.</param>
    /// <param name="CustNo">Code[20].</param>    
    procedure SendToDiskForCust(RentalReportUsage: Enum "TWE Rent. Report Sel. Usage"; RecordVariant: Variant; DocNo: Code[20]; DocName: Text; CustNo: Code[20])
    var
        TempRentalReportSelections: Record "TWE Rental Report Selections" temporary;
        ElectronicDocumentFormat: Record "Electronic Document Format";
        // FileManagement: Codeunit "File Management";
        ServerAttachmentFilePath: Text[250];
        ClientAttachmentFileName: Text;
    begin
        OnBeforeSetReportLayout(RecordVariant, RentalReportUsage.AsInteger());
        FindRentalReportUsageForCust(RentalReportUsage, CustNo, TempRentalReportSelections);
        repeat
            ServerAttachmentFilePath := SaveReportAsPDF(TempRentalReportSelections."Report ID", RecordVariant, TempRentalReportSelections."Custom Report Layout Code", RentalReportUsage);
            ClientAttachmentFileName := ElectronicDocumentFormat.GetAttachmentFileName(DocNo, DocName, 'pdf');
        /*  FileManagement.DownloadHandler(
             ServerAttachmentFilePath, '', '', FileManagement.GetToFilterText('', ClientAttachmentFileName), ClientAttachmentFileName); */
        until TempRentalReportSelections.Next() = 0;
    end;

    /// <summary>
    /// SendToZipForCust.
    /// </summary>
    /// <param name="RentalReportUsage">Enum "TWE Rent. Report Sel. Usage".</param>
    /// <param name="RecordVariant">Variant.</param>
    /// <param name="DocNo">Code[20].</param>
    /// <param name="CustNo">Code[20].</param>
    /// <param name="DataCompression">VAR Codeunit "Data Compression".</param>
    procedure SendToZipForCust(RentalReportUsage: Enum "TWE Rent. Report Sel. Usage"; RecordVariant: Variant;
                                                  DocNo: Code[20];
                                                  CustNo: Code[20]; var DataCompression: Codeunit "Data Compression")
    var
        TempRentalReportSelections: Record "TWE Rental Report Selections" temporary;
        ElectronicDocumentFormat: Record "Electronic Document Format";
        ServerAttachmentTempBlob: Codeunit "Temp Blob";
        ServerAttachmentInStream: InStream;
        ServerAttachmentFilePath: Text;
    begin
        OnBeforeSetReportLayout(RecordVariant, RentalReportUsage.AsInteger());
        FindRentalReportUsageForCust(RentalReportUsage, CustNo, TempRentalReportSelections);
        repeat
            ServerAttachmentFilePath := SaveReportAsPDF(TempRentalReportSelections."Report ID", RecordVariant, TempRentalReportSelections."Custom Report Layout Code", RentalReportUsage);
            //FileManagement.BLOBImportFromServerFile(ServerAttachmentTempBlob, ServerAttachmentFilePath);
            ServerAttachmentTempBlob.CreateInStream(ServerAttachmentInStream);
            DataCompression.AddEntry(
              ServerAttachmentInStream, ElectronicDocumentFormat.GetAttachmentFileName(DocNo, Format(TempRentalReportSelections.Usage), 'pdf'));
        until TempRentalReportSelections.Next() = 0;
    end;

    /// <summary>
    /// GetEmailAddressForDoc.
    /// </summary>
    /// <param name="DocumentNo">Code[20].</param>
    /// <param name="RentalReportUsage">Enum "TWE Rent. Report Sel. Usage".</param>
    /// <returns>Return value of type Text[250].</returns>
    procedure GetEmailAddressForDoc(DocumentNo: Code[20]; RentalReportUsage: Enum "TWE Rent. Report Sel. Usage"): Text[250]
    var
        // EmailParameter: Record "Email Parameter";
        ToAddress: Text[250];
    begin
        /*         if EmailParameter.GetParameterWithRentalReportUsage(DocumentNo, RentalReportUsage, EmailParameter."Parameter Type"::Address) then
                    ToAddress := EmailParameter.GetParameterValue(); */

        exit(ToAddress);
    end;

    /// <summary>
    /// GetEmailAddressForCust.
    /// </summary>
    /// <param name="BillToCustomerNo">Code[20].</param>
    /// <param name="RentalReportUsage">Enum "TWE Rent. Report Sel. Usage".</param>
    /// <returns>Return value of type Text[250].</returns>
    procedure GetEmailAddressForCust(BillToCustomerNo: Code[20]; RentalReportUsage: Enum "TWE Rent. Report Sel. Usage"): Text
    var
        Customer: Record Customer;
        Contact: Record Contact;
        ToAddress: Text;
        IsHandled: Boolean;
    begin
        OnBeforeGetCustEmailAddress(BillToCustomerNo, ToAddress, RentalReportUsage.AsInteger(), IsHandled);
        if IsHandled then
            exit(ToAddress);

        if Customer.Get(BillToCustomerNo) then
            ToAddress := Customer."E-Mail"
        else
            if Contact.Get(BillToCustomerNo) then
                ToAddress := Contact."E-Mail";
        exit(ToAddress);
    end;

    local procedure SaveReportAsPDF(ReportID: Integer; RecordVariant: Variant; LayoutCode: Code[20]; RentalReportUsage: Enum "TWE Rent. Report Sel. Usage") FilePath: Text[250]
    var
        ReportLayoutSelectionLocal: Record "Report Layout Selection";
        // FileMgt: Codeunit "File Management";
        TempBlob: Codeunit "Temp Blob";
        IsHandled: Boolean;
    begin
        OnBeforeSetReportLayout(RecordVariant, RentalReportUsage.AsInteger());
        //FilePath := CopyStr(FileMgt.ServerTempFileName('pdf'), 1, 250);

        ReportLayoutSelectionLocal.SetTempLayoutSelected(LayoutCode);
        OnBeforeSaveReportAsPDF(ReportID, RecordVariant, LayoutCode, IsHandled, FilePath, RentalReportUsage, false, TempBlob);
        /*         if not IsHandled then
                    Report.SaveAsPdf(ReportID, FilePath, RecordVariant); */
        OnAfterSaveReportAsPDF(ReportID, RecordVariant, LayoutCode, FilePath, false, TempBlob);

        ReportLayoutSelectionLocal.SetTempLayoutSelected('');

        Commit();
    end;

    local procedure SaveReportAsPDFInTempBlob(var TempBlob: Codeunit "Temp Blob"; ReportID: Integer; RecordVariant: Variant; LayoutCode: Code[20]; RentalReportUsage: Enum "TWE Rent. Report Sel. Usage")
    var
        ReportLayoutSelectionLocal: Record "Report Layout Selection";
        IsHandled: Boolean;
        OutStream: OutStream;
    begin
        OnBeforeSetReportLayout(RecordVariant, RentalReportUsage.AsInteger());

        ReportLayoutSelectionLocal.SetTempLayoutSelected(LayoutCode);
        OnBeforeSaveReportAsPDF(ReportID, RecordVariant, LayoutCode, IsHandled, '', RentalReportUsage, true, TempBlob);
        if not IsHandled then begin
            TempBlob.CreateOutStream(OutStream);
            Report.SaveAs(ReportID, '', ReportFormat::Pdf, OutStream, RecordVariant);
        end;
        OnAfterSaveReportAsPDF(ReportID, RecordVariant, LayoutCode, '', true, TempBlob);

        ReportLayoutSelectionLocal.SetTempLayoutSelected('');

        Commit();
    end;

    local procedure SaveReportAsHTML(ReportID: Integer; RecordVariant: Variant; LayoutCode: Code[20]; RentalReportUsage: Enum "TWE Rent. Report Sel. Usage") FilePath: Text[250]
    var
        localReportLayoutSelection: Record "Report Layout Selection";
    //FileMgt: Codeunit "File Management";
    begin
        OnBeforeSetReportLayout(RecordVariant, RentalReportUsage.AsInteger());
        //FilePath := CopyStr(FileMgt.ServerTempFileName('html'), 1, 250);

        OnSaveReportAsHTMLOnBeforeSetTempLayoutSelected(RecordVariant, RentalReportUsage, ReportID, LayoutCode);
        localReportLayoutSelection.SetTempLayoutSelected(LayoutCode);
        //REPORT.SaveAsHtml(ReportID, FilePath, RecordVariant);
        localReportLayoutSelection.SetTempLayoutSelected('');

        Commit();
    end;

    local procedure FindReportSelections(var RentalReportSelections: Record "TWE Rental Report Selections"; AccountNo: Code[20]; TableNo: Integer): Boolean
    var
        Handled: Boolean;
    begin
        OnFindReportSelections(RentalReportSelections, Handled, Rec, AccountNo, TableNo);
        if Handled then
            exit(true);

        if CopyCustomReportSectionToReportSelection(AccountNo, RentalReportSelections, TableNo) then
            exit(true);

        exit(CopyReportSelectionToReportSelection(RentalReportSelections));
    end;

    local procedure CopyCustomReportSectionToReportSelection(AccountNo: Code[20]; var ToRentalReportSelections: Record "TWE Rental Report Selections"; TableNo: Integer): Boolean
    var
        CustomReportSelection: Record "Custom Report Selection";
    begin
        GetCustomReportSelectionByUsageFilter(CustomReportSelection, AccountNo, GetFilter(Usage), TableNo);
        CopyToReportSelection(ToRentalReportSelections, CustomReportSelection);

        if not ToRentalReportSelections.FindSet() then
            exit(false);
        exit(true);
    end;

    local procedure CopyToReportSelection(var ToRentalReportSelections: Record "TWE Rental Report Selections"; var CustomReportSelection: Record "Custom Report Selection")
    begin
        ToRentalReportSelections.Reset();
        ToRentalReportSelections.DeleteAll();
        if CustomReportSelection.FindSet() then
            repeat
                ToRentalReportSelections.Usage := CustomReportSelection.Usage;
                ToRentalReportSelections.Sequence := Format(CustomReportSelection.Sequence);
                ToRentalReportSelections."Report ID" := CustomReportSelection."Report ID";
                ToRentalReportSelections."Custom Report Layout Code" := CustomReportSelection."Custom Report Layout Code";
                ToRentalReportSelections."Email Body Layout Code" := CustomReportSelection."Email Body Layout Code";
                ToRentalReportSelections."Use for Email Attachment" := CustomReportSelection."Use for Email Attachment";
                ToRentalReportSelections."Use for Email Body" := CustomReportSelection."Use for Email Body";
                OnCopyToReportSelectionOnBeforInsertToReportSelections(ToRentalReportSelections, CustomReportSelection);
                ToRentalReportSelections.Insert();
            until CustomReportSelection.Next() = 0;
    end;

    local procedure CopyReportSelectionToReportSelection(var ToRentalReportSelections: Record "TWE Rental Report Selections"): Boolean
    begin
        ToRentalReportSelections.Reset();
        ToRentalReportSelections.DeleteAll();
        if FindSet() then
            repeat
                ToRentalReportSelections := Rec;
                if ToRentalReportSelections.Insert() then;
            until Next() = 0;

        exit(ToRentalReportSelections.FindSet());
    end;

    local procedure GetCustomReportSelection(var CustomReportSelection: Record "Custom Report Selection"; AccountNo: Code[20]; TableNo: Integer): Boolean
    var
        IsHandled: Boolean;
        ReturnValue: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetCustomReportSelection(Rec, CustomReportSelection, AccountNo, TableNo, ReturnValue, IsHandled);
        if IsHandled then
            exit(ReturnValue);

        CustomReportSelection.SetRange("Source Type", TableNo);
        CustomReportSelection.SetRange("Source No.", AccountNo);
        if CustomReportSelection.IsEmpty then
            exit(false);

        CustomReportSelection.SetFilter("Use for Email Attachment", GetFilter("Use for Email Attachment"));
        CustomReportSelection.SetFilter("Use for Email Body", GetFilter("Use for Email Body"));

        OnAfterGetCustomReportSelection(CustomReportSelection, AccountNo, TableNo);
    end;

    local procedure GetCustomReportSelectionByUsageFilter(var CustomReportSelection: Record "Custom Report Selection"; AccountNo: Code[20]; RentalReportUsageFilter: Text; TableNo: Integer): Boolean
    begin
        CustomReportSelection.SetFilter(Usage, RentalReportUsageFilter);
        exit(GetCustomReportSelection(CustomReportSelection, AccountNo, TableNo));
    end;

    local procedure GetCustomReportSelectionByUsageOption(var CustomReportSelection: Record "Custom Report Selection"; AccountNo: Code[20]; RentalReportUsage: Enum "TWE Rent. Report Sel. Usage"; TableNo: Integer): Boolean
    begin
        CustomReportSelection.SetRange(Usage, RentalReportUsage);
        exit(GetCustomReportSelection(CustomReportSelection, AccountNo, TableNo));
    end;

    local procedure GetNextEmailAddressFromCustomReportSelection(var CustomReportSelection: Record "Custom Report Selection"; DefaultEmailAddress: Text; RentalReportUsage: Enum "TWE Rent. Report Sel. Usage"; SequenceText: Text): Text
    var
        SequenceInteger: Integer;
    begin
        if Evaluate(SequenceInteger, SequenceText) then begin
            CustomReportSelection.SetRange(Usage, RentalReportUsage);
            CustomReportSelection.SetRange(Sequence, SequenceInteger);
            if CustomReportSelection.FindFirst() then
                if CustomReportSelection.GetSendToEmail(true) <> '' then
                    exit(CustomReportSelection."Send To Email");
        end;
        exit(DefaultEmailAddress);
    end;

    local procedure GetUniqueAccountNos(var TempNameValueBuffer: Record "Name/Value Buffer" temporary; RecRef: RecordRef; AccountNoFieldNo: Integer)
    var
        TempCustomer: Record Customer temporary;
        AccountNoFieldRef: FieldRef;
    begin
        if AccountNoFieldNo <> 0 then begin
            AccountNoFieldRef := RecRef.Field(AccountNoFieldNo);
            if RecRef.FindSet() then
                repeat
                    TempNameValueBuffer.ID += 1;
                    TempNameValueBuffer.Name := AccountNoFieldRef.Value;
                    TempCustomer."No." := AccountNoFieldRef.Value; // to avoid duplicate No. insertion into Name/Value buffer
                    if TempCustomer.Insert() then
                        TempNameValueBuffer.Insert();
                until RecRef.Next() = 0;
        end else begin
            TempNameValueBuffer.Init();
            TempNameValueBuffer.Insert();
        end;
    end;

    procedure PrintReportsForUsage(RentalReportUsage: Enum "TWE Rent. Report Sel. Usage")
    var
        RentalReportUsageInt: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        RentalReportUsageInt := RentalReportUsage.AsInteger();
        OnBeforePrintForUsage(RentalReportUsageInt, IsHandled);
        RentalReportUsage := "Report Selection Usage".FromInteger(RentalReportUsageInt);
        if IsHandled then
            exit;

        Reset();
        SetRange(Usage, RentalReportUsage);
        if FindSet() then
            repeat
                REPORT.RunModal("Report ID", true);
            until Next() = 0;
    end;

    local procedure FindEmailAddressForEmailLayout(LayoutCode: Code[20]; AccountNo: Code[20]; RentalReportUsage: Enum "TWE Rent. Report Sel. Usage"; TableNo: Integer): Text[200]
    var
        CustomReportSelection: Record "Custom Report Selection";
    begin
        // Search for a potential email address from Custom Report Selections
        GetCustomReportSelectionByUsageOption(CustomReportSelection, AccountNo, RentalReportUsage, TableNo);
        CustomReportSelection.UpdateSendtoEmail(false);
        CustomReportSelection.SetFilter("Send To Email", '<>%1', '');
        CustomReportSelection.SetRange("Email Body Layout Code", LayoutCode);
        if CustomReportSelection.FindFirst() then
            exit(CustomReportSelection."Send To Email");

        // Relax the filter and search for an email address
        CustomReportSelection.SetFilter("Use for Email Body", '');
        CustomReportSelection.SetRange("Email Body Layout Code", '');
        if CustomReportSelection.FindFirst() then
            exit(CustomReportSelection."Send To Email");
        exit('');
    end;

    local procedure ShowNoBodyNoAttachmentError(RentalReportUsage: Enum "TWE Rent. Report Sel. Usage"; FoundBody: Boolean;
                                                                       FoundAttachment: Boolean)
    begin
        if not (FoundBody or FoundAttachment) then begin
            Usage := RentalReportUsage;
            Error(MustSelectAndEmailBodyOrAttahmentErr, Usage);
        end;
    end;

    /// <summary>
    /// ConvertRentalReportUsageToRentalDocumentType.
    /// </summary>
    /// <param name="DocumentType">VAR Enum "TWE Rental Document Type".</param>
    /// <param name="RentalReportUsage">Enum "TWE Rent. Report Sel. Usage".</param>
    /// <returns>Return value of type Boolean.</returns>
    procedure ConvertRentalReportUsageToRentalDocumentType(var DocumentType: Enum "TWE Rental Document Type"; RentalReportUsage: Enum "TWE Rent. Report Sel. Usage"): Boolean
    begin
        case RentalReportUsage of
            Usage::"R.Invoice":
                DocumentType := "TWE Rental Document Type"::Invoice;
            Usage::"R.Quote":
                DocumentType := "TWE Rental Document Type"::Quote;
            Usage::"R.Cr.Memo":
                DocumentType := "TWE Rental Document Type"::"Credit Memo";
            Usage::"R.Contract":
                DocumentType := "TWE Rental Document Type"::Contract;
            else
                exit(false);
        end;
        exit(true);
    end;

    /// <summary>
    /// SendEmailInForeground.
    /// </summary>
    /// <param name="DocRecordID">RecordID.</param>
    /// <param name="DocNo">Code[20].</param>
    /// <param name="DocName">Text[150].</param>
    /// <param name="RentalReportUsage">Integer.</param>
    /// <param name="SourceIsCustomer">Boolean.</param>
    /// <param name="SourceNo">Code[20].</param>
    /// <returns>Return value of type Boolean.</returns>
    procedure SendEmailInForeground(DocRecordID: RecordID; DocNo: Code[20]; DocName: Text[150]; RentalReportUsage: Integer; SourceIsCustomer: Boolean; SourceNo: Code[20]): Boolean
    var
        RecRef: RecordRef;
    begin
        // Blocks the user until the email is sent; use SendEmailInBackground for normal purposes.

        if not RecRef.Get(DocRecordID) then
            exit(false);

        RecRef.LockTable();
        RecRef.Find();
        RecRef.SetRecFilter();

        if SourceIsCustomer then
            exit(SendEmailToCustDirectly("Report Selection Usage".FromInteger(RentalReportUsage), RecRef, DocNo, DocName, false, SourceNo));
    end;

    local procedure RecordsCanBeSent(RecRef: RecordRef): Boolean
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if RecRef.Count > 1 then
            exit(ConfirmManagement.GetResponseOrDefault(OneRecordWillBeSentQst, false));

        exit(true);
    end;

    local procedure GetLastSequenceNo(var TempRentalReportSelectionsSource: Record "TWE Rental Report Selections" temporary; RentalReportUsage: Enum "TWE Rent. Report Sel. Usage"): Code[10]
    var
        rentalReportSelections: Record "TWE Rental Report Selections";
    begin
        rentalReportSelections.SetRange(Usage, RentalReportUsage);
        if rentalReportSelections.FindLast() then;
        if rentalReportSelections.Sequence = '' then
            rentalReportSelections.Sequence := '1';
        exit(rentalReportSelections.Sequence);
    end;

    /// <summary>
    /// IsRentalDocument.
    /// </summary>
    /// <param name="RecordRef">RecordRef.</param>
    /// <returns>Return value of type Boolean.</returns>
    procedure IsRentalDocument(RecordRef: RecordRef): Boolean
    begin
        if RecordRef.Number in
           [DATABASE::"TWE Rental Header", DATABASE::"TWE Rental Shipment Header",
            DATABASE::"TWE Rental Cr.Memo Header", DATABASE::"TWE Rental Invoice Header"]
        then
            exit(true);
        exit(false);
    end;

    local procedure HasReportWithUsage(var TempRentalReportSelectionsSource: Record "TWE Rental Report Selections" temporary; RentalReportUsage: Enum "TWE Rent. Report Sel. Usage"; ReportID: Integer): Boolean
    var
        TempRentalReportSelections: Record "TWE Rental Report Selections" temporary;
    begin
        TempRentalReportSelections.Copy(TempRentalReportSelectionsSource, true);
        TempRentalReportSelections.SetRange(Usage, RentalReportUsage);
        TempRentalReportSelections.SetRange("Report ID", ReportID);
        exit(not TempRentalReportSelections.IsEmpty());
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetCustomReportSelection(var CustomReportSelection: Record "Custom Report Selection"; AccountNo: Code[20]; TableNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSaveReportAsPDF(ReportID: Integer; RecordVariant: Variant; LayoutCode: Code[20]; FilePath: Text[250]; SaveToBlob: Boolean; var TempBlob: Codeunit "Temp Blob")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetCustEmailAddress(BillToCustomerNo: Code[20]; var ToAddress: Text; RentalReportUsage: Option; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetHtmlReport(var DocumentContent: Text; RentalReportUsage: Integer; RecordVariant: Variant; CustNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetEmailAddress(RentalReportUsage: Option; RecordVariant: Variant; var TempBodyRentalReportSelections: Record "TWE Rental Report Selections" temporary; var EmailAddress: Text; var IsHandled: Boolean; CustNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetEmailAddressIgnoringLayout(RentalReportUsage: Enum "TWE Rent. Report Sel. Usage"; RecordVariant: Variant; var TempBodyRentalReportSelections: Record "TWE Rental Report Selections" temporary; CustNo: Code[20]; var EmailAddress: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetCustomReportSelection(var RentalReportSelections: Record "TWE Rental Report Selections"; var CustomReportSelection: Record "Custom Report Selection"; AccountNo: Code[20]; TableNo: Integer; var ReturnValue: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrint(RentalReportUsage: Integer; RecordVariant: Variant; CustomerNoFieldNo: Integer; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintForUsage(var RentalReportUsage: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintWithCheck(RentalReportUsage: Integer; RecordVariant: Variant; CustomerNoFieldNo: Integer; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintWithGUIYesNoWithCheck(RentalReportUsage: Integer; RecordVariant: Variant; IsGUI: Boolean; CustomerNoFieldNo: Integer; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintWithGUIYesNo(RentalReportUsage: Integer; RecordVariant: Variant; IsGUI: Boolean; CustomerNoFieldNo: Integer; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSaveReportAsPDF(var ReportID: Integer; RecordVariant: Variant; var LayoutCode: Code[20]; var IsHandled: Boolean; FilePath: Text[250]; RentalReportUsage: Enum "TWE Rent. Report Sel. Usage"; SaveToBlob: Boolean; var TempBlob: Codeunit "Temp Blob")
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnBeforeSetReportLayout(RecordVariant: Variant; RentalReportUsage: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSendEmailToCust(RentalReportUsage: Integer; RecordVariant: Variant; DocNo: Code[20]; DocName: Text[150]; ShowDialog: Boolean; CustNo: Code[20]; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnFindReportSelections(var FilterRentalReportSelections: Record "TWE Rental Report Selections"; var IsHandled: Boolean; var ReturnRentalReportSelections: Record "TWE Rental Report Selections"; AccountNo: Code[20]; TableNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetEmailBodyCustomer(RentalReportUsage: Integer; RecordVariant: Variant; var TempBodyRentalReportSelections: Record "TWE Rental Report Selections" temporary; CustNo: Code[20]; var CustEmailAddress: Text; var EmailBodyText: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetEmailBodyCustomer(var CustomerEmailAddress: Text; ServerEmailBodyFilePath: Text[250]; RecordVariant: Variant; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSendEmailDirectly(RentalReportUsage: Integer; RecordVariant: Variant; var AllEmailsWereSuccessful: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPrintDocument(TempRentalReportSelections: Record "TWE Rental Report Selections" temporary; IsGUI: Boolean; RecVarToPrint: Variant)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPrintDocumentsWithCheckGUIYesNoCommon(RentalReportUsage: Integer; RecVarToPrint: Variant)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintDocument(TempRentalReportSelections: Record "TWE Rental Report Selections" temporary; IsGUI: Boolean; RecVarToPrint: Variant; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSendEmailDirectly(var RentalReportSelections: Record "TWE Rental Report Selections"; RentalReportUsage: Enum "TWE Rent. Report Sel. Usage"; RecordVariant: Variant;
                                                                                                                                        DocNo: Code[20];
                                                                                                                                        DocName: Text[150];
                                                                                                                                        FoundBody: Boolean;
                                                                                                                                        FoundAttachment: Boolean;
                                                                                                                                        ServerEmailBodyFilePath: Text[250]; var DefaultEmailAddress: Text[250]; ShowDialog: Boolean; var TempAttachRentalReportSelections: Record "TWE Rental Report Selections" temporary; var CustomReportSelection: Record "Custom Report Selection"; var AllEmailsWereSuccessful: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyToReportSelectionOnBeforInsertToReportSelections(var RentalReportSelections: Record "TWE Rental Report Selections"; CustomReportSelection: Record "Custom Report Selection")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetEmailAddressOnAfterGetEmailAddressForCust(RentalReportUsage: Enum "TWE Rent. Report Sel. Usage"; RecordVariant: Variant; var TempBodyRentalReportSelections: Record "TWE Rental Report Selections" temporary; var EmailAddress: Text; CustNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetEmailBodyCustomerTextOnAfterNotFindEmailBodyUsage(RentalReportUsage: Integer; RecordVariant: Variant; CustNo: Code[20]; var TempBodyRentalReportSelections: Record "TWE Rental Report Selections" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrintDocumentsOnAfterSelectTempReportSelectionsToPrint(RecordVariant: Variant; var TempRentalReportSelections: Record "TWE Rental Report Selections" temporary; var TempNameValueBuffer: Record "Name/Value Buffer" temporary; var WithCheck: Boolean; RentalReportUsage: Integer; TableNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSendEmailDirectlyOnBeforeSendFiles(RentalReportUsage: Integer; RecordVariant: Variant; var DefaultEmailAddress: Text[250]; var TempAttachRentalReportSelections: Record "TWE Rental Report Selections" temporary; var CustomReportSelection: Record "Custom Report Selection")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSendEmailInBackgroundOnAfterGetJobQueueParameters(var RecRef: RecordRef; var ParamString: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSendEmailToCustOnAfterSetParameterString(var RecRef: RecordRef; var ParameterString: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSaveReportAsHTMLOnBeforeSetTempLayoutSelected(RecordVariant: Variant; RentalReportUsage: Enum "TWE Rent. Report Sel. Usage"; var ReportID: Integer; var LayoutCode: Code[20])
    begin
    end;
}

