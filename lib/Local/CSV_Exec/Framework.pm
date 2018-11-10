package Local::CSV_Exec::Framework;
# ==============================================================
# Local::CSV_Exec::Framework
# ==============================================================
#   Contains functions for the CSV_Exec script(s) and plug-ins
# ==============================================================
use Modern::Perl qw(2018);
use English qw(-no_match_vars);
use Const::Fast;
use Getopt::Long qw( GetOptionsFromArray :config pass_through no_auto_abbrev no_ignore_case_always bundling );
use Log::Log4perl qw( :easy );
use File::Spec;
use Cwd qw( abs_path );
use Taint::Util;

BEGIN {
    require Exporter;

    # set the version for version checking
    use version; our $VERSION = qv('0.0.0');

    # Inherit from Exporter to export functions and variables
    use base qw(Exporter);

    my @INIT_FUNCS = qw(
        init_logger
        get_base_options
    ); # END @INIT_FUNCS #

    my @FILEPATH_FUNCS = qw(
        split_filepath
        validate_output_filepath
    ); # END @FILEPATH_FUNCS #

    # Functions and variables which are exported by default
    # our @EXPORT = qw();

    # Functions and variables which can be exported upon request
    our @EXPORT_OK = ( @INIT_FUNCS, @FILEPATH_FUNCS );

    # Functions and variables which can be exported as a group
    our %EXPORT_TAGS = (
        'all'  => [ @EXPORT_OK ],
    );

} # END BEGIN #

# ==============================================================
# Initialization Functions
# ==============================================================

# --------------------------------------------------------------
# init_logger()
#   Initialize error logging
# --------------------------------------------------------------
sub init_logger {
    my ($opt_ref, $logname) = @_;
    return if ! defined $opt_ref;
    return unless $logname;

    $opt_ref->{'logname'} = $logname;
    Log::Log4perl->easy_init({
        level => $ERROR,
        file  => 'STDERR',
        utf8  => 1,
        category => $opt_ref->{'logname'},
        layout => '%d{yyyy-MM-dd HH:mm:ss} (%F{1}) %p: %m%n',
    });

    return 1;
} # END init_logger #

# --------------------------------------------------------------
# get_base_options()
#   Reads command-line options and loads parser
#   Prints usage statement and exits, if needed (--help)
#   Prints selected options and exits, if needed (--check)
# --------------------------------------------------------------
sub get_base_options {
    my ($opt_ref) = @_;
    return if ! defined $opt_ref;
    return if ! defined $opt_ref->{'args'};

    # Command-line parameters
    GetOptionsFromArray($opt_ref->{'args'}, $opt_ref,
        'help',
        'check',
        'verbose',
        'dry-run',
        'input|i=s',
        'output|o=s',
    ) or return;

    return 1;
} # END get_base_options() #

# ==============================================================
# Filepath Functions
# ==============================================================

# --------------------------------------------------------------
# split_filepath()
#   Converts the given filepath to an absolut path and splits
#   it apart to return:
#     ( volume, path, filename, fullpath )
# --------------------------------------------------------------
sub split_filepath {
    my ($filepath) = @_;
    return unless $filepath;

    # Split filepath
    my ( $volume, $path, $filename ) = File::Spec->splitpath($filepath);

    # Convert to absolute filepath
    $path = File::Spec->curdir() if ! $path;
    $path = abs_path($path);

    # Recombine filepath
    $filepath = File::Spec->catpath($volume, $path, $filename);

    return ($volume, $path, $filename, $filepath);

} # END split_filepath #

# --------------------------------------------------------------
# validate_output_filepath()
#   Parses $opt_ref->{input} to return
#     $opt_ref->{in_volume  }
#     $opt_ref->{in_path    }
#     $opt_ref->{in_filename}
#     $opt_ref->{in_filepath}
#   Assuming {input} is set and refers to an existing file or directory
#   Returns true (1) on success, false (undef) on failure
# --------------------------------------------------------------
sub validate_output_filepath {
    my ($opt_ref) = @_;
    return if ! defined $opt_ref;
    return if ! defined $opt_ref->{'out_filepath'};
    my $logger = get_logger($opt_ref->{'logname'});

    # Validate filepath
    if ( _validate_filepath($opt_ref->{'out_filepath'}) ) {
        untaint $opt_ref->{'out_volume'} ;
        untaint $opt_ref->{'out_path'};
        untaint $opt_ref->{'out_filename'};
        untaint $opt_ref->{'out_filepath'};
    } else {
        $logger->error('Output filepath contains invalid characters');
        $opt_ref->{'out_volume'}   = undef;
        $opt_ref->{'out_path'}     = undef;
        $opt_ref->{'out_filename'} = undef;
        $opt_ref->{'out_filepath'} = undef;
        return;
    } # END if #

    return 1;
} # END validate_output_filepath #

# ==============================================================
# Internal Utility Functions
# ==============================================================

# --------------------------------------------------------------
# _validate_filepath()
#   Returns true (1) if given filepath contains only valid characters
# --------------------------------------------------------------
sub _validate_filepath {
    my ($filepath) = @_;
    if ( ! $filepath =~ m{\A [^\p{Other}]+ \z}xms ) {
        return;
    } # END if #
    return 1;
} # END _validate_filepath #

1;