#!/usr/bin/perl
use utf8;
use Modern::Perl qw(2018);
use English qw(-no_match_vars);
use Const::Fast;
use File::Spec;
use Test::More;

my @funcs = qw(
    set_default_parser_hooks
    set_loaded_parser_hooks
);
my @hooks = qw(
    parser_get_options
    parser_print_options
    parser_print_usage
    parser_init
    parser_final
    parser_header_row
    parser_data_row
    parser_wanted
); # END @hooks #

my @header_tests = (
   [ [ ],
     'empty header' ],
   [ [ 'SRC_BASE',
       'SRC_PATH',
       'SRC_FILENAME' ],
     'find header' ],
); # END @header_tests #

my @data_tests = (
    [ { },
      'empty data row' ],
    [ { 'SRC_BASE'     => '/home/zoltair',
        'SRC_PATH'     => 'movies',
        'SRC_FILENAME' => 'The Black Hole (1979).mkv' },
      'find data' ],
); # END @data_tests #

my @wanted_tests = (
    [ { 'type'         => 'f',
        'src_filepath' => './script/csvexec' },
      1,
      'Wanted file/found file' ],
    [ { 'type'         => 'd',
        'src_filepath' => './script/csvexec' },
      undef,
      'Wanted directory/found file' ],
    [ { 'type'         => 'f',
        'src_filepath' => './script' },
      undef,
      'Wanted file/found directory' ],
    [ { 'type'         => 'd',
        'src_filepath' => './script' },
      1,
      'Wanted directory/found directory' ],
); # END @wanted_tests #

# Set testing plan
const my $BASE_TEST_COUNT   => 3;
const my $HOOK_TEST_COUNT   => 5;
const my $HEADER_TEST_COUNT => 2;
const my $DATA_TEST_COUNT   => 2;
const my $WANTED_TEST_COUNT => 1;
my $count = $BASE_TEST_COUNT;
$count += scalar @funcs;
$count += ($HOOK_TEST_COUNT   * scalar @hooks);
$count += ($HEADER_TEST_COUNT * scalar @header_tests);
$count += ($DATA_TEST_COUNT   * scalar @data_tests);
$count += ($WANTED_TEST_COUNT * scalar @wanted_tests);
plan tests => $count;

# Load script
require_ok('./script/csvexec');
my $opt_ref = main::get_opt_ref();

#---------------------------------------------------------------
# Function definition tests
#---------------------------------------------------------------
foreach my $func ( @funcs ) {
    ok(defined &{$func}, (sprintf '%s() is defined',$func));
} # END foreach #

#---------------------------------------------------------------
# Default Hooks
#---------------------------------------------------------------
foreach my $hook ( @hooks ) {
    ok(!defined $opt_ref->{$hook}, (sprintf '%s() hook is not defined',$hook));
} # END foreach #
ok(main::set_default_parser_hooks($opt_ref),'set_default_parser_hooks() call');
foreach my $hook ( @hooks ) {
    ok(defined $opt_ref->{$hook}, (sprintf '%s() hook defined',$hook));
    ok($opt_ref->{$hook}, (sprintf 'default %s() hook call',$hook));
} # END foreach #

#---------------------------------------------------------------
# Default "header_row" hook
#   Should copy 'in_header' array to 'out_header' array
#---------------------------------------------------------------
foreach my $test ( @header_tests ) {
    my ($input, $name) = @{$test};
    $opt_ref->{'in_header'} = $input;
    ok($opt_ref->{'parser_header_row'}->($opt_ref), (sprintf 'default parser_header_row() call: %s', $name));
    is_deeply($opt_ref->{'out_header'}, $input, (sprintf 'default parser_header_row() results: %s', $name));
} # END foreach #

#---------------------------------------------------------------
# Default "data_row" hook
#   Should copy 'in_data' hash to 'out_data' hash
#---------------------------------------------------------------
foreach my $test ( @data_tests ) {
    my ($input, $name) = @{$test};
    $opt_ref->{'in_data'} = $input;
    ok($opt_ref->{'parser_data_row'}->($opt_ref), (sprintf 'default parser_data_row() call: %s', $name));
    is_deeply($opt_ref->{'out_data'}, $input, (sprintf 'default parser_data_row() results: %s', $name));
} # END foreach #

#---------------------------------------------------------------
# Default "wanted" hook
#   Returns true for files of the selected "type"
#---------------------------------------------------------------
foreach my $test ( @wanted_tests ) {
    my ($input, $output, $name) = @{$test};
    foreach ( keys %{$input} ) { $opt_ref->{$_} = $input->{$_}; }
    is($opt_ref->{'parser_wanted'}->($opt_ref),$output,$name);
} # END foreach #

#---------------------------------------------------------------
# Loaded Hooks
#---------------------------------------------------------------

# Hook functions (each returns its own name for testing purposes)
sub main::parser_get_options   { return 'parser_get_options'; };
sub main::parser_print_options { return 'parser_print_options'; };
sub main::parser_print_usage   { return 'parser_print_usage'; };
sub main::parser_init          { return 'parser_init'; };
sub main::parser_final         { return 'parser_final'; };
sub main::parser_header_row    { return 'parser_header_row'; };
sub main::parser_data_row      { return 'parser_data_row'; };
sub main::parser_wanted        { return 'parser_wanted'; };

foreach ( @hooks ) { $opt_ref->{$_} = undef; }
ok(main::set_loaded_parser_hooks($opt_ref), 'set_loaded_parser_hooks() call');

# Hooks are defined and return their own name
foreach my $hook ( @hooks ) {
    ok(defined $opt_ref->{$hook}, (sprintf '%s() hook is defined',$hook));
    is($opt_ref->{$hook}->($opt_ref), $hook, (sprintf '%s() call',$hook));
} # END foreach #
