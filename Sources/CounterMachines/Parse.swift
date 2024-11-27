func parse(tokens: [Token]) -> Result<[ASTNode], ParseError> {
    fatalError()
}

enum ASTNode {
    case jez(Register, Label)
    case incr(Register)
    case decr(Register)
    case call([Value])
}

struct Register {
    let name: String
}

struct Label {
    let name: String
}

enum Value {
    case Text(String)
    case Number(Int)
}

struct ParseError: Error {
    enum ErrorKind {

    }

    let kind: ErrorKind
}
