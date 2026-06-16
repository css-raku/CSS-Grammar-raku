use v6;

use Test;

use CSS::Grammar::Test;
use CSS::Grammar::CSS1;
use CSS::Grammar::CSS21;
use CSS::Grammar::CSS3;
use CSS::Grammar::CSS4;
use CSS::Grammar::Actions;

my $css-sample = 't/parse-warnings.css'.IO.slurp;
my @lines = $css-sample.lines;
my %warnings = @lines.map({/^(\w+)\-warnings\:\s/ ?? (~$0 => $/.postmatch) !! Empty});
my $actions = CSS::Grammar::Actions.new;

for CSS::Grammar::CSS1, CSS::Grammar::CSS21, CSS::Grammar::CSS3, CSS::Grammar::CSS4 -> $grammar {

    $actions.reset;
    my $level = $grammar.^shortname.lc;
    my $p1 = $grammar.parse( $css-sample, :$actions);
    ok $p1, $level ~ ' parse';

    my $expected-warnings = %warnings{$level} // %warnings<other>;
    my $actual-warnings = ~$actions.warnings;
    is $actual-warnings, $expected-warnings, $level ~ ' warnings';
}

done-testing;
