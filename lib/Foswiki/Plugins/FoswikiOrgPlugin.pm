# See bottom of file for license and copyright information
package Foswiki::Plugins::FoswikiOrgPlugin;

use strict;
use warnings;

use Foswiki;
use Foswiki::Func;

use constant TRACE => 1;

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

###############################################################################
sub writeDebug {
    return unless TRACE;
    print STDERR "- FoswikiOrgPlugin - " . $_[0] . "\n";

    #Foswiki::Func::writeDebug("- NatEditPlugin - $_[0]");
}

###############################################################################
#
# This function controls security of the Task.  If the priority of a task is set
# to "Security", then the ACLs are set to restrict access to the creator, and
# to the security group.
#
sub beforeSaveHandler {
    my ( $text, $topic, $web, $meta ) = @_;

    writeDebug("called beforeSaveHandler($web, $topic)");

    # Only active in the Tasks web on Item* topics
    return unless ( substr( $topic, 0, 4 ) eq 'Item' && $web eq 'Tasks' );

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
        writeDebug("Topic was secured by task state");
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
        writeDebug("Security preference set based upon Task state.");

    }

# Only remove the access control if the topic was previously secured by automatic controls.
    elsif ($securedTopic) {
        $meta->remove( 'PREFERENCE', 'ALLOWTOPICVIEW' );
        writeDebug("Security preference removed based upon Task state.");
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
