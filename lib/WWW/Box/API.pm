package WWW::Box::API;

use 5.010;

use strict;
use warnings;
use Carp qw(carp croak);

use LWP;
use LWP::Authen::OAuth2;

use URI::QueryParam;
use JSON;

use WWW::Box::API::OAuth2;
use Module::Find;

use version; our $VERSION = qv('0.1.1');

useall WWW::Box::API::Collections;

our $APIURL   = 'https://api.box.com/2.0/';
our $DEBUG    = 1;
our $MAXLIMIT = 1000;

sub new {
    my ($class, %opts) = @_;
    my $self = bless {}, $class;
    $self->_init(%opts);
    return $self;
}

sub _init {
    my ($self, %opts) = @_;

    croak('Missing client_id')
      unless defined($opts{'client_id'});

    croak('Missing client_secret')
      unless defined($opts{'client_secret'});

    croak('Missing redirect_uri')
      unless defined($opts{'redirect_uri'});

    my %oauth_opts = (
        'client_id'        => $opts{'client_id'},
        'client_secret'    => $opts{'client_secret'},
        'redirect_uri'     => $opts{'redirect_uri'},
        'service_provider' => 'WWW::Box::API::OAuth2',
    );

    if (defined($opts{'token_file'})) {
        $self->{'token_file'} = $opts{'token_file'};
        if (-f $self->{'token_file'}) {
            $oauth_opts{'token_string'} = $self->_load_token();
        } else {
            open my $tf, '>', $self->{'token_file'}
              or croak('Failed to create token file: ' . $!);
            close $tf
              or croak('Failed to close token file: ' . $!);
        }
        $oauth_opts{'save_tokens'} = sub {
            my $token_string = shift;
            $self->_save_token($token_string);
        };
    }

    if (   defined($opts{'limit'})
        && $opts{'limit'} > 0
        && $opts{'limit'} < $MAXLIMIT)
    {
        $self->{'limit'} = $opts{'limit'};
    } else {
        $self->{'limit'} = $MAXLIMIT;
    }

    $self->{'client'} = LWP::Authen::OAuth2->new(%oauth_opts)
      or croak('Failed to create LWP::Authen::OAuth2 instance');

    $self->{'as-user'} = 0;

    return;
}

## OAuth 2.0

sub _save_token {
    my ($self, $token_string) = @_;
    my $status = 0;    # assume failure

    if (!defined($self->{'token_file'})) {
        carp('No token_file defined');
    } else {
        open my $TOKENS, '>', $self->{'token_file'}
          or croak("Can't open token file for writing: $!");

        printf {$TOKENS} "%s\n", $token_string;

        close $TOKENS
          or croak("Failed to close token file: $!");
        $status = 1;
    }
    printf "SAVING\n";
    return $status;
}

sub _load_token {
    my $self = shift;

    my $token_string = 0;

    if (!defined($self->{'token_file'})) {
        carp('No token_file defined');
    } else {
        open my $TOKENS, '<', $self->{'token_file'}
          or croak("Can't open token file for reading: $!");

        $token_string = qw{};
        while (<$TOKENS>) {
            chomp;
            $token_string .= $_;
        }
        close $TOKENS
          or croak("Failed to close token file: $!");
    }

    return $token_string;
}

sub access_token {
    my $self = shift;
    return $self->{'client'}->access_token();
}

sub authorization_url {
    my $self = shift;
    return $self->{'client'}->authorization_url();
}

sub request_tokens {
    my ($self, $code) = @_;
    return $self->{'client'}->request_tokens('code' => $code);
}

sub should_refresh {
    my $self = shift;
    return $self->{'client'}->should_refresh();
}

sub can_refresh_tokens {
    my $self = shift;
    return $self->{'client'}->can_refresh_tokens();
}

sub new_uri {
    my ($self, $collection, $id) = @_;
    my $path = $collection . (defined($id) ? "/${id}" : q{});
    return URI->new_abs($path, $APIURL);
}

sub as_user {
    my ($self, $user_id) = @_;
    if ($user_id) {
        $self->{'as-user'} = $user_id;
    } else {
        $self->{'as-user'} = 0;
    }

    return;
}

sub _set_headers {
    my ($self, %headers) = @_;
    if (%headers) {
        $self->{'headers'} = \%headers;
    } else {
        $self->{'headers'} = {};
    }

    $self->{'headers'}->{'Accept'} = 'application/json'
      unless $self->{'headers'}->{'Accept'};

    $self->{'headers'}->{'Content-Type'} = 'application/json'
      unless $self->{'headers'}->{'Content-Type'};

    $self->{'headers'}->{'As-User'} = $self->{'as-user'}
      unless ($self->{'as-user'} == 0);

    return;
}

sub _handle_response {
    my ($self, $uri, $response) = @_;

    $self->{'last_status'}  = $response->code;
    $self->{'last_content'} = $response->content;
    $self->{'is_success'}   = $response->is_success;

    if (!$response->is_success) {
        carp('Box API Error: ' . $response->code . "\n");
        carp('Box API Error: ' . $response->content . "\n");
        # syslog ('err', 'could not connect to Box');
    }

    return $response;
}

sub get {
    my ($self, $uri) = @_;

    $self->_set_headers();
    my $res = $self->{'client'}->get($uri, %{ $self->{'headers'} });

    return $self->_handle_response($uri, $res);
}

