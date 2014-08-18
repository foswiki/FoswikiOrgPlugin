# See the bottom of the file for description, copyright and license information
package FoswikiOrgPluginTests;

use FoswikiFnTestCase;
our @ISA = qw( FoswikiFnTestCase );

use strict;
use Error (':try');

sub new {
    my $self = shift()->SUPER::new(@_);
    return $self;
}

sub set_up {
    my $this = shift;
    $this->SUPER::set_up();

    my $ItemTemplateText = <<TMPL;
%META:TOPICINFO{author="ProjectContributor" comment="reprev" date="1348637084" format="1.1" version="106"}%

| *Name*  | *Type* | *Size* | *Values* | *Tooltip message* | *Attributes* |
| Summary | text | 85 | | | M |
| ReportedBy | text | 35 | %WIKIUSERNAME% | | M |
| Codebase | checkbox | 5 | | |
| SVN Range | text | 8 | | | |
| AppliesTo | select | 1 | | | M |
| Component | textboxlist | | | If applicable |
| [[Priority]] | select | 1 | | | M |
| CurrentState | select | 1 |  | | M |
| WaitingFor | textboxlist | | | |  |
| Checkins | text | 35 | | | |
| TargetRelease | radio, n/a | 4 | | |
| ReleasedIn| select | 1 | | | |
| CheckinsOnBranches | text | 35 | | | |
| trunkCheckins | text | 35 | | | |
| Release01x01Checkins | text | 35 | | | |
| Release01x02Checkins | text | 35 | | | |

TMPL

    my $topicObject = Foswiki::Meta->new(
        $this->{session}, $this->{test_web},
        "ItemTemplate",   $ItemTemplateText
    );
    $topicObject->save();

    my $testTask = <<TASK;
%META:TOPICINFO{author="ProjectContributor" date="1407889321" format="1.1" version="131"}%
---+!! Migrate to git

Migrate the core infrastructure away from Subversion, to git.

-- Main.ProjectContributor - 20 Nov 2011

%COMMENT%

%META:FORM{name="ItemTemplate"}%
%META:FIELD{name="Summary" attributes="M" title="Summary" value="Migrate from subversion to git"}%
%META:FIELD{name="ReportedBy" attributes="M" title="ReportedBy" value="Main.ProjectContributor"}%
%META:FIELD{name="Codebase" attributes="" title="[[Codebase]]" value=""}%
%META:FIELD{name="SVNRange" attributes="" title="SVN Range" value=""}%
%META:FIELD{name="AppliesTo" attributes="M" title="AppliesTo" value="Engine"}%
%META:FIELD{name="Component" attributes="" title="Component" value="SCM"}%
%META:FIELD{name="Priority" attributes="M" title="[[Priority]]" value="Security"}%
%META:FIELD{name="CurrentState" attributes="M" title="CurrentState" value="Being Worked On"}%
%META:FIELD{name="WaitingFor" attributes="" title="WaitingFor" value="Main.JoeUser"}%
%META:FIELD{name="Checkins" attributes="" title="Checkins" value="Foswikirev:17890 Foswikirev:17891 Foswikirev:17898 Foswikirev:17899"}%
%META:FIELD{name="TargetRelease" attributes="" title="TargetRelease" value="n/a"}%
%META:FIELD{name="ReleasedIn" attributes="" title="ReleasedIn" value="n/a"}%
%META:FIELD{name="CheckinsOnBranches" attributes="" title="CheckinsOnBranches" value="Release01x01 trunk"}%
%META:FIELD{name="trunkCheckins" attributes="" title="trunkCheckins" value="Foswikirev:17898 Foswikirev:17899"}%
%META:FIELD{name="Release01x01Checkins" attributes="" title="Release01x01Checkins" value="Foswikirev:17890 Foswikirev:17891"}%
%META:PREFERENCE{name="VIEW_TEMPLATE" title="VIEW_TEMPLATE" type="Set" value="ItemView"}%
TASK

    $topicObject =
      Foswiki::Meta->new( $this->{session}, $this->{test_web}, "Item11267",
        $testTask );
    $topicObject->save();

}

sub loadExtraConfig {
    my $this = shift;
    $this->SUPER::loadExtraConfig();
    $Foswiki::cfg{Plugins}{FoswikiOrgPlugin}{Enabled} = 1;
    $Foswiki::cfg{Plugins}{FoswikiOrgPlugin}{Module} =
      'Foswiki::Plugins::FoswikiOrgPlugin';
    $Foswiki::cfg{Plugins}{FoswikiOrgPlugin}{GithubSecret} = 'asdfasdf';
    $Foswiki::cfg{Plugins}{FoswikiOrgPlugin}{TrackingBranches} =
      qr/^(master|Release01x00|Release01x01|Release01x02)$/;
    $Foswiki::cfg{Plugins}{FoswikiOrgPlugin}{Workarea}      = '';
    $Foswiki::cfg{Plugins}{FoswikiOrgPlugin}{TasksWeb}      = $this->{test_web};
    $Foswiki::cfg{Plugins}{FoswikiOrgPlugin}{SecurityGroup} = 'SecurityGroup';
}

sub tear_down {
    my $this = shift;
    $this->SUPER::tear_down();
}

sub test_update_Task {
    my $this = shift;

    require Foswiki::Plugins::FoswikiOrgPlugin::Core;

    my $topicObject =
      Foswiki::Meta->load( $this->{session}, $this->{test_web}, "Item11267" );

    #print $topicObject->getEmbeddedStoreForm();

    my $repository = 'distro';
    my $branch     = 'master';
    my $commitID   = 'deadbeefdead';
    my $taskItem   = 'Item11267';

    Foswiki::Plugins::FoswikiOrgPlugin::Core::_updateTask( $repository, $branch,
        $commitID, $taskItem );

    $topicObject =
      Foswiki::Meta->load( $this->{session}, $this->{test_web}, "Item11267" );
    my $formField = $topicObject->get( 'FIELD', 'Checkins' );
    my $value = $formField->{'value'};
    $this->assert_equals(
"Foswikirev:17890 Foswikirev:17891 Foswikirev:17898 Foswikirev:17899 %GITREF{distro:deadbeefdead}%",
        $value
    );
    $formField = $topicObject->get( 'FIELD', 'masterCheckins' );
    $value = $formField->{'value'};
    $this->assert_matches( qr/%GITREF{distro:deadbeefdead}%/, $value );

}
1;
__END__

Plugin for Foswiki - The Free and Open Source Wiki, http://foswiki.org/

Copyright (C) 2014 George Clark and Foswiki Contributors.
All Rights Reserved. Foswiki Contributors
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

For licensing info read LICENSE file in the Foswiki root.

Author: George Clark
