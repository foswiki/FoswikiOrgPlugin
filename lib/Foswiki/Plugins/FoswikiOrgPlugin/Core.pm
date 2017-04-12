# See bottom of file for license and copyright information
package Foswiki::Plugins::FoswikiOrgPlugin::Core;

use strict;
use warnings;

use Foswiki::Plugins::FoswikiOrgPlugin;
use Data::Dumper;

use Digest::HMAC_SHA1 qw( hmac_sha1_hex );
use JSON qw( decode_json );
use Fcntl qw(:flock);
use File::Spec;
use File::Path qw/make_path/;

use Foswiki;
use Foswiki::Func;
use Foswiki::Meta;
use Foswiki::Sandbox;
use Foswiki::Time;

sub _githubPush {
    my ( $session, $plugin, $verb, $response, $query ) = @_;
    my $status = 200;

    Foswiki::Plugins::FoswikiOrgPlugin::writeDebug("REST Handler CORE entered");

    # Extract out the signature for later validation of the payload

    my $sigHead   = $query->header('X-Hub-Signature');
    my $signature = '';

    unless ( $Foswiki::cfg{Plugins}{FoswikiOrgPlugin}{GithubSecret} ) {
        _sendResponse( $response, 500,
'ERROR: (500) Invalid configuration: Shared "GithubSecret" is not configured'
        );
        return undef;
    }

    if ($sigHead) {
        ($signature) = $sigHead =~ m/^sha1=(.*)$/;
    }

    unless ($signature) {
        _sendResponse( $response, 400,
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
    $payload = Foswiki::encode_utf8($payload);

    unless ($payload) {
        _sendResponse( $response, 400,
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
        _sendResponse( $response, 403,
'ERROR: (403) Invalid REST invocation: X-Hub-Signature does not match payload signature, request forbidden'
        );
        Foswiki::Plugins::FoswikiOrgPlugin::writeDebug(
            Data::Dumper::Dumper( \$query ) );
        return undef;
    }

    return _processValidatedPayload( $session, $response, $query, $payload )

}

sub _processValidatedPayload {
    my ( $session, $response, $query, $payload ) = @_;
    my $msg;    # Collects the response

    # Decode the JSON and do basic validations

    my $payloadRef = decode_json $payload;

    unless ($payloadRef) {
        _sendResponse( $response, 400,
'ERROR: (400) Invalid REST invocation: Unable to decode JSON from the POSTDATA, request rejected.'
        );
        Foswiki::Plugins::FoswikiOrgPlugin::writeDebug(
            Data::Dumper::Dumper( \$query ) );
        return undef;
    }

    if (   $payloadRef->{'zen'}
        && $payloadRef->{'hook'}
        && !$payloadRef->{'ref'} )
    {
        _sendResponse( $response, 200, 'PING Received!' );
        return undef;
    }

    unless ( $payloadRef->{'ref'} ) {
        _sendResponse( $response, 400,
'ERROR: (400) Invalid REST invocation: No git \'ref\' found in message, Unable to determine branch. request rejected..'
        );
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
        _sendResponse( $response, 200,
            "Commits against branch $branch are not being tracked" );
        return undef;
    }

    my $repoRef    = $payloadRef->{'repository'};
    my $repository = $repoRef->{'name'};

    my $commitsRef = $payloadRef->{'commits'};
    unless ( defined $commitsRef ) {
        _sendResponse( $response, 200,
            'No commits found in this push, ignored.' );
        return undef;
    }

    foreach my $commit (@$commitsRef) {
        my @list;
        my $commitMsg = $commit->{'message'};

        while ( $commitMsg =~ s/\b(Item\d+)\s*:// ) {
            push( @list, $1 );
            _updateTask( $repository, $branch, $commit, $1 )
              if ( $Foswiki::cfg{Plugins}{FoswikiOrgPlugin}{UpdateTasks} );
        }

        _logCommit( $repository, $branch, $commit, \@list );

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

    _sendResponse( $response, 200, $msg );
    return undef;

}

sub _sendResponse {

    # my ( $response, $status, $message) = @_;
    # Unit tests doesn't pass in a $response

    if ( defined $_[0] ) {
        $_[0]->header(
            -type    => 'text/plain',
            -status  => $_[1],
            -charset => 'UTF-8'
        );
        $_[0]->print( $_[2] );
    }
    else {
        print STDERR $_[2] . "\n";
    }
    Foswiki::Plugins::FoswikiOrgPlugin::writeDebug( $_[2] );
}

=tml

---+++ _searchMapTable( $userHash ) -> $cUID

Examines the "Author" or "Committer" hash from a github commit notification.
Three fields are available.   github userid, email address,  and user name.

Match the 3 components against entries in the Git map table.  Use the matching
username on an exact match.

Return undef if nothing found.

=cut

sub _searchMapTable {

    # my $userHash = shift;
    # $_[0]->{email}        # github email address
    # $_[0]->{username}     # github userid
    # $_[0]->{name}         # Full name used github registration

    my $cUID;
    my @wikiNames;

    my $mapTopic = $Foswiki::cfg{Plugins}{FoswikiOrgPlugin}{GitUserMap}
      || 'System.GitUserMap';
    my ( $web, $topic ) = Foswiki::Func::normalizeWebTopicName( '', $mapTopic );
    ( undef, my $maptable ) = Foswiki::Func::readTopic( $web, $topic );
    my @map = $maptable =~ m/^\|\s*(.*?)$/msg;

    #print STDERR "Map Table " . Data::Dumper::Dumper( \@map );

    foreach my $row (@map) {

        my ( $name, $email, $username, $wikiname ) = split( /\s*\|\s*/, $row );

        if (   $_[0]->{name}
            && $_[0]->{name} eq $name
            && $_[0]->{username}
            && $_[0]->{username} eq $username
            && $_[0]->{email}
            && $_[0]->{email} eq $email )
        {
            my $cUID =
              $Foswiki::Plugins::SESSION->{users}
              ->getCanonicalUserID($wikiname);
            Foswiki::Plugins::FoswikiOrgPlugin::writeDebug(
"_searchMapTable found $wikiname for $_[0]->{name}:$_[0]->{username}:$_[0]->{email} "
            );
            return $cUID;
        }
    }

    Foswiki::Plugins::FoswikiOrgPlugin::writeDebug(
"_searchMapTable failed for $_[0]->{name}:$_[0]->{username}:$_[0]->{email} "
    );

    return;
}

=tml

---+++ _findcUID( $userHash ) -> $cUID

Examines the "Author" or "Committer" hash from a github commit notification.
Three fields are available.   github userid, email address,  and user name.

Email address is probably the most secure, so if wikiname(s) are found for the
commit email, use it.  If more than one,  see if the User Name can morph to match
one of the names.  This is probably not necessary since we don't permit email address
reuse, but historically there are some out there.

If no email address match is found,  see if a "wikified" user name matches.

Return undef if nothing found.

=cut

sub _findcUID {

    # my $userHash = shift;
    # $_[0]->{email}        # github email address
    # $_[0]->{username}     # github userid
    # $_[0]->{name}         # Full name used github registration

    my $cUID;
    my @wikiNames;

    if ( defined $_[0]->{email} ) {
        @wikiNames = Foswiki::Func::emailToWikiNames( $_[0]->{email}, 1 );

        if ( scalar @wikiNames == 1 ) {

            # Single match - good
            Foswiki::Plugins::FoswikiOrgPlugin::writeDebug(
                "_findcUID: Found single $wikiNames[0] for $_[0]->{email} ");

# SMELL: We should really use Func::getCanonicalUserID,  but it always returns an ID,
# And we don't want to default to the logged in (ie guest) user if this fails.
            return $Foswiki::Plugins::SESSION->{users}
              ->getCanonicalUserID( $wikiNames[0] );
        }
    }

# Either no email was defined (unlikely)  or it doesn't match up with an existing user registration
# Or we found multiple possible wikinames.  Check if the full name matches a registered wikiname.

    # {name} is the full name the user registered with on github.com
    # Make it into a wikiword.

    my $tryName = $_[0]->{name} || '';
    $tryName =~ s/\s//g;    # Remove any white space
    unless ( Foswiki::Func::isValidWikiWord($tryName) ) {

        # The simple transform didn't work,
        # Split on spaces and make sure each part begins with Upper.

        $tryName = '';
        my @nameParts = split( /\s/, ( $_[0]->{name} || '' ) );
        foreach my $part (@nameParts) {
            $part = ucfirst($part);
            $tryName .= $part;
        }
    }

    # Try to match one of the WikiNames with the github user name
    if ( scalar @wikiNames ) {
        foreach my $wname (@wikiNames) {
            if ( $tryName eq $wname ) {
                Foswiki::Plugins::FoswikiOrgPlugin::writeDebug(
                    "_findcUID: Found matching $tryName for $_[0]->{email} ");
                return $Foswiki::Plugins::SESSION->{users}
                  ->getCanonicalUserID($tryName);
            }
        }
        Foswiki::Plugins::FoswikiOrgPlugin::writeDebug(
            "_findcUID: No exact match for $_[0]->{email}, using $wikiNames[0] "
        );
        return $Foswiki::Plugins::SESSION->{users}
          ->getCanonicalUserID( $wikiNames[0] )
          ;    # Just return the first if none matched the github name
    }

    # Just try what we have for WikiName,
    Foswiki::Plugins::FoswikiOrgPlugin::writeDebug(
        "_findcUID: No email match for $_[0]->{email}, using $tryName ");
    return $Foswiki::Plugins::SESSION->{users}->getCanonicalUserID($tryName);

}

=tml

---+++ _updateTask

Applies the commit to the data form entry in the task.

=cut

sub _updateTask {
    my $repository = shift;
    my $branch     = shift;
    my $commit     = shift;
    my $taskItem   = shift;

    my $commitID = substr( $commit->{id}, 0, 12 );

    unless (
        Foswiki::Func::topicExists(
            $Foswiki::cfg{Plugins}{FoswikiOrgPlugin}{TasksWeb}, $taskItem
        )
      )
    {
        print STDERR "- FoswikiOrgPlugin - $taskItem not found\n";
        Foswiki::Plugins::FoswikiOrgPlugin::writeDebug("$taskItem not found");
        return undef;
    }

    # No need to check access permission,  Github key required for access

    my ( $meta, undef ) = Foswiki::Func::readTopic(
        $Foswiki::cfg{Plugins}{FoswikiOrgPlugin}{TasksWeb}, $taskItem );

    my $changed;

    my $formField = $meta->get( 'FIELD', 'CheckinsOnBranches' );
    my $value;
    $value = $formField->{'value'} if ( defined $formField );
    unless ( $value && $value =~ m/\b\Q$branch\E\b/ ) {
        $changed = 1;
        Foswiki::Plugins::FoswikiOrgPlugin::writeDebug(
            "Added $branch to CheckinsOnBranches for $taskItem");
        $value .= ' ' if $value;
        $value .= $branch;
        $meta->putKeyed( 'FIELD',
            { name => 'CheckinsOnBranches', value => $value } );
    }

# Adjust for Item specific branches.   The complete branch name was recorded in CheckinsOnBranches
# but the individual commits are combined into 'ItemBranchCheckins'
    if ( $branch =~ m/^(Item[0-9]{4,6})/ ) {
        $branch = 'ItemBranch';
    }

    foreach my $field ( 'Checkins', "${branch}Checkins" ) {
        my $formField = $meta->get( 'FIELD', $field );
        my $value;
        $value = $formField->{'value'} if ( defined $formField );
        unless ( $value && $value =~ m/\Q%GITREF{$repository:$commitID}%\E/ ) {
            $changed = 1;
            Foswiki::Plugins::FoswikiOrgPlugin::writeDebug(
                "Added $commitID to $field for $taskItem");
            $value .= ' ' if $value;
            $value .= "%GITREF{$repository:$commitID}%";
            $meta->putKeyed( 'FIELD', { name => $field, value => $value } );
        }
    }

    #DEBUG:
    #print STDERR Data::Dumper::Dumper( \$commit->{'author'} );
    #print STDERR Data::Dumper::Dumper( \$commit->{'committer'} );

    my $cUID =
         _findcUID( $commit->{'author'} )
      || _findcUID( $commit->{'committer'} )
      || _searchMapTable( $commit->{'author'} )
      || _searchMapTable( $commit->{'committer'} )
      || 'ProjectContributor';
    if ($changed) {
        my $newRev = $meta->save( author => $cUID );
        Foswiki::Plugins::FoswikiOrgPlugin::writeDebug(
            "Saved r$newRev of $taskItem");
    }
    return;
}

=tml

---+++ _logCommit

Gets a workarea and appends a record of the commit to a logfile of the repository name.
We might use this to trigger offline processing such as scheduling
git pull events for a local repository.

=cut

sub _logCommit {
    my $repository = shift;
    my $branch     = shift;
    my $commit     = shift;
    my $tasklist   = shift;

    my $workPath;
    my $now = Foswiki::Time::formatTime( time(), 'iso', 'gmtime' );
    my $message =
      "| $now |  $branch | $commit->{'id'} | " . join( ',', @$tasklist ) . " |";

    if ( $Foswiki::cfg{Plugins}{FoswikiOrgPlugin}{Workarea} ) {
        $workPath = $Foswiki::cfg{Plugins}{FoswikiOrgPlugin}{Workarea};
        File::Path::make_path($workPath) unless ( -d $workPath );
    }
    else {
        $workPath = Foswiki::Func::getWorkArea('FoswikiOrgPlugin');
    }

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

    my $securedTopic = 0;
    my $oldPriority  = '';
    my $oldState     = '';
    my $fieldData;

    if ( Foswiki::Func::topicExists( $web, $topic ) ) {

        # Load the old topic prior to edit to examine the security controls
        my $oldMeta =
          Foswiki::Meta->load( $Foswiki::Plugins::SESSION, $web, $topic );

        $fieldData = $oldMeta->get( 'FIELD', 'Priority' );
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
    }

    my $taskPriority = '';
    my $reportedBy   = '';
    my $waitingFor   = '';
    my $currentState = '';

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
              . $Foswiki::cfg{Plugins}{FoswikiOrgPlugin}{SecurityGroup} );
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
