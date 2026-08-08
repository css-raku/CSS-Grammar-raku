# CSS Testing - lightweight harness

unit module CSS::Grammar::Test;

use Test;
use JSON::Fast;

proto sub json-eqv($,$) is export(:json-eqv) {*}
# allow only json compatible data
multi sub json-eqv(%a, %b) {
    %a.elems == %b.elems
    && !%a.first({!.value.&json-eqv(%b{.key})})
}
multi sub json-eqv(@a, @b) {
    @a == @b
    && !@a.pairs.first({!.value.&json-eqv(@b[.key])})
}
multi sub json-eqv (Numeric:D $a, Numeric:D $b) { $a == $b }
multi sub json-eqv (Stringy:D $a, Stringy:D $b) { $a eq $b }
multi sub json-eqv(Any:U $a, Any:U $b) { True }
multi sub json-eqv (Any $a, Any $b) is default {
    note "data type mismatch";
    note "    - expected: {to-json($b)}";
    note "    - got: {to-json($a)}";
    return False;
}

our proto parse-tests(|c) {*}

multi parse-tests($input, :$module!, Bool :$lax, |c) {
    my $grammar = $module.grammar;
    my Any:D $actions = $module.actions.new: :$lax;
    parse-tests($grammar, $input, :$actions, |c);
}

multi parse-tests($grammar, Str:D $input, :$parse is copy, :$actions,
                    :$rule = 'TOP', :$suite = $grammar.^shortname.lc, :$writer,
                    :%expected) is export(:parse-tests) {

    $parse //= do {
        $actions.reset if $actions.can('reset');
        $grammar.subparse( $input, :$rule, :$actions)
    };

    my $expected-parse = (%expected<parse> // $input).trim;

    my %todo = $_ with %expected<todo>;

    if $input.defined && $expected-parse.defined {
        my @input-lines = $input.lines;
        my $input-display = @input-lines >= 3
            ?? [~] @input-lines[0], '... ', @input-lines.tail
            !! $input;
        my $got = $parse.defined ?? (~$parse).trim !! '';
        # partial matches bit iffy at the moment
        is $got, $expected-parse, "{$suite} $rule parse: " ~ $input-display;
    }

    my @warnings = $actions.warnings».message
        if $actions.can('warnings');

    if  %expected<warnings>:exists && ! %expected<warnings>.defined {
        diag "untested warnings: " ~ @warnings
            if @warnings;
    }
    else {
        todo $_ with %todo<warnings>;

        if %expected<warnings>.isa('Regex') {
            my $matched = @warnings.join.match(%expected<warnings>);
            ok $matched, "{$suite} $rule warnings"
                or diag @warnings;
        }
        else {
            my @expected-warnings = @$_ with %expected<warnings>;
            is @warnings, @expected-warnings, "{$suite} $rule {@expected-warnings??''!!'no '}warnings";
        }
    }

    my $actual-ast = .ast with $parse;

    with %expected<ast> -> $expected-ast {

        todo $_ with %todo<ast>;
        my $ast-ok = cmp-ok $actual-ast, &json-eqv, $expected-ast,  "{$suite} $rule ast";;

        if $ast-ok && $writer.can('write') {
            # recursive test of reserialized css.
            try {
                my %writer-opts = $_ with %expected<writer>;
                my %writer-expected = ast => %writer-opts<ast> // $expected-ast;
                my $type = $actual-ast.can('type') && $actual-ast.units // $actual-ast.type;
                my %args = $type ?? ($type => $expected-ast) !! %$expected-ast;

                my $css-again = $writer.write( |%args );
                ok $css-again.chars, "ast reserialization";

                # check that ast remains identical after reserialization
                parse-tests($grammar, $css-again, :$rule, :$actions, :expected(%writer-expected), :suite("  -- $suite reserialized") );

                CATCH {
                    note "error writing: {$actual-ast.raku}";
                    note "regenerated css: $css-again";
                    die $_;
                }
            }
        }
    }
    elsif $actual-ast.defined {
        note 'untested_ast: ' ~ to-json( $actual-ast )
            unless %expected<ast>:exists;
    }

    return $parse;
}

