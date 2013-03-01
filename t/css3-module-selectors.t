#!/usr/bin/env perl6

use Test;

use CSS::Grammar;
use CSS::Grammar::CSS3;
use CSS::Grammar::Actions;

use lib '.';
use t::CSS;

my $css_actions = CSS::Grammar::Actions.new;

for (
    # thanks to: http://kilianvalkhof.com/2008/css-xhtml/the-css3-not-selector/
    negation   => {input => ':not(p)',
                   ast => {"type_selector" => {"element_name" => "p"}},
    },
    selector   => {input => ':not(p',
                   ast => ["simple_selector" => ["negation" => {"type_selector" => {"element_name" => "p"}}]],
                   warnings => "missing closing ')'",
    },
    selector   => {input => ':not(:not(p))',
                   warnings => "unexpected negation: :not(p)",
                   ast => Mu,
    },
    selector   => {input => ':not(.home)',
                   ast => ["simple_selector" => ["negation" => {"class" => "home"}]],
    },
    selector   => {input => 'div *:not(p)',
                   ast => ["simple_selector" => ["element_name" => "div"], "simple_selector" => ["wildcard" => "*", "negation" => ["type_selector" => {"element_name" => "p"}]]],
    },
    selector   => {input => 'input:not([type="file"])',
                   ast => ["simple_selector" => ["element_name" => "input", "negation" => ["attrib" => {"ident" => "type", "attribute_selector" => "=", "string" => "file"}]]],
    },
    selector   => {input => 'li:not(.pingback) .comment-content p:first-child:first-line',
                   ast => ["simple_selector" => ["element_name" => "li", "negation" => ["class" => "pingback"]], "simple_selector" => ["class" => "comment-content"], "simple_selector" => ["element_name" => "p", "pseudo" => {"class" => "first-child"}, "pseudo" => {"class" => "first-line"}]],
    },
    selector   => {input => 'body:not(.home) h2 + p:first-letter',
                   ast => ["simple_selector" => ["element_name" => "body", "negation" => ["class" => "home"]], "simple_selector" => ["element_name" => "h2"], "combinator" => "+", "simple_selector" => ["element_name" => "p", "pseudo" => {"class" => "first-letter"}]],
    },
    selector =>   {input => 'h2:not(:first-of-type):not(:last-of-type)',
                   ast => ["simple_selector" => ["element_name" => "h2", "negation" => ["pseudo" => {"class" => "first-of-type"}], "negation" => ["pseudo" => {"class" => "last-of-type"}]]],
    },
    ) {
    my $rule = $_.key;
    my %test = $_.value;
    my $input = %test<input>;

    $css_actions.warnings = ();
    my $p3 = CSS::Grammar::CSS3.parse( $input, :rule($rule), :actions($css_actions));
    t::CSS::parse_tests($input, $p3, :rule($rule), :compat('css3-selector'),
                         :warnings($css_actions.warnings),
                         :expected(%test) );
}

done;
