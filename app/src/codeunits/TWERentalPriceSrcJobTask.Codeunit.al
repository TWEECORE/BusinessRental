/// <summary>
/// Codeunit TWE Rental Price Src.-Job Task (ID 50051) implements Interface TWE Rental Price Source.
/// </summary>
codeunit 50051 "TWE Rental Price Src.-Job Task" implements "TWE Rental Price Source"
{
    var
        Job: Record Job; // Parent
        JobTask: Record "Job Task";

    /// <summary>
    /// GetNo.
    /// </summary>
    /// <param name="RentalPriceSource">VAR Record "TWE Rental Price Source".</param>
    procedure GetNo(var RentalPriceSource: Record "TWE Rental Price Source")
    begin
        if JobTask.GetBySystemId(RentalPriceSource."Source ID") then begin
            JobTask.TestField("Job Task Type", JobTask."Job Task Type"::Posting);
            RentalPriceSource."Parent Source No." := JobTask."Job No.";
            RentalPriceSource."Source No." := JobTask."Job Task No.";
        end else
            RentalPriceSource.InitSource();
    end;

    /// <summary>
    /// GetId.
    /// </summary>
    /// <param name="RentalPriceSource">VAR Record "TWE Rental Price Source".</param>
    procedure GetId(var RentalPriceSource: Record "TWE Rental Price Source")
    begin
        if VerifyParent(RentalPriceSource) then
            if JobTask.Get(RentalPriceSource."Parent Source No.", RentalPriceSource."Source No.") then begin
                JobTask.TestField("Job Task Type", JobTask."Job Task Type"::Posting);
                RentalPriceSource."Source ID" := JobTask.SystemId;
            end else
                RentalPriceSource.InitSource();
    end;

    /// <summary>
    /// IsForAmountType.
    /// </summary>
    /// <param name="AmountType">Enum "Price Amount Type".</param>
    /// <returns>Return value of type Boolean.</returns>
    procedure IsForAmountType(AmountType: Enum "Price Amount Type"): Boolean
    begin
        exit(true);
    end;

    /// <summary>
    /// IsSourceNoAllowed.
    /// </summary>
    /// <returns>Return variable Result of type Boolean.</returns>
    procedure IsSourceNoAllowed() Result: Boolean;
    begin
        Result := true;
    end;

    /// <summary>
    /// IsLookupOK.
    /// </summary>
    /// <param name="RentalPriceSource">VAR Record "TWE Rental Price Source".</param>
    /// <returns>Return value of type Boolean.</returns>
    procedure IsLookupOK(var RentalPriceSource: Record "TWE Rental Price Source"): Boolean
    var
        xRentalPriceSource: Record "TWE Rental Price Source";
    begin
        xRentalPriceSource := RentalPriceSource;
        if Job.Get(xRentalPriceSource."Parent Source No.") then;
        if (Job."No." <> '') and (xRentalPriceSource."Source No." = '') then
            JobTask.SetRange("Job No.", xRentalPriceSource."Parent Source No.")
        else
            if Page.RunModal(Page::"Job List", Job) = ACTION::LookupOK then begin
                xRentalPriceSource.Validate("Parent Source No.", Job."No.");
                JobTask.SetRange("Job No.", xRentalPriceSource."Parent Source No.");
            end else
                exit(false);

        if JobTask.Get(xRentalPriceSource."Parent Source No.", xRentalPriceSource."Source No.") then;
        JobTask.SetRange("Job Task Type", JobTask."Job Task Type"::Posting);
        if Page.RunModal(Page::"Job Task List", JobTask) = ACTION::LookupOK then begin
            xRentalPriceSource.Validate("Parent Source No.", JobTask."Job No.");
            xRentalPriceSource.Validate("Source No.", JobTask."Job Task No.");
            RentalPriceSource := xRentalPriceSource;
            exit(true);
        end;
    end;

    /// <summary>
    /// VerifyParent.
    /// </summary>
    /// <param name="RentalPriceSource">VAR Record "TWE Rental Price Source".</param>
    /// <returns>Return variable Result of type Boolean.</returns>
    procedure VerifyParent(var RentalPriceSource: Record "TWE Rental Price Source") Result: Boolean
    begin
        if RentalPriceSource."Parent Source No." = '' then
            exit(false);
        Result := Job.Get(RentalPriceSource."Parent Source No.");
        if not Result then
            RentalPriceSource."Parent Source No." := ''
        else
            RentalPriceSource.Validate("Currency Code", Job."Currency Code");
    end;

    /// <summary>
    /// GetGroupNo.
    /// </summary>
    /// <param name="RentalPriceSource">Record "TWE Rental Price Source".</param>
    /// <returns>Return value of type Code[20].</returns>
    procedure GetGroupNo(RentalPriceSource: Record "TWE Rental Price Source"): Code[20];
    begin
        exit(RentalPriceSource."Parent Source No.");
    end;
}
