package Local::CSV_Exec::Framework;
# ==============================================================
# CSV_Exec::Framework
# ==============================================================
#   Contains functions for the CSV_Exec script(s) and plug-ins
# ==============================================================
use Modern::Perl qw(2018);
use English qw(-no_match_vars);
use Const::Fast;
use Getopt::Long qw( GetOptionsFromArray :config pass_through no_auto_abbrev no_ignore_case_always bundling );
use Log::Log4perl qw( :easy );
use File::Spec;
use File::BOM qw( :all );
use Cwd qw( abs_path );
use Text::CSV;
use List::Util qw( first );
use Taint::Util;

BEGIN {
    require Exporter;

    # set the version for version checking
    our $VERSION = '0.00';

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

    my @FILEHANDLE_FUNCS = qw(
        open_input_file   close_input_file
        open_output_file  close_output_file
        acquire_stdin     release_stdin
        acquire_stdout    release_stdout
    ); # END @FILEHANDLE_FUNCS #

    my @CSV_FUNCS = qw(
        acquire_in_csv    release_in_csv
        acquire_out_csv   release_out_csv
        read_csv_header   read_csv_data_row
        write_csv_header  write_csv_data_row
    );

    my @ALL_FUNCS = ( @INIT_FUNCS, @FILEPATH_FUNCS, @FILEHANDLE_FUNCS, @CSV_FUNCS );

    # Functions and variables which are exported by default
    # our @EXPORT = qw();

    # Functions and variables which can be exported upon request
    our @EXPORT_OK = @ALL_FUNCS;

    # Functions and variables which can be exported as a group
    our %EXPORT_TAGS = (
        'all'  => [ @ALL_FUNCS ],
        'init' => [ @INIT_FUNCS ],
        'csv'  => [ @CSV_FUNCS ],
        'fh'   => [ @FILEHANDLE_FUNCS ],
        'opt'  => [ @FILEPATH_FUNCS ],
    );
} # END BEGIN #

# ==============================================================
# Global Constants
# ==============================================================
const my $EMPTY_STR => q{};

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
# Input File Handle Functions
# ==============================================================

# --------------------------------------------------------------
# open_input_file()
#   Initialize the input source
# --------------------------------------------------------------
sub open_input_file {
    my ($opt_ref) = @_;
    return if ! defined $opt_ref;
    return if ! defined $opt_ref->{'in_filepath'};
    my $logger = get_logger($opt_ref->{'logname'});

    # Initialize input file handle
    $logger->debug(sprintf 'Opening input file: %s', $opt_ref->{'in_filepath'});
    unless ( open $opt_ref->{'in_fh'}, '<', $opt_ref->{'in_filepath'} ) {
        $logger->error(sprintf 'Unable to open input file (%s): %s', $opt_ref->{'in_filepath'},$OS_ERROR);
        return;
    } # END unless #

    return 1;
} # END open_input_file #

# --------------------------------------------------------------
# close_input_file()
#   Closes the input CSV file
# --------------------------------------------------------------
sub close_input_file {
    my ($opt_ref) = @_;
    return if ! defined $opt_ref;
    return if ! defined $opt_ref->{'in_fh'};
    my $logger = get_logger($opt_ref->{'logname'});

    # Close input file handle
    $logger->debug('Closing input file');
    unless ( close $opt_ref->{'in_fh'} ) {
        $logger->error(sprintf 'Unable to close input file: %s',$OS_ERROR);
    } # END unless #
    $opt_ref->{'in_fh'} = undef;

    return 1;
} # END close_input_file #

# --------------------------------------------------------------
# acquire_stdin()
#    Initialize STDIN file handle for input
# --------------------------------------------------------------
sub acquire_stdin {
    my ($opt_ref) = @_;
    return if ! defined $opt_ref;
    my $logger = get_logger($opt_ref->{'logname'});

    $logger->debug('Opening STDIN');
    $opt_ref->{'stdin'} = 1;
    $opt_ref->{'in_fh'} = *STDIN;

    return 1;
} # END acquire_stdin #

# --------------------------------------------------------------
# release_stdin()
# --------------------------------------------------------------
sub release_stdin {
    my ($opt_ref) = @_;
    return if ! defined $opt_ref;
    return if ! defined $opt_ref->{'in_fh'};
    my $logger = get_logger($opt_ref->{'logname'});

    $logger->debug('Closing STDIN');
    $opt_ref->{'in_fh'} = undef;
    $opt_ref->{'stdin'} = undef;

    return 1;
} # END release_stdin #

# ==============================================================
# Output File Handle Functions
# ==============================================================

# --------------------------------------------------------------
# open_output_file()
#   Initialize the output CSV file handle
# --------------------------------------------------------------
sub open_output_file {
    my ($opt_ref) = @_;
    return if ! defined $opt_ref;
    return if ! defined $opt_ref->{'out_filepath'};
    my $logger = get_logger($opt_ref->{'logname'});

    $logger->debug(sprintf 'Opening ouput file: %s', $opt_ref->{'out_filepath'});
    unless ( open $opt_ref->{'out_fh'}, '>', $opt_ref->{'out_filepath'} ) {
        $logger->error(sprintf 'Unable to open output file %s: %s',$opt_ref->{'out_filepath'},$OS_ERROR);
        return;
    } # END unless #

    return 1;
} # END open_output_file #

