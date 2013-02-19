#!/usr/bin/env perl6

use Test;

use CSS::Grammar::CSS1;
use CSS::Grammar::CSS21;
use CSS::Grammar::CSS3;
use CSS::Grammar::Actions;

my $css_actions = CSS::Grammar::Actions.new;

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
    class => {input => '.zippy', ast => 'zippy'},
    class => {input => '.\55ft', ast => Buf.new(0x55f).decode('ISO-8859-1')~'t'},
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
            warnings => ["missing closing ')'", 'unterminated string'],
            skip => True,
    },
    rgb => {input => 'Rgb(10, 20, 30)',
            ast => {r => 10, g => 20, b => 30}},
    pseudo => {input => ':visited', ast => {ident => 'visited'}},
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
                                 "pseudo" => {"ident" => "Visited"}}},
    },
    selector => {input => ':visited',
                 ast => {"simple_selector"
                             => {pseudo => {ident => "visited"}}},
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
                                 "pseudo" => {"ident" => "link"}}},
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
    pseudo => {input => ':first-line', ast => {ident => 'first-line'}},
    selector => {input => 'BODY.some-class:active',
                 ast => {"simple_selector"
                             => {"element_name" => "BODY",
                                 "class" => "some-class",
                                 "pseudo" => {"ident" => "active"}}},
    },
    # Test for whitespace sensitivity in selectors
    selector => {input => '#my-id /* white-space */ :first-line',
                 ast => [
                     "simple_selector" => {"id" => "my-id"},
                     "simple_selector" => {"pseudo" => {"ident" => "first-line"}}]
    },
    selector => {input => '#my-id:first-line',
                 ast => ["simple_selector" => {"id" => "my-id", "pseudo" => {"ident" => "first-line"}}],
    },
    selector => {input => '#my-id+:first-line',
                 ast => ["simple_selector" => {"id" => "my-id"},
                         "combinator" => "+",
                         "simple_selector" => {"pseudo" => {"ident" => "first-line"}}],
                 css1 => {parse => '#my-id',
                          ast => ["simple_selector" => {"id" => "my-id"}]},
    },
    # css1 doesn't understand '+' combinator
    selector => {input => '#my-id + :first-line',
                 ast => ["simple_selector" => {"id" => "my-id"},
                                  "combinator" => "+",
                                  "simple_selector" => {"pseudo" => {"ident" => "first-line"}}],
                 css1 => {parse => '#my-id',
                          ast => ["simple_selector" => {"id" => "my-id"}]},
    },
    selector => {input => 'A:first-letter',
                 ast => ["simple_selector" => {"element_name" => "A",
                                               "pseudo" => {"ident" => "first-letter"}}],
    },
    selector => {input => 'A:Link IMG',
                 ast => ["simple_selector" => {"element_name" => "A",
                                               "pseudo" => {"ident" => "Link"}},
                          "simple_selector" => {"element_name" => "IMG"}],
    },
    term => {input => '#eeeeee', ast => 'eeeeee'},
    term => {input => 'rgb(17%, 33%, 70%)',
             ast => {r => 17, g => 33, b => 70},
    },
    term => {input => 'rgb(17%, 33%, 70%',
             warnings => ["missing closing ')'"],
             ast => {r => 17, g => 33, b => 70},
    },
    num => {input => '1',ast => 1},
    num => {input => '.1', ast => .1 },
    num => {input => '1.9', ast => 1.9},
    uterm => {input => '1cm', ast => 1},
    uterm => {input => 'em', ast => 'em'},
    uterm => {input => '01.10', ast => 1.1},
    expr => {input => 'RGB(70,133,200 ), #fff',
             ast => ["term" => {"r" => 70, "g" => 133, "b" => 200},
                     "operator" => ",",
                     "term" => "fff"],
    },
    expr => {input => "'Helvetica Neue',helvetica-neue, helvetica",
             ast => ["term" => "Helvetica Neue", "operator" => ",",
                     "term" => "helvetica-neue", "operator" => ",",
                     "term" => "helvetica"],
    },
    expr => {input => '13mm EM', ast => ["term" => 13, "term" => "em"]},
    expr => {input => '-1CM', ast => [term => 1]},
    expr => {input => '2px solid blue',
             ast => ["term" => 2, "term" => "solid", "term" => "blue"],
    },
    # CSS21  Expressions
    expr => {input => 'top,ccc/#IDID',
             ast => ["term" => "top", "operator" => ",",
                     "term" => 'ccc', "operator" => '/',
                     "term" => 'IDID'],
    },
    expr => {input => '-moz-linear-gradient',
             ast => ["term" => "-moz-linear-gradient"],
             # css1 treats leading '-' as an operator
             css1 => {ast => ["term" => "moz-linear-gradient"]},
    },
    # css2 understands some functions
    expr => {input => '-moz-linear-gradient(top, #CCC, #DDD)',
             ast =>  ["term"
                      => {"ident" => "-moz-linear-gradient",
                          "expr" => ["term" => "top",
                                     "operator" => ",",
                                     "term" => "CCC",
                                     "operator" => ",",
                                     "term" => "DDD"]}],
             css1 => {warnings => ['skipping term: (top, #CCC, #DDD)'],
                      ast => ["term" => "moz-linear-gradient"],
             },
    },
    expr => {input => '12px/20px',
             ast => ["term" => 12, "operator" => "/", "term" => 20],
    },
    declaration => {input => 'line-height: 1.1px !important',
                    ast => {"property" => {"ident" => "line-height"},
                            "expr" => ["term" => 1.1],
                            "prio" => "important"},
    },
    declaration => {input => 'line-height: 1.5px !vital',
                    warnings => ['skipping term: vital'],
                    ast => {"property" => {"ident" => "line-height"},
                            "expr" => ["term" => 1.5]},
    },
    declaration => {input => 'margin: 1em',
                    ast => {"property" => {"ident" => "margin"},
                            "expr" => ["term" => 1]},
    },
    declaration => {input => 'border: 2px solid blue',
                    ast => {"property" => {"ident" => "border"},
                            "expr" => ["term" => 2,
                                       "term" => "solid",
                                       "term" => "blue"]},
    },
    ruleset => {input => 'H1 { color: blue; }',
                ast => {"selectors" => ["selector" => ["simple_selector" => {"element_name" => "H1"}]], "declarations" => ["declaration" => {"property" => {"ident" => "color"}, "expr" => ["term" => "blue"]}]},
    },
    ruleset => {input => 'A:link H1 { color: blue; }',
                ast => {"selectors" => ["selector" => ["simple_selector" => {"element_name" => "A", "pseudo" => {"ident" => "link"}},
                                                       "simple_selector" => {"element_name" => "H1"}]],
                        "declarations" => ["declaration" => {"property" => {"ident" => "color"}, "expr" => ["term" => "blue"]}]},
    },
    ruleset => {input => 'A:link,H1 { color: blue; }',
                ast => {"selectors" => ["selector" => ["simple_selector" => {"element_name" => "A", "pseudo" => {"ident" => "link"}}],
                                        "selector" => ["simple_selector" => {"element_name" => "H1"}]],
                        "declarations" => ["declaration" => {"property" => {"ident" => "color"}, "expr" => ["term" => "blue"]}]},
    },
    ruleset => {input => 'H1#abc { color: blue; }',
                ast => {"selectors" => ["selector" => ["simple_selector" => {"element_name" => "H1", "id" => "abc"}]],
                        "declarations" => ["declaration" => {"property" => {"ident" => "color"}, "expr" => ["term" => "blue"]}]},
    },
    ruleset => {input => 'A.external:visited { color: blue; }',
                ast => {"selectors" => ["selector" => ["simple_selector" => {"element_name" => "A", "class" => "external", "pseudo" => {"ident" => "visited"}}]],
                        "declarations" => ["declaration" => {"property" => {"ident" => "color"}, "expr" => ["term" => "blue"]}]},
    },
    dimension => {input => '70deg', ast => 70, units => 'deg'},
    # character set differences:
    # \255 is not in the css1 charset, but is in css2; some tricksters
    # use this to verify that the parse is css2 compliant
    #
    ruleset => {input => ".TB	\{mso-special-format:nobullet\x[95];\}",
                ast => {"selectors" => ["selector" => ["simple_selector" => {"class" => "TB"}]],
                        "declarations" => ["declaration" => {"property" => {"ident" => "mso-special-format"}, "expr" => ["term" => "nobullet\x[95]"]}]},
                css1 => {
                    ast => {"selectors" => ["selector" => ["simple_selector" => {"class" => "TB"}]],
                            "declarations" => ["declaration" => {"property" => {"ident" => "mso-special-format"}, "expr" => ["term" => "nobullet"]}]},
                    warnings => 'skipping term: \\x[95]',
                },
    },
    ruleset => {input => 'H2 { color: green; rotation: 70deg; }',
                ast => {"selectors" => ["selector" => ["simple_selector" => {"element_name" => "H2"}]],
                        "declarations" => ["declaration" => {"property" => {"ident" => "color"}, "expr" => ["term" => "green"]}, "declaration" => {"property" => {"ident" => "rotation"}, "expr" => ["term" => 70e0]}]},
                css1 => {
                    warnings => ['skipping term: 70deg'],
                    ast => {"selectors" => ["selector" => ["simple_selector" => {"element_name" => "H2"}]],
                            "declarations" => ["declaration" => {"property" => {"ident" => "color"}, "expr" => ["term" => "green"]}, "declaration" => {"property" => {"ident" => "rotation"}, "expr" => []}]},
                },
    },
    ruleset => {input => 'H1 { color }',
                warnings => ['skipping term: color '],
    },
    ruleset => {input => 'H1 { color; }',
                warnings => ['skipping term: color'],
    },
    ruleset => {input => 'H1 { color: }',
                warnings => ['incomplete declaration'],
    },
    ruleset => {input => 'H1 { : blue }',
                warnings => ['skipping term: : blue '],
    },
    ruleset => {input => 'H1 { color blue }',
                warnings => ['skipping term: color blue '],
    },

    # unclosed rulesets
    ruleset => {input => 'H2 { color: green; rotation: 70deg;',
                warnings => ["no closing '}'"],
                css1 => {
                    warnings => ["no closing '}'",
                                 'skipping term: 70deg']
                }
    },
    ruleset => {input => 'H2 { color: green; rotation: }',
                warnings => "incomplete declaration",
    },

    ruleset => {input => 'H2 { test: "this is not closed',
                warnings => [
                    "no closing '}'",
                    'unterminated string',
                    ]
    },

    # from the top
    TOP => {input => "@charset 'bazinga';\n",
            css2 => {
                ast => [charset => "bazinga"],
            },
            css1 => {
                warnings => [q{skipping: @charset 'bazinga';}]
            },
    },
    TOP => {input => "\@import 'foo';\nH1 \{ color: blue; \};\n@charset 'bazinga';\n\@import 'too-late';\nH2\{color:green\}",
            ast => ["import" => {"string" => "foo"}, "ruleset" => {"selectors" => ["selector" => ["simple_selector" => {"element_name" => "H1"}]], "declarations" => ["declaration" => {"property" => {"ident" => "color"}, "expr" => ["term" => "blue"]}]}, "ruleset" => {"selectors" => ["selector" => ["simple_selector" => {"element_name" => "H2"}]], "declarations" => ["declaration" => {"property" => {"ident" => "color"}, "expr" => ["term" => "green"]}]}],
            warnings => [
                q{ignoring out of sequence directive: @charset 'bazinga';},
                q{ignoring out of sequence directive: @import 'too-late';},
                ],
             css1 => {
                warnings => [
                    q{ignoring out of sequence directive: @import 'too-late';},
                    q{skipping: @charset 'bazinga';},
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

    # CSS1 Compat
    $css_actions.warnings = ();
    my $p1 = CSS::Grammar::CSS1.parse( $input, :rule($rule), :actions($css_actions));
    compat_tests($input, $p1, :rule($rule), :compat('css1'), :expected( %(%test, %$css1)) );

    # CSS21 Compat
    $css_actions.warnings = ();
    my $p2 = CSS::Grammar::CSS21.parse( $input, :rule($rule), :actions($css_actions));
    compat_tests($input, $p2, :rule($rule), :compat('css2'), :expected( %(%test, %$css2)) );

    # CSS3 Compat
    $css_actions.warnings = ();
    my $p3 = CSS::Grammar::CSS3.parse( $input, :rule($rule), :actions($css_actions));
    compat_tests($input, $p3, :rule($rule), :compat('css3'), :expected( %(%test, %$css3)) );
}

sub compat_tests($input, $parse, :$rule, :$compat, :%expected) {

    my $parsed = %expected<parse> // $input;

    is($parse.Str, $parsed, "{$compat}: " ~ $rule ~ " parse: " ~ $input);

    my @expected_warnings = %expected<warnings> // ();
    my @warnings = sort $css_actions.warnings;
    is(@warnings, @expected_warnings,
       @expected_warnings ?? "{$compat} warnings" !! "{$compat} no warnings");

    if defined (my $ast = %expected<ast>) {
        is($parse.ast, $ast, "{$compat} - ast")
            or diag $parse.ast.perl;
    }
    else {
        if defined $parse.ast {
            note {untested_ast =>  $parse.ast}.perl;
        }
        else {
            diag "no {$compat} ast: " ~ $input;
        }
    }

    if defined (my $units = %expected<units>) {
        if ok($parse.ast.can('units'), "{$compat} does units") {
            is($parse.ast.units, $units, "{$compat} - units")
                or diag $parse.ast.units
            }
    }

    if defined (my $skip = %expected<skip>) {
        if ok($parse.ast.can('skip'), "{$compat} does skip") {
            is($parse.ast.skip, $skip, "{$compat} - skip is " ~ $skip);
        }
    }

}

done;
