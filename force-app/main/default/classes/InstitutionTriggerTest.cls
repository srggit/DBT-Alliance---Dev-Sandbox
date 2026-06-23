@isTest
public class InstitutionTriggerTest {
  public static testmethod void insit(){
        
        Grants__c g=new Grants__c();
        g.Background__c='Vali';
        insert g;  
      
        Country__c c=new Country__c();
        c.Name='India';
        insert c;
        
        Address__c add=new Address__c();
        add.Billing_City__c='bundi';
        insert add;
        
        Account a=new Account();
        a.name='Abhi';
        a.Department__c='test';
        a.Institution_Categories__c='Hospital';
        a.Country__c=c.id; 
        a.Address__c=add.id; 
        a.City__c='bundi'; 
        a.Pincode__c=9890; 
        insert a;
        
        Institution__c i= new Institution__c();
        i.Type__c='	Lead Institution';
        i.Institution__c=a.id;
        i.Grants__c=g.id;
        insert i;
        
       
        
    }
}