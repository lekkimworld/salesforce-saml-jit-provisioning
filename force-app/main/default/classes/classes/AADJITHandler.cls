public class AADJITHandler extends AbstractJITHandler {
    
    public User createUser(Id samlSsoProviderId, Id communityId, Id portalId, String federationId, Map<String,String> attributes, String assertion) {
        // see if we have user based on federation id
        List<User> users = [SELECT Id FROM User WHERE FederationIdentifier =: federationId];
        if (users.size() == 1) return users[0];

        // get profile if ID not supplied
        String profileId = attributes.get('http://schemas.xmlsoap.org/ws/2005/05/identity/claims/ProfileId');
        if (String.isEmpty(profileId)) {
            final Profile p = [SELECT Id FROM Profile WHERE Name =: DEFAULT_PROFILE_NAME LIMIT 1];    
            profileId = p.Id;
        }

        // create user
        final User u = new User();
        u.firstname = attributes.get('http://schemas.xmlsoap.org/ws/2005/05/identity/claims/FirstName');
        u.lastname = attributes.get('http://schemas.xmlsoap.org/ws/2005/05/identity/claims/LastName');
        u.username = attributes.get('http://schemas.xmlsoap.org/ws/2005/05/identity/claims/Username');
        u.email = attributes.get('http://schemas.xmlsoap.org/ws/2005/05/identity/claims/Email');
        u.alias = attributes.get('http://schemas.xmlsoap.org/ws/2005/05/identity/claims/Alias');
        u.ProfileId = profileId;
        u.IsActive = true;
        u.EmailEncodingKey = DEFAULT_EMAIL_ENCODING;
        u.LanguageLocaleKey = DEFAULT_LANGUAGE;
        u.LocaleSidKey = DEFAULT_LOCALE;
        u.TimeZoneSidKey = DEFAULT_TIMEZONE;
        INSERT u;

        // maintain permission set group assignments
        final String permissionSetGroups = attributes.get('http://schemas.xmlsoap.org/ws/2005/05/identity/claims/PSG');
        this.maintainPermissionSetGroupAssignments(u.Id, permissionSetGroups);

        // return
        return u;
    }

    public void updateUser(Id userId, Id samlSsoProviderId, Id communityId, Id portalId, String federationId, Map<String,String> attributes, String assertion) {
        // get user based on federation id
        User u = [SELECT Id FROM User WHERE FederationIdentifier =: federationId];
        
        // update user fields based on the SAML attributes
        u.FirstName = attributes.get('http://schemas.xmlsoap.org/ws/2005/05/identity/claims/FirstName');
        u.LastName = attributes.get('http://schemas.xmlsoap.org/ws/2005/05/identity/claims/LastName');
        u.Email = attributes.get('http://schemas.xmlsoap.org/ws/2005/05/identity/claims/Email');
        u.Username = attributes.get('http://schemas.xmlsoap.org/ws/2005/05/identity/claims/Username');
        
        // save the updated user
        UPDATE u;

        // maintain permission set group assignments
        final String permissionSetGroups = attributes.get('http://schemas.xmlsoap.org/ws/2005/05/identity/claims/PSG');
        this.maintainPermissionSetGroupAssignments(u.Id, permissionSetGroups);
    }

}