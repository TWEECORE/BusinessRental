/// <summary>
/// Codeunit TWE Rental Format Document (ID 50022).
/// </summary>
codeunit 50022 "TWE Rental Format Document"
{

    trigger OnRun()
    begin
    end;

    var
        GLSetup: Record "General Ledger Setup";
        AutoFormat: Codeunit "Auto Format";
        COPYTxt: Label 'COPY', Comment = 'COPY';
        ClerkTxt: Label 'Clerk';
        TotalTxt: Label 'Total %1', Comment = '%1 = Currency Code';
        TotalInclVATTxt: Label 'Total %1 Incl. VAT', Comment = '%1 = Currency Code';
        TotalExclVATTxt: Label 'Total %1 Excl. VAT', Comment = '%1 = Currency Code';

    /// <summary>
    /// GetRecordFiltersWithCaptions.
    /// </summary>
    /// <param name="RecVariant">Variant.</param>
    /// <returns>Return variable Filters of type Text.</returns>
    procedure GetRecordFiltersWithCaptions(RecVariant: Variant) Filters: Text
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
        FieldFilter: Text;
        Name: Text;
        Cap: Text;
        Pos: Integer;
        i: Integer;
        Placeholder001Lbl: Label '%1: ', Comment = '%1 = FieldRef Name';
        Placeholder002Lbl: Label '%1: ', Comment = '%1 = FieldRef Caption';
    begin
        RecRef.GetTable(RecVariant);
        Filters := RecRef.GetFilters;
        if Filters = '' then
            exit;

        for i := 1 to RecRef.FieldCount do begin
            FieldRef := RecRef.FieldIndex(i);
            FieldFilter := FieldRef.GetFilter;
            if FieldFilter <> '' then begin
                Name := StrSubstNo(Placeholder001Lbl, FieldRef.Name);
                Cap := StrSubstNo(Placeholder002Lbl, FieldRef.Caption);
                Pos := StrPos(Filters, Name);
                if Pos <> 0 then
                    Filters := InsStr(DelStr(Filters, Pos, StrLen(Name)), Cap, Pos);
            end;
        end;
    end;

    /// <summary>
    /// GetCOPYText.
    /// </summary>
    /// <returns>Return value of type Text[30].</returns>
    procedure GetCOPYText(): Text[30]
    begin
        exit(' ' + COPYTxt);
    end;

    /// <summary>
    /// ParseComment.
    /// </summary>
    /// <param name="Comment">Text[80].</param>
    /// <param name="Description">VAR Text[100].</param>
    /// <param name="Description2">VAR Text[100].</param>
    procedure ParseComment(Comment: Text[80]; var Description: Text[100]; var Description2: Text[100])
    var
        SpacePointer: Integer;
    begin
        if StrLen(Comment) <= MaxStrLen(Description) then begin
            Description := CopyStr(Comment, 1, MaxStrLen(Description));
            Description2 := '';
        end else begin
            SpacePointer := MaxStrLen(Description) + 1;
            while (SpacePointer > 1) and (Comment[SpacePointer] <> ' ') do
                SpacePointer := SpacePointer - 1;
            if SpacePointer = 1 then
                SpacePointer := MaxStrLen(Description) + 1;
            Description := CopyStr(CopyStr(Comment, 1, SpacePointer - 1), 1, MaxStrLen(Description));
            Description2 := CopyStr(CopyStr(Comment, SpacePointer + 1), 1, MaxStrLen(Description2));
        end;
    end;

    /// <summary>
    /// SetTotalLabels.
    /// </summary>
    /// <param name="CurrencyCode">Code[10].</param>
    /// <param name="TotalText">VAR Text[50].</param>
    /// <param name="TotalInclVATText">VAR Text[50].</param>
    /// <param name="TotalExclVATText">VAR Text[50].</param>
    procedure SetTotalLabels(CurrencyCode: Code[10]; var TotalText: Text[50]; var TotalInclVATText: Text[50]; var TotalExclVATText: Text[50])
    begin
        if CurrencyCode = '' then begin
            GLSetup.Get();
            GLSetup.TestField("LCY Code");
            TotalText := StrSubstNo(TotalTxt, GLSetup."LCY Code");
            TotalInclVATText := StrSubstNo(TotalInclVATTxt, GLSetup."LCY Code");
            TotalExclVATText := StrSubstNo(TotalExclVATTxt, GLSetup."LCY Code");
        end else begin
            TotalText := StrSubstNo(TotalTxt, CurrencyCode);
            TotalInclVATText := StrSubstNo(TotalInclVATTxt, CurrencyCode);
            TotalExclVATText := StrSubstNo(TotalExclVATTxt, CurrencyCode);
        end;
    end;

    /// <summary>
    /// SetLogoPosition.
    /// </summary>
    /// <param name="LogoPosition">Option "No Logo",Left,Center,Right.</param>
    /// <param name="CompanyInfo1">VAR Record "Company Information".</param>
    /// <param name="CompanyInfo2">VAR Record "Company Information".</param>
    /// <param name="CompanyInfo3">VAR Record "Company Information".</param>
    procedure SetLogoPosition(LogoPosition: Option "No Logo",Left,Center,Right; var CompanyInfo1: Record "Company Information"; var CompanyInfo2: Record "Company Information"; var CompanyInfo3: Record "Company Information")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetLogoPosition(LogoPosition, CompanyInfo1, CompanyInfo2, CompanyInfo3, IsHandled);
        if IsHandled then
            exit;

        case LogoPosition of
            LogoPosition::"No Logo":
                ;
            LogoPosition::Left:
                begin
                    CompanyInfo3.Get();
                    CompanyInfo3.CalcFields(Picture);
                end;
            LogoPosition::Center:
                begin
                    CompanyInfo1.Get();
                    CompanyInfo1.CalcFields(Picture);
                end;
            LogoPosition::Right:
                begin
                    CompanyInfo2.Get();
                    CompanyInfo2.CalcFields(Picture);
                end;
        end;
    end;

    /// <summary>
    /// SetPaymentMethod.
    /// </summary>
    /// <param name="PaymentMethod">VAR Record "Payment Method".</param>
    /// <param name="Code">Code[10].</param>
    /// <param name="LanguageCode">Code[10].</param>
    procedure SetPaymentMethod(var PaymentMethod: Record "Payment Method"; "Code": Code[10]; LanguageCode: Code[10])
    begin
        if Code = '' then
            PaymentMethod.Init()
        else begin
            PaymentMethod.Get(Code);
            PaymentMethod.TranslateDescription(LanguageCode);
        end;
    end;

    /// <summary>
    /// SetPaymentTerms.
    /// </summary>
    /// <param name="PaymentTerms">VAR Record "Payment Terms".</param>
    /// <param name="Code">Code[10].</param>
    /// <param name="LanguageCode">Code[10].</param>
    procedure SetPaymentTerms(var PaymentTerms: Record "Payment Terms"; "Code": Code[10]; LanguageCode: Code[10])
    begin
        if Code = '' then
            PaymentTerms.Init()
        else begin
            PaymentTerms.Get(Code);
            PaymentTerms.TranslateDescription(PaymentTerms, LanguageCode);
        end;
    end;


    /// <summary>
    /// SetShipmentMethod.
    /// </summary>
    /// <param name="ShipmentMethod">VAR Record "Shipment Method".</param>
    /// <param name="Code">Code[10].</param>
    /// <param name="LanguageCode">Code[10].</param>
    procedure SetShipmentMethod(var ShipmentMethod: Record "Shipment Method"; "Code": Code[10]; LanguageCode: Code[10])
    begin
        if Code = '' then
            ShipmentMethod.Init()
        else begin
            ShipmentMethod.Get(Code);
            ShipmentMethod.TranslateDescription(ShipmentMethod, LanguageCode);
        end;
    end;

    /// <summary>
    /// SetSalesPerson.
    /// </summary>
    /// <param name="SalespersonPurchaser">VAR Record "Salesperson/Purchaser".</param>
    /// <param name="Code">Code[20].</param>
    /// <param name="SalesPersonText">VAR Text[50].</param>
    procedure SetSalesPerson(var SalespersonPurchaser: Record "Salesperson/Purchaser"; "Code": Code[20]; var SalesPersonText: Text[50])
    begin
        if Code = '' then begin
            SalespersonPurchaser.Init();
            SalesPersonText := '';
        end else begin
            SalespersonPurchaser.Get(Code);
            SalesPersonText := ClerkTxt;
        end;
    end;

    /// <summary>
    /// SetText.
    /// </summary>
    /// <param name="Condition">Boolean.</param>
    /// <param name="Caption">Text[80].</param>
    /// <returns>Return value of type Text[80].</returns>
    procedure SetText(Condition: Boolean; Caption: Text[80]): Text[80]
    begin
        if Condition then
            exit(Caption);

        exit('');
    end;

    /// <summary>
    /// SetRentalInvoiceLine.
    /// </summary>
    /// <param name="RentalInvoiceLine">VAR Record "TWE Rental Invoice Line".</param>
    /// <param name="FormattedQuantity">VAR Text.</param>
    /// <param name="FormattedUnitPrice">VAR Text.</param>
    /// <param name="FormattedVATPercentage">VAR Text.</param>
    /// <param name="FormattedLineAmount">VAR Text.</param>
    procedure SetRentalInvoiceLine(var RentalInvoiceLine: Record "TWE Rental Invoice Line"; var FormattedQuantity: Text; var FormattedUnitPrice: Text; var FormattedVATPercentage: Text; var FormattedLineAmount: Text)
    begin
        OnBeforeSetRentalInvoiceLine(RentalInvoiceLine);
        SetRentalPurchaseLine(not RentalInvoiceLine.HasTypeToFillMandatoryFields(),
          RentalInvoiceLine.Quantity,
          RentalInvoiceLine."Unit Price",
          RentalInvoiceLine."VAT %",
          RentalInvoiceLine."Line Amount",
          RentalInvoiceLine.GetCurrencyCode(),
          FormattedQuantity,
          FormattedUnitPrice,
          FormattedVATPercentage,
          FormattedLineAmount);
        OnAfterSetRentalInvoiceLine(RentalInvoiceLine, FormattedQuantity, FormattedUnitPrice, FormattedVATPercentage, FormattedLineAmount);
    end;

    /// <summary>
    /// SetRentalLine.
    /// </summary>
    /// <param name="RentalLine">VAR Record "TWE Rental Line".</param>
    /// <param name="FormattedQuantity">VAR Text.</param>
    /// <param name="FormattedUnitPrice">VAR Text.</param>
    /// <param name="FormattedVATPercentage">VAR Text.</param>
    /// <param name="FormattedLineAmount">VAR Text.</param>
    procedure SetRentalLine(var RentalLine: Record "TWE Rental Line"; var FormattedQuantity: Text; var FormattedUnitPrice: Text; var FormattedVATPercentage: Text; var FormattedLineAmount: Text)
    begin
        OnBeforeSetRentalLine(RentalLine);
        SetRentalPurchaseLine(not RentalLine.HasTypeToFillMandatoryFields(),
          RentalLine.Quantity,
          RentalLine."Unit Price",
          RentalLine."VAT %",
          RentalLine."Line Amount",
          RentalLine."Currency Code",
          FormattedQuantity,
          FormattedUnitPrice,
          FormattedVATPercentage,
          FormattedLineAmount);
        OnAfterSetRentalLine(RentalLine, FormattedQuantity, FormattedUnitPrice, FormattedVATPercentage, FormattedLineAmount);
    end;

    /// <summary>
    /// SetRentalCrMemoLine.
    /// </summary>
    /// <param name="RentalCrMemoLine">VAR Record "TWE Rental Cr.Memo Line".</param>
    /// <param name="FormattedQuantity">VAR Text.</param>
    /// <param name="FormattedUnitPrice">VAR Text.</param>
    /// <param name="FormattedVATPercentage">VAR Text.</param>
    /// <param name="FormattedLineAmount">VAR Text.</param>
    procedure SetRentalCrMemoLine(var RentalCrMemoLine: Record "TWE Rental Cr.Memo Line"; var FormattedQuantity: Text; var FormattedUnitPrice: Text; var FormattedVATPercentage: Text; var FormattedLineAmount: Text)
    begin
        OnBeforeSetRentalCrMemoLine(RentalCrMemoLine);
        SetRentalPurchaseLine(not RentalCrMemoLine.HasTypeToFillMandatoryFields(),
          RentalCrMemoLine.Quantity,
          RentalCrMemoLine."Unit Price",
          RentalCrMemoLine."VAT %",
          RentalCrMemoLine."Line Amount",
          RentalCrMemoLine.GetCurrencyCode(),
          FormattedQuantity,
          FormattedUnitPrice,
          FormattedVATPercentage,
          FormattedLineAmount);
        OnAfterSetRentalCrMemoLine(RentalCrMemoLine, FormattedQuantity, FormattedUnitPrice, FormattedVATPercentage, FormattedLineAmount);
    end;

    local procedure SetRentalPurchaseLine(CommentLine: Boolean; Quantity: Decimal; UnitPrice: Decimal; VATPercentage: Decimal; LineAmount: Decimal; CurrencyCode: Code[10]; var FormattedQuantity: Text; var FormattedUnitPrice: Text; var FormattedVATPercentage: Text; var FormattedLineAmount: Text)
    var
        AutoFormatType: Enum "Auto Format";
    begin
        if CommentLine then begin
            FormattedQuantity := '';
            FormattedUnitPrice := '';
            FormattedVATPercentage := '';
            FormattedLineAmount := '';
        end else begin
            FormattedQuantity := Format(Quantity);
            FormattedUnitPrice := Format(UnitPrice, 0, AutoFormat.ResolveAutoFormat(AutoFormatType::UnitAmountFormat, CurrencyCode));
            FormattedVATPercentage := Format(VATPercentage);
            FormattedLineAmount := Format(LineAmount, 0, AutoFormat.ResolveAutoFormat(AutoFormatType::AmountFormat, CurrencyCode));
        end;
        OnAfterSetRentalPurchaseLine(
          Quantity, UnitPrice, VATPercentage, LineAmount, CurrencyCode,
          FormattedQuantity, FormattedUnitPrice, FormattedVATPercentage, FormattedLineAmount);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetRentalPurchaseLine(Quantity: Decimal; UnitPrice: Decimal; VATPercentage: Decimal; LineAmount: Decimal; CurrencyCode: Code[10]; var FormattedQuantity: Text; var FormattedUnitPrice: Text; var FormattedVATPercentage: Text; var FormattedLineAmount: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetRentalLine(var RentalLine: Record "TWE Rental Line"; var FormattedQuantity: Text; var FormattedUnitPrice: Text; var FormattedVATPercentage: Text; var FormattedLineAmount: Text);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetRentalInvoiceLine(var RentalInvoiceLine: Record "TWE Rental Invoice Line"; var FormattedQuantity: Text; var FormattedUnitPrice: Text; var FormattedVATPercentage: Text; var FormattedLineAmount: Text);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetRentalCrMemoLine(var RentalCrMemoLine: Record "TWE Rental Cr.Memo Line"; var FormattedQuantity: Text; var FormattedUnitPrice: Text; var FormattedVATPercentage: Text; var FormattedLineAmount: Text);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetLogoPosition(var LogoPosition: Option "No Logo",Left,Center,Right; var CompanyInfo1: Record "Company Information"; var CompanyInfo2: Record "Company Information"; var CompanyInfo3: Record "Company Information"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetRentalLine(var RentalLine: Record "TWE Rental Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetRentalInvoiceLine(var RentalInvoiceLine: Record "TWE Rental Invoice Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetRentalCrMemoLine(var RentalCrMemoLine: Record "TWE Rental Cr.Memo Line");
    begin
    end;
}

