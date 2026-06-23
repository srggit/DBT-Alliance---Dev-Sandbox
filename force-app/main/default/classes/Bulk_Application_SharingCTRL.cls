public class Bulk_Application_SharingCTRL{
    public List<Option> profileList {get;set;}
    public List<Option> userList {get;set;}
    public List<Option> selectedUserOptionList {get;set;}
    public List<Grants__c> grantList {get;set;}
    public List<Option> grantOptionList {get;set;}
    public boolean profileUserNext {get;set;}
    public boolean profileSelectAll {get;set;}
    public boolean userSelectAll {get;set;}
    public boolean userSelectNextAll {get;set;}
    public boolean grantSelectAll{get;set;}
    public string recordId {get;set;}
    public void profileUserNext(){
        profileUserNext = false;
        selectedUserOptionList = new List<Option>();
        List<Option> opList = new List<Option>();
        opList.addAll(userList );
        Set<Id> userSet = new Set<Id>();
        for(Option o : opList){
            if(o.isSelected){
                if(String.isNotBlank(o.User.Id)){
                    userSet.add(o.User.Id);
                }
            }
        }
        
        List<User> selectedUserList = [SELECT Id, Name, IsActive FROM User WHERE Id IN: userSet ORDER BY Name];
        for(User  u: selectedUserList ){
            Option op = new Option();
            op.User = u;
            selectedUserOptionList.add(op);
        }
        setupGrantRecords();
        if(userSet.isEmpty()){
            profileUserNext = true;
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Please select user to continue.'));
        }
    }
    public void setupGrantRecords(){
        grantList = [SELECT Id, Name, CreatedBy.Name, Owner.Name,Reference_Number__c, (SELECT Id, Assigned_User__r.Name, CreatedDate FROM Assigned_Reviewers__r ORDER BY Assigned_User__r.Name) FROM Grants__c WHERE Status__c = 'Submitted' ORDER BY Name LIMIT 1000 ];
        grantOptionList = new List<Option>();
        for(Grants__c  g : grantList ){
            Option op = new Option();
            op.grant = g;
            grantOptionList.add(op);
        }
    }
    public void profileUserPrevious(){
        profileUserNext = true;
    }
    public void selectAllProfile(){
        for(Option o : profileList ){
            o.isSelected = profileSelectAll ;
        }
    }
    public void nSelectAllUserAction(){
        for(Option o : selectedUserOptionList){
            o.isSelected = userSelectNextAll;
        }
    }
    public void nSelectAllGrantAction(){
        for(Option o : grantOptionList ){
            o.isSelected = grantSelectAll;
        }
    }
    public void selectAllUser(){
        for(Option o : userList ){
            o.isSelected = userSelectAll;
        }
    }
    public void setupSelectAllUser(){
        userSelectAll = true;
        for(Option o : userList ){
            if(!o.isSelected) userSelectAll = false;
        }
    }
    public void nSelectUserAll(){
        userSelectNextAll = true;
        for(Option o : selectedUserOptionList){
            if(!o.isSelected) userSelectNextAll = false;
        }
    }
    public void setupSelectAllGrant(){
        grantSelectAll= true;
        for(Option o : grantOptionList ){
            if(!o.isSelected) grantSelectAll = false;
        }
    }
    
    public void assignUserSetting(){
        List<Assigned_Reviewer__c> arList = new List<Assigned_Reviewer__c>();
        List<Option> tempOption = new List<Option>();
        for(Option o : grantOptionList){
            if(o.isSelected){
                for(Option u : selectedUserOptionList){
                    if(u.isSelected){
                        arList.add(new Assigned_Reviewer__c(Assigned_User__c = u.User.Id, Grants__c = o.grant.Id));
                    }
                }
            }
        }
        for(Option u : selectedUserOptionList){
            if(!u.isSelected){
                tempOption.add(u);
            }
        }
        selectedUserOptionList = tempOption;
        if(!arList.isEmpty()){
            Database.insert(arList, false);
            if(selectedUserOptionList.isEmpty()){
                grantOptionList = new List<Option>();
                grantList = new List<Grants__c>();
                selectedUserOptionList = new List<Option>();
                profileUserNext = true;
                profileList = new List<Option>();
                userList = new List<Option>();
                Set<Id> proSet = new Set<Id>();
                for(User  u: [SELECT Id, ProfileId, Name, IsActive FROM User ORDER BY Name]){
                    Option op = new Option();
                    op.User = u;
                    userList.add(op);
                    proSet.add(u.ProfileId);
                }
                
                for(Profile pro : [SELECT Id, Name FROM Profile WHERE Id IN : proSet ORDER BY Name]){
                    Option op = new Option();
                    op.profile  = pro ;
                    profileList.add(op);
                }
            }else{
                for(Option o : grantOptionList){
                    o.isSelected = false;
                }
                setupGrantRecords();
            }
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM,'Record User Authentication/Sharing : Accepted'));
        }else{
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Please select grants/users.'));
        }
        
    }
    
    public void setupUserMenu(){
        Set<Id> proSet = new Set<Id>();
        userList = new List<Option>();
        profileSelectAll = true;
        for(Option o : profileList){
            if(o.isSelected){
                if(String.isNotBlank(o.profile.Id)){
                    proSet.add(o.profile.Id);
                }
            }else{
                profileSelectAll = false;
            }
        }
        List<User> users = [SELECT Id, ProfileId, Name, IsActive FROM User ORDER BY Name];
        for(User  u: users){
            if(proSet.contains(u.ProfileId) || proSet.isEmpty()){
                Option op = new Option();
                op.User = u;
                if(userSelectAll ) op.isSelected  = userSelectAll ;
                userList.add(op);
            }
        }
    }
    
    public Bulk_Application_SharingCTRL(){
        profileSelectAll = false;
        userSelectAll = false;
        userSelectNextAll = false;
        grantSelectAll = false;
        recordId = '';
        
        grantOptionList = new List<Option>();
        grantList = new List<Grants__c>();
        selectedUserOptionList = new List<Option>();
        profileUserNext = true;
        profileList = new List<Option>();
        userList = new List<Option>();
        Set<Id> proSet = new Set<Id>();
        for(User  u: [SELECT Id, ProfileId, Name, IsActive FROM User ORDER BY Name]){
            Option op = new Option();
            op.User = u;
            userList.add(op);
            proSet.add(u.ProfileId);
        }
        
        for(Profile pro : [SELECT Id, Name FROM Profile WHERE Id IN : proSet ORDER BY Name]){
            Option op = new Option();
            op.profile  = pro ;
            profileList.add(op);
        }
        
    }
    public class Option{
        public Boolean isSelected {get;set;}
        public User user {get;set;}
        public Profile profile {get;set;}
        public Grants__c grant{get;set;}
        
        public Option(){
            this.isSelected = false;
            this.user = new User ();
            this.profile = new Profile ();
            this.grant = new Grants__c ();
        }
    }
    
    public void apexDeleteRecord(){
        if(string.isNotBlank(recordId)){
            Id id = recordId;
            String ObjectName = id.getSObjectType()+'';
            sObject sObj = Schema.getGlobalDescribe().get(ObjectName).newSObject() ;
            sObj.put('Id',recordId);
            database.delete(sObj, false);
            
            recordId = '';
        }
        setupGrantRecords();
    }
}