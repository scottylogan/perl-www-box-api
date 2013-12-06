package WWW::Box::API::Collections::Groups;

use strict;
use warnings;

use Carp qw(carp croak);

use base 'WWW::Box::API::Collection';

sub _init {    ## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
    my $self = shift;

    $self->{'collection'}      = 'groups';
    $self->{'required_fields'} = ['name'];
    $self->{'all_key'}         = 'name';

    return;
}

sub memberships {
    my ($self, $group_id) = @_;
    return WWW::Box::API::Collections::GroupMemberships->new(
        $self->{'client'},
        'path' => $self->{'collection'},
        'id'   => $group_id
    );
}

sub collaborations {
    my ($self, $group_id) = @_;
    return WWW::Box::API::Collections::Collaborations->new(
        $self->{'client'},
        'path' => $self->{'collection'},
        'id'   => $group_id
    );
}

1;
