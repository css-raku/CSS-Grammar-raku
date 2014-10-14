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
			:$verbose = False, :$rule = 'TOP', :$suite = '', :%expected) {

	my $p = $parse;

	try {

	    $p //= do { 
		$actions.reset if $actions.can('reset');
                $actions.verbose = $verbose  if $actions.can('verbose');
		$class.subparse( $input, :rule($rule), :actions($actions))
	    };

	    my @warnings = $actions.warnings
		if $actions.can('warnings');

	    my $expected-parse = (%expected<parse> // $input).trim;

            my %todo = %( %expected<todo> // {} );

	    if $input.defined && $expected-parse.defined {
		my $input-display = $input.chars > 300
		    ?? $input.substr(0,50) ~ "     ......    "  ~ $input.substr(*-50)
		    !! $input;
		my $got = $p.defined ?? (~$p).trim !! '';
		# partial matches bit iffy at the moment
		is($got, $expected-parse, "{$suite} $rule parse: " ~ $input-display)
	    }

            todo( %todo<warnings> )
                if %todo<warnings>;

	    if  %expected<warnings>:exists && ! %expected<warnings>.defined {
		diag "untested warnings: " ~ @warnings
		    if @warnings;
	    }
	    else {
               if %expected<warnings>.isa('Regex') {
                   my @matched = ([~] @warnings).match(%expected<warnings>);
                   ok( @matched, "{$suite} $rule warnings")
                       or diag @warnings;
               }
               else {
                   my @expected-warnings = @( %expected<warnings> // () );
                   is_deeply @warnings, @expected-warnings, "{$suite} $rule {@expected-warnings??''!!'no '}warnings";
               }
	    }

	    if defined (my $ast = %expected<ast>) {

               todo( %todo<ast> )
		    if %todo<ast>;     

		ok ($p.defined && $p.ast.defined && json-eqv($p.ast, $ast)), "{$suite} $rule ast"
		    or do {diag "expected: " ~ to-json($ast);
			   diag "got: " ~ to-json($p.ast)};
	    }
	    else {
		if $p.defined && $p.ast.defined {
		    note 'untested_ast: ' ~ to-json( $p.ast )
			unless %expected<ast>:exists;
		}
	    }

	    if defined (my $token = %expected<token>) {
		if ok($p.defined && $p.ast.can('units'), "{$suite} $rule is a token") {
		    if my $units = %$token<units> {
			is($p.ast.units, $units, "{$suite} $rule units: " ~$units);
		    }
		    if my $type = %$token<type> {
			is($p.ast.type, $type, "{$suite} $rule type: " ~$type);
		    }
		}
	    }

            CATCH {
                default {
                    note "parse failure: $_";
                    flunk("{$suite} $rule parsed");
                    diag "input $rule: {$input}"
                        if $input.defined;
                    diag "ast: {$p.ast.perl}"
                        if $p.defined && $p.ast.defined;
                }
	    }
	}	

	return $p;
    }

}
