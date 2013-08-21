#!/usr/bin/env perl6
use v6;
use Test;

use CSS::Grammar::CSS3;
use CSS::Grammar::Actions;

use CSS::Grammar::Test;

my %expected = {ast => Mu};

my $test-css = %*ENV<CSS_TEST_FILE>;
if $test-css {
    diag "loading $test-css";
    %expected<warnings> = Mu;
}
else {
    $test-css = 't/jquery-ui-themeroller.css';
    diag "loading $test-css (set \$CSS_TEST_FILE to override)";
}

my $fh = open $test-css
    or die "unable to open $fh: $!";

my $css-body = join("\n", $fh.lines);
$fh.close;

my $actions = CSS::Grammar::Actions.new;

diag "...parsing...";

my $p = try { CSS::Grammar::CSS3.parsefile($test-css, :actions($actions) ) };

ok($p, "parsed css content ($test-css)")
    or die "parse failed - can't continue";

CSS::Grammar::Test::parse-tests(CSS::Grammar::CSS3, $css-body,
				:parse($p),
				:suite('css3 file'),
				:expected(%expected));

diag "...dumping...";
note $p.ast.perl;

done;
