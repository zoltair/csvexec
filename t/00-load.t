#!/usr/bin/perl
use utf8;
use Modern::Perl qw(2018);
use English qw(-no_match_vars);
use Const::Fast;
use File::Spec;
use Test::More;

# Untested/untestable functions
my @funcs = qw(
    run
    init            final
    process_header  process_data
    print_usage     print_options
); # END @funcs #

# Test counts
const my $LOAD_TEST_COUNT => 2;
const my $BASE_TEST_COUNT => 3;
const my $FUNC_TEST_COUNT => scalar @funcs;

# Test plan
my $count = $LOAD_TEST_COUNT;
$count += $BASE_TEST_COUNT;
$count += $FUNC_TEST_COUNT;
plan tests => $count;

# Load tests
use_ok('Local::CSV_Exec::Framework');
require_ok('./script/csvexec');

# Base tests
ok(defined &main::get_opt_ref,'get_opt_ref() is defined');
my $opt_ref = main::get_opt_ref();
ok(defined $opt_ref, 'Global opt_ref is defined');
ok(defined $opt_ref->{'logname'}, 'Global logname is defined');

# Function tests
foreach my $func ( @funcs ) {
    ok(defined &{$func}, (sprintf '%s() is defined',$func));
} # END foreach #
