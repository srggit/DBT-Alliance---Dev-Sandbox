public class PeerReviewerApprovalVFController{
public boolean accept {get;set;}
public string reviewRecordId ;
public string submitErrorMessage {get;set;}
public boolean isAccepted {get;set;}
    
    public PeerReviewerApprovalVFController(){
        reviewRecordId = ApexPages.currentPage().getParameters().get('id');
        
        List<Peer_Reviewer__c> Peer_ReviewerList = [SELECT Id, Name, Declined__c , First_Name__c, Last_Name__c, Full_Name__c, Email__c, Created_User__c, Designation__c, Is_User_Created__c, Verified_by_User__c, Grant_Id_Selected__c FROM Peer_Reviewer__c WHERE Id = : reviewRecordId];
        isAccepted = true;
        if(!Peer_ReviewerList.isEmpty()){
            isAccepted = Peer_ReviewerList.get(0).Is_User_Created__c || Peer_ReviewerList.get(0).Declined__c ;
        }
    }
    public void declined(){
        update new Peer_Reviewer__c(Id=reviewRecordId, Declined__c = true);
        isAccepted = true;
    }
    public void acceptTerms(){
        try{
            List<Peer_Reviewer__c> Peer_ReviewerList = [SELECT Id, Name, Declined__c ,First_Name__c, Last_Name__c, Full_Name__c, Email__c, Created_User__c, Designation__c, Is_User_Created__c, Verified_by_User__c, Grant_Id_Selected__c FROM Peer_Reviewer__c WHERE Id = : reviewRecordId];
            List<Profile> profileList = [SELECT Id FROM Profile WHERE Name = : Label.Peer_Reviewer_Profile_Name];
            List<Assigned_Reviewer__c > shareList = new List<Assigned_Reviewer__c >();
            if(!profileList.isEmpty()){
                if(!Peer_ReviewerList.isEmpty()){
                    Peer_Reviewer__c pr = Peer_ReviewerList.get(0);
                    contact con = null;
                    if(Label.Is_Portal_Peer_Reviewer_Profile == 'true'){
                        List<Contact> contacts = [SELECT Id FROM Contact WHERE Email =: pr.Email__c AND FirstName =: pr.First_Name__c AND LastName =: pr.Last_Name__c];
                        if(!contacts.isEmpty()){
                            con = contacts.get(0);
                        }else{
                            con  = new Contact(
                                Email = pr.Email__c,
                                FirstName = pr.First_Name__c,
                                LastName = pr.Last_Name__c
                            );
                            if(!Test.isRunningTest() ) insert con  ;
                        }
                    }
                    
                    User userRegistration = new User();
                    userRegistration.Email = pr.Email__c;
                    userRegistration.FirstName = pr.First_Name__c;
                    userRegistration.LastName = pr.Last_Name__c;
                    userRegistration.Username = pr.Email__c;
                    userRegistration.profileId = profileList.get(0).Id;
                    userRegistration.Alias = 'IAIN';
                    userRegistration.EmailEncodingKey='UTF-8';
                    userRegistration.LanguageLocaleKey='en_US';
                    userRegistration.LocaleSidKey='en_US';
                    userRegistration.TimeZoneSidKey='Asia/Kolkata';
                    if(con != null) userRegistration.ContactId=con.Id; userRegistration.communityNickname = pr.Last_Name__c + '_' + Math.random();

                    if(!Test.isRunningTest() ) Database.insert(userRegistration);
                    
                    pr.Created_User__c = userRegistration.Id;
                    pr.Verified_by_User__c = true;
                    update pr;
                    
                    string userId = userRegistration.Id;
                    List<String> grantIdList = pr.Grant_Id_Selected__c != null ? pr.Grant_Id_Selected__c.split(';') : new List<String>();
                    if(!grantIdList.isEmpty()){
                        for(String id : grantIdList){
                            Assigned_Reviewer__c sRd = new Assigned_Reviewer__c(Assigned_User__c = userId , Grants__c = id);
                            shareList.add(sRd);
                        }
                        
                        if(!shareList.isEmpty()) database.insert(shareList, false);
                    }
                    if(!Test.isRunningTest() ) System.resetPassword(Id.valueOf(userId), true);
                    isAccepted = true;
                }
            }
        }catch(Exception e){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,e.getMessage()));
        }
    }
}