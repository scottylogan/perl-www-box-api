package WWW::Box::API::Collections::Folders;

use strict;
use warnings;

use Carp qw(carp croak);

use base 'WWW::Box::API::Collection';

sub init {
    my $self = shift;

    $self->{'collection'} = 'folders';
    $self->{'all_key'}    = 'name';

    return;
}

sub add {
    my ($self, $name, $parent_id) = @_;

    $parent_id = '0'
      unless (defined($parent_id));

    my %req = (
        'name'   => $name,
        'parent' => {
            'id' => $parent_id
        }
    );

    return $self->SUPER::add(%req);
}

1;
