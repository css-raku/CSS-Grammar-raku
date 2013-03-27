use v6;

# specification: http://www.w3.org/TR/2011/REC-CSS2-20110607/propidx.html

grammar CSS::Grammar::CSS21::Properties:ver<20110607.000> {

    token inherit {:i inherit}

    rule prop:sym<azimuth> {:i (azimuth) ':' [
                                 $<ok>=[<angle>
                                        | [[$<lr>=[ left\-side | far\-left | left | center\-left | center | center\-right | right | far\-right | right\-side ] $<bh>='behind'? | $<bh>=behind ]]
                                        | $<delta>=[$<dl>=leftwards | $<dr>=rightwards]
                                        | <inherit> ]
                                 || <any>* ] }

    rule prop:sym<elevation> {:i (elevation) ':' [
                                 $<ok>=[ <angle>
                                         | $<tilt>=[below | level | above]
                                         | $<delta>=[ $<dh>=higher | $<dl>=lower ]
                                         | <inherit> ]
                                 || <any>* ] }

    rule prop:sym<background-attachment> {:i (background\-attachment) ':' [
                                               $<ok>=[scroll | fixed | inherit]
                                               || <any>* ] }
    #...
    # font-style - inherited from css1    
}

class CSS::Grammar::CSS21::Properties::Actions {

    method prop:sym<azimuth>($/) {
        # see http://www.w3.org/TR/2011/REC-CSS2-20110607/aural.html

        return $.warning('usage azimuth: <angle> | [[ left-side | far-left | left | center-left | center | center-right | right | far-right | right-side ] || behind ] | leftwards | rightwards | inherit')
            unless $<ok>;

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

        make %ast;
    }

    method prop:sym<elevation>($/) {
        # see http://www.w3.org/TR/2011/REC-CSS2-20110607/aural.html

        return $.warning('usage elevation: <angle> | below | level | above | higher | lower | inherit')
            unless $<ok>;

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

        make %ast;
    }

    method prop:sym<background-attachment>($/) {
        return $.warning('usage background-attachment: scroll | fixed | inherit')
            unless $<ok>;
        make $<ok>.Str.trim.lc
    };
}
