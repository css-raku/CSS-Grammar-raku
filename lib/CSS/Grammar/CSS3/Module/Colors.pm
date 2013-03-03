use v6;

# CSS3 Color Module Extensions
# specification: http://www.w3.org/TR/2011/REC-css3-color-20110607/

grammar CSS::Grammar::CSS3::Module::Colors:ver<20110607.000> {

# extensions for CSS3 Color Module

    # color_rgb and color_hex are defined in CSS core grammar

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

    rule aterm:sym<color_rgb>     {<color_rgb>}
    rule aterm:sym<color_hex>     {<id>}
    rule aterm:sym<color_rgba>    {<color_rgba>}
    rule aterm:sym<color_hsl>     {<color_hsl>}
    rule aterm:sym<color_hsla>    {<color_hsla>}
}

class CSS::Grammar::CSS3::Module::Colors::Actions {
    # color_rgb is defined in core actions
    method color_rgba($/) { make $.node($/) }
    method color_hsl($/)  { make $.node($/) }
    method color_hsla($/) { make $.node($/) }

    method aterm:sym<color_rgb>($/)  { make $.node($/) }
    method aterm:sym<color_rgba>($/) { make $.node($/) }
    method aterm:sym<color_hsl>($/)  { make $.node($/) }
    method aterm:sym<color_hsla>($/) { make $.node($/) }
}

