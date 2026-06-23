/**
 * An apex page controller that exposes the site forgot password functionality
 */
public with sharing class CNT_ForgotPasswordController {
    public String username {get; set;}   
       
    public CNT_ForgotPasswordController() {}
	
  	public PageReference forgotPassword() {
        if(username == '' || username == null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please enter username'));
            return null;
        }
  		boolean success = Site.forgotPassword(username);
  		PageReference pr = Page.VFP_ForgotPasswordConfirm;
  		pr.setRedirect(true);
  		
  		if (success) {  			
  			return pr;
  		}
  		return null;
  	}
    
    public PageReference cancel() {
  		PageReference pr = Page.VFP_CommunityLogin;
  		pr.setRedirect(true);
  		return pr;
  	}
}