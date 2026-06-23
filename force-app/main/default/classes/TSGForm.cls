global class TSGForm{
    @AuraEnabled
    global Grants__c grantRecord {get;set;}
    @AuraEnabled
    global String grantRecordId {get;set;}
    @AuraEnabled
    global String selectedPI{get;set;}
    @AuraEnabled
    global List<Institution__c> institutionRecordList{get;set;}
    @AuraEnabled
    global List<Investigator> investigatorRecordList {get;set;}
    @AuraEnabled
    global List<Investigator> investigatorRecordListPH {get;set;}
    @AuraEnabled
    global List<Reviewers_and_Restrictions__c> rarList {get;set;}
    @AuraEnabled
    global Budget budget {get;set;}
    @AuraEnabled
    global Decimal totalYearAmount{get;set;}
    
    @AuraEnabled
    global Decimal subTotal{get;set;}
    @AuraEnabled
    global Decimal x10subTotal {get;set;}
    @AuraEnabled
    global Decimal total {get;set;}
    @AuraEnabled
    global Investigator__c investigator;
    @AuraEnabled
    global Boolean isTSG {get;set;}
    @AuraEnabled
    global Boolean isCRC {get;set;}
    @AuraEnabled
    global Boolean isSbumited = false;
    @AuraEnabled
    global List<ContentDocumentLink > contentDocumentLinkList {get;set;}
    
    @AuraEnabled
    global List<ContentDocumentLink > contentDocumentLinkUndertakingList {get;set;}
    
    @AuraEnabled
    global List<OtherDocuments> OtherDocumentsList {get;set;}
    
    @AuraEnabled
    global List<String> restrictedReviewerList {get;set;}
    @AuraEnabled
    global List<String> cmldList {get;set;}
    @AuraEnabled
    global Date meetingDate {get;set;}
    @AuraEnabled
    global String grantsFundingName {get;set;}
    @AuraEnabled
    global String comments {get;set;}
    @AuraEnabled
    global List<String> refereeCommentsReceivedList {get;set;}
    @AuraEnabled
    global List<String> reportnotReceivedList {get;set;}
    @AuraEnabled
    global List<String> notRespondedList {get;set;}
    @AuraEnabled
    global Boolean isAdmin {get;set;}
    
    @AuraEnabled
    global List<Checklist__c> currentReviewChecklist {get;set;}
    @AuraEnabled
    global List<Peer_Review_Checklist__c> currentPeerReviewChecklist {get;set;}
    @AuraEnabled
    global List<Screening_Committee__c> currentSCCChecklist{get;set;}
    
    global List<BlobData> fileDataList;
    global List<Id> contentDocumentIdList = new List<Id>();
    global class BlobData{
        public string ContentDocumentId;
        public string fileName;
        public string fileType;
        public string blobString;
        public blob blobData;
    }
    
    global TSGForm(String grantRecordId){
        this.isTSG = false;
        this.isCRC = false;
        this.total = 0.00;
        this.subTotal= 0.00;
        this.x10subTotal = 0.00;
        this.totalYearAmount = 0.00;
        this.restrictedReviewerList = new List<String>();
        this.cmldList= new List<String>();
        this.refereeCommentsReceivedList = new List<String>();
        this.reportnotReceivedList = new List<String>();
        this.notRespondedList = new List<String>();
        this.fileDataList = new List<BlobData>();
        this.currentReviewChecklist = new List<Checklist__c> ();
        this.currentPeerReviewChecklist = new List<Peer_Review_Checklist__c>();
        this.currentSCCChecklist = new List<Screening_Committee__c>();
        
        this.OtherDocumentsList = new List<OtherDocuments>();
        investigator = new Investigator__c (Grants__c = grantRecordId);
        this.grantRecordId = grantRecordId;
        this.investigatorRecordList = new List<Investigator>();
        this.investigatorRecordListPH = new List<Investigator>();
        if(string.isNotBlank(grantRecordId )){
            this.contentDocumentLinkList = [SELECT Id, LinkedEntityId, ContentDocumentId, ContentDocument.Title FROM ContentDocumentLink WHERE LinkedEntityId = : grantRecordId];
            for(ContentDocumentLink cdl : contentDocumentLinkList ){
                contentDocumentIdList.add(cdl.ContentDocumentId);
            }
            
            this.rarList = [SELECT Id, Name, Grants__c, First_Name__c, Last_Name__c, Full_Name__c, Institution__c,Institution__r.Name, Email__c, Area_of_Expertise__c, Reason_for_being_appropriate_to_review__c,Explain_if_you_know_the_reviewer__c,Type__c FROM Reviewers_and_Restrictions__c WHERE Grants__c = : grantRecordId];
            this.institutionRecordList = [SELECT Id,Grants__c, Type__c, Institution__c, Institution__r.Name, Institution__r.Department__c FROM Institution__c WHERE Grants__c = : grantRecordId ORDER BY Type__c];
            List<Investigator__c> investigatorList = [SELECT Id, Is_other_financial_support__c, Will_be_submitted_for_funding__c,Selected_CV__c,Is_Programme_Head__c, Type__c, Name,Total_Funds_requested_INR__c,Percentage_of_total_funds__c,Summary_of_Scientific_Career_to_Date__c,Experience_Relevant_to_this_Proposal__c,Research_Output_in_last_5_years__c,Other_financial_support__c,Describe_the_Current_Active_Awards__c,Please_specify_your_medical_degree__c,what_is_your_specialty_Active__c,Related_applications__c,Name_of_the_Sponsor__c,Title_of_current_Post__c,Highest_Degree__c,Years_of_Running_Research_Group_Lab__c,Email_of_the_Sponsor__c,Your_Contract_of_Employment__c,Source_of_personal_salary_support__c,Other_affiliations__c,Date_of_Birth__c,Gender__c,ORCID_ID__c,Contact_Number__c,Email__c,Nationality__c,Hours_per_week_on_Non_Research_Activitiy__c , Hours_per_week_on_Active_Grants_Projects__c , Hours_per_week_on_Project_Proposed_to_IA__c , If_you_are_a_Practicing_Clinician__c, Hours_per_week_to_be_spent_on_Research__c, Number_of_total_working_hours_per_week__c, Investigators_Type__c,Full_Name__c,Role__c, Title__c, Discipline_expertise__c,Institution__r.Name, Institution__r.Address__c, Institution__r.City__c, Institution__r.Country__r.Name, Institution__r.Department__c, Institution__r.Pincode__c,Year_1__c,Year_2__c,Year_3__c,Year_4__c,Year_5__c FROM Investigator__c WHERE Grants__c = : grantRecordId ORDER BY Investigators_Type__c, Type__c, CreatedDate];
            Map<String, Integer> picodeMap = new Map<String, Integer>();
            
            List<Other_Document__c> documentList = [SELECT Id, Name, Description__c, Grants__c, Subject__c FROM Other_Document__c WHERE Grants__c = : grantRecordId];
            Set<Id> linkEntityIdSet = new Set<Id>();
            for(Other_Document__c cd : documentList ){
                linkEntityIdSet.add(cd.Id);
            }
            List<ContentDocumentLink > cDocumentLinkList = new List<ContentDocumentLink >();
            Map<Id, List<ContentDocumentLink  >> cdlByDocumentIdMap  = new Map<Id, List<ContentDocumentLink  >> ();
            if(!linkEntityIdSet.isEmpty()){
                cDocumentLinkList = [SELECT Id, LinkedEntityId, ContentDocumentId, ContentDocument.Title FROM ContentDocumentLink WHERE LinkedEntityId IN : linkEntityIdSet];
                cdlByDocumentIdMap = new Map<Id, List<ContentDocumentLink  >> ();
                for(ContentDocumentLink  cdl: cDocumentLinkList ){
                    if(!cdlByDocumentIdMap.containsKey(cdl.LinkedEntityId)) cdlByDocumentIdMap.put(cdl.LinkedEntityId, new List<ContentDocumentLink  >());
                    
                    cdlByDocumentIdMap.get(cdl.LinkedEntityId).add(cdl);
                    
                    contentDocumentIdList.add(cdl.ContentDocumentId);
                }
            }
            for(Other_Document__c cd : documentList ){
                List<ContentDocumentLink > cdlList = new List<ContentDocumentLink >();
                if(cdlByDocumentIdMap.containsKey(cd.Id)){
                    cdlList = cdlByDocumentIdMap.get(cd.Id);
                }
                this.OtherDocumentsList.add(new OtherDocuments(cd, cdlList ));
            }
            
            Map<String, List<Positions_Held__c >> positionHeadMap = new Map<String, List<Positions_Held__c >>();
            for(Positions_Held__c ph: [SELECT Id, Supervisor__c,Position__c,Date_From__c, Date_To__c, Department__c, Organisations__c, Organisations__r.Name, Principle_Investigator__c, Name FROM Positions_Held__c WHERE Principle_Investigator__c IN: investigatorList ORDER BY Date_From__c DESC]){
                if(!positionHeadMap.containsKey(ph.Principle_Investigator__c)){
                    positionHeadMap.put(ph.Principle_Investigator__c, new List<Positions_Held__c >());
                }
                positionHeadMap.get(ph.Principle_Investigator__c).add(ph);
            }
            
            Map<String, List<Qualifications__c>> qualificationsMap = new Map<String, List<Qualifications__c>>();
            for(Qualifications__c ph: [SELECT Id,Supervisor__c, Qualification__c, Date_From__c, Date_To__c, Subject__c, Organisation__c, Organisation__r.Name, Principle_Investigator__c, Name FROM Qualifications__c WHERE Principle_Investigator__c IN: investigatorList ORDER BY Date_From__c DESC]){
                if(!qualificationsMap.containsKey(ph.Principle_Investigator__c)){
                    qualificationsMap.put(ph.Principle_Investigator__c, new List<Qualifications__c >());
                }
                qualificationsMap.get(ph.Principle_Investigator__c).add(ph);
            }
            
            Map<String, List<Funding_Organisation__c>> fundingOrganisationMap = new Map<String, List<Funding_Organisation__c>>();
            for(Funding_Organisation__c fo: [SELECT Id, Brief_summary_under_200_words__c, Investigator__c, Name_of_the_funding_organisation__c, Expected_decision_date__c, Name FROM Funding_Organisation__c WHERE Investigator__c IN: investigatorList ORDER BY Expected_decision_date__c DESC]){
                if(!fundingOrganisationMap.containsKey(fo.Investigator__c)){
                    fundingOrganisationMap.put(fo.Investigator__c, new List<Funding_Organisation__c >());
                }
                fundingOrganisationMap.get(fo.Investigator__c).add(fo);
            }
            
            Map<String, List<Other_Financial_Support__c>> otherFinancialSupportMap = new Map<String, List<Other_Financial_Support__c>>();
            for(Other_Financial_Support__c ofs: [SELECT Id,Awarded_Budget_with_currencies__c,End_Date__c,Investigator__c,Name_s_of_recipient__c,Name_of_the_funder__c,Start_Date__c,Title_of_the_project__c,Your_role_in_the_project__c, Name FROM Other_Financial_Support__c WHERE Investigator__c IN: investigatorList ORDER BY Start_Date__c DESC]){
                if(!otherFinancialSupportMap.containsKey(ofs.Investigator__c)){
                    otherFinancialSupportMap.put(ofs.Investigator__c, new List<Other_Financial_Support__c>());
                }
                otherFinancialSupportMap.get(ofs.Investigator__c).add(ofs);
            }
            
            string code = '';
            
            for(Investigator__c inv : investigatorList){
                if(inv.Year_1__c != null) this.totalYearAmount += inv.Year_1__c;
                if(inv.Year_2__c != null) this.totalYearAmount += inv.Year_2__c;
                if(inv.Year_3__c != null) this.totalYearAmount += inv.Year_3__c;
                if(inv.Year_4__c != null) this.totalYearAmount += inv.Year_4__c;
                if(inv.Year_5__c != null) this.totalYearAmount += inv.Year_5__c;
            
                if(inv.Selected_CV__c) selectedPI = inv.Id;
                if(inv.Investigators_Type__c != null){
                    if(!picodeMap.containsKey(inv.Investigators_Type__c))  picodeMap.put(inv.Investigators_Type__c,1);
                    Integer n = picodeMap.get(inv.Investigators_Type__c);
                    if(inv.Investigators_Type__c != null && !inv.Investigators_Type__c.equalsignorecase('Principal Investigator')){
                        code = inv.Investigators_Type__c.replace('Principal Investigator','PI')+' ['+ n +']';
                        picodeMap.put(inv.Investigators_Type__c,n+1);
                    }else if(inv.Investigators_Type__c.equalsignorecase('Principal Investigator')){
                        code = inv.Investigators_Type__c.replace('Principal Investigator','PI');
                    }
                }
                
                if(inv.Type__c != null){
                    if(!picodeMap.containsKey(inv.Type__c))  picodeMap.put(inv.Type__c,1);
                    Integer n = picodeMap.get(inv.Type__c);
                    if(inv.Type__c != null && !inv.Type__c.equalsignorecase('Programme Head')){
                        code = ' ['+ n +']';
                        picodeMap.put(inv.Type__c,n+1);
                    }else if(inv.Type__c.equalsignorecase('Programme Head')){
                        code = inv.Type__c.replace('Programme Head','[ PH ]');
                    }
                }
                List<Positions_Held__c > phList = new List<Positions_Held__c >();
                if(positionHeadMap.containsKey(inv.Id)){ phList = positionHeadMap.get(inv.Id);
                }
                List<Qualifications__c > qualificationlList = new List<Qualifications__c >();
                if(qualificationsMap.containsKey(inv.Id)){ qualificationlList  = qualificationsMap.get(inv.Id);
                }
                List<Funding_Organisation__c> fundingOrganisationlList = new List<Funding_Organisation__c >();
                if(fundingOrganisationMap.containsKey(inv.Id)){fundingOrganisationlList  = fundingOrganisationMap.get(inv.Id);
                }
                List<Other_Financial_Support__c > otherFinancialSupportlList = new List<Other_Financial_Support__c >();
                if(otherFinancialSupportMap.containsKey(inv.Id)){ otherFinancialSupportlList = otherFinancialSupportMap.get(inv.Id);
                }
                if(String.isBlank(this.selectedPI) && !investigatorList.isEmpty()){
                    this.selectedPI = investigatorList.get(0).Id;
                }
                if(inv.Is_Programme_Head__c){
                    this.investigatorRecordListPH.add(new Investigator(
                        inv, 
                        code ,
                        phList,
                        qualificationlList,
                        fundingOrganisationlList  ,
                        otherFinancialSupportlList 
                    ));
                }else{
                    this.investigatorRecordList.add(new Investigator(
                        inv, 
                        code ,
                        phList,
                        qualificationlList,
                        fundingOrganisationlList  ,
                        otherFinancialSupportlList 
                    ));
                }
            }
        }
        List<Grants__c> grants = [SELECT Id, Is_Admin__c, National_Apex_Committee_for_Stem_Cell_Re__c, IU_Documents__c ,PI_Documents__c ,Describe_Why_Team_Approach_Is_necessary__c,Institution_Justification__c, OwnerId, RecordType.Name,Budget__c, IsDeleted, Name, RecordTypeId, CreatedDate, CreatedById, Type__c, Title__c, Project_Title__c, Research_summary__c, Lay_summary__c, Proposal_Statements__c, Address__c, City__c, Pincode__c, Duration_of_the_grant_in_months__c, Start_date__c,  Human_participants__c, Experiments_with_human_stem_cells__c, Personal_data__c, Biological_samples__c, Scheme__c, If_your_project_involves_Experiments__c, Institutional_Committee_for_Stem_Cell__c, Institutional_Ethics_Committee_IEC__c, Will_your_project_require_National__c, Use_of_animals__c, Use_of_animal_tissue__c, Use_of_animal_stem_cells__c,  designation__c, Status__c, Will_the_Proposed_research_generates__c,   Public_Dissemination_of_Funded_Research__c, By_Whom_and_When_the_Project_was_Review__c, Details_of_Stem_Cell_Experiments__c, Project_Requires_to_patients_Treatments__c, Details_Procedures_of_Animals__c, Why_is_animal_use_necessary__c, plan_to_work_on_animal_stem_cells__c, following_species_will_be_used__c, Why_are_the_species_to_be_used__c, Proposed_Research_or_Outcomes_Pose_Risk__c, Have_any_Research_Sponsorship_Agreements__c, Details_of_Technology_materials__c, Undertaking_Statement__c,Reviewers_and_Restrictions_Justification__c,Reference_Number__c,Programme__c,Staff_Member__r.Name,Alleviation_of_the_disease_burden__c, Contribution_to_the_host_institution__c, Sustainable_Development_Goals__c, Alleviation_of_your_country_s_disease__c, SDGs_Description__c,Institutional_Undertakings_Description__c FROM Grants__c WHERE Id =: grantRecordId];
        if(! grants.isEmpty()) this.grantRecord = grants.get(0); this.isAdmin = grants.get(0).Is_Admin__c;
        
        this.contentDocumentLinkUndertakingList = [SELECT Id, LinkedEntityId, ContentDocumentId, ContentDocument.Title FROM ContentDocumentLink WHERE LinkedEntityId = : grantRecord.IU_Documents__c OR LinkedEntityId =: grantRecord.PI_Documents__c];
        for(ContentDocumentLink cdl : contentDocumentLinkUndertakingList ){
            contentDocumentIdList.add(cdl.ContentDocumentId);
        }
        if(this.grantRecord.RecordType.Name.equalsignorecase('Team Science Grants (TSG)')) isTSG = true;
        if(this.grantRecord.RecordType.Name.equalsignorecase('Clinical/Public Health Research Centers(CRC)')) isCRC = true;
        
        List<Budget__c> budgets = [SELECT Id, Name, Support_staff_justification__c, Justification_for_Travel_Costs__c, Justification_for_miscellaneous_costs__c, Justification_for_animal_costs_requested__c, Justification_for_access_charges__c, Salaries_for_PIs_Justification__c, Equipment_Justification__c, Materials_and_Consumables_Justification__c FROM Budget__c WHERE Id = : grantRecord.Budget__c ];
        this.budget = new Budget(new Budget__c());
        if(budgets  != null && ! budgets.isEmpty()) this.budget = new Budget(budgets.get(0));
        
        this.subTotal = this.totalYearAmount ;
        this.subTotal += this.budget.totalsfAmount ;
        this.subTotal += this.budget.totalmcAmount  ;
        this.subTotal += this.budget.totaleqAmount ;
        this.subTotal += this.budget.totalaccessAmount ;
        this.subTotal += this.budget.totalanimalAmount ;
        this.subTotal += this.budget.totalanimalacAmount ;
        this.subTotal += this.budget.totalmisAmount;
        this.subTotal += this.budget.totaltcAmount ;
        this.subTotal += this.budget.IAContributionAmount;
        
        this.x10subTotal = (this.subTotal*10)/100;
        this.total = this.subTotal + x10subTotal ;
    }
    global class Budget{
        @AuraEnabled
        global Budget__c budgetRecord {get;set;}
        @AuraEnabled
        global List<Support_Staff__c> supportStaffList {get;set;}
        @AuraEnabled
        global List<Materials_and_Consumables__c> MConsumablesList {get;set;}
        @AuraEnabled
        global List<Equipments__c> eqList {get;set;}
        @AuraEnabled
        global List<Access_charges__c > accessList {get;set;}
        @AuraEnabled
        global List<Animals__c> animalList {get;set;}
        @AuraEnabled
        global Decimal totalanimalAmount{get;set;}
        @AuraEnabled
        global List<Travel_Cost__c> tcList {get;set;}
        @AuraEnabled
        global List<Animal_Associated_costs__c > animalaclList {get;set;}
        @AuraEnabled
        global List<Miscellaneous__c> misList {get;set;}
        @AuraEnabled
        global Decimal totalsfAmount {get;set;}
        @AuraEnabled
        global Decimal totalmcAmount {get;set;}
        @AuraEnabled
        global Decimal totaleqAmount {get;set;}
        @AuraEnabled
        global Decimal totalaccessAmount {get;set;}
        @AuraEnabled
        global Decimal totalanimalacAmount {get;set;}
        @AuraEnabled
        global Decimal totalmisAmount {get;set;}
        @AuraEnabled
        global Decimal totaltcAmount {get;set;}
        @AuraEnabled
        global Decimal IAContributionAmount{get;set;}
        
        global Budget(Budget__c budgetRecord){
            this.totalsfAmount = 0.00;
            this.totaltcAmount = 0.00;
            this.totalanimalacAmount = 0.00;
            this.totaltcAmount = 0.00;
            this.totalmisAmount = 0.00;
            this.totalaccessAmount = 0.00;
            this.totaleqAmount = 0.00;
            this.totalmcAmount = 0.00;
            this.IAContributionAmount= 2000000.00;
            this.totalanimalAmount = 0.00;
            this.budgetRecord = budgetRecord;
            this.supportStaffList = [SELECT Id, Total__c, Staff_Category__c,Number_of_Positions__c, Organisation__c, Organisation__r.Name, Salary_Grade__c, Period_on_Project__c, Time__c,Budget__c FROM Support_Staff__c WHERE Budget__c = : budgetRecord.Id];
            for(Support_Staff__c sf : supportStaffList ){if(sf.Total__c != null) this.totalsfAmount += sf.Total__c;}
            
            this.MConsumablesList = [SELECT Id, Materials_and_Consumables_Name__c, Budget__c, Costs__c, Name FROM Materials_and_Consumables__c WHERE Budget__c = : budgetRecord.Id];
            for(Materials_and_Consumables__c  mc : MConsumablesList ){if(mc.Costs__c != null) this.totalmcAmount += mc.Costs__c;}
            
            this.eqList = [SELECT Id, OwnerId, Name, Cost_of_maintenance_contract_per_year__c,CreatedDate, CreatedById, Budget__c, Type_of_Equipment__c, Number_of_items__c, Cost_per_item__c, Duration_of_Maintenance__c, Total__c , Contribution_from_other_sources__c FROM Equipments__c WHERE Budget__c = : budgetRecord.Id];
            for(Equipments__c  eq : eqList ){if(eq.Total__c != null) this.totaleqAmount += eq.Total__c;}
            
            this.accessList = [SELECT Id, Place__c,Access_Charge_Name__c,Access_Charges_Per_Unit__c, Specify_access__c, Budget__c, Number_of_Units__c, Total__c FROM Access_charges__c WHERE Budget__c = : budgetRecord.Id];
            for(Access_charges__c acc : accessList ){if(acc.Total__c != null) this.totalaccessAmount += acc.Total__c;}
            
            this.animalList = [SELECT Id, Name, Animal_species__c, Budget__c, Total_maintenance_and_procedure_cost__c, Total_number_to_be_purchased__c, Total_purchase_cost__c, Total__c FROM Animals__c WHERE Budget__c = : budgetRecord.Id];
            for(Animals__c an : animalList ){ if(an.Total__c != null) this.totalanimalAmount += an.Total__c;}
            
            this.animalaclList = [SELECT Id, Name, Budget__c, Description__c, Total__c FROM Animal_Associated_costs__c WHERE Budget__c = : budgetRecord.Id];
            for(Animal_Associated_costs__c aac : animalaclList ){if(aac.Total__c != null) this.totalanimalacAmount += aac.Total__c;}
            
            this.misList = [SELECT Id, Type__c, Name, Budget__c, Description__c, Total__c FROM Miscellaneous__c WHERE Budget__c = : budgetRecord.Id];
            for(Miscellaneous__c mis : misList ){ if(mis.Total__c != null) this.totalmisAmount += mis.Total__c; }
            
            this.tcList = [SELECT Id, Name, Budget__c, Place_to_Travel__c, Year__c, Amount__c FROM Travel_Cost__c WHERE Budget__c = : budgetRecord.Id ORDER By Year__c];
            for(Travel_Cost__c tc : tcList ){if(tc.Amount__c != null) this.totaltcAmount += tc.Amount__c;}
        }
    }
    global class OtherDocuments{
        @AuraEnabled
        global List<ContentDocumentLink> contentDocumentLinkList{get;set;}
        @AuraEnabled
        global Other_Document__c other_Document{get;set;}
        
        global OtherDocuments(Other_Document__c other_Document, List<ContentDocumentLink> contentDocumentLinkList){
            this.other_Document= other_Document;
            this.contentDocumentLinkList = contentDocumentLinkList;
        }
    }
    
    global class Investigator{
        @AuraEnabled
        public string investigatorRecordId {get;set;}
        @AuraEnabled
        public string investigatorType {get;set;}
        @AuraEnabled
        public string code {get;set;}
        @AuraEnabled
        public Investigator__c investigatorRecord {get;set;} 
        @AuraEnabled
        public List<Positions_Held__c > phList {get;set;}
        @AuraEnabled
        public List<Qualifications__c > qualificationlList {get;set;}
        @AuraEnabled
        public List<Funding_Organisation__c> fundingOrganisationList {get;set;}
        @AuraEnabled
        public List<Other_Financial_Support__c > otherFinancialSupportList {get;set;}
        
        public Investigator(){
            this.investigatorRecord = new Investigator__c();
        }
        public Investigator(
                                Investigator__c investigatorRecord, 
                                string code,
                                List<Positions_Held__c > phList,
                                List<Qualifications__c > qualificationlList,
                                List<Funding_Organisation__c> fundingOrganisationList,
                                List<Other_Financial_Support__c > otherFinancialSupportList
                                //List<Investigator_Year_Salary__c > IYSList
                            ){
            this.fundingOrganisationList = fundingOrganisationList;
            this.otherFinancialSupportList = otherFinancialSupportList;
            this.phList = phList;
            this.qualificationlList = qualificationlList;
            this.code = code;
            this.investigatorRecord = investigatorRecord;
            this.investigatorRecordId = investigatorRecord.Id;
        }
        public Investigator(Investigator__c investigatorRecord){
            this.investigatorRecord = investigatorRecord;
        }
    }
    
    global class Response{
        @AuraEnabled
        public Boolean isPassed = true;
        @AuraEnabled
        public List<String> errorMsgList;
        
        @AuraEnabled
        public String recordId;
        
        global Response(){
            this.errorMsgList = new List<String>();
        }
    }
}