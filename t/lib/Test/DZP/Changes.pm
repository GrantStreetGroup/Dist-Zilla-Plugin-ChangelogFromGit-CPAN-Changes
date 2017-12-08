package Test::DZP::Changes;

use Test::Roo::Role;
use Test::DZil;
use Test::CPAN::Changes;
use Test::TempDir::Tiny;
use Archive::Tar;
use File::chdir;
use Dist::Zilla::File::InMemory;
use Path::Tiny;

has test_repo_name => (is => 'ro',   required => 1);
has test_repo      => (is => 'lazy');
has tzil           => (is => 'lazy', clearer  => 1);

has changes_opts => (
    is      => 'ro',
    lazy    => 1,
    default => sub { {} },
    clearer => 1,
);

has _test_data_dir => (
    is      => 'ro',
    default => sub { path('t', 'data') });

# initialise the Dzil test builder object
sub _build_tzil {
    my $self = shift;

    my @plugins =
      (['GatherDir' => {exclude_filename => 'Changes'}], 'FakeRelease');

    if ($self->changes_opts) {
        push @plugins,
          ['ChangelogFromGit::CPAN::Changes' => $self->changes_opts];
    } else {
        push @plugins, 'ChangelogFromGit::CPAN::Changes';
    }

    my $tzil = Builder->from_config(
        {dist_root => $self->test_repo},
        {
            add_files => {'source/dist.ini' => simple_ini(@plugins)}
        },
    );
    return $tzil;
}

# extracts the test git repo from a tarball
sub _build_test_repo {
    my $self = shift;

    my $repo_dir = path(tempdir);
    my $repo_archive =
      $self->_test_data_dir->child('repos', $self->test_repo_name . '.tar.gz')
      ->absolute;

    local $CWD = $repo_dir;    ## no critic (ProhibitLocalVars)

    diag "Extracting $repo_archive to $repo_dir";

    Archive::Tar->extract_archive($repo_archive);

    return $repo_dir->child($self->test_repo_name)->absolute;
}

after teardown => sub { shift->test_repo->remove_tree({safe => 0}) };
after each_test => sub {
    my $self = shift;
    $self->clear_tzil;
    $self->clear_changes_opts;
};

sub test_changes {
    my ($self, $expected_name) = @_;

    $self->tzil->release;

    my $changes_file = $self->tzil->tempdir->child('build/Changes');
    changes_file_ok $changes_file;

    my $expected_file =
      $self->_test_data_dir->child('changes', $expected_name);
    my @expected_changes = $expected_file->lines_utf8;
    my @got_changes      = $changes_file->lines_utf8;

    diag "Comparing $changes_file to $expected_file";

    # everything should match except the date
    for my $i (0 .. scalar @expected_changes - 1) {
        if ($expected_changes[$i] =~ /^\d+\.\d{3}/) {
            like $got_changes[$i],
              qr/^\d+\.\d{3}(_\d+)? \d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z?$/,
              'Matched line';
        } else {
            is $got_changes[$i], $expected_changes[$i], 'Matched line';
        }
    }

    return;
}

1;
