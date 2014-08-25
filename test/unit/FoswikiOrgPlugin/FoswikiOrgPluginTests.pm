# See the bottom of the file for description, copyright and license information
package FoswikiOrgPluginTests;

use FoswikiFnTestCase;
our @ISA = qw( FoswikiFnTestCase );

use strict;
use Error (':try');

my $payload =
'{"ref": "refs/heads/master","after": "ccb0cad41b8678d722528a06f862dc7ebc27738e","before": "417c46b6f957a37077df7dbebdea30ec4e873092","created": false,"deleted": false,"forced": false,"compare": "https://github.com/foswiki/distro/compare/417c46b6f957...ccb0cad41b86","commits": [{"id": "291ba7fcbc52189da37ef82ab353229f9426abb4","distinct": true,"message": "Item11267: Add unit tests for year in 2-digit notation.","timestamp": "2014-08-21T21:19:08-04:00","url": "https://github.com/foswiki/distro/commit/291ba7fcbc52189da37ef82ab353229f9426abb4","author": {"name": "The Author","email": "theauthor@foswiki.com","username": "theauthor"},"committer": {"name": "The Comitter","email": "committer@foswiki.com","username": "committer"},"added": [],"removed": [],"modified": ["SpreadSheetPlugin/test/unit/SpreadSheetPlugin/SpreadSheetPluginTests.pm"]},{"id": "ccb0cad41b8678d722528a06f862dc7ebc27738e","distinct": true,"message": "Item11267: make time functions work with dates before 1970\n\nA date before 01.01.1970 has a negative epoch. Perl time functions can handle this. This patch allows a negative epoch in CALC time functions.","timestamp": "2014-08-21T21:19:19-04:00","url": "https://github.com/foswiki/distro/commit/ccb0cad41b8678d722528a06f862dc7ebc27738e","author": {"name": "The Author","email": "theauthor@foswiki.com","username": "theauthor"},"committer": {"name": "The Comitter","email": "committer@foswiki.com","username": "thecommit"},"added": [],"removed": [],"modified": ["SpreadSheetPlugin/lib/Foswiki/Plugins/SpreadSheetPlugin/Calc.pm","SpreadSheetPlugin/test/unit/SpreadSheetPlugin/SpreadSheetPluginTests.pm"]}],"head_commit": {"id": "ccb0cad41b8678d722528a06f862dc7ebc27738e","distinct": true,"message": "Item11267: make time functions work with dates before 1970\n\nA date before 01.01.1970 has a negative epoch. Perl time functions can handle this. This patch allows a negative epoch in CALC time functions.","timestamp": "2014-08-21T21:19:19-04:00","url": "https://github.com/foswiki/distro/commit/ccb0cad41b8678d722528a06f862dc7ebc27738e","author": {"name": "The Author","email": "theauthor@foswiki.com","username": "theauthor"},"committer": {"name": "The Comitter","email": "committer@foswiki.com","username": "thecommit"},"added": [],"removed": [],"modified": ["SpreadSheetPlugin/lib/Foswiki/Plugins/SpreadSheetPlugin/Calc.pm","SpreadSheetPlugin/test/unit/SpreadSheetPlugin/SpreadSheetPluginTests.pm"]},"repository": {"id": 23052818,"name": "distro","full_name": "foswiki/distro","owner": {"name": "foswiki","email": "foswiki-discuss@lists.sourceforge.net"},"private": false,"html_url": "https://github.com/foswiki/distro","description": "START HERE!  This is the Foswiki project \"Distribution\".  It is a monolith repository with the core + default extensions.","fork": false,"url": "https://github.com/foswiki/distro","forks_url": "https://api.github.com/repos/foswiki/distro/forks","keys_url": "https://api.github.com/repos/foswiki/distro/keys{/key_id}","collaborators_url": "https://api.github.com/repos/foswiki/distro/collaborators{/collaborator}","teams_url": "https://api.github.com/repos/foswiki/distro/teams","hooks_url": "https://api.github.com/repos/foswiki/distro/hooks","issue_events_url": "https://api.github.com/repos/foswiki/distro/issues/events{/number}","events_url": "https://api.github.com/repos/foswiki/distro/events","assignees_url": "https://api.github.com/repos/foswiki/distro/assignees{/user}","branches_url": "https://api.github.com/repos/foswiki/distro/branches{/branch}","tags_url": "https://api.github.com/repos/foswiki/distro/tags","blobs_url": "https://api.github.com/repos/foswiki/distro/git/blobs{/sha}","git_tags_url": "https://api.github.com/repos/foswiki/distro/git/tags{/sha}","git_refs_url": "https://api.github.com/repos/foswiki/distro/git/refs{/sha}","trees_url": "https://api.github.com/repos/foswiki/distro/git/trees{/sha}","statuses_url": "https://api.github.com/repos/foswiki/distro/statuses/{sha}","languages_url": "https://api.github.com/repos/foswiki/distro/languages","stargazers_url": "https://api.github.com/repos/foswiki/distro/stargazers","contributors_url": "https://api.github.com/repos/foswiki/distro/contributors","subscribers_url": "https://api.github.com/repos/foswiki/distro/subscribers","subscription_url": "https://api.github.com/repos/foswiki/distro/subscription","commits_url": "https://api.github.com/repos/foswiki/distro/commits{/sha}","git_commits_url": "https://api.github.com/repos/foswiki/distro/git/commits{/sha}","comments_url": "https://api.github.com/repos/foswiki/distro/comments{/number}","issue_comment_url": "https://api.github.com/repos/foswiki/distro/issues/comments/{number}","contents_url": "https://api.github.com/repos/foswiki/distro/contents/{+path}","compare_url": "https://api.github.com/repos/foswiki/distro/compare/{base}...{head}","merges_url": "https://api.github.com/repos/foswiki/distro/merges","archive_url": "https://api.github.com/repos/foswiki/distro/{archive_format}{/ref}","downloads_url": "https://api.github.com/repos/foswiki/distro/downloads","issues_url": "https://api.github.com/repos/foswiki/distro/issues{/number}","pulls_url": "https://api.github.com/repos/foswiki/distro/pulls{/number}","milestones_url": "https://api.github.com/repos/foswiki/distro/milestones{/number}","notifications_url": "https://api.github.com/repos/foswiki/distro/notifications{?since,all,participating}","labels_url": "https://api.github.com/repos/foswiki/distro/labels{/name}","releases_url": "https://api.github.com/repos/foswiki/distro/releases{/id}","created_at": 1408318013,"updated_at": "2014-08-21T00:28:29Z","pushed_at": 1408670421,"git_url": "git://github.com/foswiki/distro.git","ssh_url": "git@github.com:foswiki/distro.git","clone_url": "https://github.com/foswiki/distro.git","svn_url": "https://github.com/foswiki/distro","homepage": "http://foswiki.org/","size": 0,"stargazers_count": 1,"watchers_count": 1,"language": "Perl","has_issues": true,"has_downloads": true,"has_wiki": true,"forks_count": 0,"mirror_url": null,"open_issues_count": 0,"forks": 0,"open_issues": 0,"watchers": 1,"default_branch": "master","stargazers": 1,"master_branch": "master","organization": "foswiki"},"pusher": {"name": "thecommit","email": "thecommit@users.noreply.github.com"},"distinct_commits": [{"id": "291ba7fcbc52189da37ef82ab353229f9426abb4","distinct": true,"message": "Item11267: Add unit tests for year in 2-digit notation.","timestamp": "2014-08-21T21:19:08-04:00","url": "https://github.com/foswiki/distro/commit/291ba7fcbc52189da37ef82ab353229f9426abb4","author": {"name": "The Author","email": "theauthor@foswiki.com","username": "theauthor"},"committer": {"name": "The Comitter","email": "committer@foswiki.com","username": "thecommit"},"added": [],"removed": [],"modified": ["SpreadSheetPlugin/test/unit/SpreadSheetPlugin/SpreadSheetPluginTests.pm"]},{"id": "ccb0cad41b8678d722528a06f862dc7ebc27738e","distinct": true,"message": "Item11267: make time functions work with dates before 1970\n\nA date before 01.01.1970 has a negative epoch. Perl time functions can handle this. This patch allows a negative epoch in CALC time functions.","timestamp": "2014-08-21T21:19:19-04:00","url": "https://github.com/foswiki/distro/commit/ccb0cad41b8678d722528a06f862dc7ebc27738e","author": {"name": "The Author","email": "theauthor@foswiki.com","username": "theauthor"},"committer": {"name": "The Comitter","email": "committer@foswiki.com","username": "thecommit"},"added": [],"removed": [],"modified": ["SpreadSheetPlugin/lib/Foswiki/Plugins/SpreadSheetPlugin/Calc.pm","SpreadSheetPlugin/test/unit/SpreadSheetPlugin/SpreadSheetPluginTests.pm"]}],"ref_name": "master"}';

