package WWW::Box::API::Collections::UserAliases;

use strict;
use warnings;

use Carp qw(carp croak);

use base 'WWW::Box::API::Collection';

sub _init {    ## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
    my $self = shift;
    my $path = $self->{'path'}
      or croak('UserAlias construction requires a path');

    $self->{'collection'}      = $path . '/email_aliases';
    $self->{'required_fields'} = ['email'];
    $self->{'all_key'}         = 'email';

    return;
}

1;
