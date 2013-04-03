#!/usr/bin/env perl6

use Test;

use CSS::Grammar;
use CSS::Grammar::CSS3;
use CSS::Grammar::Actions;
use CSS::Grammar::CSS3::Module::PagedMedia;

# prepare our own composite class with paged media extensions

grammar t::CSS3::PagedMediaGrammar
    is CSS::Grammar::CSS3::Module::PagedMedia
    is CSS::Grammar::CSS3
    {};

class t::CSS3::PagedMediaActions
    is CSS::Grammar::CSS3::Module::PagedMedia::Actions
    is CSS::Grammar::Actions
    {};

use lib '.';
use t::AST;

my $css_actions = t::CSS3::PagedMediaActions.new;

my $top_center = 'page { color: red;
        @top-center {
           content: "Page " counters(page,".");
       }
}';

my $top_center_ast = {"declarations" => {"color" => {"expr" => ["term" => "red"]},
                                         "\@top-center" => {"margin-box" => {"box-vpos" => "top",
                                                                             "box-center" => "center"},
                                                            "declarations" => {"content" => {"expr" => ["term" => "Page ", "term" => {"ident" => "counters", "args" => ["ident" => "page", "string" => "."]}]}}}}, "\@" => "page"};

for (
    at_rule   => {input => 'page :left { margin-left: 4cm; }',
                  ast => {"page" => "left", "declarations" => {"margin-left" => {"expr" => ["term" => 4e0]}}, "\@" => "page"},
    },
    at_rule   => {input => 'page :junk { margin-right: 2cm }',
                  ast => {"declarations" => {"margin-right" => {"expr" => ["term" => 2e0]}}, "\@" => "page"},
                  warnings => 'ignoring page pseudo: junk',
    },
    at_rule   => {input => 'page : { margin-right: 2cm }',
                  ast => Mu,
                  warnings => "':' should be followed by one of: left right first",
    },
    'page-declarations' => {input => '{@bottom-right-CorNeR {color:blue}}',
                 ast => {"\@bottom-right-corner" => {"margin-box" => {"box-vpos" => "bottom",
                                                                      "box-hpos" => "right"},
                                                     "declarations" => {"color" => {"expr" => ["term" => "blue"]}}}},
    },
    'page-declarations' => {input => '{ @Top-CENTER {content: "Page " counters(page);} }',
                 ast => {"\@top-center" => {"margin-box" => {"box-vpos" => "top", "box-center" => "center"},
                                           "declarations" => {"content" => {"expr" => ["term" => "Page ", "term" => {"ident" => "counters", "args" => ["ident" => "page"]}]}}}},
    },
    at_rule => {input => $top_center, ast => $top_center_ast},
    ) {
    my $rule = $_.key;
    my %test = $_.value;
    my $input = %test<input>;
note $input;
    $css_actions.reset;
    my $p3 = t::CSS3::PagedMediaGrammar.parse( $input, :rule($rule), :actions($css_actions));
    t::AST::parse_tests($input, $p3, :rule($rule), :suite('css3 @page'),
                         :warnings($css_actions.warnings),
                         :expected(%test) );
}

done;
