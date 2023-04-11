public class AADJITHandler implements Auth.SamlJitHandler {
    // constants with default values
    private static final String DEFAULT_TIMEZONE = 'Europe/Paris';
    private static final String DEFAULT_LOCALE = 'da';
    private static final String DEFAULT_LANGUAGE = 'en_US';
    private static final String DEFAULT_EMAIL_ENCODING = 'UTF-8';
    private static final String DEFAULT_PROFILE = 'Standard User';

    // white list of permission set group assignments to delete if not supplied - any 
    // permission set group not supplied which is not listed here is left untouched
    private static final List<String> PSG_DELETE_WHITE_LIST = new List<String> {'Permission_Set_Group_1', 'Permission_Set_Group_2'};

    public User createUser(Id samlSsoProviderId, Id communityId, Id portalId, String federationId, Map<String,String> attributes, String assertion) {
        // see if we have user based on federation id
        List<User> users = [SELECT Id FROM User WHERE FederationIdentifier =: federationId];
        if (users.size() == 1) return users[0];

        // get profile
        final Profile p = [SELECT Id FROM Profile WHERE Name =: DEFAULT_PROFILE LIMIT 1];

        // create user
        final User u = new User();
        u.firstname = attributes.get('http://schemas.xmlsoap.org/ws/2005/05/identity/claims/FirstName');
        u.lastname = attributes.get('http://schemas.xmlsoap.org/ws/2005/05/identity/claims/LastName');
        u.username = attributes.get('http://schemas.xmlsoap.org/ws/2005/05/identity/claims/Username');
        u.email = attributes.get('http://schemas.xmlsoap.org/ws/2005/05/identity/claims/Email');
        u.ProfileId = attributes.get('http://schemas.xmlsoap.org/ws/2005/05/identity/claims/ProfileId');
        u.alias = attributes.get('http://schemas.xmlsoap.org/ws/2005/05/identity/claims/Alias');
        u.FederationIdentifier = federationId;
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
        u.FederationIdentifier = federationId;
        u.Username = attributes.get('http://schemas.xmlsoap.org/ws/2005/05/identity/claims/Username');
        
        // save the updated user
        UPDATE u;

        // maintain permission set group assignments
        final String permissionSetGroups = attributes.get('http://schemas.xmlsoap.org/ws/2005/05/identity/claims/PSG');
        this.maintainPermissionSetGroupAssignments(u.Id, permissionSetGroups);
    }

    private void maintainPermissionSetGroupAssignments(Id userId, String psgApiNamesStr) {
        System.debug('Received permission set groups API names <' + psgApiNamesStr + '>');
        final List<String> psgApiNames = psgApiNamesStr.split(',');

        // get ID's of permission set assignments for permission set groups for the user
        final List<PermissionSetAssignment> psaCurrent = [SELECT Id, AssigneeId, PermissionSetGroupId FROM PermissionSetAssignment WHERE AssigneeId =: userId AND PermissionSetGroupId != NULL];
        final List<String> psgCurrentIds = new List<String>();
        for (PermissionSetAssignment psa : psaCurrent) psgCurrentIds.Add(psa.PermissionSetGroupId);

        // get ID's of the permission set groups the user must have 
        final List<PermissionSetGroup> psgs = [SELECT Id, DeveloperName FROM PermissionSetGroup WHERE DeveloperName IN :psgApiNames];
        final List<String> psgIds = new List<String>();
        for (PermissionSetGroup psg : psgs) psgIds.add(psg.Id);

        // get ID's of the permission set groups in the delete white list
        final List<PermissionSetGroup> psgsWhiteList = [SELECT Id, DeveloperName FROM PermissionSetGroup WHERE DeveloperName IN :PSG_DELETE_WHITE_LIST];
        final List<String> psgWhiteListIds = new List<String>();
        for (PermissionSetGroup psg : psgsWhiteList) psgWhiteListIds.add(psg.Id);

        // create holders for assignmetns to delete and create
        final List<PermissionSetAssignment> psaDelete = new List<PermissionSetAssignment>();
        final List<PermissionSetAssignment> psaCreate = new List<PermissionSetAssignment>();

        // loop permission set groups to assign
        for (PermissionSetGroup psg : psgs) {
            if (psgCurrentIds.Contains(psg.Id)) {
                System.debug('User is already assigned permission set group with ID <' + psg.Id + '> - ignore');
            } else {
                System.debug('User is NOT assigned permission set group with ID <' + psg.Id + '> - add assignment');
                psaCreate.Add(new PermissionSetAssignment(AssigneeId=userId, PermissionSetGroupId=psg.Id));
            }
        }

        // find permission set groups to delete
        System.debug('Starting to loop prior permission set group assignments to find ones to delete');
        for (PermissionSetAssignment psa : psaCurrent) {
            if (!psgIds.Contains(psa.PermissionSetGroupId) && psgWhiteListIds.Contains(psa.PermissionSetGroupId)) {
                System.debug('User has permission set group with ID <' + psa.PermissionSetGroupId + '> which is white listed but NOT supplied - delete');
                psaDelete.Add(psa);
            }
        }

        // create and delete in bulk
        INSERT psaCreate;
        DELETE psaDelete;
    }

}