#!/usr/bin/env perl6

use Test;
use CSS::Grammar;
use CSS::Grammar::CSS1;
use CSS::Grammar::CSS21;
use CSS::Grammar::CSS3;

# whitespace
for (' ', '  ', "\t", "\r\n", ' /* hi */ ', '/*there*/', '<!-- zzz -->') {
    ok($_ ~~ /^<CSS::Grammar::ws>$/, "ws: $_");
}
nok("r\n" ~~ /^<CSS::Grammar::ws>$/, "ws: r\\n");

# comments
for ('/**/', '/* hi */', '<!--X-->',
     '<!-- almost done -->',
     '<!-- Out of coffee',
     '/* is that the door?',) {
    ok($_ ~~ /^<CSS::Grammar::comment>$/, "comment: $_");
}

# unicode
for ("\\f", "\\012f", "\\012A") {
    ok($_ ~~ /^<CSS::Grammar::unicode>$/, "unicode: $_");
}

for ("\\012AF", "\\012AFc") {
    # css2+ unicode is up to 6 digits
    nok($_ ~~ /^<CSS::Grammar::CSS1::unicode>$/, "not css1 unicode: $_");
    ok($_ ~~ /^<CSS::Grammar::CSS21::unicode>$/, "css21 unicode: $_");
    ok($_ ~~ /^<CSS::Grammar::CSS3::unicode>$/, "css3 unicode: $_");
}

# angle, freq - introduced with css2
for ('70deg', '50Hz') { 
    ok($_ ~~ /^<CSS::Grammar::CSS1::num><CSS::Grammar::CSS1::ident>$/, "css1 num+ident: $_");
    ok($_ ~~ /^<CSS::Grammar::CSS21::term>$/, "css21 term: $_");
    ok($_ ~~ /^<CSS::Grammar::CSS3::term>$/, "css3 term: $_");
}

# non-ascii
for ('¡', "\o250", 'ÿ') {
    ok($_ ~~ /^<CSS::Grammar::nonascii>$/, "non-ascii: $_ ("~$_.ord~')');
    ok($_ ~~ /^<CSS::Grammar::CSS1::nonascii>$/, "non-ascii css1: $_");
    ok($_ ~~ /^<CSS::Grammar::CSS21::nonascii>$/, "non-ascii css21: $_");
    ok($_ ~~ /^<CSS::Grammar::CSS3::nonascii>$/, "non-ascii css3: $_");
}

# css1 and css21 only recognise latin chars as non-ascii (\o240-\o377)
for ('') {
    ok($_ ~~ /^<CSS::Grammar::nonascii>$/, "non-ascii: $_ ("~$_.ord~')');
    nok($_ ~~ /^<CSS::Grammar::CSS1::nonascii>$/, "not non-ascii css1: $_");
    nok($_ ~~ /^<CSS::Grammar::CSS21::nonascii>$/, "not non-ascii css21: $_");
    ok($_ ~~ /^<CSS::Grammar::CSS3::nonascii>$/, "non-ascii css3: $_");
}

for (chr(0), ' ', '~') {
    nok($_ ~~ /^<CSS::Grammar::nonascii>$/, "not non-ascii: $_");
    nok($_ ~~ /^<CSS::Grammar::CSS1::nonascii>$/, "not non-ascii css1: $_");
    nok($_ ~~ /^<CSS::Grammar::CSS21::nonascii>$/, "not non-ascii css21: $_");
    nok($_ ~~ /^<CSS::Grammar::CSS3::nonascii>$/, "not non-ascii css3: $_");
} 

for ('http://www.bg.com/pinkish.gif', '"http://www.bg.com/pinkish.gif"', "'http://www.bg.com/pinkish.gif'", '"http://www.bg.com/pink(ish).gif"', "'http://www.bg.com/pink(ish).gif'", 'http://www.bg.com/pink%20ish.gif', 'http://www.bg.com/pink\(ish\).gif') {
    ok($_ ~~ /^<CSS::Grammar::url_string>$/, "css1 url_string: $_");
}

for ('http://www.bg.com/pink(ish).gif') {
    nok($_ ~~ /^<CSS::Grammar::url_string>$/, "not css1 url_string: $_");
}

for ('Appl8s', 'oranges', 'k1w1-fru1t', '-i') {
    ok($_ ~~ /^<CSS::Grammar::ident>$/, "ident: $_");
}

for ('8') {
    nok($_ ~~ /^<CSS::Grammar::ident>$/, "not ident: $_");
}

for (q{"Hello"}, q{'world'}, q{''}, q{""}, q{"'"}, q{'"'}, q{"grocer's"}, q{"Hello},  q{"},) {
    ok($_ ~~ /^<CSS::Grammar::string>$/, "string: $_")
        or diag $_;
}

for (q{world'}, q{'''}, q{'grocer's'},  "'hello\nworld'") {
    nok($_ ~~ /^<CSS::Grammar::string>$/, "not string: $_")
        or diag $_;
}

my $media_rules = '{
   body { font-size: 10pt }
}';

for ('{ }', $media_rules) { 
    ok($_ ~~ /^<CSS::Grammar::CSS21::media_rules>$/, "css21 media_rules: $_");
    ok($_ ~~ /^<CSS::Grammar::CSS3::media_rules>$/, "css3 media_rules: $_");
}

my $at_rule_page = 'page :left { margin: 3cm };';
my $at_rule_print = 'media print ' ~ $media_rules;

for ($at_rule_page, $at_rule_print) { 
    ok($_ ~~ /^<CSS::Grammar::CSS21::at_rule>$/, "css21 at_rule: $_");
}

done;
