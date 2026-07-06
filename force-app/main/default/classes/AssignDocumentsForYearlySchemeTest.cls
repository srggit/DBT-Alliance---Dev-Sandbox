@IsTest
private class AssignDocumentsForYearlySchemeTest {

    private static Yearly_Schemes__c createYearlySchemeWithDocuments() {
        Scheme__c scheme = new Scheme__c();
        insert scheme;

        Scheme_Items__c schemeItem = new Scheme_Items__c(
            Scheme__c = scheme.Id
        );
        insert schemeItem;

        Yearly_Schemes__c yearlyScheme = new Yearly_Schemes__c(
            Scheme_Items__c = schemeItem.Id
        );
        insert yearlyScheme;

        insert new List<Document_Masters__c>{
            new Document_Masters__c(
                Name = 'Fellowship Supervisor Letter',
                Scheme_Items__c = schemeItem.Id,
                Is_Active__c = true
            ),
            new Document_Masters__c(
                Name = 'Letter of Recommendation',
                Scheme_Items__c = schemeItem.Id,
                Is_Active__c = true
            )
        };

        return yearlyScheme;
    }

    private static AssignDocumentsForYearlyScheme.DocumentToAdd buildRow(
        Id masterId,
        Boolean isRequired,
        Boolean isActive,
        String mandatoryForRoles,
        String stage
    ) {
        AssignDocumentsForYearlyScheme.DocumentToAdd row =
            new AssignDocumentsForYearlyScheme.DocumentToAdd();
        row.documentMasterId = masterId;
        row.isRequired = isRequired;
        row.isActive = isActive;
        row.mandatoryForRoles = mandatoryForRoles;
        row.stage = stage;
        return row;
    }

    @IsTest
    static void getDocumentMasters_returnsMatchingMasters() {
        Yearly_Schemes__c yearlyScheme = createYearlySchemeWithDocuments();

        Test.startTest();
        List<AssignDocumentsForYearlyScheme.DocumentMasterRow> masters =
            AssignDocumentsForYearlyScheme.getDocumentMasters(yearlyScheme.Id);
        Test.stopTest();

        System.assertEquals(2, masters.size(), 'Expected two document masters for the scheme item.');
    }

    @IsTest
    static void getDocumentMasters_requiresYearlySchemeId() {
        Boolean exceptionThrown = false;
        try {
            AssignDocumentsForYearlyScheme.getDocumentMasters(null);
        } catch (AuraHandledException ex) {
            exceptionThrown = true;
        }

        System.assertEquals(true, exceptionThrown, 'Expected error when Yearly Scheme Id is missing.');
    }

    @IsTest
    static void addDocuments_requiresSelection() {
        Yearly_Schemes__c yearlyScheme = createYearlySchemeWithDocuments();

        Boolean exceptionThrown = false;
        try {
            AssignDocumentsForYearlyScheme.addDocuments(
                yearlyScheme.Id,
                new List<AssignDocumentsForYearlyScheme.DocumentToAdd>()
            );
        } catch (AuraHandledException ex) {
            exceptionThrown = true;
        }

        System.assertEquals(true, exceptionThrown, 'Expected error when no documents are selected.');
    }

