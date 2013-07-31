use v6;

grammar CSS::Grammar::Scan{...}

grammar CSS::Grammar:ver<0.0.1> {

    # abstract base grammar for CSS instance grammars:
    #  CSS::Grammar::CSS1  - CSS level 1
    #  CSS::Grammar::CSS21 - CSS level 2.1
    #  CSS::Grammar::CSS3  - CSS level 3

    # Comments and whitespace

    token nl {\xA|"\r"\xA|"\r"|"\f"}

    # comments: nb trigger <nl> for accurate line counting
    token comment {('<!--') [<.nl>|.]*? ['-->' | <unclosed-comment>]
                  |('/*')   [<.nl>|.]*? ['*/'  | <unclosed-comment>]}
    token unclosed-comment {$}

    token wc {<.nl> | "\t"  | " "}
    token ws {<!ww>[<.wc>|<.comment>]*}

    # "lexer"com
    # taken from http://www.w3.org/TR/css3-syntax/ 11.2 Lexical Scanner

    token unicode  {(<[0..9 a..f A..F]>**1..6)}
    # w3c nonascii :== #x80-#xD7FF #xE000-#xFFFD #x10000-#x10FFFF
    token regascii {<[\x20..\x7F]>}
    token nonascii {<- [\x0..\x7F]>}
    token escape   {'\\'[<unicode>|<char=.regascii>|<char=.nonascii>]}
    token nmstrt   {(<[_ a..z A..Z]>)|<nonascii>|<escape>}
    token nmchar   {<nmreg>|<nonascii>|<escape>}
    token nmreg    {<[_ \- a..z A..Z 0..9]>+}
    token ident    {$<pfx>=['-']?<nmstrt><nmchar>*}
    token name     {<nmchar>+}
    token num      {[\+|\-]?[\d* \.]? \d+}
    token posint   {\d+}

    proto token stringchar {*}
    token stringchar:sym<cont>      {\\<nl>}
    token stringchar:sym<escape>    {<escape>}
    token stringchar:sym<nonascii>  {<nonascii>}
    token stringchar:sym<ascii>     {<[\x20 \! \# \$ \% \& \(..\[ \]..\~]>+}

    token single-quote   {\'}
    token double-quote   {\"}
    proto token string   {<...>}
    token string:sym<double-q>  {\"[<stringchar>|<stringchar=.single-quote>]*\"}
    token string:sym<single-q>  {\'[<stringchar>|<stringchar=.double-quote>]*\'}

    token id             {'#'<name>}
    token class          {'.'<name>}
    token element-name   {<ident>}

    proto token distance-units     {<...>}
    token distance-units:sym<abs>  {:i pt|mm|cm|pc|in|px}
    token distance-units:sym<font> {<rel-font-units>}
    token rel-font-units           {:i em|ex}

    proto token length         {<...>}
    token length:sym<dim>      {:i<num><units=.distance-units>}
    # As a special case, relative font lengths don't need a number.
    # E.g. -ex :== -1ex
    token length:sym<rel-font-unit> {(\+|\-)? (<.rel-font-units>)}

    proto token dimension {<...>}
    token dimension:sym<length>     {<length>}

    token url_delim_char   { <[ \( \) \' \" \\ ]> | <.wc>}
    token url-chars        {<char=.escape>|<char=.nonascii>|<- url_delim_char>+}

    proto rule url         {<...>}
    rule url:sym<string>   {:i'url(' <string> ')' }
    rule url:sym<unquoted> {:i'url(' <url-chars>* ')' }

    token percentage       {<num>'%'}

    # productions

    token operator       {'/'|','}

    rule property        {<property=.ident> ':'}
    rule end-decl        { ';' | <?before '}'> | $ }

    rule color-range     {<num>$<percentage>=[\%]?}

    proto rule color    {*}
    rule color:sym<rgb> {:i'rgb('
                   [ <r=.color-range> ','
                     <g=.color-range> ','
                     <b=.color-range> || <any-args> ]
                   ')'
    }
    rule color:sym<hex> {<id>}

    token prio {:i'!' [('important')||<any>] }

    # pseudos
    proto rule pseudo {<...>}

    # Combinators - introduced with css2.1
    proto rule combinator {*}
    rule combinator:sym<adjacent> { '+' }
    rule combinator:sym<child>    { '>' }

    proto rule term {*}
    rule term:sym<num>        {<num><!before ['%'|\w]>}
    rule term:sym<dimension>  {<dimension>}
    rule term:sym<percentage> {<percentage>}
    rule term:sym<string>     {<string>}
    rule term:sym<color>      {<color>}
    rule term:sym<url>        {<url>}
    rule term:sym<ident>      {<ident><!before '('>}

    # Unicode ranges - used by selector modules + scan rules
    proto rule unicode-range {*}
    rule unicode-range:sym<from-to> {$<from>=[<.xdigit>**1..6] '-' $<to>=[<.xdigit>**1..6]}
    rule unicode-range:sym<masked>  {$<mask>=[<.xdigit>|'?']**1..6 <!before \->}

    proto rule declaration {<...>}

    # Error Recovery
    # --------------
    # - <any>                    - for unknown terms etc
    rule any       {<CSS::Grammar::Scan::_value>}
    # - <any-arg>, <any-args>    - for incorrect function args
    rule any-arg   {<CSS::Grammar::Scan::_arg>}
    rule any-args  {<any-arg>*}
    # - <badstring>               - for unclosed strings
    rule badstring {<CSS::Grammar::Scan::_badstring>}
    rule unclosed-paren-square {<?>}
    rule unclosed-paren-round  {<?>}

    # failed declaration parse - how well formulated is it?
    proto rule dropped-decl { <...> }
    # - extra semicolon - just ignore
    rule dropped-decl:sym<empty>     { ';' }
    # - parsed a property; some terms are unknown
    rule dropped-decl:sym<forward-compat> { <property> [<expr>||(<any>)]*? <end-decl> }
    # - couldn't get a property, but terms well formed
    rule dropped-decl:sym<stray-terms>    { (<any>)+? <end-decl> }
    # - unterminated string. might consume ';' '}' and other constructs
    rule dropped-decl:sym<badstring>      { <property>? (<any>)*? <.badstring> <end-decl>? }
    # - unable to parse it at all; throw it out
    rule dropped-decl:sym<flushed>        { ( <any> || <- [\;\}]> )+? <end-decl> }

    rule end-block {[$<closing-paren>='}' ';'?]?}

    # forward compatible scanning and recovery - from the stylesheet top level
    # - skip statements, at-rules or other recognised constructs
    token unknown  {  <CSS::Grammar::Scan::_statement>
                   || [ <any> | <badstring> ]
                   || <CSS::Grammar::Scan::_ascii-punct>
                   # - last resort - skip a character
                   || <[.]>+?
                   }
}


grammar CSS::Grammar::Scan is CSS::Grammar {

    # Fallback/Normalization Grammar
    # This is based on the universal grammar syntax described in
    # http://www.w3.org/TR/2011/REC-CSS2-20110607/syndata.html#syntax
    # It is a scanning grammar that is only used to implement:
    # -- term flushing  for forward compatiblity and error recovery
    # -- normalization

    # Term Flushing:
    # --------------
    # It's been generalized to handle the rule dropping requirements outlined
    # in http://www.w3.org/TR/2003/WD-css3-syntax-20030813/#rule-sets
    # e.g this should be completely dropped: h3, h4 & h5 {color: red }

    # Errata:
    # - declarations are less structured - optimized for robustness
    # - added <_op> for general purpose operator detection
    # - may assume closing parenthesis in nested values and blocks

    rule TOP           {^ <_stylesheet> $}
    rule _stylesheet   {<_statement>*}
    rule _statement    {<_ruleset> | '@'<_at-rule>}

    rule _at-keyword   {\@<ident>}
    rule _at-rule      {(<ident>) <_any>* [ <_block> | <_badstring> | ';' ]}
    rule _block        {'{' [ <_value> | <_badstring> | ';' ]* '}'?}

    rule _ruleset      { <_selectors>? <_declarations> }
    rule _selectors    { [<_any> | <_badstring>]+ }
    rule _declarations {'{' <_declaration-list> '}' ';'?}
    rule _declaration-list {[ <.property> | <_value> | <_badstring> |';' ]*}
    rule _value        {[ <_any> | <_block> | <_at-keyword> ]+}

    token _ascii-punct {<[\! .. \~] -alnum>}
    token _delim       {<[ \( \) \[ \] \{ \} \; \" \' \\ ]>}
    token _op          {[<._ascii-punct> & <- _delim>]+}

    rule _badstring    {\"[<.stringchar>|\']*[<.nl>|$]
                       |\'[<.stringchar>|\"]*[<.nl>|$]}

    proto rule _any { <...> }
    rule _any:sym<string> { <.string> }
    rule _any:sym<dim>    { <.num>['%'|<.ident>]? }
    rule _any:sym<urange> { 'U+'<.unicode-range> }
    rule _any:sym<ident>  { <.ident> }
    rule _any:sym<pseudo> { <.pseudo> }
    rule _any:sym<id>     { <.id> }
    rule _any:sym<class>  { <.class> }
    rule _any:sym<op>     { <_op> }
    rule _any:sym<attrib> { '[' <_arg>* [ ']' || <.unclosed-paren-square> ] }
    rule _any:sym<args>   { '(' <_arg>* [ ')' || <.unclosed-paren-round> ] }

    rule _arg {[ <_any> | <_block> | <_at-keyword> | <_badstring> ]}

    # Ident cleanup
    # -------------
    # CSS grammars allow escapes anywhere that idents may appear.
    # This leads to irregular parsing. For example, to define EM
    # in http://www.w3.org/TR/2011/REC-CSS2-20110607/grammar.html
    #
    # E		e|\\0{0,4}(45|65)(\r\n|[ \t\r\n\f])?
    # M		m|\\0{0,4}(4d|6d)(\r\n|[ \t\r\n\f])?|\\m
    # {num}?{E}{M}		{return EMS;}
    #
    # <ident-cleanup> is an experimental rule for cleaning of irregular idents.
    #
    #  my $a = CSS::Grammar::Scan::Actions.new;
    #  my $p = CSS::Grammar::Scan.parse('\h1{c\ol\6fr: bl\ue}', :actions($a), :rule<ident-cleanup>);
    #  my $css-cleaned = $p.ast; # 'h1{color: blue}'
    #  CSS::Language::CSS21.parse($css-cleaned);

    token ident-cleanup {^ [<ident>(.*?)|(.+?)]* $}
}
