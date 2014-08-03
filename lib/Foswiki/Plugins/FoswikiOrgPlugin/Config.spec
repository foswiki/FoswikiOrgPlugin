# ---+ Extensions
# ---++ FoswikiOrgPlugin
# **PASSWORD 80**
# Specify the secret used to calculate the HMAC signature of the post.
$Foswiki::cfg{Plugins}{FoswikiOrgPlugin}{GithubSecret} = '';

# **REGEX**
# List the branches that should be tracked against tasks.  Checkins against
# other branches than those listed here will be ignored.
$Foswiki::cfg{Plugins}{FoswikiOrgPlugin}{TrackingBranches} =  qr/^(master|Release01x00|Release01x01|Release01x02)$/;

