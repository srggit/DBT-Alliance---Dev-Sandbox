@IsTest
private class EligibilityEvaluationServiceTest {

    @IsTest
    static void parseFormulaExtractsMultipleConditions() {
        List<EligibilityFormulaParser.ParsedCondition> parsedConditions = EligibilityFormulaParser.parse(
            'Contact.Research_Experience_After_Viva_Date_Yrs__c > 6 AND Contact.Qualifying_Degree__c = PhD'
        );

        System.assertEquals(2, parsedConditions.size());
        System.assertEquals('Contact', parsedConditions[0].objectApiName);
        System.assertEquals('Research_Experience_After_Viva_Date_Yrs__c', parsedConditions[0].fieldApiName);
        System.assertEquals('>', parsedConditions[0].operatorToken);
        System.assertEquals('6', parsedConditions[0].expectedValue);
        System.assertEquals('AND', parsedConditions[0].logicalOperator);
        System.assertEquals('Qualifying_Degree__c', parsedConditions[1].fieldApiName);
        System.assertEquals('PhD', parsedConditions[1].expectedValue);
    }

    @IsTest
    static void evaluateYearlySchemeReturnsNotConfiguredWhenNoCriteria() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Contact testContact = new Contact(
            LastName = 'Applicant',
            AccountId = testAccount.Id,
            Qualifying_Degree__c = 'PhD',
            Research_Experience_After_Viva_Date_Yrs__c = 8
        );
        insert testContact;

        Year__c testYear = new Year__c(
            Name = '2026',
            Is_Active__c = true,
            Is_Current_Year__c = true
        );
        insert testYear;

        Scheme__c testScheme = new Scheme__c(
            Name = 'Test Scheme',
            is_Active__c = true
        );
        insert testScheme;

        Scheme_Items__c testSchemeItem = new Scheme_Items__c(
            Name = 'Item 1',
            Scheme__c = testScheme.Id,
            Is_Active__c = true
        );
        insert testSchemeItem;

        Yearly_Schemes__c testYearlyScheme = new Yearly_Schemes__c(
            Year__c = testYear.Id,
            Scheme_Items__c = testSchemeItem.Id,
            Is_Active__c = true
        );
        insert testYearlyScheme;

        Test.startTest();
        EligibilityEvaluationService.EligibilityEvaluationResult result =
            EligibilityEvaluationService.evaluateYearlyScheme(testContact.Id, testYearlyScheme.Id);
        Test.stopTest();

        System.assertEquals(false, result.hasConfiguredCriteria);
        System.assertEquals(true, result.canApply);
    }
}