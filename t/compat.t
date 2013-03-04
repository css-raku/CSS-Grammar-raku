#!/usr/bin/env perl6

# general compatibility tests
# -- css1 is a subset of css2.1 and sometimes parses differently
# -- css3 without extensions should be largley css2.1 compatibile
# -- css3 with extensions enabled should be able to parse css2.1
#    input and produce compatible ASTs (to ensures a smooth transition
#    when installing extension modules).

use Test;

use CSS::Grammar::CSS1;
use CSS::Grammar::CSS21;
use CSS::Grammar::CSS3;
use CSS::Grammar::CSS3::Extended; # all extensions enabled
use CSS::Grammar::Actions;

use lib '.';
use t::CSS;

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
    string => {input => '"Hello World\\021"',
               ast => 'Hello World!',
               skip => False,
    },
    string => {input => '"Hello Black H',
               ast => 'Hello Black H',
               warnings => ['unterminated string'],
               skip => True,
    },
    num => {input => '2.52', ast => 2.52},
    id => {input => '#z0y\021', ast => 'z0y!'},
    percentage => {input => '50%', ast => 50, units => '%'},
    freq => {input => '50hz', ast => '50'},
    # number, percent, length, emx, emx, angle, time, freq
    expr => {input => '42 7% 12.5cm -1 em 2 ex 45deg 10s 50Hz "ZZ"',
             ast => [term => {num => 42}, term => {percentage => 7},
                     term => {length => 12.5}, term => {num => 1},
                     term => {emx => "em"}, term => {num => 2},
                     term => {emx => "ex"}, term => {angle => 45},
                     term => {time => 10}, term => {freq => 50},
                     term => {string => 'ZZ'}],
             css1 => {
                 warnings => 'skipping term: 45deg 10s 50Hz "ZZ"',
                 ast => [term => {num => 42}, term => {percentage => 7},
                         term => {length => 12.5}, term => {num => 1},
                         term => {emx => "em"}, term => {num => 2},
                         term => {emx => "ex"}],
             },
    },
    class => {input => '.zippy', ast => 'zippy'},
    class => {input => '.\55ft', ast => "\x[55f]t"},
    length => {input => '2.52cm', ast => 2.52, units => 'cm'},
    url => {input => 'url("http://www.bg.com/pinkish.gif")',
            ast => 'http://www.bg.com/pinkish.gif',
    },
    url => {input => 'URL(http://www.bg.com/pinkish.gif)',
            ast => 'http://www.bg.com/pinkish.gif',
    },
    url => {input => 'URL(http://www.bg.com/pinkish.gif',
            ast => 'http://www.bg.com/pinkish.gif',
            warnings => ["missing closing ')'"],
            skip => False,
    },
    url => {input => 'URL("http://www.bg.com/pinkish.gif',
            ast => 'http://www.bg.com/pinkish.gif',
            warnings => ['unterminated string', "missing closing ')'"],
            skip => True,
    },
    color_rgb => {input => 'Rgb(10, 20, 30)',
                  ast => {r => 10, g => 20, b => 30}},
    pseudo => {input => ':visited', ast => {class => 'visited'}},
    pseudo => {input => ':lang(fr-ca)',
               ast => {lang => 'fr-ca'},
               css1 => {  # not understood by css1
                   parse => ':lang',
                   ast => {class => 'lang'},
               },
    },
    import => {input => "@import url('file:///etc/passwd');",
               ast => {url => 'file:///etc/passwd'}},
    import => {input => "@IMPORT '/etc/group';",
               ast => {string => '/etc/group'}},
    class => {input => '.class', ast => 'class'},
    simple_selector => {input => 'BODY',
                        ast => {element_name => 'BODY'},},
    selector => {input => 'A:Visited',
                 ast => {"simple_selector"
                             => {"element_name" => "A",
                                 "pseudo" => {"class" => "Visited"}}},
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
                        ast => {"element_name" => "BODY",
                                "class" => "some_class"},
                        css1 => {parse => 'BODY.some',
                                 ast => {"element_name" => "BODY",
                                         "class" => "some"}},
    },
    pseudo => {input => ':first-line',
               ast => {class => 'first-line'},
               css1 => {ast => {element => 'first-line'}},
    },
    selector => {input => 'BODY.some-class:active',
                 ast => {"simple_selector"
                             => {"element_name" => "BODY",
                                 "class" => "some-class",
                                 "pseudo" => {"class" => "active"}}},
    },
    # Test for whitespace sensitivity in selectors
    selector => {input => '#my-id /* white-space */ :first-line',
                 css1 => {
                     ast => [
                         "simple_selector" => {"id" => "my-id"},
                         "simple_selector" => {"pseudo" => {"element" => "first-line"}}]
                 },
                         ast => [
                             "simple_selector" => {"id" => "my-id"},
                             "simple_selector" => {"pseudo" => {"class" => "first-line"}}]
    },
    selector => {input => '#my-id:first-line',
                 css1 => {ast => ["simple_selector" => {"id" => "my-id", "pseudo" => {"element" => "first-line"}}]},
                 ast => ["simple_selector" => {"id" => "my-id", "pseudo" => {"class" => "first-line"}}],
    },
    selector => {input => '#my-id+:first-line',
                 css1 => {ast => Mu},
                 ast => ["simple_selector" => {"id" => "my-id"},
                         "combinator" => "+",
                         "simple_selector" => {"pseudo" => {"class" => "first-line"}}],
                 css1 => {parse => '#my-id',
                          ast => ["simple_selector" => {"id" => "my-id"}]},
    },
    # css1 doesn't understand '+' combinator
    selector => {input => '#my-id + :first-line',
                 css1 => {ast => Mu},
                 ast => ["simple_selector" => {"id" => "my-id"},
                         "combinator" => "+",
                         "simple_selector" => {"pseudo" => {"class" => "first-line"}}],
                 css1 => {parse => '#my-id',
                          ast => ["simple_selector" => {"id" => "my-id"}]},
    },
    selector => {input => 'A:first-letter',
                 css1 => {ast => Mu},
                 ast => ["simple_selector" => {"element_name" => "A",
                                               "pseudo" => {"class" => "first-letter"}}],
    },
    selector => {input => 'A:Link IMG',
                 ast => ["simple_selector" => {"element_name" => "A",
                                               "pseudo" => {"class" => "Link"}},
                         "simple_selector" => {"element_name" => "IMG"}],
    },
    selector => {input => 'A:After IMG',
                 ast => ["simple_selector" => {"element_name" => "A",
                                               "pseudo" => {"class" => "After"}},
                         "simple_selector" => {"element_name" => "IMG"}],
    },
    term => {input => '#eeeeee', ast => {id => 'eeeeee'},
    },
    term => {input => 'rgb(17%, 33%, 70%)',
             ast => {color_rgb => {r => 17, g => 33, b => 70}},
    },
    term => {input => 'rgb(17%, 33%, 70%',
             warnings => ["missing closing ')'"],
             ast => {color_rgb => {r => 17, g => 33, b => 70}},
    },
    num => {input => '1',ast => 1},
    num => {input => '.1', ast => .1 },
    num => {input => '1.9', ast => 1.9},
    term => {input => '1cm', ast => {length => 1}},
    term => {input => 'em', ast => {emx => 'em'}},
    term => {input => '01.10', ast => {num => 1.1}},
    # function without arguments, e.g. jquery-ui-themeroller.css
    term => {input => 'mask()',
             ast => {"function" => {"ident" => "mask"}},
             css1 => {
                 parse => 'mask',
                 ast => {ident => 'mask'},
             },
    },
    expr => {input => 'RGB(70,133,200 ), #fff',
             ast => ["term" => {color_rgb => {"r" => 70, "g" => 133, "b" => 200}},
                     "operator" => ",",
                     "term" => {id => "fff"}],
    },
    expr => {input => "'Helvetica Neue',helvetica-neue, helvetica",
             ast => ["term" => {string => "Helvetica Neue"}, "operator" => ",",
                     "term" => {ident => "helvetica-neue"}, "operator" => ",",
                     "term" => {ident => "helvetica"}],
    },
    expr => {input => '13mm EM', ast => ["term" => {length => 13}, "term" => {emx => "em"}]},
    expr => {input => '-1CM', ast => [term => {length => 1}]},
    expr => {input => '2px solid blue',
             ast => ["term" => {length => 2}, "term" => {ident => "solid"}, "term" => {ident => "blue"}],
    },
    # CSS21  Expressions
    expr => {input => 'top,ccc/dddd',
             ast => ["term" => {ident => "top"}, "operator" => ",",
                     "term" => {ident =>'ccc'}, "operator" => '/',
                     "term" => {ident => 'dddd'}],
    },
    expr => {input => '-moz-linear-gradient',
             ast => ["term" => {ident => "-moz-linear-gradient"}],
             # css1 treats leading '-' as an operator
             css1 => {ast => ["term" => {ident => 'moz-linear-gradient'}]},
    },
    # css2 understands some functions
    expr => {input => '-moz-linear-gradient(top, t2, t3)',
             ast =>  ["term"
                      => {function => {"ident" => "-moz-linear-gradient",
                                       "expr" => ["term" => {ident => "top"},
                                                  "operator" => ",",
                                                  "term" => {ident => "t2"},
                                                  "operator" => ",",
                                                  "term" => {ident => "t3"}]}}
                 ],
             css1 => {warnings => ['skipping term: (top, t2, t3)'],
                      ast => ["term" => {ident => "moz-linear-gradient"}],
             },
    },
    expr => {input => '12px/20px',
             ast => ["term" => {length => 12}, "operator" => "/", "term" => {length => 20}],
    },
    declaration => {input => 'line-height: 1.1px !important',
                    ast => {"property" => {"ident" => "line-height"},
                            "expr" => ["term" => {length => 1.1}],
                            "prio" => "important"},
    },
    declaration => {input => 'line-height: 1.5px !vital',
                    warnings => ['skipping term: vital'],
                    ast => {"property" => {"ident" => "line-height"},
                            "expr" => ["term" => {length => 1.5}]},
    },
    declaration => {input => 'margin: 1em',
                    ast => {"property" => {"ident" => "margin"},
                            "expr" => ["term" => {length => 1}]},
    },
    declaration => {input => 'border: 2px solid blue',
                    ast => {"property" => {"ident" => "border"},
                            "expr" => ["term" => {length => 2},
                                       "term" => {ident => "solid"},
                                       "term" => {ident => "blue"}]},
    },
    ruleset => {input => 'H1 { color: blue; }',
                ast => {"selectors" => ["selector" => ["simple_selector" => {"element_name" => "H1"}]],
                        "declarations" => ["declaration" => {"property" => {"ident" => "color"}, "expr" => ["term" => {ident => "blue"}]}]},
    },
    ruleset => {input => 'A:link H1 { color: blue; }',
                ast => {"selectors" => ["selector" => ["simple_selector" => {"element_name" => "A", "pseudo" => {"class" => "link"}},
                                                       "simple_selector" => {"element_name" => "H1"}]],
                        "declarations" => ["declaration" => {"property" => {"ident" => "color"}, "expr" => ["term" => {ident => "blue"}]}]},
    },
    ruleset => {input => 'A:link,H1 { color: blue; }',
                ast => {"selectors" => ["selector" => ["simple_selector" => {"element_name" => "A", "pseudo" => {"class" => "link"}}],
                                        "selector" => ["simple_selector" => {"element_name" => "H1"}]],
                        "declarations" => ["declaration" => {"property" => {"ident" => "color"}, "expr" => ["term" => {ident => "blue"}]}]},
    },
    ruleset => {input => 'H1#abc { color: blue; }',
                ast => {"selectors" => ["selector" => ["simple_selector" => {"element_name" => "H1", "id" => "abc"}]],
                        "declarations" => ["declaration" => {"property" => {"ident" => "color"}, "expr" => ["term" => {ident => "blue"}]}]},
    },
    ruleset => {input => 'A.external:visited { color: blue; }',
                ast => {"selectors" => ["selector" => ["simple_selector" => {"element_name" => "A", "class" => "external", "pseudo" => {"class" => "visited"}}]],
                        "declarations" => ["declaration" => {"property" => {"ident" => "color"}, "expr" => ["term" => {ident => "blue"}]}]},
    },
    dimension => {input => '70deg', ast => 70, units => 'deg'},
    simple_selector => {input => 'A[ href ]',
                        ast => {"element_name" => "A", "attrib" => {"ident" => "href"}},
                        css1 => {
                            parse => 'A', ast => {"element_name" => "A"},
                        },
    },
    simple_selector => {input => 'a[href~="foo"]',
                        ast => {"element_name" => "a", "attrib" => {"ident" => "href", "attribute_selector" => "~=", "string" => "foo"}},
                        css1 => {
                            parse => 'a', ast => {"element_name" => "a"},
                        },
    },
    # character set differences:
    # \255 is not recognised by css1 or css2 as non-ascii chars
    ruleset => {input => ".TB	\{mso-special-format:nobullet\x[95];\}",
                ast => {"selectors" => ["selector" => ["simple_selector" => {"class" => "TB"}]],
                        "declarations" => ["declaration" => {"property" => {"ident" => "mso-special-format"}, "expr" => ["term" => {ident => "nobullet"}]}]},
                warnings => 'skipping term: \\x[95]',
                css3 => {
                    warnings => Mu,
                    ast => {"selectors" => ["selector" => ["simple_selector" => {"class" => "TB"}]],
                            "declarations" => ["declaration" => {"property" => {"ident" => "mso-special-format"}, "expr" => ["term" => {ident => "nobullet\x[95]"}]}]},
                },
    },
    ruleset => {input => 'H2 { color: green; rotation: 70deg; }',
                ast => {"selectors" => ["selector" => ["simple_selector" => {"element_name" => "H2"}]],
                        "declarations" => ["declaration" => {"property" => {"ident" => "color"}, "expr" => ["term" => {ident => "green"}]}, "declaration" => {"property" => {"ident" => "rotation"}, "expr" => ["term" => {angle => 70}]}]},
                css1 => {
                    warnings => ['skipping term: 70deg'],
                    ast => {"selectors" => ["selector" => ["simple_selector" => {"element_name" => "H2"}]],
                            "declarations" => ["declaration" => {"property" => {"ident" => "color"}, "expr" => ["term" => {ident => "green"}]}, "declaration" => {"property" => {"ident" => "rotation"}, "expr" => []}]},
                },
    },
    ruleset => {input => 'H1 { color }',
                warnings => ['skipping term: color '],
                ast => Mu,
    },
    ruleset => {input => 'H1 { color; }',
                warnings => ['skipping term: color'],
                ast => Mu,
    },
    ruleset => {input => 'H1 { color: }',
                warnings => ['incomplete declaration'],
                ast => Mu,
    },
    ruleset => {input => 'H1 { : blue }',
                warnings => ['skipping term: : blue '],
                ast => Mu,
    },
    ruleset => {input => 'H1 { color blue }',
                warnings => ['skipping term: color blue '],
                ast => Mu,
    },

    # unclosed rulesets
    ruleset => {input => 'H2 { color: green; rotation: 70deg;',
                warnings => ["no closing '}'"],
                ast => Mu,
                css1 => {
                    warnings => ['skipping term: 70deg',
                                 "no closing '}'",
                        ]
                }
    },
    ruleset => {input => 'H2 { color: green; rotation: }',
                warnings => "incomplete declaration",
                ast => Mu,
    },

    ruleset => {input => 'H2 { test: "this is not closed',
                warnings => [
                    'unterminated string',
                    "no closing '}'",
                    ],
                ast => Mu,
    },
    at_rule => {input => '@media print {body{margin: 1cm}}',
                ast => {"media_list" => ["media_query" => ["media" => "print"]], "media_rules" => ["ruleset" => {"selectors" => ["selector" => ["simple_selector" => ["element_name" => "body"]]], "declarations" => ["declaration" => {"property" => {"ident" => "margin"}, "expr" => ["term" => {"length" => 1}]}]}]},
                css1 => {skip_test => True},
                # haven't managed to keep @media compatible
    },
    at_rule => {input => '@page :first { margin-right: 2cm }',
                ast => {"page" => "first", "declarations" => ["declaration" => {"property" => {"ident" => "margin-right"}, "expr" => ["term" => {"length" => 2}]}]},
                css1 => {skip_test => True},
    },

    # from the top
    TOP => {input => "@charset 'bazinga';\n",
            ast => Mu,
            css2 => {
                ast => [charset => "bazinga"],
            },
            css1 => {
                warnings => [q{skipping: @charset }, q{skipping: 'bazinga'}, q{skipping: ;} ]
            },
    },
    TOP => {input => "\@import 'foo';\nH1 \{ color: blue; \};\n@charset 'bazinga';\n\@import 'too-late';\nH2\{color:green\}",
            ast => ["import" => {"string" => "foo"},
                    "ruleset" => {"selectors" => ["selector" => ["simple_selector" => {"element_name" => "H1"}]],
                                  "declarations" => ["declaration" => {"property" => {"ident" => "color"}, "expr" => ["term" => {ident => "blue"}]}]},
                    "ruleset" => {"selectors" => ["selector" => ["simple_selector" => {"element_name" => "H2"}]],
                                  "declarations" => ["declaration" => {"property" => {"ident" => "color"}, "expr" => ["term" => {ident => "green"}]}]}],
            warnings => [
                q{ignoring out of sequence directive: @charset 'bazinga';},
                q{ignoring out of sequence directive: @import 'too-late';},
                ],
                css1 => {
                    warnings => [
                        q{skipping: @charset }, q{skipping: 'bazinga'}, q{skipping: ;},
                        q{ignoring out of sequence directive: @import 'too-late';},
                        ],
            },
    },
    ) {

    my $rule = $_.key;
    my %test = $_.value;
    my $input = %test<input>;

    $css_actions.warnings = ();
    my $css1 = %test<css1> // {};
    my $css2 = %test<css2> // {};
    my $css3 = %test<css3> // {};
    my $css3p = %test{'css3+'} // {};

    # CSS1 Compat
    unless %$css1<skip_test> {
        $css_actions.warnings = ();
        my $p1 = CSS::Grammar::CSS1.parse( $input, :rule($rule), :actions($css_actions));
        t::CSS::parse_tests($input, $p1, :rule($rule), :compat('css1'),
                            :warnings($css_actions.warnings),
                            :expected( %(%test, %$css1)) );
    }
        
    # CSS21 Compat
    $css_actions.warnings = ();
    my $p2 = CSS::Grammar::CSS21.parse( $input, :rule($rule), :actions($css_actions));
    t::CSS::parse_tests($input, $p2, :rule($rule), :compat('css2'),
                         :warnings($css_actions.warnings),
                         :expected( %(%test, %$css2)) );

    # CSS3 Compat
    # -- css3 core only
    $css_actions.warnings = ();
    my $p3 = CSS::Grammar::CSS3.parse( $input, :rule($rule), :actions($css_actions));
    t::CSS::parse_tests($input, $p3, :rule($rule), :compat('css3'),
                         :warnings($css_actions.warnings),
                         :expected( %(%test, %$css3)) );

    # -- css3 with all extensions enabled
    $css_extended_actions.warnings = ();
    my $p3ext = CSS::Grammar::CSS3::Extended.parse( $input, :rule($rule), :actions($css_extended_actions));
    t::CSS::parse_tests($input, $p3ext, :rule($rule), :compat('css3-ext'),
                        :warnings($css_extended_actions.warnings),
                        :expected( %(%test, %$css3)) );
}

done;
