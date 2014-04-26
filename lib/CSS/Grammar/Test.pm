# CSS Testing - lightweight harness

module CSS::Grammar::Test {

    use Test;
    use JSON::Tiny;

    # allow only json compatible data
    multi sub json-eqv (EnumMap:D $a, EnumMap:D $b) {
	if +$a != +$b { return False }
	for $a.kv -> $k, $v {
	    unless $b.exists_key($k) && json-eqv($a{$k}, $b{$k}) {
		return False;
	    }
	}
	return True;
    }
    multi sub json-eqv (List:D $a, List:D $b) {
	if +$a != +$b { return Bool::False }
	for (0 .. +$a-1) {
	    return False
		unless (json-eqv($a[$_], $b[$_]));
	}
	return True;
    }
    multi sub json-eqv (Numeric:D $a, Numeric:D $b) { $a == $b }
    multi sub json-eqv (Stringy $a, Stringy $b) { $a eq $b }
    multi sub json-eqv (Bool $a, Bool $b) { $a == $b }
    multi sub json-eqv (Any $a, Any $b) {
	note "data type mismatch";
	note "    - expected: {$b.perl}";
	note "    - got: {$a.perl}";
	return False;
    }

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

	    my $parsed = $p.defined && ~$p ne '';

	    ok(~$parsed, "{$suite}: " ~ $rule ~ " parsed");

	    if $parsed {
		if defined $input {
		    my $input-display = $input.chars > 300 ?? $input.substr(0,50) ~ "     ......    "  ~ $input.substr(*-50) !! $input;
		    my $got = (~$p).trim;
		    my $expected-parse = (%expected<parse> // $input).trim;
		    is($got, $expected-parse, "{$suite}: " ~ $rule ~ " parse: " ~ $input-display)
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
		    else {
			# just test stringification
			ok ($p.ast.defined && json-eqv($p.ast, $ast)), "{$suite} - ast"
			    or do {diag "expected: " ~ to-json($ast);
				   diag "got: " ~ to-json($p.ast)};
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
	    }

	    CATCH {
		default {
		    note "parse failure: $_";
		    flunk("{$suite}: " ~ $rule ~ " parsed");
		    diag "input: {$input}"
			if $input;
		    diag "ast: {$p.ast.perl}"
			if $p.ast;
		}
	    }
	}	

	return $p;
    }

}
