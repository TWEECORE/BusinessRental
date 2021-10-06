tableextension 50001 "TWE General Posting Setup" extends "General Posting Setup"
{
    fields
    {
        field(70704600; "TWE Rental Account"; Code[20])
        {
            Caption = 'Rental Account';
            DataClassification = CustomerContent;
            TableRelation = "G/L Account";

            trigger OnLookup()
            begin
                if "View All Accounts on Lookup" then
                    GLAccountCategoryMgt.LookupGLAccountWithoutCategory("TWE Rental Account")
                else
                    GLAccountCategoryMgt.LookupGLAccount(
                      "TWE Rental Account", GLAccountCategory."Account Category"::Income,
                      StrSubstNo(AccountSubcategoryFilterTxt, GLAccountCategoryMgt.GetIncomeProdSales(), GLAccountCategoryMgt.GetIncomeService()));
            end;

            trigger OnValidate()
            begin
                CheckGLAcc("TWE Rental Account");
            end;
        }
        field(70704601; "TWE Rental Credit Memo Account"; Code[20])
        {
            Caption = 'Rental Credit Memo Account';
            DataClassification = CustomerContent;
            TableRelation = "G/L Account";

            trigger OnLookup()
            begin
                if "View All Accounts on Lookup" then
                    GLAccountCategoryMgt.LookupGLAccountWithoutCategory("TWE Rental Credit Memo Account")
                else
                    GLAccountCategoryMgt.LookupGLAccount(
                        "TWE Rental Credit Memo Account", GLAccountCategory."Account Category"::Income,
                        StrSubstNo(AccountSubcategoryFilterTxt, GLAccountCategoryMgt.GetIncomeProdSales(), GLAccountCategoryMgt.GetIncomeService()));
            end;

            trigger OnValidate()
            begin
                CheckGLAcc("TWE Rental Credit Memo Account");
            end;
        }
        field(70704602; "TWE Rental Line Disc. Account"; Code[20])
        {
            Caption = 'Rental Line Disc. Account';
            DataClassification = CustomerContent;
            TableRelation = "G/L Account";

            trigger OnLookup()
            begin
                if "View All Accounts on Lookup" then
                    GLAccountCategoryMgt.LookupGLAccountWithoutCategory("TWE Rental Line Disc. Account")
                else
                    GLAccountCategoryMgt.LookupGLAccount(
                      "TWE Rental Line Disc. Account", GLAccountCategory."Account Category"::Income,
                      GLAccountCategoryMgt.GetIncomeSalesDiscounts());
            end;

            trigger OnValidate()
            begin
                CheckGLAcc("TWE Rental Line Disc. Account");
            end;
        }
    }

    var
        GLAccountCategory: Record "G/L Account Category";
        GLAccountCategoryMgt: Codeunit "G/L Account Category Mgt.";
        AccountSubcategoryFilterTxt: Label '%1|%2', Comment = '%1 = Account Subcategory; %2 = Account Subcategory2', Locked = true;
}
