package WWW::Box::API::OAuth2;

use strict;
use warnings;

use LWP::Authen::OAuth2::ServiceProvider;

use base qw(LWP::Authen::OAuth2::ServiceProvider);

sub authorization_endpoint {
    return 'https://www.box.com/api/oauth2/authorize';
}

sub token_endpoint {
    return 'https://www.box.com/api/oauth2/token';
}

sub authorization_optional_params {
    my $self = shift;
    return ('state', $self->SUPER::authorization_optional_params());
}

my %flow_class = (
    default      => 'WebServer',
    'web server' => 'WebServer',
);

sub flow_class {
    my ($class, $flow) = @_;
    if (exists $flow_class{$flow}) {
        return "WWW::Box::API::OAuth2::$flow_class{$flow}";
    } else {
        my $allowed = join ', ', sort keys %flow_class;
        Carp::croak("Flow '$flow' not in: $allowed");
    }
}

1;

