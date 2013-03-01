#!/usr/bin/env perl6

use Test;

use CSS::Grammar;
use CSS::Grammar::CSS3;
use CSS::Grammar::Actions;

use lib '.';
use t::CSS;

my $css_actions = CSS::Grammar::Actions.new;

# to do: nested rule-sets. grammars?

my $nested = '
@page { color: red;
        @top-center {
           content: "Page " counter(page);
       }
}';

for (
    at_rule   => {input => '@page :left { margin-left: 4cm; }',
                  ast => {"page_pseudo" => "left", "declarations" => ["declaration" => {"property" => {"ident" => "margin-left"}, "expr" => ["term" => {length => 4}]}]},
    },
    at_rule   => {input => '@page :junk { margin-right: 2cm }',
                  ast => {"declarations" => ["declaration" => {"property" => {"ident" => "margin-right"}, "expr" => ["term" => {length => 2}]}]},
                  warnings => 'ignoring page pseudo: junk',
    },
    at_rule   => {input => '@page : { margin-right: 2cm }',
                  ast => Mu,
                  warnings => "':' should be followed by one of: left right first",
    },
    ) {
    my $rule = $_.key;
    my %test = $_.value;
    my $input = %test<input>;

    $css_actions.warnings = ();
    my $p3 = CSS::Grammar::CSS3.parse( $input, :rule($rule), :actions($css_actions));
    t::CSS::parse_tests($input, $p3, :rule($rule), :compat('css3 at-rule'),
                         :warnings($css_actions.warnings),
                         :expected(%test) );
}

done;
