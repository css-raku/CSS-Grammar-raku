# CSS Testing - utility functions

module t::AST {

    use Test;

    our sub parse_tests($input, $parse,
                         :$rule, :$suite, :%expected, :@warnings) {

        my $parsed = %expected<parse> // $input;

        if (defined $input) {
            is($parse.Str, $parsed, "{$suite}: " ~ $rule ~ " parse: " ~ $input)
        }
        else {
            ok($parse.Str, "{$suite}: " ~ $rule ~ " parsed")
        }

        my @expected_warnings = %expected<warnings> // ();
        is(@warnings, @expected_warnings,
           @expected_warnings ?? "{$suite} warnings" !! "{$suite} no warnings");

        if defined (my $ast = %expected<ast>) {
            is($parse.ast, $ast, "{$suite} - ast")
                or diag $parse.ast.perl;
        }
        else {
            if defined $parse.ast {
                note {untested_ast =>  $parse.ast}.perl
                    unless %expected.exists('ast');
            }
            else {
                diag "no {$suite} ast: " ~ ($input // '');
            }
        }

        if defined (my $token = %expected<token>) {
            if ok($parse.ast.can('units'), "{$suite} is a token") {
                if my $units = %$token<units> {
                    is($parse.ast.units, $units, "{$suite} - units: " ~$units);
                }
                if my $type = %$token<type> {
                    is($parse.ast.type, $type, "{$suite} - type: " ~$type);
                }
                if (my $skip = %$token<skip>).defined {
                    is($parse.ast.skip // False, $skip, "{$suite} - skip: " ~ $skip);
                }
            }
        }
    }
}
