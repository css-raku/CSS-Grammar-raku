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
use t::AST;

my $css_actions = t::CSS3::SelectorsActions.new;

for (
    unicode_range => {input => '416', ast => [0x416, 0x416]},
    unicode_range => {input => '400-4FF', ast => [0x400, 0x4FF]},
    unicode_range => {input => '4??', ast => [0x400, 0x4FF]},
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
    # namespaces and wildcards
    selector   => {input => '*', ast => ["simple_selector" => ["wildcard" => "*"]],},
    selector => {input => 'foo|h1',
                 ast => ["simple_selector" => ["namespace_prefix" => {"ident" => "foo"}, "element_name" => "h1"]],
    },
    selector => {input => 'foo|*',
                 ast => ["simple_selector" => ["namespace_prefix" => {"ident" => "foo"},
                                               "wildcard" => "*"]],
    },
    selector => {input => '|h1',
                 ast => ["simple_selector" => ["namespace_prefix" => {},
                                               "element_name" => "h1"]],
    },
    selector => {input => '*|h1',
                 ast => ["simple_selector" => ["namespace_prefix" => {"wildcard" => "*"},
                                               "element_name" => "h1"]],
                 
    },
    # attributes
    selector => {input => 'span[hello="Cleveland"][goodbye="Columbus"]',
                 ast => ["simple_selector" => ["element_name" => "span",
                                               "attrib" => {"ident" => "hello", "attribute_selector" => "=", "string" => "Cleveland"},
                                               "attrib" => {"ident" => "goodbye", "attribute_selector" => "=", "string" => "Columbus"}]],
    },
    selector => {input => 'object[type^="image/"]',
                 ast => ["simple_selector" => ["element_name" => "object",
                                              "attrib" => {"ident" => "type", "attribute_selector" => "^=", "string" => "image/"}]],
    },
    # nth-... selectors
    selector => {input => 'foo:myfunc(42)',
                 ast => ["simple_selector" => ["element_name" => "foo",
                                               "pseudo" => {"function" => {"ident" => "myfunc", "expr" => ["term" => 42]}}]],
    },
    selector => {input => 'bar:nth-child(3n+1)',
                 ast => ["simple_selector" => ["element_name" => "bar",
                                               "pseudo" => {"nth_function" => {"ident" => "nth-child",
                                                                               "expr" => {"a" => 3, "b" => 1}}}]],
    },
    selector => {input => 'bar:nth-last-child(odd)',
                 ast => ["simple_selector" => ["element_name" => "bar",
                                               "pseudo" => {"nth_function" => {"ident" => "nth-last-child",
                                                                               "expr" => 'odd'}}]],
    },
    selector => {input => 'tr:nth-last-child(-n+2)',
                 ast => ["simple_selector" => ["element_name" => "tr", "pseudo" => {"nth_function" => {"ident" => "nth-last-child", "expr" => {"b" => 2, "a" => -1}}}]],
    },
    selector => {input => 'td:nth-child(3)',
                 ast => ["simple_selector" => ["element_name" => "td",
                                               "pseudo" => {"nth_function" => {"ident" => "nth-child",
                                                                               "expr" => {"b" => 3}}}]],
    },
    ) {
    my $rule = $_.key;
    my %test = $_.value;
    my $input = %test<input>;

    $css_actions.warnings = ();
    my $p3 = t::CSS3::SelectorsGrammar.parse( $input, :rule($rule), :actions($css_actions));
    t::AST::parse_tests($input, $p3, :rule($rule), :suite('css3-selector'),
                         :warnings($css_actions.warnings),
                         :expected(%test) );
}

done;
