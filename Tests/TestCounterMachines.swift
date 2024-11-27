import Testing

@testable import CounterMachines

@Suite("Tokenization Suite")
struct name {
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
