use v6;

# CSS3 Paged Media Module Extensions
# - reference: http://www.w3.org/TR/2006/WD-css3-page-20061010/
#

grammar CSS::Grammar::CSS3::Module::PagedMedia:ver<20061010.000> {

    proto rule page_pseudo {<...>}
    rule page_pseudo:sym<left>    {:i'left'}
    rule page_pseudo:sym<right>   {:i'right'}
    rule page_pseudo:sym<first>   {:i'first'}
    rule page_pseudo:sym<other>   {<ident>}
    rule page_pseudo:sym<missing> {''}

    rule at_rule:sym<page>  { \@(:i'page') [\:<page_pseudo>]? <page_declarations> }

    rule page_declarations {
        '{' [<page_box> | <declaration>] [';' [<page_box> | <declaration>]]* ';'? <end_block>
    }

    rule page_box {
        '@'<page_pos> <declarations>
    }

    token page_pos {<hpos>'-'[<vpos>'-corner'?|<center>]
                   |<vpos>'-'[<hpos>'-corner'?|<center>]
                   }

    token hpos   {:i[left|right]}
    token vpos   {:i[top|bottom]}
    token center {:i[cent[er|re]]}
}

class CSS::Grammar::CSS3::Module::PagedMedia::Actions {

    method at_rule:sym<page>($/) { make $.node($/) }
    method page_pseudo:sym<left>($/) {make 'left'}
    method page_pseudo:sym<right>($/) {make 'right'}
    method page_pseudo:sym<first>($/) {make 'first'}
    method page_pseudo:sym<other>($/) {$.warning('ignoring page pseudo', $/.Str)}
    method page_pseudo:sym<missing>($/) {$.warning("':' should be followed by one of: left right first")}

    method page_box($/) { make $.node($/) }
    method page_declarations($/) { make $.list($/) }

    method page_pos($/) {
       my %pos;
       %pos<hpos> = $<hpos> ?? $<hpos>.Str.lc !! 'center';
       %pos<vpos> = $<vpos> ?? $<vpos>.Str.lc !! 'center';
       make %pos;
    }
}



