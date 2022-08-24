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

    class NonConcreteExpError: Error {
        proc init() { }
    }

    class MissingEnvironmentError: Error {
        proc init() { }
    }

    proc eval(head: borrowed BaseExp, const ref env: map(string, int)): int throws {
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
                throw new NonConcreteExpError();
            }
        } else if h_una != nil {
            const h_int = h_una:(borrowed IntExp?);
            const h_var = h_una:(borrowed VarExp?);

            if h_int != nil {
                return h_int!.value;
            } else if h_var != nil {
                if env.contains(h_var!.symbol) {
                    return env[h_var!.symbol];
                } else {
                    throw new MissingEnvironmentError();
                }
            } else {
                throw new NonConcreteExpError();
            }
        } else {
            throw new NonConcreteExpError();
        }
    }

    // ----------------------------------
    // Expression Printing Function
    // ----------------------------------

    proc exprToString(head: borrowed BaseExp): string {
        const h_bin = head:(borrowed BinaryExp?);
        const h_una = head:(borrowed UnaryExp?);

         if h_bin != nil {
            const h_add = h_bin:(borrowed AddExp?);
            const h_sub = h_bin:(borrowed SubExp?);
            const h_mul = h_bin:(borrowed MulExp?);

            if h_add != nil {
                return "(" + exprToString(h_add!.left) + " + " + exprToString(h_add!.right) + ")";
            } else if h_sub != nil {
                return "(" + exprToString(h_sub!.left) + " - " +  exprToString(h_sub!.right) + ")";
            } else if h_mul != nil {
                return exprToString(h_mul!.left) + " * " +  exprToString(h_mul!.right);
            } else {
                return exprToString(h_bin!.left) + " ? " + exprToString(h_bin!.right);
            }
        } else if h_una != nil {
            const h_int = h_una:(borrowed IntExp?);
            const h_var = h_una:(borrowed VarExp?);

            if h_int != nil {
                return h_int!.value:string;
            } else if h_var != nil {
                return h_var!.symbol;
            } else {
                return "_";
            }
        } else {
            return "{ }";
        }
    }

    // ----------------------------------
    // Testing
    // ----------------------------------

    proc main() {
        basic_test();
        missing_env_error();
        generic_exp_error();
        all_ops_test();
        to_string_test();
    }

    proc basic_test() {
        // build tree
        const exp = new AddExp(new shared VarExp("x"), new shared IntExp(42));

        // setup environment
        var env = new map(string, int);
        env.add("x", 3);

        // evaluate expression
        try! {
            const result = eval(exp, env);
            const msg = if result == 45 then "Passed!" else "Failed!";
            writeln("'", getRoutineName(), "': ", msg);
        }
    }

    proc missing_env_error() {
        // build tree
        const exp : shared AddExp = new shared AddExp(new shared VarExp("x"), new shared IntExp(42));

        // setup environment with missing "x"
        var env = new map(string, int);

        // look for correct error type
        try {
            const result = eval(exp, env);
        } catch e: MissingEnvironmentError {
            writeln("'", getRoutineName(), "': Passed!");
        } catch {
            writeln("'", getRoutineName(), "': Failed!");
        }
    }

    proc generic_exp_error() {
        // build tree with a direct UnaryExp
        const exp : shared AddExp = new shared AddExp(new shared VarExp("x"), new shared UnaryExp());

        // setup environment
        var env = new map(string, int);
        env.add("x", 3);

        // look for correct error type
        try {
            const result = eval(exp, env);
        } catch e: NonConcreteExpError {
            writeln("'", getRoutineName(), "': Passed!");
        } catch {
            writeln("'", getRoutineName(), "': Failed!");
        }
    }

    proc all_ops_test() {
        // setup larger tree ((1 + x) * y) + (z - 5)
        const exp = new AddExp(
            new shared MulExp(
                new shared AddExp(
                    new shared VarExp("x"),
                    new shared IntExp(1)
                ),
                new shared VarExp("y")
            ),
            new shared SubExp(
                new shared VarExp("z"),
                new shared IntExp(5)
            )
        );

        // setup two environments
        var env_1 = new map(string, int);
        env_1.add("x", 1);
        env_1.add("y", 2);
        env_1.add("z", 3);

        var env_2 = new map(string, int);
        env_2.add("x", 100);
        env_2.add("y", 10);
        env_2.add("z", 1);

        // check that the expression evaluates correctly for both of them
        try! {
            const r1 = eval(exp, env_1);
            const r2 = eval(exp, env_2);

            const msg = if r1 == 2 && r2 == 1006 then "Passed!" else "Failed!";
            writeln("'", getRoutineName(), "': ", msg);
        }
    }

     proc to_string_test() {
        // setup larger tree ((x + 1) * y) + (z - 5)
        const exp = new AddExp(
            new shared MulExp(
                new shared AddExp(
                    new shared VarExp("x"),
                    new shared IntExp(1)
                ),
                new shared VarExp("y")
            ),
            new shared SubExp(
                new shared VarExp("z"),
                new shared IntExp(5)
            )
        );

        const exp_string = exprToString(exp);
        const msg = if exp_string == "((x + 1) * y + (z - 5))" then "Passed!" else "Failed!";
        writeln("'", getRoutineName(), "': ", msg);
    }
}
