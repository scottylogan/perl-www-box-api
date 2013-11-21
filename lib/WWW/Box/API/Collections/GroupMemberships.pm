package WWW::Box::API::Collections::GroupMemberships;

use strict;
use warnings;

use Carp qw(carp croak);

use base 'WWW::Box::API::Collection';

sub init {
    my $self = shift;

    $self->{'collection'} = 'group_memberships';
    $self->{'all_key'}    = 'id';

    return;
}

sub add {
    my ($self, $group_id, $user_id, $role) = @_;

    my %req = (
        'group' => {
            'id' => $group_id
        },
        'user' => {
            'id' => $user_id
        },
        'role' => $role,
    );

    return $self->SUPER::add(%req);
}

1;
