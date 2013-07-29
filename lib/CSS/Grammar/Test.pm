# CSS Testing - utility functions

module CSS::Grammar::Test {

    use Test;

    our sub parse_tests($input, $parse,
                         :$rule, :$suite, :%expected, :@warnings) {

        my $expected_parse = %expected<parse> // $input;

        if (defined $input) {
            my $input_display = $input.chars > 300 ?? $input.substr(0,50) ~ "     ......    "  ~ $input.substr(*-50) !! $input;
            my $got = $parse.trim;
            my $expected = $expected_parse.trim;
            is($got, $expected, "{$suite}: " ~ $rule ~ " parse: " ~ $input_display)
        }
        else {
            ok($parse.Str, "{$suite}: " ~ $rule ~ " parsed")
        }

        if  %expected.exists('warnings') && ! %expected<warnings>.defined {
            diag "untested warnings: " ~ @warnings
                if @warnings;
        }
        else {
            todo( %expected<warnings-todo> )
                if %expected<warnings-todo>;
     
            if %expected<warnings>.isa('Regex') {
                my @matched = ([~] @warnings).match(%expected<warnings>);
                ok( @matched, "{$suite} warnings")
                    or diag @warnings;
            }
            else {
                my @expected_warnings = %expected<warnings> // ();
                is(@warnings, @expected_warnings,
                   @expected_warnings ?? "{$suite} warnings" !! "{$suite} no warnings");
            }
	}

        if defined (my $ast = %expected<ast>) {
            if my $todo-ast = %expected<todo><ast> {
                todo($todo-ast);
            }
	    is($parse.ast, $ast, "{$suite} - ast")
                or diag $parse.ast.perl;
        }
        else {
            if defined $parse.ast {
                note 'untested_ast: ' ~ $parse.ast.perl
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
