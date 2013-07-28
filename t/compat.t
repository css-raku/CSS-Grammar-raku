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

use lib '.';
use CSS::Grammar::Test;

my $css_actions = CSS::Grammar::Actions.new;

my $fh = open 't/compat.json', :r;

for ($fh.lines) {
    if .substr(0,2) eq '//' {
##        note '[' ~ .substr(2) ~ ']';
        next;
    }
    my ($rule, %test) = @( from-json($_) );

    my $input = %test<input>;

    $css_actions.reset;
    my $css1 = %test<css1> // {};
    my $css2 = %test<css2> // {};
    my $css3 = %test<css3> // {};

    # CSS1 Compat
    unless %$css1<skip_test> {
        $css_actions.reset;
        my $p1 = CSS::Grammar::CSS1.parse( $input, :rule($rule), :actions($css_actions));
        CSS::Grammar::Test::parse_tests($input, $p1, :rule($rule), :suite('css1'),
                            :warnings($css_actions.warnings),
                            :expected( %(%test, %$css1)) );
    }
        
    # CSS21 Compat
    $css_actions.reset;
    my $p2 = CSS::Grammar::CSS21.parse( $input, :rule($rule), :actions($css_actions));
    CSS::Grammar::Test::parse_tests($input, $p2, :rule($rule), :suite('css2'),
                         :warnings($css_actions.warnings),
                         :expected( %(%test, %$css2)) );

    # CSS3 Compat
    # -- css3 core only
    $css_actions.reset;
    my $p3 = CSS::Grammar::CSS3.parse( $input, :rule($rule), :actions($css_actions));
    CSS::Grammar::Test::parse_tests($input, $p3, :rule($rule), :suite('css3'),
                         :warnings($css_actions.warnings),
                         :expected( %(%test, %$css3)) );

    # try a general scan
    if ($rule ~~ /^(TOP|statement|at\-rule|ruleset|selectors|declaration[s|\-list]|property)$/
    && !$css_actions.warnings) {
        my $p_any = CSS::Grammar::Scan.parse( $input, :rule('_'~$rule) );
        CSS::Grammar::Test::parse_tests($input, $p_any, :rule($rule), :suite('scan'),
                            :expected({ast => Any}) );
    }
}

done;
