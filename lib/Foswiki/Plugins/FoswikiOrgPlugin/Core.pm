# See bottom of file for license and copyright information
package Foswiki::Plugins::FoswikiOrgPlugin::Core;

use strict;
use warnings;

use Digest::HMAC_SHA1 qw( hmac_sha1_hex );
use JSON qw( decode_json );

use Foswiki;
use Foswiki::Func;

use constant TRACE => 1;

sub _githubPush {
    my ( $session, $plugin, $verb, $response, $query ) = @_;
    my $msg;    # Collects the response
    my $status = 200;

    print STDERR "REST Handler CORE entered\n" if TRACE;

    my $sigHead   = $query->header('X-Hub-Signature');
    my $signature = '';

    if ($sigHead) {
        ($signature) = $sigHead =~ m/^sha1=(.*)$/;
    }

    unless ($signature) {
        _sendError( $session, $response, 403,
'ERROR: (403) Invalid REST invocation: X-Hub-Signature header missing or incorrect, request forbidden'
        );
        return;
    }

    print STDERR "SIGNATURE: $signature\n" if TRACE;

    my $payload = $query->param('POSTDATA');
    my $payloadSig =
      hmac_sha1_hex( $payload,
        $Foswiki::cfg{Plugins}{FoswikiOrgPlugin}{GithubSecret} );

    print STDERR "CALCULATED: $payloadSig " if TRACE;

    unless ( $signature eq $payloadSig ) {
        _sendError( $session, $response, 403,
'ERROR: (403) Invalid REST invocation: X-Hub-Signature does not match payload signature, request forbidden'
        );
        return;
    }

    my $payloadRef = decode_json $payload;

    my ($branch) = $payloadRef->{'ref'} =~ m#^.*/.*/(.*)$#;
    $branch ||= 'unknown';

    # Check if $branch is one we are tracking
    # If not,  bail out here.

    my $commitsRef = $payloadRef->{'commits'};
    foreach my $commit (@$commitsRef) {
        my @list;
        my $commitMsg = $commit->{'message'};
        while ( $commitMsg =~ s/\b(Item\d+)\s*:// ) {
            push( @list, $1 );
        }

        next unless scalar @list;

        $msg .= "COMMIT ID: $commit->{'id'}";
        $msg .= " Author: $commit->{'author'}{'email'} ";
        $msg .= " Branch: $branch ";
        $msg .= " Tasks: " . join( ', ', @list ) . "\n";

    }
    $response->header(
        -type    => 'text/plain',
        -status  => 200,
        -charset => 'UTF-8'
    );

    $msg = "No tasks found" unless ($msg);
    return $msg;
}

sub _sendError {

    # my ($session, $response, $status, $message) = @_;

    $_[1]->header(
        -type    => 'text/plain',
        -status  => $_[2],
        -charset => 'UTF-8'
    );

    $_[1]->print( $_[3] );
    $_[0]->logger->log( 'warning', $_[3] );
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
