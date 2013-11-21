package WWW::Box::API::Collections::Users;

use strict;
use warnings;

use Carp qw(carp croak);

use base 'WWW::Box::API::Collection';

sub init {
    my $self = shift;

    $self->{'collection'}      = 'users';
    $self->{'required_fields'} = ['login', 'name'];
    $self->{'all_key'}         = 'login';

    return;
}

sub memberships {
    my ($self, $user_id) = @_;

    return $self->SUPER::get_subresource($user_id, 'memberships');
}

1;
