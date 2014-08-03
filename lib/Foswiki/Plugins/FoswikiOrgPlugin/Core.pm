# See bottom of file for license and copyright information
package Foswiki::Plugins::FoswikiOrgPlugin::Core;

use strict;
use warnings;

use Foswiki::Plugins::FoswikiOrgPlugin;

use Digest::HMAC_SHA1 qw( hmac_sha1_hex );
use JSON qw( decode_json );
use Fcntl qw(:flock);
use File::Spec;

use Foswiki;
use Foswiki::Func;
use Foswiki::Sandbox;

sub _githubPush {
    my ( $session, $plugin, $verb, $response, $query ) = @_;
    my $msg;    # Collects the response
    my $status = 200;

    Foswiki::Plugins::FoswikiOrgPlugin::writeDebug("REST Handler CORE entered");

    # Extract out the signature for later validation of the payload

    my $sigHead   = $query->header('X-Hub-Signature');
    my $signature = '';

    unless ( $Foswiki::cfg{Plugins}{FoswikiOrgPlugin}{GithubSecret} ) {
        _sendResponse( $session, $response, 500,
'ERROR: (500) Invalid configuration: Shared "GithubSecret" is not configured'
        );
        return undef;
    }

    if ($sigHead) {
        ($signature) = $sigHead =~ m/^sha1=(.*)$/;
    }

    unless ($signature) {
        _sendResponse( $session, $response, 400,
'ERROR: (400) Invalid REST invocation: X-Hub-Signature header missing or incorrect, request forbidden'
        );
        return undef;
    }

    Foswiki::Plugins::FoswikiOrgPlugin::writeDebug("SIGNATURE: $signature");

    # Get the delivery ID for debugging / tracking

    my $delivery = $query->header('X-GitHub-Delivery');
    $delivery ||= 'No delivery id';
    Foswiki::Plugins::FoswikiOrgPlugin::writeDebug("Delivery ID:: $delivery ");

    # Get the payload for processing

    my $payload = $query->param('POSTDATA');

    unless ($payload) {
        _sendResponse( $session, $response, 400,
'ERROR: (400) Invalid REST invocation: No POSTDATA found in request. request rejected'
        );
        return undef;
    }

    # Verify the signature.  Calculate a hmac_sha1 of the payload and secret.
    # It should match the signature in the headers.

    my $payloadSig =
      hmac_sha1_hex( $payload,
        $Foswiki::cfg{Plugins}{FoswikiOrgPlugin}{GithubSecret} );

    Foswiki::Plugins::FoswikiOrgPlugin::writeDebug("CALCULATED: $payloadSig ");

    unless ( $signature eq $payloadSig ) {
        _sendResponse( $session, $response, 403,
'ERROR: (403) Invalid REST invocation: X-Hub-Signature does not match payload signature, request forbidden'
        );
        use Data::Dumper;
        Foswiki::Plugins::FoswikiOrgPlugin::writeDebug(
            Data::Dumper::Dumper( \$query ) );
        return undef;
    }

    # Decode the JSON and do basic validations

    my $payloadRef = decode_json $payload;

    unless ($payloadRef) {
        _sendResponse( $session, $response, 400,
'ERROR: (400) Invalid REST invocation: Unable to decode JSON from the POSTDATA, request rejected.'
        );
        use Data::Dumper;
        Foswiki::Plugins::FoswikiOrgPlugin::writeDebug(
            Data::Dumper::Dumper( \$query ) );
        return undef;
    }

    unless ( $payloadRef->{'ref'} ) {
        _sendResponse( $session, $response, 400,
'ERROR: (400) Invalid REST invocation: No git \'ref\' found in message, Unable to determine branch. request rejected..'
        );
        use Data::Dumper;
        Foswiki::Plugins::FoswikiOrgPlugin::writeDebug(
            Data::Dumper::Dumper( \$query ) );
        return undef;
    }

    # Parse out the branch name.

    my ($branch) = $payloadRef->{'ref'} =~ m#^.*/.*/(.*)$#;
    $branch ||= 'unknown';

    # Check if $branch is one we are tracking
    # If not,  bail out here.

    unless ( $branch =~
        m/$Foswiki::cfg{Plugins}{FoswikiOrgPlugin}{TrackingBranches}/ )
    {
        Foswiki::Plugins::FoswikiOrgPlugin::writeDebug(
"Ignoring commit against $branch does not match $Foswiki::cfg{Plugins}{FoswikiOrgPlugin}{TrackingBranches}"
        );
        _sendResponse( $session, $response, 200,
            "Commits against branch $branch are not being tracked" );
        return undef;
    }

    my $repoRef    = $payloadRef->{'repository'};
    my $repository = $repoRef->{'name'};

    my $commitsRef = $payloadRef->{'commits'};
    unless ( defined $commitsRef ) {
        Foswiki::Plugins::FoswikiOrgPlugin::writeDebug(
            "No commits found in Delivery ID: $delivery");
        _sendResponse( $session, $response, 200,
            'No commits found in this push, ignored.' );
        return undef;
    }

    foreach my $commit (@$commitsRef) {
        my @list;
        my $commitMsg = $commit->{'message'};
        while ( $commitMsg =~ s/\b(Item\d+)\s*:// ) {
            push( @list, $1 );
        }

        _logCommit( $delivery, $repository, $branch, $commit, \@list );

        next unless scalar @list;

        $msg .= "COMMIT ID: $commit->{'id'}";
        $msg .= " Author: "
          . ( $commit->{'author'}{'username'} || $commit->{'author'}{'name'} );
        $msg .=
          " Committer: "
          . (    $commit->{'committer'}{'username'}
              || $commit->{'committer'}{'name'} );
        $msg .= " Repository: $repository ";
        $msg .= " Branch: $branch ";
        $msg .= " Tasks: " . join( ', ', @list ) . "\n";

    }

    $msg ||= 'No commits found';

    _sendResponse( $session, $response, 200, $msg );
    return undef;

}

