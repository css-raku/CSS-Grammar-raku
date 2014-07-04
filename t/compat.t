#!/usr/bin/env perl6

# general compatibility tests
# -- css1 is a subset of css2.1 and sometimes parses differently
# -- css3 without extensions should be largely css2.1 compatibile
# -- our scanning grammar should parse identically to css21 and css3, when
#    there are no warnings

use Test;
use JSON::Tiny;

use CSS::Grammar::CSS1;
use CSS::Grammar::CSS21;
use CSS::Grammar::CSS3;
use CSS::Grammar::Actions;
use CSS::Grammar::Test;

my $css-actions = CSS::Grammar::Actions.new;

my $fh = open 't/compat.json', :r;

for $fh.lines {
    if .substr(0,2) eq '//' {
##        note '[' ~ .substr(2) ~ ']';
        next;
    }
    my ($rule, $t) = @( from-json($_) );
    my %test = %$t;
    my $input = %test<input>;

    for (css1  => CSS::Grammar::CSS1),
        (css21 => CSS::Grammar::CSS21),
        (css3  => CSS::Grammar::CSS3) {

	my ($level, $class) = .kv;
	my %level-tests = %( %test{$level} // () );
	my %expected = %test, %level-tests;

	$css-actions.reset;

	if %expected<skip> {
	    skip( $rule ~ ': ' ~ %expected<skip> );
	    next;
	}

	CSS::Grammar::Test::parse-tests($class, $input,
					:actions($css-actions),
					:rule($rule),
					:suite($level),
					:expected(%expected));
    }

    if CSS::Grammar::Core.can( '_' ~ $rule ) {
        my %expected =  %(%test, warnings => Any, ast => Any);
        CSS::Grammar::Test::parse-tests(CSS::Grammar::Core, $input,
					    :actions($css-actions),
					    :rule('_' ~ $rule),
					    :suite('scan'),
					    :expected(%expected));
    }
}

done;
