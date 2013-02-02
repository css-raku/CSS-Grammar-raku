use v6;

# AST: CSS Parse Abstract Syntax Tree Objects
# although we're using this directly at the moment. It will become an abstract
# base class, once we've built instances (CSS::Grammar::AST::Selector etc).

class CSS::Grammar::AST {

    # $.skip - W3C compliant processors should skip processing of this
    #          node and its children
    has Bool $.skip is rw;

    # $.warning - warning associated with this node.
    # Note: child elements may also contain warnings.
    has Str $.warning;

    # $.line_no - source line number
    has Int $.line_no;

}



