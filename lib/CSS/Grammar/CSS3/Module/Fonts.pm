use v6;

# CSS3 Font Module Extensions
# - see http://www.w3.org/TR/css3-fonts/
#
# nb this standard is under revision (as of Feb 2013). Biggest change
# is the proposed at-rule @font-feature-values

grammar CSS::Grammar::CSS3::Module::Fonts {
    rule at_rule:sym<font_face> { \@(:i'font-face') <declarations> }
}

class CSS::Grammar::CSS3::Module::Fonts::Actions {
    method at_rule:sym<font_face>($/) { make $.node($/) }
}

