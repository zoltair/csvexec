#!/usr/bin/perl
use utf8;
use Modern::Perl qw(2018);
use English qw(-no_match_vars);
use Const::Fast;
use File::Spec;
use Test::More;
use Cwd qw( abs_path );

# Test script program name
my ( $volume, $program_path, $program_filename ) = File::Spec->splitpath($PROGRAM_NAME);

my @funcs = qw(
  get_options
  set_input_options
  set_output_options
); # END @funcs #

# Test Indexes
const my $INPUT => 0;
const my $OUTPUT => 1;
const my $NAME => 2;

# Test filenames
my $exists_path = File::Spec->catfile($program_path,(sprintf '%s.d',$program_filename));
my $exists_filename    = 'readme.txt';
my $exists_filepath    = File::Spec->catfile($exists_path,$exists_filename);
my $no_exists_filename = 'DELETE';
my $no_exists_filepath = File::Spec->catfile($exists_path,$no_exists_filename);

my @option_tests = (
    # Defaults
    [ [ ],
      { 'help'   => undef, 'check' => undef, 'dry-run' => undef, 'verbose' => undef,
        'parser' => undef, 'input' => undef, 'output'  => undef, 'type'    => 'f' },
      '(defaults)' ],
    # --help
    [ [ '--help' ],    { 'help' => 1 },     'help option' ],
    [ [ '-h' ],        { 'help' => 1 },     'h option' ],
    # --check
    [ [ '--check' ],   { 'check' => 1 } ,   'check option' ],
    [ [ '-c' ],        { 'check' => 1 } ,   'c option' ],
    # --dry-run
    [ [ '--dry-run' ], { 'dry-run' => 1 } , 'dry-run option' ],
    [ [ '-d' ],        { 'dry-run' => 1 } , 'd option' ],
    # --verbose
    [ [ '--verbose' ], { 'verbose' => 1 } , 'verbose option' ],
    [ [ '-v' ],        { 'verbose' => 1 } , 'v option' ],
    # --append
    [ [ '--append' ],  { 'append' => 1 } ,  'append option' ],
    [ [ '-a' ],        { 'append' => 1 } ,  'a option' ],
    # --parser
    [ [ '--parser', 'MoveFiles' ] ,
      { 'help'   => undef,       'check' => undef, 'dry-run' => undef, 'verbose' => undef,
        'parser' => 'MoveFiles', 'input' => undef , 'output' => undef, 'type'    => 'f' } ,
      'parser option' ],
    [ [ '-p', 'MoveFiles' ] ,
      { 'help'   => undef,       'check' => undef, 'dry-run' => undef, 'verbose' => undef,
        'parser' => 'MoveFiles', 'input' => undef , 'output' => undef, 'type'    => 'f' } ,
      'p option' ],
    # --input
    [ [ '--input', 'input.csv' ] ,
      { 'help'   => undef, 'check' => undef,      'dry-run' => undef, 'verbose' => undef,
        'parser' => undef, 'input' => 'input.csv', 'output' => undef, 'type'    => 'f' } ,
      'input option' ],
    [ [ '-i', 'input.csv' ] ,
      { 'help'   => undef, 'check' => undef,      'dry-run' => undef, 'verbose' => undef,
        'parser' => undef, 'input' => 'input.csv', 'output' => undef, 'type'    => 'f' } ,
      'i option' ],
    # output
    #   'output' is not set by get_options();
    #   it is set in main() after the 'parser_get_options' hook function has been called
    [ [ 'output.csv' ] ,
      { 'help'   => undef, 'check' => undef, 'dry-run' => undef, 'verbose' => undef,
        'parser' => undef, 'input' => undef,  'output' => undef, 'type'    => 'f' },
      'output option' ],
    # --type
    [ [ '--type', 'f' ],     { 'type' => 'f' } , 'type option (file)' ],
    [ [ '--type', 'd' ],     { 'type' => 'd' } , 'type option (directory)' ],
    [ [ '--type', 'l' ],     { 'type' => 'l' } , 'type option (symbolic link)' ],
    [ [ '--type', 'b' ],     { 'type' => 'b' } , 'type option (block special file)' ],
    [ [ '--type', 'c' ],     { 'type' => 'c' } , 'type option (character special file)' ],
    [ [ '-t', 'f' ],         { 'type' => 'f' } , 't option (file)' ],
    [ [ '-t', 'd' ],         { 'type' => 'd' } , 't option (directory)' ],
    [ [ '-t', 'l' ],         { 'type' => 'l' } , 't option (symbolic link)' ],
    [ [ '-t', 'b' ],         { 'type' => 'b' } , 't option (block special file)' ],
    [ [ '-t', 'c' ],         { 'type' => 'c' } , 't option (character special file)' ],
    [ [ '--type', 'file' ],  { 'type' => 'f' } , 'type option (\'file\')' ],
    [ [ '--type', 'dir' ],   { 'type' => 'd' } , 'type option (\'dir\')' ],
    [ [ '--type', 'link' ],  { 'type' => 'l' } , 'type option (\'link\')' ],
    [ [ '--type', 'block' ], { 'type' => 'b' } , 'type option (\'block\')' ],
    [ [ '--type', 'char' ],  { 'type' => 'c' } , 'type option (\'char\')' ],
); # END @option_tests #

