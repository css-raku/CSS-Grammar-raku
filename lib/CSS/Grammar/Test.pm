# CSS Testing - lightweight harness

module CSS::Grammar::Test {

    use Test;
    use JSON::Tiny;

    our sub parse-tests($class, $input, :$parse, :$actions,
			:$rule, :$suite, :%expected) {

	my $p = $parse;

	try {

	    $p //= do { 
		$actions.reset if $actions.can('reset');
		$class.parse( $input, :rule($rule), :actions($actions))
	    };

	    my @warnings = $actions.warnings
		if $actions.can('warnings');

	    my $expected-parse = %expected<parse> // $input;

	    if (defined $input) {
		my $input-display = $input.chars > 300 ?? $input.substr(0,50) ~ "     ......    "  ~ $input.substr(*-50) !! $input;
		my $got = (~$p).trim;
		my $expected = $expected-parse.trim;
		is($got, $expected, "{$suite}: " ~ $rule ~ " parse: " ~ $input-display)
	    }
	    else {
		ok(~$p, "{$suite}: " ~ $rule ~ " parsed")
	    }

	    if  %expected<warnings>:exists && ! %expected<warnings>.defined {
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
		    is( to-json($p.ast), to-json($ast), "{$suite} - ast");
		}
		else {
		    # just test stringification
		    is( ~$p.ast, ~$ast, "{$suite} - ast")
			or diag to-json($p.ast);
		}
	    }
	    else {
		if defined $p.ast {
		    note 'untested_ast: ' ~ to-json( $p.ast )
			unless %expected<ast>:exists;
		}
	    }

	    if defined (my $token = %expected<token>) {
		if ok($p.ast.can('units'), "{$suite} is a token") {
		    if my $units = %$token<units> {
			is($p.ast.units, $units, "{$suite} - units: " ~$units);
		    }
		    if my $type = %$token<type> {
			is($p.ast.type, $type, "{$suite} - type: " ~$type);
		    }
		}
	    }

	    CATCH {
		default {
		    note "parse failure: $_";
		    flunk("{$suite}: " ~ $rule ~ " parsed");
		}
	    }
	}	

	return $p;
    }

}
