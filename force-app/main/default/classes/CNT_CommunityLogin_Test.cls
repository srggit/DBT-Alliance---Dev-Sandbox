@isTest
public class CNT_CommunityLogin_Test {
    
    public static testmethod void cntCommunity1(){
        
        Country__c cc= new Country__c();
        cc.Name='India';
        insert cc;
        
        String profileName;
        Account a= new Account();
        a.Name='Vali';
        a.Department__c='IT';
        a.Country__c=cc.Id;
        a.Address__c='Gutur';
        a.City__c='Guntur';
        a.Pincode__c= 522112;
        a.Institution_Categories__c='Hospital';
        insert a ;
        PageReference pageRef = Page.CommunitiesLanding;
        ApexPages.StandardController sc = new ApexPages.standardController(a);
        CNT_CommunityLogin  controller = new CNT_CommunityLogin();
        pageRef.getParameters().put('id',a.id);
        Boolean    showLoginSection = false;
        Boolean  showRegisterSection = false;
        Boolean    showRegisterationSection = true;
        controller.login();
        controller.register();
        // controller.next();
        controller.clear();
        controller.clearUserDetails();
        controller.cancel();
        
        ID adminProfileID = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].ID;
        
        
        user u= new user();
        u.Title__c='Professor';
        u.FirstName='abhi';
        u.Date_of_Birth__c=Date.newInstance(2000, 1, 23);
        u.Nationality__c='India';
        u.Expertise__c='ans';
        u.Position__c='sales';
        u.Department__c='item';
        u.Gender__c='male';
        u.Organisation__c='hs';
        u.Address__c='hds';
        u.City__c='bundi';
        u.Countries__c='india';
        u.Postal_Code__c='560030';
        u.International_Dialing_Code__c=90.39;
        u.Phone='9933832822';
        u.Alias = 'firstusr';
        u.TimeZoneSidKey = 'America/Los_Angeles';
        u.LocaleSidKey = 'en_US';
        u.EmailEncodingKey = 'UTF-8';
        u.LanguageLocaleKey = 'en_US';
        u.Username='saket.sharma48d@gmail.com	';
        u.LastName='sharma';
        u.Email='masthanvali.n@appistoki.com	';
        // u.ContactId = c.Id;
        u.ProfileId =adminProfileID;
        insert u;
        user u1= new user();
        //controller.userRegistration=u1;
        controller.dob='2000-01-23';
        controller.nextToSubmit();
        controller.next();
        //controller.submit();
        controller.validateEmail('abhishek.nagar@appistoki.com');
        CNT_CommunityLogin.getOrganisationByFilterString('t');
    }
    public static testmethod void cntCommunity2(){
        
        Country__c cc= new Country__c();
        cc.Name='India';
        insert cc;
        
        String profileName;
        Account a= new Account();
        a.Name='Vali';
        a.Department__c='IT';
        a.Country__c=cc.Id;
        a.Address__c='Gutur';
        a.City__c='Guntur';
        a.Pincode__c= 522112;
        a.Institution_Categories__c='Hospital';
        insert a ;
        PageReference pageRef = Page.CommunitiesLanding;
        ApexPages.StandardController sc = new ApexPages.standardController(a);
        CNT_CommunityLogin  controller = new CNT_CommunityLogin();
        pageRef.getParameters().put('id',a.id);
        Boolean    showLoginSection = false;
        Boolean  showRegisterSection = false;
        Boolean    showRegisterationSection = true;
        controller.login();
        controller.register();
        // controller.next();
        controller.clear();
        controller.clearUserDetails();
        controller.cancel();
        
        ID adminProfileID = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].ID;
        
        
        user u= new user();
        u.Title__c='Professor';
        u.FirstName='abhi';
        u.Date_of_Birth__c=Date.newInstance(2000, 1, 23);
        u.Nationality__c='India';
        u.Expertise__c='ans';
        u.Position__c='sales';
        u.Department__c='item';
        u.Gender__c='male';
        u.Organisation__c='hs';
        u.Address__c='hds';
        u.City__c='bundi';
        u.Countries__c='india';
        u.Postal_Code__c='560030';
        u.International_Dialing_Code__c=90.39;
        u.Phone='9933832822';
        u.Alias = 'firstusr';
        u.TimeZoneSidKey = 'America/Los_Angeles';
        u.LocaleSidKey = 'en_US';
        u.EmailEncodingKey = 'UTF-8';
        u.LanguageLocaleKey = 'en_US';
        u.Username='saket.sharma48d@gmail.com	';
        u.LastName='sharma';
        u.Email='masthanvali.n@appistoki.com	';
        // u.ContactId = c.Id;
        u.ProfileId =adminProfileID;
        insert u;
        user u1= new user();
        u1.Title__c='test';
        u1.FirstName='test';
        u1.LastName='';
        u1.Date_of_Birth__c=system.today();
        u1.Nationality__c='';
        u1.Expertise__c='';
        controller.userRegistration=u1;
        controller.dob='2000-01-23';
        controller.nextToSubmit();
        controller.email='abhsk.nagar@appistoki.com';
        controller.confirmEmail='abh.nagar@appistoki.com';
        controller.validateEmail('abhsk.nagar@appistoki.com');
        controller.next();
        //controller.submit();
        
        CNT_CommunityLogin.getOrganisationByFilterString('t');
    }
    public static testmethod void cntCommunity3(){
        
        Country__c cc= new Country__c();
        cc.Name='India';
        insert cc;
        
        String profileName;
        Account a= new Account();
        a.Name='Vali';
        a.Department__c='IT';
        a.Country__c=cc.Id;
        a.Address__c='Gutur';
        a.City__c='Guntur';
        a.Pincode__c= 522112;
        a.Institution_Categories__c='Hospital';
        insert a ;
        PageReference pageRef = Page.CommunitiesLanding;
        ApexPages.StandardController sc = new ApexPages.standardController(a);
        CNT_CommunityLogin  controller = new CNT_CommunityLogin();
        pageRef.getParameters().put('id',a.id);
        Boolean    showLoginSection = false;
        Boolean  showRegisterSection = false;
        Boolean    showRegisterationSection = true;
        controller.login();
        controller.register();
        // controller.next();
        controller.clear();
        controller.clearUserDetails();
        controller.cancel();
        
        ID adminProfileID = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].ID;
        
        
        user u= new user();
        u.Title__c='Professor';
        u.FirstName='abhi';
        u.Date_of_Birth__c=Date.newInstance(2000, 1, 23);
        u.Nationality__c='India';
        u.Expertise__c='ans';
        u.Position__c='sales';
        u.Department__c='item';
        u.Gender__c='male';
        u.Organisation__c='hs';
        u.Address__c='hds';
        u.City__c='bundi';
        u.Countries__c='india';
        u.Postal_Code__c='560030';
        u.International_Dialing_Code__c=90.39;
        u.Phone='9933832822';
        u.Alias = 'firstusr';
        u.TimeZoneSidKey = 'America/Los_Angeles';
        u.LocaleSidKey = 'en_US';
        u.EmailEncodingKey = 'UTF-8';
        u.LanguageLocaleKey = 'en_US';
        u.Username='saket.sharma48d@gmail.com	';
        u.LastName='sharma';
        u.Email='masthanvali.n@appistoki.com	';
        // u.ContactId = c.Id;
        u.ProfileId =adminProfileID;
        insert u;
        user u1= new user();
        u1.Title__c='test';
        u1.FirstName='test';
        u1.LastName='test';
        u1.Date_of_Birth__c=null;
        u1.Nationality__c='';
        u1.Expertise__c='';
        controller.userRegistration=u1;
        //controller.dob='2000-01-23';
        //controller.nextToSubmit();
        controller.termsAndConditions=true;
        //controller.confirmEmail='abh.nagar@appistoki.com';
        controller.validateEmail('ask.nagar@appistoki.com');
        //controller.next();
        controller.submit();
        
        CNT_CommunityLogin.getOrganisationByFilterString('t');
    }
    public static testmethod void cntCommunity4(){
        
        Country__c cc= new Country__c();
        cc.Name='India';
        insert cc;
        
        String profileName;
        Account a= new Account();
        a.Name='Vali';
        a.Department__c='IT';
        a.Country__c=cc.Id;
        a.Address__c='Gutur';
        a.City__c='Guntur';
        a.Pincode__c= 522112;
        a.Institution_Categories__c='Hospital';
        insert a ;
        PageReference pageRef = Page.CommunitiesLanding;
        ApexPages.StandardController sc = new ApexPages.standardController(a);
        CNT_CommunityLogin  controller = new CNT_CommunityLogin();
        pageRef.getParameters().put('id',a.id);
        Boolean    showLoginSection = false;
        Boolean  showRegisterSection = false;
        Boolean    showRegisterationSection = true;
        controller.login();
        controller.register();
        // controller.next();
        controller.clear();
        controller.clearUserDetails();
        controller.cancel();
        
        ID adminProfileID = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].ID;
        
        
        user u= new user();
        u.Title__c='Professor';
        u.FirstName='abhi';
        u.Date_of_Birth__c=Date.newInstance(2000, 1, 23);
        u.Nationality__c='India';
        u.Expertise__c='ans';
        u.Position__c='sales';
        u.Department__c='item';
        u.Gender__c='male';
        u.Organisation__c='hs';
        u.Address__c='hds';
        u.City__c='bundi';
        u.Countries__c='india';
        u.Postal_Code__c='560030';
        u.International_Dialing_Code__c=90.39;
        u.Phone='9933832822';
        u.Alias = 'firstusr';
        u.TimeZoneSidKey = 'America/Los_Angeles';
        u.LocaleSidKey = 'en_US';
        u.EmailEncodingKey = 'UTF-8';
        u.LanguageLocaleKey = 'en_US';
        u.Username='saket.sharma48d@gmail.com	';
        u.LastName='sharma';
        u.Email='masthanvali.n@appistoki.com	';
        // u.ContactId = c.Id;
        u.ProfileId =adminProfileID;
        insert u;
        user u1= new user();
        u1.Title__c='test';
        u1.FirstName='test';
        u1.LastName='test';
        u1.Date_of_Birth__c=System.today();
        u1.Nationality__c='';
        u1.Expertise__c='';
        controller.userRegistration=u1;
        controller.dob='2000-01-23';
        controller.nextToSubmit();
        controller.email='abhsk.nagar';
        //controller.confirmEmail='abh.nagar@appistoki.com';
        controller.validateEmail('testm');
        controller.next();
        controller.submit();
        controller.previous();
        CNT_CommunityLogin.getOrganisationByFilterString('t');
        
        CNT_ForgotPasswordController testForgotPasswordCNT = new CNT_ForgotPasswordController();
        testForgotPasswordCNT.forgotPassword();
        testForgotPasswordCNT.username = 'test@gmail.com';
        testForgotPasswordCNT.forgotPassword();
        testForgotPasswordCNT.cancel();
    }
    
}