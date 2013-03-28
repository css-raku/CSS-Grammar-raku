use v6;

# specification: http://www.w3.org/TR/2011/REC-CSS2-20110607/propidx.html

grammar CSS::Grammar::CSS21::Properties:ver<20110607.000> {

    token inherit {:i inherit}

    rule prop:sym<azimuth> {:i (azimuth) ':' [
                                 <angle>
                                 | [[$<lr>=[ left\-side | far\-left | left | center\-left | center | center\-right | right | far\-right | right\-side ] $<bh>='behind'? | $<bh>=behind ]]
                                 | $<delta>=[$<dl>=leftwards | $<dr>=rightwards]
                                 | <inherit> || <bad_args> ]}

    rule prop:sym<elevation> {:i (elevation) ':' [
                                   <angle>
                                   | $<tilt>=[below | level | above]
                                   | $<delta>=[ $<dh>=higher | $<dl>=lower ]
                                   | <inherit> || <bad_args> ]}

    rule prop:sym<background-attachment> {:i (background\-attachment) ':' [
                                               [ scroll | fixed ] & <ident>
                                               | <inherit> || <bad_args> ]}

    rule prop:sym<background-color> {:i (background\-color) ':' [
                                          <color>
                                          | [ fixed & <ident> ]
                                          | <inherit> || <bad_args> ]}

    rule prop:sym<background-image> {:i (background\-image) ':' [
                                          <uri>
                                          | [ fixed & <ident> ]
                                          | <inherit> || <bad_args> ]}
    #...
    # font-style - inherited from css1    
}

class CSS::Grammar::CSS21::Properties::Actions {

    method inherit($/) {make True }

    method _make_prop($/, $synopsis) {
        my $property = $0.Str.trim.lc;

        return $.warning('usage ' ~ $property ~ ': ' ~ $synopsis)
            if $<bad_args>;

        my @ast = $.list($/);

        make ($property => @ast);
     }

    method prop:sym<azimuth>($/) {
        # see http://www.w3.org/TR/2011/REC-CSS2-20110607/aural.html

        return $.warning('usage azimuth: <angle> | [[ left-side | far-left | left | center-left | center | center-right | right | far-right | right-side ] || behind ] | leftwards | rightwards | inherit')
            if $<bad_args>;

        my %ast;

        if $<angle> {
            %ast<angle> = $<angle>.ast;
        }
        elsif $<lr> || $<bh> {

            state %angles = (
                'left-side'    => [270, 270],
                'far-left'     => [300, 240],
                'left'         => [320, 220],
                'center-left'  => [340, 200],
                'center'       => [0,   180],
                'center-right' => [20,  160],
                'right'        => [40,  140],
                'far-right'    => [60,  120],
                'right-side'   => [90,  90],
                'behind'       => [180, 180],
            );

            my $keyw = $<lr>.Str.trim.lc || 'behind';
            my $bh = $<bh>.Str ?? 1 !! 0;

            %ast<angle> = $.token(%angles{$keyw}[$bh], :type('angle'), :units('degrees') );
        }
        elsif $<delta> {
            my $delta_angle = $<dl> ?? -20 !! 20;
            %ast<delta> = $.token($delta_angle, :type('angle'), :units('degrees') );
        }
        elsif $<inherit> {
            %ast<inherit> = True;
        }

        my $property = $0.Str.trim.lc;
        make ($property => %ast);
    }

    method prop:sym<elevation>($/) {
        # see http://www.w3.org/TR/2011/REC-CSS2-20110607/aural.html

        return $.warning('usage elevation: <angle> | below | level | above | higher | lower | inherit')
            if $<bad_args>;

        my %ast;

        if $<angle> {
            %ast<angle> = $<angle>.ast;
        }
        elsif $<tilt> {

            state %angles = (
                'below'    => -90,
                'level'    =>   0,
                'above'    =>  90,
            );

            my $keyw = $<tilt>.Str.trim.lc;
            %ast<angle> = $.token(%angles{$keyw}, :type('angle'), :units('degrees') );
        }
        elsif $<delta> {
            my $delta_angle = $<dl> ?? -10 !! 10;
            %ast<delta> = $.token($delta_angle, :type('angle'), :units('degrees') );
        }
        elsif $<inherit> {
            %ast<inherit> = True;
        }

        my $property = $0.Str.trim.lc;
        make ($property => %ast);
    }

    method prop:sym<background-attachment>($/) {
        $._make_prop($/, 'scroll | fixed | inherit');
    };

    method prop:sym<background-color>($/) {
        $._make_prop($/, '<color> | transparent | inherit')
    };

    method prop:sym<background-image>($/) {
        $._make_prop($/, '<uri> | none | inherit')
    };
}
