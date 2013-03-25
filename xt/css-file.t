#!/usr/bin/env perl6
use v6;
use Test;

use CSS::Grammar::CSS3::Extended;
use CSS::Grammar::Actions;

use lib '.';
use t::AST;

# can't find alplha(..) or mask(..) in specs or w3c css validator test suite

my %expected = {ast => Mu,
                warnings => Mu,
};

my $test_css = %*ENV<CSS_TEST_FILE>;
if ($test_css) {
    diag "loading $test_css";
    %expected<warnings> = Mu;
}
else {
    $test_css = 't/jquery-ui-themeroller.css';
    %expected<warnings> = [
        'unknown function: alpha', 'dropping declaration: filter',
        'unknown function: mask',  'dropping declaration: filter',
        'unknown function: alpha', 'dropping declaration: filter',
        ];

    diag "loading $test_css (set \$CSS_TEST_FILE to override)";
}

my $fh = open $test_css
    or die "unable to open $fh: $!";

my $css_body = join("\n", $fh.lines);
$fh.close;

my $actions = CSS::Grammar::CSS3::Extended::Actions.new;

diag "...parsing...";

my $p = CSS::Grammar::CSS3::Extended.parsefile($test_css, :actions($actions) );

ok($p, "parsed css content ($test_css)")
    or die "parse failed - can't continue";

t::AST::parse_tests($css_body, $p, :suite('css3 file'), :rule('TOP'),
                    :warnings($actions.warnings),
                    :expected(%expected));

diag "...dumping...";
note $p.ast.perl;

done;
