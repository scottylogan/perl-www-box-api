#! /usr/bin/perl -I./usr/share/perl5

use WWW::Box::API;
use Data::Dumper;

my $box = new WWW::Box::API (
	'client_id' => $ENV{'CLIENT_ID'},
	'client_secret' => $ENV{'CLIENT_SECRET'},
	'redirect_uri' => $ENV{'REDIRECT_URI'},
	'token_file'    => $ENV{'TOKEN_FILE'},
);

my %new_group = (
	'name' => 'first_v2_group'
);

my %new_user = (
	'name' => 'Test User',
	'login' => 'testuser@itlab.stanford.edu'
);

my $group;
my $user;
my $membership;
my $aliases;
my $alias;
my $folder;

sub cleanup {
	$box->as_user(0);
#	if (defined($folder)) {
#		$box->folders->remove($folder->{'id'});
#		if ($box->succeeded) {
#			printf "Removed folder\n";
#		} else {
#			printf "Failed to remove folder: %d\n", $box->status;
#		}
#	}

	if (defined($membership)) {
		$box->group_memberships->remove($membership->{'id'});
		if ($box->succeeded) {
			printf "Removed membership\n";
		} else {
			printf "Failed to remove membership: %d\n", $box->status;
		}
	}

	if (defined($user)) {
		$box->users->remove($user->{'id'}, 'force' => 'true', 'notify' => 'false');
		if ($box->succeeded) {
			printf "Removed user\n";
		} else {
			printf "Failed to remove user: %d\n", $box->status;
		}
	}

	if (defined($group)) {
		$box->groups->remove($group->{'id'});
		if ($box->succeeded) {
			printf "Removed group\n";
		} else {
			printf "Failed to remove group: %d\n", $box->status;
		}
	}
	exit();
}

printf "Creating group\n";
$group = $box->groups->add('name' => 'v2_test_group');
if ($group && $box->succeeded) {
	printf "Created group, id = %d\n", $group->{'id'};
} else {
	cleanup();
}

printf "Creating user\n";
$user = $box->users->add('name' => 'Test User', 'login' => 'v2_test_user@itlab.stanford.edu');
if ($user && $box->succeeded) {
	printf "Created user, id = %d\n", $user->{'id'};
} else {
	printf "FAILED to add user: %d\n", $box->status;
	printf "message: %s\n", $box->content;
	cleanup();
}

$aliases = $box->users->aliases($user->{'id'});

printf "Adding alias\n";
$alias = $aliases->add('email' => 'v2.test.user@itlab.stanford.edu');
if ($alias && $box->succeeded) {
	printf "Added alias, id = %d\n", $alias->{'id'};
} else {
	printf "FAILED to add alias: %d\n", $box->status;
	printf "message: %s\n", $box->content;
	cleanup();
}

printf "Getting aliases\n";

my $all_aliases = $aliases->all();
if ($all_aliases && $box->succeeded) {
	printf "Aliases: %s\n", Dumper($all_aliases);
} else {
	printf "FAILED to get aliases: %d\n", $box->status;
	printf "message: %s\n", $box->content;
}

$box->as_user($user->{'id'});
printf "Getting user as user\n";
my $new_user = $box->users->get('me');
if ($new_user && $box->succeeded) {
	printf "Got user, id = %d\n", $new_user->{'id'};
} else {
	printf "FAILED to get user: %d\n", $box->status;
	printf "message: %s\n", $box->content;
}

$box->as_user(0);

printf "Adding user to group\n";
$membership = $box->group_memberships->add(
	'group_id' => $group->{'id'},
	'user_id'  => $user->{'id'},
	'role'     => 'admin'
);

if ($membership && $box->succeeded) {
	printf "Created group membership, id = %d\n", $membership->{'id'};
	my $memberships = $box->groups->memberships($group->{'id'})->all();
	if (! $box->succeeded) {
		printf "FAILED to get memberships: %d\n", $box->status;
		printf "message: %s\n", $box->content;
	} else {
		printf "MEMBERSHIP\n";
		printf "%s\n", Dumper($memberships);
	}
} else {
	cleanup();
}

printf "Getting root folder info\n";

$folder = $box->folders->get(0);
if ($folder && $box->succeeded) {
	printf "Got folder\n";
#	printf "%s\n", Dumper($folder);
} else {
	printf "FAILED to get folder: %d\n", $box->status;
	printf "message: %s\n", $box->content;
}


printf "RUNNING AS USER %d\n", $user->{'id'};

$box->as_user($user->{'id'});

printf "Creating folder\n";
$folder = $box->folders->add('Test Folder');
if ($folder && $box->succeeded) {
	printf "Created folder, id = %d\n", $folder->{'id'};
} else {
	cleanup();
}


## Box documentation on group collaborations lacks any useful
## info.
##
## The owner of the folder must also be an admin of the group
## that's being added
## the request also needs to include a 'type' field, set to 'group'
## in the 'accessible_by' property

printf "Adding group as co-owner\n";

my $collaboration = $box->collaborations->add(
	'folder_id' => $folder->{'id'},
	'group_id' => $group->{'id'},
	'role' => 'co-owner'
);


if ($collaboration && $box->succeeded) {
	printf "Created collaboration, id = %d\n", $collaboration->{'id'};
	printf "%s\n", Dumper($collaboration);
} else {
	printf "FAILED to create collaboration: %d\n", $box->status;
	printf "message: %s\n", $box->content;
	cleanup();
}

printf "Getting collaborations for group\n";

my $collaborations = $box->groups->collaborations($group->{'id'})->all();
if ($collaborations && $box->succeeded) {
	printf "%s\n", Dumper($collaborations);
} else {
	printf "FAILED to get collaborations: %d\n", $box->status;
	printf "message: %s\n", $box->content;
}

printf "RUNNING AS ADMIN\n";

$box->as_user(0);

printf "Press enter to cleanup\n";
<STDIN>;

cleanup();