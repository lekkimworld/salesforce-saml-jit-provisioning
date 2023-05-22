public abstract class AbstractJITHandler implements Auth.SamlJitHandler {
    // constants
    public static final String DEFAULT_TIMEZONE = 'Europe/Copenhagen';
    public static final String DEFAULT_LOCALE = 'en';
    public static final String DEFAULT_LANGUAGE = 'en_UK';
    public static final String DEFAULT_EMAIL_ENCODING = 'UTF-8';
    public static final String DEFAULT_PROFILE_NAME = 'Standard User';

    // ! A list of special permission set groups (PSGs) which will not be removed from the user 
    // ! assignments, even if missing in the psgApiNamesStr
    public static final List<String> PSG_WHITE_LIST = new List<String> {'SF_Admin_PSG'};

    protected void maintainPermissionSetGroupAssignments(Id userId, String psgApiNamesStr) {
        System.debug('Received permission set groups API names <' + psgApiNamesStr + '>');
        final List<String> psgApiNames = psgApiNamesStr.split(',');
        final List<PermissionSetAssignment> psaCurrent = [SELECT Id, AssigneeId, PermissionSetGroupId FROM PermissionSetAssignment WHERE AssigneeId =: userId AND PermissionSetGroupId != NULL];
        final List<String> psgCurrentIds = new List<String>();
        for (PermissionSetAssignment psa : psaCurrent) psgCurrentIds.Add(psa.PermissionSetGroupId);

        // Get PSG ids that the user must have.
        final List<PermissionSetGroup> psgs = [SELECT Id, DeveloperName FROM PermissionSetGroup WHERE DeveloperName IN :psgApiNames];
        final List<String> psgIds = new List<String>();
        for (PermissionSetGroup psg : psgs) psgIds.add(psg.Id);

        // Get the whitelisted PSG ids. These are special PSGs that we will never remove.
        final List<PermissionSetGroup> psgsWhiteList = [SELECT Id, DeveloperName FROM PermissionSetGroup WHERE DeveloperName IN :PSG_WHITE_LIST];
        final List<String> psgWhiteListIds = new List<String>();
        for (PermissionSetGroup psg : psgsWhiteList) psgWhiteListIds.add(psg.Id);

        // Create holders for assignmetns to delete and create
        final List<PermissionSetAssignment> psaDelete = new List<PermissionSetAssignment>();
        final List<PermissionSetAssignment> psaCreate = new List<PermissionSetAssignment>();

        // Handle assignments
        for (PermissionSetGroup psg : psgs) {
            if (psgCurrentIds.Contains(psg.Id)) {
                System.debug('User is already assigned permission set group with ID <' + psg.Id + '> - ignore');
            } else {
                System.debug('User is NOT assigned permission set group with ID <' + psg.Id + '> - add assignment');
                psaCreate.Add(new PermissionSetAssignment(AssigneeId=userId, PermissionSetGroupId=psg.Id));
            }
        }

        // Handle deletions
        System.debug('Starting to loop prior permission set group assignments to find ones to delete');
        for (PermissionSetAssignment psa : psaCurrent) {
            if (!psgIds.Contains(psa.PermissionSetGroupId) && !psgWhiteListIds.Contains(psa.PermissionSetGroupId)) {
                System.debug('User has permission set group with ID <' + psa.PermissionSetGroupId + '> which is white listed but NOT supplied - delete');
                psaDelete.Add(psa);
            }
        }

        // create and delete in bulk
        INSERT psaCreate;
        DELETE psaDelete;
    }

}