#'   # vim formatting messes up due to the long line.   This restores it.

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
%META:FIELD{name="Checkins" attributes="" title="Checkins" value="Foswikirev:17890 Foswikirev:17891 Foswikirev:17898 Foswikirev:17899 %GITREF{distro:deadbeefdead}%"}%
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

    $Foswiki::cfg{Register}{AllowLoginName} = 0;

    $this->registerUser( 'theauthor', 'The', "Author",
        'theauthor@foswiki.com' );
    $this->registerUser( 'thecommit', 'The', "Committer",
        'committer@foswiki.com' );

    # 2nd wikiname with same email
    $this->registerUser( 'anotherauthor', 'Another', "Author",
        'theauthor@foswiki.com' );
    $this->registerUser( 'thecommit2', 'The', "Committer2",
        'committer@foswiki.com' );
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
    $Foswiki::cfg{Plugins}{FoswikiOrgPlugin}{UpdateTasks}   = 1;
}

sub tear_down {
    my $this = shift;
    $this->SUPER::tear_down();
}

sub test_processValidatedPayload {
    my $this = shift;

    require Foswiki::Plugins::FoswikiOrgPlugin::Core;

    Foswiki::Plugins::FoswikiOrgPlugin::Core::_processValidatedPayload(
        $this->{session}, undef, undef, $payload );

    my $topicObject =
      Foswiki::Meta->load( $this->{session}, $this->{test_web}, "Item11267" );

    my $ti = $topicObject->get('TOPICINFO');
    $this->assert_equals( 'TheAuthor', $ti->{author} );

    my $formField = $topicObject->get( 'FIELD', 'masterCheckins' );
    my $value = $formField->{'value'};
    $this->assert_equals(
        '%GITREF{distro:291ba7fcbc52}% %GITREF{distro:ccb0cad41b86}%', $value );

    $formField = $topicObject->get( 'FIELD', 'Checkins' );
    $value = $formField->{'value'};
    $this->assert_matches( qr/%GITREF{distro:deadbeefdead}%/, $value );

    $formField = $topicObject->get( 'FIELD', 'CheckinsOnBranches' );
    $value = $formField->{'value'};
    $this->assert_equals( 'Release01x01 trunk master', $value );
}

