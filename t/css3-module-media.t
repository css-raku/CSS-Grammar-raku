#!/usr/bin/env perl6

use Test;

use CSS::Grammar;
use CSS::Grammar::CSS3;
use CSS::Grammar::Actions;
use CSS::Grammar::CSS3::Module::PagedMedia;
use CSS::Grammar::CSS3::Module::Media;

# prepare our own composite class with paged media extensions

grammar t::CSS3::MediaGrammar
    is CSS::Grammar::CSS3::Module::PagedMedia  # for nested @page
    is CSS::Grammar::CSS3::Module::Media
    is CSS::Grammar::CSS3
{};

class t::CSS3::MediaActions
    is CSS::Grammar::CSS3::Module::PagedMedia::Actions
    is CSS::Grammar::CSS3::Module::Media::Actions
    is CSS::Grammar::Actions
{};

use lib '.';
use t::CSS;

my $css_actions = t::CSS3::MediaActions.new;

my $embedded_page = '@media print and (width: 21cm) and (height: 29.7cm) {
      @page { margin: 3cm; }
   }';

my $embedded_page_ast = {"media_list" => ["media_query" => ["media_type" => "print", "media_expr" => {"media_feature" => "width", "expr" => ["term" => {"length" => 21}]}, "media_expr" => {"media_feature" => "height", "expr" => ["term" => {"length" => 29.7}]}]], "media_rules" => ["at_rule" => {"page_declarations" => ["declaration" => {"property" => {"ident" => "margin"}, "expr" => ["term" => {"length" => 3}]}]}]};

for (
    at_rule   => {input => '@media all { body { background:lime } }',
                  ast => {"media_list" => ["media_query" => {"media_type" => "all"}],
                          "media_rules" => ["ruleset" => {"selectors" => ["selector" => ["simple_selector" => ["element_name" => "body"]]],
                                                          "declarations" => ["declaration" => {"property" => {"ident" => "background"}, "expr" => ["term" => {"ident" => "lime"}]}]}]},
    },
    at_rule => {input => '@media all and (color) { }',
                ast => {"media_list" => ["media_query" => ["media_type" => "all", "media_expr" => {"media_feature" => "color"}]], "media_rules" => []},
    },
    at_rule => {input => '@media all and (min-color: 2) { }',
                ast => {"media_list" => ["media_query" => ["media_type" => "all", "media_expr" => {"media_feature" => "min-color", "expr" => ["term" => {"num" => 2}]}]], "media_rules" => []},
    },
    at_rule => {input => '@media not print {body{margin: 1cm}}',
                ast => {"media_list" => ["media_query" => ["media_op" => "not", "media_type" => "print"]], "media_rules" => ["ruleset" => {"selectors" => ["selector" => ["simple_selector" => ["element_name" => "body"]]], "declarations" => ["declaration" => {"property" => {"ident" => "margin"}, "expr" => ["term" => {"length" => 1}]}]}]},
    },
    # forgetting to enclose sub-rule
     at_rule => {input => '@media not print {body{margin: 1cm}}',
                 ast => {"media_list" => ["media_query" => ["media_op" => "not", "media_type" => "print"]], "media_rules" => ["ruleset" => {"selectors" => ["selector" => ["simple_selector" => ["element_name" => "body"]]], "declarations" => ["declaration" => {"property" => {"ident" => "margin"}, "expr" => ["term" => {"length" => 1}]}]}]},
    },
    at_rule => {input => $embedded_page, ast => $embedded_page_ast},
    ) {
    my $rule = $_.key;
    my %test = $_.value;
    my $input = %test<input>;

    $css_actions.warnings = ();
    my $p3 = t::CSS3::MediaGrammar.parse( $input, :rule($rule), :actions($css_actions));
    t::CSS::parse_tests($input, $p3, :rule($rule), :compat('css3 @media'),
                         :warnings($css_actions.warnings),
                         :expected(%test) );
}

done;
