#!/usr/bin/env perl6

# general compatibility tests
# -- css1 is a subset of css2.1 and sometimes parses differently
# -- css3 without extensions should be largley css2.1 compatibile
# -- css3 with extensions enabled should be able to parse css2.1
#    input and produce compatible ASTs (to ensures a smooth transition
#    when enabling extension modules).

use Test;

use CSS::Grammar::CSS1;
use CSS::Grammar::CSS21;
use CSS::Grammar::CSS3;
use CSS::Grammar::CSS3::Extended; # all extensions enabled
use CSS::Grammar::Actions;

use lib '.';
use t::AST;

my $css_actions = CSS::Grammar::Actions.new;
my $css_extended_actions = CSS::Grammar::CSS3::Extended::Actions.new;

for (
    ws => {input => ' '},
    ws => {input => "/* comments\n1 */"},
    ws => {input => "<!-- comments\n2 -->"},
    ws => {input => "<!-- unterminated comment",
           warnings => ['unclosed comment at end of input'],
    },
    ws => {input => "/* unterminated\nstar\ncomment ... ",
           warnings => ['unclosed comment at end of input'],
    },
    name => {input => 'my-class', ast => 'my-class'},
    unicode => {input => '\\021',
                ast => '!',
    },
    url_string => {input => q{"'Hello World\\021\\""},
                   ast => q{'Hello World!"},
    },
    num => {input => '2.52', ast => 2.52},
    id => {input => '#z0y\021', ast => 'z0y!'},
    # number, percent, length, emx, emx, angle, time, freq
    class => {input => '.zippy', ast => 'zippy'},
    class => {input => '.\55ft', ast => "\x[55f]t"},
    color => {input => 'Rgb(10, 20, 30)',
              ast => (rgb => {r => 10, g => 20, b => 30})},
    pseudo => {input => ':visited', ast => {class => 'visited'}},
    pseudo => {input => ':Lang(fr-ca)',
               ast => {"function" => {"ident" => "lang", "args" => [ident => "fr-ca"]}},
               css1 => {  # not understood by css1
                   parse => ':Lang',
                   ast => {class => 'lang'},
               },
    },
    import => {input => "@import url('file:///etc/passwd');",
               ast => {url => 'file:///etc/passwd'}},
    import => {input => "@IMPORT '/etc/group';",
               ast => {string => '/etc/group'}},
    # imports can be assigned to media types. See:
    # http://www.w3.org/TR/2011/REC-CSS2-20110607/cascade.html#at-import
    import => {input => '@import url("bluish.css") projection, tv;',
               ast => {url => "bluish.css",
                       "media_list" => ["media_query" => ["media" => "projection"],
                                        "media_query" => ["media" => "tv"]]},
               css1 => {
                   parse => '',
                   ast => Mu,
               },
    },
    class => {input => '.class', ast => 'class'},
    simple_selector => {input => 'BODY',
                        ast => {element_name => 'body'},},
    selector => {input => 'A:Visited',
                 ast => {"simple_selector"
                             => {"element_name" => "a",
                                 "pseudo" => {"class" => "visited"}}},
    },
    selector => {input => ':visited',
                 ast => {"simple_selector"
                             => {pseudo => {class => "visited"}}},
    },
    # Note: CSS1 doesn't allow '_' in names or identifiers
    selector => {input => '.some_class',
                 ast => {simple_selector => {class => 'some_class'}},
                 css1 => {parse => '.some',
                          ast => {simple_selector => {class => 'some'}}},
    },
    selector => {input => '.some_class:link',
                 ast => {"simple_selector"
                             => {"class" => "some_class",
                                 "pseudo" => {"class" => "link"}}},
                     css1 => {parse => '.some',
                              ast => {"simple_selector"
                                          => {"class" => "some"}}},
    },
    simple_selector => {input => 'BODY.some_class',
                        ast => {"element_name" => "body",
                                "class" => "some_class"},
                        css1 => {parse => 'BODY.some',
                                 ast => {"element_name" => "body",
                                         "class" => "some"}},
    },
    pseudo => {input => ':first-line',
               ast => {element => 'first-line'},
    },
    selector => {input => 'BODY.some-class:active',
                 ast => {"simple_selector"
                             => {"element_name" => "body",
                                 "class" => "some-class",
                                 "pseudo" => {"class" => "active"}}},
    },
    # Test for whitespace sensitivity in selectors
    selector => {input => '#my-id /* white-space */ :first-line',
                 ast => [
                     "simple_selector" => {"id" => "my-id"},
                     "simple_selector" => {"pseudo" => {"element" => "first-line"}}],
    },
    selector => {input => '#my-id:first-line',
                 ast => ["simple_selector" => {"id" => "my-id", "pseudo" => {"element" => "first-line"}}],
    },
    selector => {input => '#my-id+:first-line',
                 css1 => {ast => Mu},
                 ast => ["simple_selector" => {"id" => "my-id"},
                         "combinator" => "+",
                         "simple_selector" => {"pseudo" => {"element" => "first-line"}}],
                 css1 => {parse => '#my-id',
                          ast => ["simple_selector" => {"id" => "my-id"}]},
    },
    # css1 doesn't understand '+' combinator
    selector => {input => '#my-id + :first-line',
                 css1 => {ast => Mu},
                 ast => ["simple_selector" => {"id" => "my-id"},
                         "combinator" => "+",
                         "simple_selector" => {"pseudo" => {"element" => "first-line"}}],
                 css1 => {parse => '#my-id',
                          ast => ["simple_selector" => {"id" => "my-id"}]},
    },
    # '>' combinator also introduced with css2.1
    selector => {input => 'ol > li:first-child + li +li+ li+li',
                 ast => ["simple_selector" => ["element_name" => "ol"],
                         "combinator" => ">",
                         "simple_selector" => ["element_name" => "li", "pseudo" => {"class" => "first-child"}],
                         "combinator" => "+",
                         "simple_selector" => ["element_name" => "li"],
                         "combinator" => "+",
                         "simple_selector" => ["element_name" => "li"],
                         "combinator" => "+",
                         "simple_selector" => ["element_name" => "li"],
                         "combinator" => "+",
                         "simple_selector" => ["element_name" => "li"],
                    ],
                 css1 => {
                     parse => 'ol',
                     ast => ["simple_selector" => ["element_name" => "ol"]],
                 },
    },
    selector => {input => 'A:first-letter',
                 ast => ["simple_selector" => {"element_name" => "a",
                                               "pseudo" => {"element" => "first-letter"}}],
    },
    selector => {input => 'A:Link IMG',
                 ast => ["simple_selector" => {"element_name" => "a",
                                               "pseudo" => {"class" => "link"}},
                         "simple_selector" => {"element_name" => "img"}],
    },
    selector => {input => 'A:After IMG',
                 css1 => {  # css1 doesn't understand :after element
                      ast => ["simple_selector" => {"element_name" => "a",
                                               "pseudo" => {"class" => "after"}},
                         "simple_selector" => {"element_name" => "img"}],
                 },
                 ast => ["simple_selector" => {"element_name" => "a",
                                               "pseudo" => {"element" => "after"}},
                         "simple_selector" => {"element_name" => "img"}],
    },
    num => {input => '1',ast => 1},
    num => {input => '.1', ast => .1 },
    num => {input => '1.9', ast => 1.9},
    expr => {input => 'RGB(70,133,200 ), #fa7',
             ast => ["term" => {"r" => 70, "g" => 133, "b" => 200},
                     "operator" => ",",
                     "term" => {"r" => 0xFF, "g" => 0xAA, "b" => 0x77}],
    },
    expr => {input => "'Helvetica Neue',helvetica-neue, helvetica",
             ast => ["term" => "Helvetica Neue", "operator" => ",",
                     "term" => "helvetica-neue", "operator" => ",",
                     "term" => "helvetica"],
    },
    expr => {input => '+13mm EM', ast => ["term" => 13, "term" => 1]},
    expr => {input => '-1CM', ast => [term => -1]},
    expr => {input => '2px solid blue',
             ast => ["term" => 2, "term" => "solid", "term" => "blue"],
    },
    # CSS21  Expressions
    expr => {input => 'top,ccc/dddd',
             ast => ["term" => 'top', "operator" => ",",
                     "term" => 'ccc', "operator" => '/',
                     "term" => 'dddd'],
    },
    expr => {input => '-moz-linear-gradient',
             ast => ["term" => "-moz-linear-gradient"],
             # css1 treats leading '-' as an operator
             css1 => {ast => ["term" => 'moz-linear-gradient']},
    },
    # css2 understands some functions
    expr => {input => '-moz-linear-gradient(top, t2, t3)',
             ast => Mu,
             warnings => 'unknown function: -moz-linear-gradient',

             css1 => {
                 ast => Mu,
                 parse => '-moz-linear-gradient',
                 warnings => Mu,
             },
    },
    expr => {input => '12px/20px',
             ast => ["term" => 12, "operator" => "/", "term" => 20],
    },
    declaration_list => {input => 'terms: 42 7% 12.5cm -1em 2 ex 45deg 10s 50Hz "ZZ" counter(a,b) counters(p,"s") attr(data-foo)',
                         ast => [declaration => {
                             property => 'terms',
                             expr => [term => 42, term => 7,
                                      term => 12.5, term => -1,
                                      term => 2, term => 1,
                                      term => 45,
                                      term => 10, term => 50,
                                      term => 'ZZ',
                                      term => {"ident" => "counter", "args" => ["ident" => "a", ident => "b"]},
                                      term => {"ident" => "counters", "args" => ["ident" => "p", string => "s"]},
                                      term => {"ident" => "attr", "args" => ["attribute_name" => "data-foo"]},
                                 ]
                                 }],
                         css1 => {
                             warnings => ['dropping term: 45deg 10s 50Hz "ZZ" counter(a,b) counters(p,"s") attr(data-foo)',
                                          'dropping declaration: terms',],
                             ast => Mu,
                     },
    },
    declaration => {input => 'line-height: 1.1px !important',
                    ast => {"property" => "line-height",
                            "expr" => ["term" => 1.1],
                            "prio" => "important"},
    },
    declaration => {input => 'line-height: 1.5px !vital',
                    warnings => ['dropping term: !vital'],
                    ast => {"property" => "line-height",
                            "expr" => ["term" => 1.5]},
    },
    declaration => {input => 'margin: 1em',
                    ast => {"property" => "margin",
                            "expr" => ["term" => 1]},
    },
    declaration => {input => 'border: 2px solid blue',
                    ast => {"property" => "border",
                            "expr" => ["term" => 2,
                                       "term" => "solid",
                                       "term" => "blue"]},
    },
    declaration_list => {input => 'font-size:0px;color:white;z-index:-9;position:absolute;left:-999px',
                         ast => ["declaration" => {"property" => "font-size", "expr" => ["term" => 0]},
                                 "declaration" => {"property" => "color", "expr" => ["term" => "white"]},
                                 "declaration" => {"property" => "z-index", "expr" => ["term" => -9]},
                                 "declaration" => {"property" => "position", "expr" => ["term" => "absolute"]},
                                 "declaration" => {"property" => "left", "expr" => ["term" => -999]}],
    },
    ruleset => {input => 'H1 { color: blue; }',
                ast => {"selectors" => ["selector" => ["simple_selector" => {"element_name" => "h1"}]],
                        "declarations" => ["declaration" => {"property" => "color", "expr" => ["term" => "blue"]}]},
    },
    ruleset => {input => 'A:link H1 { color: blue; }',
                ast => {"selectors" => ["selector" => ["simple_selector" => {"element_name" => "a", "pseudo" => {"class" => "link"}},
                                                       "simple_selector" => {"element_name" => "h1"}]],
                        "declarations" => ["declaration" => {"property" => "color", "expr" => ["term" => 'blue']}]},
    },
    ruleset => {input => 'A:link,H1 { color: blue; }',
                ast => {"selectors" => ["selector" => ["simple_selector" => {"element_name" => "a", "pseudo" => {"class" => "link"}}],
                                        "selector" => ["simple_selector" => {"element_name" => "h1"}]],
                        "declarations" => ["declaration" => {"property" => "color", "expr" => ["term" => 'blue']}]},
    },
    ruleset => {input => 'H1#abc { color: blue; }',
                ast => {"selectors" => ["selector" => ["simple_selector" => {"element_name" => "h1", "id" => "abc"}]],
                        "declarations" => ["declaration" => {"property" => "color", "expr" => ["term" => 'blue']}]},
    },
    ruleset => {input => 'A.external:visited { color: blue; }',
                ast => {"selectors" => ["selector" => ["simple_selector" => {"element_name" => "a", "class" => "external", "pseudo" => {"class" => "visited"}}]],
                        "declarations" => ["declaration" => {"property" => "color", "expr" => ["term" => 'blue']}]},
    },
    simple_selector => {input => 'A[ href ]',
                        ast => {"element_name" => "a", "attrib" => {"ident" => "href"}},
                        css1 => {
                            parse => 'A', ast => {"element_name" => "a"},
                        },
    },
    simple_selector => {input => 'a[href~="foo"]',
                        ast => {"element_name" => "a", "attrib" => {"ident" => "href", "attribute_selector" => "~=", "string" => "foo"}},
                        css1 => {
                            parse => 'a', ast => {"element_name" => "a"},
                        },
    },
    # character set differences:
    # \255 is not recognised by css1 or css2.1 as non-ascii chars
    ruleset => {input => ".TB	\{mso-special-format:nobullet\x[95];\}",
                ast => {"selectors" => ["selector" => ["simple_selector" => {"class" => "TB"}]],
                        "declarations" => []},
                warnings => ['dropping term: \\x[95]',
                             'dropping declaration: mso-special-format'],
                css3 => {
                    warnings => Mu,
                    ast => {"selectors" => ["selector" => ["simple_selector" => {"class" => "TB"}]],
                            "declarations" => ["declaration" => {"property" => "mso-special-format", "expr" => ["term" => "nobullet\x[95]"]}]},
                },
    },
    ruleset => {input => 'H2 { color: green; rotation: 70deg; }',
                ast => {"selectors" => ["selector" => ["simple_selector" => {"element_name" => "h2"}]],
                        "declarations" => ["declaration" => {"property" => "color", "expr" => ["term" => 'green']},
                                           "declaration" => {"property" => "rotation", "expr" => ["term" => 70]}]},
                css1 => {
                    warnings => ['dropping term: 70deg', 'dropping declaration: rotation'],
                    ast => {"selectors" => ["selector" => ["simple_selector" => {"element_name" => "h2"}]],
                            "declarations" => ["declaration" => {"property" => "color", "expr" => ["term" => 'green']}]},
                },
    },
    ruleset => {input => 'H1 { color }',
                warnings => ['dropping term: color'],
                ast => Mu,
    },
    ruleset => {input => 'H1 { color; }',
                warnings => ['dropping term: color'],
                ast => Mu,
    },
    ruleset => {input => 'H1 { : blue }',
                warnings => ['dropping term: : blue'],
                ast => Mu,
    },
    ruleset => {input => 'H1 { color blue }',
                warnings => ['dropping term: color blue'],
                ast => Mu,
    },
    ruleset => {input => 'H1 { color: }',
                warnings => ['dropping declaration: color'],
                ast => Mu,
    },

    # unclosed rulesets
    ruleset => {input => 'H2 { color: green; rotation: 70deg;',
                warnings => ["no closing '}'"],
                ast => Mu,
                css1 => {
                    # doesn't understand angles
                    warnings => [
                        'dropping term: 70deg',
                        'dropping declaration: rotation',
                        "no closing '}'",
                        ]
                }
    },
    ruleset => {input => 'H2 { color: green; rotation: }',
                warnings => "dropping declaration: rotation",
                ast => Mu,
    },
    ruleset => {input => 'H2 { test: "this is not closed',
                warnings => [
                    q{unterminated string: "this is not closed},
                    'dropping declaration: test',
                    "no closing '}'",
                    ],
                ast => Mu,
    },
    at_rule => {input => 'media print {body{margin: 1cm}}',
                ast => {"media_list" => ["media_query" => ["media" => "print"]],
                        "media_rules" => ["ruleset" => {"selectors" => ["selector" => ["simple_selector" => ["element_name" => "body"]]],
                                                        "declarations" => ["declaration" => {"property" => "margin", "expr" => ["term" => 1]}]}],
                        '@' => 'media'},
                css1 => {skip_test => True},
    },
    at_rule => {input => 'page :first { margin-right: 2cm }',
                ast => {"page" => "first", "declarations" => ["declaration" => {"property" => "margin-right", "expr" => ["term" => 2]}],
                        '@' => 'page'},
                css1 => {skip_test => True},
    },

    # from the top
    stylesheet => {input => "@charset 'bazinga';\n",
                   ast => Mu,
                   css2 => {
                       ast => [charset => "bazinga"],
                   },
                   css1 => {
                       warnings => [q{dropping: @charset 'bazinga';}]
                   },
    },
    stylesheet => {input => "\@import 'foo';\nH1 \{ color: blue; \};\n@charset 'bazinga';\n\@import 'too-late';\nH2\{color:green\}",
                   ast => ["import" => {"string" => "foo"},
                           "ruleset" => {"selectors" => ["selector" => ["simple_selector" => {"element_name" => "h1"}]],
                                         "declarations" => ["declaration" => {"property" => "color", "expr" => ["term" => 'blue']}]},
                           "ruleset" => {"selectors" => ["selector" => ["simple_selector" => {"element_name" => "h2"}]],
                                         "declarations" => ["declaration" => {"property" => "color", "expr" => ["term" => 'green']}]}],
                   warnings => [
                       q{ignoring out of sequence directive: @charset 'bazinga';},
                       q{ignoring out of sequence directive: @import 'too-late';},
                       ],
                       css1 => {
                           warnings => [
                               q{dropping: @charset 'bazinga';},
                               q{ignoring out of sequence directive: @import 'too-late';},
                               ],
                   },
    },
    ) {

    my $rule = $_.key;
    my %test = $_.value;
    my $input = %test<input>;

    $css_actions.reset;
    my $css1 = %test<css1> // {};
    my $css2 = %test<css2> // {};
    my $css3 = %test<css3> // {};

    # CSS1 Compat
    unless %$css1<skip_test> {
        $css_actions.reset;
        my $p1 = CSS::Grammar::CSS1.parse( $input, :rule($rule), :actions($css_actions));
        t::AST::parse_tests($input, $p1, :rule($rule), :suite('css1'),
                            :warnings($css_actions.warnings),
                            :expected( %(%test, %$css1)) );
    }
        
    # CSS21 Compat
    $css_actions.reset;
    my $p2 = CSS::Grammar::CSS21.parse( $input, :rule($rule), :actions($css_actions));
    t::AST::parse_tests($input, $p2, :rule($rule), :suite('css2'),
                         :warnings($css_actions.warnings),
                         :expected( %(%test, %$css2)) );

    # CSS3 Compat
    # -- css3 core only
    $css_actions.reset;
    my $p3 = CSS::Grammar::CSS3.parse( $input, :rule($rule), :actions($css_actions));
    t::AST::parse_tests($input, $p3, :rule($rule), :suite('css3'),
                         :warnings($css_actions.warnings),
                         :expected( %(%test, %$css3)) );

    # -- css3 with all extensions enabled
    $css_extended_actions.reset;
    my $p3ext = CSS::Grammar::CSS3::Extended.parse( $input, :rule($rule), :actions($css_extended_actions));
    t::AST::parse_tests($input, $p3ext, :rule($rule), :suite('css3-ext'),
                        :warnings($css_extended_actions.warnings),
                        :expected( %(%test, %$css3)) );

    # try a general scan

    if ($rule ~~ /^(TOP|statement|at_rule|ruleset|selectors|declaration[s|_list]|property)$/
        && ! $css_extended_actions.warnings) {
        my $p_any = CSS::Grammar::Scan.parse( $input, :rule('_'~$rule) );
        t::AST::parse_tests($input, $p_any, :rule($rule), :suite('any'),
                            :expected({ast => Mu}) );
    }
}

done;
