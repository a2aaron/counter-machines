func parse(tokens: [Token]) throws -> Program {
    var tokens = TokenStream(tokens: tokens)

    var program = Program()

    while let next = tokens.peek() {
        switch next {
        case .define:
            let functionDefinition = try ParseFunctionDefinition().parse(tokens: &tokens)
            program.functionDefinitions.append(functionDefinition)
        default:
            let statement = try ParseStatement().parse(tokens: &tokens)
            program.statements.append(statement)
        }
    }

    return program
}

struct Program: Equatable {
    var functionDefinitions = [FunctionDefinition]()
    var statements = [Statement]()
}

protocol ProductionRule<Output> {
    associatedtype Output

    func parse(tokens: inout TokenStream) throws -> Output
    var ruleName: String { get }
    var ruleDef: String { get }
}

struct ParseFunctionDefinition: ProductionRule {
    typealias Output = FunctionDefinition

    var ruleName: String = "function-definition"

    var ruleDef: String = "DEFINE *<function-args> AS *<statement> END"

    func parse(tokens: inout TokenStream) throws -> FunctionDefinition {
        try tokens.consume(.define)
        let name = try tokens.consume_text()
        let args = try KleeneStar(of: ParseFunctionArgs()).parse(tokens: &tokens)
        try tokens.consume(.as)
        let body = try KleeneStar(of: ParseStatement()).parse(tokens: &tokens)
        try tokens.consume(.end)
        return FunctionDefinition(name: name, args: args, body: body)
    }
}

struct ParseFunctionArgs: ProductionRule {
    typealias Output = FunctionArg

    var ruleName: String { "function-arg" }

    var ruleDef: String { "<TEXT> COLON <function-type>" }

    func parse(tokens: inout TokenStream) throws -> FunctionArg {
        let name = try tokens.consume_text()
        try tokens.consume(.colon)
        let type: ValueType =
            switch try tokens.consume_text() {
            case "NUM": .number
            case "REG": .register
            case "LABEL": .label
            default: throw ParseError.failedRule(self)
            }

        return FunctionArg(name: name, type: type)
    }
}

struct Or<Output>: ProductionRule {
    typealias Output = Output

    var ruleName: String { "or" }

    var ruleDef: String {
        let ruleDefs = rules.map({ $0.ruleDef })
        return ruleDefs.joined(separator: " | ")
    }

    func parse(tokens: inout TokenStream) throws -> Output {
        for rule in rules {
            if let value = try? rule.parse(tokens: &tokens) {
                return value
            }
        }
        throw ParseError.failedRule(self)
    }

    let rules: [any ProductionRule<Output>]

    init(of rules: [any ProductionRule<Output>]) {
        self.rules = rules
    }

    init(_ rules: any ProductionRule<Output>...) {
        self.init(of: rules)
    }
}

struct KleeneStar<Output>: ProductionRule {
    typealias Output = [Output]

    var ruleName: String { "star-of-\(rule.ruleName)" }

    var ruleDef: String { "(\(rule.ruleDef))*" }

    func parse(tokens: inout TokenStream) throws -> [Output] {
        var values = [Output]()
        while let value = try? rule.parse(tokens: &tokens) {
            values.append(value)
        }
        return values
    }

    let rule: any ProductionRule<Output>

    init(of rule: any ProductionRule<Output>) {
        self.rule = rule
    }
}

struct ParseStatement: ProductionRule {
    typealias Output = Statement

    var ruleName: String { return "statement" }
    var ruleDef: String { return "<JEZ> | <INCR> | <DECR> | <CALL>" }

    func parse(tokens: inout TokenStream) throws -> Statement {
        let rule = Or(ParseRepeat(), ParseJez(), ParseIncr(), ParseDecr(), ParseCall())
        return try rule.parse(tokens: &tokens)
    }
}

struct ParseRepeat: ProductionRule {
    typealias Output = Statement

    var ruleName: String { return "repeat" }
    var ruleDef: String { return "REPEAT <VALUE> (<statement>)* END" }

    func parse(tokens: inout TokenStream) throws -> Statement {
        try tokens.consume(.repeat)
        let value = try ParseValue().parse(tokens: &tokens)
        let statements = try KleeneStar(of: ParseStatement()).parse(tokens: &tokens)
        try tokens.consume(.end)

        return .repeat(value, statements)
    }
}

struct ParseJez: ProductionRule {
    typealias Output = Statement

    var ruleName: String { "jez" }
    var ruleDef: String { "JEZ <register> <label>" }

    func parse(tokens: inout TokenStream) throws -> Statement {
        try tokens.consume(.jez)
        let register = try ParseRegister().parse(tokens: &tokens)
        let label = try ParseLabel().parse(tokens: &tokens)
        return .jez(register, label)
    }
}
struct ParseIncr: ProductionRule {
    typealias Output = Statement

    var ruleName: String { "incr" }
    var ruleDef: String { "INCR <register>" }

