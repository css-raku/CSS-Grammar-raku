use v6;

grammar CSS::Grammar {

    token eol {"\r\n"  # ms/dos
               | "\n"  #'nix
               | "\r"} # mac-osx

    token ws_char {'<!--' .*? '-->'
                   |'/*' .*? '*/'
		   | "\n" | "\t" | "\o12" | "\f" | "\r" | " "}

    token ws {
	<!ww>
	<ws_char>*}


}
