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

# Set testing plan
const my $BASE_TEST_COUNT => 4;
my $count = $BASE_TEST_COUNT;
$count += scalar @funcs;
plan tests => $count;

# Load script
require_ok('./script/csvexec');
ok(defined &main::get_opt_ref,'get_opt_ref() is defined');
my $opt_ref = main::get_opt_ref();

# Confirm global options
ok(defined $opt_ref, 'Global opt_ref is defined');
ok(defined $opt_ref->{'logname'}, 'Global logname is defined');

# Functions definition tests
foreach my $func ( @funcs ) {
    ok(defined &{$func}, (sprintf '%s() is defined',$func));
} # END foreach #
