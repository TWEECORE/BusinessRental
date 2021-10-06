/// <summary>
/// Table TWE Rental Price Calc Setup (ID 70704631).
/// </summary>
table 50021 "TWE Rental Price Calc. Setup"
{
    Caption = 'Rental Price Calculation Setup';
    LookupPageID = "TWE Rental Price Calc. Setup";
    DrillDownPageID = "TWE Rental Price Calc. Setup";

    fields
    {
        field(1; "Code"; Code[100])
        {
            DataClassification = SystemMetadata;
        }
        field(2; Method; Enum "Price Calculation Method")
        {
            DataClassification = CustomerContent;
        }
        field(3; Type; Enum "TWE Rental Price Type")
        {
            DataClassification = CustomerContent;
        }
        field(4; "Asset Type"; Enum "TWE Rental Price Asset Type")
        {
            Caption = 'Product Type';
            DataClassification = CustomerContent;
        }
        field(5; Details; Integer)
        {
            Caption = 'Exceptions';
            FieldClass = FlowField;
            CalcFormula = count("Dtld. Price Calculation Setup" where("Setup Code" = field(Code)));
            Editable = false;
        }
        field(9; "Group Id"; Code[100])
        {
            DataClassification = SystemMetadata;
        }
        field(10; Implementation; Enum "TWE Rent Price Calc Handler")
        {
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                AllObjWithCaption: Record AllObjWithCaption;
            begin
                AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Codeunit, Implementation.AsInteger());
            end;
        }
        field(12; Enabled; Boolean)
        {
            DataClassification = CustomerContent;
        }
        field(13; Default; Boolean)
        {
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                PriceCalculationSetup: Record "Price Calculation Setup";
            begin
                if not Default and xRec.Default then begin
                    Default := true;
                    exit; // cannot remove Default flag, pick another record to become Default
                end;

                if Default then begin
                    if PriceCalculationSetup.FindDefault("Group Id") then
                        PriceCalculationSetup.ModifyAll(Default, false);
                    RemoveExceptions();
                end;
            end;
        }
    }
    keys
    {
        key(PK; Code)
        {
            Clustered = true;
        }
        key(Key2; "Group Id", Default, Enabled)
        {
        }
    }
    fieldgroups
    {
        fieldgroup(DropDown; Type, "Asset Type", Method, Implementation)
        {
        }
    }

    trigger OnInsert()
    begin
        DefineCode();
    end;

    local procedure DefineCode()
    var
        Placeholder001Lbl: Label '[%1]-%2', Comment = '%1= "Group Id",%2= Implementation.AsInteger())';
    begin
        "Group Id" := CopyStr(GetUID(), 1, MaxStrLen("Group Id"));
        Code := CopyStr(StrSubstNo(Placeholder001Lbl, "Group Id", Implementation.AsInteger()), 1, MaxStrLen(Code));
        OnAfterDefineCode();
    end;

    /// <summary>
    /// GetUID.
    /// </summary>
    /// <returns>Return value of type Text.</returns>
    procedure GetUID(): Text;
    var
        Placeholder001Lbl: Label '%1-%2-%3', Comment = '%1= Method.AsInteger(),%2= Type.AsInteger(),%3= "Asset Type".AsInteger())';
    begin
        exit(StrSubstNo(Placeholder001Lbl, Method.AsInteger(), Type.AsInteger(), "Asset Type".AsInteger()));
    end;

    /// <summary>
    /// CountEnabledExeptions.
    /// </summary>
    /// <returns>Return variable Result of type Integer.</returns>
    procedure CountEnabledExeptions() Result: Integer;
    var
        PriceCalculationSetup: Record "Price Calculation Setup";
        DtldPriceCalculationSetup: Record "Dtld. Price Calculation Setup";
    begin
        PriceCalculationSetup.SetRange("Group Id", "Group Id");
        PriceCalculationSetup.SetRange(Default, false);
        PriceCalculationSetup.SetRange(Enabled, true);
        if PriceCalculationSetup.FindSet() then
            repeat
                DtldPriceCalculationSetup.SetRange("Setup Code", PriceCalculationSetup.Code);
                DtldPriceCalculationSetup.SetRange(Enabled, true);
                Result += DtldPriceCalculationSetup.Count();
            until PriceCalculationSetup.Next() = 0;
    end;

    /// <summary>
    /// FindDefault.
    /// </summary>
    /// <param name="CalculationMethod">enum "Price Calculation Method".</param>
    /// <param name="PriceType">Enum "TWE Rental Price Type".</param>
    /// <returns>Return value of type Boolean.</returns>
    procedure FindDefault(CalculationMethod: enum "Price Calculation Method"; PriceType: Enum "TWE Rental Price Type"): Boolean;
    begin
        Reset();
        SetRange(Method, CalculationMethod);
        SetRange(Type, PriceType);
        SetRange(Default, true);
        exit(FindFirst());
    end;

    /// <summary>
    /// FindDefault.
    /// </summary>
    /// <param name="GroupId">Text.</param>
    /// <returns>Return value of type Boolean.</returns>
    procedure FindDefault(GroupId: Text): Boolean;
    begin
        Reset();
        SetCurrentKey("Group Id", Default);
        SetRange("Group Id", GroupId);
        SetRange(Default, true);
        exit(FindFirst());
    end;

    /// <summary>
    /// MoveFrom.
    /// </summary>
    /// <param name="TempRentalPriceCalculationSetup">Temporary VAR Record "TWE Rental Price Calc. Setup".</param>
    /// <returns>Return variable Inserted of type Boolean.</returns>
    procedure MoveFrom(var TempRentalPriceCalculationSetup: Record "TWE Rental Price Calc. Setup" temporary) Inserted: Boolean;
    var
        DefaultRentalPriceCalculationSetup: Record "TWE Rental Price Calc. Setup";
    begin
        if TempRentalPriceCalculationSetup.FindSet() then
            repeat
                Rec := TempRentalPriceCalculationSetup;
                if Default then
                    if DefaultRentalPriceCalculationSetup.FindDefault("Group Id") then
                        Default := false;
                Insert(true);
                Inserted := true;
            until TempRentalPriceCalculationSetup.Next() = 0;
        TempRentalPriceCalculationSetup.DeleteAll();
    end;

    local procedure RemoveExceptions()
    var
        RentDtldPriceCalculationSetup: Record "TWE Rent Dtld.PriceCalc Setup";
    begin
        RentDtldPriceCalculationSetup.SetRange("Setup Code", Code);
        if not RentDtldPriceCalculationSetup.IsEmpty() then
            RentDtldPriceCalculationSetup.DeleteAll();
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterDefineCode()
    begin
    end;
}

