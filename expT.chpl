module main {
    use IO;
    use Map;
    use Reflection;

    // ----------------------------------
    /* Class Hierarchy:
                    Base Exp
                    /       \
            Binary Exp      Unary Exp
            /    |     \         |    \
          Add  Sub    Mul       Var    Int
    */
    // ----------------------------------

    class BaseExp { }

    class BinaryExp : BaseExp { var left, right : shared BaseExp; }
    class AddExp : BinaryExp { }
    class SubExp : BinaryExp { }
    class MulExp : BinaryExp { }

    class UnaryExp : BaseExp { }
    class VarExp: UnaryExp { var symbol: string; }
    class IntExp: UnaryExp { var value: int; }

    proc BinaryExp.writeThis(ch:channel) throws { ch.write("(", this.left, ", ", this.right, ")"); }
    override proc AddExp.writeThis(ch: channel) throws { ch.write("Add "); super.writeThis(ch); }
    override proc SubExp.writeThis(ch: channel) throws { ch.write("Sub "); super.writeThis(ch); }
    override proc MulExp.writeThis(ch: channel) throws { ch.write("Mul "); super.writeThis(ch); }

    proc VarExp.writeThis(ch: channel) throws { ch.write("'", this.symbol, "'"); }
    proc IntExp.writeThis(ch: channel) throws { ch.write(this.value); }

    // ----------------------------------
    // Tree Evaluation Function
    // ----------------------------------
    proc eval(head: borrowed BaseExp, const ref env: map(string, int)): int {
        const h_bin = head:(borrowed BinaryExp?);
        const h_una = head:(borrowed UnaryExp?);

        if h_bin != nil {
            const h_add = h_bin:(borrowed AddExp?);
            const h_sub = h_bin:(borrowed SubExp?);
            const h_mul = h_bin:(borrowed MulExp?);

            if h_add != nil {
                return eval(h_add!.left, env) + eval(h_add!.right, env);
            } else if h_sub != nil {
                return eval(h_sub!.left, env) - eval(h_sub!.right, env);
            } else if h_mul != nil {
                return eval(h_mul!.left, env) * eval(h_mul!.right, env);
            } else {
                writeln("Cannot apply non-concrete operator!");
                halt(1);
            }
        } else if h_una != nil {
            const h_int = h_una:(borrowed IntExp?);
            const h_var = h_una:(borrowed VarExp?);
            if h_int != nil {
                return h_int!.value;
            } else if h_var != nil {
                return env[h_var!.symbol];
            } else {
                writeln("Cannot evaluate non-concrete Unary Expression!");
                halt(1);
            }
        } else {
            writeln("Cannot Evaluate non-concrete expressions!");
            halt(1);
        }

        return 0;
    }

    proc main() {
        basic_test();
    }

    proc basic_test() {
        // build tree
        const exp : shared AddExp = new shared AddExp(new shared VarExp("x"), new shared IntExp(42));

        // setup environment
        var env = new map(string, int);
        env.add("x", 3);

        // evaluate tree
        const result = eval(exp, env);
        const msg = if result == 45 then "Passed!" else "Failed!";
        writeln("'", getRoutineName(), "': ", msg);
    }
}
