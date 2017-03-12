# See bottom of file for license and copyright information
package Foswiki::Plugins::FoswikiOrgPlugin;

use strict;
use warnings;

use Foswiki;
use Foswiki::Func;

use constant TRACE => 1;

our $VERSION = '1.04';
our $RELEASE = '12 Mar 2017';
our $SHORTDESCRIPTION =
  'Adds github WebHook and other utility functions for foswiki.org';
our $NO_PREFS_IN_TOPIC = 1;

# Plugin init method, used to initialise handlers
sub initPlugin {

    # check for Plugins.pm versions, don't register REST handler
    # on older versions of Foswiki.
    unless ( $Foswiki::Plugins::VERSION < 2.3 ) {
        Foswiki::Func::registerRESTHandler(
            'githubpush', \&_RESTgithubpush,
            validate => 0,    # No strikeone applicable
            authenticate =>
              0,    # Github push provides a security token for checking
            http_allow => 'POST',    # Github only will POST.
            description =>
'Handle webhook push requests from GitHub.  Secured by HMAC hash of payload with shared secret.'
        );
    }

  # Register the _FoswikiAgentVersion function to handle %FOSWIKIREQUESTAGENT{}%
    Foswiki::Func::registerTagHandler( 'FOSWIKIREQUESTAGENT',
        \&_FoswikiAgentVersion );

    return 1;
}

sub _RESTgithubpush {

    #my ( $session, $plugin, $verb, $response ) = @_;

    require Foswiki::Plugins::FoswikiOrgPlugin::Core;

    push @_, $_[0]->{request};    # Add the request object
    return Foswiki::Plugins::FoswikiOrgPlugin::Core::_githubPush(@_);

}

sub _FoswikiAgentVersion {

    #    my($session, $params, $topic, $web, $topicObject) = @_;

    my $request = Foswiki::Func::getRequestObject();
    my $ua = $request->userAgent() || '';

    if ( $ua =~ m#Foswiki::Net/V?([^\ _]+)#i ) {
        return $1;
    }
    else {
        return 'unknown';
    }

}
###############################################################################
sub writeDebug {
    return unless TRACE;
    print STDERR "- FoswikiOrgPlugin - " . $_[0] . "\n";

}

###############################################################################
#
# This function controls security of the Task.  If the priority of a task is set
# to "Security", then the ACLs are set to restrict access to the creator, and
# to the security group.
#
sub beforeSaveHandler {
    my ( $text, $topic, $web, $meta ) = @_;

    # Only active in the Tasks web on Item* topics
    return
      unless ( substr( $topic, 0, 4 ) eq 'Item'
        && $web eq $Foswiki::cfg{Plugins}{FoswikiOrgPlugin}{TasksWeb} );

    require Foswiki::Plugins::FoswikiOrgPlugin::Core;
    Foswiki::Plugins::FoswikiOrgPlugin::Core::_beforeSaveHandler(@_);
    return;

}

1;
__END__
Foswiki - The Free and Open Source Wiki, http://foswiki.org/

Copyright (C) 2008-2014 Foswiki Contributors. Foswiki Contributors
are listed in the AUTHORS file in the root of this distribution.
NOTE: Please extend that file, not this notice.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version. For
more details read LICENSE in the root of this distribution.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

As per the GPL, removal of this notice is prohibited.
