#!/usr/bin/perl
use utf8;
use Modern::Perl qw(2018);
use English qw(-no_match_vars);
use Const::Fast;
use File::Spec;
use Test::More;
use Cwd qw( abs_path );
use List::MoreUtils qw( first_index );
use Array::Compare;

# Test script program name
my ( $volume, $program_path, $program_filename ) = File::Spec->splitpath($PROGRAM_NAME);
my $test_path     = File::Spec->catdir($program_path,(sprintf '%s.d',$program_filename));
my $test_filename = 'output.csv';
my $test_filepath = File::Spec->catfile($test_path,$test_filename);
my $find_path     = File::Spec->catdir($test_path,'find-dir');

my @funcs = qw(
    process_find_header
    process_find_data
    read_find_header
); # END @funcs #

const my $EMPTY => q{};
const my @HEADER => qw(
    SRC_BASE_PATH
    SRC_PATH
    SRC_FILENAME
    SRC_EXTENSION
); # END @HEADER #
const my @DATA_ROWS => (
    [ abs_path($find_path), $EMPTY,      'regular-file-1.txt', 'TXT'  ],
    [ abs_path($find_path), $EMPTY,      'regular-file-2.tmp', 'TMP'  ],
    [ abs_path($find_path), $EMPTY,      'regular-file-3',     $EMPTY ],
    [ abs_path($find_path), 'directory', 'regular-file',       $EMPTY ],
); # END @COLORS_DATA_ROWS #

# Test counts
const my $BASE_TEST_COUNT   => 1;
const my $HEADER_TEST_COUNT => 3;
const my $FIND_TEST_COUNT   => 9;
const my $READ_TEST_COUNT   => 8;

# Test plan
my $count = $BASE_TEST_COUNT;
$count += scalar @funcs;
$count += $HEADER_TEST_COUNT;
$count += $FIND_TEST_COUNT;
$count += $READ_TEST_COUNT;
$count += scalar @DATA_ROWS;
plan tests => $count;

# Load script
require_ok('./script/csvexec');
my $opt_ref = main::get_opt_ref();

# Function definition tests
foreach my $func ( @funcs ) {
    ok(defined &{$func},(sprintf '%s() is defined',$func));
} # END foreach #

# read_find_header() tests
ok(main::read_find_header($opt_ref),'read_find_header() call');
is_deeply($opt_ref->{'in_header'},\@HEADER,'Input header for find processing');
is_deeply($opt_ref->{'out_header'},\@HEADER,'Output header for find processing');

# Initialize input
$opt_ref->{'input'} = $find_path;
ok(main::set_input_options($opt_ref),'Setting input options');

# Initialize output
$opt_ref->{'output'} = $test_filepath;
ok(main::set_output_options($opt_ref),'Setting output options');
ok(main::open_output_file($opt_ref),'Opening output file');
ok(main::acquire_out_csv($opt_ref),'Initializing output CSV');

# Process Header
ok(main::set_default_parser_hooks($opt_ref),'set_default_parser_hooks() call');
ok(main::process_find_header($opt_ref),'process_find_header() call');

# Process Data Rows
$opt_ref->{'type'} = 'f';
ok(main::process_find_data($opt_ref),'process_find_data() call');

# Finalize output
ok(main::release_out_csv($opt_ref),'Releasing output CSV');
ok(main::close_output_file($opt_ref),'Closing output file');

# Initialize input
$opt_ref->{'input'} = $test_filepath;
ok(main::set_input_options($opt_ref),'Setting input options');
ok(main::open_input_file($opt_ref),'Opening input file');
ok(main::acquire_in_csv($opt_ref),'Initializing input CSV');

# Read header
ok(main::read_csv_header($opt_ref),'Reading header');
is_deeply($opt_ref->{'in_header'},\@HEADER,'Verifying header');

# Read data rows
# The files will not be found in a predictable order
my %found;
my $comp = Array::Compare->new();
foreach ( 0..$#DATA_ROWS ) {
    ok(main::read_csv_data_row($opt_ref),'Reading data row');
    my @data_row = map { $opt_ref->{'in_data'}->{$_} } @HEADER;
    my $index = first_index { $comp->compare(\@data_row,$_) } @DATA_ROWS;
    $found{$index} = 1;
} # END foreach #
is(scalar keys %found,scalar @DATA_ROWS,'All data rows found');

# Finalize input
ok(main::release_in_csv($opt_ref),'Releasing input CSV');
ok(main::close_input_file($opt_ref),'Closing input file');

unlink $test_filepath;
