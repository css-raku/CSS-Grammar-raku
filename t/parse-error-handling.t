#!/usr/bin/env perl6

# these tests check for conformance with error handling as outline in
# http://www.w3.org/TR/2011/REC-CSS2-20110607/syndata.html#parsing-errors

use Test;

use CSS::Grammar;
use CSS::Grammar::CSS3;
use CSS::Grammar::Actions;

use lib '.';
use t::AST;

my $css_actions = CSS::Grammar::Actions.new;

for (
    ruleset =>  {input => 'h1 { color: red; rotation: 70minutes }',
                 warnings => ['skipping term: 70minutes ', 'dropping declaration: rotation'],
                 ast => {"selectors" => ["selector" => ["simple_selector" => ["element_name" => "h1"]]],
                 "declarations" => ["declaration" => {"property" => "color", "expr" => ["term" => "red"]}]},
    },
    ruleset => {input => 'p { color:green; color }',                # malformed declaration missing ':', value
                ast => Mu,
                warnings => 'skipping term: color ',
    },
    ruleset => {input => 'p { color:red;   color; color:green }',   # same with expected recovery
                ast => Mu,
                warnings => 'skipping term: color',
    },
    ruleset => {input => 'p { color:green; color: }',               # malformed declaration missing value
                ast => Mu,
                warnings => 'incomplete declaration',
    },
    ruleset => {input => 'p { color:red;   color:; color:green }',  # same with expected recovery
                 ast => Mu, warnings => 'incomplete declaration',
    },
    ruleset => {input => 'p { color:green; color{;color:maroon} }', # unexpected tokens { }
                 ast => Mu, warnings => 'skipping term: color{;color:maroon} ',
    },
    ruleset => {input => 'p { color:red;   color{;color:maroon}; color:green }',  # same with recovery
                ast => Mu, warnings => Mu,
                warnings => 'skipping term: color{;color:maroon}',
    },
    stylesheet => {input => 'p @here {color: red}',  # ruleset with unexpected at-keyword "@here"
                ast => Mu, warnings => 'skipping: p @here {color: red}',
    },
    stylesheet => {input => '@foo @bar;',            # at-rule with unexpected at-keyword "@bar"
                   ast => Mu, warnings => Mu,
                   warnings => 'skipping: @foo @bar;',
    },
    stylesheet => {input => '}} {{ - }}',
                   ast => Mu,
                   warnings => ['skipping: }', 'skipping: }', 'skipping: {{ - }}'],
    },
    # example from http://www.w3.org/TR/2003/WD-css3-syntax-20030813/#rule-sets
    # the middle rule is invalid and should be skipped
    stylesheet => {input => 'h1, h2 {color: green }
h3, h4 & h5 {color: red }
h6 {color: black }',
            warnings => 'skipping: h3, h4 & h5 {color: red }',
            ast => ["ruleset" => {"selectors" => ["selector" => ["simple_selector" => ["element_name" => "h1"]],
                                                  "selector" => ["simple_selector" => ["element_name" => "h2"]]],
                                  "declarations" => ["declaration" => {"property" => "color", "expr" => ["term" => "green"]}]},
                    "ruleset" => {"selectors" => ["selector" => ["simple_selector" => ["element_name" => "h6"]]],
                                  "declarations" => ["declaration" => {"property" => "color", "expr" => ["term" => "black"]}]}]
    },
    stylesheet => {input => '@three-dee {
      @background-lighting {
        azimuth: 30deg;
        elevation: 190deg;
      }
      h1 { color: red }
    }
    h1 { color: blue }',
                   warnings => 'skipping: @three-dee {\n      @background-lighting {\n        azimuth: 30deg;\n        elevation: 190deg;\n      }\n      h1 { color: red }\n    }\n    ',
                   ast => ["ruleset" => {"selectors" => ["selector" => ["simple_selector" => ["element_name" => "h1"]]],
                                         "declarations" => ["declaration" => {"property" => "color", "expr" => ["term" => "blue"]}]}],
    },
    # try a few extended terms
    stylesheet => {input => '@media print and (width: 21cm)  @page { margin: 3cm;  @top-center { content: "Page " counter(page); }}',
                   ast => [], warnings => 'skipping: @media print and (width: 21cm)  @page { margin: 3cm;  @top-center { content: "Page " counter(page); }}',
    },
    stylesheet => {input => '* foo|* |h1 body:not(.home) h2 + p:first-letter tr:nth-last-child(-n+2) object[type^="image/" {}',
                   ast => [], warnings => 'skipping: * foo|* |h1 body:not(.home) h2 + p:first-letter tr:nth-last-child(-n+2) object[type^="image/" {}',
    },
    ) {
    my $rule = $_.key;
    my %test = $_.value;
    my $input = %test<input>;

    $css_actions.warnings = ();
    my $p3 = CSS::Grammar::CSS3.parse( $input, :rule($rule), :actions($css_actions));
    t::AST::parse_tests($input, $p3, :rule($rule), :suite('css3 errors'),
                         :warnings($css_actions.warnings),
                         :expected(%test) );
}

done;
