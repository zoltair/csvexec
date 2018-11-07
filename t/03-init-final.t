#!/usr/bin/perl
use utf8;
use Modern::Perl qw(2018);
use English qw(-no_match_vars);
use Const::Fast;
use File::Spec;
use Test::More;

# Test script program name
my ( $volume, $program_path, $program_filename ) = File::Spec->splitpath($PROGRAM_NAME);
my $test_path = File::Spec->catdir($program_path,(sprintf '%s.d',$program_filename));

# Test filepaths
my $test_in_filename  = 'input.csv';
my $test_in_filepath  = File::Spec->catfile($test_path,$test_in_filename);
my $test_out_filename = 'output.csv';
my $test_out_filepath = File::Spec->catfile($test_path,$test_out_filename);

my @funcs = qw(
    acquire_in_csv    release_in_csv
    acquire_out_csv   release_out_csv
    acquire_stdin     release_stdin
    acquire_stdout    release_stdout
    open_input_file   close_input_file
    open_output_file  close_output_file
); # END @funcs #

const my $BASE_TEST_COUNT => 28;
my $count = $BASE_TEST_COUNT;
$count += scalar @funcs;
plan tests => $count;

# Load script
require_ok('./script/csvexec');
my $opt_ref = main::get_opt_ref();

# Function definition tests
foreach my $func ( @funcs ) {
    ok(defined &{$func}, (sprintf '%s() is defined',$func));
} # END foreach #

# Acquire/Release CSV objects
ok(main::acquire_in_csv($opt_ref),'Acquire input CSV object');
ok(defined $opt_ref->{'in_csv'},'Input CSV object is defined');
ok(main::release_in_csv($opt_ref),'Release input CSV object');
ok(!defined $opt_ref->{'in_csv'},'Input CSV object is not defined');
ok(main::acquire_out_csv($opt_ref),'Acquire output CSV object');
ok(defined $opt_ref->{'out_csv'},'Output CSV object is defined');
ok(main::release_out_csv($opt_ref),'Release output CSV object');
ok(!defined $opt_ref->{'out_csv'},'Output CSV object is not defined');

# Open/Close STDIN/STDOUT
ok(main::acquire_stdin($opt_ref),'Open STDIN');
ok(defined $opt_ref->{'in_fh'},'STDIN file handle is defined');
ok(main::release_stdin($opt_ref),'Close STDIN');
ok(!defined $opt_ref->{'in_fh'},'STDIN file handle is not defined');
ok(main::acquire_stdout($opt_ref),'Open STDOUT');
ok(defined $opt_ref->{'out_fh'},'STDOUT file handle is defined');
ok(main::release_stdout($opt_ref),'Close STDOUT');
ok(!defined $opt_ref->{'out_fh'},'STDOUT file handle is not defined');

# Open/Close files
$opt_ref->{'input'} = $test_in_filepath;
ok(main::set_input_options($opt_ref),'Set input filepath');
ok(main::open_input_file($opt_ref),'Open input file');
ok(defined $opt_ref->{'in_fh'},'Input file handle is defined');
ok(main::close_input_file($opt_ref),'Close input file');
ok(!defined $opt_ref->{'in_fh'},'Input file handle is not defined');

$opt_ref->{'output'} = $test_out_filepath;
ok(main::set_output_options($opt_ref),'Set output filepath');
ok(main::open_output_file($opt_ref),'Open output file');
ok(defined $opt_ref->{'out_fh'},'Output file handle is defined');
ok(main::close_output_file($opt_ref),'Close output file');
ok(!defined $opt_ref->{'out_fh'},'Output file handle is not defined');
ok(-f $opt_ref->{'output'},'Ouput file exists');
unlink $opt_ref->{'output'};
