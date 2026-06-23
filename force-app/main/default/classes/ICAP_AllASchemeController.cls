public class ICAP_AllASchemeController{
     
    @AuraEnabled
    public static List<Scheme__c> getAllScheme(){
        Date today = Date.Today();
        return [SELECT Id, OwnerId, Name, CreatedDate, CreatedById, Type__c, Outcome__c, Total_Requested_Amount__c, Approval_Committee__c, Award_Date__c, Finance_Reference__c, Original_Award__c, Adjustments__c, Current_Award__c, Start_Date__c, Close_Date__c, End_Date__c, Approved_Duration__c, Current_Duration__c, Extension__c, Is_Suspended__c, Contract_Is_Invalid__c, Contract_Signed_On__c, Is_Frozen__c, Payment_Schedule_Is_Invalid__c, Payments_Due__c, Active_Transactions__c, Comments__c, Status__c FROM Scheme__c WHERE Status__c = 'Open' AND End_Date__c >=: today ];
    }
    
    @AuraEnabled
    public static List<RecordTypeWrp> getAllApplicationRecordTypes(){
        List<RecordTypeWrp> rtList = new List<RecordTypeWrp>();
        for(RecordType  rt : [SELECT Id, Name, DeveloperName, SobjectType FROM RecordType where SobjectType IN ('Application__c','Grants__c') AND IsActive = true]){
            rtList.add(new RecordTypeWrp(rt));
        }
        
        return rtList ;
    }           
    
    /*@AuraEnabled
    public static boolean submitApplication(String recordId){
        List<Application__c> applications = [SELECT Id,Applicant_Number__c,RecordType.Name FROM Application__c WHERE Id = : recordId AND (Status__c IN ('Open','Pre-Submission','Post-Submission','Awaited Signatory Approval','Pending Submission','Submission Failed') OR Status__c = null)];
        if(applications != null && applications.size() > 0){
            Application__c app = new Application__c(Id = recordId, Status__c = 'Submitted');
            string readOnlyRT = '';
            try{
               readOnlyRT = Schema.SObjectType.Application__c.getRecordTypeInfosByName().get(applications.get(0).RecordType.Name+' - Read Only').getRecordTypeId();
            }catch(exception e){readOnlyRT = '';}
            
            if(readOnlyRT != '') app.RecordTypeId = readOnlyRT ;
            update app;
            return true;
        }
        return false;
    }*/
    @AuraEnabled
    public static boolean ApplicationGenerateFile(String recordId){
        //try{
            List<Application__c> applications = [SELECT Id,Applicant_Number__c FROM Application__c WHERE Id = : recordId AND Status__c IN ('Open','Pre-Submission','Post-Submission','Awaited Signatory Approval','Pending Submission','Submission Failed')];
            
          //  if(applications != null && applications.size() == 0){
               // applications = [SELECT Id,Applicant_Number__c FROM Application__c WHERE Id = : recordId];
                if(applications != null && applications.size() > 0){
                    PageReference pdfToBeGenerated = new Pagereference('/apex/ApplicationReportPDF?id='+recordId);
                    
                    ContentVersion fileToattach1 = new ContentVersion(); 
                    fileToattach1.ContentLocation = 'S'; 
                    fileToattach1.PathOnClient = applications.get(0).Applicant_Number__c + ' :  '+ Date.Today()+'.pdf'; 
                    fileToattach1.Origin = 'H'; 
                    fileToattach1.Title = applications.get(0).Applicant_Number__c + ' :  '+ Date.Today();
                    if(!Test.isRunningTest()){
                    fileToattach1.VersionData = pdfToBeGenerated.getContent(); 
                    }
                    else{
                         fileToattach1.VersionData =blob.valueOf('Test'); }
                    insert fileToattach1;
                    
                    ContentVersion contentDocIdOfFileAttached1 = [select ContentDocumentId from ContentVersion where Id =: fileToattach1.Id LIMIT 1]; 
                    ContentDocumentLink contentDocLink1 = new ContentDocumentLink(LinkedEntityId = applications.get(0).Id, ContentDocumentId = contentDocIdOfFileAttached1.ContentDocumentId, ShareType = 'I'); 
                    
                    insert contentDocLink1;
                    return true;
                }
           // }
        //}catch(Exception e){return false;}
        return false;
    }

    /*@AuraEnabled
    public static boolean isApplicationSubmitted(String recordId){
        List<Application__c> applications = [SELECT Id FROM Application__c WHERE Id = : recordId AND Status__c IN ('Open','Pre-Submission','Post-Submission','Awaited Signatory Approval','Pending Submission','Submission Failed')];
        if(applications != null && applications.size() > 0){
            return true;
        }
        return false;
    }*/
    
    @AuraEnabled
    public static RecordTypeLayout getLoadLayout(String recordTypeId){
        RecordTypeLayout rtObj = new RecordTypeLayout();
        /*List<Metadata.Metadata> layouts = 
        Metadata.Operations.retrieve(Metadata.MetadataType.Layout, new List<String> {'Application__c-IRMIRM Grant Application Form'});

        Metadata.Layout layoutMd = (Metadata.Layout)layouts.get(0);
        for (Metadata.LayoutSection section : layoutMd.layoutSections) {
            for (Metadata.LayoutColumn column : section.layoutColumns) {
                if (column.layoutItems != null) {
                    for (Metadata.LayoutItem item : column.layoutItems) {
                        if(item.behavior+'' != 'Readonly'){
                            rtObj.fields.add(item.field);
                        }
                    }
                }
            }
        }*/
        return rtObj;
    }
    public class RecordTypeLayout{
        @AuraEnabled
        public List<String> fields ;
        @AuraEnabled
        public Application__c application;
        @AuraEnabled
        public User user;
       
        
        public RecordTypeLayout(){
            fields = new List<String>();
            application = new Application__c ();
            user = [SELECT Id, Username, LastName, FirstName, MiddleName, Suffix, Name, CompanyName, Division, Department, Title, Street, City, State, PostalCode, Country, Latitude, Longitude, GeocodeAccuracy, Address, Email, Title__c, Email__c, First_Name__c, Last_Name__c, Date_of_Birth__c, Gender__c, Expertise__c, Position__c, Department__c, Organisation__c, Address__c, City__c, Postal_Code__c, Country__c, International_Dialing_Code__c, Phone__c, Nationality__c, User_Contact_Number__c, Countries__c, Organisation_Id__c FROM User WHERE Id =: userinfo.getuserid()];
        }
        
    }
    
    public class RecordTypeWrp{
        @AuraEnabled
        public string name;
        @AuraEnabled
        public boolean isExistApplication;
        @AuraEnabled
        public string dName;
        @AuraEnabled
        public string rId;
        @AuraEnabled
        public string sObjectName;
       
        public RecordTypeWrp(){}
        public RecordTypeWrp(RecordType  rt){
            this.name = rt.Name;
            this.dName = rt.DeveloperName ;
            this.rId = rt.Id;
            this.sObjectName = rt.SobjectType;
        }
    }
}