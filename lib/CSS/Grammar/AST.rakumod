unit class CSS::Grammar::AST;

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
    $type = $_ with CSSUnits.enums{$type};

    my $raw-type = $type.split(':').head;
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
    my @l = $/.isa(Capture)
        ?? $/
        !! $/.grep: *.defined;

    for @l {
        for .caps -> $cap {
            my ($key, $value) = $cap.kv;
            next if $key eq '0';
            $key .= lc;
            my $type = $key.split(':').head;

            $value .= ast
                // next;

            if $key.starts-with('expr-') {
                $key.substr-rw(4,1) = ':';
            }
            elsif $value.isa(Pair) {
                ($key, $value) = $value.kv;
            }
            elsif %known-type{$type}:!exists {
                warn "{$value.perl} has unknown type: $type";
            }

            if %terms{$key}:exists {
                warn "repeated term " ~ $key ~ ':' ~ $value;
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
        ?? $/
        !! $/.grep: *.defined;

    for @l {
        for .caps -> $cap {
            my ($key, $value) = $cap.kv;
            next if $key eq '0';
            $key .= lc;

            my $type = $key.split(':').head;

            $value .= ast
                // next;

            if $key.starts-with('expr-') {
                $key.substr-rw(4,1) = ':';
            }
            elsif $value.isa(Pair) {
                ($key, $value) = $value.kv;
            }
            elsif %known-type{$type}:!exists {
                warn "{$value.raku} has unknown type: $type";
            }

            push( @terms, {$key => $value} );
        }
    }

    @terms;
}

method at-rule($/) {
    my %terms = $.node($/);
    %terms{ CSSValue::AtKeywordComponent } //= $0.lc;
    return $.token( %terms, :type(CSSObject::AtRule));
}

method func(Str:D $ident,
            $args,
            :$type     = CSSValue::FunctionComponent,
            :$arg-type = CSSValue::ArgumentListComponent,
            |c --> Pair) {
    my %ast = $args.isa(List)
        ?? ($arg-type => $args)
        !! $args;
    %ast ,= :$ident;
    $.token( %ast, :$type, |c );
}

method pseudo-func( Str $ident, $/ --> Pair) {
    my $expr = $.list($/);
    my %ast = :$ident, :$expr;
    $.token( %ast, :type(CSSSelector::PseudoFunction) );
}

method decl($/, :$obj!) {

    my %ast;

    %ast<ident> = .trim.lc
        with $0;

    with $<val> {
        my Hash $val = .ast;

        with $val<usage> -> $synopsis {
            my $usage = 'usage ' ~ $synopsis;
            $usage ~= ' | ' ~ $_
                for @.proforma;
            $obj.warning($usage);
            return;
        }
        elsif ! $val<expr> {
            $obj.warning('dropping declaration', %ast<ident>);
            return;
        }
        else {
            %ast<expr> = $val<expr>;
        }
    }

    return %ast;
}

method rule($/) {
    $.node($/).pairs[0];
}

method proforma { [] }
