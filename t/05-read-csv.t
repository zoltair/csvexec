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
    read_csv_header
    read_csv_data_row
); # END @funcs #

my @encodings = qw(
    utf-8
    utf-8-bom
    utf-16be-bom
    utf-16le-bom
); # END @encodings #

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
    map { { zip @COLORS_HEADER => @{$_} } } # Create a hash reference for each data row
    @COLORS_DATA_ROWS;
$tests{'comics'}{'header'} = \@COMICS_HEADER;
@{ $tests{'comics'}{'data_rows'} } =
    map { { zip @COMICS_HEADER => @{$_} } } # Create a hash reference for each data row
    @COMICS_DATA_ROWS;
## use critic

# Test counts
const my $BASE_TEST_COUNT     => 1;
const my $FILE_TEST_COUNT     => 5;
const my $HEADER_TEST_COUNT   => 2;
const my $DATA_ROW_TEST_COUNT => 2;

# Test plan
my $count = $BASE_TEST_COUNT;
$count += scalar @funcs;
$count += ($FILE_TEST_COUNT   * (scalar keys %tests) * (scalar @encodings));
$count += ($HEADER_TEST_COUNT * (scalar keys %tests) * (scalar @encodings));
foreach my $key ( keys %tests ) {
    $count += ($DATA_ROW_TEST_COUNT * (scalar @{ $tests{$key}{'data_rows'} }) * (scalar @encodings));
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
    my $test_ref = $tests{$key};
    foreach my $enc ( @encodings ) {

        # Generate filenames
        my $test_filename = sprintf '%s-%s.csv',$key,$enc;
        my $test_filepath = File::Spec->catfile($test_path,$test_filename);

        # Initialize
        $opt_ref->{'input'} = $test_filepath;
        ok(main::set_input_options($opt_ref),(sprintf 'Setting input options (%s)',$test_filename));
        ok(main::open_input_file($opt_ref),(sprintf 'Opening file (%s)',$test_filename));
        ok(main::acquire_in_csv($opt_ref),(sprintf 'Initializing CSV (%s)',$test_filename));

        # Test header
        my $header_ref = $test_ref->{'header'};
        ok(main::read_csv_header($opt_ref),(sprintf 'Read input header (%s)',$test_filename));
        is_deeply($opt_ref->{'in_header'},$header_ref,(sprintf 'Input header (%s)',$test_filename));

        # Test data
        foreach my $data_row_ref ( @{ $test_ref->{'data_rows'} } ) {
            ok(main::read_csv_data_row($opt_ref),(sprintf 'Read input data (%s)',$test_filename));
            is_deeply($opt_ref->{'in_data'},$data_row_ref,(sprintf 'Input data read (%s)',$test_filename));
        } # END foreach #

        # Finalize
        ok(main::release_in_csv($opt_ref),(sprintf 'Releasing CSV (%s)',$test_filename));
        ok(main::close_input_file($opt_ref),(sprintf 'Closing file (%s)',$test_filename));
    } # END foreach #
} # END foreach #
