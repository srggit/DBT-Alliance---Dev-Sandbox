public class GrantApplicationPDFController{
    public TSGForm form {get;set;}
    
    public GrantApplicationPDFController(){
        String recordId = ApexPages.currentPage().getParameters().get('id');
        if(String.isNotBlank(recordId )){
            this.form = new TSGForm(recordId);
            form.meetingDate = date.today();
            form.grantsFundingName = 'Grants Funding Committee Interview Meeting';
            form.comments = '';
            form.isAdmin = true;
            form.currentReviewChecklist = [SELECT Id, Name, Lead_Institution__c, Queries_sent_to_Applicants__c,Co_Institution_1__c, Investigator__c, Co_Institution_2__c, All_Investigators_Eligible__c, All_Organizations_Eligible__c, Role_of_all_Investigators__c, Time_Commitment_Satisfactory__c, Proposal_Within_Remit__c, Abstract_Appropriate__c, Proposal_within_word_limit__c, Clinical_Trial_Proposed__c, CRTP_Proposed__c, Access_of_CSDU_Available__c, Research_Management_plan_Presented__c, Sustainability_plan_Presented__c, Satisfactory_Representation_of_Milestone__c, Satisfactory_Representation_of_Timelines__c, Guidelines_for_Figures_and_table__c, Guidelines_followed_for_References__c, Publications_in_CVs_as_per_Guidelines__c, Format_for_grants_in_CVs_per_guidelines__c, No_Other_Affiliations_any_Investigator__c, Pending_Applications_other_Agencies__c, Animal_Number_Calculation_Provided__c, Any_Experiment_on_big_Animals__c, Source_of_Human_Samples__c, No_link_with_Commercial_Organizations__c, Restricted_reviewers_not_Included__c, Appropriate_Undertaking_investigators__c, Appropriate_Undertaking_from_Institution__c, Budget_within_cap__c, No_Disallowed_costs__c, No_Mismatch_in_Calculation__c, Salary_for_PIs_not_Requested__c, Distribution_of_funds__c, Ref_No__c, Grants__c, GA__c, Reference_Number__c, LI_Name_and_Organisation__c, CO_1_Name_and_Organisation__c, CO_2_Name_and_Organisation__c, Type__c, Comments__c, Comments_from_Secretary__c,  Any_Additional_Concern__c, Response_from_Later_Stages__c, Name_of_Investigator2__c, Name_of_Investigator1__c, Salaries_for_PIs__c, Support_Staff_salaries__c, Materials_and_consumables__c, Animals__c, Equipment__c, Access_charges__c, Miscellaneous__c, Travel_costs__c, Flexible_Funding_Allowance__c, Sub_Total__c, Overheads__c, Total__c FROM Checklist__c WHERE Grants__c = : recordId];
            form.currentPeerReviewChecklist = [SELECT Id, Name, Grants__c, Name_of_Lead_PI__c, Name_of_Reviewer__c, Address_of_Reviewer__c, Potential_Conflicts_of_Interest__c, Track_Record_of_the_Team__c, Collaboration__c, Feasibility_of_Project_and_Research__c, Strengths__c, Weaknesses__c, Time_Commitment__c, Resources__c, Why_the_Resources_not_Appropriate__c, Feedback_to_Applicants__c, Research_on_Animals__c, Research_Involving_Human_Participation__c, Institutional_Support__c, Data_Management_and_Sharing__c, Impact__c, Reviewer__c, Type__c, Team_Not_Supportable__c, Team_Satisfactory__c, Team_Compititive__c, Project_Excellent__c, Team_Excellent__c, Project_Outstanding__c, Team_Outstanding__c, Project_Not_Supportable__c, Project_Satisfactory__c, Project_Compititive__c, Summarise_Ratings__c FROM Peer_Review_Checklist__c WHERE Grants__c = : recordId];
            form.currentSCCChecklist = [SELECT Id, Name, Grants__c, Application_Taken_Forward_to_Next_Stage__c, Comments_on_the_Application__c, Name_of_Co_PIs_and_Organization__c, Name_of_Committee_Member__c, Name_of_PI_and_Organization__c, Scores__c, Reviewer__c, Type__c FROM Screening_Committee__c WHERE Grants__c = : recordId];
            
            List<Assigned_Reviewer__c> arList = [SELECT Id, Grants__c, Assigned_User__r.Name, Status__c FROM Assigned_Reviewer__c WHERE Grants__c = : recordId];
            for(Assigned_Reviewer__c ar : arList ){
                if(ar.Status__c != null && ar.Status__c.equalsignorecase('Submitted')){ form.refereeCommentsReceivedList.add(ar.Assigned_User__r.Name);
                }else{ form.reportnotReceivedList.add(ar.Assigned_User__r.Name); }
            }
        }
    }
}