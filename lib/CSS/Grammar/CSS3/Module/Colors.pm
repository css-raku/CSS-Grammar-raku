use v6;

# CSS3 Color Module Extensions
# specification: http://www.w3.org/TR/2011/REC-css3-color-20110607/

grammar CSS::Grammar::CSS3::Module::Colors:ver<20110607.000> {

# extensions and at rules for CSS3 Color Module

    rule at_rule:sym<color_profile> { \@(:i'color-profile') <declarations> }

    # color_rgb and color_hex are defined in CSS core grammar

    rule color_rgba {:i'rgba('
                   <r=.color_arg> ','
                   <g=.color_arg> ','
                   <b=.color_arg> ','
                   <a=.color_arg>
                   [')' | <unclosed_paren>]
    }

    rule color_hsl {:i'hsl('
                   <h=.color_arg> ','
                   <s=.color_arg> ','
                   <l=.color_arg>
                   [')' | <unclosed_paren>]
    }

    rule color_hsla {:i'hsla('
                   <h=.color_arg> ','
                   <s=.color_arg> ','
                   <l=.color_arg> ','
                   <a=.color_arg>
                   [')' | <unclosed_paren>]
    }

    rule aterm:sym<color_rgb>     {<color_rgb>}
    rule aterm:sym<color_hex>     {<id>}
    rule aterm:sym<color_rgba>    {<color_rgba>}
    rule aterm:sym<color_hsl>     {<color_hsl>}
    rule aterm:sym<color_hsla>    {<color_hsla>}
}

class CSS::Grammar::CSS3::Module::Colors::Actions {

    method at_rule:sym<color_profile>($/) { make $.at_rule($/) }

    # color_rgb is defined in core actions
    method color_rgba($/) { make $.node($/) }
    method color_hsl($/)  { make $.node($/) }
    method color_hsla($/) { make $.node($/) }

    method aterm:sym<color_rgba>($/) { make $.token($<color_rgba>.ast, :type('color'), :units('rgba')) }
    method aterm:sym<color_hsl>($/)  { make $.token($<color_hsl>.ast, :type('color'), :units('hsl')) }
    method aterm:sym<color_hsla>($/) { make $.token($<color_hsla>.ast, :type('color'), :units('hsla')) }
}

