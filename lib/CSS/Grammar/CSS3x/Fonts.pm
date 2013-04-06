use v6;

# CSS3 Font Extension Module
# specification: http://www.w3.org/TR/2013/WD-css3-fonts-20130212/
#
# nb this standard is under revision (as of Feb 2013). Biggest change
# is the proposed at-rule @font-feature-values

grammar CSS::Grammar::CSS3x::Fonts:ver<20130212.000> {
    rule at_rule:sym<font_face> {(:i'font-face') <declarations> }

    # functions
    # ---------
    rule function:sym<fmt-or-loc> {:i(format|local)'(' [ <string> || <bad_args> ] ')'}
}

class CSS::Grammar::CSS3x::Fonts::Actions {
    method at_rule:sym<font_face>($/) { make $.at_rule($/) }

    method function:sym<fmt-or-loc>($/) {
        my $func = $0.Str.lc;
        return $.warning("usage: $func(<string>)")
            if $<bad_args>;

        make {ident => $func, args => $.list($/)}
    }

}

