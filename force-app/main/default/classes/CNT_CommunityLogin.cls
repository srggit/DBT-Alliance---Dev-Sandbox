public class CNT_CommunityLogin {
    public String username {get;set;}
    public String password {get;set;}
    public Boolean showLoginError {get;set;}
    public Boolean rememberMe {get;set;}
    
    public String email {get;set;}
    public String confirmEmail {get;set;}
    public Boolean showRegisterError {get;set;}
    public String registerErrorMessage {get;set;}
    
    public User userRegistration {get;set;}
    public String userLastName {get;set;}
    public String userPassword {get;set;}
    public String usrName {get;set;}
    public Boolean showUserCreationError {get;set;}
    public String userCreationErrorMessage {get;set;}
    public String dob{get;set;}
    
    public Boolean termsAndConditions {get;set;}
    public Boolean showSubmitError {get;set;}
    public String submitErrorMessage {get;set;}
    
    public Boolean showLoginSection {get;set;}
    public Boolean showRegisterSection {get;set;}
    public Boolean showRegisterationSection {get;set;}
    public Boolean showSubmitSection {get;set;}
    
    public CNT_CommunityLogin() {
        showLoginError = false;
        rememberMe = false;
        showRegisterError = false;
        
        userRegistration = new User();
        showUserCreationError = false;
        
        termsAndConditions = false;
        showSubmitError = false;
        
        showLoginSection = true;
        showRegisterSection = false;
        showRegisterationSection = false;
        showSubmitSection = false;
        dob = system.now().format('MM-dd-YYYY');
    }
    
    public PageReference login(){
        String startUrl = System.currentPageReference().getParameters().get('startURL');
        system.debug('Start URL ==' + startUrl);
        PageReference landingPage = Site.login(username, password, null);
        system.debug('Landing Page =====' + landingPage);
        if(landingPage == null) {
            showLoginError = true;
        }
        system.debug('showLoginError' + showLoginError);
        
        if(showLoginError) {
            return null;
        }
        else {
            return landingPage;
        }
    }
    
    public PageReference register(){
        //system.assert(false,'Here');
        showLoginSection = false;
        showRegisterSection = true;
        return null;
    }
    
    public PageReference previous() {
        showLoginSection = false;
        showRegisterSection = false;
        showSubmitSection = false;
        showRegisterationSection = true;
        return null;
    }
    public PageReference next(){
        usrName = email ;
        if(email == '' || email == null || confirmEmail == '' || confirmEmail == null) {
            registerErrorMessage = 'Required fields are missing';
            showRegisterError = true;
        }
        else if(email != confirmEmail) {
            registerErrorMessage = 'Email and confirm email does not match';
            showRegisterError = true;
        }
        else if(!validateEmail(email)) {
            registerErrorMessage = 'Invalid email address';
            showRegisterError = true;
        }
        else {
            showLoginSection = false;
            showRegisterSection = false;
            showRegisterationSection = true;
        }
        return null;
    }
    
    public PageReference clear(){
        email = '';
        confirmEmail = '';
        return null;
    }
    
    public PageReference clearUserDetails(){
        userLastName = '';
        userRegistration = new User();
        return null;
    }
    
    public PageReference cancel(){
        showLoginSection = true;
        showRegisterSection = false;
        showRegisterationSection = false;
        showSubmitSection = false;
        
        username = '';
        password = '';
        showLoginError = false;
        email = '';
        confirmEmail = '';
        showRegisterError = false;
        registerErrorMessage = '';
        userRegistration = new User();
        showUserCreationError = false;
        
        termsAndConditions = false;
        showSubmitError = false;
        
        return null;
    }
    
    public PageReference nextToSubmit(){
        Integer minYears = 17;
        userPassword = 'as12cd3@123';
        
        if(string.isNotBlank(dob)) userRegistration.Date_of_Birth__c = Date.ValueOf(dob);
        System.debug(userRegistration);
        if(userRegistration.Title__c == '' || userRegistration.Title__c== null ||
           userRegistration.FirstName == '' || userRegistration.FirstName == null ||
           userLastName == '' || userLastName == null ||
           userRegistration.Date_of_Birth__c == null ||
           userRegistration.Nationality__c == '' || userRegistration.Nationality__c == null ||
           userRegistration.Expertise__c == '' || userRegistration.Expertise__c == null ||
           userRegistration.Position__c == '' || userRegistration.Position__c == null ||
           userRegistration.Department__c == '' || userRegistration.Department__c == null ||
           userRegistration.Gender__c == '' || userRegistration.Gender__c == null ||
           //userRegistration.Organisation__c == '' || userRegistration.Organisation__c == null ||
           userRegistration.Address__c == '' || userRegistration.Address__c == null ||
           userRegistration.City__c == '' || userRegistration.City__c == null ||
           userRegistration.Countries__c == '' || userRegistration.Countries__c == null ||
           userRegistration.Postal_Code__c == '' || userRegistration.Postal_Code__c == null ||
           userRegistration.International_Dialing_Code__c  == null ||
           userRegistration.Phone == '' || userRegistration.Phone == null) {
               userCreationErrorMessage = 'Required fields are missing';
               showUserCreationError = true;
        }else if(userRegistration.Date_of_Birth__c != null && userRegistration.Date_of_Birth__c > Date.Today().addYears(-(minYears))){
           userCreationErrorMessage = 'Required age above '+System.now().addYears(-(minYears)).format('dd/MM/YYYY');
           showUserCreationError = true;
        }else {
            showRegisterationSection = false;
            showSubmitSection = true;
        }
        system.debug('userRegistration.Date_of_Birth__c '+userRegistration.Date_of_Birth__c);
        return null;
    }
    
    public PageReference submit(){
        if(!termsAndConditions) {
            showSubmitError = true;
            submitErrorMessage = 'Please accept the terms and conditions';
        } else {
            showSubmitError = false;
        }
        if(!showSubmitError) {
            String profileId = null; // To be filled in by customer.
            String roleEnum = null; // To be filled in by customer.
            String accountId = ''; // To be filled in by customer.
            
            userRegistration.CommunityNickname = userRegistration.FirstName + userLastName;
            
            //userRegistration.ProfileId = [Select id from profile where name = :userRegistration.Form_Type__c].Id;
            userRegistration.Email = email;
            userRegistration.LastName = userLastName;
            userRegistration.Username = usrName;
            String userId;
            
            try {
                userId = Site.createExternalUser(userRegistration, accountId, password);
            } catch(Site.ExternalUserCreateException ex) {
                List<String> errors = ex.getDisplayMessages();
                for (String error : errors)  {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, error));
                }
                
                // This message is used for debugging. Do not display this in the UI to the end user.
                // It has the information around why the user creation failed.
                System.debug(ex.getMessage());
                if(ex.getMessage().contains('nickname')) {
                    submitErrorMessage = 'User already exists with this email. Please use different email to register.';
                }
                else {
                	submitErrorMessage = ex.getMessage();
                }
                showSubmitError = true;
            }
            if (userId != null && !showSubmitError) { 
                PageReference page = System.Page.CommunitiesSelfRegConfirm;
                page.setRedirect(true);
                return page;
            }
            /*if (userId != null) { 
                if (password != null && password.length() > 1) {
                    return Site.login(userName, password, '/CommunitiesLanding');
                }
                else {
                    PageReference page = System.Page.CommunitiesSelfRegConfirm;
                    page.setRedirect(true);
                    return page;
                }
            }*/
            return null;
        } else {
            return null;
        }
    }
    
    Public Boolean validateEmail(String email) {
        
        String emailRegex = '^[a-zA-Z0-9._|\\\\%#~`=?&/$^*!}{+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,4}$';
        Pattern MyPattern = Pattern.compile(emailRegex);
        Matcher MyMatcher = MyPattern.matcher(email);
        
        if (!MyMatcher.matches()) 
            return false;
        else
            return true;
    }
    
    @RemoteAction
    public static List<Account> getOrganisationByFilterString(String searchString) {
        searchString = searchString+'%';
        List<Account> accounts = [SELECT Id, Name FROM Account WHERE Name LIKE : searchString LIMIT 50];
        return accounts;
    }
}