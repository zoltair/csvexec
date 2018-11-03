use strict;
use warnings;
use ExtUtils::MakeMaker;
use File::Find;
my @scriptdirs = qw(script);
my @scripts;
find( { wanted => sub { -f && -x && push @scripts,$File::Find::name; } }, @scriptdirs );
WriteMakefile (
    NAME       => 'CSVExec',
    VERSION    => '0.01',
    MIN_PERL_VERSION => 5.10.0,
    AUTHOR   => 'Justin J. Clark (zoltair@gmail.com)',
    ABSTRACT => 'Utility script which performs actions for each line of an input CSV file (or each file found in a folder) to generate an output CSV file',
    #LICENSE      => 'artistic_2',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
        'File::Find' => 0,
        # ...
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
        # ...
    },
    PREREQ_PM => {
        'Modern::Perl' => 0,
        'Getopt::Long' => 0,
        'Log::Log4perl' => 0,
        'File::Spec' => 0,
        'File::Basename' => 0,
        'File::Find' => 0,
        'File::Path' => 0,
        'File::BOM' => 0,
        'Cwd' => 0,
        'Text::CSV' => 0,
        'Module::Load' => 0,
        'Module::Load::Conditional' => 0,
        'Encode' => 0,
    },
    # INSTALLDIRS => 'site', # (default)
    INSTALLSITELIB => '/usr/local/lib/site_perl',
    # INSTALLSITEBIN => '/usr/local/bin', # (default)
    # INSTALLSITESCRIPT => '/usr/local/bin', # (default)
    EXE_FILES  => \@scripts,
    #EXE_FILES  => [ map { "script/$_" } @scripts ],
);

1;