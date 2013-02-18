use v6;

use Test;
use CSS::Grammar::CSS1;
use CSS::Grammar::CSS21;
use CSS::Grammar::CSS3;
use CSS::Grammar::Actions;

for ("\\012AF", "\\012AFc") {
    # css2 unicode is up to 6 digits
    ok($_ !~~ /^<CSS::Grammar::CSS1::unicode>$/, "not css1 unicode: $_");
    ok($_ ~~ /^<CSS::Grammar::CSS21::unicode>$/, "css2 unicode: $_");
}

for ('70deg') { 
    ok($_ ~~ /^<CSS::Grammar::CSS1::num><CSS::Grammar::CSS1::ident>$/, "css2 angle: $_");
    ok($_ ~~ /^<CSS::Grammar::CSS21::angle>$/, "css2 angle: $_");
}

# from: http://www.w3.org/Style/CSS/Test/CSS1/current/sec71.htm
my $css3_sample = q:to/END_CSS3/;
@Import 'foo.bar';
P.one {color: green; rotation: 70deg;}
P.oneb {color: green;}
P.oneb {color: invalidValue;}
P.two {background-color: inherit;}
@zz {foo:bar}
H1 + P.three {color: blue;}
P.four + H1 {color: red;}
P.five {background-color: "red";}
P.sixa {border-width: medium; border-style: solid;}
P.sixb {border-width: funny; border-style: solid;}
P.sixc {border-width: 50Hz; border-style: solid;}
P.sixd {border-width: px; border-style: solid;}

@three-dee {
 @background-lighting {
  azimuth: 30deg;
  elevation: 190deg;
  }
 P.seven { color: red }
 }

P.eight {COLOR: GREEN;}
OL:wait {color: maroon;}
P.ten:first-child {color: maroon;}
UL:lang(fr) {color: gray;}
BLOCKQUOTE[href] {color: navy;}
ACRONYM[href="foo"] {color: purple;}
ADDRESS[href~="foo"] {color: purple;}
SPAN[lang|="fr"] {color: #c37;}
@media tty {
 H1 {color: red;}
 P.sixteen {color: red;}
 }
@three-dee {
 P.seventeen {color: red }
 }
P.eighteena {text-decoration: underline overline line-through diagonal;
            font: bold highlighted 100% sans-serif;}
P.eighteenb {text-decoration: underline overline line-through diagonal;
            font: bold highlighted 100% serif;}
EM, P.nineteena ! EM, STRONG {font-size: 200%; }

// UL.nineteenb,
P.nineteenb {color: red;}

P.twentya {rotation-code: "}"; color: blue;} 
P.twentyb {rotation-code: "\"}\""; color: green;}
P.twentyonea {rotation-code: '}'; color: purple;} 
P.twentyoneb {rotation-code: '\'}\''; color: green;}

P.twentytwo {
 type-display: @threedee {rotation-code: '}';};
 color: green;
 }

P.twentythree {text-indent: 0.5in;}

P.twentyfour {color: red;}
END_CSS3

my @tests = (
    sample => $css3_sample,
    );

my $css_actions = CSS::Grammar::Actions.new;

for @tests {
    $css_actions.warnings = ();     
    my $p1 = CSS::Grammar::CSS1.parse( $_.value, :actions($css_actions) );
    ok( $p1, 'css1 parse ' ~ $_.key)
    or diag do {$_.value ~~ /(<CSS::Grammar::CSS1::stylesheet>)/; $0.Str || $_.value};
    # warnings are normal here - tests to be added
    note $css_actions.warnings if $css_actions.warnings;
}
            
for @tests {
    $css_actions.warnings = ();     
    my $p2 = CSS::Grammar::CSS21.parse( $_.value, :actions($css_actions) );
    ok( $p2, 'css2 parse ' ~ $_.key)
    or diag do {$_.value ~~ /(<CSS::Grammar::CSS21::stylesheet>)/; $0.Str || $_.value};
            
    # warnings are normal here - tests to be added
    note $css_actions.warnings if $css_actions.warnings;
}

for @tests {
    $css_actions.warnings = ();     
    my $p3 = CSS::Grammar::CSS3.parse( $_.value, :actions($css_actions) );
    ok( $p3, 'css3 parse ' ~ $_.key)
    or diag do {$_.value ~~ /(<CSS::Grammar::CSS3::stylesheet>)/; $0.Str || $_.value};
            
    # warnings are normal here - tests to be added
    note $css_actions.warnings if $css_actions.warnings;
}

done;
