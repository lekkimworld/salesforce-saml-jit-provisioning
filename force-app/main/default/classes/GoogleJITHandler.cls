public class GoogleJITHandler extends AbstractJITHandler {
    public static final String CLAIM_LASTNAME = 'User.LastName';
    public static final String CLAIM_USERNAME = 'User.Username';
    public static final String CLAIM_EMAIL = 'User.Email';
    public static final String CLAIM_PERMISSIONSET_GROUPS = 'PSG';
    public static final String CLAIM_PROFILE_ID = 'User.ProfileId';
    
    public User createUser(Id samlSsoProviderId, Id communityId, Id portalId, String federationId, Map<String,String> attributes, String assertion) {
        // see if we have user based on federation id
        List<User> users = [SELECT Id FROM User WHERE FederationIdentifier =: federationId];
        if (users.size() == 1) return users[0];

        // get profile if ID not supplied
        final String profileId = this.getProfileId(attributes);

        // create user & auto-generate alias
        String now = String.valueOf(DateTime.now().getTime());
        String alias = now.substring(now.length()-8);
        final User u = new User();
        u.lastname = attributes.get(CLAIM_LASTNAME);
        u.username = attributes.get(CLAIM_USERNAME);
        u.email = attributes.get(CLAIM_EMAIL);
        u.FederationIdentifier = federationId;
        u.ProfileId = profileId;
        u.IsActive = true;
        u.EmailEncodingKey = DEFAULT_EMAIL_ENCODING;
        u.LanguageLocaleKey = DEFAULT_LANGUAGE;
        u.LocaleSidKey = DEFAULT_LOCALE;
        u.TimeZoneSidKey = DEFAULT_TIMEZONE;
        u.alias = alias;
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

        // get profile if ID not supplied
        final String profileId = this.getProfileId(attributes);
        
        // update user fields based on the SAML attributes
        u.lastname = attributes.get(CLAIM_LASTNAME);
        u.username = attributes.get(CLAIM_USERNAME);
        u.email = attributes.get(CLAIM_EMAIL);
        u.ProfileId = profileId;
        u.FederationIdentifier = federationId;

        
        // save the updated user
        UPDATE u;

        // maintain permission set group assignments
        final String permissionSetGroups = attributes.get(CLAIM_PERMISSIONSET_GROUPS);
        this.maintainPermissionSetGroupAssignments(u.Id, permissionSetGroups);
    }

    private String getProfileId(Map<String,String> attributes) {
        // get profile if ID not supplied
        String profileId = attributes.get(CLAIM_PROFILE_ID);
        if (String.isEmpty(profileId)) {
            final Profile p = [SELECT Id FROM Profile WHERE Name =: DEFAULT_PROFILE_NAME LIMIT 1];    
            profileId = p.Id;
        }
        return profileId;
    }
}
