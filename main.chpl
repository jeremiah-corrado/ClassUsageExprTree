module main {
    use IO;
    use Map;

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

    class BinaryExp: BaseExp {
        var left;
        var right;
    }

    class UnaryExp: BaseExp { }

    class AddExp: BinaryExp { }
    proc AddExp.writeThis(ch: channel) throws {
        ch.write("Add: "); super.writeThis(ch);
    }

    class SubExp: BinaryExp { }
    proc AddExp.writeThis(ch: channel) throws {
        ch.write("Subtract: "); super.writeThis(ch);
    }

    class MulExp: BinaryExp { }
    proc AddExp.writeThis(ch: channel) throws {
        ch.write("Mult: "); super.writeThis(ch);
    }

    class VarExp: UnaryExp {
        var symbol: string;
    }

    class IntExp: UnaryExp {
        var value: int;
    }

    proc eval(head: borrowed BaseExp, const ref env: map(string, int)): int {
        writeln("Evaluating: ", head);
        writeln("With Environment: ", env);
        return 0;
    }

    proc main() {
        basic();
    }

    // ----------------------------------
    // test procs
    // ----------------------------------
    proc basic() {
        const exp = new shared AddExp(new shared VarExp("x"), new shared IntExp(42));
        var env = new map(string, int); env.add("x", 3);
        const result = eval(exp!, env);

        // check passing condition
        const msg = if result == 45 then "Passed!" else "Failed!"; writeln(msg);
    }

}
