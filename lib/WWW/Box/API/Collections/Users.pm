package WWW::Box::API::Collections::Users;

use strict;
use warnings;

use Carp qw(carp croak);

use base 'WWW::Box::API::Collection';
use WWW::Box::API::Collections::UserAliases;

sub _init {    ## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
    my $self = shift;

    $self->{'collection'}      = 'users';
    $self->{'required_fields'} = ['login', 'name'];
    $self->{'all_key'}         = 'login';

    return;
}

sub memberships {
    my ($self, $user_id) = @_;
    return WWW::Box::API::Collections::GroupMemberships->new(
        $self->{'client'},
        'path' => $self->{'collection'},
        'id'   => $user_id
    );
}

sub aliases {
    my ($self, $user_id) = @_;
    return WWW::Box::API::Collections::UserAliases->new($self->{'client'},
        'path' => $self->{'collection'} . q{/} . $user_id);
}

1;
