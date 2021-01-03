use v6;

class CSS::Grammar::AST {

    use CSS::Grammar::Defs :CSSObject, :CSSValue, :CSSSelector, :CSSUnits, :CSSTrait;

    # re-exports (may be deprecated)
    constant css-obj is export(:CSSObject) = CSSObject;
    constant css-val is export(:CSSObject) = CSSValue;
    constant css-sel is export(:CSSSelector) = CSSValue;
    constant css-units is export(:CSSUnits) = CSSUnits;
    constant css-trait is export(:CSSTrait) = CSSTrait;

BEGIN our %known-type =
    %( CSSObject.enums.invert ),
    %( CSSValue.enums.invert ),
    %( CSSSelector.enums.invert ),
    ;


    #| utility token builder method, e.g.: $.token(42, :type<cm>)  -->   :cm(42)
    method token(Mu $ast, Str :$type is copy) {

        die 'usage: $.token($ast, :$type)'
            unless $type;

        return unless $ast.defined;

        my Str $units = $type;
	$type = CSSUnits.enums{$type}
	    if CSSUnits.enums{$type}:exists;

	my ($raw-type, $_class) = $type.split(':');
	die "unknown type: '$raw-type'"
	    unless %known-type{$raw-type}:exists;

        $ast.isa(Pair)
            ?? ($units => $ast.value)
	    !! ($units => $ast);
    }

    #| utility AST builder method for leaf nodes (no repeated tokens)
    method node($/ --> Hash) {
        my %terms;

        # unwrap Parcels
        my @l = $/.can('caps')
            ?? ($/)
            !! $/.grep: *.defined;

        for @l {
            for .caps -> $cap {
                my ($key, $value) = $cap.kv;
                next if $key eq '0';
                $key = $key.lc;
                my ($type, $_class) = $key.split(':');

                $value = $value.ast
                    // next;

                if substr($key, 0, 5) eq 'expr-' {
                    $key = 'expr:' ~ substr($key, 5);
                }
                elsif $value.isa(Pair) {
                    ($key, $value) = $value.kv;
                }
                elsif %known-type{$type}:!exists {
                    warn "{$value.perl} has unknown type: $type";
                }

                if %terms{$key}:exists {
                    $.warning("repeated term " ~ $key, $value);
                    return Any;
                }

                %terms{$key} = $value;
            }
        }

        %terms;
    }

    #| utility AST builder method for nodes with repeatable elements
    method list($/ --> Array) {
        my @terms;

        # unwrap Parcels
        my @l = $/.can('caps')
            ?? ($/)
            !! $/.grep: *.defined;

        for @l {
            for .caps -> $cap {
                my ($key, $value) = $cap.kv;
                next if $key eq '0';
                $key = $key.lc;

                my ($type, $_class) = $key.split(':');

                $value = $value.ast
                    // next;

                if substr($key, 0, 5) eq 'expr-' {
                    $key = 'expr:' ~ substr($key, 5);
                }
                elsif $value.isa(Pair) {
                    ($key, $value) = $value.kv;
                }
                elsif %known-type{$type}:!exists {
                    warn "{$value.perl} has unknown type: $type";
                }

                push( @terms, {$key => $value} );
            }
        }

        @terms;
    }

}
