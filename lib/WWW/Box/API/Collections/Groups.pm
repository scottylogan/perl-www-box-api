package WWW::Box::API::Collections::Groups;

use strict;
use warnings;

use Carp qw(carp croak);

use base 'WWW::Box::API::Collection';

sub init {
    my $self = shift;

    $self->{'collection'}      = 'groups';
    $self->{'required_fields'} = ['name'];
    $self->{'all_key'}         = 'name';

    return;
}

1;
