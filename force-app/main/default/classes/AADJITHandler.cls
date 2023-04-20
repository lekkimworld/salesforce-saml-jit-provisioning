public class AADJITHandler extends AbstractJITHandler {
    public static final String CLAIM_FIRSTNAME = 'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/FirstName';
    public static final String CLAIM_LASTNAME = 'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/LastName';
    public static final String CLAIM_USERNAME = 'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/Username';
    public static final String CLAIM_EMAIL = 'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/Email';
    public static final String CLAIM_ALIAS = 'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/Alias';
    public static final String CLAIM_PROFILE_ID = 'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/ProfileId';
    public static final String CLAIM_PERMISSIONSET_GROUPS = 'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/PSG';
    
    public User createUser(Id samlSsoProviderId, Id communityId, Id portalId, String federationId, Map<String,String> attributes, String assertion) {
        // see if we have user based on federation id
        List<User> users = [SELECT Id FROM User WHERE FederationIdentifier =: federationId];
        if (users.size() == 1) return users[0];

        // get profile if ID not supplied
        String profileId = attributes.get(CLAIM_PROFILE_ID);
        if (String.isEmpty(profileId)) {
            final Profile p = [SELECT Id FROM Profile WHERE Name =: DEFAULT_PROFILE_NAME LIMIT 1];    
            profileId = p.Id;
        }

        // create user
        final User u = new User();
        u.firstname = attributes.get(CLAIM_FIRSTNAME);
        u.lastname = attributes.get(CLAIM_LASTNAME);
        u.username = attributes.get(CLAIM_USERNAME);
        u.email = attributes.get(CLAIM_EMAIL);
        u.alias = attributes.get(CLAIM_ALIAS);
        u.ProfileId = profileId;
        u.IsActive = true;
        u.EmailEncodingKey = DEFAULT_EMAIL_ENCODING;
        u.LanguageLocaleKey = DEFAULT_LANGUAGE;
        u.LocaleSidKey = DEFAULT_LOCALE;
        u.TimeZoneSidKey = DEFAULT_TIMEZONE;
        INSERT u;

        // maintain permission set group assignments
        final String permissionSetGroups = attributes.get(CLAIM_PERMISSIONSET_GROUPS);
        this.maintainPermissionSetGroupAssignments(u.Id, permissionSetGroups);

        // return
        return u;
    }

    public void updateUser(Id userId, Id samlSsoProviderId, Id communityId, Id portalId, String federationId, Map<String,String> attributes, String assertion) {
        // get user based on federation id
        User u = [SELECT Id FROM User WHERE FederationIdentifier =: federationId];
        
        // update user fields based on the SAML attributes
        u.FirstName = attributes.get(CLAIM_FIRSTNAME);
        u.LastName = attributes.get(CLAIM_LASTNAME);
        u.Email = attributes.get(CLAIM_EMAIL);
        u.Username = attributes.get(CLAIM_USERNAME);
        
        // save the updated user
        UPDATE u;

        // maintain permission set group assignments
        final String permissionSetGroups = attributes.get(CLAIM_PERMISSIONSET_GROUPS);
        this.maintainPermissionSetGroupAssignments(u.Id, permissionSetGroups);
    }

}