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

use version; our $VERSION = qv('0.1.0');

useall Box::Collections;

our $APIURL       = 'https://api.box.com/2.0/';
our $DEBUG        = 1;
our $MAXLIMIT     = 1000;

sub new {
    my ($class, %opts) = @_;
    my $self = bless {}, $class;
    $self->init(%opts);
    return $self;
}

sub init {
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
        'service_provider' => 'Box::OAuth2',
    );

    if (defined($opts{'token_file'})) {
        $self->{'token_file'}       = $opts{'token_file'};
        $oauth_opts{'token_string'} = $self->load_token();
        $oauth_opts{'save_tokens'}  = sub {
            my $token_string = shift;
            $self->save_token($token_string);
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

sub save_token {
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

sub load_token {
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

sub set_headers {
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

sub handle_response {
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

    $self->set_headers();
    my $res = $self->{'client'}->get($uri, %{ $self->{'headers'} });

    return $self->handle_response($uri, $res);
}

sub post {
    my ($self, $uri, $json, %headers) = @_;

    $headers{'Content'} = $json;

    $self->set_headers(%headers);

    my $res = $self->{'client'}->post($uri, %{ $self->{'headers'} });

    return $self->handle_response($uri, $res);

}

sub delete {    ## no critic (Subroutines::ProhibitBuiltinHomonyms)
    my ($self, $uri, %headers) = @_;

    $self->set_headers();

    my $res = $self->{'client'}->delete($uri, %{ $self->{'headers'} });
    return $self->handle_response($uri, $res);
}

sub put {
    my ($self, $uri, %headers) = @_;

    $self->set_headers(%headers);

    my $res = $self->{'client'}->put($uri, %{ $self->{'headers'} });
    return $self->handle_response($uri, $res);
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
    return Box::Collections::Users->new($self);
}

sub groups {
    my $self = shift;
    return Box::Collections::Groups->new($self);
}

sub folders {
    my $self = shift;
    return Box::Collections::Folders->new($self);
}

sub group_memberships {
    my $self = shift;
    return Box::Collections::GroupMemberships->new($self);
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

=over

=item new( %params )

Returns a new instance of this class.

=back

=head1 NAMESPACE METHODS

=over

=item users

Users namespace of the API (See L<WWW::Box::API::Users>).

=item groups

Groups namespace of the API (See L<WWW::Box::API::Groups>).

=item folders

Folders namespace of the API (See L<WWW::Box::API::Folders>).

=item grouo_memberships

GroupMemberships namespace of the API (See L<WWW::Box::API::GroupMemberships>).

=head1 PUBLIC METHODS

=over

=item as_user

blah blah

=head1 INCOMPATIBILITIES

None.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-www-box-api@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 SOURCE REPOSITORY

http://github.com/scottylogan/perl-www-box-api/

=head1 TESTING

No tests yet

=head1 AUTHOR

Scotty Logan C<< <swl@stanford.edu> >>

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

