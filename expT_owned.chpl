module main {
    use Map;
    use Reflection;
    use Memory.Diagnostics;

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

    class BinaryExp : BaseExp { var left, right : owned BaseExp; }
    class AddExp : BinaryExp { }
    class SubExp : BinaryExp { }
    class MulExp : BinaryExp { }

    class UnaryExp : BaseExp { }
    class VarExp: UnaryExp { var symbol: string; }
    class IntExp: UnaryExp { var value: int; }

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
        const h_bin = head:BinaryExp?;
        const h_una = head:UnaryExp?;

        if h_bin != nil {
            const h_add = h_bin:AddExp?;
            const h_sub = h_bin:SubExp?;
            const h_mul = h_bin:MulExp?;

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
            const h_int = h_una:IntExp?;
            const h_var = h_una:VarExp?;

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
        const h_bin = head:BinaryExp?;
        const h_una = head:UnaryExp?;

         if h_bin != nil {
            const h_add = h_bin:AddExp?;
            const h_sub = h_bin:SubExp?;
            const h_mul = h_bin:MulExp?;

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
            const h_int = h_una:IntExp?;
            const h_var = h_una:VarExp?;

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

        printMemAllocs();
    }

    proc basic_test() {
        // build tree
        const exp = new AddExp(new VarExp("x"), new IntExp(42));

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
        const exp = new AddExp(new VarExp("x"), new IntExp(42));

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
        const exp = new AddExp(new VarExp("x"), new UnaryExp());

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
            new MulExp(
                new AddExp(
                    new VarExp("x"),
                    new IntExp(1)
                ),
                new VarExp("y")
            ),
            new SubExp(
                new VarExp("z"),
                new IntExp(5)
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
            new MulExp(
                new AddExp(
                    new VarExp("x"),
                    new IntExp(1)
                ),
                new VarExp("y")
            ),
            new SubExp(
                new VarExp("z"),
                new IntExp(5)
            )
        );

        const exp_string = exprToString(exp);
        const msg = if exp_string == "((x + 1) * y + (z - 5))" then "Passed!" else "Failed!";
        writeln("'", getRoutineName(), "': ", msg);
    }
}
