#!/usr/bin/perl
use utf8;
use Modern::Perl qw(2018);
use English qw(-no_match_vars);
use Const::Fast;
use File::Spec;
use Test::More;
use List::MoreUtils qw( zip );

# Test script program name
my ( $volume, $program_path, $program_filename ) = File::Spec->splitpath($PROGRAM_NAME);
my $test_path = File::Spec->catdir($program_path,(sprintf '%s.d',$program_filename));

my @funcs = qw(
    write_csv_header
    write_csv_data_row
); # END @funcs #

# Colors CSV
const my @COLORS_HEADER => qw(
    ID
    NAME
); # END @COLORS_HEADER #
const my @COLORS_DATA_ROWS => (
    [ 1,  'White' ],
    [ 2,  'Grey' ],
    [ 21, 'Bright Red' ],
    [ 23, 'Bright Blue' ],
    [ 24, 'Bright Yellow' ],
    [ 26, 'Black' ],
    [ 28, 'Dark Green' ],
    [ 27, 'Dark Grey' ],
); # END @COLORS_DATA_ROWS #

# Comics CSV
const my @COMICS_HEADER => qw(
    SRC_BASE_PATH
    SRC_PATH
    SRC_FILENAME
    SRC_EXTENSION
    №
); # END @COMICS_HEADER #
const my @COMICS_DATA_ROWS => (
    [
        '/net/unsorted/Comics/Marvel',
        'Sergio Aragonés The Groo Chronicles (1989)',
        '001 - Sergio Aragonés The Groo Chronicles Book One (1989).cbz',
        'CBZ',
        '①'
    ],
    [
        '/net/unsorted/Comics/Marvel',
        'Sergio Aragonés The Groo Chronicles (1989)',
        '002 - Sergio Aragonés The Groo Chronicles Book Two (1989).cbz',
        'CBZ',
        '②'
    ],
    [
        '/net/unsorted/Comics/Marvel',
        'Sergio Aragonés The Groo Chronicles (1989)',
        '003 - Sergio Aragonés The Groo Chronicles Book Three (1989).cbz',
        'CBZ',
        '③'
    ],
    [
        '/net/unsorted/Comics/Marvel',
        'Sergio Aragonés The Groo Chronicles (1989)',
        '004 - Sergio Aragonés The Groo Chronicles Book Four (1989).cbz',
        'CBZ',
        '④'
    ],
    [
        '/net/unsorted/Comics/Marvel',
        'Sergio Aragonés The Groo Chronicles (1989)',
        '005 - Sergio Aragonés The Groo Chronicles Book Five (1989).cbz',
        'CBZ',
        '⑤'
    ],
    [
        '/net/unsorted/Comics/Marvel',
        'Sergio Aragonés The Groo Chronicles (1989)',
        '006 - Sergio Aragonés The Groo Chronicles Book Six (1989).cbz',
        'CBZ',
        '⑥'
    ],
); # END @COMICS_DATA_ROWS #

## no critic (ProhibitComplexMappings)
my %tests;
$tests{'colors'}{'header'} = \@COLORS_HEADER;
@{ $tests{'colors'}{'data_rows'} } =
    map { { zip @COLORS_HEADER, @{$_} } }
    @COLORS_DATA_ROWS;
$tests{'comics'}{'header'} = \@COMICS_HEADER;
@{ $tests{'comics'}{'data_rows'} } =
    map { { zip @COMICS_HEADER, @{$_} } }
    @COMICS_DATA_ROWS;
## use critic

# Test counts
const my $BASE_TEST_COUNT     => 1;
const my $FILE_TEST_COUNT     => 10;
const my $HEADER_TEST_COUNT   => 3;
const my $DATA_ROW_TEST_COUNT => 3;

# Test plan
my $count = $BASE_TEST_COUNT;
$count += (scalar @funcs);
$count += ($FILE_TEST_COUNT   * (scalar keys %tests));
$count += ($HEADER_TEST_COUNT * (scalar keys %tests));
foreach my $key ( keys %tests ) {
    $count += ($DATA_ROW_TEST_COUNT * (scalar @{ $tests{$key}->{'data_rows'} }));
} # END foreach #
plan tests => $count;

# Load script
require_ok('./script/csvexec');
my $opt_ref = main::get_opt_ref();

# Function definition tests
foreach my $func ( @funcs ) {
    ok(defined &{$func},(sprintf '%s() is defined',$func));
} # END foreach #

foreach my $key ( sort keys %tests ) {
    # Generate filename
    my $test_filename = sprintf '%s.csv',$key;
    my $test_filepath = File::Spec->catpath($volume,$test_path,$test_filename);

    # Initialize output
    $opt_ref->{'output'} = $test_filepath;
    ok(main::set_output_options($opt_ref),(sprintf 'Setting output options (%s)',$test_filename));
    ok(main::open_output_file($opt_ref),(sprintf 'Opening output file (%s)',$test_filename));
    ok(main::acquire_out_csv($opt_ref),(sprintf 'Initializing output CSV (%s)',$test_filename));

    # Write header
    $opt_ref->{'out_header'} = $tests{$key}{'header'};
    ok(main::write_csv_header($opt_ref),(sprintf 'Writing header (%s)',$test_filename));

    # Write data rows
    foreach my $data_row_ref ( @{ $tests{$key}{'data_rows'} } ) {
        $opt_ref->{'out_data'} = $data_row_ref;
        ok(main::write_csv_data_row($opt_ref),(sprintf 'Writing data row (%s)',$test_filename));
    } # END foreach #

    # Finalize output
    ok(main::release_out_csv($opt_ref),(sprintf 'Releasing output CSV (%s)',$test_filename));
    ok(main::close_output_file($opt_ref),(sprintf 'Closing output file (%s)',$test_filename));

    # Initialize input
    $opt_ref->{'input'} = $test_filepath;
    ok(main::set_input_options($opt_ref),(sprintf 'Setting input options (%s)',$test_filename));
    ok(main::open_input_file($opt_ref),(sprintf 'Opening input file (%s)',$test_filename));
    ok(main::acquire_in_csv($opt_ref),(sprintf 'Initializing input CSV (%s)',$test_filename));

    # Read header
    ok(main::read_csv_header($opt_ref),(sprintf 'Reading header (%s)',$test_filename));
    is_deeply($opt_ref->{'in_header'},$tests{$key}{'header'},(sprintf 'Verifying header (%s)',$test_filename));

    # Write data rows
    foreach my $data_row_ref ( @{ $tests{$key}{'data_rows'} } ) {
        ok(main::read_csv_data_row($opt_ref),(sprintf 'Reading data row (%s)',$test_filename));
        is_deeply($opt_ref->{'in_data'},$data_row_ref,(sprintf 'Verifying data row (%s)',$test_filename));
    } # END foreach #

    # Finalize input
    ok(main::release_in_csv($opt_ref),(sprintf 'Releasing input CSV (%s)',$test_filename));
    ok(main::close_input_file($opt_ref),(sprintf 'Closing input file (%s)',$test_filename));

    unlink $test_filepath;
} # END foreach #
