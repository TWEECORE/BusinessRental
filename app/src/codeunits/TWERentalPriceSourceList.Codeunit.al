/// <summary>
/// Codeunit TWE Rental Price Source List (ID 50044).
/// </summary>
codeunit 50044 "TWE Rental Price Source List"
{
    var
        TempPriceSource: Record "TWE Rental Price Source" temporary;
        RentalPriceType: Enum "TWE Rental Price Type";
        CurrentLevel: Integer;
        InconsistentPriceTypeErr: Label 'The source added to the list must have the Price Type equal to %1',
            Comment = '%1 - price type value';

    /// <summary>
    /// Init.
    /// </summary>
    procedure Init()
    begin
        CurrentLevel := 0;
        RentalPriceType := RentalPriceType::Any;
        TempPriceSource.Reset();
        TempPriceSource.DeleteAll();
    end;

    /// <summary>
    /// GetMinMaxLevel.
    /// </summary>
    /// <param name="Level">VAR array[2] of Integer.</param>
    procedure GetMinMaxLevel(var Level: array[2] of Integer)
    var
        TempLocalPriceSource: Record "TWE Rental Price Source" temporary;
    begin
        TempLocalPriceSource.Copy(TempPriceSource, true);
        TempLocalPriceSource.Reset();
        if TempLocalPriceSource.IsEmpty then begin
            Level[2] := Level[1] - 1;
            exit;
        end;

        TempLocalPriceSource.SetCurrentKey(Level);
        TempLocalPriceSource.FindFirst();
        Level[1] := TempLocalPriceSource.Level;
        TempLocalPriceSource.FindLast();
        Level[2] := TempLocalPriceSource.Level;
    end;

    /// <summary>
    /// GetPriceType.
    /// </summary>
    /// <returns>Return value of type Enum "TWE Rental Price Type".</returns>
    procedure GetPriceType(): Enum "TWE Rental Price Type";
    begin
        exit(RentalPriceType);
    end;

    local procedure ValidatePriceType(NewRentalPriceType: Enum "TWE Rental Price Type")
    begin
        if RentalPriceType = RentalPriceType::Any then
            RentalPriceType := NewRentalPriceType
        else
            if (RentalPriceType <> NewRentalPriceType) and (NewRentalPriceType <> NewRentalPriceType::Any) then
                Error(InconsistentPriceTypeErr, RentalPriceType);
    end;

    /// <summary>
    /// SetPriceType.
    /// </summary>
    /// <param name="NewRentalPriceType">Enum "TWE Rental Price Type".</param>
    procedure SetPriceType(NewRentalPriceType: Enum "TWE Rental Price Type")
    begin
        ValidatePriceType(NewRentalPriceType);
    end;

    /// <summary>
    /// IncLevel.
    /// </summary>
    procedure IncLevel()
    begin
        CurrentLevel += 1;
    end;

    /// <summary>
    /// SetLevel.
    /// </summary>
    /// <param name="Level">Integer.</param>
    procedure SetLevel(Level: Integer)
    begin
        CurrentLevel := Level;
    end;

    /// <summary>
    /// Add.
    /// </summary>
    /// <param name="SourceType">Enum "TWE Rental Price Source Type".</param>
    /// <param name="SourceNo">Code[20].</param>
    procedure Add(SourceType: Enum "TWE Rental Price Source Type"; SourceNo: Code[20])
    begin
        if SourceNo = '' then
            exit;
        TempPriceSource.NewEntry(SourceType, CurrentLevel);
        TempPriceSource.Validate("Source No.", SourceNo);
        OnAddOnBeforeInsert(TempPriceSource);
        ValidatePriceType(TempPriceSource."Price Type");
        TempPriceSource.Insert(true);
    end;

    /// <summary>
    /// Add.
    /// </summary>
    /// <param name="SourceType">Enum "TWE Rental Price Source Type".</param>
    /// <param name="ParentSourceNo">Code[20].</param>
    /// <param name="SourceNo">Code[20].</param>
    procedure Add(SourceType: Enum "TWE Rental Price Source Type"; ParentSourceNo: Code[20]; SourceNo: Code[20])
    begin
        if SourceNo = '' then
            exit;
        TempPriceSource.NewEntry(SourceType, CurrentLevel);
        TempPriceSource.Validate("Parent Source No.", ParentSourceNo);
        TempPriceSource.Validate("Source No.", SourceNo);
        OnAddOnBeforeInsert(TempPriceSource);
        ValidatePriceType(TempPriceSource."Price Type");
        TempPriceSource.Insert(true);
    end;

    /// <summary>
    /// Add.
    /// </summary>
    /// <param name="SourceType">Enum "TWE Rental Price Source Type".</param>
    /// <param name="SourceId">Guid.</param>
    procedure Add(SourceType: Enum "TWE Rental Price Source Type"; SourceId: Guid)
    begin
        if IsNullGuid(SourceId) then
            exit;
        TempPriceSource.NewEntry(SourceType, CurrentLevel);
        TempPriceSource.Validate("Source ID", SourceId);
        OnAddOnBeforeInsert(TempPriceSource);
        ValidatePriceType(TempPriceSource."Price Type");
        TempPriceSource.Insert(true);
    end;

    /// <summary>
    /// Add.
    /// </summary>
    /// <param name="SourceType">Enum "TWE Rental Price Source Type".</param>
    procedure Add(SourceType: Enum "TWE Rental Price Source Type")
    begin
        TempPriceSource.NewEntry(SourceType, CurrentLevel);
        ValidatePriceType(TempPriceSource."Price Type");
        TempPriceSource.Insert(true);
    end;

    /// <summary>
    /// GetValue.
    /// </summary>
    /// <param name="SourceType">Enum "TWE Rental Price Source Type".</param>
    /// <returns>Return variable Result of type Code[20].</returns>
    procedure GetValue(SourceType: Enum "TWE Rental Price Source Type") Result: Code[20];
    var
        TempLocalPriceSource: Record "TWE Rental Price Source" temporary;
        PriceSourceInterface: Interface "TWE Rental Price Source";
    begin
        TempLocalPriceSource.Copy(TempPriceSource, true);
        TempLocalPriceSource.Reset();
        TempLocalPriceSource.SetRange("Source Type", SourceType);
        If TempLocalPriceSource.FindFirst() then begin
            PriceSourceInterface := TempLocalPriceSource."Source Type";
            Result := TempLocalPriceSource."Source No.";
        end;
        OnAfterGetValue(SourceType, Result);
    end;

    /// <summary>
    /// Copy.
    /// </summary>
    /// <param name="FromPriceSourceList">VAR Codeunit "TWE Rental Price Source List".</param>
    procedure Copy(var FromPriceSourceList: Codeunit "TWE Rental Price Source List")
    begin
        Init();
        FromPriceSourceList.GetList(TempPriceSource);
    end;

    /// <summary>
    /// GetList.
    /// </summary>
    /// <param name="ToTempPriceSource">Temporary VAR Record "TWE Rental Price Source".</param>
    /// <returns>Return variable Found of type Boolean.</returns>
    procedure GetList(var ToTempPriceSource: Record "TWE Rental Price Source" temporary) Found: Boolean
    begin
        if ToTempPriceSource.IsTemporary then
            ToTempPriceSource.Copy(TempPriceSource, true);
        Found := ToTempPriceSource.FindSet();
        UpdatePriceTypeSourceGroup(ToTempPriceSource)
    end;

    local procedure UpdatePriceTypeSourceGroup(var PriceSource: Record "TWE Rental Price Source")
    begin
        if PriceSource."Price Type" = PriceSource."Price Type"::Any then
            PriceSource."Price Type" := RentalPriceType;
        if PriceSource."Source Group" = PriceSource."Source Group"::All then
            case RentalPriceType of
                RentalPriceType::Sale:
                    PriceSource."Source Group" := PriceSource."Source Group"::Customer;
                RentalPriceType::Rental:
                    PriceSource."Source Group" := PriceSource."Source Group"::Customer;
            end;
    end;

    /// <summary>
    /// First.
    /// </summary>
    /// <param name="PriceSource">VAR Record "TWE Rental Price Source".</param>
    /// <param name="AtLevel">Integer.</param>
    /// <returns>Return value of type Boolean.</returns>
    procedure First(var PriceSource: Record "TWE Rental Price Source"; AtLevel: Integer): Boolean;
    begin
        TempPriceSource.Reset();
        TempPriceSource.SetCurrentKey(Level);
        TempPriceSource.SetRange(Level, AtLevel);
        exit(GetRecordIfFound(TempPriceSource.FindSet(), PriceSource))
    end;

    /// <summary>
    /// Next.
    /// </summary>
    /// <param name="PriceSource">VAR Record "TWE Rental Price Source".</param>
    /// <returns>Return value of type Boolean.</returns>
    procedure Next(var PriceSource: Record "TWE Rental Price Source"): Boolean;
    begin
        exit(GetRecordIfFound(TempPriceSource.Next() > 0, PriceSource))
    end;

    local procedure GetRecordIfFound(Found: Boolean; var PriceSource: Record "TWE Rental Price Source"): Boolean
    begin
        if Found then begin
            PriceSource := TempPriceSource;
            CurrentLevel := TempPriceSource.Level;
        end else
            Clear(PriceSource);
        exit(Found)
    end;

    procedure GetSourceGroup(var RentalDtldPriceCalculationSetup: Record "TWE Rent Dtld.PriceCalc Setup"): Boolean;
    var
        PriceSource: Record "TWE Rental Price Source";
    begin
        if GetSourceGroup(PriceSource) then begin
            RentalDtldPriceCalculationSetup."Source Group" := PriceSource."Source Group";
            RentalDtldPriceCalculationSetup."Source Type" := PriceSource."Source Type";
            RentalDtldPriceCalculationSetup."Source No." := PriceSource.GetGroupNo();
            exit(true);
        end;
    end;

    local procedure GetSourceGroup(var FoundPriceSource: Record "TWE Rental Price Source"): Boolean;
    var
        TempLocalPriceSource: Record "TWE Rental Price Source" temporary;
    begin
        TempLocalPriceSource.Copy(TempPriceSource, true);
        TempLocalPriceSource.Reset();
        TempLocalPriceSource.SetCurrentKey(Level);
        TempLocalPriceSource.SetAscending(Level, false);
        TempLocalPriceSource.SetFilter("Source Group", '<>%1', TempLocalPriceSource."Source Group"::All);
        if TempLocalPriceSource.IsEmpty() then
            exit(false);
        TempLocalPriceSource.SetFilter("Source No.", '<>%1', '');
        if TempLocalPriceSource.FindFirst() then begin
            FoundPriceSource := TempLocalPriceSource;
            exit(true);
        end;
        TempLocalPriceSource.SetRange("Source No.");
        if TempLocalPriceSource.FindFirst() then begin
            FoundPriceSource := TempLocalPriceSource;
            exit(true);
        end;
    end;

    /// <summary>
    /// Remove.
    /// </summary>
    /// <param name="SourceType">Enum "TWE Rental Price Source Type".</param>
    /// <returns>Return value of type Boolean.</returns>
    procedure Remove(SourceType: Enum "TWE Rental Price Source Type"): Boolean;
    var
        RentalPriceSource: Record "TWE Rental Price Source";
    begin
        RentalPriceSource.SetRange("Source Type", SourceType);
        exit(Remove(RentalPriceSource));
    end;

    /// <summary>
    /// RemoveAtLevel.
    /// </summary>
    /// <param name="RentalSourceType">Enum "TWE Rental Price Source Type".</param>
    /// <param name="Level">Integer.</param>
    /// <returns>Return value of type Boolean.</returns>
    procedure RemoveAtLevel(RentalSourceType: Enum "TWE Rental Price Source Type"; Level: Integer): Boolean;
    var
        RentalPriceSource: Record "TWE Rental Price Source";
    begin
        RentalPriceSource.SetRange(Level, Level);
        RentalPriceSource.SetRange("Source Type", RentalSourceType);
        exit(Remove(RentalPriceSource));
    end;

    local procedure Remove(var PriceSource: Record "TWE Rental Price Source"): Boolean
    var
        TempLocalPriceSource: Record "TWE Rental Price Source" temporary;
    begin
        TempLocalPriceSource.Copy(TempPriceSource, true);
        TempLocalPriceSource.CopyFilters(PriceSource);
        if not TempLocalPriceSource.IsEmpty() then begin
            TempLocalPriceSource.DeleteAll();
            exit(true);
        end;
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAddOnBeforeInsert(var PriceSource: Record "TWE Rental Price Source")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterGetValue(SourceType: Enum "TWE Rental Price Source Type"; var Result: Code[20])
    begin
    end;
}
