#!/usr/bin/env perl6

use Test;
use CSS::Grammar;
use CSS::Grammar::CSS21;

# whitespace
for (' ', '  ', "\t", "\r\n", ' /* hi */ ', '/*there*/', '<!-- zzz -->') {
    ok($_ ~~ /^<CSS::Grammar::ws>$/, "ws: $_");
}

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

# nonascii
for ('¡', "\o250", 'ÿ') {
    ok($_ ~~ /^<CSS::Grammar::nonascii>$/, "nonascii: $_");
}

for (chr(0), ' ', '~') {
    ok($_ !~~ /^<CSS::Grammar::nonascii>$/, "not nonascii: $_");
} 

for ('http://www.bg.com/pinkish.gif', '"http://www.bg.com/pinkish.gif"', "'http://www.bg.com/pinkish.gif'", '"http://www.bg.com/pink(ish).gif"', "'http://www.bg.com/pink(ish).gif'", 'http://www.bg.com/pink%20ish.gif', 'http://www.bg.com/pink\(ish\).gif') {
    ok($_ ~~ /^<CSS::Grammar::url_string>$/, "css1 url_string: $_");
}

for ('http://www.bg.com/pink(ish).gif') {
    ok($_ !~~ /^<CSS::Grammar::url_string>$/, "not css1 url_string: $_");
}

for ('Appl8s', 'oranges', 'k1w1-fru1t', '-i') {
    ok($_ ~~ /^<CSS::Grammar::ident>$/, "ident: $_")
        or diag $_;
}

for ('8') {
    ok($_ !~~ /^<CSS::Grammar::ident>$/, "not ident: $_")
        or diag $_;
}

my $rulesets = '{
   body { font-size: 10pt }
}';

for ('{ }', $rulesets) { 
    ok($_ ~~ /^<CSS::Grammar::CSS21::rulesets>$/, "css2 rulesets: $_");
}

my $at_rule_page = '@page :left { margin: 3cm };';
my $at_rule_print = '@media print ' ~ $rulesets;

for ($at_rule_page, $at_rule_print) { 
    ok($_ ~~ /^<CSS::Grammar::CSS21::at_rule>$/, "css2 at_rule: $_");
}

for (q{"Hello"}, q{'world'}, q{''}, q{""}, q{"'"}, q{'"'}, q{"grocer's"}, q{"Hello},  q{"},) {
    ok($_ ~~ /^<CSS::Grammar::string>$/, "string: $_")
        or diag $_;
}

for (q{world'}, q{'''}, q{'grocer's'},  "'hello\nworld'") {
    ok($_ !~~ /^<CSS::Grammar::string>$/, "not string: $_")
        or diag $_;
}

done;