# --------------------------------------------------------------
# close_output_file()
#   Closes the output CSV file
# --------------------------------------------------------------
sub close_output_file {
    my ($opt_ref) = @_;
    return if ! defined $opt_ref;
    return if ! defined $opt_ref->{'out_fh'};
    my $logger = get_logger($opt_ref->{'logname'});

    $logger->debug('Closing ouput file');
    unless ( close $opt_ref->{'out_fh'} ) {
        $logger->error(sprintf '%s: %s',$opt_ref->{'out_filepath'},$OS_ERROR);
    } # END unless #
    $opt_ref->{'out_fh'} = undef;

    return 1;
} # END close_output_file #

# --------------------------------------------------------------
# acquire_stdout()
#   Initialize STDOUT file handle for output
# --------------------------------------------------------------
sub acquire_stdout {
    my ($opt_ref) = @_;
    return if ! defined $opt_ref;
    my $logger = get_logger($opt_ref->{'logname'});

    $logger->debug('Opening STDOUT');
    binmode STDOUT, ':utf8';
    $opt_ref->{'stdout'} = 1;
    $opt_ref->{'out_fh'} = *STDOUT;

    return 1;
} # END acquire_stdout #

# --------------------------------------------------------------
# release_stdout()
# --------------------------------------------------------------
sub release_stdout {
    my ($opt_ref) = @_;
    return if ! defined $opt_ref;
    return if ! defined $opt_ref->{'out_fh'};
    my $logger = get_logger($opt_ref->{'logname'});

    $logger->debug('Closing STDOUT');
    $opt_ref->{'out_fh'} = undef;
    $opt_ref->{'stdout'} = undef;

    return 1;
} # END release_stdout #

# ==============================================================
# Read CSV Input
# ==============================================================

# --------------------------------------------------------------
# acquire_in_csv()
#    Initialize input CSV object
# --------------------------------------------------------------
sub acquire_in_csv {
    my ($opt_ref) = @_;
    return if ! defined $opt_ref;

    my $logger = get_logger($opt_ref->{'logname'});
    $opt_ref->{'in_csv'} = Text::CSV->new( { binary => 1, auto_diag => 1 } );
    if ( ! defined $opt_ref->{'in_csv'} ) {
        $logger->error(sprintf 'Cannot use Text::CSV for input (%s)', (join q{,},Text::CSV->error_diag()));
        return;
    } # END if #

    return 1;
} # END acquire_in_csv #

# --------------------------------------------------------------
# release_in_csv()
# --------------------------------------------------------------
sub release_in_csv {
    my ($opt_ref) = @_;
    return if ! defined $opt_ref;
    return if ! defined $opt_ref->{'in_csv'};

    $opt_ref->{'in_csv'} = undef;

    return 1;
} # END release_in_csv #

# --------------------------------------------------------------
# read_csv_header()
#   Reads an input header row from file or STDIN
#   Detects Unicode BOM (byte-order mark) and sets CSV encoding
# TODO:
#   Try different separators, like Text::CSV::header() does
# --------------------------------------------------------------
sub read_csv_header {
    my ($opt_ref) = @_;
    return if ! defined $opt_ref;
    return if ! defined $opt_ref->{'in_fh'};
    return if ! defined $opt_ref->{'in_csv'};
    my $logger = get_logger($opt_ref->{'logname'});

    # Read Byte-Order Mark (BOM), if any
    ( $opt_ref->{'in_encoding'}, $opt_ref->{'in_spillage'} ) = defuse($opt_ref->{'in_fh'});

    # Read line of data into string
    my $line = readline $opt_ref->{'in_fh'};
    if ( ! defined $line ) {
        $logger->error('Unable to read CSV header');
        return;
    } # END if #

    # Add BOM spillage to line, if needed
    $opt_ref->{'in_spillage'} ||= $EMPTY_STR;
    $line = sprintf '%s%s',$opt_ref->{'in_spillage'},$line;

    # Parse line into fields
    if ( ! $opt_ref->{'in_csv'}->parse($line) ) {
        $logger->error('Unable to parse CSV header');
        return;
    } # END if #

    # Set input header array
    @{$opt_ref->{'in_header'}} = $opt_ref->{'in_csv'}->fields();
    if ( ! scalar @{$opt_ref->{'in_header'}} ) {
        return;
    } # END if #
    $opt_ref->{'in_row'} = 1;

    # Set CSV object column names for Text::CSV::getline_hr()
    $opt_ref->{'in_csv'}->column_names($opt_ref->{'in_header'});

    return 1;
} # END read_csv_header #

