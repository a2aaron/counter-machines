import Testing

@testable import CounterMachines

@Suite("Tokenization Suite")
struct TokenizationSuite {
    @Test("Tokenize Simple Words")
    func testTokenizeSimple() {
        let program = """
            INCR 0
            JEZ 1
            DECR 2

            ADD 1
            """

        let expected: [Token] = [
            .incr, .num(0),
            .jez, .num(1),
            .decr, .num(2),
            .text("ADD"), .num(1),
        ]

        let actual = tokenize(program)

        #expect(expected == actual, "Mismatched tokenization result")
    }

    @Test("Tokenize Simple Words - Whitespace")
    func testTokenizeWhitespace() {
        let program = """
            \tINCR     0
            JEZ   1
            \tDECR            2

            ADD        \t 1
            """

        let expected: [Token] = [
            .incr, .num(0),
            .jez, .num(1),
            .decr, .num(2),
            .text("ADD"), .num(1),
        ]

        let actual = tokenize(program)

        #expect(expected == actual, "Mismatched tokenization result")
    }

    @Test("Tokenize - Function Definition")
    func testTokenizeFunction() {
        let program = """
            DEFINE ADD reg:REG num:NUM AS
                REPEAT num
                    INCR reg
                END
            END

            ADD reg1 3
            """

        let expected: [Token] = [
            .define, .text("ADD"),
            .text("reg"), .colon, .text("REG"),
            .text("num"), .colon, .text("NUM"),
            .as_,

            .repeat_, .text("num"),
            .incr, .text("reg"),
            .end,
            .end,

            .text("ADD"), .text("reg1"), .num(3),
        ]

        let actual = tokenize(program)

        #expect(expected == actual, "Mismatched tokenization result")
    }
}

@Suite("Parsing Suite")
struct ParsingSuite {
    @Test("Parse Add2")
    func testParseAdd2() throws {
        let program = """
            DEFINE ADD2 reg:REG AS
                INCR reg
                INCR reg
            END

            ADD2 register;
            ADD2 register2 ;
            """

        let tokens = tokenize(program)
        let actual = try parse(tokens: tokens)

        let expected = Program(
            functionDefinitions: [
                FunctionDefinition(
                    name: "ADD2",
                    args: [
                        FunctionArg(name: "reg", type: .register)
                    ],
                    body: [.incr(Register("reg")), .incr(Register("reg"))])
            ],
            statements: [
                .call("ADD2", [.text("register")]),
                .call("ADD2", [.text("register2")]),
            ]
        )

        #expect(expected == actual)
    }
}
