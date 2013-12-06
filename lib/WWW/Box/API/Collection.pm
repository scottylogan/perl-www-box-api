package WWW::Box::API::Collection;

use 5.010;

use strict;
use warnings;

use Carp qw(carp croak);
use LWP;
use JSON;

sub new {
    my ($class, $client, %opts) = @_;
    my $self = { 'client' => $client };
    foreach my $k (keys %opts) {
        $self->{$k} = $opts{$k};
    }
    bless $self, $class;
    $self->_init(%opts);
    return $self;
}

sub _init {
    croak('WWW::Box::API::Collection::init should never be called');
}

# Get data from the Box.com V2 API, with support for pagination
# Returns the last HTTP request status and an array of entries
# Warns if things fail.
#
# Callers can specify the page size in the request (page_size),
# and a subset of fields to return (fields=field1,field2,...)
#
# See http://developers.box.com/docs/#fields for documentation
# on the fields parameter, and # and http://developers.box.com/docs/
# for documentation on the offset and limit parameters
#
# NOTE: return parameters are ordered differently from post_request:
#       status, data rather than data, status
sub all {
    my ($self, %opts) = @_;

    my $offset      = 0;
    my $key         = $self->{'all_key'};
    my $total_count = undef;
    my $count       = 0;
    my $entries     = {};
    my %headers     = ('Accept' => 'application/json');

    # create the base URI for requests
    my $uri = $self->{'client'}->new_uri($self->{'collection'});

    for my $opt ('fields', 'filter_term') {
        if (defined($opts{$opt})) {
            $uri->query_param($opt => $opts{$opt});
        }
    }

    if (defined($opts{'limit'})) {
        $uri->query_param('limit' => $opts{'limit'});
    }

    while (!defined($total_count) || $count < $total_count) {
        # use $count for the offset, since there's no guarantee that
        # each request will return $limit entries
        $uri->query_param('offset' => $count);

        my $response = $self->{'client'}->get($uri);

        if ($self->{'client'}->status != 200) {
            carp('Box: error retrieving data: ' . $uri->as_string . "\n");
            # syslog ('err', 'error retrieving data from box.com');
            last;
        }

        # For the managed users command, we can get back multiple people with
        # the same name thanks to people creating accounts for their primary
        # sunetid@stanford.edu address and then for their mail aliases.  But
        # we don't want to change the XML parsing all over, so only remove the
        # key mapping for XML::Simple when requesting the list of all managed
        # users.

        my %res = %{ decode_json($response->content) };

        if (!defined($res{'total_count'})) {
            carp("Box: invalid response: no total_count property\n");
            last;
        }

        if (!$res{'entries'}) {
            carp("Box: invalid response: no entries property\n");
            last;
        }

        if (!defined($total_count)) {
            # this is the first response
            $total_count = $res{'total_count'};
        }

        foreach my $entry (@{ $res{'entries'} }) {
            if ($entry->{$key}) {
                $count++;
                $entries->{ $entry->{$key} } = $entry;
            } else {
                carp("Box: invalid entry in response: ${entry}\n");
            }
        }

    }

    return ($self->{'client'}->status == 200) ? $entries : undef;
}

sub as_user {
    my ($self, $user_id) = @_;
    return $self->{'client'}->as_user($user_id);
}

# Get data from the Box.com V2 API, with support for pagination
# Returns the last HTTP request status and an array of entries
# Warns if things fail.
#
# Callers can specify the page size in the request (page_size),
# and a subset of fields to return (fields=field1,field2,...)
#
# See http://developers.box.com/docs/#fields for documentation
# on the fields parameter, and # and http://developers.box.com/docs/
# for documentation on the offset and limit parameters
#
# NOTE: return parameters are ordered differently from post_request:
#       status, data rather than data, status
sub get {
    my ($self, $id, %opts) = @_;

    return $self->_get_subresource($id, q{}, %opts);
}

sub _get_subresource {
    my ($self, $id, $path, %opts) = @_;

    my $json;

    my $uri
      = $self->{'client'}->new_uri($self->{'collection'}, "${id}/${path}");

    if (defined($opts{fields})) {
        $uri->query_param('fields' => $opts{fields});
    }

    my $response = $self->{'client'}->get($uri);

    if ($response->is_success) {
        $json = decode_json($response->content);
        if (!$json) {
            carp('Box: error retrieving data: ' . $uri->as_string . "\n");
            # syslog ('err', 'error retrieving data from box.com');
        }
    }

    return $json;
}

sub add {
    my ($self, %obj) = @_;
    my $uri = $self->{'client'}->new_uri($self->{'collection'});

    if ($self->{'required_fields'}) {
        foreach my $req_field (@{ $self->{'required_fields'} }) {
            if (!defined($obj{$req_field})) {
                croak("$req_field is a required field");
            }
        }
    }

    my $new_obj;
    my $json = encode_json(\%obj);

    my $response = $self->{'client'}->post($uri, $json);

    if ($response->is_success) {
        $new_obj = decode_json($response->content);
        if (!defined($new_obj->{'id'})) {
            carp('Box: error creating resource: ' . $uri->as_string . "\n");
            # syslog ('err', 'error retrieving data from box.com');
            $new_obj = undef;
        }
    }

    return $new_obj;
}

sub remove {
    my ($self, $id, %params) = @_;

    my $uri = $self->{'client'}->new_uri($self->{'collection'}, $id);
    $uri->query_form(%params);
    my $response = $self->{'client'}->delete($uri);

    return $response->is_success;
}

sub update {
    my ($self, $id, %obj) = @_;

    my $uri = $self->{'client'}->new_uri($self->{'collection'}, $id);

    my $new_obj;
    my $json = encode_json(\%obj);
    my $response = $self->{'client'}->put($uri, $json);

    if ($response->is_success) {
        $new_obj = decode_json($response->content);
        if (!defined($new_obj->{'id'})) {
            carp('Box: error updating resource: ' . $uri->as_string . "\n");
            # syslog ('err', 'error retrieving data from box.com');
            $new_obj = undef;
        }
    }

    return $new_obj;

}
1;

