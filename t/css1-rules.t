#!/usr/bin/env perl6

use Test;
use CSS::Grammar::CSS1;
use CSS::Grammar::CSS2;
use CSS::Grammar::Actions;

my $css_actions = CSS::Grammar::Actions.new;

for (
    ws => ' ',
    ws => "/* comments\n1 */",
    ws => "<!-- comments\n2 -->",
    ws => "<!-- unterminated comment",
    percentage => '50%',
    unicode => '\\021',
    id => '#zzz',
    class => '.zippy',
    num => '2.52',
    length => '2.52cm',
    pseudo => ':visited',
    url_spec => '"http://www.bg.com/pinkish.gif"',
    url_spec => 'http://www.bg.com/pinkish.gif',
    url_spec => 'http://www.bg.com/pinkish.gif',
    url => 'url("http://www.bg.com/pinkish.gif")',
    url => 'URL(http://www.bg.com/pinkish.gif)',
    url => 'URL(http://www.bg.com/pinkish.gif',
    import => "@import 'file:///etc/passwd';",
    import => "@IMPORT 'file:///etc/group';",
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
    term => '#eeeeee',
    term => 'rgb(17%, 33%, 70%)',
    num => '1',
    num => '.1',
    num => '1.9',
    term => '1cm',
    term => 'em',
    term => '1.1',
    expr => 'RGB(70,133,200 ), #fff',
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
    TOP => 'H1 { color: blue; }',
    # unclosed rulsets
    ruleset => 'H2 { color: green; rotation: 70deg;',
    ruleset => 'H2 { color: green; rotation:',
    ruleset => 'H2 { profundity: "The meaning of life is',
    ) {

    my $p1 = CSS::Grammar::CSS1.parse( $_.value, :rule($_.key), :actions($css_actions));
    ok($p1, "css1: " ~ $_.key ~ " parse: " ~ $_.value);

    my $p2 = CSS::Grammar::CSS2.parse( $_.value, :rule($_.key), :actions($css_actions));
    ok($p2, "css2: " ~ $_.key ~ " parse: " ~ $_.value);
}

done;
