package WWW::Box::API::OAuth2::WebServer;

use strict;
use warnings;

use base qw(WWW::Box::API::OAuth2);

sub required_init {
    return qw(client_id client_secret);
}

sub optional_init {
    return qw(redirect_uri);
}

sub authorization_optional_params {
    return ();
}

sub request_required_params {
    return ();
}

1;