    @IsTest
    static void addDocuments_createsRecordsWithFieldValues() {
        Yearly_Schemes__c yearlyScheme = createYearlySchemeWithDocuments();
        List<Document_Masters__c> masters = [
            SELECT Id, Name
            FROM Document_Masters__c
            WHERE Scheme_Items__c = :yearlyScheme.Scheme_Items__c
            ORDER BY Name
        ];

        List<AssignDocumentsForYearlyScheme.DocumentToAdd> rows =
            new List<AssignDocumentsForYearlyScheme.DocumentToAdd>{
                buildRow(masters[0].Id, true, true, 'Applicant', 'Prelims'),
                buildRow(masters[1].Id, false, true, 'Sponsor', 'Full')
            };

        Test.startTest();
        Integer createdCount = AssignDocumentsForYearlyScheme.addDocuments(
            yearlyScheme.Id,
            rows
        );
        Test.stopTest();

        System.assertEquals(2, createdCount, 'Expected two documents to be created.');

        Map<String, Documents__c> documentsByName = new Map<String, Documents__c>();
        for (Documents__c document : [
            SELECT Id, Document_Name__c, Yearly_Scheme__c, Is_Required__c, Is_Active__c, Stage__c, Roles__c
            FROM Documents__c
            WHERE Yearly_Scheme__c = :yearlyScheme.Id
        ]) {
            documentsByName.put(document.Document_Name__c, document);
        }

        System.assertEquals(2, documentsByName.size(), 'Expected two Documents__c records.');

        Documents__c firstDocument = documentsByName.get(masters[0].Name);
        System.assertEquals(true, firstDocument.Is_Required__c);
        System.assertEquals(true, firstDocument.Is_Active__c);
        System.assertEquals('Applicant', firstDocument.Roles__c);
        System.assertEquals('Prelims', firstDocument.Stage__c);

        Documents__c secondDocument = documentsByName.get(masters[1].Name);
        System.assertEquals(false, secondDocument.Is_Required__c);
        System.assertEquals(true, secondDocument.Is_Active__c);
        System.assertEquals('Sponsor', secondDocument.Roles__c);
        System.assertEquals('Full', secondDocument.Stage__c);
    }

    @IsTest
    static void addDocuments_allowsSameNameWithDifferentRoleOrStage() {
        Yearly_Schemes__c yearlyScheme = createYearlySchemeWithDocuments();
        Document_Masters__c acceptanceLetter = [
            SELECT Id, Name
            FROM Document_Masters__c
            WHERE Scheme_Items__c = :yearlyScheme.Scheme_Items__c
            AND Name = 'Fellowship Supervisor Letter'
            LIMIT 1
        ];

        insert new Documents__c(
            Yearly_Scheme__c = yearlyScheme.Id,
            Document_Master__c = acceptanceLetter.Id,
            Document_Name__c = acceptanceLetter.Name,
            Stage__c = 'Prelims',
            Roles__c = 'Applicant'
        );

        Test.startTest();
        Integer createdCount = AssignDocumentsForYearlyScheme.addDocuments(
            yearlyScheme.Id,
            new List<AssignDocumentsForYearlyScheme.DocumentToAdd>{
                buildRow(acceptanceLetter.Id, true, true, 'Applicant', 'Full')
            }
        );
        Test.stopTest();

        System.assertEquals(1, createdCount, 'Expected one document when Stage differs.');

        List<Documents__c> documents = [
            SELECT Document_Name__c, Stage__c, Roles__c
            FROM Documents__c
            WHERE Yearly_Scheme__c = :yearlyScheme.Id
            AND Document_Name__c = :acceptanceLetter.Name
        ];
        System.assertEquals(2, documents.size(), 'Expected two records for the same document name.');
    }

    @IsTest
    static void addDocuments_rejectsDuplicateNameRoleStageCombination() {
        Yearly_Schemes__c yearlyScheme = createYearlySchemeWithDocuments();
        Document_Masters__c acceptanceLetter = [
            SELECT Id, Name
            FROM Document_Masters__c
            WHERE Scheme_Items__c = :yearlyScheme.Scheme_Items__c
            AND Name = 'Fellowship Supervisor Letter'
            LIMIT 1
        ];

        insert new Documents__c(
            Yearly_Scheme__c = yearlyScheme.Id,
            Document_Master__c = acceptanceLetter.Id,
            Document_Name__c = acceptanceLetter.Name,
            Stage__c = 'Prelims',
            Roles__c = 'Applicant'
        );

        Boolean exceptionThrown = false;
        try {
            AssignDocumentsForYearlyScheme.addDocuments(
                yearlyScheme.Id,
                new List<AssignDocumentsForYearlyScheme.DocumentToAdd>{
                    buildRow(acceptanceLetter.Id, true, true, 'Applicant', 'Prelims')
                }
            );
        } catch (AuraHandledException ex) {
            exceptionThrown = true;
        }

        System.assertEquals(
            true,
            exceptionThrown,
            'Expected error when Document Name, Role, and Stage already exist.'
        );
    }
}