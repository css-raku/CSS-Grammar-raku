#!/usr/bin/env perl6

# general compatibility tests
# -- css1 is a subset of css2.1 and sometimes parses differently
# -- css3 without extensions should be largely css2.1 compatibile
# -- the core grammar should parse identically to css2.1 and css3

use Test;
use JSON::Fast;

use CSS::Grammar::Test :parse-tests;
use CSS::Grammar::CSS1;
use CSS::Grammar::CSS21;
use CSS::Grammar::CSS3;
use CSS::Grammar::CSS4;
use CSS::Grammar::Actions;

my $actions = CSS::Grammar::Actions.new;

for 't/compat.json'.IO.lines {
    if .starts-with('//') {
        ## note '[' ~ .substr(2) ~ ']';
        next;
    }
    my ($rule, $test) = @( from-json($_) );
    my $input = $test<input>;

    for CSS::Grammar::CSS1, CSS::Grammar::CSS21, CSS::Grammar::CSS3, CSS::Grammar::CSS4 -> $grammar {

        my $level = $grammar.^shortname.lc;
	my %level-tests = %( $test{$level} // () );
	my %expected = %$test, %level-tests;

	$actions.reset;

	if %expected<skip> {
	    skip $rule ~ ': ' ~ %expected<skip>;
	    next;
	}

	parse-tests($grammar, $input,
                    :$actions,
                    :$rule,
                    :%expected);
    }

    if CSS::Grammar::Core.can( '_' ~ $rule ) {
        my %core-tests = $test<core> // {};
	my %expected = %$test, ast => Any, warnings => Any, %core-tests;
        %expected<warnings> //= Any;
        parse-tests(CSS::Grammar::Core, $input,
                    :$actions,
                    :rule('_' ~ $rule),
                    :%expected);
    }
}

done-testing;
