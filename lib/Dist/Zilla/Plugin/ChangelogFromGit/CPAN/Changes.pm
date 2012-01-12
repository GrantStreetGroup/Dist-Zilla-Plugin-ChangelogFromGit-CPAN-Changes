package Dist::Zilla::Plugin::ChangelogFromGit::CPAN::Changes;

# ABSTRACT: Format Changelogs using CPAN::Changes

use Moose;
use CPAN::Changes;
use CPAN::Changes::Release;

extends 'Dist::Zilla::Plugin::ChangelogFromGit';

sub render_changelog {
    my ($self) = @_;

    my $cpan_changes = CPAN::Changes->new( preamble => 'Changelog for ' . $self->zilla->name, );

    foreach my $release ( reverse $self->all_releases ) {
        next if $release->has_no_changes;    # no empties

        my $version = $release->version;
        if ( $version eq 'HEAD' ) {
            $version = $self->zilla->version;
        }

        my $cpan_release = CPAN::Changes::Release->new(
            version => $version,
            date    => $release->date,
        );

        foreach my $change ( @{ $release->changes } ) {
            next if ( $change->description =~ /^\s/ );    # no empties
            my $group = $change->author_name;

            # sometimes author_name contains the "Full Name <email@address.com>"
            # sometimes not, so do a lazy check
            if ( $change->author_name !~ m/@/ ) {
                $group .= ' <' . $change->author_email . '>';
            }

            # XXX: do we want the change_id?
            # $group .= ' ' .  $change->change_id;

            $cpan_release->add_changes( { group => $group }, $change->description, );
        }

        $cpan_changes->add_release($cpan_release);
    }

    return $cpan_changes->serialize;
}

__PACKAGE__->meta->make_immutable;

1;

=head1 SEE ALSO

L<Dist::Zilla::Plugin::ChangelogFromGit::Debian> which was used as a template for this

