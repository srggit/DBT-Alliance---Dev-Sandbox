public class CNT_CheckListForm {
    @AuraEnabled
    public static checkList getCurrentChecklist(String recId) {
        Checklist__c currentChecklistRecord;
        List<Checklist__c> checkList = new List<Checklist__c>();
        checkList = [Select Abstract_Appropriate__c,Access_charges__c,Access_of_CSDU_Available__c,All_Investigators_Eligible__c,
                     All_Organizations_Eligible__c,Animal_Number_Calculation_Provided__c,Animals__c,Any_Additional_Concern__c,
                     Any_Experiment_on_big_Animals__c,Appropriate_Undertaking_from_Institution__c,Appropriate_Undertaking_investigators__c,
                     Budget_within_cap__c,Name,Clinical_Trial_Proposed__c,Co_Institution_1__c,Co_Institution_2__c,Comments__c,
                     Comments_from_Secretary__c,CreatedById,CRTP_Proposed__c,Distribution_of_funds__c,Equipment__c,Flexible_Funding_Allowance__c,
                     Format_for_grants_in_CVs_per_guidelines__c,Guidelines_for_Figures_and_table__c,Guidelines_followed_for_References__c,
                     Investigator__c,LastModifiedById,Lead_Institution__c,Materials_and_consumables__c,Miscellaneous__c,Name_of_Investigator1__c,
                     Name_of_Investigator2__c,No_Disallowed_costs__c,No_link_with_Commercial_Organizations__c,No_Mismatch_in_Calculation__c,
                     No_Other_Affiliations_any_Investigator__c,Overheads__c,OwnerId,Pending_Applications_other_Agencies__c,Proposal_Within_Remit__c,
                     Proposal_within_word_limit__c,Publications_in_CVs_as_per_Guidelines__c,Queries_sent_to_Applicants__c,RecordTypeId,Ref_No__c,
                     Reference_Number__c,Research_Management_plan_Presented__c,Response_from_Later_Stages__c,Restricted_reviewers_not_Included__c,
                     Role_of_all_Investigators__c,Salaries_for_PIs__c,Salary_for_PIs_not_Requested__c,Satisfactory_Representation_of_Milestone__c,
                     Satisfactory_Representation_of_Timelines__c,Source_of_Human_Samples__c,Sub_Total__c,Support_Staff_salaries__c,
                     Sustainability_plan_Presented__c,Time_Commitment_Satisfactory__c,Total__c,Travel_costs__c, Type__c, LI_Name_and_Organisation__c,
                     CO_1_Name_and_Organisation__c, CO_2_Name_and_Organisation__c, Grants__c 
                     from Checklist__c where Grants__c =: recId AND GA__c =: UserInfo.getUserId()];
        if(checkList.size() > 0) {
            currentChecklistRecord = checkList[0];
        }
        else {
            Grants__c currentGrantRecord = [Select RecordType.Name, Reference_Number__c from Grants__c where Id =: recId];
            List<Investigator__c> investigatorList = new List<Investigator__c>();
            investigatorList = [Select Investigators_Type__c, Full_Name__c, Institution__c, Institution__r.Name from Investigator__c where Grants__c =: recId];
            currentChecklistRecord = new Checklist__c();
            currentChecklistRecord.Grants__c = recId;
            currentChecklistRecord.GA__c = UserInfo.getUserId();
            currentChecklistRecord.Reference_Number__c = currentGrantRecord.Reference_Number__c;
            for(Investigator__c investigator : investigatorList) {
                if(investigator.Investigators_Type__c == 'Principal Investigator') {
                    if(currentChecklistRecord.Lead_Institution__c == null) {
                        currentChecklistRecord.Lead_Institution__c = investigator.Institution__c;
                        currentChecklistRecord.LI_Name_and_Organisation__c = investigator.Full_Name__c + ' and ' + investigator.Institution__r.Name;
                    }
                }
                /*else if(investigator.Investigators_Type__c == 'Co-Principal Investigator') {
                    if(currentChecklistRecord.Co_Institution_1__c == null) {
                        currentChecklistRecord.Co_Institution_1__c = investigator.Institution__c;
                        currentChecklistRecord.CO_1_Name_and_Organisation__c = investigator.Full_Name__c + ' and ' + investigator.Institution__r.Name;
                    }
                    if(currentChecklistRecord.Co_Institution_2__c == null) {
                        currentChecklistRecord.Co_Institution_2__c = investigator.Institution__c;
                        currentChecklistRecord.CO_2_Name_and_Organisation__c = investigator.Full_Name__c + ' and ' + investigator.Institution__r.Name;
                    }
                }*/
            }
            currentChecklistRecord.Salaries_for_PIs__c = 0;
            currentChecklistRecord.Support_Staff_salaries__c = 0;
            currentChecklistRecord.Materials_and_consumables__c = 0;
            currentChecklistRecord.Animals__c = 0;
            currentChecklistRecord.Equipment__c = 0;
            currentChecklistRecord.Access_charges__c = 0;
            currentChecklistRecord.Miscellaneous__c = 0;
            currentChecklistRecord.Travel_costs__c = 0;
            currentChecklistRecord.Flexible_Funding_Allowance__c = 0;
            currentChecklistRecord.Type__c = 'Save';
            if(currentGrantRecord.RecordType.Name.contains('CRC')) {
                currentChecklistRecord.RecordTypeId = Schema.SObjectType.Checklist__c.getRecordTypeInfosByName().get('CRC Checklist').getRecordTypeId();
            }
            else if(currentGrantRecord.RecordType.Name.contains('TSG')) {
                currentChecklistRecord.RecordTypeId = Schema.SObjectType.Checklist__c.getRecordTypeInfosByName().get('TSG Checklist').getRecordTypeId();
            }
        }
        checkList chk = new checkList(currentChecklistRecord);
        List<Investigator__c> investigatorList = [SELECT Id, Institution__r.Name, Full_Name__c ,Investigators_Type__c  FROM Investigator__c WHERE Grants__c = : recId AND Investigators_Type__c  = 'Co-Principal Investigator'ORDER BY Investigators_Type__c,CreatedDate];
        for(Investigator__c inv : investigatorList ){
            chk.coInvList.add(inv.Full_Name__c + ' and ' + inv.Institution__r.Name);
        }
        
        return chk ;
    }
    
    public class checkList{
        @AuraEnabled
        public Checklist__c checklistRecord;
        @AuraEnabled
        public Boolean isTSG ;
        @AuraEnabled
        public Boolean isCRC ;
        @AuraEnabled
        public List<String> coInvList ;
        
        public checkList(Checklist__c checklistRecord){
            this.checklistRecord = checklistRecord;
            this.coInvList  = new List<String>();
            List<Grants__c> grantRecordList = [SELECT Id , RecordType.Name FROM Grants__c WHERE Id = : checklistRecord.Grants__c ];
            isTSG = false;
            isCRC = false;
            if(!grantRecordList.isEmpty()){
                Grants__c grantRecord = grantRecordList.get(0);
                if(grantRecord.RecordType.Name.equalsignorecase('Team Science Grants (TSG)')) isTSG = true;
                if(grantRecord.RecordType.Name.equalsignorecase('Clinical/Public Health Research Centers(CRC)')) isCRC = true;
            }
        }
    }
    
    @AuraEnabled
    public static void saveChecklistRecord(Checklist__c checklistRecord, String checklistType) {
        checklistRecord.Type__c = checklistType;
        upsert checklistRecord;
        
        if(String.isNotBlank(checklistRecord.Grants__c)){
            List<Assigned_Reviewer__c> asList = [SELECT Id, Status__c FROM Assigned_Reviewer__c WHERE Grants__c = : checklistRecord.Grants__c AND Assigned_User__c = : UserInfo.getUserId()];
            if(!asList.isEmpty() && checklistType == 'Submit'){
                for(Assigned_Reviewer__c re : asList){
                    re.status__c = 'Submitted';
                }
                update asList;
            }
        }
    }
    @AuraEnabled
    public static boolean getGrantAccessForUser(String recId) {
        List<String> allowedProfile = Label.Reviewer_Profile_Allowed.split(';');
        List<User> users = [SELECT Id FROM User WHERE Profile.Name =: allowedProfile AND Id = : UserInfo.getUserId() ];
        
        List<Assigned_Reviewer__c> assigned_ReviewerList = [SELECT Id FROM Assigned_Reviewer__c WHERE Grants__c = : recId AND Assigned_User__c = : UserInfo.getUserId()];
        if(!assigned_ReviewerList.isEmpty() || !users.isEmpty()){
            return true;
        }
        return false;
    }
    
    
    @AuraEnabled
    public static Peer_Review_Checklist__c getCurrentReviewChecklist(String recId) {
        Peer_Review_Checklist__c currentReviewChecklistRecord;
        List<Peer_Review_Checklist__c> reviewCheckList = new List<Peer_Review_Checklist__c>();
        reviewCheckList = [Select Address_of_Reviewer__c,Collaboration__c,CreatedById,Data_Management_and_Sharing__c,
                           Feasibility_of_Project_and_Research__c,Feedback_to_Applicants__c,Grants__c,Impact__c,
                           Institutional_Support__c,LastModifiedById,Name_of_Lead_PI__c,Name_of_Reviewer__c,OwnerId,Name,
                           Potential_Conflicts_of_Interest__c,Project_Compititive__c,Project_Excellent__c,
                           Project_Not_Supportable__c,Project_Outstanding__c,Project_Satisfactory__c,
                           Research_Involving_Human_Participation__c,Research_on_Animals__c,Resources__c,Reviewer__c,
                           Strengths__c,Team_Compititive__c,Team_Excellent__c,Team_Not_Supportable__c,Team_Outstanding__c,
                           Team_Satisfactory__c,Time_Commitment__c,Track_Record_of_the_Team__c,Weaknesses__c,
                           Why_the_Resources_not_Appropriate__c,Type__c,Summarise_Ratings__c
                           from Peer_Review_Checklist__c where Grants__c =: recId AND Reviewer__c =: UserInfo.getUserId()];
        if(reviewCheckList.size() > 0) {
            currentReviewChecklistRecord = reviewCheckList[0];
        }
        else {
            Grants__c currentGrantRecord = [Select RecordType.Name, Reference_Number__c from Grants__c where Id =: recId];
            List<Investigator__c> investigatorList = new List<Investigator__c>();
            investigatorList = [Select Investigators_Type__c, Full_Name__c, Institution__c, Institution__r.Name from Investigator__c where Grants__c =: recId];
            currentReviewChecklistRecord = new Peer_Review_Checklist__c();
            currentReviewChecklistRecord.Grants__c = recId;
            currentReviewChecklistRecord.Reviewer__c = UserInfo.getUserId();
            currentReviewChecklistRecord.Name_of_Reviewer__c = UserInfo.getName();
            currentReviewChecklistRecord.Type__c = 'Save';
            currentReviewChecklistRecord.Team_Not_Supportable__c = false;
            currentReviewChecklistRecord.Team_Satisfactory__c = false;
            currentReviewChecklistRecord.Team_Compititive__c = false;
            currentReviewChecklistRecord.Team_Excellent__c = false;
            currentReviewChecklistRecord.Team_Outstanding__c = false;
            for(Investigator__c investigator : investigatorList) {
                if(investigator.Investigators_Type__c == 'Principal Investigator') {
                    if(currentReviewChecklistRecord.Name_of_Lead_PI__c == null) {
                        currentReviewChecklistRecord.Name_of_Lead_PI__c = investigator.Full_Name__c;
                    }
                }
            }
        }
        return currentReviewChecklistRecord;
    }
    
    @AuraEnabled
    public static void saveReviewChecklistRecord(Peer_Review_Checklist__c reviewChecklistRecord, String checklistType) {
        reviewChecklistRecord.Type__c = checklistType;
        upsert reviewChecklistRecord;
    }
    
    @AuraEnabled
    public static Screening_Committee__c getCurrentReviewScreening(String recId) {
        Screening_Committee__c currentReviewScreeningRecord;
        List<Screening_Committee__c> reviewScreeningList = new List<Screening_Committee__c>();
        reviewScreeningList = [Select Application_Taken_Forward_to_Next_Stage__c, Comments_on_the_Application__c, Grants__c,
                               Name_of_Committee_Member__c, Name_of_Co_PIs_and_Organization__c, Name_of_PI_and_Organization__c,
                               Reviewer__c, Scores__c, Type__c 
                           from Screening_Committee__c where Grants__c =: recId AND Reviewer__c =: UserInfo.getUserId()];
        if(reviewScreeningList.size() > 0) {
            currentReviewScreeningRecord = reviewScreeningList[0];
        }
        else {
            Grants__c currentGrantRecord = [Select RecordType.Name, Reference_Number__c from Grants__c where Id =: recId];
            List<Investigator__c> investigatorList = new List<Investigator__c>();
            investigatorList = [Select Investigators_Type__c, Full_Name__c, Institution__c, Institution__r.Name from Investigator__c where Grants__c =: recId];
            currentReviewScreeningRecord = new Screening_Committee__c();
            currentReviewScreeningRecord.Grants__c = recId;
            currentReviewScreeningRecord.Reviewer__c = UserInfo.getUserId();
            currentReviewScreeningRecord.Name_of_Committee_Member__c = UserInfo.getName();
            currentReviewScreeningRecord.Type__c = 'Save';
            for(Investigator__c investigator : investigatorList) {
                if(investigator.Investigators_Type__c == 'Principal Investigator') {
                    if(currentReviewScreeningRecord.Name_of_PI_and_Organization__c == null) {
                        currentReviewScreeningRecord.Name_of_PI_and_Organization__c = investigator.Full_Name__c + ' and ' + investigator.Institution__r.Name;
                    }
                }
                else if(investigator.Investigators_Type__c == 'Co-Principal Investigator') {
                    if(currentReviewScreeningRecord.Name_of_Co_PIs_and_Organization__c == null) {
                        currentReviewScreeningRecord.Name_of_Co_PIs_and_Organization__c = investigator.Full_Name__c + ' and ' + investigator.Institution__r.Name;
                    }
                }
            }
        }
        return currentReviewScreeningRecord;
    }
    
    @AuraEnabled
    public static void saveReviewScreeningRecord(Screening_Committee__c reviewScreeningRecord, String reviewScreeningType) {
        reviewScreeningRecord.Type__c = reviewScreeningType;
        upsert reviewScreeningRecord;
    }
}