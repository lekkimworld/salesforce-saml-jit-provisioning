# Salesforce SAML JIT Provisioning

**Please Note:** I assume absolutely no responsibility for any of the code in this repository. Use at your own risk.

Sample Apex classes that implement the `Auth.SamlJitHandler` interface for a SAML just-in-time (JIT) provisioning 
to occur based on data in the SAML assertion. The classes will handle both creating and updating users based on 
the data in the assertion. The class also maintains the permisssion set group assignments for the user based on 
assertion data. In the repo you'll find an implementation for Azure (`AADJITHandler.cls`) and for Google `GoogleJITHandler.cls`. Both 
extend a common abstract base class with some common functionality.

The `PSG_DELETE_WHITE_LIST` list in the class is used to ensure the class only deletes permission set group 
assignments we have whitelisted i.e. not permission set groups assigned manually in the org.

Note: The `AADJITHandler.cls` utilizes custom Azure AD claims as its claim types. It is advised that you make the necessary modifications to http://schemas.xmlsoap.org/ws/2005/05/identity/claims/* to match your SAML provider's attribute requirements and availability. 

One method for identifying your claim types is to analyze the SAML response assertion using a SAML decoder, such as https://developer.pingidentity.com/en/tools/saml-decoder.html.

The standard Salesforce accepted claims are listed here and does not support Permission Set &/ Permission Set Group assignments: https://help.salesforce.com/s/articleView?language=en_US&id=sf.sso_jit_requirements.htm&type=5
Example:
User.Username
User.Email
User.LastName
User.ProfileId
