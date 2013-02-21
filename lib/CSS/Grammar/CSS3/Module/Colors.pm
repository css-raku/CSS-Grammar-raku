grammar CSS::Grammar::CSS3::Module::Colors {

# extensions for CSS3 Color Module
# - see http://www.w3.org/TR/css3-color/#hsla-color
# Note: plain rgb() is included in the CSS3 core

    rule color_rgba {:i'rgba('
                   [<r=.percentage>|<r=.num>] ','
                   [<g=.percentage>|<g=.num>] ','
                   [<b=.percentage>|<b=.num>] ','
                   [<a=.percentage>|<a=.num>]
                   [')' | <unclosed_paren>]
    }

    rule color_hsl {:i'hsl('
                   [<h=.percentage>|<h=.num>] ','
                   [<s=.percentage>|<s=.num>] ','
                   [<l=.percentage>|<l=.num>]
                   [')' | <unclosed_paren>]
    }

    rule color_hsla {:i'hsla('
                   [<h=.percentage>|<h=.num>] ','
                   [<s=.percentage>|<s=.num>] ','
                   [<l=.percentage>|<l=.num>] ','
                   [<a=.percentage>|<a=.num>]
                   [')' | <unclosed_paren>]
    }

    rule _term:sym<color_rgba>     {<color_rgba>}
    rule _term:sym<color_hsl>      {<color_hsl>}
    rule _term:sym<color_hsla>     {<color_hsla>}
}

class CSS::Grammar::CSS3::Module::Colors::Actions {
    method color_rgba($/) { make $.node($/) }
    method color_hsl($/)  { make $.node($/) }
    method color_hsla($/) { make $.node($/) }

    method _term:sym<color_rgba>($/) { make $.node($/) }
    method _term:sym<color_hsl>($/)  { make $.node($/) }
    method _term:sym<color_hsla>($/) { make $.node($/) }
}

