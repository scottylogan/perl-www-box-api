use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'WWW::Box::API',
    AUTHOR              => 'Scotty Logan <swl@stanford.edu>',
    VERSION_FROM        => 'lib/WWW/Box/API.pm',
    ABSTRACT_FROM       => 'lib/WWW/Box/API.pm',
    LICENSE             => 'perl',
    PL_FILES            => {},
    PREREQ_PM => {
        'URI::QueryParam'      => 0,
        'Module::Find'         => 0,
        'JSON'                 => 0,
        'LWP'                  => 0,
        'LWP::Authen::OAuth2'  => 0,
        'Module::Find'         => 0,
    },
    INSTALLDIRS           => 'site',
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'WWW-Box-API-*' },
);
