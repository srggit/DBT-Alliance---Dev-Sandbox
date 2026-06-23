@isTest
public class ICAP_AllASchemeController_Test {
    public static testmethod void sampleTest(){
        List<Scheme__c> List_scm= new List<Scheme__c>();
        Scheme__c sc= new Scheme__c();
        sc.Name='Masthan';
        sc.Type__c='IRMI RM Grant Application Form';
        insert sc;
        List_scm.add(sc);
        List<Application__c> AppList= new List<Application__c>();
        Application__c appi= new Application__c();
        appi.Name_of_applicant__c='Masthan';
        appi.Status__c='Open';
        insert appi;
        AppList.add(appi);
        ICAP_AllASchemeController.ApplicationGenerateFile(appi.Id);
        ICAP_AllASchemeController.getAllApplicationRecordTypes();
        ICAP_AllASchemeController.getAllScheme();
        ICAP_AllASchemeController.getLoadLayout(appi.Id);

    }
}