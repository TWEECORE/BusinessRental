/// <summary>
/// Page TWE Rental Return Shipment (ID 50018).
/// </summary>
page 50018 "TWE Rental Return Shipment"
{
    Caption = 'Rental Return Shipment';
    PageType = Document;
    PromotedActionCategories = 'New,Process,Report,Print/Send,Shipment';
    RefreshOnActivate = true;
    SourceTable = "TWE Rental Header";
    SourceTableView = WHERE("Document Type" = FILTER("Return Shipment"));

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the number of the record.';
                }
                field("Rented-to Customer Name"; Rec."Rented-to Customer Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Customer';
                    ToolTip = 'Specifies the name of customer at the Rented-to address.';
                }
                group("Rented-to")
                {
                    Caption = 'Rented-to';
                    field("Rented-to Address"; Rec."Rented-to Address")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Address';
                        Importance = Additional;
                        ToolTip = 'Specifies the customer''s Rented-to address.';
                    }
                    field("Rented-to Address 2"; Rec."Rented-to Address 2")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Address 2';
                        Importance = Additional;
                        ToolTip = 'Specifies the customer''s extended Rented-to address.';
                    }
                    field("Rented-to City"; Rec."Rented-to City")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'City';
                        Importance = Additional;
                        ToolTip = 'Specifies the city of the customer on the rental document.';
                    }
                    group(Control15)
                    {
                        ShowCaption = false;
                        Visible = IsSellToCountyVisible;
                        field("Rented-to County"; Rec."Rented-to County")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'County';
                            Importance = Additional;
                            ToolTip = 'Specifies the state, province or county as a part of the address.';
                        }
                    }
                    field("Rented-to Post Code"; Rec."Rented-to Post Code")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Post Code';
                        Importance = Additional;
                        ToolTip = 'Specifies the post code of the customer''s Rented-to address.';
                    }
                    field("Rented-to Country/Region Code"; Rec."Rented-to Country/Region Code")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Country/Region';
                        Importance = Additional;
                        ToolTip = 'Specifies the country/region of the customer on the rental document.';
                    }
                    field("Rented-to Contact No."; Rec."Rented-to Contact No.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Contact No.';
                        Importance = Additional;
                        ToolTip = 'Specifies the contact number.';
                    }
                    field(SellToPhoneNo; SellToContact."Phone No.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Phone No.';
                        Importance = Additional;
                        ExtendedDatatype = PhoneNo;
                        ToolTip = 'Specifies the telephone number of the contact person at the customer''s Rented-to address.';
                    }
                    field(SellToMobilePhoneNo; SellToContact."Mobile Phone No.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Mobile Phone No.';
                        Importance = Additional;
                        ExtendedDatatype = PhoneNo;
                        ToolTip = 'Specifies the mobile telephone number of the contact person at the customer''s Rented-to address.';
                    }
                    field(SellToEmail; SellToContact."E-Mail")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Email';
                        Importance = Additional;
                        ExtendedDatatype = EMail;
                        ToolTip = 'Specifies the email address of the contact person at the customer''s Rented-to address.';
                    }
                }
                field("Rented-to Contact"; Rec."Rented-to Contact")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Contact';
                    ToolTip = 'Specifies the name of the contact at the customer''s Rented-to address.';
                }
                field("No. Printed"; Rec."No. Printed")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies how many times the document has been printed.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the posting date for the entry.';
                }
                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the posting date of the document.';
                }
                field("Requested Delivery Date"; Rec."Requested Delivery Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date that the customer has asked for the contract to be delivered.';
                }
                field("Promised Delivery Date"; Rec."Promised Delivery Date")
                {
                    ApplicationArea = OrderPromising;
                    ToolTip = 'Specifies the date that you have promised to deliver the contract, as a result of the Order Promising function.';
                }
                field("Quote No."; Rec."Quote No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the rental quote document if a quote was used to start the rental process.';
                }
                field("External Document No."; Rec."External Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the number that the customer uses in their own system to refer to this rental document.';
                }
                field("Salesperson Code"; Rec."Salesperson Code")
                {
                    ApplicationArea = Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies a code for the salesperson who normally handles this customer''s account.';
                }
                field("Responsibility Center"; Rec."Responsibility Center")
                {
                    ApplicationArea = Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the code for the responsibility center that serves the customer on this rental document.';
                }
                group("Work Description")
                {
                    Caption = 'Work Description';
                    field(GetWorkDescription; Rec.GetWorkDescription())
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        MultiLine = true;
                        ShowCaption = false;
                        ToolTip = 'Specifies the products or services being offered.';
                    }
                }
            }
            part(RentalReturnShipmLines; "TWE Return Rent. Shpt. Subf.")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Document No." = FIELD("No.");
            }
            group(Shipping)
            {
                Caption = 'Shipping';
                field("Ship-to Code"; Rec."Ship-to Code")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Address Code';
                    Importance = Promoted;
                    ToolTip = 'Specifies the code for the customer''s additional shipment address.';
                }
                field("Ship-to Name"; Rec."Ship-to Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Name';
                    ToolTip = 'Specifies the name of the customer that you delivered the items to.';
                }
                field("Ship-to Address"; Rec."Ship-to Address")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Address';
                    ToolTip = 'Specifies the address that you delivered the items to.';
                }
                field("Ship-to Address 2"; Rec."Ship-to Address 2")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Address 2';
                    ToolTip = 'Specifies the extended address that you delivered the items to.';
                }
                field("Ship-to City"; Rec."Ship-to City")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'City';
                    ToolTip = 'Specifies the city of the customer on the rental document.';
                }
                group(Control21)
                {
                    ShowCaption = false;
                    Visible = IsShipToCountyVisible;
                    field("Ship-to County"; Rec."Ship-to County")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'County';
                        ToolTip = 'Specifies the state, province or county as a part of the address.';
                    }
                }
                field("Ship-to Post Code"; Rec."Ship-to Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Post Code';
                    Importance = Promoted;
                    ToolTip = 'Specifies the post code of the customer''s ship-to address.';
                }
                field("Ship-to Country/Region Code"; Rec."Ship-to Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Country/Region';
                    ToolTip = 'Specifies the customer''s country/region.';
                }
                field("Ship-to Contact"; Rec."Ship-to Contact")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Contact';
                    ToolTip = 'Specifies the name of the person you regularly contact at the address that the items were shipped to.';
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    Importance = Promoted;
                    ToolTip = 'Specifies the location from where inventory items to the customer on the rental document are to be shipped by default.';
                }
            }
            group(Billing)
            {
                Caption = 'Billing';
                field("Bill-to Customer No."; Rec."Bill-to Customer No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Customer No.';
                    Importance = Additional;
                    ToolTip = 'Specifies the number of the customer at the billing address.';
                }
                field("Bill-to Name"; Rec."Bill-to Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Name';
                    ToolTip = 'Specifies the name of the customer that you sent the invoice to.';
                }
                field("Bill-to Address"; Rec."Bill-to Address")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Address';
                    Importance = Additional;
                    ToolTip = 'Specifies the address that you sent the invoice to.';
                }
                field("Bill-to Address 2"; Rec."Bill-to Address 2")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Address 2';
                    Importance = Additional;
                    ToolTip = 'Specifies the extended address that you sent the invoice to.';
                }
                field("Bill-to City"; Rec."Bill-to City")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'City';
                    Importance = Additional;
                    ToolTip = 'Specifies the city of the customer on the rental document.';
                }
                group(Control29)
                {
                    ShowCaption = false;
                    Visible = IsBillToCountyVisible;
                    field("Bill-to County"; Rec."Bill-to County")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'County';
                        Importance = Additional;
                        ToolTip = 'Specifies the state, province or county as a part of the address.';
                    }
                }
                field("Bill-to Post Code"; Rec."Bill-to Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Post Code';
                    Importance = Additional;
                    ToolTip = 'Specifies the post code of the customer''s bill-to address.';
                }
                field("Bill-to Country/Region Code"; Rec."Bill-to Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Country/Region Code';
                    Importance = Additional;
                    ToolTip = 'Specifies the country or region of the address.';
                }
                field("Bill-to Contact No."; Rec."Bill-to Contact No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Contact No.';
                    Importance = Additional;
                    ToolTip = 'Specifies the number of the contact person at the customer''s bill-to address.';
                }
                field(BillToContactPhoneNo; BillToContact."Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Phone No.';
                    Importance = Additional;
                    ExtendedDatatype = PhoneNo;
                    ToolTip = 'Specifies the telephone number of the contact person at the customer''s bill-to address.';
                }
                field(BillToContactMobilePhoneNo; BillToContact."Mobile Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Mobile Phone No.';
                    Importance = Additional;
                    ExtendedDatatype = PhoneNo;
                    ToolTip = 'Specifies the mobile telephone number of the contact person at the customer''s bill-to address.';
                }
                field(BillToContactEmail; BillToContact."E-Mail")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Email';
                    Importance = Additional;
                    ExtendedDatatype = EMail;
                    ToolTip = 'Specifies the email address of the contact at the customer''s bill-to address.';
                }
                field("Bill-to Contact"; Rec."Bill-to Contact")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Contact';
                    ToolTip = 'Specifies the name of the person you regularly contact at the customer to whom you sent the invoice.';
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Return Shipment")
            {
                Caption = '&Return Shipment';
                Image = Shipment;
                action(Statistics)
                {
                    ApplicationArea = Suite;
                    Caption = 'Statistics';
                    Image = Statistics;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedIsBig = true;
                    RunObject = Page "TWE Rent. Ret.-Ship. Stat.";
                    RunPageLink = "No." = FIELD("No.");
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
                }
                action("Co&mments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    Promoted = true;
                    PromotedCategory = Category5;
                    RunObject = Page "TWE Rental Comment Sheet";
                    RunPageLink = "Document Type" = CONST("Return Shipment"),
                                  "No." = FIELD("No."),
                                  "Document Line No." = CONST(0);
                    ToolTip = 'View or add comments for the record.';
                }
                action(Dimensions)
                {
                    AccessByPermission = TableData Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedIsBig = true;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to rental and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        Rec.ShowDocDim();
                    end;
                }
                action(Approvals)
                {
                    AccessByPermission = TableData "Posted Approval Entry" = R;
                    ApplicationArea = Suite;
                    Caption = 'Approvals';
                    Image = Approvals;
                    Promoted = true;
                    PromotedCategory = Category5;
                    ToolTip = 'View a list of the records that are waiting to be approved. For example, you can see who requested the record to be approved, when it was sent, and when it is due to be approved.';

                    trigger OnAction()
                    var
                        RentalApprovalsMgmt: Codeunit "TWE Rental Approvals Mgmt.";
                    begin
                        RentalApprovalsMgmt.ShowPostedApprovalEntries(Rec.RecordId);
                    end;
                }
                /*  action(CertificateOfSupplyDetails)
                 {
                     ApplicationArea = Basic, Suite;
                     Caption = 'Certificate of Supply Details';
                     Image = Certificate;
                     RunObject = Page "Certificates of Supply";
                     RunPageLink = "Document Type" = FILTER("Sales Shipment"),
                                   "Document No." = FIELD("No.");
                     ToolTip = 'View the certificate of supply that you must send to your customer for signature as confirmation of receipt. You must print a certificate of supply if the shipment uses a combination of VAT business posting group and VAT product posting group that have been marked to require a certificate of supply in the VAT Posting Setup window.';
                 }
                 action(PrintCertificateofSupply)
                 {
                     ApplicationArea = Basic, Suite;
                     Caption = 'Print Certificate of Supply';
                     Image = PrintReport;
                     Promoted = false;
                     ToolTip = 'Print the certificate of supply that you must send to your customer for signature as confirmation of receipt.';

                     trigger OnAction()
                     var
                         CertificateOfSupply: Record "Certificate of Supply";
                     begin
                         CertificateOfSupply.SetRange("Document Type", CertificateOfSupply."Document Type"::"Sales Shipment");
                         CertificateOfSupply.SetRange("Document No.", Rec."No.");
                         CertificateOfSupply.Print();
                     end;
                 } */
            }
        }
        area(processing)
        {
            group(Action21)
            {
                Caption = 'Release';
                Image = ReleaseDoc;
                action(Release)
                {
                    ApplicationArea = Suite;
                    Caption = 'Re&lease';
                    Image = ReleaseDoc;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    ShortCutKey = 'Ctrl+F9';
                    ToolTip = 'Release the document to the next stage of processing. When a document is released, it will be included in all availability calculations from the expected receipt date of the items. You must reopen the document before you can make changes to it.';

                    trigger OnAction()
                    var
                        ReleaseRentalDoc: Codeunit "TWE Release Rental Document";
                    begin
                        ReleaseRentalDoc.PerformManualRelease(Rec);
                    end;
                }
                action(Reopen)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Re&open';
                    Enabled = Rec.Status <> Rec.Status::Open;
                    Image = ReOpen;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedOnly = true;
                    ToolTip = 'Reopen the document to change it after it has been approved. Approved documents have the Released status and must be opened before they can be changed.';

                    trigger OnAction()
                    var
                        ReleaseRentalDoc: Codeunit "TWE Release Rental Document";
                    begin
                        ReleaseRentalDoc.PerformManualReopen(Rec);
                    end;
                }
            }
            group("P&osting")
            {
                Caption = 'P&osting';
                Image = Post;
                action(Post)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'P&ost';
                    Ellipsis = true;
                    Image = PostOrder;
                    Promoted = true;
                    PromotedCategory = Category6;
                    PromotedIsBig = true;
                    ShortCutKey = 'F9';
                    ToolTip = 'Finalize the document or journal by posting the amounts and quantities to the related accounts in your company books.';

                    trigger OnAction()
                    begin
                        PostDocument(CODEUNIT::"TWE Rental-Post (Yes/No)");
                    end;
                }
                action(PostAndSend)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Post and Send';
                    Ellipsis = true;
                    Image = PostMail;
                    Promoted = true;
                    PromotedCategory = Category6;
                    ToolTip = 'Finalize and prepare to send the document according to the customer''s sending profile, such as attached to an email. The Send document to window opens first so you can confirm or select a sending profile.';

                    trigger OnAction()
                    begin
                        PostDocument(CODEUNIT::"TWE Rental-Post and Send");
                    end;
                }
            }
            // action("&Print")
            // {
            //     ApplicationArea = Basic, Suite;
            //     Caption = '&Print';
            //     Ellipsis = true;
            //     Image = Print;
            //     Promoted = true;
            //     PromotedCategory = Category4;
            //     ToolTip = 'Print the shipping notice.';

            //     trigger OnAction()
            //     begin
            //         RentalHeader := Rec;
            //         //OnBeforePrintRecords(Rec, RentalReturnShptHeader);
            //         CurrPage.SetSelectionFilter(RentalHeader);
            //         RentalHeader.PrintRecords(true);
            //     end;
            // } 
        }
    }

    trigger OnOpenPage()
    begin
        Rec.SetSecurityFilterOnRespCenter();
        IsBillToCountyVisible := FormatAddress.UseCounty(Rec."Bill-to Country/Region Code");
        IsShipToCountyVisible := FormatAddress.UseCounty(Rec."Ship-to Country/Region Code");
        IsSellToCountyVisible := FormatAddress.UseCounty(Rec."Rented-to Country/Region Code");
    end;

    trigger OnAfterGetRecord()
    begin
        if SellToContact.Get(Rec."Rented-to Contact No.") then;
        if BillToContact.Get(Rec."Bill-to Contact No.") then;
    end;

    var
        SellToContact: Record Contact;
        BillToContact: Record Contact;
        FormatAddress: Codeunit "Format Address";
        OpenPostedRentalReturnShipmentQst: Label 'The return shipment is posted as number %1 and moved to the Posted Return Shipment window.\\Do you want to open the posted return shipment?', Comment = '%1 = posted document number';
        DocumentIsPosted: Boolean;
        DocumentIsScheduledForPosting: Boolean;
        IsBillToCountyVisible: Boolean;
        IsSellToCountyVisible: Boolean;
        IsShipToCountyVisible: Boolean;




    /// <summary>
    /// PostDocument.
    /// </summary>
    /// <param name="PostingCodeunitID">Integer.</param>
    /// <param name="Navigate">Option.</param>
    procedure PostDocument(PostingCodeunitID: Integer)
    var
        RentalHeader: Record "TWE Rental Header";
        InstructionMgt: Codeunit "Instruction Mgt.";
    begin
        Rec.SendToPosting(PostingCodeunitID);

        DocumentIsScheduledForPosting := Rec."Job Queue Status" = Rec."Job Queue Status"::"Scheduled for Posting";
        DocumentIsPosted := (not RentalHeader.Get(Rec."Document Type", Rec."No.")) or DocumentIsScheduledForPosting;
        OnPostOnAfterSetDocumentIsPosted(RentalHeader, DocumentIsScheduledForPosting, DocumentIsPosted);

        CurrPage.Update(false);

        if PostingCodeunitID <> CODEUNIT::"TWE Rental-Post (Yes/No)" then
            exit;

        if InstructionMgt.IsEnabled(InstructionMgt.ShowPostedConfirmationMessageCode()) then
            ShowPostedConfirmationMessage();

        if DocumentIsScheduledForPosting or DocumentIsPosted then
            CurrPage.Close();
    end;



    local procedure ShowPostedConfirmationMessage()
    var
        RentalRtnShipHeader: Record "TWE Rental Return Ship. Header";
        InstructionMgt: Codeunit "Instruction Mgt.";
    begin
        RentalRtnShipHeader.SetRange("No.", Rec."Last Posting No.");
        if RentalRtnShipHeader.FindFirst() then
            if InstructionMgt.ShowConfirm(StrSubstNo(OpenPostedRentalReturnShipmentQst, RentalRtnShipHeader."No."),
                 InstructionMgt.ShowPostedConfirmationMessageCode())
            then
                PAGE.Run(PAGE::"TWE Post. Rental Return Ship.", RentalRtnShipHeader);
    end;


    [IntegrationEvent(false, false)]
    local procedure OnPostOnAfterSetDocumentIsPosted(RentalHeader: Record "TWE Rental Header"; var IsScheduledPosting: Boolean; var DocumentIsPosted: Boolean)
    begin
    end;

}

