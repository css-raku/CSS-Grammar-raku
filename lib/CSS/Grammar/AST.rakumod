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
multi method token(Mu:D $ast, Str:D :$type!) {
    given CSSUnits.enums{$type} // $type.split(':').head -> $base-type {
        die "unknown type: '$base-type'"
            unless %known-type{$base-type}:exists;
    }

    $type => $ast.isa(Pair) ?? $ast.value !! $ast;
}
multi method token(Mu:U) { }

method !terms($/ --> Array) {
    my @terms;
    my %glob;
    # unwrap Parcels
    my @l = $/.isa(Capture)
        ?? $/
        !! $/.grep(Capture:D);

    for @l {
        for .caps -> Pair:D $_ {
            my $key = .key.lc;
            next if $key eq '0';

            if $key.starts-with('css-val-') {
                my $prop = $key.substr(8);
                my $value = $.list(.value);
                with %glob{$prop} {
                    .push: @terms.pop
                        if @terms.tail.key eq 'op';
                    .append: (@$value);
                }
                else {
                    $_ = $value; # start globbing
                    @terms.push:  'expr:'~$prop => $value;
                }
            }
            else {
                my $value = .value.ast // next;
                if $key.starts-with('expr-') {
                    $key = 'expr:' ~ $key.substr(4);
                }
                elsif $value.isa(Pair) {
                    ($key, $value) = $value.kv;
                }
                else {
                    given $key.split(':').head -> $type {
                        warn "{$value.raku} has unknown type: $type"
                            unless %known-type{$type}:exists;
                    }
                }

                @terms.push: $key => $value;
            }
        }
    }

    @terms;
}

#| utility AST builder method for leaf nodes (no repeated tokens)
method node($/ --> Hash) {
    self!terms($/).Hash;
}

#| utility AST builder method for nodes with repeatable elements
method list($/) {
    [ self!terms($/).map: *.Hash ];
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
    my @expr := self!terms($/);
    my %ast = :$ident, :@expr;
    $.token( %ast, :type(CSSSelector::PseudoFunction) );
}

method decl($/, :$obj!) {

    my %ast;
    my $prop-name;
    with $0 {
        $prop-name = .trim.lc;
        %ast<ident> = $prop-name;
    }
    with $<val> {
        my %val = .ast;
        with %val<usage> -> $synopsis {
            my $usage = 'usage ' ~ $synopsis;
            $usage ~= ' | ' ~ $_
                for @.proforma;
            $obj.warning($usage);
            return;
        }
        else {
            my $expr = %val{'expr:' ~ $_} with $prop-name;
            $expr //= %val<expr>;

            if $expr {
                %ast<expr> = $expr;
            }
            else {
                $obj.warning('dropping declaration', $prop-name // $/.Str);
                return;
            }
        }
    }

    return %ast;
}

method rule($/) {
    given  self!terms($/) {
        .elems > 1 ?? :expr($_) !! .head;
    }
}

method proforma { [] }
