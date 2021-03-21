CSS-Grammar-raku
=================

CSS::Grammar is a set of Raku grammars for the W3C family of CSS standards.

It aims to implement a reasonable portion of the base grammars with an
emphasis on:

- support for CSS1, CSS2.1 and CSS3
- forward compatibility rules, scanning and error recovery

This module performs generic parsing of declarations in style-sheet rules.

Contents
========

Base Grammars
-------------
- `CSS::Grammar::CSS1`  - CSS 1.0 compatible grammar
- `CSS::Grammar::CSS21` - CSS 2.1 compatible grammar
- `CSS::Grammar::CSS3`  - CSS 3.0 (core) compatible grammar

The CSS 3.0 core grammar, `CSS::Grammar::CSS3`, is based on CSS2.1; it understands:

- `#hex` and `rgb(...)` colors; but not `rgba(..)`, `hsl(...)`, `hsla(...)` or named colors
- basic `@media` at-rules; but not advanced media queries, resolutions or embedded `@page` rules.
- basic `@page` page description rules
- basic css3 level selectors

Parser Actions
--------------
`CSS::Grammar::Actions` can be used with in conjunction with any of the CSS1
CSS21 or CSS3 base grammars. It produces an abstract syntax tree (AST), plus
warnings for any unexpected input.

    use v6;
    use CSS::Grammar::CSS3;
    use CSS::Grammar::Actions;

    my $css = 'H1 { color: blue; gunk }';

    my $actions =  CSS::Grammar::Actions.new;
    my $p = CSS::Grammar::CSS3.parse($css, :actions($actions));
    .note for $actions.warnings;
    say "H1: " ~ $p.ast<stylesheet>[0]<ruleset><selectors>;
    # output:
    # dropping term: gunk
    # H1: selector    simple-selector qname   element-name    h1

## Actions Options

- **`:lax`** Pass back, don't drop, quantities with unknown dimensions.

Installation
------------

You can use the Raku `zef` module installer to test and install `CSS::Grammar`:

    % zef install CSS::Grammar

To try parsing some content:

    % raku -MCSS::Grammar::CSS3 -e"say CSS::Grammar::CSS3.parse('H1 {color:blue}')"

See Also
--------
- [CSS::Properties](https://github.com/css-raku/CSS-Properties-raku) CSS Propery-list manipulation library.
- [CSS](https://github.com/css-raku/CSS-raku) CSS Stylesheets and processing.
- [CSS::Module::CSS3::Selectors](https://github.com/css-raku/CSS-Module-CSS3-Selectors-raku) extends CSS::Grammar::CSS3 to fully implement CSS Level 3 Selectors.
- [CSS::Module](https://github.com/css-raku/CSS-Module-raku) further extends CSS::Grammar levels 1, 2.1 and 3. It understands named colors and is able to perform property-specific parsing and validation.
- [CSS::Writer](https://github.com/css-raku/CSS-Writer-raku) - AST reserializer
- [CSSGrammar.pm](https://github.com/Raku/examples/blob/master/categories/parsers/CSSGrammar.pm) from [Raku/examples](https://github.com/Raku/examples) gives an introductory Raku grammar for CSS 2.1.

References
----------
This module been built from the W3C CSS Specifications. In particular:

- CSS 1.0 Grammar - http://www.w3.org/TR/2008/REC-CSS1-20080411/#appendix-b
- CSS 2.1 Grammar - http://www.w3.org/TR/CSS21/grammar.html
- CSS3 module: Syntax - http://www.w3.org/TR/2014/CR-css-syntax-3-20140220/
- CSS Style Attributes - http://www.w3.org/TR/2010/CR-css-style-attr-20101012/#syntax
