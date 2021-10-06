/// <summary>
/// Table TWE Rental Doc. Send. Profile (ID 50006).
/// </summary>
table 50006 "TWE Rental Doc. Send. Profile"
{
    Caption = 'Rental Document Sending Profile';
    LookupPageID = "Document Sending Profiles";

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            DataClassification = CustomerContent;
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
        }
        field(10; Printer; Option)
        {
            Caption = 'Printer';
            DataClassification = CustomerContent;
            OptionCaption = 'No,Yes (Prompt for Settings),Yes (Use Default Settings)';
            OptionMembers = No,"Yes (Prompt for Settings)","Yes (Use Default Settings)";
        }
        field(11; "E-Mail"; Option)
        {
            Caption = 'Email';
            DataClassification = CustomerContent;
            OptionCaption = 'No,Yes (Prompt for Settings),Yes (Use Default Settings)';
            OptionMembers = No,"Yes (Prompt for Settings)","Yes (Use Default Settings)";
        }
        field(12; "E-Mail Attachment"; Enum "Document Sending Profile Attachment Type")
        {
            Caption = 'Email Attachment';
            DataClassification = CustomerContent;
        }
        field(13; "E-Mail Format"; Code[20])
        {
            Caption = 'Email Format';
            DataClassification = CustomerContent;
            TableRelation = "Electronic Document Format".Code;
        }
        field(15; Disk; Option)
        {
            Caption = 'Disk';
            DataClassification = CustomerContent;
            OptionCaption = 'No,PDF,Electronic Document,PDF & Electronic Document';
            OptionMembers = No,PDF,"Electronic Document","PDF & Electronic Document";
        }
        field(16; "Disk Format"; Code[20])
        {
            Caption = 'Disk Format';
            DataClassification = CustomerContent;
            TableRelation = "Electronic Document Format".Code;
        }
        field(20; "Electronic Document"; Option)
        {
            Caption = 'Electronic Document';
            DataClassification = CustomerContent;
            OptionCaption = 'No,Through Document Exchange Service';
            OptionMembers = No,"Through Document Exchange Service";
        }
        field(21; "Electronic Format"; Code[20])
        {
            Caption = 'Electronic Format';
            DataClassification = CustomerContent;
            TableRelation = "Electronic Document Format".Code;
        }
        field(30; Default; Boolean)
        {
            Caption = 'Default';
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                RentalDocumentSendingProfile: Record "TWE Rental Doc. Send. Profile";
            begin
                if (xRec.Default = true) and (Default = false) then
                    Error(CannotRemoveDefaultRuleErr);

                RentalDocumentSendingProfile.SetRange(Default, true);
                RentalDocumentSendingProfile.ModifyAll(Default, false, false);
            end;
        }
        field(50; "Send To"; Option)
        {
            Caption = 'Send To';
            DataClassification = CustomerContent;
            OptionCaption = 'Disk,Email,Print,Electronic Document';
            OptionMembers = Disk,Email,Print,"Electronic Document";
        }
        field(51; Usage; Enum "Document Sending Profile Usage")
        {
            Caption = 'Usage';
            DataClassification = CustomerContent;
        }
        field(52; "One Related Party Selected"; Boolean)
        {
            Caption = 'One Related Party Selected';
            DataClassification = CustomerContent;
            InitValue = true;

            trigger OnValidate()
            begin
                if not "One Related Party Selected" then begin
                    "Electronic Document" := "Electronic Document"::No;
                    "Electronic Format" := '';
                end;
            end;
        }
        field(60; "Combine Email Documents"; Boolean)
        {
            Caption = 'Combine Email Documents';
            DataClassification = CustomerContent;
            InitValue = false;
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        Customer: Record Customer;
    begin
        if Default then
            Error(CannotDeleteDefaultRuleErr);

        Customer.SetRange("Document Sending Profile", Code);
        if Customer.FindFirst() then
            if Confirm(UpdateAssCustomerQst, false, Code) then
                Customer.ModifyAll("Document Sending Profile", '')
            else
                Error(CannotDeleteErr);
    end;

    trigger OnInsert()
    var
        RentalDocumentSendingProfile: Record "TWE Rental Doc. Send. Profile";
    begin
        RentalDocumentSendingProfile.SetRange(Default, true);
        if RentalDocumentSendingProfile.IsEmpty() then
            Default := true;
    end;

    var
        DefaultCodeTxt: Label 'DEFAULT', Comment = 'Translate as we translate default term in local languages';
        DefaultDescriptionTxt: Label 'Default rule used if no other provided';
        RecordAsTextFormatterTxt: Label '%1 ; %2', Comment = '%1 = FieldCaption "Electronic Document",%2 = "Electronic Document"';
        FieldCaptionContentFormatterTxt: Label '%1 (%2)', Comment = '%1=Field Caption (e.g. Email), %2=Field Content (e.g. PDF) so for example ''Email (PDF)''';
        CannotDeleteDefaultRuleErr: Label 'You cannot delete the default rule. Assign other rule to be default first.';
        CannotRemoveDefaultRuleErr: Label 'There must be one default rule in the system. To remove the default property from this rule, assign default to another rule.';
        UpdateAssCustomerQst: Label 'If you delete document sending profile %1, it will also be deleted on customer cards that use the profile.\\Do you want to continue?', Comment = '%1 = Code';
        CannotDeleteErr: Label 'Cannot delete the document sending profile.';
        CannotSendMultipleSalesDocsErr: Label 'You can only send one electronic sales document at a time.';
        ProfileSelectionQst: Label 'Confirm the first profile and use it for all selected documents.,Confirm the profile for each document.,Use the default profile for all selected documents without confimation.', Comment = 'Translation should contain comma separators between variants as ENU value does. No other commas should be there.';
        CustomerProfileSelectionInstrTxt: Label 'Customers on the selected documents might use different document sending profiles. Choose one of the following options: ';
        VendorProfileSelectionInstrTxt: Label 'Vendors on the selected documents might use different document sending profiles. Choose one of the following options: ';
        InvoicesTxt: Label 'Invoices';
        ShipmentsTxt: Label 'Shipments';
        CreditMemosTxt: Label 'Credit Memos';

    /// <summary>
    /// GetDefaultForCustomer.
    /// </summary>
    /// <param name="CustomerNo">Code[20].</param>
    /// <param name="RentalDocumentSendingProfile">VAR Record "TWE Rental Doc. Send. Profile".</param>
    procedure GetDefaultForCustomer(CustomerNo: Code[20]; var RentalDocumentSendingProfile: Record "TWE Rental Doc. Send. Profile")
    var
        Customer: Record Customer;
    begin
        if Customer.Get(CustomerNo) then
            if RentalDocumentSendingProfile.Get(Customer."Document Sending Profile") then
                exit;

        GetDefault(RentalDocumentSendingProfile);
    end;

    local procedure GetDefaultSendingProfileForCustomerFromLookup(CustomerNo: Code[20]; var RentalDocumentSendingProfile: Record "TWE Rental Doc. Send. Profile")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetDefaultSendingProfileForCustomerFromLookup(CustomerNo, RentalDocumentSendingProfile, IsHandled);
        if IsHandled then
            exit;

        GetDefaultForCustomer(CustomerNo, RentalDocumentSendingProfile);
    end;

    /// <summary>
    /// GetDefault.
    /// </summary>
    /// <param name="DefaultRentalDocumentSendingProfile">VAR Record "TWE Rental Doc. Send. Profile".</param>
    procedure GetDefault(var DefaultRentalDocumentSendingProfile: Record "TWE Rental Doc. Send. Profile")
    var
        RentalDocumentSendingProfile: Record "TWE Rental Doc. Send. Profile";
    begin
        RentalDocumentSendingProfile.SetRange(Default, true);
        if not RentalDocumentSendingProfile.FindFirst() then begin
            RentalDocumentSendingProfile.Init();
            RentalDocumentSendingProfile.Validate(Code, DefaultCodeTxt);
            RentalDocumentSendingProfile.Validate(Description, DefaultDescriptionTxt);
            RentalDocumentSendingProfile.Validate("E-Mail", "E-Mail"::"Yes (Prompt for Settings)");
            RentalDocumentSendingProfile.Validate("E-Mail Attachment", "E-Mail Attachment"::PDF);
            RentalDocumentSendingProfile.Validate(Default, true);
            OnGetDefaultOnBeforeDocumentSendingProfileInsert(RentalDocumentSendingProfile);
            RentalDocumentSendingProfile.Insert(true);
        end;

        DefaultRentalDocumentSendingProfile := RentalDocumentSendingProfile;
    end;

    /// <summary>
    /// GetRecordAsText.
    /// </summary>
    /// <returns>Return value of type Text.</returns>
    procedure GetRecordAsText(): Text
    var
        RecordAsText: Text;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetRecordAsText(Rec, RecordAsText, IsHandled);
        if IsHandled then
            exit(RecordAsText);

        RecordAsText := '';

        if ("Electronic Document" <> "Electronic Document"::No) and ("Electronic Format" <> '') then
            RecordAsText := StrSubstNo(
                RecordAsTextFormatterTxt,
                StrSubstNo(FieldCaptionContentFormatterTxt, FieldCaption("Electronic Document"), "Electronic Document"), RecordAsText);

        if "E-Mail" <> "E-Mail"::No then
            RecordAsText := StrSubstNo(
                RecordAsTextFormatterTxt,
                StrSubstNo(FieldCaptionContentFormatterTxt, FieldCaption("E-Mail"), "E-Mail Attachment"), RecordAsText);
        if Printer <> Printer::No then
            RecordAsText := StrSubstNo(RecordAsTextFormatterTxt, FieldCaption(Printer), RecordAsText);

        if Disk <> Disk::No then
            RecordAsText := StrSubstNo(
                RecordAsTextFormatterTxt, StrSubstNo(FieldCaptionContentFormatterTxt, FieldCaption(Disk), Disk), RecordAsText);

        exit(RecordAsText);
    end;

    /// <summary>
    /// WillUserBePrompted.
    /// </summary>
    /// <returns>Return value of type Boolean.</returns>
    procedure WillUserBePrompted(): Boolean
    begin
        exit(
          (Printer = Printer::"Yes (Prompt for Settings)") or
          ("E-Mail" = "E-Mail"::"Yes (Prompt for Settings)"));
    end;

    /// <summary>
    /// SetDocumentUsage.
    /// </summary>
    /// <param name="DocumentVariant">Variant.</param>
    procedure SetDocumentUsage(DocumentVariant: Variant)
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
        DocumentUsage: Option;
    begin
        ElectronicDocumentFormat.GetDocumentUsage(DocumentUsage, DocumentVariant);
        Validate(Usage, DocumentUsage);
    end;

    /// <summary>
    /// VerifySelectedOptionsValid.
    /// </summary>
    procedure VerifySelectedOptionsValid()
    begin
        if "One Related Party Selected" then
            exit;

        if "E-Mail Attachment" <> "E-Mail Attachment"::PDF then
            Error(CannotSendMultipleSalesDocsErr);

        if "Electronic Document" > "Electronic Document"::No then
            Error(CannotSendMultipleSalesDocsErr);
    end;

    /// <summary>
    /// LookupProfile.
    /// </summary>
    /// <param name="CustNo">Code[20].</param>
    /// <param name="Multiselection">Boolean.</param>
    /// <param name="ShowDialog">Boolean.</param>
    /// <returns>Return value of type Boolean.</returns>
    procedure LookupProfile(CustNo: Code[20]; Multiselection: Boolean; ShowDialog: Boolean): Boolean
    var
        RentalDocumentSendingProfile: Record "TWE Rental Doc. Send. Profile";
        OfficeMgt: Codeunit "Office Management";
    begin
        if OfficeMgt.IsAvailable() then begin
            GetOfficeAddinDefault(Rec, OfficeMgt.AttachAvailable());
            exit(true);
        end;

        GetDefaultSendingProfileForCustomerFromLookup(CustNo, RentalDocumentSendingProfile);
        if ShowDialog then
            exit(RunSelectSendingOptionsPage(RentalDocumentSendingProfile.Code, Multiselection));

        Rec := RentalDocumentSendingProfile;
        exit(true);
    end;

    local procedure RunSelectSendingOptionsPage(DocumentSendingProfileCode: Code[20]; OneRelatedPartySelected: Boolean): Boolean
    var
        TempRentalDocumentSendingProfile: Record "TWE Rental Doc. Send. Profile" temporary;
    begin
        TempRentalDocumentSendingProfile.Init();
        TempRentalDocumentSendingProfile.Code := DocumentSendingProfileCode;
        TempRentalDocumentSendingProfile.Validate("One Related Party Selected", OneRelatedPartySelected);
        TempRentalDocumentSendingProfile.Insert();

        Commit();
        if PAGE.RunModal(PAGE::"Select Sending Options", TempRentalDocumentSendingProfile) = ACTION::LookupOK then begin
            Rec := TempRentalDocumentSendingProfile;
            exit(true);
        end;

        exit(false);
    end;

    /// <summary>
    /// SendCustomerRecords.
    /// </summary>
    /// <param name="ReportUsage">Integer.</param>
    /// <param name="RecordVariant">Variant.</param>
    /// <param name="DocName">Text[150].</param>
    /// <param name="CustomerNo">Code[20].</param>
    /// <param name="DocumentNo">Code[20].</param>
    /// <param name="CustomerFieldNo">Integer.</param>
    /// <param name="DocumentFieldNo">Integer.</param>
    procedure SendCustomerRecords(ReportUsage: Integer; RecordVariant: Variant; DocName: Text[150]; CustomerNo: Code[20]; DocumentNo: Code[20]; CustomerFieldNo: Integer; DocumentFieldNo: Integer)
    var
        RentalDocumentSendingProfile: Record "TWE Rental Doc. Send. Profile";
        RecRefSource: RecordRef;
        RecRefToSend: RecordRef;
        ProfileSelectionMethod: Option ConfirmDefault,ConfirmPerEach,UseDefault;
        SingleCustomerSelected: Boolean;
        ShowDialog: Boolean;
        Handled: Boolean;
    begin
        OnBeforeSendCustomerRecords(ReportUsage, RecordVariant, DocName, CustomerNo, DocumentNo, CustomerFieldNo, DocumentFieldNo, Handled);
        if Handled then
            exit;

        SingleCustomerSelected := IsSingleRecordSelected(RecordVariant, CustomerNo, CustomerFieldNo);

        if not CheckShowProfileSelectionMethodDialog(SingleCustomerSelected, ProfileSelectionMethod, CustomerNo, true) then
            exit;

        if SingleCustomerSelected or (ProfileSelectionMethod = ProfileSelectionMethod::ConfirmDefault) then begin
            OnSendCustomerRecordsOnBeforeLookupProfile(ReportUsage, RecordVariant, CustomerNo, RecRefToSend);
            if RentalDocumentSendingProfile.LookupProfile(CustomerNo, true, true) then
                RentalDocumentSendingProfile.Send(ReportUsage, RecordVariant, DocumentNo, CustomerNo, DocName, CustomerFieldNo, DocumentFieldNo);
        end else begin
            ShowDialog := ProfileSelectionMethod = ProfileSelectionMethod::ConfirmPerEach;
            RecRefSource.GetTable(RecordVariant);
            if RecRefSource.FindSet() then
                repeat
                    RecRefToSend := RecRefSource.Duplicate();
                    RecRefToSend.SetRecFilter();
                    CustomerNo := RecRefToSend.Field(CustomerFieldNo).Value;
                    DocumentNo := RecRefToSend.Field(DocumentFieldNo).Value;
                    OnSendCustomerRecordsOnBeforeLookupProfile(ReportUsage, RecordVariant, CustomerNo, RecRefToSend);
                    if RentalDocumentSendingProfile.LookupProfile(CustomerNo, true, ShowDialog) then
                        RentalDocumentSendingProfile.Send(ReportUsage, RecRefToSend, DocumentNo, CustomerNo, DocName, CustomerFieldNo, DocumentFieldNo);
                until RecRefSource.Next() = 0;
        end;

        OnAfterSendCustomerRecords(ReportUsage, RecordVariant, DocName, CustomerNo, DocumentNo, CustomerFieldNo, DocumentFieldNo);
    end;

    local procedure CheckShowProfileSelectionMethodDialog(SingleRecordSelected: Boolean; var ProfileSelectionMethod: Option ConfirmDefault,ConfirmPerEach,UseDefault; AccountNo: Code[20]; IsCustomer: Boolean) Result: Boolean
    var
        RentalDocumentSendingProfile: Record "TWE Rental Doc. Send. Profile";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckShowProfileSelectionMethodDialog(ProfileSelectionMethod, AccountNo, IsCustomer, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if not SingleRecordSelected then
            if not RentalDocumentSendingProfile.ProfileSelectionMethodDialog(ProfileSelectionMethod, IsCustomer) then
                exit(false);
        exit(true);
    end;

    procedure Send(ReportUsage: Integer; RecordVariant: Variant; DocNo: Code[20]; ToCust: Code[20]; DocName: Text[150]; CustomerFieldNo: Integer; DocumentNoFieldNo: Integer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSend(ReportUsage, RecordVariant, DocNo, ToCust, DocName, CustomerFieldNo, DocumentNoFieldNo, IsHandled);
        if IsHandled then
            exit;

        //SendToVAN(RecordVariant);
        SendToPrinter("Report Selection Usage".FromInteger(ReportUsage), RecordVariant, CustomerFieldNo);
        TrySendToEMailGroupedMultipleSelection(
            "Report Selection Usage".FromInteger(ReportUsage), RecordVariant, DocumentNoFieldNo, DocName, CustomerFieldNo, true);
        SendToDisk("Report Selection Usage".FromInteger(ReportUsage), RecordVariant, DocNo, DocName, ToCust);

        OnAfterSend(ReportUsage, RecordVariant, DocNo, ToCust, DocName, CustomerFieldNo, DocumentNoFieldNo);
    end;

    /// <summary>
    /// TrySendToVAN.
    /// </summary>
    /// <param name="RecordVariant">Variant.</param>
    [Scope('OnPrem')]
    procedure TrySendToVAN(RecordVariant: Variant)
    begin
        "Electronic Document" := "Electronic Document"::"Through Document Exchange Service";
        // SendToVAN(RecordVariant);
    end;

    /// <summary>
    /// TrySendToPrinter.
    /// </summary>
    /// <param name="ReportUsage">Integer.</param>
    /// <param name="RecordVariant">Variant.</param>
    /// <param name="CustomerFieldNo">Integer.</param>
    /// <param name="ShowDialog">Boolean.</param>
    procedure TrySendToPrinter(ReportUsage: Integer; RecordVariant: Variant; CustomerFieldNo: Integer; ShowDialog: Boolean)
    var
        Handled: Boolean;
    begin
        OnBeforeTrySendToPrinter(ReportUsage, RecordVariant, CustomerFieldNo, ShowDialog, Handled);
        if Handled then
            exit;

        if ShowDialog then
            Printer := Printer::"Yes (Prompt for Settings)"
        else
            Printer := Printer::"Yes (Use Default Settings)";

        SendToPrinter("TWE Rent. Report Sel. Usage".FromInteger(ReportUsage), RecordVariant, CustomerFieldNo);
    end;

    /// <summary>
    /// TrySendToEMail.
    /// </summary>
    /// <param name="ReportUsage">Integer.</param>
    /// <param name="RecordVariant">Variant.</param>
    /// <param name="DocumentNoFieldNo">Integer.</param>
    /// <param name="DocName">Text[150].</param>
    /// <param name="CustomerFieldNo">Integer.</param>
    /// <param name="ShowDialog">Boolean.</param>
    procedure TrySendToEMail(ReportUsage: Integer; RecordVariant: Variant; DocumentNoFieldNo: Integer; DocName: Text[150]; CustomerFieldNo: Integer; ShowDialog: Boolean)
    var
        Handled: Boolean;
    begin
        OnBeforeTrySendToEMail(ReportUsage, RecordVariant, DocumentNoFieldNo, DocName, CustomerFieldNo, ShowDialog, Handled);
        if Handled then
            exit;

        if ShowDialog then
            "E-Mail" := "E-Mail"::"Yes (Prompt for Settings)"
        else
            "E-Mail" := "E-Mail"::"Yes (Use Default Settings)";

        "E-Mail Attachment" := "E-Mail Attachment"::PDF;

        TrySendToEMailGroupedMultipleSelection(
            "TWE Rent. Report Sel. Usage".FromInteger(ReportUsage), RecordVariant, DocumentNoFieldNo, DocName, CustomerFieldNo, true);
    end;

    local procedure TrySendToEMailGroupedMultipleSelection(ReportUsage: Enum "TWE Rent. Report Sel. Usage"; RecordVariant: Variant; DocumentNoFieldNo: Integer; DocName: Text[150]; CustomerVendorFieldNo: Integer; IsCustomer: Boolean)
    var
        RecRef: RecordRef;
        RecToSend: RecordRef;
        CustomerNoFieldRef: FieldRef;
        RecToSendCombine: Variant;
        CustomerVendorNos: Dictionary of [Code[20], Code[20]];
        CustomerVendorNo: Code[20];
        DocumentNo: Code[20];
    begin
        RecRef.GetTable(RecordVariant);

        if Rec."Combine Email Documents" then begin
            GetDistinctCustomerVendor(RecRef, CustomerVendorFieldNo, CustomerVendorNos);

            RecToSendCombine := RecordVariant;
            CustomerNoFieldRef := RecRef.Field(CustomerVendorFieldNo);
            foreach CustomerVendorNo in CustomerVendorNos.Keys() do begin
                CustomerNoFieldRef.SetRange(CustomerVendorNo);
                RecRef.FindFirst();
                RecRef.SetTable(RecToSendCombine);

                DocumentNo := GetMultipleDocumentsNo(RecRef, DocumentNoFieldNo);
                DocName := GetMultipleDocumentsName(DocName, ReportUsage, RecRef);
                if IsCustomer then
                    SendToEMail(ReportUsage, RecToSendCombine, DocumentNo, DocName, CustomerVendorNo);
            end;
        end
        else
            if RecRef.FindSet() then
                repeat
                    RecToSend := RecRef.Duplicate();
                    RecToSend.SetRecFilter();
                    CustomerVendorNo := RecToSend.Field(CustomerVendorFieldNo).Value;
                    DocumentNo := RecToSend.Field(DocumentNoFieldNo).Value;
                    if IsCustomer then
                        SendToEMail(ReportUsage, RecToSend, DocumentNo, DocName, CustomerVendorNo);
                until RecRef.Next() = 0;
    end;

    local procedure GetMultipleDocumentsNo(RecRef: RecordRef; DocumentNoFieldNo: Integer): Code[20]
    var
        DocumentNoFieldRef: FieldRef;
    begin
        if RecRef.Count > 1 then
            exit('');

        DocumentNoFieldRef := RecRef.Field(DocumentNoFieldNo);
        exit(DocumentNoFieldRef.Value);
    end;

    local procedure GetMultipleDocumentsName(DocName: Text[150]; ReportUsage: Enum "TWE Rent. Report Sel. Usage"; RecRef: RecordRef): Text[150]
    var
        RentalReportSelections: Record "TWE Rental Report Selections";
    begin
        if RecRef.Count > 1 then
            case ReportUsage of
                RentalReportSelections.Usage::"R.Invoice":
                    exit(InvoicesTxt);
                RentalReportSelections.Usage::"R.Shipment":
                    exit(ShipmentsTxt);
                RentalReportSelections.Usage::"R.Cr.Memo":
                    exit(CreditMemosTxt);
                else begin
                        OnGetDocumentName(ReportUsage, DocName);
                        exit(DocName);
                    end;
            end;

        exit(DocName);
    end;

    local procedure GetDistinctCustomerVendor(RecRef: RecordRef; CustomerVendorFieldNo: Integer; var CustomerVendorNos: Dictionary of [Code[20], Code[20]])
    var
        FieldRef: FieldRef;
        CustomerNo: Code[20];
    begin
        if RecRef.FindSet() then
            repeat
                FieldRef := RecRef.Field(CustomerVendorFieldNo);
                CustomerNo := FieldRef.Value;
                if CustomerVendorNos.Add(CustomerNo, CustomerNo) then;
            until RecRef.Next() = 0;
    end;

    /// <summary>
    /// TrySendToDisk.
    /// </summary>
    /// <param name="ReportUsage">Integer.</param>
    /// <param name="RecordVariant">Variant.</param>
    /// <param name="DocNo">Code[20].</param>
    /// <param name="DocName">Text[150].</param>
    /// <param name="ToCust">Code[20].</param>
    [Scope('OnPrem')]
    procedure TrySendToDisk(ReportUsage: Integer; RecordVariant: Variant; DocNo: Code[20]; DocName: Text[150]; ToCust: Code[20])
    begin
        Disk := Disk::PDF;
        SendToDisk("TWE Rent. Report Sel. Usage".FromInteger(ReportUsage), RecordVariant, DocNo, DocName, ToCust);
    end;

    /*   local procedure SendToVAN(RecordVariant: Variant)
      var
          ReportDistributionManagement: Codeunit "Report Distribution Management";
      begin
          if "Electronic Document" = "Electronic Document"::No then
              exit;

          //ReportDistributionManagement.VANDocumentReport(RecordVariant, Rec);
      end; */

    local procedure SendToPrinter(ReportUsage: Enum "TWE Rent. Report Sel. Usage"; RecordVariant: Variant; CustomerNoFieldNo: Integer)
    var
        RentalReportSelections: Record "TWE Rental Report Selections";
        ShowRequestForm: Boolean;
    begin
        if Printer = Printer::No then
            exit;

        ShowRequestForm := Printer = Printer::"Yes (Prompt for Settings)";
        RentalReportSelections.PrintWithDialogForCust(ReportUsage, RecordVariant, ShowRequestForm, CustomerNoFieldNo);
    end;

    local procedure SendToEMail(ReportUsage: Enum "TWE Rent. Report Sel. Usage"; RecordVariant: Variant; DocNo: Code[20]; DocName: Text[150]; ToCust: Code[20])
    var
        RentalReportSelections: Record "TWE Rental Report Selections";
        //ElectronicDocumentFormat: Record "Electronic Document Format";
        //ReportDistributionManagement: Codeunit "Report Distribution Management";
        //DocumentMailing: Codeunit "Document-Mailing";
        DataCompression: Codeunit "Data Compression";
        ShowDialog: Boolean;
        //ClientFilePath: Text[250];
        //ServerFilePath: Text[250];
        //ZipPath: Text[250];
        //ClientZipFileName: Text[250];
        ServerEmailBodyFilePath: Text[250];
        SendToEmailAddress: Text;
    begin
        if "E-Mail" = "E-Mail"::No then
            exit;

        ShowDialog := "E-Mail" = "E-Mail"::"Yes (Prompt for Settings)";

        case "E-Mail Attachment" of
            "E-Mail Attachment"::PDF:
                RentalReportSelections.SendEmailToCust(ReportUsage.AsInteger(), RecordVariant, DocNo, DocName, ShowDialog, ToCust);
            "E-Mail Attachment"::"Electronic Document":
                //begin
                RentalReportSelections.GetEmailBodyForCust(ServerEmailBodyFilePath, ReportUsage, RecordVariant, ToCust, SendToEmailAddress);
            //ReportDistributionManagement.SendXmlEmailAttachment(
            //                      RecordVariant, "E-Mail Format", ServerEmailBodyFilePath, SendToEmailAddress);
            //end;
            "E-Mail Attachment"::"PDF & Electronic Document":
                begin
                    //                  ElectronicDocumentFormat.SendElectronically(ServerFilePath, ClientFilePath, RecordVariant, "E-Mail Format");
                    //                ReportDistributionManagement.CreateOrAppendZipFile(DataCompression, ServerFilePath, ClientFilePath, ClientZipFileName);
                    RentalReportSelections.SendToZipForCust(ReportUsage, RecordVariant, DocNo, ToCust, DataCompression);
                    // SaveZipArchiveToServerFile(DataCompression, ZipPath);

                    RentalReportSelections.GetEmailBodyForCust(ServerEmailBodyFilePath, ReportUsage, RecordVariant, ToCust, SendToEmailAddress);
                    // DocumentMailing.EmailFile(
                    //   ZipPath, ClientZipFileName, ServerEmailBodyFilePath, DocNo, SendToEmailAddress, DocName,
                    //   not ShowDialog, ReportUsage.AsInteger());
                end;
        end;
    end;

    local procedure SendToDisk(RentalReportUsage: Enum "TWE Rent. Report Sel. Usage"; RecordVariant: Variant; DocNo: Code[20]; DocName: Text; ToCust: Code[20])
    var
        //  RentalReportSelections: Record "TWE Rental Report Selections";
        //ElectronicDocumentFormat: Record "Electronic Document Format";
        //ReportDistributionManagement: Codeunit "Report Distribution Management";
        //DataCompression: Codeunit "Data Compression";
        //ServerFilePath: Text[250];
        //ClientFilePath: Text[250];
        //ZipPath: Text[250];
        //ClientZipFileName: Text[250];
        IsHandled: Boolean;
    begin
        if Disk = Disk::No then
            exit;

        OnBeforeSendToDisk(RentalReportUsage.AsInteger(), RecordVariant, DocNo, DocName, ToCust, IsHandled);
        if IsHandled then
            exit;

        /* case Disk of
            Disk::PDF:
                RentalReportSelections.SendToDiskForCust(RentalReportUsage, RecordVariant, DocNo, DocName, ToCust);
            Disk::"Electronic Document":
                begin
                    ElectronicDocumentFormat.SendElectronically(ServerFilePath, ClientFilePath, RecordVariant, "Disk Format");
                    ReportDistributionManagement.SaveFileOnClient(ServerFilePath, ClientFilePath);
                end;
            Disk::"PDF & Electronic Document":
                begin
                    ElectronicDocumentFormat.SendElectronically(ServerFilePath, ClientFilePath, RecordVariant, "Disk Format");
                    ReportDistributionManagement.CreateOrAppendZipFile(DataCompression, ServerFilePath, ClientFilePath, ClientZipFileName);
                    RentalReportSelections.SendToZipForCust(RentalReportUsage, RecordVariant, DocNo, ToCust, DataCompression);
                    SaveZipArchiveToServerFile(DataCompression, ZipPath);

                    ReportDistributionManagement.SaveFileOnClient(ZipPath, ClientZipFileName);
                end;
        end; */
    end;

    /// <summary>
    /// GetOfficeAddinDefault.
    /// </summary>
    /// <param name="TempRentalDocumentSendingProfile">Temporary VAR Record "TWE Rental Doc. Send. Profile".</param>
    /// <param name="CanAttach">Boolean.</param>
    procedure GetOfficeAddinDefault(var TempRentalDocumentSendingProfile: Record "TWE Rental Doc. Send. Profile" temporary; CanAttach: Boolean)
    begin
        TempRentalDocumentSendingProfile.Init();
        TempRentalDocumentSendingProfile.Code := DefaultCodeTxt;
        TempRentalDocumentSendingProfile.Description := DefaultDescriptionTxt;
        if CanAttach then
            TempRentalDocumentSendingProfile."E-Mail" := TempRentalDocumentSendingProfile."E-Mail"::"Yes (Use Default Settings)"
        else
            TempRentalDocumentSendingProfile."E-Mail" := TempRentalDocumentSendingProfile."E-Mail"::"Yes (Prompt for Settings)";
        TempRentalDocumentSendingProfile."E-Mail Attachment" := TempRentalDocumentSendingProfile."E-Mail Attachment"::PDF;
        Default := false;
    end;

    /// <summary>
    /// ProfileSelectionMethodDialog.
    /// </summary>
    /// <param name="ProfileSelectionMethod">VAR Option ConfirmDefault,ConfirmPerEach,UseDefault.</param>
    /// <param name="IsCustomer">Boolean.</param>
    /// <returns>Return value of type Boolean.</returns>
    procedure ProfileSelectionMethodDialog(var ProfileSelectionMethod: Option ConfirmDefault,ConfirmPerEach,UseDefault; IsCustomer: Boolean): Boolean
    var
        ProfileSelectionInstruction: Text;
    begin
        if IsCustomer then
            ProfileSelectionInstruction := CustomerProfileSelectionInstrTxt
        else
            ProfileSelectionInstruction := VendorProfileSelectionInstrTxt;

        case StrMenu(ProfileSelectionQst, 3, ProfileSelectionInstruction) of
            0:
                exit(false);
            1:
                ProfileSelectionMethod := ProfileSelectionMethod::ConfirmDefault;
            2:
                ProfileSelectionMethod := ProfileSelectionMethod::ConfirmPerEach;
            3:
                ProfileSelectionMethod := ProfileSelectionMethod::UseDefault;
        end;
        exit(true);
    end;

    local procedure IsSingleRecordSelected(RecordVariant: Variant; CVNo: Code[20]; CVFieldNo: Integer): Boolean
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecRef.GetTable(RecordVariant);
        if not RecRef.FindSet() then
            exit(false);

        if RecRef.Next() = 0 then
            exit(true);

        FieldRef := RecRef.Field(CVFieldNo);
        FieldRef.SetFilter('<>%1', CVNo);
        exit(RecRef.IsEmpty);
    end;

    /// <summary>
    /// CheckElectronicSendingEnabled.
    /// </summary>
    procedure CheckElectronicSendingEnabled()
    var
        DocExchServiceMgt: Codeunit "Doc. Exch. Service Mgt.";
    begin
        if "Electronic Document" <> "Electronic Document"::No then
            if not HasThirdPartyDocExchService() then
                DocExchServiceMgt.CheckServiceEnabled();
    end;

    local procedure HasThirdPartyDocExchService() ExchServiceEnabled: Boolean
    begin
        OnCheckElectronicSendingEnabled(ExchServiceEnabled);
    end;

    /* local procedure SaveZipArchiveToServerFile(var DataCompression: Codeunit "Data Compression"; var ZipPath: Text)
    var
        FileManagement: Codeunit "File Management";
        ZipFile: File;
        ZipFileOutStream: OutStream;
    begin
        ZipPath := CopyStr(FileManagement.ServerTempFileName('zip'), 1, 250);
        ZipFile.Create(ZipPath);
        ZipFile.CreateOutStream(ZipFileOutStream);
        DataCompression.SaveZipArchive(ZipFileOutStream);
        DataCompression.CloseZipArchive;
        ZipFile.Close();
    end; */

    [IntegrationEvent(TRUE, false)]
    local procedure OnAfterSend(ReportUsage: Integer; RecordVariant: Variant; DocNo: Code[20]; ToCust: Code[20]; DocName: Text[150]; CustomerFieldNo: Integer; DocumentNoFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSendCustomerRecords(ReportUsage: Integer; RecordVariant: Variant; DocName: Text[150]; CustomerNo: Code[20]; DocumentNo: Code[20]; CustomerFieldNo: Integer; DocumentFieldNo: Integer);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckShowProfileSelectionMethodDialog(var ProfileSelectionMethod: Option ConfirmDefault,ConfirmPerEach,UseDefault; AccountNo: Code[20]; IsCustomer: Boolean; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetDefaultSendingProfileForCustomerFromLookup(CustomerNo: Code[20]; var RentalDocumentSendingProfile: Record "TWE Rental Doc. Send. Profile"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetRecordAsText(RentalDocumentSendingProfile: Record "TWE Rental Doc. Send. Profile"; var RecordAsText: Text; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnBeforeSend(ReportUsage: Integer; RecordVariant: Variant; DocNo: Code[20]; ToCust: Code[20]; DocName: Text[150]; CustomerFieldNo: Integer; DocumentNoFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSendCustomerRecords(ReportUsage: Integer; RecordVariant: Variant; DocName: Text[150]; CustomerNo: Code[20]; DocumentNo: Code[20]; CustomerFieldNo: Integer; DocumentFieldNo: Integer; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeSendToDisk(ReportUsage: Integer; RecordVariant: Variant; DocNo: Code[20]; DocName: Text; ToCust: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTrySendToPrinter(ReportUsage: Integer; RecordVariant: Variant; CustomerFieldNo: Integer; ShowDialog: Boolean; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTrySendToEMail(ReportUsage: Integer; RecordVariant: Variant; DocumentNoFieldNo: Integer; DocName: Text[150]; CustomerFieldNo: Integer; ShowDialog: Boolean; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckElectronicSendingEnabled(var ExchServiceEnabled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetDocumentName(ReportUsage: Enum "TWE Rent. Report Sel. Usage"; var DocumentName: Text[150])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetDefaultOnBeforeDocumentSendingProfileInsert(var RentalDocumentSendingProfile: Record "TWE Rental Doc. Send. Profile")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSendCustomerRecordsOnBeforeLookupProfile(ReportUsage: Integer; RecordVariant: Variant; CustomerNo: Code[20]; var RecRefToSend: RecordRef)
    begin
    end;

}

