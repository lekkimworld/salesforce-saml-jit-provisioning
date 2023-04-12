public class LAJITHandler implements Auth.SamlJitHandler {
    private static final string DEFAULT_TIMEZONE = 'Europe/Paris';
    private static final string DEFAULT_LOCALE = 'da';
    private static final string DEFAULT_LANGUAGE = 'en_US';
    private static final string DEFAULT_EMAIL_ENCODING = 'UTF-8';
    // Delete white listed
    private static final List<String> PSG_WHITE_LIST = new List<String> {'Permission_Set_Group_1', 'Permission_Set_Group_4'};

    public User createUser(Id samlSsoProviderId, Id communityId, Id portalId, String federationId, Map<String,String> attributes, String assertion) {
        // see if we have user based on federation id
        List<User> users = [SELECT Id FROM User WHERE FederationIdentifier =: federationId];
        if (users.size() == 1) return users[0];

        // get profile
        final Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];

        // create user & auto-generate alias
        String now = String.valueOf(DateTime.now().getTime());
        String alias = now.substring(now.length()-8);
        final User u = new User();
        u.lastname = attributes.get('User.LastName');
        u.username = attributes.get('User.Username');
        u.email = attributes.get('User.Email');
        u.ProfileId = attributes.get('User.ProfileId');
        u.FederationIdentifier = federationId;
        u.IsActive = true;
        u.EmailEncodingKey = DEFAULT_EMAIL_ENCODING;
        u.LanguageLocaleKey = DEFAULT_LANGUAGE;
        u.LocaleSidKey = DEFAULT_LOCALE;
        u.TimeZoneSidKey = DEFAULT_TIMEZONE;
        u.alias = alias;
        INSERT u;

        // maintain permission set group assignments
        final String permissionSetGroups = attributes.get('PSG');
        this.maintainPermissionSetGroupAssignments(u.Id, permissionSetGroups);

        // return
        return u;
    }

    public void updateUser(Id userId, Id samlSsoProviderId, Id communityId, Id portalId, String federationId, Map<String,String> attributes, String assertion) {
        // get user based on federation id
        User u = [SELECT Id FROM User WHERE FederationIdentifier =: federationId];
        
        // update user fields based on the SAML attributes
        u.lastname = attributes.get('User.LastName');
        u.username = attributes.get('User.Username');
        u.email = attributes.get('User.Email');
        u.ProfileId = attributes.get('User.ProfileId');
        u.FederationIdentifier = federationId;

        
        // save the updated user
        UPDATE u;

        // maintain permission set group assignments
        final String permissionSetGroups = attributes.get('PSG');
        this.maintainPermissionSetGroupAssignments(u.Id, permissionSetGroups);
    }

    private void maintainPermissionSetGroupAssignments(Id userId, String psgApiNamesStr) {
        System.debug('Received permission set groups API names <' + psgApiNamesStr + '>');
        final List<String> psgApiNames = psgApiNamesStr.split(',');
        final List<PermissionSetAssignment> psaCurrent = [SELECT Id, AssigneeId, PermissionSetGroupId FROM PermissionSetAssignment WHERE AssigneeId =: userId AND PermissionSetGroupId != NULL];
        final List<String> psgCurrentIds = new List<String>();
        for (PermissionSetAssignment psa : psaCurrent) psgCurrentIds.Add(psa.PermissionSetGroupId);

        // maintain permission set assignments for user - get permission set groups the user must have 
        // and get the groups id
        final List<PermissionSetGroup> psgs = [SELECT Id, DeveloperName FROM PermissionSetGroup WHERE DeveloperName IN :psgApiNames];
        final List<String> psgIds = new List<String>();
        for (PermissionSetGroup psg : psgs) psgIds.add(psg.Id);

        // since user may have other permission set groups assigned we maintain a white list of 
        // permission set groups to look at
        final List<PermissionSetGroup> psgsWhiteList = [SELECT Id, DeveloperName FROM PermissionSetGroup WHERE DeveloperName IN :PSG_WHITE_LIST];
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