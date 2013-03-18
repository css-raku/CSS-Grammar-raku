use v6;

# CSS3 Color Module Extensions
# specification: http://www.w3.org/TR/2011/REC-css3-color-20110607/

grammar CSS::Grammar::CSS3::Module::Colors:ver<20110607.000> {

# extensions and at rules for CSS3 Color Module

    rule at_rule:sym<color_profile> {(:i'color-profile') <declarations> }

    # color_rgb and color_hex are defined in CSS core grammar
    rule color_angle{<num>$<percentage>=[\%]?}
    rule color_alpha{<num>$<percentage>=[\%]?}

    rule color:sym<rgba> {:i'rgba('
                   <r=.color_arg> ','
                   <g=.color_arg> ','
                   <b=.color_arg> ','
                   <a=.color_alpha>
                   [')' | <unclosed_paren>]
    }

    rule color:sym<hsl> {:i'hsl('
                   <h=.color_angle> ','
                   <s=.color_alpha> ','
                   <l=.color_alpha>
                   [')' | <unclosed_paren>]
    }

    rule color:sym<hsla> {:i'hsla('
                   <h=.color_angle> ','
                   <s=.color_alpha> ','
                   <l=.color_alpha> ','
                   <a=.color_alpha>
                   [')' | <unclosed_paren>]
    }
}

class CSS::Grammar::CSS3::Module::Colors::Actions {

    method at_rule:sym<color_profile>($/) { make $.at_rule($/) }

    method color_angle($/) {
        my $angle = %<num>.ast;
        $angle = ($angle * 3.6).round
            if $<percentage>.Str;
        make $.token($angle, :type('num'), :units('degrees'));
    }

    method color_alpha($/) {
        my $alpha = %<num>.ast;
        $alpha = ($alpha / 100)
            if $<percentage>.Str;
        make $.token($alpha, :type('num'), :units('alpha'));
    }

    method color:sym<rgba>($/) { make (rgba => $.node($/)) }
    method color:sym<hsl>($/)  { make (hsl  => $.node($/)) }
    method color:sym<hsla>($/) { make (hsla => $.node($/)) }
}

