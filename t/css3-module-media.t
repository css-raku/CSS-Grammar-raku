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
use t::AST;

my $css_actions = t::CSS3::MediaActions.new;

my $embedded_page = 'media print and (width: 21cm) and (height: 29.7cm) {
      @page { margin: 3cm; }
   }';

my $embedded_page_ast = {"media_list" => ["media_query" => ["media" => "print",
                                                            "media_expr" => {"media_feature" => "width", "expr" => ["term" => 21]},
                                                            "media_expr" => {"media_feature" => "height", "expr" => ["term" => 29.7]}]],
                         "media_rules" => ["at_rule" => {"declarations" => {"margin" => {"expr" => ["term" => 3]}}},
                                           '@' => "page"],
                         '@' => "media"};

for (
    term      => {input => '300dpi', ast => 300, token => {type => 'resolution', units => 'dpi'}},
    at_rule   => {input => 'media all { body { background:lime } }',
                  ast => {"media_list" => ["media_query" => ["media" => "all"]], "media_rules" => ["ruleset" => {"selectors" => ["selector" => ["simple_selector" => ["element_name" => "body"]]], "declarations" => {"background" => {"expr" => ["term" => "lime"]}}}], '@' => "media"},
    },
    at_rule => {input => 'media all and (color) { }',
                ast => {"media_list" => ["media_query" => ["media" => "all", "media_expr" => {"media_feature" => "color"}]], "media_rules" => [], '@' => "media"},
    },
    at_rule => {input => 'media all and (min-color: 2) { }',
                ast => {"media_list" => ["media_query" => ["media" => "all", "media_expr" => {"media_feature" => "min-color", "expr" => ["term" => 2]}]], "media_rules" => [], '@' => "media"},
    },
    # try out dpi and dpcm term extensions
    at_rule => {input => 'media all AND (min-resolution: 300dpi) And (min-resolution: 118dpcm) {}',
                ast => {"media_list" => ["media_query" => ["media" => "all", "media_expr" => {"media_feature" => "min-resolution", "expr" => ["term" => 300]}, "media_expr" => {"media_feature" => "min-resolution", "expr" => ["term" => 118]}]], "media_rules" => [], '@' => "media"},
    },
    at_rule => {input => 'media noT print {body{margin : 1cm}}',
                ast => {"media_list" => ["media_query" => ["media_op" => "not", "media" => "print"]], "media_rules" => ["ruleset" => {"selectors" => ["selector" => ["simple_selector" => ["element_name" => "body"]]], "declarations" => {"margin" => {"expr" => ["term" => 1e0]}}}], "\@" => "media"},
    },
    at_rule => {input => 'media ONLY all And (none) { }',
                ast => {"media_list" => ["media_query" => ["media_op" => "only", "media" => "all", "media_expr" => {"media_feature" => "none"}]], "media_rules" => [], '@' => "media"},
    },
    # we should also have extended the import at-rule
    import => {input => '@import url(example.css) screen and (color), projection and (color);',
               ast => {"url" => "example.css",
                       "media_list" => ["media_query" => ["media" => "screen", "media_expr" => {"media_feature" => "color"}],
                                        "media_query" => ["media" => "projection", "media_expr" => {"media_feature" => "color"}]]},
    },
    at_rule => {input => $embedded_page, ast => $embedded_page_ast},
    ) {
    my $rule = $_.key;
    my %test = $_.value;
    my $input = %test<input>;

    $css_actions.reset;
    my $p3 = t::CSS3::MediaGrammar.parse( $input, :rule($rule), :actions($css_actions));
    t::AST::parse_tests($input, $p3, :rule($rule), :suite('css3 @media'),
                         :warnings($css_actions.warnings),
                         :expected(%test) );
}

done;
