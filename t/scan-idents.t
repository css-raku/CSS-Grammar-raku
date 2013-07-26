use v6;

use Test;
use CSS::Grammar::Scan::Actions;
use CSS::Grammar::CSS21;

my $a = CSS::Grammar::Scan::Actions.new;

my $p = CSS::Grammar::Scan.parse('\h1{c\ol\6fr: bl\ue}', :actions($a), :rule<ident-cleanup>);

my $css-cleaned = $p.ast;

is($css-cleaned, 'h1{color: blue}', "ident cleanup")
   or diag $css-cleaned;

done;
