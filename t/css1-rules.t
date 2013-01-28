#!/usr/bin/env perl6

use Test;
use CSS::Grammar::CSS1;
use CSS::Grammar::CSS2;

# whitespace
for (' ', '  ', "\t", "\r\n", ' /* hi */ ', '/*there*/', '<!-- zzz -->') {
    ok($_ ~~ /^<CSS::Grammar::CSS1::ws>$/, "ws: $_");
}

# unicode
for ("\\f", "\\012f", "\\012A") {
    ok($_ ~~ /^<CSS::Grammar::CSS1::unicode>$/, "unicode: $_");
}

# latin1
for ('¡', "\o250", 'ÿ') {
    ok($_ ~~ /^<CSS::Grammar::CSS1::latin1>$/, "latin1: $_");
}

for (chr(0), ' ', '~') {
    ok($_ !~~ /^<CSS::Grammar::CSS1::latin1>$/, "not latin1: $_");
} 

for ('Appl8s', 'oranges', 'k1w1-fru1t') {
    ok($_ ~~ /^<CSS::Grammar::CSS1::ident>$/, "ident: $_");
}

for ('8', '-i') {
    ok($_ !~~ /^<CSS::Grammar::CSS1::ident>$/, "not ident: $_");
}

for (q{"Hello"}, q{'world'}, q{''}, q{""}, q{"'"}, q{'"'}, q{"grocer's"}) {
    ok($_ ~~ /^<CSS::Grammar::CSS1::string>$/, "string: $_");
}

for (q{"Hello}, q{world'}, q{'''}, q{"}, q{'grocer's'},) {
    ok($_ !~~ /^<CSS::Grammar::CSS1::string>$/, "not string: $_");
}

for (
    ws => ' ',
    ws => "/* comments\n1 */",
    ws => "<!-- comments\n2 -->",
    ws => "<!-- unterminated comment",
    percentage => '50%',
    id => '#zzz',
    class => '.zippy',
    num => '2.52',
    length => '2.52cm',
    pseudo => ':visited',
    url => 'url("http://www.bg.com/pinkish.gif")',
    url => 'URL(http://www.bg.com/pinkish.gif)',
    import => "@import 'file:///etc/passwd';",
    import => "@IMPORT 'file:///etc/group';",
    quotable_char => '(',
    quotable_char => ' ',
    unquoted_escape_seq => '\(',
    unquoted_escape_seq => '\\',
    unquoted_string => 'perl\(6\)\ rocks',
    class => '.class',
    simple_selector => 'BODY',
    selector => 'A:visited',
    selector => ':visited',
    selector => '.some_class',
    selector => '.some_class:link',
    name => 'some_class',
    element_name => 'BODY', class => '.some_class',
    simple_selector => 'BODY.some_class',
    pseudo => ':first-line',
    selector => 'BODY.some_class:active',
    selector => '#my-id :first-line',
    selector => 'A:first-letter',
    selector => 'A:Link IMG',
    hexcolor => '#eeeeee',
    rgb => 'rgb(17%, 33%, 70%)',
    num => '1',
    num => '.1',
    num => '1.9',
    term => '1cm',
    term => 'em',
    term => '1.1',
    expr => 'RGB (70,133,200 ), #fff',
    expr => '13mm EM',
    expr => '-1CM',
    expr => '2px solid blue',
    declaration => 'line-height: 1.1',
    declaration => 'line-height: 1.1px',
    declaration => 'margin: 1em',
    declaration => 'border: 2px solid blue',
    ruleset => 'H1 { color: blue; }',
    ruleset => 'A:link H1 { color: blue; }',
    dimension => '70deg',
    ruleset => 'H2 { color: green; rotation: 70deg; }',
    # unclosed rulsets
    ruleset => 'H2 { color: green; rotation: 70deg;',
    ruleset => 'H2 { color: green; rotation:',
    ruleset => 'H2 { profundity: "The meaning of life is',
    TOP => 'H1 { color: blue; }',
    ) {

    my $p1 = CSS::Grammar::CSS1.parse( $_.value, :rule($_.key));
    ok($p1, "css1: " ~ $_.key ~ " parse: " ~ $_.value);

    my $p2 = CSS::Grammar::CSS2.parse( $_.value, :rule($_.key));
    ok($p2, "css2: " ~ $_.key ~ " parse: " ~ $_.value);
}

done;