    func parse(tokens: inout TokenStream) throws -> Statement {
        try tokens.consume(.incr)
        let register = try ParseRegister().parse(tokens: &tokens)
        return .incr(register)
    }
}
struct ParseDecr: ProductionRule {
    typealias Output = Statement

    var ruleName: String { "decr" }
    var ruleDef: String { "DECR <register>" }

    func parse(tokens: inout TokenStream) throws -> Statement {
        try tokens.consume(.decr)
        let register = try ParseRegister().parse(tokens: &tokens)
        return .decr(register)
    }
}
struct ParseCall: ProductionRule {
    typealias Output = Statement

    var ruleName: String { "call" }
    var ruleDef: String { "<TEXT> (<VALUE>)* SEMICOLON" }

    func parse(tokens: inout TokenStream) throws -> Statement {
        let name = try tokens.consume_text()
        let values = try KleeneStar(of: ParseValue()).parse(tokens: &tokens)
        try tokens.consume(.semicolon)
        return .call(name, values)
    }
}

struct ParseRegister: ProductionRule {
    typealias Output = Register

    var ruleName: String { return "register" }
    var ruleDef: String { return "<TEXT>" }

    func parse(tokens: inout TokenStream) throws -> Register {
        return try Register(tokens.consume_text())
    }
}

struct ParseLabel: ProductionRule {
    typealias Output = Label

    var ruleName: String { return "label" }
    var ruleDef: String { return "<TEXT>" }

    func parse(tokens: inout TokenStream) throws -> Label {
        return try Label(tokens.consume_text())
    }
}

struct ParseValue: ProductionRule {
    typealias Output = Value

    var ruleName: String { return "value" }
    var ruleDef: String { return "<TEXT> | <NUM>" }

    func parse(tokens: inout TokenStream) throws -> Value {
        if let num = try? tokens.consume_num() {
            return Value.number(num)
        } else if let text = try? tokens.consume_text() {
            return Value.text(text)
        } else {
            throw ParseError.failedRule(self)
        }
    }
}

struct TokenStream {
    let tokens: [Token]
    var index: Int

    init(tokens: [Token]) {
        self.tokens = tokens
        self.index = 0
    }

    func peek() -> Token? {
        if index < tokens.count {
            return tokens[index]
        } else {
            return nil
        }
    }

    mutating func next() -> Token? {
        let nextToken = peek()
        index += 1
        return nextToken
    }

    mutating func consume(_ expected: Token) throws {
        switch peek() {
        case nil: throw ParseError.unexpectedEOF(expected: .num(0))
        case .some(let actual) where actual == expected:
            index += 1
            return ()
        case .some(let actual): throw ParseError.unexpectedToken(expected: .num(0), actual: actual)
        }
    }

    mutating func consume_num() throws -> Int {
        switch peek() {
        case nil: throw ParseError.unexpectedEOF(expected: .num(0))
        case .num(let num):
            index += 1
            return num
        case .some(let actual): throw ParseError.unexpectedToken(expected: .num(0), actual: actual)
        }
    }

    mutating func consume_text() throws -> String {
        switch peek() {
        case nil: throw ParseError.unexpectedEOF(expected: .num(0))
        case .text(let text):
            index += 1
            return text
        case .some(let actual):
            throw ParseError.unexpectedToken(expected: .text(""), actual: actual)
        }
    }
}

enum ASTNode {
    case statement(Statement)
    case functionDefinition(FunctionDefinition)
}

struct FunctionDefinition: Equatable {
    let name: String
    let args: [FunctionArg]
    let body: [Statement]
}

struct FunctionArg: Equatable {
    let name: String
    let type: ValueType
}

enum Statement: Equatable {
    case `repeat`(Value, [Statement])
    case jez(Register, Label)
    case incr(Register)
    case decr(Register)
    case call(String, [Value])
}

enum ValueType {
    case register
    case label
    case number
}

struct Register: Equatable {
    let name: String

    init(_ register: String) {
        self.name = register
    }
}

struct Label: Equatable {
    let name: String

    init(_ label: String) {
        self.name = label
    }
}

enum Value: Equatable {
    case text(String)
    case number(Int)
}

struct ParseError: Error {
    enum ErrorKind: Sendable {
        case unexpectedToken(expected: Token, actual: Token)
        case unexpectedEOF(expected: Token)
        case failedRule(name: String, definition: String)
    }

    let kind: ErrorKind

    static func failedRule(_ rule: any ProductionRule) -> ParseError {
        return ParseError(kind: .failedRule(name: rule.ruleName, definition: rule.ruleDef))
    }

    static func unexpectedToken(expected: Token, actual: Token) -> ParseError {
        return ParseError(kind: .unexpectedToken(expected: expected, actual: actual))
    }

    static func unexpectedEOF(expected: Token) -> ParseError {
        return ParseError(kind: .unexpectedEOF(expected: expected))
    }
}
