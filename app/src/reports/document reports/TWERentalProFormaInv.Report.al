/// <summary>
/// Report TWE Rental - Pro Forma Inv (ID 50005).
/// </summary>
report 50005 "TWE Rental - Pro Forma Inv"
{
    DefaultLayout = RDLC;
    RDLCLayout = 'StandardRentalProFormaInv.rdlc';
    //WordLayout = 'StandardRentalProFormaInv.docx';
    Caption = 'Pro Forma Invoice';

    dataset
    {
        dataitem(Header; "TWE Rental Header")
        {
            DataItemTableView = SORTING("Document Type", "No.");
            RequestFilterFields = "No.", "Rented-to Customer No.", "No. Printed";
            RequestFilterHeading = 'Pro Forma Invoice';
            column(DocumentDate; Format("Document Date", 0, 4))
            {
            }
            column(CompanyPicture; CompanyInformation.Picture)
            {
            }
            column(CompanyEMail; CompanyInformation."E-Mail")
            {
            }
            column(CompanyHomePage; CompanyInformation."Home Page")
            {
            }
            column(CompanyPhoneNo; CompanyInformation."Phone No.")
            {
            }
            column(CompanyVATRegNo; CompanyInformation.GetVATRegistrationNumber())
            {
            }
            column(AddressLine; GetAddressLine(CompanyInformation))
            {
            }
            column(CompanyAddress1; CompanyAddress[1])
            {
            }
            column(CompanyAddress2; CompanyAddress[2])
            {
            }
            column(CompanyAddress3; CompanyAddress[3])
            {
            }
            column(CompanyAddress4; CompanyAddress[4])
            {
            }
            column(CompanyAddress5; CompanyAddress[5])
            {
            }
            column(CompanyAddress6; CompanyAddress[6])
            {
            }
            column(CustomerAddress1; CustomerAddress[1])
            {
            }
            column(CustomerAddress2; CustomerAddress[2])
            {
            }
            column(CustomerAddress3; CustomerAddress[3])
            {
            }
            column(CustomerAddress4; CustomerAddress[4])
            {
            }
            column(CustomerAddress5; CustomerAddress[5])
            {
            }
            column(CustomerAddress6; CustomerAddress[6])
            {
            }
            column(CustomerAddress7; CustomerAddress[7])
            {
            }
            column(CustomerAddress8; CustomerAddress[8])
            {
            }
            column(SellToContactPhoneNoLbl; SellToContactPhoneNoLbl)
            {
            }
            column(SellToContactMobilePhoneNoLbl; SellToContactMobilePhoneNoLbl)
            {
            }
            column(SellToContactEmailLbl; SellToContactEmailLbl)
            {
            }
            column(BillToContactPhoneNoLbl; BillToContactPhoneNoLbl)
            {
            }
            column(BillToContactMobilePhoneNoLbl; BillToContactMobilePhoneNoLbl)
            {
            }
            column(BillToContactEmailLbl; BillToContactEmailLbl)
            {
            }
            column(SellToContactPhoneNo; RentedToContact."Phone No.")
            {
            }
            column(SellToContactMobilePhoneNo; RentedToContact."Mobile Phone No.")
            {
            }
            column(SellToContactEmail; RentedToContact."E-Mail")
            {
            }
            column(BillToContactPhoneNo; BillToContact."Phone No.")
            {
            }
            column(BillToContactMobilePhoneNo; BillToContact."Mobile Phone No.")
            {
            }
            column(BillToContactEmail; BillToContact."E-Mail")
            {
            }
            column(YourReference; "Your Reference")
            {
            }
            column(ExternalDocumentNo; "External Document No.")
            {
            }
            column(DocumentNo; "No.")
            {
            }
            column(CompanyLegalOffice; CompanyInformation.GetLegalOffice())
            {
            }
            column(SalesPersonName; SalespersonPurchaserName)
            {
            }
            column(ShipmentMethodDescription; ShipmentMethodDescription)
            {
            }
            column(Currency; CurrencyCode)
            {
            }
            column(CustomerVATRegNo; GetCustomerVATRegistrationNumber())
            {
            }
            column(CustomerVATRegistrationNoLbl; YourVATRegistrationNo_Lbl)
            {
            }
            column(PageLbl; PageLbl)
            {
            }
            column(DocumentTitleLbl; DocumentCaption())
            {
            }
            column(YourReferenceLbl; FieldCaption("Your Reference"))
            {
            }
            column(ExternalDocumentNoLbl; FieldCaption("External Document No."))
            {
            }
            column(CompanyLegalOfficeLbl; CompanyInformation.GetLegalOfficeLbl())
            {
            }
            column(SalesPersonLbl; SalesPersonLblText)
            {
            }
            column(EMailLbl; EMailLbl)
            {
            }
            column(HomePageLbl; HomePageLbl)
            {
            }
            column(CompanyPhoneNoLbl; PhoneNoLbl)
            {
            }
            column(ShipmentMethodDescriptionLbl; DummyShipmentMethod.TableCaption)
            {
            }
            column(CurrencyLbl; DummyCurrency.TableCaption)
            {
            }
            column(ItemLbl; MainRentalItem.TableCaption)
            {
            }
            column(UnitPriceLbl; MainRentalItem.FieldCaption("Unit Price"))
            {
            }
            column(CountryOfManufactuctureLbl; CountryOfManufactuctureLbl)
            {
            }
            column(AmountLbl; Line.FieldCaption(Amount))
            {
            }
            column(VATPctLbl; Line.FieldCaption("VAT %"))
            {
            }
            column(VATAmountLbl; DummyVATAmountLine.VATAmountText())
            {
            }
            column(TotalWeightLbl; TotalWeightLbl)
            {
            }
            column(TotalAmountLbl; TotalAmountLbl)
            {
            }
            column(TotalAmountInclVATLbl; TotalAmountInclVATLbl)
            {
            }
            column(QuantityLbl; Line.FieldCaption(Quantity))
            {
            }
            column(DeclartionLbl; DeclartionLbl)
            {
            }
            column(SignatureLbl; SignatureLbl)
            {
            }
            column(SignatureNameLbl; SignatureNameLbl)
            {
            }
            column(SignaturePositionLbl; SignaturePositionLbl)
            {
            }
            column(VATRegNoLbl; CompanyInformation.GetVATRegistrationNumberLbl())
            {
            }
            column(YourCustomerNo_Lbl; YourCustomerNo_Lbl)
            {
            }
            column(Rental_Start; "Rental Start")
            {
            }
            column(Rental_End; "Rental End")
            {
            }
            column(Rental_Rate_Code; "Rental Rate Code")
            {
            }
            column(Invoicing_Period; "Invoicing Period")
            {
            }
            column(RentalStart_Lbl; RentalStart_Lbl)
            {
            }
            column(RentalEnd_Lbl; RentalEnd_Lbl)
            {
            }
            column(RentalRateCode_Lbl; RentalRateCode_Lbl)
            {
            }
            column(RentalInvPeriod_Lbl; RentalInvPeriod_Lbl)
            {
            }
            column(RentedtoCustomerNo; "Rented-to Customer No.")
            {
            }
            column(CompanyBankName_Lbl; BankNameLbl)
            {
            }
            column(CompanyBankName; CompanyInformation."Bank Name")
            {
            }
            column(CompanyIBAN; CompanyInformation.IBAN)
            {
            }
            column(CompanyIBAN_Lbl; IBANLbl)
            {
            }
            column(CompanyBankBranchNo; CompanyInformation."Bank Branch No.")
            {
            }
            column(CompanyBankBranchNo_Lbl; BankBranchNoLbl)
            {
            }
            column(CompanySWIFT; CompanyInformation."SWIFT Code")
            {
            }
            column(CompanySWIFT_Lbl; SWIFTLbl)
            {
            }
            column(Page_Lbl; PageLbl)
            {
            }
            dataitem(Line; "TWE Rental Line")
            {
                DataItemLink = "Document Type" = FIELD("Document Type"), "Document No." = FIELD("No.");
                DataItemLinkReference = Header;
                DataItemTableView = SORTING("Document No.", "Line No.");

                column(ItemNo_; "No.")
                {
                }
                column(ItemNoLbl; ItemNoLbl)
                {
                }
                column(Rental_Item_No; "Rental Item")
                {
                }
                column(Rental_Item_Lbl; Line.FieldCaption("Rental Item"))
                {
                }
                column(ItemDescription; Description)
                {
                }
                column(ItemDescriptionLbl; Line.FieldCaption(Description))
                {
                }
                column(Quantity; "Qty. to Invoice")
                {
                }
                column(Price; FormattedLinePrice)
                {
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 2;
                }
                column(LineAmount; FormattedLineAmount)
                {
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 1;
                }
                column(VATPct; "VAT %")
                {
                }
                column(VATAmount; FormattedVATAmount)
                {
                }

                trigger OnAfterGetRecord()
                var
                    AutoFormatType: Enum "Auto Format";
                begin
                    MainRentalItem.Get("No.");
                    OnBeforeLineOnAfterGetRecord(Header, Line);

                    if Quantity = 0 then begin
                        LinePrice := "Unit Price";
                        LineAmount := 0;
                        VATAmount := 0;
                    end else begin
                        LinePrice := Round(Amount / Quantity, Currency."Unit-Amount Rounding Precision");
                        LineAmount := Round(Amount * "Qty. to Invoice" / Quantity, Currency."Amount Rounding Precision");
                        VATAmount := Round(
                            Amount * "VAT %" / 100 * "Qty. to Invoice" / Quantity, Currency."Amount Rounding Precision");

                        TotalAmount += LineAmount;
                        TotalVATAmount += VATAmount;
                        TotalAmountInclVAT += Round("Amount Including VAT" * "Qty. to Invoice" / Quantity, Currency."Amount Rounding Precision");
                    end;

                    FormattedLinePrice := Format(LinePrice, 0, AutoFormat.ResolveAutoFormat(AutoFormatType::UnitAmountFormat, CurrencyCode));
                    FormattedLineAmount := Format(LineAmount, 0, AutoFormat.ResolveAutoFormat(AutoFormatType::AmountFormat, CurrencyCode));
                    FormattedVATAmount := Format(VATAmount, 0, AutoFormat.ResolveAutoFormat(AutoFormatType::AmountFormat, CurrencyCode));
                end;

                trigger OnPreDataItem()
                begin
                    TotalWeight := 0;
                    TotalAmount := 0;
                    TotalVATAmount := 0;
                    TotalAmountInclVAT := 0;
                    SetRange(Type, Type::"Rental Item");

                    OnAfterLineOnPreDataItem(Header, Line);
                end;
            }
            dataitem(Totals; "Integer")
            {
                MaxIteration = 1;
                column(TotalWeight; TotalWeight)
                {
                }
                column(TotalValue; FormattedTotalAmount)
                {
                }
                column(TotalVATAmount; FormattedTotalVATAmount)
                {
                }
                column(TotalAmountInclVAT; FormattedTotalAmountInclVAT)
                {
                }

                trigger OnPreDataItem()
                var
                    AutoFormatType: Enum "Auto Format";
                begin
                    FormattedTotalAmount := Format(TotalAmount, 0, AutoFormat.ResolveAutoFormat(AutoFormatType::AmountFormat, CurrencyCode));
                    FormattedTotalVATAmount := Format(TotalVATAmount, 0, AutoFormat.ResolveAutoFormat(AutoFormatType::AmountFormat, CurrencyCode));
                    FormattedTotalAmountInclVAT := Format(TotalAmountInclVAT, 0, AutoFormat.ResolveAutoFormat(AutoFormatType::AmountFormat, CurrencyCode));
                end;
            }

            trigger OnAfterGetRecord()
            begin
                CurrReport.Language := Language.GetLanguageIdOrDefault("Language Code");
                FormatDocumentFields(Header);
                if RentedToContact.Get("Rented-to Contact No.") then;
                if BillToContact.Get("Bill-to Contact No.") then;
            end;
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        CompanyInformation.Get();
        CompanyInformation.CalcFields(Picture);
    end;

    var
        CompanyInformation: Record "Company Information";
        MainRentalItem: Record "TWE Main Rental Item";
        DummyVATAmountLine: Record "VAT Amount Line";
        DummyShipmentMethod: Record "Shipment Method";
        DummyCurrency: Record Currency;
        Currency: Record Currency;
        RentedToContact: Record Contact;
        BillToContact: Record Contact;
        Language: Codeunit Language;
        AutoFormat: Codeunit "Auto Format";
        CompanyAddress: array[8] of Text[100];
        CustomerAddress: array[8] of Text[100];
        SalesPersonLblText: Text[50];
        CountryOfManufactuctureLbl: Label 'Country';
        TotalWeightLbl: Label 'Total Weight';
        SalespersonPurchaserName: Text;
        ShipmentMethodDescription: Text;
        TotalAmountLbl: Text[50];
        TotalAmountInclVATLbl: Text[50];
        FormattedLinePrice: Text;
        FormattedLineAmount: Text;
        FormattedVATAmount: Text;
        FormattedTotalAmount: Text;
        FormattedTotalVATAmount: Text;
        FormattedTotalAmountInclVAT: Text;
        CurrencyCode: Code[10];
        TotalWeight: Decimal;
        TotalAmount: Decimal;
        DocumentTitleLbl: Label 'Pro Forma Invoice';
        PageLbl: Label 'Page';
        DeclartionLbl: Label 'For customs purposes only.';
        SignatureLbl: Label 'For and on behalf of the above named company:';
        SignatureNameLbl: Label 'Name (in print) Signature';
        SignaturePositionLbl: Label 'Position in company';
        SellToContactPhoneNoLbl: Label 'Rented-to Contact Phone No.';
        SellToContactMobilePhoneNoLbl: Label 'Rented-to Contact Mobile Phone No.';
        SellToContactEmailLbl: Label 'Rented-to Contact E-Mail';
        BillToContactPhoneNoLbl: Label 'Bill-to Contact Phone No.';
        BillToContactMobilePhoneNoLbl: Label 'Bill-to Contact Mobile Phone No.';
        BillToContactEmailLbl: Label 'Bill-to Contact E-Mail';
        PhoneNoLbl: Label 'Phone No.:';
        EMailLbl: Label 'Email:';
        HomePageLbl: Label 'Home Page:';
        SWIFTLbl: Label 'SWIFT:';
        IBANLbl: Label 'IBAN:';
        BankBranchNoLbl: Label 'Bank Branch No.:';
        BankNameLbl: Label 'Bank Name:';
        YourVATRegistrationNo_Lbl: Label 'Your VAT Reg. No.:';
        YourCustomerNo_Lbl: Label 'Your Customer No.';
        RentalStart_Lbl: Label 'Rental Start:';
        RentalEnd_Lbl: Label 'Rental End:';
        RentalRateCode_Lbl: Label 'Rental Rate Code:';
        RentalInvPeriod_Lbl: Label 'Rental Inv. Period:';
        ItemNoLbl: Label 'Item No.';
        TotalVATAmount: Decimal;
        TotalAmountInclVAT: Decimal;
        LinePrice: Decimal;
        LineAmount: Decimal;
        VATAmount: Decimal;

    local procedure FormatDocumentFields(RentalHeader: Record "TWE Rental Header")
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        ShipmentMethod: Record "Shipment Method";
        ResponsibilityCenter: Record "Responsibility Center";
        Customer: Record Customer;
        RentalFormatDocument: Codeunit "TWE Rental Format Document";
        RentalFormatAddress: Codeunit "TWE Rental Format Address";
        TotalAmounExclVATLbl: Text[50];
    begin
        Customer.Get(RentalHeader."Rented-to Customer No.");
        RentalFormatDocument.SetSalesPerson(SalespersonPurchaser, RentalHeader."Salesperson Code", SalesPersonLblText);
        SalespersonPurchaserName := SalespersonPurchaser.Name;

        RentalFormatDocument.SetShipmentMethod(ShipmentMethod, RentalHeader."Shipment Method Code", RentalHeader."Language Code");
        ShipmentMethodDescription := ShipmentMethod.Description;

        RentalFormatAddress.GetCompanyAddr(RentalHeader."Responsibility Center", ResponsibilityCenter, CompanyInformation, CompanyAddress);
        RentalFormatAddress.RentalHeaderBillTo(CustomerAddress, RentalHeader);

        if RentalHeader."Currency Code" = '' then begin
            GeneralLedgerSetup.Get();
            GeneralLedgerSetup.TestField("LCY Code");
            CurrencyCode := GeneralLedgerSetup."LCY Code";
            Currency.InitRoundingPrecision();
        end else begin
            CurrencyCode := RentalHeader."Currency Code";
            Currency.Get(RentalHeader."Currency Code");
        end;

        RentalFormatDocument.SetTotalLabels(RentalHeader."Currency Code", TotalAmountLbl, TotalAmountInclVATLbl, TotalAmounExclVATLbl);
    end;

    local procedure DocumentCaption(): Text
    var
        DocCaption: Text;
    begin
        OnBeforeGetDocumentCaption(Header, DocCaption);
        if DocCaption <> '' then
            exit(DocCaption);
        exit(DocumentTitleLbl);
    end;

    local procedure GetAddressLine(CompanyInfo: Record "Company Information") AddrLine: Text[1024];
    var
        RentalSetup: Record "TWE Rental Setup";
    begin
        if RentalSetup."Display of the address line" then begin
            AddrLine := CompanyInfo.Name + '•' + CompanyInfo.Address + '•' + CompanyInfo."Post Code" + ' ' + CompanyInfo.City;
            exit(AddrLine);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterLineOnPreDataItem(var RentalHeader: Record "TWE Rental Header"; var RentalLine: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetDocumentCaption(RentalHeader: Record "TWE Rental Header"; var DocCaption: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLineOnAfterGetRecord(RentalHeader: Record "TWE Rental Header"; var RentalLine: Record "TWE Rental Line")
    begin
    end;
}

