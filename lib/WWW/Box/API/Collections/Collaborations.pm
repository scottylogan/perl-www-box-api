package WWW::Box::API::Collections::Collaborations;

use strict;
use warnings;

use Carp qw(carp croak);

use base 'WWW::Box::API::Collection';

sub _init {    ## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
    my $self = shift;

    if ($self->{'path'} && $self->{'id'}) {
        $self->{'collection'}
          = $self->{'path'} . q{/} . $self->{'id'} . '/collaborations';
    } else {
        $self->{'collection'} = 'collaborations?notify=false';
    }

    $self->{'all_key'} = 'id';

    return;
}

## Box documentation on group collaborations lacks any useful
## info.
##
## The owner of the folder must also be an admin of the group
## that's being added
## the request also needs to include a 'type' field, set to 'group'
## in the 'accessible_by' property

sub add {
    my ($self, %opts) = @_;

    if ($self->{'collection'} ne 'collaborations?notify=false') {
        carp 'Can only add collaborations under /collaborations';
        return;
    }

    if (   !defined($opts{'folder_id'})
        || !defined($opts{'role'})
        || (!defined($opts{'group_id'}) && !defined($opts{'user_id'})))
    {
        carp 'Need folder_id, role, and user_id or group_id'
          . ' to create collaboration';
        return;
    }

    my %req = (
        'item' => {
            'id'   => $opts{'folder_id'},
            'type' => 'folder',
        },
        'accessible_by' => {},
        'role'          => $opts{'role'},
    );

    if (defined($opts{'group_id'})) {
        $req{'accessible_by'}->{'type'} = 'group';
        $req{'accessible_by'}->{'id'}   = $opts{'group_id'};
    }

    if (defined($opts{'user_id'})) {
        $req{'accessible_by'}->{'type'} = 'user';
        $req{'accessible_by'}->{'id'}   = $opts{'user_id'};
    }

    return $self->SUPER::add(%req);
}

1;
