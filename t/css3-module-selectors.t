#!/usr/bin/env perl6

use Test;

use CSS::Grammar::CSS3;
use CSS::Grammar::CSS3::Module::Selectors;
use CSS::Grammar::Actions;

# prepare our own composite class with paged selector extensions

grammar t::CSS3::SelectorsGrammar
    is CSS::Grammar::CSS3::Module::Selectors
    is CSS::Grammar::CSS3
    {};

class t::CSS3::SelectorsActions
    is CSS::Grammar::CSS3::Module::Selectors::Actions
    is CSS::Grammar::Actions
    {};

use lib '.';
use t::CSS;

my $css_actions = t::CSS3::SelectorsActions.new;

for (
    unicode_range => {input => 'U+416', ast => [0x416, 0x416]},
    unicode_range => {input => 'U+400-4FF', ast => [0x400, 0x4FF]},
    unicode_range => {input => 'U+4??', ast => [0x400, 0x4FF]},
    term => {input => 'U+2??a', ast => {unicode_range => [0x200A, 0x2FFA]}},
    pseudo => {input => '::my-elem',
               ast => {element => 'my-elem'},
    },
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
    my $p3 = t::CSS3::SelectorsGrammar.parse( $input, :rule($rule), :actions($css_actions));
    t::CSS::parse_tests($input, $p3, :rule($rule), :compat('css3-selector'),
                         :warnings($css_actions.warnings),
                         :expected(%test) );
}

done;
