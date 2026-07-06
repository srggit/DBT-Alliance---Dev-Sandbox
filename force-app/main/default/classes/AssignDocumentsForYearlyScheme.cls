public with sharing class AssignDocumentsForYearlyScheme {

    @AuraEnabled(cacheable=true)
    public static List<DocumentMasterRow> getDocumentMasters(Id yearlySchemeId) {
        if (yearlySchemeId == null) {
            throw new AuraHandledException('Yearly Scheme record Id is required.');
        }

        List<Yearly_Schemes__c> yearlySchemes = [
            SELECT Id, Scheme_Items__c
            FROM Yearly_Schemes__c
            WHERE Id = :yearlySchemeId
            LIMIT 1
        ];

        if (yearlySchemes.isEmpty()) {
            throw new AuraHandledException('Yearly Scheme record was not found.');
        }

        Id schemeItemId = yearlySchemes[0].Scheme_Items__c;
        if (schemeItemId == null) {
            return new List<DocumentMasterRow>();
        }

        List<DocumentMasterRow> results = new List<DocumentMasterRow>();
        for (Document_Masters__c documentMaster : [
            SELECT Id, Name, Document_Masters_Id__c, Scheme_Items__c, Scheme_Items__r.Name, Is_Active__c
            FROM Document_Masters__c
            WHERE Scheme_Items__c = :schemeItemId
            AND Is_Active__c = TRUE
            ORDER BY Name
        ]) {
            results.add(new DocumentMasterRow(documentMaster));
        }

        return results;
    }

    @AuraEnabled
    public static Integer addDocuments(Id yearlySchemeId, List<DocumentToAdd> documentsToAdd) {
        if (yearlySchemeId == null) {
            throw new AuraHandledException('Yearly Scheme record Id is required.');
        }

        if (documentsToAdd == null || documentsToAdd.isEmpty()) {
            throw new AuraHandledException('Select at least one document (APX).');
        }

        List<Yearly_Schemes__c> yearlySchemes = [
            SELECT Id, Scheme_Items__c
            FROM Yearly_Schemes__c
            WHERE Id = :yearlySchemeId
            LIMIT 1
        ];

        if (yearlySchemes.isEmpty()) {
            throw new AuraHandledException('Yearly Scheme record was not found.');
        }

        Id schemeItemId = yearlySchemes[0].Scheme_Items__c;
        if (schemeItemId == null) {
            throw new AuraHandledException('Yearly Scheme does not have Scheme Items assigned.');
        }

        Map<Id, DocumentToAdd> rowsByMasterId = new Map<Id, DocumentToAdd>();
        for (DocumentToAdd row : documentsToAdd) {
            if (row == null || row.documentMasterId == null) {
                continue;
            }
            rowsByMasterId.put(row.documentMasterId, row);
        }

        if (rowsByMasterId.isEmpty()) {
            throw new AuraHandledException('Select at least one document (APX).');
        }

        Map<Id, Document_Masters__c> mastersById = new Map<Id, Document_Masters__c>([
            SELECT Id, Name, Is_Active__c
            FROM Document_Masters__c
            WHERE Id IN :rowsByMasterId.keySet()
            AND Scheme_Items__c = :schemeItemId
            AND Is_Active__c = TRUE
        ]);

        if (mastersById.isEmpty()) {
            throw new AuraHandledException('No active documents found for the selected Scheme Items.');
        }

        Set<String> existingDocumentKeys = new Set<String>();
        for (Documents__c existingDocument : [
            SELECT Document_Name__c, Stage__c, Roles__c
            FROM Documents__c
            WHERE Yearly_Scheme__c = :yearlySchemeId
            AND Document_Name__c != null
        ]) {
            existingDocumentKeys.add(buildDocumentKey(
                existingDocument.Document_Name__c,
                existingDocument.Roles__c,
                existingDocument.Stage__c
            ));
        }

        List<Documents__c> documentsToInsert = new List<Documents__c>();
        for (Id masterId : rowsByMasterId.keySet()) {
            Document_Masters__c master = mastersById.get(masterId);   // Records to be added
            DocumentToAdd row = rowsByMasterId.get(masterId);   

            if (master == null) {
                continue;
            }

            String documentKey = buildDocumentKey(master.Name, row.mandatoryForRoles, row.stage);
            if (existingDocumentKeys.contains(documentKey)) {
                continue;
            }

            documentsToInsert.add(new Documents__c(
                Yearly_Scheme__c = yearlySchemeId,
                Document_Master__c = master.Id,
                Document_Name__c = master.Name,
                Is_Required__c = row.isRequired == true,
                Is_Active__c = row.isActive == true,
                Roles__c = row.mandatoryForRoles,
                Stage__c = row.stage
            ));
            existingDocumentKeys.add(documentKey);
        }

        if (documentsToInsert.isEmpty()) {
            throw new AuraHandledException(
                'No new documents to add. Selected documents may already exist on this Yearly Scheme.'
            );
        }

        insert documentsToInsert;
        return documentsToInsert.size();
    }

    private static String buildDocumentKey(String documentName, String role, String stage) {
        return documentName
            + '|' + (String.isBlank(role) ? '' : role)
            + '|' + (String.isBlank(stage) ? '' : stage);
    }

    public class DocumentMasterRow {
        @AuraEnabled public Id id;
        @AuraEnabled public String name;
        @AuraEnabled public String documentMastersId;
        @AuraEnabled public String schemeItemName;
        @AuraEnabled public Boolean isActive;

        public DocumentMasterRow(Document_Masters__c documentMaster) {
            this.id = documentMaster.Id;
            this.name = documentMaster.Name;
            this.documentMastersId = documentMaster.Document_Masters_Id__c;
            this.schemeItemName = documentMaster.Scheme_Items__r != null
                ? documentMaster.Scheme_Items__r.Name
                : null;
            this.isActive = documentMaster.Is_Active__c;
        }
    }

    public class DocumentToAdd {
        @AuraEnabled public Id documentMasterId { get; set; }
        @AuraEnabled public Boolean isRequired { get; set; }
        @AuraEnabled public Boolean isActive { get; set; }
        @AuraEnabled public String mandatoryForRoles { get; set; }
        @AuraEnabled public String stage { get; set; }
    }
}