sub _sendResponse {

    # my ($session, $response, $status, $message) = @_;

    $_[1]->header(
        -type    => 'text/plain',
        -status  => $_[2],
        -charset => 'UTF-8'
    );

    $_[1]->print( $_[3] );
    Foswiki::Plugins::FoswikiOrgPlugin::writeDebug( $_[3] );
}

=tml

---+++ _logCommit

Gets a workarea and appends a record of the commit to a logfile of the repository name.
We might use this to trigger offline processing such as scheduling
git pull events for a local repository.

=cut

sub _logCommit {
    my $delivery   = shift;
    my $repository = shift;
    my $branch     = shift;
    my $commit     = shift;
    my $tasklist   = shift;

    my $now = Foswiki::Time::formatTime( time(), 'servertime' );
    my $message = "| $now | $delivery | $branch | $commit | "
      . join( ',', @$tasklist ) . " |\n";

    my $workPath = Foswiki::Func::getWorkArea('FoswikiOrgPlugin');

    my $repo = Foswiki::Sandbox::untaint( $repository,
        \&Foswiki::Sandbox::validateAttachmentName );
    $repo ||= 'invalidRepo';

    my $log = File::Spec->catfile( $workPath, $repo );

    if ( open( my $file, '>>', $log ) ) {
        binmode $file, ":encoding(utf-8)";
        _lock($file);
        print $file "$message\n";
        close($file);
    }
    else {
        Foswiki::Plugins::FoswikiOrgPlugin::writeDebug(
            "log open $log failed:  $! ");
    }
}

sub _lock {    # borrowed from Log::Dispatch::FileRotate, Thanks!
    my $fh = shift;
    eval { flock( $fh, LOCK_EX ) }; # Ignore lock errors,   not all platforms support flock
                                    # Make sure we are at the EOF
    seek( $fh, 0, 2 );
    return 1;
}

