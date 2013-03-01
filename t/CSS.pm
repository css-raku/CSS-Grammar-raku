# CSS Testing - utility functions

module t::CSS {

    use Test;

    our sub parse_tests($input, $parse,
                         :$rule, :$compat, :%expected, :@warnings) {

        my $parsed = %expected<parse> // $input;

        if (defined $input) {
            is($parse.Str, $parsed, "{$compat}: " ~ $rule ~ " parse: " ~ $input)
        }
        else {
            ok($parse.Str, "{$compat}: " ~ $rule ~ " parsed")
        }

        my @expected_warnings = %expected<warnings> // ();
        is(@warnings, @expected_warnings,
           @expected_warnings ?? "{$compat} warnings" !! "{$compat} no warnings");

        if defined (my $ast = %expected<ast>) {
            is($parse.ast, $ast, "{$compat} - ast")
                or diag $parse.ast.perl;
        }
        else {
            if defined $parse.ast {
                note {untested_ast =>  $parse.ast}.perl
                    unless %expected.exists('ast');
            }
            else {
                diag "no {$compat} ast: " ~ ($input // '');
            }
        }

        if defined (my $units = %expected<units>) {
            if ok($parse.ast.can('units'), "{$compat} does units") {
                is($parse.ast.units, $units, "{$compat} - units")
                    or diag $parse.ast.units
                }
        }

        if defined (my $skip = %expected<skip>) {
            if ok($parse.ast.can('skip'), "{$compat} does skip") {
                is($parse.ast.skip, $skip, "{$compat} - skip is " ~ $skip);
            }
        }
    }
}
