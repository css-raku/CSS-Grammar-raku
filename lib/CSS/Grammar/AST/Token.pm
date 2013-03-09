use v6;

role CSS::Grammar::AST::Token {
    has Bool $.skip is rw;

    has $.type is rw;
    has $.units is rw;
}
