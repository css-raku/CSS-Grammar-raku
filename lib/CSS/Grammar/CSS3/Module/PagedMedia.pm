use v6;

# CSS3 Paged Media Module Extensions
# - reference: http://www.w3.org/TR/2006/WD-css3-page-20061010/
#

grammar CSS::Grammar::CSS3::Module::PagedMedia:ver<20061010.000> {

    proto rule page-pseudo {*}
    rule page-pseudo:sym<left>    {:i'left'}
    rule page-pseudo:sym<right>   {:i'right'}
    rule page-pseudo:sym<first>   {:i'first'}
    rule page-pseudo:sym<other>   {<ident>}
    rule page-pseudo:sym<missing> {''}

    rule at_rule:sym<page>  {(:i'page') [\:<page=.page-pseudo>]? <declarations=.page-declarations> }

    rule page-declarations {
        '{' [ '@'<declaration=.margin-declaration> | <declaration> || <dropped_decl> ]* <.end_block>
    }

    token box-hpos   {:i[left|right]}
    token box-vpos   {:i[top|bottom]}
    token box-center {:i[cent[er|re]]}
    token margin-box{:i[<box-hpos>'-'[<box-vpos>['-corner']?|<box-center>]
                      |<box-vpos>'-'[<box-hpos>['-corner']?|<box-center>]]}
    rule margin-declaration { <margin-box> <declarations> }

}

class CSS::Grammar::CSS3::Module::PagedMedia::Actions {

    method page-pseudo:sym<left>($/)  {make 'left'}
    method page-pseudo:sym<right>($/) {make 'right'}
    method page-pseudo:sym<first>($/) {make 'first'}
    method page-pseudo:sym<other>($/) {$.warning('ignoring page pseudo', $/.Str)}
    method page-pseudo:sym<missing>($/) {$.warning("':' should be followed by one of: left right first")}

    method page-declarations($/) { make $.declaration_list($/) }

    method box-hpos($/)   { make $/.Str.lc }
    method box-vpos($/)   { make $/.Str.lc }
    method box-center($/) { make 'center' }
    method margin-box($/) { make $.node($/) }

    method margin-declaration($/) {
        my %ast = $.node($/);
        %ast<property> = '@' ~ $<margin-box>.Str.lc;
        make %ast;
    }
}
