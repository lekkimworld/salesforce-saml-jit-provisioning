public abstract class AbstractJITHandler implements Auth.SamlJitHandler {
    // constants
    public static final String DEFAULT_TIMEZONE = 'Europe/Paris';
    public static final String DEFAULT_LOCALE = 'da';
    public static final String DEFAULT_LANGUAGE = 'en_US';
    public static final String DEFAULT_EMAIL_ENCODING = 'UTF-8';
    public static final String DEFAULT_PROFILE_NAME = 'Standard User';

    // white list of permission set group assignments to delete if not supplied - any 
    // permission set group not supplied which is not listed here is left untouched
    public static final List<String> PSG_WHITE_LIST = new List<String> {'Permission_Set_Group_1', 'Permission_Set_Group_4'};

    protected void maintainPermissionSetGroupAssignments(Id userId, String psgApiNamesStr) {
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