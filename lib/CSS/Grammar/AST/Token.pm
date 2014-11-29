use v6;

role CSS::Grammar::AST::Token {
    has $.type is rw;
    has $.units is rw;
    has $.trait is rw;
}
