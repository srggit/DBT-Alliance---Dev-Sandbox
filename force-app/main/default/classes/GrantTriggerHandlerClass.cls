public class GrantTriggerHandlerClass {
    public static void sendEmailOnStatusChange(List<Grants__c> newGrantsList, Map<Id, Grants__c> oldGrantsMap) {
        Map<String, List<Grants__c>> mapOfStatusWithGrants = new Map<String, List<Grants__c>>();
        Set<Id> grantIdsToSendEmail = new Set<Id>();
        for(Grants__c newGrant : newGrantsList) {
            if(newGrant.Status__c != oldGrantsMap.get(newGrant.Id).Status__c && (newGrant.Status__c == 'Ineligible' || newGrant.Status__c == 'Decline')) {
                if(!mapOfStatusWithGrants.containsKey(newGrant.Status__c)) {
                    mapOfStatusWithGrants.put(newGrant.Status__c, new List<Grants__C>());
                    grantIdsToSendEmail.add(newGrant.Id);
                }
                mapOfStatusWithGrants.get(newGrant.Status__c).add(newGrant);
            }
        }
        if(mapOfStatusWithGrants.size() > 0) {
            sendEmail(mapOfStatusWithGrants, grantIdsToSendEmail);
        }
    }
    
    private static void sendEmail(Map<String, List<Grants__c>> mapOfStatusWithGrants, Set<Id> grantIds) {
        Map<Id, List<Investigator__c>> mapOfGrantWithInvestigators = new Map<Id, List<Investigator__c>>();
        for(Investigator__c investigator : [Select Grants__c, Investigators_Type__c, Email__c, Full_Name__c, Designation__c, Title__c, Institution__r.Name from Investigator__c where Grants__c IN: grantIds AND Email__c != null]) {
            if(!mapOfGrantWithInvestigators.containsKey(investigator.Grants__c)) {
                mapOfGrantWithInvestigators.put(investigator.Grants__c, new List<Investigator__c>());
            }
            mapOfGrantWithInvestigators.get(investigator.Grants__c).add(investigator);
        }
        List<Messaging.SingleEmailMessage> listOfEmails = new List<Messaging.SingleEmailMessage>();
        Messaging.SingleEmailMessage statusEmail;
        List<String> toEmailAddress;
        List<String> ccEmailAddress;
        Boolean firstPI;
        String headerURL = getDocumentRelativeLink('Email Header');
        String footerURL = getDocumentRelativeLink('Email Footer');
        system.debug('URL'+footerURL);
        system.debug('Footer URL'+headerURL);
        for(String grantStatus : mapOfStatusWithGrants.keySet()) {
            toEmailAddress = new List<String>();
            ccEmailAddress = new List<String>();
            statusEmail = new Messaging.SingleEmailMessage();
            statusEmail.setSubject('Grant '+ grantStatus);
            String emailBody;
            for(Grants__c currentGrant : mapOfStatusWithGrants.get(grantStatus)) {
                firstPI = false;
                for(Investigator__c investigator : mapOfGrantWithInvestigators.get(currentGrant.Id)) {
                    if(investigator.Investigators_Type__c == 'Principal Investigator' && !firstPI) {
                        firstPI = true;
                        emailBody = '<table><tr><td colspan="2" style="text-align:right"><img src="' + headerURL + '"/></td></tr>';
                        emailBody += '<tr><td colspan="2"><b><u>Private and Confidential</u></b></td></tr>';
                        emailBody += '<tr><td style="text-align:left;width:75%"><b>Dr. '+ investigator.Full_Name__c + '<br/>' + investigator.Designation__c + '<br/>' + investigator.Institution__r.Name +'</b></td>';
                        emailBody += '<td style="text-align:right;">E-mail: team.science@indiaalliance.org<br/>Tel: Hyd: +91 040 4018 9445<br/>New Del: +91 011 4100 8403<br/><b>Grant Ref:'+ currentGrant.Reference_Number__c +'<br/>' + Date.today() + '</b</td></tr></table>';
                        emailBody += '<br/><br/><b>Dear Dr ' + investigator.Full_Name__c + '<br/><br/>' + investigator.Title__c + '</b>';
                        if(grantStatus == 'Ineligible') {
                            emailBody += '<br/><br/>DBT/ Wellcome Trust India Alliance’s Committee has considered your application for a Team Science Grant. We regret to inform you that your application has not been shortlisted to the next stage in this competition.';
                            emailBody += '<br/><br/>The Round received many high-quality submissions and the selection process was very competitive. We regret to notify you that you did not meet all the eligibility criteria provided for the call, therefore, your application did not proceed to the review stage.';
                            emailBody += '<br/><br/>We thank you for your interest in this program and appreciate the significant amount of work that you put in preparing your application. If you wish, as per India Alliance policy, you may reapply in a future TSG competition.';
                            emailBody += '<br/><br/>Please inform the other team members on this grant of this decision. We would not be writing to them individually.';
                            emailBody += '<br/><br/>We wish you success in your future endeavours.<br/><br/>With best wishes<br/><br/>Team TSG<br/>India Alliance';
                        }
                        else if(grantStatus == 'Decline') {
                            emailBody += '<br/><br/>Thank you and your team (DELETE \'and your team\' if not applicable) for interviewing with the DBT/ Wellcome Trust India Alliance’s Grants Funding Committee for a Team Science Grant OR Clinical/Public Health Research Centre Grant. As informed earlier, your application was not successful.';
                            emailBody += '<br/><br/>The Committee assessed your application based on its own merit, assessments from reviewers, your interview with the Committee and in competition with other applications received in the cohort. Reviewers have identified both strengths and weaknesses of your proposal, which we hope you will find useful. These comments are being shared with you in the attached document.';
                            emailBody += '<br/><br/>We are unable to discuss the shared reviewers’ comments or the Committee’s decision any further.';
                            emailBody += '<br/><br/>Please be aware of our resubmission policy. As your proposal has been unsuccessful after the Funding Committee review, it cannot be re-submitted to the scheme. Please also note that you cannot re-apply to the scheme as the Lead Principal Investigator (LPI). However, you may apply as a Principal Investigator (PI) in any future round.';
                            emailBody += '<br/><br/><br/>We wish you success in your future endeavors.';
                            emailBody += '<br/><br/>Yours sincerely,<br/>India Alliance';
                        }
                        emailBody += '<br/><br/><center><img src="' + footerURL + '"/></center>';
                    }
                    if(investigator.Investigators_Type__c == 'Principal Investigator') {
                        toEmailAddress.add(investigator.Email__c);
                    }
                    else if(grantStatus == 'Decline'){
                        ccEmailAddress.add(investigator.Email__c);
                    }
                }
            }
            if(toEmailAddress.size() > 0) {
                statusEmail.setHtmlBody(emailBody);
                statusEmail.setToAddresses(toEmailAddress);
                listOfEmails.add(statusEmail);
            }
        }
        if(listOfEmails.size() > 0) {
            Messaging.sendEmail(listOfEmails);
        }
    }
   
    public Static String getDocumentRelativeLink(String documentName){
        String documentURL= '';
        try{
            list<Document> doc = [Select id,Name,SystemModStamp From Document Where Name  = :documentName];
            ID docIds = doc[0].id;
            documentURL = URL.getSalesforceBaseUrl().getProtocol()+'://'+System.URL.getSalesforceBaseUrl().getHost().remove('-api' )+'/servlet/servlet.ImageServer?id='+docIds+'&oid='+userinfo.getorganizationid();
        }Catch(Exception ex){}
        return documentURL ;
    }
}