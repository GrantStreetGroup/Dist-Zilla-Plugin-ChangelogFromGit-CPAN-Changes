use Test::Roo;
use lib 't/lib';
with 'Test::DZP::Changes';

test not_releasing_no_changelog => sub {
    my $self = shift;
    $ENV{DZIL_RELEASING} = 0;
    $self->tzil->build;
    my $changes_file = $self->tzil->tempdir->child('build/Changes');
    ok !$changes_file->is_file, 'No changes file created';
};

test v1_defaults => sub {
    my $self = shift;
    $self->test_changes('v1_defaults');
};

test v1_no_author => sub {
    my $self = shift;
    $self->changes_opts->{show_author} = 0;
    $self->test_changes('v1_no_author');
};

test v1_email => sub {
    my $self = shift;
    $self->changes_opts->{show_author_email} = 1;
    $self->test_changes('v1_email');
};

test v1_group_author => sub {
    my $self = shift;
    $self->changes_opts->{group_by_author} = 1;
    $self->test_changes('v1_group_author');
};

test v1_group_author_email => sub {
    my $self = shift;
    $self->changes_opts->{group_by_author}   = 1;
    $self->changes_opts->{show_author_email} = 1;
    $self->test_changes('v1_group_author_email');
};

run_me({test_repo_name => 'test_repo'});
done_testing;