sub _beforeSaveHandler {
    my ( $text, $topic, $web, $meta ) = @_;

    Foswiki::Plugins::FoswikiOrgPlugin::writeDebug(
        "called beforeSaveHandler($web, $topic)");

#  Read the Priority, ReportedBy and WaitingFor fields from the form
#  %META:FIELD{name="CurrentState" attributes="M" title="CurrentState" value="Being Worked On"}%
#  %META:FIELD{name="Priority" attributes="M" title="[[Priority]]" value="Normal"}%
#  %META:FIELD{name="ReportedBy" attributes="M" title="ReportedBy" value="Main.OlivierRaginel"}%
#  %META:FIELD{name="WaitingFor" attributes="" title="WaitingFor" value="Main.OlivierRaginel, GeorgeClark"}%

    # Load the old topic prior to edit to examine the security controls
    my $oldMeta =
      Foswiki::Meta->load( $Foswiki::Plugins::SESSION, $web, $topic );

    my $securedTopic = 0;
    my $oldPriority;
    my $oldState;

    my $fieldData = $oldMeta->get( 'FIELD', 'Priority' );
    if ( defined $fieldData ) {
        $oldPriority = $fieldData->{'value'};
    }

    $fieldData = $oldMeta->get( 'FIELD', 'CurrentState' );
    if ( defined $fieldData ) {
        $oldState = $fieldData->{'value'};
    }

    if (   $oldPriority eq 'Security'
        && $oldState ne 'Closed'
        && $oldState ne 'No Action Required' )
    {
        Foswiki::Plugins::FoswikiOrgPlugin::writeDebug(
            "Topic was secured by task state");
        $securedTopic = 1;
    }

    # get rid of old meta,  we don't need it any further.
    $oldMeta->finish();

    my $taskPriority;
    my $reportedBy;
    my $waitingFor;
    my $currentState;

    $fieldData = $meta->get( 'FIELD', 'Priority' );
    if ( defined $fieldData ) {
        $taskPriority = $fieldData->{'value'};
    }

    $fieldData = $meta->get( 'FIELD', 'ReportedBy' );
    if ( defined $fieldData ) {
        $reportedBy = $fieldData->{'value'};
    }

    $fieldData = $meta->get( 'FIELD', 'WaitingFor' );
    if ( defined $fieldData ) {
        $waitingFor = $fieldData->{'value'};
    }

    $fieldData = $meta->get( 'FIELD', 'CurrentState' );
    if ( defined $fieldData ) {
        $currentState = $fieldData->{'value'};
    }

    if (   $taskPriority eq 'Security'
        && $currentState ne 'Closed'
        && $currentState ne 'No Action Required' )
    {

        my @users;

        push( @users,
                $Foswiki::cfg{UsersWebName} . '.'
              . $Foswiki::cfg{SuperAdminGroup} );
        push( @users, split( ',', $reportedBy ) );
        push( @users, split( ',', $waitingFor ) );

# SMELL:  It would be nice to actually validate that the the listed users are actually real users
# but trunk.foswiki.org doesn't have a user database avaiable. So we just take what we have.

        $meta->putKeyed(
            'PREFERENCE',
            {
                name  => 'ALLOWTOPICVIEW',
                title => 'ALLOWTOPICVIEW',
                type  => 'Set',
                value => join( ', ', @users ),
            }
        );
        Foswiki::Plugins::FoswikiOrgPlugin::writeDebug(
            "Security preference set based upon Task state.");

    }

# Only remove the access control if the topic was previously secured by automatic controls.
    elsif ($securedTopic) {
        $meta->remove( 'PREFERENCE', 'ALLOWTOPICVIEW' );
        Foswiki::Plugins::FoswikiOrgPlugin::writeDebug(
            "Security preference removed based upon Task state.");
    }

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
