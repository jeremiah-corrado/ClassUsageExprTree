module main {
    use IO;
    use Map;

    enum Ops {
        Add,
        Sub,
        Mul,
        No,
    }

    enum Shapes {
        Binary,
        Unary,
        No,
    }

    // ----------------------------------
    /* Class Hierarchy:
                    Base Exp
                    /       \
            Binary Exp      Unary Exp
            /    |     \         |    \
          Add  Sub    Mul       Var    Int
    */
    // ----------------------------------

    class BaseExp {
        var shape = Shapes.No;
        var op = Ops.No;
    }

    class BinaryExp: BaseExp {
        var left, right;
    }
    proc BinaryExp.writeThis(ch: channel) throws {
        ch.write("(", this.left, ", ", this.right, ")");
    }

    class UnaryExp: BaseExp { }

    class AddExp: BinaryExp { }
    override proc AddExp.writeThis(ch: channel) throws {
        ch.write("Add "); super.writeThis(ch);
    }
    proc AddExp.init(left, right) {
        super.init(Shapes.Binary, Ops.Add, left, right);
    }

    class SubExp: BinaryExp { }
    override proc SubExp.writeThis(ch: channel) throws {
        ch.write("Subtract "); super.writeThis(ch);
    }
    proc SubExp.init(left, right) {
        super.init(Shapes.Binary, Ops.Sub, left, right);
    }

    class MulExp: BinaryExp { }
    override proc MulExp.writeThis(ch: channel) throws {
        ch.write("Multiply "); super.writeThis(ch);
    }
    proc MulExp.init(left, right) {
        super.init(Shapes.Binary, Ops.Mul, left, right);
    }

    class VarExp: UnaryExp {
        var symbol: string;
    }
    proc VarExp.writeThis(ch: channel) throws {
        ch.write("'", symbol, "'");
    }
    proc VarExp.init(symbol: string) {
        super.init(Shapes.Unary, Ops.No);
        this.symbol = symbol;
    }

    class IntExp: UnaryExp {
        var value: int;
    }
    proc IntExp.writeThis(ch: channel) throws {
        ch.write(value);
    }
    proc IntExp.init(value: int) {
        super.init(Shapes.Unary, Ops.No);
        this.value = value;
    }

    proc eval(head: borrowed BaseExp, const ref env: map(string, int)): int {
        return 0;
    }

    proc main() {
        basic();
    }

    // ----------------------------------
    // test procs
    // ----------------------------------
    proc basic() {
        // build tree
        const exp : shared AddExp = new shared AddExp(new shared VarExp("x"), new shared IntExp(42));
        writeln(exp);

        // setup environment
        var env = new map(string, int);
        env.add("x", 3);

        // evaluate tree
        const result = eval(exp, env);
        const msg = if result == 45 then "Passed!" else "Failed!"; writeln(msg);
    }

}
