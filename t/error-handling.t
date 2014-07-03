#!/usr/bin/env perl6

# these tests check for conformance with error handling as outline in
# http://www.w3.org/TR/2011/REC-CSS2-20110607/syndata.html#parsing-errors

use Test;
use JSON::Tiny;

use CSS::Grammar;
use CSS::Grammar::CSS3;
use CSS::Grammar::Actions;
use CSS::Grammar::Test;

my $actions = CSS::Grammar::Actions.new;

my $fh = open("t/error-handling.json", :r);

for ( $fh.lines ) {
    if .substr(0,2) eq '//' {
##        note '[' ~ .substr(2) ~ ']';
        next;
    }
    my ($rule, $t) = @( from-json($_) );
    my %test = @$t;
    my $input = %test<input>;

    CSS::Grammar::Test::parse-tests(CSS::Grammar::CSS3, $input,
				    :actions($actions),
				    :rule($rule),
				    :suite<css3 errors>,
				    :expected(%test) );

}

done;
