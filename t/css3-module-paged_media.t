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
use t::CSS;

my $css_actions = t::CSS3::PagedMediaActions.new;

my $top_center = '
@page { color: red;
        @top-center {
           content: "Page " counter(page);
       }
}';

my $top_center_ast = {
    "declarations" => ["declaration" => {"property" => "color",
                                         "expr" => ["term" => "red"]},
                       "page_rules" => {"margin_box" => {"hpos" => "center", "vpos" => "top"},
                                        "declarations" => ["declaration" => {"property" => "content",
                                                                             "expr" => ["term" => "Page ",
                                                                                        "term" => {"ident" => "counter", "expr" => ["term" => "page"]}]}]}],
    "\@" => "page"};

for (
    at_rule   => {input => '@page :left { margin-left: 4cm; }',
                  ast => {"page" => "left", "declarations" => ["declaration" => {"property" => "margin-left", "expr" => ["term" => 4]}], '@' => "page"},
    },
    at_rule   => {input => '@page :junk { margin-right: 2cm }',
                  ast => {"declarations" => ["declaration" => {"property" => "margin-right", "expr" => ["term" => 2]}], '@' => "page"},
                  warnings => 'ignoring page pseudo: junk',
    },
    at_rule   => {input => '@page : { margin-right: 2cm }',
                  ast => Mu,
                  warnings => "':' should be followed by one of: left right first",
    },
    margin_box => {input => 'top-left', ast => {hpos => 'left', vpos => 'top'}},
    margin_box => {input => 'top-center', ast => {hpos => 'center', vpos => 'top'}},
    margin_box => {input => 'RIGHT-TOP', ast => {hpos => 'right', vpos => 'top'}},
    margin_box => {input => 'bottom-left-corner', ast => {hpos => 'left', vpos => 'bottom'}},
    margin_box => {input => 'bottom-right', ast => {hpos => 'right', vpos => 'bottom'}},
    page_rules => {input => '@bottom-right {color:blue}',
                 ast => {"margin_box" => {"hpos" => "right", "vpos" => "bottom"},
                         "declarations" => ["declaration" => {"property" => "color", "expr" => ["term" => "blue"]}]},
    },
    page_rules => {input => '@top-center {content: "Page " counter(page);}',
                 ast => {"margin_box" => {"hpos" => "center", "vpos" => "top"},
                         "declarations" => ["declaration" => {"property" => "content", "expr" => ["term" => "Page ", "term" => {"ident" => "counter", "expr" => ["term" => "page"]}]}]},
    },
    at_rule => {input => $top_center, ast => $top_center_ast},
    ) {
    my $rule = $_.key;
    my %test = $_.value;
    my $input = %test<input>;

    $css_actions.warnings = ();
    my $p3 = t::CSS3::PagedMediaGrammar.parse( $input, :rule($rule), :actions($css_actions));
    t::CSS::parse_tests($input, $p3, :rule($rule), :compat('css3 @page'),
                         :warnings($css_actions.warnings),
                         :expected(%test) );
}

done;
