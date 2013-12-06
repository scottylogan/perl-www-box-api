package WWW::Box::API::Collections::GroupMemberships;

use strict;
use warnings;

use Carp qw(carp croak);

use base 'WWW::Box::API::Collection';

sub _init {    ## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
    my $self = shift;

    if ($self->{'path'} && $self->{'id'}) {
        $self->{'collection'}
          = $self->{'path'} . q{/} . $self->{'id'} . '/memberships';
    } else {
        $self->{'collection'} = 'group_memberships';
    }

    $self->{'all_key'} = 'id';

    return;
}

sub add {
    my ($self, %opts) = @_;

    if ($self->{'collection'} ne 'group_memberships') {
        carp 'Can only add group memberships under /group_memberships';
        return;
    }

    if (   !defined($opts{'group_id'})
        || !defined($opts{'user_id'})
        || !defined($opts{'role'}))
    {
        carp 'Need group_id, user_id and role to create group membership';
        return;
    }

    my %req = (
        'group' => {
            'id' => $opts{'group_id'},
        },
        'user' => {
            'id' => $opts{'user_id'},
        },
        'role' => $opts{'role'},
    );

    return $self->SUPER::add(%req);
}

1;
