# ---+ Extensions
# ---++ FoswikiOrgPlugin
# **PASSWORD 80**
# Specify the secret used to calculate the HMAC signature of the post.
$Foswiki::cfg{Plugins}{FoswikiOrgPlugin}{GithubSecret} = '';

# **REGEX**
# List the branches that should be tracked against tasks.  Checkins against
# other branches than those listed here will be ignored.
$Foswiki::cfg{Plugins}{FoswikiOrgPlugin}{TrackingBranches} =  qr/^(master|Release01x00|Release01x01|Release01x02)$/;

# **BOOLEAN**
# Enable updating of tasks from github messages
$Foswiki::cfg{Plugins}{FoswikiOrgPlugin}{UpdateTasks} = '0';

# **STRING 20**
# Override the webname used for storing tasks.
$Foswiki::cfg{Plugins}{FoswikiOrgPlugin}{TasksWeb} = 'Tasks';

# **PATH**
# If provided, this overrides the normal working directory: 'foswiki/working/work_areas/FoswikiOrgPlugin'
# If directory path does not exist it will be created.
$Foswiki::cfg{Plugins}{FoswikiOrgPlugin}{Workarea} = '';

# **STRING 20**
# Specify the group name used for Security related tasks
$Foswiki::cfg{Plugins}{FoswikiOrgPlugin}{SecurityGroup} = 'AdminGroup';
