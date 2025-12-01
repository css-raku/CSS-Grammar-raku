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

#| utility AST builder method for nodes with repeatable elements
method !terms($/ --> Array) {
    my @terms;
    my %glob;
    # unwrap Parcels
    my @l = $/.isa(Capture)
        ?? $/
        !! $/.grep(Capture:D);

    for @l {
        for .caps -> $cap {
            my ($key, $value) = $cap.kv;
            $value .= ast;
            $value //= $.list($cap.value) if $key.starts-with('css-val-');
            next if $key eq '0' || !$value.defined;
            $key .= lc;

            if $key.starts-with('expr-') {
                $key.substr-rw(4,1) = ':';
            }
            elsif $key.starts-with('css-val-') {
                $key = 'expr:' ~ $key.substr(8);
                with %glob{$key} {
                    .push: @terms.pop
                        if @terms.tail.key eq 'op';
                    .append: (@$value);
                    next;
                }
                else {
                    $_ = $value;
                }
            }
            elsif $value.isa(Pair) {
                ($key, $value) = $value.kv;
            }
            else {
                my $type = $key.split(':').head;
                warn "{$value.raku} has unknown type: $type"
                    unless %known-type{$type}:exists;
            }

            if $key eq 'node' {
                @terms.append: @$value;
            }
            else {
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
        .elems == 1 ?? .head !! :node($_);
    }
}

method proforma { [] }
