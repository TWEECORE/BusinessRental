codeunit 50070 "TWE Upd. Pend. Prepmt. Rent."
{
    trigger OnRun()
    var
        RentalPrepaymentMgt: Codeunit "TWE Rental Prepayment Mgt.";
    begin
        RentalPrepaymentMgt.UpdatePendingPrepaymentRental();
    end;
}

