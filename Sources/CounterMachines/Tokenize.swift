public func tokenize(_ text: String) -> [Token] {
    var tokens = [Token]()

    var current = ""

    let tokenize_current = {
        if current.isEmpty { return }
        let token = Token.tryFromString(current)
        tokens.append(token)
        current = ""
    }

    for char in text {
        if char.isWhitespace {
            tokenize_current()
        } else if char == ":" {
            // Tokenize what's been already seen (end the current token)
            tokenize_current()
            // Tokenize the colon
            current.append(char)
            tokenize_current()
        } else {
            current.append(char)
        }
    }

    // Clean up any remaining input
    tokenize_current()

    return tokens
}

public enum Token: Equatable {
    case incr
    case decr
    case jez
    case define
    case as_
    case end
    case colon
    case repeat_
    case text(String)
    case num(Int)

    static func tryFromString(_ string: String) -> Token {
        switch string {
        case "INCR": .incr
        case "DECR": .decr
        case "JEZ": .jez
        case "DEFINE": .define
        case "END": .end
        case "AS": .as_
        case "REPEAT": .repeat_
        case ":": .colon
        case let text:
            if let num = Int(text) {
                .num(num)
            } else {
                .text(text)
            }
        }
    }
}
