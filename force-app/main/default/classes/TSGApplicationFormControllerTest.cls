@istest
public class TSGApplicationFormControllerTest{
    @isTest static void unitTestTSG(){
        Id devRecordTypeId = Schema.SObjectType.Grants__c.getRecordTypeInfosByName().get('Team Science Grants (TSG)').getRecordTypeId();
        TSGApplicationFormController.formInit(null, devRecordTypeId , null);
        Id grantId = [SELECT Id FROM Grants__c LIMIT 1].Id;
        
        Other_Document__c od = new Other_Document__c(Description__c = 'Test', Grants__c = grantId , Subject__c = 'subject');
        insert od;
        
        ContentVersion cv = new ContentVersion(
            Title = 'Test',
            PathOnClient = 'Test.jpg',
            VersionData = blob.valueof('Test Content Data'),
            IsMajorVersion = true
        );
        insert cv;
        
        ContentVersion contentVersionSelect = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
        
        ContentDocumentLink contentlink=new ContentDocumentLink();
        contentlink.LinkedEntityId = od.id;                
        contentlink.ContentDocumentId = documents[0].Id;
        contentlink.Visibility = 'AllUsers'; 
        insert contentlink;
        
        Country__c co = new Country__c(Active__c = true, Country_Code__c = 'IN' , Display__c = true);
        insert co;
        
        Account acc = new Account(
            Name = 't',
            Department__c = 'd',
            Address__c = 'Address__c',
            City__c = 'City__c',
            Country__c = co.Id,
            Pincode__c = 54545454,
            Institution_Categories__c = 'Other'
        );
        insert acc;
        
        Investigator__c inv = new Investigator__c(
            Institution__c = acc.Id,
            Title__c= 'Mr.',
            First_Name__c = 'First_Name__c',
            Last_Name__c = 'Last_Name__c',
            Investigators_Type__c = 'Principal Investigator',
            Role__c = 'Role__c',
            Nationality__c = 'Nationality__c',
            Gender__c = 'Male',
            Email__c = 'test@gmil.com',
            Contact_Number__c = '12154545',
            Date_of_Birth__c = date.today(),
            Discipline_expertise__c = 'Discipline_expertise__c',
            ORCID_ID__c = '0000-0000-0000-0000',
            Grants__c = grantId 
        
        );
        insert inv;
        Investigator__c inv2 = new Investigator__c(
            Institution__c = acc.Id,
            Title__c= 'Mr.',
            First_Name__c = 'First_Name__c',
            Last_Name__c = 'Last_Name__c',
            Type__c = ' Programme Head',
            Role__c = 'Role__c',
            Nationality__c = 'Nationality__c',
            Gender__c = 'Male',
            Email__c = 'test@gmil.com',
            Contact_Number__c = '12154545',
            Date_of_Birth__c = date.today(),
            Discipline_expertise__c = 'Discipline_expertise__c',
            ORCID_ID__c = '0000-0000-0000-0000',
            Grants__c = grantId ,
            Is_Programme_Head__c = true
        
        );
        insert inv2;
        
        TSGForm form = TSGApplicationFormController.formInit(grantId , devRecordTypeId , null);
        TSGApplicationFormController.editGrant(grantId);
        TSGApplicationFormController.upsertInvestigator(inv);
        
        form.grantRecord.Human_participants__c = true;
        form.grantRecord.Institutional_Ethics_Committee_IEC__c = true;
        form.grantRecord.Use_of_animals__c = true;
        String json = JSON.serialize(form );
        TSGApplicationFormController.addYearApex('2020', json);
        
        TSGApplicationFormController.saveData(json, 'step1', false);
        TSGApplicationFormController.saveData(json, 'step2', false);
        TSGApplicationFormController.saveData(json, 'step3', false);
        TSGApplicationFormController.saveData(json, 'step4', false);
        TSGApplicationFormController.saveData(json, 'step5', false);
        TSGApplicationFormController.saveData(json, 'step6', false);
        TSGApplicationFormController.saveData(json, 'step7', false);
        TSGApplicationFormController.saveData(json, 'step8', false);
        TSGApplicationFormController.saveData(json, 'step9', false);
        TSGApplicationFormController.saveData(json, 'step10', false);
        TSGApplicationFormController.saveData(json, 'step11', false);
        TSGApplicationFormController.saveData(json, 'step12', false);
        TSGApplicationFormController.saveData(json, 'step13', false);
        TSGApplicationFormController.saveData(json, 'step14', false);
        TSGApplicationFormController.saveData(json, 'step15', false);
        TSGApplicationFormController.saveData(json, 'step1', true);
        
        TSGApplicationFormController.submitGrant(grantId);
        
        Grants__c  grant = new Grants__c (Status__c = 'Ineligible', Id=grantId );
        update grant;
        
        TSGApplicationFormController.pass();
    }
}