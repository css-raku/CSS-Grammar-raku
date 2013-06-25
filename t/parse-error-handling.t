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
    declaration-list => {input => 'background:url("http://www.bg.com/pinkish.gif")',
            ast => {"background" => "expr" => ["term" => "http://www.bg.com/pinkish.gif"]},
    },
    declaration-list => {input => 'background:URL(http://www.bg.com/pinkish.gif)',
                         ast => {"background" => {"expr" => ["term" => "http://www.bg.com/pinkish.gif"]}},
   },
    declaration-list => {input => 'background:URL(http://www.bg.com/pinkish.gif',
                         ast => Mu,
                         warnings => ["no closing ')'",
                                      'dropping term: URL(http://www.bg.com/pinkish.gif',
                                      'dropping declaration: background',
                             ],
    },
    declaration-list => {input => 'background:URL("http://www.bg.com/pinkish.gif',
                         ast => Mu,
                         warnings => ["no closing ')'", q{dropping term: URL("http://www.bg.com/pinkish.gif}, q{dropping declaration: background}],
    },
    ruleset =>  {input => 'h1 { color: red; rotation: 70minutes }',
                 warnings => ['dropping term: 70minutes',
                              'dropping declaration: rotation'],
                 ast => {"selectors" => ["selector" => ["simple-selector" => [qname => {"element-name" => "h1"}]]],
                 "declarations" => {"color" =>"expr" => ["term" => "red"]}},
    },
    # unclosed parens
    ruleset => {input => 'h1 {kept1:1; color: dropped1 rgb(10,20,30 dropped2; kept2:2;}',
                warnings => ["no closing ')'",
                             'dropping term: rgb(10,20,30 dropped2',
                             'dropping declaration: color'],
                ast => {"selectors" => ["selector" => ["simple-selector" => [qname => {"element-name" => "h1"}]]],
                        "declarations" => {"kept1" => {"expr" => ["term" => 1]},
                                           "kept2" => {"expr" => ["term" => 2]}}
                        },
                
    },
    ruleset => {input => 'h1 {color:red; content:"Section" counter(hdr-1)}',
                ast => {
                    "selectors" => ["selector" => ["simple-selector" => [qname => {"element-name" => "h1"}]]],
                    "declarations" => {"color" => {"expr" => ["term" => "red"]},
                                       "content" => {"expr" => ["term" => "Section", "term" => {"function" => "counter", "args" => ["term" => 'hdr-1']}]}}
                },
    },
    # unclosed string. scanner should discard first line
    ruleset => {input => 'h2 {bad: dropme "http://unclosed-string.org; color:blue;
                              background-color:#ccc;}',
                ast => {"selectors" => ["selector" => ["simple-selector" => [qname => {"element-name" => "h2"}]]],
                        "declarations" => {"background-color" => {"expr" => ["term" => {"r" => 204, "g" => 204, "b" => 204}]}}},
                warnings => [
                    'unterminated string: "http://unclosed-string.org; color:blue;',
                    'dropping declaration: bad',
                    ],
    },
    ruleset => {input => 'p { color:rgb(10,17); }',
                ast => Mu,
                warnings => ['usage: rgb(c,c,c) where c is 0..255 or 0%-100%',
                             'dropping declaration: color'],
    },
    ruleset => {input => 'p:foo(42) { color:bar(); }',
                ast => Mu,
                warnings => ['unknown pseudo-function: foo'],
    },
    ruleset => {input => 'p { color }',                # malformed declaration missing ':', value
                ast => Mu,
                warnings => 'dropping term: color',
    },
    ruleset => {input => 'p { term1:a; color; term2:b }',   # same with expected recovery
                ast => Mu,
                warnings => 'dropping term: color',
    },
    ruleset => {input => 'p {term1:a; color: }',               # malformed declaration missing value
                ast => Mu,
                warnings => 'dropping declaration: color',
    },
    ruleset => {input => 'p { term1:a; color:; term2:b }',  # same with expected recovery
                 ast => Mu, warnings => 'dropping declaration: color',
    },
    ruleset => {input => 'p { term1:a; color{;color:maroon} }', # unexpected tokens { }
                 ast => Mu, warnings => 'dropping term: color{;color:maroon}',
    },
    ruleset => {input => 'p { term1:a; color{;color:maroon}; color:green }',  # same with recovery
                ast => Mu, warnings => Mu,
                warnings => 'dropping term: color{;color:maroon}',
    },
    stylesheet => {input => 'p @here {color: red}',  # ruleset with unexpected at-keyword "@here"
                ast => Mu, warnings => 'dropping: p @here {color: red}',
    },
    stylesheet => {input => '@foo @bar;',            # at-rule with unexpected at-keyword "@bar"
                   ast => Mu, warnings => Mu,
                   warnings => 'dropping: @foo @bar;',
    },
    stylesheet => {input => '}} {{ - }}',
                   ast => Mu,
                   warnings => ['dropping: }', 'dropping: }', 'dropping: {{ - }}'],
    },
    # example from http://www.w3.org/TR/2003/WD-css3-syntax-20030813/#rule-sets
    # the middle rule is invalid and should be skipped
    stylesheet => {input => 'h1, h2 {color: green }
h3, h4 & h5 {color: red }
h6 {color: black }',
            warnings => 'dropping: h3, h4 & h5 {color: red }',
                   ast => ["ruleset" => {"selectors" => ["selector" => ["simple-selector" => [qname => {"element-name" => "h1"}]],
                                                         "selector" => ["simple-selector" => [qname => {"element-name" => "h2"}]]],
                                         "declarations" => {"color" => {"expr" => ["term" => "green"]}},
                                         "ruleset" => {"selectors" => ["selector" => ["simple-selector" => [qname => {"element-name" => "h6"}]]],
                                                       "declarations" => {"color" => {"expr" => ["term" => "black"]}}}
                           }
                       ],
    },
    stylesheet => {input => '@three-dee {
      @background-lighting {
        azimuth: 30deg;
        elevation: 190deg;
      }
      h1 { color: red }
    }
    h1 { color: blue }',
                   warnings => 'dropping: @three-dee { @background-lighting { azimuth: 30deg; elevation: 190deg; } h1 { color: red } }',
                   ast => ["ruleset" => {"selectors" => ["selector" => ["simple-selector" => [qname => {"element-name" => "h1"}]]],
                                         "declarations" => {"color" => {"expr" => ["term" => "blue"]}}}],
    },
    # try a few extended terms. we don't have the media extensions loaded
    stylesheet => {input => '@media print and (width: 21cm)  { @page { margin: 3cm; @top-center { content: "Page " counter(page); }}}',
                   ast => [],
                   warnings => 'dropping: @media print and (width: 21cm) { @page { margin: 3cm; @top-center { content: "Page " counter(page); }}}',
    },
    stylesheet => {input => '* foo|* |h1 body:not(.home) h2 + p:first-letter tr:nth-last-child(-n+2) object[type^="image/"] {}',
                   ast => [],
                   warnings => 'dropping: * foo|* |h1 body:not(.home) h2 + p:first-letter tr:nth-last-child(-n+2) object[type^="image/"] {}',
    },
    ) {
    my $rule = .key;
    my %test = .value;
    my $input = %test<input>;

    $css_actions.reset;
    my $p3 = CSS::Grammar::CSS3.parse( $input, :rule($rule), :actions($css_actions));
    t::AST::parse_tests($input, $p3, :rule($rule), :suite('css3 errors'),
                         :warnings($css_actions.warnings),
                         :expected(%test) );
}

done;