sub test_update_Task {
    my $this = shift;

    require Foswiki::Plugins::FoswikiOrgPlugin::Core;

    my $topicObject =
      Foswiki::Meta->load( $this->{session}, $this->{test_web}, "Item11267" );

    my $repository = 'distro';
    my $branch     = 'master';
    my $taskItem   = 'Item11267';

    my %commit;
    $commit{'id'} = 'deadbeefdead';

    Foswiki::Plugins::FoswikiOrgPlugin::Core::_updateTask( $repository,
        $branch, \%commit, $taskItem );

    $topicObject =
      Foswiki::Meta->load( $this->{session}, $this->{test_web}, "Item11267" );
    my $formField = $topicObject->get( 'FIELD', 'Checkins' );
    my $value = $formField->{'value'};

    # Make sure it didn't get added twice
    $this->assert_equals(
"Foswikirev:17890 Foswikirev:17891 Foswikirev:17898 Foswikirev:17899 %GITREF{distro:deadbeefdead}%",
        $value
    );

    $formField = $topicObject->get( 'FIELD', 'masterCheckins' );
    $value = $formField->{'value'};
    $this->assert_matches( qr/%GITREF{distro:deadbeefdead}%/, $value );

    $formField = $topicObject->get( 'FIELD', 'CheckinsOnBranches' );
    $value = $formField->{'value'};
    $this->assert_equals( 'Release01x01 trunk master', $value );

    my $ti = $topicObject->get('TOPICINFO');
    $this->assert_equals( 'ProjectContributor', $ti->{author} );
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
