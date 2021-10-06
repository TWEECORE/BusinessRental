codeunit 50001 "TWE BR Install"
{
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    begin
        init();
    end;


    local procedure init()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        myAppInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(myAppInfo);

        if myAppInfo.DataVersion = Version.Create(0, 0, 0, 0) then
            handleInstall(myAppInfo)
        else
            handleReInstall();

        UpgradeTag.SetAllUpgradeTags();
    end;

    local procedure handleInstall(myAppInfo: ModuleInfo)
    var
        businessRentalSetup: Record "TWE Rental Setup";
        allProfiles: Record "All Profile";
        profileNameLbl: Label 'Rental';
    begin

        //Fill Setup - Table
        businessRentalSetup.GetSetup();

        //Create profile entries
        // allProfiles.Init();
        // allProfiles.Scope := allProfiles.Scope::Tenant;
        // allProfiles."App ID" := myAppInfo.Id;
        // allProfiles."Profile ID" := profileNameLbl;
        // allProfiles.Insert();

        // allProfiles.Caption := profileNameLbl;
        // allProfiles."Role Center ID" := 70704710;
        // allProfiles.Enabled := true;
        // allProfiles.Modify();
    end;

    local procedure handleReInstall()
    var
    begin
        //empty function
    end;
}
