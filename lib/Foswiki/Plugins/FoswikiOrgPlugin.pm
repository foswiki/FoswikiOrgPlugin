# See bottom of file for license and copyright information
package Foswiki::Plugins::FoswikiOrgPlugin;

use strict;
use warnings;

use Digest::HMAC_SHA1 qw( hmac_sha1_hex );

use Foswiki;
use Foswiki::Func;

our $VERSION           = '1.0';
our $RELEASE           = '1.0';
our $SHORTDESCRIPTION  = 'Adds github WebHook to accept push notifications';
our $NO_PREFS_IN_TOPIC = 1;

# Plugin init method, used to initialise handlers
sub initPlugin {
    Foswiki::Func::registerRESTHandler(
        'githubpush', \&_githubPush,
        validate     => 0,  # No strikeone applicable
        authenticate => 0,  # Github push provides a security token for checking
        http_allow => 'GET,POST'    # Github only will POST.
    );
    return 1;
}

sub _githubPush {
    my ( $session, $plugin, $verb, $response ) = @_;

    print STDERR "REST Handler entered\n";

    my $query = $session->{request};

    my $sigHead   = $query->header('X-Hub-Signature');
    my $signature = '';

    if ($sigHead) {
        ($signature) = $sigHead =~ m/^sha1=(.*)$/;
    }

    print STDERR "SIGNATURE: $signature\n";

    my $payload = $query->param('POSTDATA');
    my $payloadSig =
      hmac_sha1_hex( $payload,
        $Foswiki::cfg{Plugins}{FoswikiOrgPlugin}{GithubSecret} );

    print STDERR "CALCULATED: $payloadSig ";

    unless ( $signature eq $payloadSig ) {
        print STDERR " ... FAIL:  Signature failed to match \n";
    }

    #    use Data::Dumper;
    #    print STDERR Data::Dumper::Dumper( \$query );

    return undef;
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