my @input_tests = (
    [ { 'input' => undef },
      { 'in_src'      => 'stdin',
        'in_volume'   => undef,
        'in_path'     => undef,
        'in_filename' => undef,
        'in_filepath' => undef },
      'No input given' ],
    [ { 'input' => $exists_filepath } ,
      { 'in_src'      => 'file',
        'in_volume'   => $volume,
        'in_path'     => abs_path($exists_path),
        'in_filename' => $exists_filename,
        'in_filepath' => abs_path($exists_filepath) },
      'Existing file' ],
    [ { 'input' => $exists_path },
      { 'in_src'      => 'find',
        'in_volume'   => $volume,
        'in_path'     => abs_path($exists_path),
        'in_filename' => undef,
        'in_filepath' => abs_path($exists_path) },
      'Existing directory' ],
    [ { 'input' => $no_exists_filepath },
      { 'in_src'      => 'stdin',
        'in_volume'   => undef,
        'in_path'     => undef,
        'in_filename' => undef,
        'in_filepath' => undef },
      'Non-existant file/directory' ],
); # END @input_tests #

my @output_tests = (
    [ { 'output' => undef },
      { 'out_dst'      => 'stdout',
        'out_volume'   => undef,
        'out_path'     => undef,
        'out_filename' => undef,
        'out_filepath' => undef },
      'No output given' ],
    [ { 'output' => $exists_filepath } ,
      { 'out_dst'      => 'file',
        'out_volume'   => $volume,
        'out_path'     => abs_path($exists_path),
        'out_filename' => $exists_filename,
        'out_filepath' => abs_path($exists_filepath) },
      'Existing file' ],
    [ { 'output' => $exists_path },
      { 'out_dst'      => 'stdout',
        'out_volume'   => undef,
        'out_path'     => undef,
        'out_filename' => undef,
        'out_filepath' => undef },
      'Existing directory' ],
    [ { 'output' => $no_exists_filepath },
      { 'out_dst'      => 'file',
        'out_volume'   => $volume,
        'out_path'     => abs_path($exists_path),
        'out_filename' => $no_exists_filename,
        'out_filepath' => abs_path($no_exists_filepath) },
      'Non-existant file/directory' ],
); # END @output_tests #

#---------------------------------------------------------------
# Testing plan
#---------------------------------------------------------------
const my $BASE_TEST_COUNT => 1;
my $count = $BASE_TEST_COUNT;
$count += scalar @funcs;
$count += scalar @option_tests;
foreach ( @option_tests ) { $count += scalar keys %{$_->[$OUTPUT]}; }
$count += scalar @input_tests;
foreach ( @input_tests ) { $count += scalar keys %{$_->[$OUTPUT]}; }
$count += scalar @output_tests;
foreach ( @output_tests ) { $count += scalar keys %{$_->[$OUTPUT]}; }
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
# get_options() tests
#---------------------------------------------------------------
foreach my $test ( @option_tests ) {
    my ( $input, $output, $name ) = @{$test};
    $opt_ref->{'args'} = $input;
    foreach ( keys %{$output} ) { $opt_ref->{$_} = undef; }
    ok(main::get_options($opt_ref), (sprintf 'get_options() call: %s',$name));
    foreach ( keys %{$output} ) { is($opt_ref->{$_}, $output->{$_}, (sprintf '%s: %s value check', $name, $_)); }
} # END foreach #

# Turn off logging, if needed
my $logger = Log::Log4perl::get_logger($opt_ref->{'logname'});
$logger->level($Log::Log4perl::OFF) if $Log::Log4perl::OFF;

#---------------------------------------------------------------
# set_input_options() tests
#---------------------------------------------------------------
foreach my $test ( @input_tests ) {
    my ( $input, $output, $name ) = @{$test};
    foreach ( keys %{$input} )  { $opt_ref->{$_} = $input->{$_}; }
    foreach ( keys %{$output} ) { $opt_ref->{$_} = undef; }
    ok(main::set_input_options($opt_ref), (sprintf 'set_input_options() call: %s',$name));
    foreach ( keys %{$output} ) { is($opt_ref->{$_}, $output->{$_}, (sprintf '%s: %s value',$name,$_)); }
    foreach ( keys %{$input} )  { $opt_ref->{$_} = undef; }
} # END foreach #

#---------------------------------------------------------------
# set_output_options() tests
#---------------------------------------------------------------
foreach my $test ( @output_tests ) {
    my ( $input, $output, $name ) = @{$test};
    foreach ( keys %{$input} )  { $opt_ref->{$_} = $input->{$_}; }
    foreach ( keys %{$output} ) { $opt_ref->{$_} = undef; }
    ok(main::set_output_options($opt_ref), (sprintf 'set_output_options() call: %s',$name));
    foreach ( keys %{$output} ) { is($opt_ref->{$_}, $output->{$_}, (sprintf '%s: %s value',$name,$_)); }
    foreach ( keys %{$input} )  { $opt_ref->{$_} = undef; }
} # END foreach #
