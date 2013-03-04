#!/usr/bin/env perl6

use Test;

use CSS::Grammar::CSS1;
use CSS::Grammar::CSS21;
use CSS::Grammar::CSS3;
use CSS::Grammar::Actions;
use lib '.';
use t::CSS;

my $css_actions = CSS::Grammar::Actions.new;

for (
    string => {input => "'\\\nto \\\n\\\nbe \\\ncontinued\\\n'",
               ast => 'to be continued'},
    ) {

    my $rule = $_.key;
    my %test = $_.value;
    my $input = %test<input>;

    $css_actions.warnings = ();
     my $p3 = CSS::Grammar::CSS3.parse( $input, :rule($rule), :actions($css_actions));
    t::CSS::parse_tests($input, $p3, :rule($rule), :compat('css3'),
                         :warnings($css_actions.warnings),
                         :expected(%test) );
}

done;
