#!/usr/bin/env perl6

use Test;

use CSS::Grammar::CSS3;
use CSS::Grammar::Actions;
use CSS::Grammar::Test;

my $actions = CSS::Grammar::Actions.new( );

my $fh = open 't/parse-verbose.json', :r;

for $fh.lines {

    if .substr(0,2) eq '//' {
##        note '[' ~ .substr(2) ~ ']';
        next;
    }
    my ($rule, $test) = @( from-json($_) );
    my $input = $test<input>;

    CSS::Grammar::Test::parse-tests(CSS::Grammar::CSS3, $input,
				    :actions($actions),
				    :rule($rule),
				    :suite<css3>,
                                    :verbose,
				    :expected($test) );
}

done;
