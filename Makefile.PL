## no critic (RequireExplicitPackage)
use Modern::Perl qw(2018);
use ExtUtils::MakeMaker;
use File::Find;

# Search for executable files in the "script" directory
my @scriptdirs = qw(script);
my @scripts;
find( { wanted => sub { -f && -x && push @scripts,$File::Find::name; } }, @scriptdirs );

WriteMakefile (
    NAME       => 'CSV_Exec',
    VERSION    => '0.02.0',
    MIN_PERL_VERSION => 5.10.0,
    AUTHOR   => 'Justin J. Clark (zoltair@gmail.com)',
    ABSTRACT => 'Script to perform actions for each line of CSV input (or each file found in a search) and generate one line of CSV output for each result',
    #LICENSE      => 'artistic_2',
    CONFIGURE_REQUIRES => {
        'Modern::Perl' => 0,
        'ExtUtils::MakeMaker' => 0,
        'File::Find' => 0,
        # ...
    },
    BUILD_REQUIRES => {
        'Modern::Perl' => 0,
        'English' => 0,
        'Const::Fast' => 0,
        'File::Spec' => 0,
        'Cwd' => 0,
        'Test::More' => 0,
        'List::MoreUtils' => 0,
        'Array::Compare' => 0,
        # ...
    },
    PREREQ_PM => {
        'Modern::Perl' => 0,
        'English' => 0,
        'Const::Fast' => 0,
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
        'List::Util'  => 0,
        'Taint::Util' => 0,
    },
    # INSTALLDIRS => 'site', # (default)
    INSTALLSITELIB => '/usr/local/lib/site_perl',
    # INSTALLSITEBIN => '/usr/local/bin', # (default)
    # INSTALLSITESCRIPT => '/usr/local/bin', # (default)
    EXE_FILES  => \@scripts,
);

1;
## use critic