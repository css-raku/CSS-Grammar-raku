# CSS Testing - utility functions

module CSS::Grammar::Test {

    use Test;
    use JSON::Tiny;

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
	    if %*ENV<CSS_XT> {
		# test json canonicalization - thorough, but slower
		is( to-json($parse.ast), to-json($ast), "{$suite} - ast");
	    }
	    else {
		# just test stringification
		is( $parse.ast.Str, $ast.Str, "{$suite} - ast");
	    }
        }
        else {
            if defined $parse.ast {
                note 'untested_ast: ' ~ to-json( $parse.ast )
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
