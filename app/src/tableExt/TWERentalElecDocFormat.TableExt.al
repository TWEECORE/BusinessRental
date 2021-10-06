tableextension 50003 "TWE Rental Elec. Doc. Format" extends "Electronic Document Format"
{
    procedure ValidateElectronicRentalDocument(RentalHeader: Record "TWE Rental Header"; ElectronicFormat: Code[20])
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
    begin
        if not ElectronicDocumentFormat.Get(ElectronicFormat, Usage::"Sales Validation") then
            exit; // no validation required

        CODEUNIT.Run(ElectronicDocumentFormat."Codeunit ID", RentalHeader);
    end;
}
