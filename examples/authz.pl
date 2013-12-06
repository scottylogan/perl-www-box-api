#! /usr/bin/perl -I./usr/share/perl5

use WWW::Box::API;

use Carp;
use English;

my $box = new WWW::Box::API (
	'client_id' => $ENV{'CLIENT_ID'},
	'client_secret' => $ENV{'CLIENT_SECRET'},
	'redirect_uri' => $ENV{'REDIRECT_URI'},
	'token_file'    => $ENV{'TOKEN_FILE'},
);

my ($code) = @ARGV;

if ($code) {
	$box->request_tokens($code);
} else {

	if ($box->access_token()) {
		if ($box->should_refresh()) {
			printf "Token refresh required\n";
			if ($box->can_refresh_tokens()) {
				printf "Token refresh should work\n";
				my $user = $box->users->get('me');
				if ($box->succeeded) {
					printf "Refreshed token\n";
				} else {
					printf "Failed to refresh token\n";
				}
			}
		} else {
			printf "Tokens are OK\n";
		}
	} else {
		printf "Please authorize this app at\n\n%s\n", $box->authorization_url();
	}
}