# --------------------------------------------------------------
# read_csv_data_row()
#     Reads a single data row from the input CSV source
# --------------------------------------------------------------
sub read_csv_data_row {
    my ($opt_ref) = @_;
    return if ! defined $opt_ref;
    return if ! defined $opt_ref->{'in_fh'};
    return if ! defined $opt_ref->{'in_csv'};

    # Read line of data into hash
    my $in_data_ref = $opt_ref->{'in_csv'}->getline_hr($opt_ref->{'in_fh'});
    return unless $in_data_ref;

    # Set input data hash
    $opt_ref->{'in_data'} = $in_data_ref;
    $opt_ref->{'in_row'} += 1;

    return 1;
} # END read_csv_data_row #

# ==============================================================
# Write CSV Output
# ==============================================================

# --------------------------------------------------------------
# acquire_out_csv()
#    Initialize output CSV object
# --------------------------------------------------------------
sub acquire_out_csv {
    my ($opt_ref) = @_;
    return if ! defined $opt_ref;

    my $logger = get_logger($opt_ref->{'logname'});
    $opt_ref->{'out_csv'} = Text::CSV->new( {eol => "\n", binary => 1, always_quote => 1} );
    if ( ! defined $opt_ref->{'out_csv'} ) {
	    $logger->error(sprintf 'Cannot use Text::CSV for output (%s)', (join q{,},Text::CSV->error_diag()));
        return;
    } # END if #

    return 1;
} # END acquire_out_csv #

# --------------------------------------------------------------
# release_out_csv()
# --------------------------------------------------------------
sub release_out_csv {
    my ($opt_ref) = @_;
    return if ! defined $opt_ref;
    return if ! defined $opt_ref->{'out_csv'};

    $opt_ref->{'out_csv'} = undef;

    return 1;
} # END release_out_csv #

# --------------------------------------------------------------
# write_csv_header()
#   Produces and prints an output header row
#   Sets output to use UTF-8 encoding with a Byte Order Mark (BOM)
# --------------------------------------------------------------
sub write_csv_header {
    my ($opt_ref) = @_;
    return if ! defined $opt_ref;
    return if ! defined $opt_ref->{'out_fh'};
    return if ! defined $opt_ref->{'out_csv'};
    return if ! defined $opt_ref->{'out_header'};

    # Set output encoding
    $opt_ref->{'out_encoding'} = 'UTF-8'; # if ! defined $opt_ref->{'out_encoding'};
    my $encoding = sprintf ':encoding(%s)',$opt_ref->{'out_encoding'};
    binmode $opt_ref->{'out_fh'}, $encoding;

    # Write Byte-Order Mark (BOM) for encoding, if needed
    if ( _needs_bom($opt_ref->{'out_encoding'}) ) {
        return unless print { $opt_ref->{'out_fh'} } "\N{BOM}";
    } # END if #

    # Write output header row
    $opt_ref->{'out_csv'}->print($opt_ref->{'out_fh'}, $opt_ref->{'out_header'});
    $opt_ref->{'out_row'} = 1;

    # If verbose, also send output to STDOUT
    if ( $opt_ref->{'verbose'} && $opt_ref->{'out_dst'} ne 'stdout' ) {
        $opt_ref->{'out_csv'}->print(*STDOUT, $opt_ref->{'out_header'});
    } # END if #

    return 1;
} # END write_csv_header #

# --------------------------------------------------------------
# write_csv_data_row()
#   Writes a single data row to the output
# --------------------------------------------------------------
sub write_csv_data_row {
    my ($opt_ref) = @_;
    return if ! defined $opt_ref;
    return if ! defined $opt_ref->{'out_fh'};
    return if ! defined $opt_ref->{'out_csv'};

    # Return success if there is nothing to write
    if ( ! defined $opt_ref->{'out_data'} ) {
        return 1;
    } # END if #

    # Write Output Data Row
    my @out_data = map { $opt_ref->{'out_data'}->{$_} } @{$opt_ref->{'out_header'}};
    $opt_ref->{'out_csv'}->print($opt_ref->{'out_fh'}, \@out_data);
    $opt_ref->{'out_row'} += 1;

    # If verbose, also send output to STDOUT
    if ( $opt_ref->{'verbose'} && $opt_ref->{'out_dst'} ne 'stdout' ) {
        $opt_ref->{'out_csv'}->print(*STDOUT, \@out_data);
    } # END if #

    return 1;
} # END write_csv_data_row #

# ==============================================================
# Internal Utility Functions
# ==============================================================

# --------------------------------------------------------------
# _needs_bom
#   Returns true (1) if the given encoding should include a
#   Byte Order Mark (BOM) when used as an output encoding
#   Returns false (undef) otherwise
# --------------------------------------------------------------
sub _needs_bom {
    my ($encoding) = @_;
    my @bom_encodings = qw(
        UTF-8
        UTF-16 UTF-16LE UTF-16BE
        UTF-32 UTF-32LE UTF-32BE
    ); # END @bom_encodings #
    return 1 if first { $_ eq $encoding } @bom_encodings;
    return;
} # END _needs_bom #

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