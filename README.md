# Salesforce SAML JIT Provisioning

**Please Note:** I assume absolutely no responsibility for any of the code in this repository. Use at your own risk.

Sample Apex class implementing the `Auth.SamlJitHandler` interface for a SAML just-in-time (JIT) provisioning 
to occur based on data in the SAML assertion. The class will handle both creating and updating users based on 
the data in the assertion. The class also maintains the permisssion set group assignments for the user based on 
assertion data. 

The `PSG_DELETE_WHITE_LIST` list in the class is used to ensure the class only deletes permission set group 
assignments we have whitelisted i.e. not permission set groups assigned manually in the org.

