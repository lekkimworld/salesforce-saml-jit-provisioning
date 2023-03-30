# Salesforce SAML JIT Provisioning

**Please Note:** I assume absolutely no responsibility for any of the code in this repository. Use at your own risk.

Sample Apex class implementing the `Auth.SamlJitHandler` interface for a SAML just-in-time (JIT) provisioning 
to occur based on data in the SAML assertion. The class will handle both creating and updating users based on 
the data in the assertion. The class also maintains the permisssion set group assignments for the user based on 
assertion data. 

The `PSG_DELETE_WHITE_LIST` list in the class is used to ensure the class only deletes permission set group 
assignments we have whitelisted i.e. not permission set groups assigned manually in the org.

Note: The MyJitHandler.cls utilizes custom Azure AD claims as its claim types. It is advised that you make the necessary modifications to http://schemas.xmlsoap.org/ws/2005/05/identity/claims/* to match your SAML provider's attribute requirements and availability. 

One method for identifying your claim types is to analyze the SAML response assertion using a SAML decoder, such as https://developer.pingidentity.com/en/tools/saml-decoder.html.

The standard Salesforce accepted claims are listed here and does not support Permission Set &/ Permission Set Group assignments: https://help.salesforce.com/s/articleView?language=en_US&id=sf.sso_jit_requirements.htm&type=5
Example:
User.Username
User.Email
User.LastName
User. ProfileId
