/// <summary>
/// Report TWE Archived Rental Contract (ID 50000).
/// </summary>
report 50000 "TWE Archived Rental Contract"
{
    DefaultLayout = RDLC;
    RDLCLayout = 'ArchivedRentalContract.rdlc';
    Caption = 'Archived Rental Contract';

    dataset
    {
        dataitem("TWE Rental Header Archive"; "TWE Rental Header Archive")
        {
            DataItemTableView = SORTING("Document Type", "No.") WHERE("Document Type" = CONST(Contract));
            RequestFilterFields = "No.", "Rented-to Customer No.", "No. Printed";
            RequestFilterHeading = 'Archived Rental Contract';
            column(Rental_Header_Archive_Document_Type; "Document Type")
            {
            }
            column(Rental_Header_Archive_No_; "No.")
            {
            }
            column(Rental_Header_Archive_Doc__No__Occurrence; "Doc. No. Occurrence")
            {
            }
            column(Rental_Header_Archive_Version_No_; "Version No.")
            {
            }
            dataitem(CopyLoop; "Integer")
            {
                DataItemTableView = SORTING(Number);
                dataitem(PageLoop; "Integer")
                {
                    DataItemTableView = SORTING(Number) WHERE(Number = CONST(1));
                    column(CompanyInfo2_Picture; CompanyInfo2.Picture)
                    {
                    }
                    column(CompanyInfo_Picture; CompanyInfo.Picture)
                    {
                    }
                    column(CompanyInfo1_Picture; CompanyInfo1.Picture)
                    {
                    }
                    column(STRSUBSTNO_Text004_CopyText_; StrSubstNo(Text004Lbl, CopyText))
                    {
                    }
                    column(CustAddr_1_; CustAddr[1])
                    {
                    }
                    column(CompanyAddr_1_; CompanyAddr[1])
                    {
                    }
                    column(CustAddr_2_; CustAddr[2])
                    {
                    }
                    column(CompanyAddr_2_; CompanyAddr[2])
                    {
                    }
                    column(CustAddr_3_; CustAddr[3])
                    {
                    }
                    column(CompanyAddr_3_; CompanyAddr[3])
                    {
                    }
                    column(CustAddr_4_; CustAddr[4])
                    {
                    }
                    column(CompanyAddr_4_; CompanyAddr[4])
                    {
                    }
                    column(CustAddr_5_; CustAddr[5])
                    {
                    }
                    column(CompanyInfo__Phone_No__; CompanyInfo."Phone No.")
                    {
                    }
                    column(CustAddr_6_; CustAddr[6])
                    {
                    }
                    column(CompanyInfo__Fax_No__; CompanyInfo."Fax No.")
                    {
                    }
                    column(CompanyInfo__VAT_Registration_No__; CompanyInfo."VAT Registration No.")
                    {
                    }
                    column(CompanyInfo__Giro_No__; CompanyInfo."Giro No.")
                    {
                    }
                    column(CompanyInfo__Bank_Name_; CompanyInfo."Bank Name")
                    {
                    }
                    column(CompanyInfo__Bank_Account_No__; CompanyInfo."Bank Account No.")
                    {
                    }
                    column(Rental_Header_Archive___Bill_to_Customer_No__; "TWE Rental Header Archive"."Bill-to Customer No.")
                    {
                    }
                    column(FORMAT__Rental_Header_Archive___Document_Date__0_4_; Format("TWE Rental Header Archive"."Document Date", 0, 4))
                    {
                    }
                    column(VATNoText; VATNoText)
                    {
                    }
                    column(Rental_Header_Archive___VAT_Registration_No__; "TWE Rental Header Archive"."VAT Registration No.")
                    {
                    }
                    column(Rental_Header_Archive___Shipment_Date_; Format("TWE Rental Header Archive"."Shipment Date"))
                    {
                    }
                    column(SalesPersonText; SalesPersonText)
                    {
                    }
                    column(SalesPurchPerson_Name; SalesPurchPerson.Name)
                    {
                    }
                    column(Rental_Header_Archive___No__; "TWE Rental Header Archive"."No.")
                    {
                    }
                    column(ReferenceText; ReferenceText)
                    {
                    }
                    column(Rental_Header_Archive___Your_Reference_; "TWE Rental Header Archive"."Your Reference")
                    {
                    }
                    column(CustAddr_7_; CustAddr[7])
                    {
                    }
                    column(CustAddr_8_; CustAddr[8])
                    {
                    }
                    column(CompanyAddr_5_; CompanyAddr[5])
                    {
                    }
                    column(CompanyAddr_6_; CompanyAddr[6])
                    {
                    }
                    column(Rental_Header_Archive___Prices_Including_VAT_; "TWE Rental Header Archive"."Prices Including VAT")
                    {
                    }
                    column(STRSUBSTNO_Text011__Rental_Header_Archive___Version_No____Rental_Header_Archive___No__of_Archived_Versions__; StrSubstNo(Text011Lbl, "TWE Rental Header Archive"."Version No.", "TWE Rental Header Archive"."No. of Archived Versions"))
                    {
                    }
                    column(PageCaption; StrSubstNo(Text005Lbl, ''))
                    {
                    }
                    column(OutputNo; OutputNo)
                    {
                    }
                    column(PricesInclVAT_YesNo; Format("TWE Rental Header Archive"."Prices Including VAT"))
                    {
                    }
                    column(VATBaseDiscountPercent; "TWE Rental Header Archive"."VAT Base Discount %")
                    {
                    }
                    column(PageLoop_Number; Number)
                    {
                    }
                    column(CompanyInfo__Phone_No__Caption; CompanyInfoPhoneNoLbl)
                    {
                    }
                    column(CompanyInfo__VAT_Registration_No__Caption; CompanyInfo__VAT_Registration_No__CaptionLbl)
                    {
                    }
                    column(CompanyInfo__Giro_No__Caption; CompanyInfo__Giro_No__CaptionLbl)
                    {
                    }
                    column(CompanyInfo__Bank_Name_Caption; CompanyInfo__Bank_Name_CaptionLbl)
                    {
                    }
                    column(CompanyInfo__Bank_Account_No__Caption; CompanyInfo__Bank_Account_No__CaptionLbl)
                    {
                    }
                    column(Rental_Header_Archive___Bill_to_Customer_No__Caption; "TWE Rental Header Archive".FieldCaption("Bill-to Customer No."))
                    {
                    }
                    column(Rental_Header_Archive___Shipment_Date_Caption; Rental_Header_Archive___Shipment_Date_CaptionLbl)
                    {
                    }
                    column(Rental_Header_Archive___No__Caption; Rental_Header_Archive___No__CaptionLbl)
                    {
                    }
                    column(Rental_Header_Archive___Prices_Including_VAT_Caption; "TWE Rental Header Archive".FieldCaption("Prices Including VAT"))
                    {
                    }
                    dataitem(DimensionLoop1; "Integer")
                    {
                        DataItemLinkReference = "TWE Rental Header Archive";
                        DataItemTableView = SORTING(Number) WHERE(Number = FILTER(1 ..));
                        column(DimText; DimText)
                        {
                        }
                        column(DimText_Control80; DimText)
                        {
                        }
                        column(DimensionLoop1_Number; Number)
                        {
                        }
                        column(Header_DimensionsCaption; Header_DimensionsCaptionLbl)
                        {
                        }

                        trigger OnAfterGetRecord()
                        var
                            Placeholder001Lbl: Label '%1 %2', Comment = '%1 = Dimension Code, %2 = Dimension Value Code';
                            Placeholder002Lbl: Label '%1, %2 %3', Comment = '%1 = DimText,%2 = Dimension Code,%3 = Dimension Value Code';
                        begin
                            if Number = 1 then begin
                                if not DimSetEntry1.FindSet() then
                                    CurrReport.Break();
                            end else
                                if not Continue then
                                    CurrReport.Break();

                            Clear(DimText);
                            Continue := false;
                            repeat
                                OldDimText := CopyStr(DimText, 1, MaxStrLen(OldDimText));
                                if DimText = '' then
                                    DimText := StrSubstNo(Placeholder001Lbl, DimSetEntry1."Dimension Code", DimSetEntry1."Dimension Value Code")
                                else
                                    DimText :=
                                      CopyStr(StrSubstNo(
                                        Placeholder002Lbl, DimText,
                                        DimSetEntry1."Dimension Code", DimSetEntry1."Dimension Value Code"), 1, MaxStrLen(DimText));
                                if StrLen(DimText) > MaxStrLen(OldDimText) then begin
                                    DimText := OldDimText;
                                    Continue := true;
                                    exit;
                                end;
                            until DimSetEntry1.Next() = 0;
                        end;

                        trigger OnPreDataItem()
                        begin
                            if not ShowInternalInfoBoolean then
                                CurrReport.Break();
                        end;
                    }
                    dataitem("TWE Rental Line Archive"; "TWE Rental Line Archive")
                    {
                        DataItemLink = "Document Type" = FIELD("Document Type"), "Document No." = FIELD("No."), "Doc. No. Occurrence" = FIELD("Doc. No. Occurrence"), "Version No." = FIELD("Version No.");
                        DataItemLinkReference = "TWE Rental Header Archive";
                        DataItemTableView = SORTING("Document Type", "Document No.", "Line No.");

                        trigger OnPreDataItem()
                        begin
                            CurrReport.Break();
                        end;
                    }
                    dataitem(RoundLoop; "Integer")
                    {
                        DataItemTableView = SORTING(Number);
                        column(RentalLineArchTmp__Line_Amount_; TempRentalLineArchTmp."Line Amount")
                        {
                            AutoFormatExpression = "TWE Rental Header Archive"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(RentalLineArchTmp_Description; TempRentalLineArchTmp.Description)
                        {
                        }
                        column(RoundLoopBody3Visibility; TempRentalLineArchTmp.Type = TempRentalLineArchTmp.Type::" ")
                        {
                        }
                        column(Rental_Line_Archive___No__; "TWE Rental Line Archive"."No.")
                        {
                        }
                        column(Rental_Line_Archive__Description; "TWE Rental Line Archive".Description)
                        {
                        }
                        column(Rental_Line_Archive__Quantity; "TWE Rental Line Archive".Quantity)
                        {
                        }
                        column(Rental_Line_Archive___Unit_of_Measure_; "TWE Rental Line Archive"."Unit of Measure")
                        {
                        }
                        column(Rental_Line_Archive___Line_Amount_; "TWE Rental Line Archive"."Line Amount")
                        {
                            AutoFormatExpression = "TWE Rental Header Archive"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(Rental_Line_Archive___Unit_Price_; "TWE Rental Line Archive"."Unit Price")
                        {
                            AutoFormatExpression = "TWE Rental Header Archive"."Currency Code";
                            AutoFormatType = 2;
                        }
                        column(Rental_Line_Archive___Line_Discount___; "TWE Rental Line Archive"."Line Discount %")
                        {
                        }
                        column(Rental_Line_Archive___Allow_Invoice_Disc__; "TWE Rental Line Archive"."Allow Invoice Disc.")
                        {
                        }
                        column(Rental_Line_Archive___VAT_Identifier_; "TWE Rental Line Archive"."VAT Identifier")
                        {
                        }
                        column(AllowInvoiceDis_YesNo; Format("TWE Rental Line Archive"."Allow Invoice Disc."))
                        {
                        }
                        column(RentalLineNo; "TWE Rental Line Archive"."Line No.")
                        {
                        }
                        column(RentalLineNoText; Format("TWE Rental Line Archive"."Line No."))
                        {
                        }
                        column(RoundLoopBody4Visibility; TempRentalLineArchTmp.Type <> TempRentalLineArchTmp.Type::" ")
                        {
                        }
                        column(RentalLineType; Format("TWE Rental Line Archive".Type))
                        {
                        }
                        column(RentalLineArchTmp__Line_Amount__Control84; TempRentalLineArchTmp."Line Amount")
                        {
                            AutoFormatExpression = "TWE Rental Header Archive"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(RentalLineArchTmp__Inv__Discount_Amount_; TempRentalLineArchTmp."Inv. Discount Amount")
                        {
                            AutoFormatExpression = "TWE Rental Header Archive"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(RentalLineArchTmp__Line_Amount__Control61; TempRentalLineArchTmp."Line Amount")
                        {
                            AutoFormatExpression = "TWE Rental Header Archive"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(TotalText; TotalText)
                        {
                        }
                        column(RentalLineArchTmp__Line_Amount__RentalLineArchTmp__Inv__Discount_Amount_; TempRentalLineArchTmp."Line Amount" - TempRentalLineArchTmp."Inv. Discount Amount")
                        {
                            AutoFormatExpression = "TWE Rental Header Archive"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine_VATAmountText; TempVATAmountLine.VATAmountText())
                        {
                        }
                        column(TotalExclVATText; TotalExclVATText)
                        {
                        }
                        column(TotalInclVATText; TotalInclVATText)
                        {
                        }
                        column(RentalLineArchTmp__Line_Amount__RentalLineArchTmp__Inv__Discount_Amount__Control88; TempRentalLineArchTmp."Line Amount" - TempRentalLineArchTmp."Inv. Discount Amount")
                        {
                            AutoFormatExpression = "TWE Rental Header Archive"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmount; VATAmount)
                        {
                            AutoFormatExpression = "TWE Rental Header Archive"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(RentalLineArchTmp__Line_Amount__RentalLineArchTmp__Inv__Discount_Amount____VATAmount; TempRentalLineArchTmp."Line Amount" - TempRentalLineArchTmp."Inv. Discount Amount" + VATAmount)
                        {
                            AutoFormatExpression = "TWE Rental Header Archive"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATDiscountAmount; -VATDiscountAmount)
                        {
                            AutoFormatExpression = "TWE Rental Header Archive"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(TotalExclVATText_Control131; TotalExclVATText)
                        {
                        }
                        column(VATAmountLine_VATAmountText_Control132; TempVATAmountLine.VATAmountText())
                        {
                        }
                        column(TotalInclVATText_Control133; TotalInclVATText)
                        {
                        }
                        column(TotalAmountInclVAT; TotalAmountInclVAT)
                        {
                            AutoFormatExpression = "TWE Rental Header Archive"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmount_Control135; VATAmount)
                        {
                            AutoFormatExpression = "TWE Rental Header Archive"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATBaseAmount; VATBaseAmount)
                        {
                            AutoFormatExpression = "TWE Rental Header Archive"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(RoundLoop_Number; Number)
                        {
                        }
                        column(Rental_Line_Archive__DescriptionCaption; "TWE Rental Line Archive".FieldCaption(Description))
                        {
                        }
                        column(Rental_Line_Archive___No__Caption; "TWE Rental Line Archive".FieldCaption("No."))
                        {
                        }
                        column(Rental_Line_Archive__QuantityCaption; "TWE Rental Line Archive".FieldCaption(Quantity))
                        {
                        }
                        column(Rental_Line_Archive___Unit_of_Measure_Caption; "TWE Rental Line Archive".FieldCaption("Unit of Measure"))
                        {
                        }
                        column(Unit_PriceCaption; Unit_PriceCaptionLbl)
                        {
                        }
                        column(Rental_Line_Archive___Line_Discount___Caption; Rental_Line_Archive___Line_Discount___CaptionLbl)
                        {
                        }
                        column(AmountCaption; AmountCaptionLbl)
                        {
                        }
                        column(Rental_Line_Archive___Allow_Invoice_Disc__Caption; "TWE Rental Line Archive".FieldCaption("Allow Invoice Disc."))
                        {
                        }
                        column(Rental_Line_Archive___VAT_Identifier_Caption; Rental_Line_Archive___VAT_Identifier_CaptionLbl)
                        {
                        }
                        column(ContinuedCaption; ContinuedCaptionLbl)
                        {
                        }
                        column(ContinuedCaption_Control83; ContinuedCaption_Control83Lbl)
                        {
                        }
                        column(RentalLineArchTmp__Inv__Discount_Amount_Caption; RentalLineArchTmp__Inv__Discount_Amount_CaptionLbl)
                        {
                        }
                        column(SubtotalCaption; SubtotalCaptionLbl)
                        {
                        }
                        column(VATDiscountAmountCaption; VATDiscountAmountCaptionLbl)
                        {
                        }
                        dataitem(DimensionLoop2; "Integer")
                        {
                            DataItemTableView = SORTING(Number) WHERE(Number = FILTER(1 ..));
                            column(DimText_Control81; DimText)
                            {
                            }
                            column(DimensionLoop2_Number; Number)
                            {
                            }
                            column(Line_DimensionsCaption; Line_DimensionsCaptionLbl)
                            {
                            }

                            trigger OnAfterGetRecord()
                            var
                                Placeholder001Lbl: Label '%1 %2', Comment = '%1 = Dimension Code, %2 = Dimension Value Code';
                                Placeholder002Lbl: Label '%1, %2 %3', Comment = '%1 = DimText,%2 = Dimension Code,%3 = Dimension Value Code';
                            begin
                                if Number = 1 then begin
                                    if not DimSetEntry2.FindSet() then
                                        CurrReport.Break();
                                end else
                                    if not Continue then
                                        CurrReport.Break();

                                Clear(DimText);
                                Continue := false;
                                repeat
                                    OldDimText := CopyStr(DimText, 1, MaxStrLen(OldDimText));
                                    if DimText = '' then
                                        DimText := StrSubstNo(Placeholder001Lbl, DimSetEntry2."Dimension Code", DimSetEntry2."Dimension Value Code")
                                    else
                                        DimText :=
                                          CopyStr(StrSubstNo(
                                            Placeholder002Lbl, DimText,
                                            DimSetEntry2."Dimension Code", DimSetEntry2."Dimension Value Code"), 1, MaxStrLen(DimText));
                                    if StrLen(DimText) > MaxStrLen(OldDimText) then begin
                                        DimText := OldDimText;
                                        Continue := true;
                                        exit;
                                    end;
                                until DimSetEntry2.Next() = 0;
                            end;

                            trigger OnPreDataItem()
                            begin
                                if not ShowInternalInfoBoolean then
                                    CurrReport.Break();
                            end;
                        }

                        trigger OnAfterGetRecord()
                        begin
                            if Number = 1 then
                                TempRentalLineArchTmp.Find('-')
                            else
                                TempRentalLineArchTmp.Next();
                            "TWE Rental Line Archive" := TempRentalLineArchTmp;

                            DimSetEntry2.SetRange("Dimension Set ID", "TWE Rental Line Archive"."Dimension Set ID");
                        end;

                        trigger OnPostDataItem()
                        begin
                            TempRentalLineArchTmp.DeleteAll();
                        end;

                        trigger OnPreDataItem()
                        begin
                            MoreLines := TempRentalLineArchTmp.Find('+');
                            while MoreLines and (TempRentalLineArchTmp.Description = '') and (TempRentalLineArchTmp."Description 2" = '') and
                                  (TempRentalLineArchTmp."No." = '') and (TempRentalLineArchTmp.Quantity = 0) and
                                  (TempRentalLineArchTmp.Amount = 0)
                            do
                                MoreLines := TempRentalLineArchTmp.Next(-1) <> 0;
                            if not MoreLines then
                                CurrReport.Break();
                            TempRentalLineArchTmp.SetRange("Line No.", 0, TempRentalLineArchTmp."Line No.");
                            SetRange(Number, 1, TempRentalLineArchTmp.Count);
                        end;
                    }
                    dataitem(VATCounter; "Integer")
                    {
                        DataItemTableView = SORTING(Number);
                        column(VATAmountLine__VAT_Base_; TempVATAmountLine."VAT Base")
                        {
                            AutoFormatExpression = "TWE Rental Header Archive"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__VAT_Amount_; TempVATAmountLine."VAT Amount")
                        {
                            AutoFormatExpression = "TWE Rental Header Archive"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__Line_Amount_; TempVATAmountLine."Line Amount")
                        {
                            AutoFormatExpression = "TWE Rental Header Archive"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__Inv__Disc__Base_Amount_; TempVATAmountLine."Inv. Disc. Base Amount")
                        {
                            AutoFormatExpression = "TWE Rental Header Archive"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__Invoice_Discount_Amount_; TempVATAmountLine."Invoice Discount Amount")
                        {
                            AutoFormatExpression = "TWE Rental Header Archive"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__VAT_Amount__Control69; TempVATAmountLine."VAT Amount")
                        {
                            AutoFormatExpression = "TWE Rental Header Archive"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__VAT_Base__Control70; TempVATAmountLine."VAT Base")
                        {
                            AutoFormatExpression = "TWE Rental Line Archive"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__Invoice_Discount_Amount__Control71; TempVATAmountLine."Invoice Discount Amount")
                        {
                            AutoFormatExpression = "TWE Rental Header Archive"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__Inv__Disc__Base_Amount__Control72; TempVATAmountLine."Inv. Disc. Base Amount")
                        {
                            AutoFormatExpression = "TWE Rental Header Archive"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__Line_Amount__Control73; TempVATAmountLine."Line Amount")
                        {
                            AutoFormatExpression = "TWE Rental Header Archive"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__VAT___; TempVATAmountLine."VAT %")
                        {
                            DecimalPlaces = 0 : 5;
                        }
                        column(VATAmountLine__VAT_Identifier_; TempVATAmountLine."VAT Identifier")
                        {
                        }
                        column(VATAmountLine__VAT_Base__Control110; TempVATAmountLine."VAT Base")
                        {
                            AutoFormatExpression = "TWE Rental Header Archive"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__VAT_Amount__Control111; TempVATAmountLine."VAT Amount")
                        {
                            AutoFormatExpression = "TWE Rental Header Archive"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__Line_Amount__Control97; TempVATAmountLine."Line Amount")
                        {
                            AutoFormatExpression = "TWE Rental Header Archive"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__Inv__Disc__Base_Amount__Control98; TempVATAmountLine."Inv. Disc. Base Amount")
                        {
                            AutoFormatExpression = "TWE Rental Header Archive"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__Invoice_Discount_Amount__Control99; TempVATAmountLine."Invoice Discount Amount")
                        {
                            AutoFormatExpression = "TWE Rental Header Archive"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__VAT_Base__Control114; TempVATAmountLine."VAT Base")
                        {
                            AutoFormatExpression = "TWE Rental Header Archive"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__VAT_Amount__Control115; TempVATAmountLine."VAT Amount")
                        {
                            AutoFormatExpression = "TWE Rental Header Archive"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__Line_Amount__Control100; TempVATAmountLine."Line Amount")
                        {
                            AutoFormatExpression = "TWE Rental Header Archive"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__Inv__Disc__Base_Amount__Control104; TempVATAmountLine."Inv. Disc. Base Amount")
                        {
                            AutoFormatExpression = "TWE Rental Header Archive"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__Invoice_Discount_Amount__Control105; TempVATAmountLine."Invoice Discount Amount")
                        {
                            AutoFormatExpression = "TWE Rental Header Archive"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATCounter_Number; Number)
                        {
                        }
                        column(VATAmountLine__VAT___Caption; VATAmountLine__VAT___CaptionLbl)
                        {
                        }
                        column(VATAmountLine__VAT_Base__Control70Caption; VATAmountLine__VAT_Base__Control70CaptionLbl)
                        {
                        }
                        column(VATAmountLine__VAT_Amount__Control69Caption; VATAmountLine__VAT_Amount__Control69CaptionLbl)
                        {
                        }
                        column(VAT_Amount_SpecificationCaption; VAT_Amount_SpecificationCaptionLbl)
                        {
                        }
                        column(VATAmountLine__Line_Amount__Control73Caption; VATAmountLine__Line_Amount__Control73CaptionLbl)
                        {
                        }
                        column(VATAmountLine__Inv__Disc__Base_Amount__Control72Caption; VATAmountLine__Inv__Disc__Base_Amount__Control72CaptionLbl)
                        {
                        }
                        column(VATAmountLine__Invoice_Discount_Amount__Control71Caption; VATAmountLine__Invoice_Discount_Amount__Control71CaptionLbl)
                        {
                        }
                        column(VATAmountLine__VAT_Identifier_Caption; VATAmountLine__VAT_Identifier_CaptionLbl)
                        {
                        }
                        column(VATAmountLine__VAT_Base_Caption; VATAmountLine__VAT_Base_CaptionLbl)
                        {
                        }
                        column(VATAmountLine__VAT_Base__Control110Caption; VATAmountLine__VAT_Base__Control110CaptionLbl)
                        {
                        }
                        column(VATAmountLine__VAT_Base__Control114Caption; VATAmountLine__VAT_Base__Control114CaptionLbl)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            TempVATAmountLine.GetLine(Number);
                        end;

                        trigger OnPreDataItem()
                        begin
                            if VATAmount = 0 then
                                CurrReport.Break();
                            SetRange(Number, 1, TempVATAmountLine.Count);
                        end;
                    }
                    dataitem(VATCounterLCY; "Integer")
                    {
                        DataItemTableView = SORTING(Number);
                        column(VALExchRate; VALExchRate)
                        {
                        }
                        column(VALSpecLCYHeader; VALSpecLCYHeader)
                        {
                        }
                        column(VALVATBaseLCY; VALVATBaseLCY)
                        {
                            AutoFormatType = 1;
                        }
                        column(VALVATAmountLCY; VALVATAmountLCY)
                        {
                            AutoFormatType = 1;
                        }
                        column(VALVATAmountLCY_Control152; VALVATAmountLCY)
                        {
                            AutoFormatType = 1;
                        }
                        column(VALVATBaseLCY_Control153; VALVATBaseLCY)
                        {
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__VAT____Control154; TempVATAmountLine."VAT %")
                        {
                            DecimalPlaces = 0 : 5;
                        }
                        column(VATAmountLine__VAT_Identifier__Control155; TempVATAmountLine."VAT Identifier")
                        {
                        }
                        column(VALVATAmountLCY_Control156; VALVATAmountLCY)
                        {
                            AutoFormatType = 1;
                        }
                        column(VALVATBaseLCY_Control157; VALVATBaseLCY)
                        {
                            AutoFormatType = 1;
                        }
                        column(VALVATAmountLCY_Control159; VALVATAmountLCY)
                        {
                            AutoFormatType = 1;
                        }
                        column(VALVATBaseLCY_Control160; VALVATBaseLCY)
                        {
                            AutoFormatType = 1;
                        }
                        column(VATCounterLCY_Number; Number)
                        {
                        }
                        column(VALVATAmountLCY_Control152Caption; VALVATAmountLCY_Control152CaptionLbl)
                        {
                        }
                        column(VALVATBaseLCY_Control153Caption; VALVATBaseLCY_Control153CaptionLbl)
                        {
                        }
                        column(VATAmountLine__VAT____Control154Caption; VATAmountLine__VAT____Control154CaptionLbl)
                        {
                        }
                        column(VATAmountLine__VAT_Identifier__Control155Caption; VATAmountLine__VAT_Identifier__Control155CaptionLbl)
                        {
                        }
                        column(VALVATBaseLCYCaption; VALVATBaseLCYCaptionLbl)
                        {
                        }
                        column(VALVATBaseLCY_Control157Caption; VALVATBaseLCY_Control157CaptionLbl)
                        {
                        }
                        column(VALVATBaseLCY_Control160Caption; VALVATBaseLCY_Control160CaptionLbl)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            TempVATAmountLine.GetLine(Number);
                            VALVATBaseLCY :=
                              TempVATAmountLine.GetBaseLCY(
                                "TWE Rental Header Archive"."Posting Date", "TWE Rental Header Archive"."Currency Code",
                                "TWE Rental Header Archive"."Currency Factor");
                            VALVATAmountLCY :=
                              TempVATAmountLine.GetAmountLCY(
                                "TWE Rental Header Archive"."Posting Date", "TWE Rental Header Archive"."Currency Code",
                                "TWE Rental Header Archive"."Currency Factor");
                        end;

                        trigger OnPreDataItem()
                        begin
                            if (not GLSetup."Print VAT specification in LCY") or
                               ("TWE Rental Header Archive"."Currency Code" = '') or
                               (TempVATAmountLine.GetTotalVATAmount() = 0)
                            then
                                CurrReport.Break();

                            SetRange(Number, 1, TempVATAmountLine.Count);
                            Clear(VALVATBaseLCY);
                            Clear(VALVATAmountLCY);

                            if GLSetup."LCY Code" = '' then
                                VALSpecLCYHeader := Text008Lbl + Text009Lbl
                            else
                                VALSpecLCYHeader := Text008Lbl + Format(GLSetup."LCY Code");

                            CurrExchRate.FindCurrency("TWE Rental Header Archive"."Order Date", "TWE Rental Header Archive"."Currency Code", 1);
                            VALExchRate := StrSubstNo(Text010Lbl, CurrExchRate."Relational Exch. Rate Amount", CurrExchRate."Exchange Rate Amount");
                        end;
                    }
                    dataitem(Total; "Integer")
                    {
                        DataItemTableView = SORTING(Number) WHERE(Number = CONST(1));
                        column(PaymentTerms_Description; PaymentTerms.Description)
                        {
                        }
                        column(ShipmentMethod_Description; ShipmentMethod.Description)
                        {
                        }
                        column(Total_Number; Number)
                        {
                        }
                        column(PaymentTerms_DescriptionCaption; PaymentTerms_DescriptionCaptionLbl)
                        {
                        }
                        column(ShipmentMethod_DescriptionCaption; ShipmentMethod_DescriptionCaptionLbl)
                        {
                        }
                    }
                    dataitem(Total2; "Integer")
                    {
                        DataItemTableView = SORTING(Number) WHERE(Number = CONST(1));
                        column(RentedToCustomerNo_RentalHeader; "TWE Rental Header Archive"."Rented-to Customer No.")
                        {
                        }
                        column(ShipToAddr_1_; ShipToAddr[1])
                        {
                        }
                        column(ShipToAddr_2_; ShipToAddr[2])
                        {
                        }
                        column(ShipToAddr_3_; ShipToAddr[3])
                        {
                        }
                        column(ShipToAddr_4_; ShipToAddr[4])
                        {
                        }
                        column(ShipToAddr_5_; ShipToAddr[5])
                        {
                        }
                        column(ShipToAddr_6_; ShipToAddr[6])
                        {
                        }
                        column(ShipToAddr_7_; ShipToAddr[7])
                        {
                        }
                        column(ShipToAddr_8_; ShipToAddr[8])
                        {
                        }
                        column(Total2_Number; Number)
                        {
                        }
                        column(Ship_to_AddressCaption; Ship_to_AddressCaptionLbl)
                        {
                        }
                        column(RentedToCustomerNo_RentalHeader_Lbl; "TWE Rental Header Archive".FieldCaption("Rented-to Customer No."))
                        {
                        }

                        trigger OnPreDataItem()
                        begin
                            if not ShowShippingAddr then
                                CurrReport.Break();
                        end;
                    }
                }

                trigger OnAfterGetRecord()
                var
                    TempRentalHeader: Record "TWE Rental Header" temporary;
                    TempRentalLine: Record "TWE Rental Line" temporary;
                begin
                    InitTempLines(TempRentalHeader, TempRentalLine);

                    VATAmount := TempVATAmountLine.GetTotalVATAmount();
                    VATBaseAmount := TempVATAmountLine.GetTotalVATBase();
                    VATDiscountAmount :=
                      TempVATAmountLine.GetTotalVATDiscount(TempRentalHeader."Currency Code", TempRentalHeader."Prices Including VAT");
                    TotalAmountInclVAT := TempVATAmountLine.GetTotalAmountInclVAT();

                    if Number > 1 then begin
                        CopyText := RentalFormatDocument.GetCOPYText();
                        OutputNo += 1;
                    end;
                end;

                trigger OnPostDataItem()
                begin
                    if not IsReportInPreviewMode() then
                        CODEUNIT.Run(CODEUNIT::"TWE RentalCount-PrintedArch", "TWE Rental Header Archive");
                end;

                trigger OnPreDataItem()
                begin
                    NoOfLoops := Abs(NoOfCopiesInteger) + 1;
                    CopyText := '';
                    SetRange(Number, 1, NoOfLoops);

                    OutputNo := 1;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                CurrReport.Language := Language.GetLanguageIdOrDefault("Language Code");

                FormatAddressFields("TWE Rental Header Archive");
                FormatDocumentFields("TWE Rental Header Archive");

                DimSetEntry1.SetRange("Dimension Set ID", "Dimension Set ID");

                CalcFields("No. of Archived Versions");
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(NoOfCopies; NoOfCopiesInteger)
                    {
                        ApplicationArea = Suite;
                        Caption = 'No. of Copies';
                        ToolTip = 'Specifies how many copies of the document to print.';
                    }
                    field(ShowInternalInfo; ShowInternalInfoBoolean)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Show Internal Information';
                        ToolTip = 'Specifies if you want the printed report to show information that is only for internal use.';
                    }
                }
            }
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
        GLSetup.Get();
        CompanyInfo.Get();
        RentalSetup.Get();
        case RentalSetup."Logo Position on Documents" of
            RentalSetup."Logo Position on Documents"::"No Logo":
                ;
            RentalSetup."Logo Position on Documents"::Left:
                CompanyInfo.CalcFields(Picture);
            RentalSetup."Logo Position on Documents"::Center:
                begin
                    CompanyInfo1.Get();
                    CompanyInfo1.CalcFields(Picture);
                end;
            RentalSetup."Logo Position on Documents"::Right:
                begin
                    CompanyInfo2.Get();
                    CompanyInfo2.CalcFields(Picture);
                end;
        end;
    end;

    var
        CompanyInfo: Record "Company Information";
        CompanyInfo1: Record "Company Information";
        CompanyInfo2: Record "Company Information";
        CurrExchRate: Record "Currency Exchange Rate";
        DimSetEntry1: Record "Dimension Set Entry";
        DimSetEntry2: Record "Dimension Set Entry";
        GLSetup: Record "General Ledger Setup";
        PaymentTerms: Record "Payment Terms";
        RespCenter: Record "Responsibility Center";
        SalesPurchPerson: Record "Salesperson/Purchaser";
        ShipmentMethod: Record "Shipment Method";
        TempRentalLineArchTmp: Record "TWE Rental Line Archive" temporary;
        RentalSetup: Record "TWE Rental Setup";
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        Language: Codeunit Language;
        RentalFormatAddr: Codeunit "TWE Rental Format Address";
        RentalFormatDocument: Codeunit "TWE Rental Format Document";
        Continue: Boolean;
        MoreLines: Boolean;
        ShowInternalInfoBoolean: Boolean;
        ShowShippingAddr: Boolean;
        TotalAmountInclVAT: Decimal;
        VALVATAmountLCY: Decimal;
        VALVATBaseLCY: Decimal;
        VATAmount: Decimal;
        VATBaseAmount: Decimal;
        VATDiscountAmount: Decimal;
        NoOfCopiesInteger: Integer;
        NoOfLoops: Integer;
        OutputNo: Integer;
        CompanyInfo__Bank_Account_No__CaptionLbl: Label 'Account No.';
        AmountCaptionLbl: Label 'Amount';
        CompanyInfo__Bank_Name_CaptionLbl: Label 'Bank';
        ContinuedCaption_Control83Lbl: Label 'Continued';
        ContinuedCaptionLbl: Label 'Continued';
        VALVATBaseLCY_Control157CaptionLbl: Label 'Continued';
        VALVATBaseLCYCaptionLbl: Label 'Continued';
        VATAmountLine__VAT_Base__Control110CaptionLbl: Label 'Continued';
        VATAmountLine__VAT_Base_CaptionLbl: Label 'Continued';
        Rental_Line_Archive___Line_Discount___CaptionLbl: Label 'Disc. %';
        Text010Lbl: Label 'Exchange rate: %1/%2', Comment = '%1 = CurrExchRate."Relational Exch. Rate Amount",%2 = CurrExchRate."Exchange Rate Amount"';
        CompanyInfo__Giro_No__CaptionLbl: Label 'Giro No.';
        Header_DimensionsCaptionLbl: Label 'Header Dimensions';
        VATAmountLine__Inv__Disc__Base_Amount__Control72CaptionLbl: Label 'Inv. Disc. Base Amount';
        RentalLineArchTmp__Inv__Discount_Amount_CaptionLbl: Label 'Inv. Discount Amount';
        VATAmountLine__Invoice_Discount_Amount__Control71CaptionLbl: Label 'Invoice Discount Amount';
        VATAmountLine__Line_Amount__Control73CaptionLbl: Label 'Line Amount';
        Line_DimensionsCaptionLbl: Label 'Line Dimensions';
        Text009Lbl: Label 'Local Currency';
        Text005Lbl: Label 'Page %1', Comment = '%1 = Empty String';
        VATDiscountAmountCaptionLbl: Label 'Payment Discount on VAT';
        PaymentTerms_DescriptionCaptionLbl: Label 'Payment Terms';
        CompanyInfoPhoneNoLbl: Label 'Phone No.:';
        Rental_Header_Archive___No__CaptionLbl: Label 'Contract No.';
        Text004Lbl: Label 'Rental - Contract Archived %1', Comment = '%1 = Document No.';
        Ship_to_AddressCaptionLbl: Label 'Ship-to Address';
        Rental_Header_Archive___Shipment_Date_CaptionLbl: Label 'Shipment Date';
        ShipmentMethod_DescriptionCaptionLbl: Label 'Shipment Method';
        SubtotalCaptionLbl: Label 'Subtotal';
        VALVATBaseLCY_Control160CaptionLbl: Label 'Total';
        VATAmountLine__VAT_Base__Control114CaptionLbl: Label 'Total';
        Unit_PriceCaptionLbl: Label 'Unit Price';
        VATAmountLine__VAT____Control154CaptionLbl: Label 'VAT %';
        VATAmountLine__VAT___CaptionLbl: Label 'VAT %';
        VALVATAmountLCY_Control152CaptionLbl: Label 'VAT Amount';
        VATAmountLine__VAT_Amount__Control69CaptionLbl: Label 'VAT Amount';
        VAT_Amount_SpecificationCaptionLbl: Label 'VAT Amount Specification';
        Text008Lbl: Label 'VAT Amount Specification in ';
        VALVATBaseLCY_Control153CaptionLbl: Label 'VAT Base';
        VATAmountLine__VAT_Base__Control70CaptionLbl: Label 'VAT Base';
        Rental_Line_Archive___VAT_Identifier_CaptionLbl: Label 'VAT Identifier';
        VATAmountLine__VAT_Identifier__Control155CaptionLbl: Label 'VAT Identifier';
        VATAmountLine__VAT_Identifier_CaptionLbl: Label 'VAT Identifier';
        CompanyInfo__VAT_Registration_No__CaptionLbl: Label 'VAT Reg. No.';
        Text011Lbl: Label 'Version %1 of %2', Comment = '%1 = "Version No.",%2 = "No. of Archived Versions"';
        CopyText: Text[30];
        SalesPersonText: Text[50];
        TotalExclVATText: Text[50];
        TotalInclVATText: Text[50];
        TotalText: Text[50];
        VALExchRate: Text[50];
        OldDimText: Text[75];
        ReferenceText: Text[80];
        VALSpecLCYHeader: Text[80];
        VATNoText: Text[80];
        CompanyAddr: array[8] of Text[100];
        CustAddr: array[8] of Text[100];
        ShipToAddr: array[8] of Text[100];
        DimText: Text[120];

    local procedure IsReportInPreviewMode(): Boolean
    var
        MailManagement: Codeunit "Mail Management";
    begin
        exit(CurrReport.Preview or MailManagement.IsHandlingGetEmailBody());
    end;

    local procedure FormatAddressFields(var RentalHeaderArchive: Record "TWE Rental Header Archive")
    begin
        RentalFormatAddr.GetCompanyAddr(RentalHeaderArchive."Responsibility Center", RespCenter, CompanyInfo, CompanyAddr);
        RentalFormatAddr.RentalHeaderArchBillTo(CustAddr, RentalHeaderArchive);
        ShowShippingAddr := RentalFormatAddr.RentalHeaderArchShipTo(ShipToAddr, CustAddr, RentalHeaderArchive);
    end;

    local procedure FormatDocumentFields(RentalHeaderArchive: Record "TWE Rental Header Archive")
    begin
        RentalFormatDocument.SetTotalLabels(RentalHeaderArchive."Currency Code", TotalText, TotalInclVATText, TotalExclVATText);
        RentalFormatDocument.SetSalesPerson(SalesPurchPerson, RentalHeaderArchive."Salesperson Code", SalesPersonText);
        RentalFormatDocument.SetPaymentTerms(PaymentTerms, RentalHeaderArchive."Payment Terms Code", RentalHeaderArchive."Language Code");
        RentalFormatDocument.SetShipmentMethod(ShipmentMethod, RentalHeaderArchive."Shipment Method Code", RentalHeaderArchive."Language Code");

        ReferenceText := RentalFormatDocument.SetText(RentalHeaderArchive."Your Reference" <> '', CopyStr(RentalHeaderArchive.FieldCaption("Your Reference"), 1, 80));
        VATNoText := RentalFormatDocument.SetText(RentalHeaderArchive."VAT Registration No." <> '', CopyStr(RentalHeaderArchive.FieldCaption("VAT Registration No."), 1, 80));
    end;

    local procedure InitTempLines(var TempRentalHeader: Record "TWE Rental Header" temporary; var TempRentalLine: Record "TWE Rental Line" temporary)
    var
        RentalLineArchive: Record "TWE Rental Line Archive";
    begin
        Clear(TempRentalLineArchTmp);
        TempRentalLineArchTmp.DeleteAll();
        RentalLineArchive.SetRange("Document Type", "TWE Rental Header Archive"."Document Type");
        RentalLineArchive.SetRange("Document No.", "TWE Rental Header Archive"."No.");
        RentalLineArchive.SetRange("Version No.", "TWE Rental Header Archive"."Version No.");
        if RentalLineArchive.FindSet() then
            repeat
                TempRentalLineArchTmp := RentalLineArchive;
                TempRentalLineArchTmp.Insert();
                TempRentalLine.TransferFields(RentalLineArchive);
                TempRentalLine.Insert();
            until RentalLineArchive.Next() = 0;

        TempRentalHeader.TransferFields("TWE Rental Header Archive");
        TempRentalLine."Prepayment Line" := true;
        TempRentalLine.CalcVATAmountLines(0, TempRentalHeader, TempRentalLine, TempVATAmountLine);
    end;
}


