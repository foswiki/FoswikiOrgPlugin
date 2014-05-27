# See bottom of file for license and copyright information
package Foswiki::Plugins::FoswikiOrgPlugin;

use strict;
use warnings;

use Foswiki;
use Foswiki::Func;

our $VERSION           = '1.0';
our $RELEASE           = '1.0';
our $SHORTDESCRIPTION  = 'Adds github WebHook to accept push notifications';
our $NO_PREFS_IN_TOPIC = 1;

# Plugin init method, used to initialise handlers
sub initPlugin {
    Foswiki::Func::registerRESTHandler(
        'githubpush', \&_RESTgithubpush,
        validate     => 0,  # No strikeone applicable
        authenticate => 0,  # Github push provides a security token for checking
        http_allow => 'GET,POST',    # Github only will POST.
        description =>
'Handle webhook push requests from GitHub.  Secured by HMAC hash of payload with shared secret.'
    );
    return 1;
}

sub _RESTgithubpush {

    #my ( $session, $plugin, $verb, $response ) = @_;

    require Foswiki::Plugins::FoswikiOrgPlugin::Core;

    push @_, $_[0]->{request};    # Add the request object
    return Foswiki::Plugins::FoswikiOrgPlugin::Core::_githubPush(@_);

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
