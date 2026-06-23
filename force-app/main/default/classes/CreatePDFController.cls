public class CreatePDFController{
    
    @AuraEnabled
    public static boolean createApplicationPDF(String recordId){
        if(String.isNotBlank(recordId)){
            Application_PDFs__c pdf = new Application_PDFs__c(Grants__c = recordId);
            insert pdf;
            String pdfRecordId = pdf.Id;
            TSGForm form = new TSGForm(recordId);
            List<ContentDocumentLink> conList = [SELECT ContentDocumentId,ContentDocument.Title,ContentDocument.ContentModifiedDate, ContentDocument.ContentSize FROM ContentDocumentLink WHERE ContentDocumentId=:form.contentDocumentIdList];
            List<ContentDocumentLink> conClone = new List<ContentDocumentLink>();
            for(ContentDocumentLink file: conList){
                ContentDocumentLink newclnk = file.clone();
                newclnk.LinkedEntityId = pdfRecordId;
                newclnk.ShareType = 'V';
                conClone.add(newclnk);
            }
            
            database.insert(conClone, false);
            
            PageReference pref = page.GrantApplicationPDF;
            pref.getParameters().put('id',recordId);
            blob pdfBlob;
            if(!test.isRunningTest()) pdfBlob = pref.getContent(); 
            ContentVersion conVer = new ContentVersion();
            conVer.ContentLocation = 'S';
            conVer.PathOnClient = form.grantRecord.Reference_Number__c+'.pdf';
            conVer.Title = form.grantRecord.Reference_Number__c;
            conVer.VersionData = pdfBlob;
            if(!test.isRunningTest()) insert conVer; 
            
            Id conDoc2;
            if(!test.isRunningTest()) conDoc2 = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:conVer.Id].ContentDocumentId;
            ContentDocumentLink conDocLink = New ContentDocumentLink();
            conDocLink.LinkedEntityId = pdfRecordId;
            conDocLink.ContentDocumentId = conDoc2;
            conDocLink.shareType = 'V';
            if(!test.isRunningTest()) insert conDocLink;
        }
        system.debug('Enter in method');
        return false;
    }
    @AuraEnabled
    public static boolean createApplicationPDFBySite(String recordId){
        if(String.isNotBlank(recordId)){
            List<Grants__c> grantList = [SELECT Id,Is_Admin__c,Is_PDF_Generated__c FROM Grants__c WHERE Id =: recordId];
            if(!grantList.isEmpty()){
                grantList[0].Generated_pdf_URL__c = '';
                grantList[0].Is_Admin__c = true;
                update grantList;
                Id batchJobId = Database.executeBatch(new BatchCreateGrantPDF(recordId), 1);
                return true;
            }
        }
        system.debug('Enter in method');
        return false;
    }
    @AuraEnabled
    public static boolean createApplicationPDFBySiteApplicant(String recordId){
        if(String.isNotBlank(recordId)){
            List<Grants__c> grantList = [SELECT Id,Is_Admin__c,Is_PDF_Generated__c FROM Grants__c WHERE Id =: recordId];
            if(!grantList.isEmpty()){
                grantList[0].Applicant_PDF_URL__c = '';
                grantList[0].Is_Admin__c = false;
                update grantList;
                Id batchJobId = Database.executeBatch(new BatchCreateGrantPDF(recordId), 1);
                return true;
            }
        }
        return false;
    }
}