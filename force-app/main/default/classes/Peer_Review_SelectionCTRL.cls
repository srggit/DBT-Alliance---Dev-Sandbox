public without sharing class Peer_Review_SelectionCTRL{
public string selectedTemplate {get;set;}  
public string selectedPeerReviewerId {get;set;}   
public List<Option> peerReviewerOption {get;set;}
public Boolean isNext{get;set;}
public Boolean nextTemplateView{get;set;}
public Boolean nextGrantView{get;set;}
public List<SelectOption> selectOptionPeerReviewer{get;set;}
public string searchGrantName{get;set;}
public Set<Grants__c> selectedGrantSet = new  Set<Grants__c>();
public List<Option> grantRecordList {get;set;}
public String selectedGrantId = '';

    public Peer_Review_SelectionCTRL(){
        isNext = false;
        nextTemplateView = false;
        nextGrantView = false;
        peerReviewerOption = new List<Option>();
        List<Peer_Reviewer__c> PeerReviewerList = [SELECT Id, Name, First_Name__c, Last_Name__c, Full_Name__c, Email__c, Designation__c, Created_User__c, Is_User_Created__c, Verified_by_User__c, Grant_Id_Selected__c, Grants__c FROM Peer_Reviewer__c WHERE Is_User_Created__c = false];
        for(Peer_Reviewer__c pr: PeerReviewerList ){
            peerReviewerOption.add(new Option(pr));
        }
    }

    public List<SelectOption> getTemplates() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('','None'));
        for(EmailTemplate et : [SELECT Id, Name, FolderName, IsActive FROM EmailTemplate WHERE IsActive = true Order By Name]){
            options.add(new SelectOption(et.Id,et.Name));
        }
        
        return options;
    }
    public void fatchGrantRecords() {
        grantRecordList = new List<Option>();
        List<Grants__c> grantRecordListTemp = new List<Grants__c>();
        if(string.isNotBlank(searchGrantName)){
            string str = '%'+searchGrantName+'%'; 
            grantRecordListTemp = [SELECT Id, Name, Owner.Name FROM Grants__c WHERE Name LIKE : str OR Owner.Name LIKE : str ORDER By Name LIMIT 1000];
        }else{
           grantRecordListTemp = [SELECT Id, Name, Owner.Name FROM Grants__c ORDER By Name LIMIT 1000];
        }
        system.debug('grantRecordListTemp  '+grantRecordListTemp );
        for(Grants__c g: grantRecordListTemp ){
            grantRecordList.add(new Option(g));
        }
    }
    
    public void selectGrantRecord(){
        for(Option op: grantRecordList){
        
        }
    }
    
    public void previous(){
        isNext = false;
    }
    
    public void previousToTemplateView(){
        nextTemplateView = false;
        nextGrantView = true;
    }
    
    public void changeEvent(){
    
    }
    public void changeEventNext(){
        for(Option pr: peerReviewerOption){
            if(pr.isSelected){
                Messaging.SingleEmailMessage email  = Messaging.renderStoredEmailTemplate(selectedTemplate, null, pr.Peer_Reviewer.Id);
                pr.emailSubject = email.getSubject();
                pr.emailBody = email.getHtmlBody();
            }
        }
        nextTemplateView = true;
        nextGrantView = false;
    }
    
    public void nextToTemplateView(){
        List<String> gIdList = new List<String>();
        for(Option o : grantRecordList){
            if(o.IsSelected) gIdList.add(o.grant.Id);
        }
        if(gIdList.size() == 0){ ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'You have to select any grant Record.'));  return; }
        if(gIdList.size() > 1){  ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'Not allowed to select more then one.')); return; }
        
        selectedGrantId = string.Join(gIdList, ';');
        
        List<Peer_Reviewer__c> updatePeer = new List<Peer_Reviewer__c>();
        for(Option pr: peerReviewerOption){
            if(pr.isSelected){
                pr.Peer_Reviewer.Grant_Id_Selected__c = selectedGrantId ; 
                pr.Peer_Reviewer.Grants__c = selectedGrantId ;
                updatePeer.add(pr.Peer_Reviewer);
            }
        }
        database.update(updatePeer, false);
    }
    
    public void submitAll(){
        List<EmailTemplate > etList = [SELECT Id, Name, Subject, FolderName, IsActive FROM EmailTemplate WHERE Id =: selectedTemplate];
        if(!etList.isEmpty()){
            EmailTemplate t = etList.get(0);
            List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
            List<Peer_Reviewer__c> Peer_ReviewerList = new List<Peer_Reviewer__c>();
            for(Option op : peerReviewerOption){
                if(op.isSelected){
                    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                    email.setSaveAsActivity(false);
                    email.setWhatId(selectedPeerReviewerId );
                    email.setSubject(op.emailSubject);
                    email.setToAddresses(new List<String>{op.Peer_Reviewer.Email__c});
                    email.setHtmlBody(op.emailBody);
                    Peer_ReviewerList.add(op.Peer_Reviewer);
                    mails.add(email);
                }
            }
            if(!mails.isEMpty()) Messaging.SendEmailResult [] r = Messaging.sendEmail(mails);
            if(!Peer_ReviewerList.isEmpty()) update Peer_ReviewerList;
            
            isNext = false;
            nextTemplateView = false;
            nextGrantView = false;
            peerReviewerOption = new List<Option>();
            List<Peer_Reviewer__c> PeerReviewerList = [SELECT Id, Name, First_Name__c, Last_Name__c, Full_Name__c, Email__c, Designation__c, Created_User__c, Is_User_Created__c, Grant_Id_Selected__c, Verified_by_User__c, Grants__c FROM Peer_Reviewer__c WHERE Is_User_Created__c = false];
            for(Peer_Reviewer__c pr: PeerReviewerList ){
                peerReviewerOption.add(new Option(pr));
            }
        }
    }
    public void submit(){
        List<EmailTemplate > etList = [SELECT Id, Name, Subject, FolderName, IsActive FROM EmailTemplate WHERE Id =: selectedTemplate];
        if(!etList.isEmpty()){
            EmailTemplate t = etList.get(0);
            
            selectOptionPeerReviewer = new List<SelectOption>();
            String revId = selectedPeerReviewerId ;
            selectedPeerReviewerId = null;
            for(Option op : peerReviewerOption){
                if(op.Peer_Reviewer.Id == revId ){
                    
                    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                    email.setSaveAsActivity(false);
                    email.setWhatId(selectedPeerReviewerId );
                    email.setSubject(op.emailSubject);
                    email.setToAddresses(new List<String>{op.Peer_Reviewer.Email__c});
                    email.setHtmlBody(op.emailBody);
                    
                    if(!Test.isRunningTest()) Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
                    update op.Peer_Reviewer;
                }
                
                if(op.isSelected && op.Peer_Reviewer.Id != revId ){
                    if(selectedPeerReviewerId == null) selectedPeerReviewerId = op.Peer_Reviewer.Id;
                    selectOptionPeerReviewer.add(new SelectOption(op.Peer_Reviewer.Id,op.Peer_Reviewer.Full_Name__c));
                }
            }
            if(selectOptionPeerReviewer.isEmpty()){
                isNext = false;
                nextTemplateView = false;
                nextGrantView = false;
                peerReviewerOption = new List<Option>();
                List<Peer_Reviewer__c> PeerReviewerList = [SELECT Id, Name, First_Name__c, Last_Name__c, Full_Name__c, Email__c, Designation__c, Created_User__c, Is_User_Created__c, Grant_Id_Selected__c, Verified_by_User__c, Grants__c FROM Peer_Reviewer__c WHERE Is_User_Created__c = false];
                for(Peer_Reviewer__c pr: PeerReviewerList ){
                    peerReviewerOption.add(new Option(pr));
                }
            }
        }
    }
    
    public void next(){
        fatchGrantRecords();
        selectedPeerReviewerId = null;
        selectOptionPeerReviewer = new List<SelectOption>();
        if(String.isBlank(selectedTemplate)){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'Template not selected, please select template to continue'));
            return;
        }
        boolean anySelected = false;
        for(Option op : peerReviewerOption ){
            if(op.isSelected){
                Messaging.SingleEmailMessage email  = Messaging.renderStoredEmailTemplate(selectedTemplate, null, op.Peer_Reviewer.Id);
                op.emailSubject = email.getSubject();
                op.emailBody = email.getHtmlBody();
                anySelected = true;
                
                if(selectedPeerReviewerId == null) selectedPeerReviewerId = op.Peer_Reviewer.Id;
                selectOptionPeerReviewer.add(new SelectOption(op.Peer_Reviewer.Id,op.Peer_Reviewer.Full_Name__c));
            }
        }
        if(anySelected){
            isNext = true;
            nextGrantView = true;
        }else{
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'You have to select any peer reviewer.'));
        }
    }
    
    public class Option{
        public Peer_Reviewer__c Peer_Reviewer {get;set;}
        public boolean isSelected {get;set;}
        public String emailBody{get;set;}
        public String emailSubject{get;set;}
        public Grants__c grant{get;set;}
        public Option(Peer_Reviewer__c Peer_Reviewer){
            this.Peer_Reviewer = Peer_Reviewer;
            this.isSelected = false;
        }
        public Option(Grants__c grant){
            this.grant = grant;
            this.isSelected = false;
        }
    }
}