sub post {
    my ($self, $uri, $json, %headers) = @_;

    %headers = () unless %headers;

    $headers{'Content'} = $json;

    $self->_set_headers(%headers);

    my $res = $self->{'client'}->post($uri, %{ $self->{'headers'} });

    return $self->_handle_response($uri, $res);

}

sub delete {    ## no critic (Subroutines::ProhibitBuiltinHomonyms)
    my ($self, $uri, %headers) = @_;

    %headers = () unless %headers;

    $self->_set_headers(%headers);

    my $res = $self->{'client'}->delete($uri, %{ $self->{'headers'} });
    return $self->_handle_response($uri, $res);
}

sub put {
    my ($self, $uri, $json, %headers) = @_;

    %headers = () unless %headers;

    $headers{'Content'} = $json;

    $self->_set_headers(%headers);

    my $res = $self->{'client'}->put($uri, %{ $self->{'headers'} });

    return $self->_handle_response($uri, $res);
}

sub status {
    my $self = shift;

    return $self->{'last_status'};
}

sub content {
    my $self = shift;

    return $self->{'last_content'};
}

sub succeeded {
    my $self = shift;

    return $self->{'is_success'};
}

sub users {
    my $self = shift;
    return WWW::Box::API::Collections::Users->new($self);
}

sub groups {
    my $self = shift;
    return WWW::Box::API::Collections::Groups->new($self);
}

sub folders {
    my $self = shift;
    return WWW::Box::API::Collections::Folders->new($self);
}

sub group_memberships {
    my $self = shift;
    return WWW::Box::API::Collections::GroupMemberships->new($self);
}

sub user_aliases {
    my $self = shift;
    return WWW::Box::API::Collections::UserAliases->new($self);
}

sub collaborations {
    my $self = shift;
    return WWW::Box::API::Collections::Collaborations->new($self);
}

1;
__END__

=head1 NAME

WWW::Box::API - Box API v2 implementation

=head1 VERSION

This document and others distributed with this module describe
WWW::Box::API version 0.1.0

=head1 SYNOPSIS

    use WWW::Box::API;

=head1 DESCRIPTION

A Perl implementation of the Box API, written mainly for making
administrative calls to an enterprise instance.

=head1 SUBROUTINES/METHODS


=head2 my $box = new WWW::Box::API(%params)

Returns a new instance of this class.  %params must include client_id,
client_secret and the redirect_uri associated with the client_id.  %params
should also include token_file to specify where to store the OAuth 2.0 tokens.

=head2 $box-E<gt>users

Return an object to access the Users collection (See L<WWW::Box::API::Users>).

=head2 $box-E<gt>groups

Return an object to access the Groups collection (See
L<WWW::Box::API::Groups>).

=head2 $box-E<gt>folders

Return an object to access the Folders collection (See
L<WWW::Box::API::Folders>).

=head2 $box-E<gt>group_memberships

Return an object to access the GroupMemberships collection (See
L<WWW::Box::API::GroupMemberships>).

=head2 $box-E<gt>user_aliases

Return an object to access the UserAliases collection (See
L<WWW::Box::API::UserAliases>).

=head2 $box-E<gt>collaborations

Return an object to access the Collaborations collection (See
L<WWW::Box::API::Collaborations>).

=head2 $box-E<gt>access_token

Returns the current OAuth 2.0 access token.

=head2 $box-E<gt>authorization_url

Returns an authorization URL to approve tokens for this client.

=head2 $box-E<gt>request_tokens($code)

Requests new tokens using the code acquired from the authorization step.

=head2 $box-E<gt>should_refresh

Checks if the tokens should be refreshed - returns true if a refresh is required.

=head2 $box-E<gt>can_refresh_tokens

Returns true if the tokens can be refreshed, and false if a new authorization is required.

=head2 $box-E<gt>new_uri($collection, $id)

If id is not specified, returns the URI for the named collection.  If
id is specified, returns the URI for that specific resource in the
collection.

=head2 $box-E<gt>as_user($user_id)

If user_id is non-zero, all future requests will include the 'As-User:
$user_id' header to act on behalf of that user.  Setting user_id to 0 will
revert back to acting as the admin user.

=head2 $box-E<gt>get($uri)

Get the specificied $uri.  Returns the resource representation as a hash.

=head2 $box-E<gt>post($uri, $json, %headers)

Post the $json representation of a resource to $uri.  Returns the new resource
representation as a hash.

=head2 $box-E<gt>delete($uri, %headers)

Delete the resource identified by $uri.

=head2 $box-E<gt>put($uri, $json, %headers)

Updates the resource identified by $uri with the (possibly partial)
representation in $json.

=head2 $box-E<gt>status

Returns the last status received from the Box API.

=head2 $box-E<gt>content

Returns the last content received from the Box API.

=head2 $box-E<gt>succeeded

Returns true if the last Box API request was successful.

=head1 INCOMPATIBILITIES

None.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
bug-www-box-api@rt.cpan.org, or through the web interface at
L<http://rt.cpan.org>.

=head1 SOURCE REPOSITORY

http://github.com/scottylogan/perl-www-box-api/

=head1 TESTING

No tests yet

=head1 AUTHOR

Scotty Logan <swl@stanford.edu>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2013,
  The Board of Trustees of the Leland Stanford Junior University

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.

