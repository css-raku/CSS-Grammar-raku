#!/usr/bin/env perl6
use v6;
use Test;

use CSS::Grammar::CSS3;
use CSS::Grammar::Actions;

use lib '.';
use t::AST;

my $test_css = %*ENV<TEST_CSS>;
if ($test_css) {
    diag "loading $test_css";
}
else {
    $test_css = 't/jquery-ui-themeroller.css';
    diag "loading $test_css (set \$TEST_CSS to override)";
}

my $fh = open $test_css
    or die "unable to open $fh: $!";

my $css_body = join("\n", $fh.lines);
$fh.close;

my $actions = CSS::Grammar::Actions.new;

diag "...parsing...";

my $p = CSS::Grammar::CSS3.parsefile($test_css, :actions($actions) );

ok($p, "parsed css content ($test_css)")
    or die "parse failed - can't continue";

diag "...dumping...";

note $p.ast.perl;

my %expected = {ast => Mu};

t::AST::parse_tests(Any, $p, :suite('css3 file'), :rule('TOP'), :expected(%expected));

done;
