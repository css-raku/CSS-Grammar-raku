use v6;

use Test;

use CSS::Grammar::Test;
use CSS::Grammar::CSS1;
use CSS::Grammar::CSS21;
use CSS::Grammar::CSS3;
use CSS::Grammar::Actions;

my $fh = open 't/parse-warnings.css', :r;
my @lines = $fh.lines;
my $expected_lines = @lines.Int;
my $css-sample = @lines.join("\n");

my %level-warnings = @lines.map({/^(\w+)\-warnings\:\s/ ?? (~$0 => $/.postmatch) !! ()});

my $css-actions = CSS::Grammar::Actions.new;

for (css1 => CSS::Grammar::CSS1),
    (css21 => CSS::Grammar::CSS21),
    (css3 => CSS::Grammar::CSS3) {

    my ($test, $class) = .kv;

    $css-actions.reset;     
    my $p1 = $class.parse( $css-sample, :actions($css-actions));
    ok( $p1, $test ~ ' parse' );

    is($css-actions.line-no, $expected_lines, 'line count');

    my $expected-warnings = %level-warnings{$test};
    my $actual-warnings = ~$css-actions.warnings;
    is($actual-warnings, $expected-warnings, $test ~ ' warnings')
}

done;
