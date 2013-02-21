grammar CSS::Grammar::CSS3::Module::Fonts {
    rule at_rule:sym<font_face> { \@(:i'font-face') <declarations> }
}

class CSS::Grammar::CSS3::Module::Fonts::Actions {
    method at_rule:sym<font_face>($/) { make $.node($/) }
}

