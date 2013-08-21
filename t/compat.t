#!/usr/bin/env perl6

# general compatibility tests
# -- css1 is a subset of css2.1 and sometimes parses differently
# -- css3 without extensions should be largley css2.1 compatibile
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

for ($fh.lines) {
    if .substr(0,2) eq '//' {
##        note '[' ~ .substr(2) ~ ']';
        next;
    }
    my ($rule, %test) = @( from-json($_) );
    my $input = %test<input>;

    for (css1  => CSS::Grammar::CSS1),
        (css21 => CSS::Grammar::CSS21),
        (css3  => CSS::Grammar::CSS3),
        (scan  => CSS::Grammar::Scan) {

	my ($level, $class) = .kv;
	my $pfx = '';

	my $level-tests = %test{$level} // {};
	my %expected =  %(%test, %$level-tests);

	if $level eq 'scan' {
	    # the scanning grammar only implements a subset of rules
	    next unless $rule ~~ /^(TOP|statement|at\-rule|ruleset|selectors|declaration[s|\-list]|property)$/;
	    # doesn't emit warnings or ASTs...
	    %expected<warnings> = Any;
	    %expected<ast> = Any;
	    # all rules are prefixed by '_'
	    $pfx = '_';
	}

	$css-actions.reset;

	unless $level-tests<skip_test> {
	    CSS::Grammar::Test::parse-tests($class, $input,
					    :actions($css-actions),
					    :rule($pfx ~ $rule),
					    :suite($level),
					    :expected(%expected) );
	}
    }
}

done;
