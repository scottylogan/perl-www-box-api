package WWW::Box::API::Collections::Folders;

use strict;
use warnings;

use Carp qw(carp croak);

use base 'WWW::Box::API::Collection';

sub _init {    ## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
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

sub collaborations {
    my ($self, $folder_id) = @_;
    return WWW::Box::API::Collections::Collaborations->new(
        $self->{'client'},
        'path' => $self->{'collection'},
        'id'   => $folder_id
    );
}

1;
