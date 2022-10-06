protocol Feature: ExpressibleByStringLiteral, RawRepresentable where RawValue == UInt8 {
    static func missing(_ lhs: Self, _ rhs: Self) -> Self
}

enum Shape: UInt8, Feature {
    case Oval = 1
    case Squiggle = 2
    case Diamond = 4
    
    init(stringLiteral value: StringLiteralType) {
        switch value {
        case "O": self = .Oval
        case "S": self = .Squiggle
        case "D": self = .Diamond
        default: fatalError("Invalid literal.")
        }
    }
}
enum Color: UInt8, Feature {
    case Green = 1
    case Purple = 2
    case Red = 4
    
    init(stringLiteral value: StringLiteralType) {
        switch value {
        case "G": self = .Green
        case "P": self = .Purple
        case "R": self = .Red
        default: fatalError("Invalid literal.")
        }
    }
}
enum Quantity: UInt8, Feature {
    case One = 1
    case Two = 2
    case Three = 4
    
    init(stringLiteral value: StringLiteralType) {
        switch value {
        case "1": self = .One
        case "2": self = .Two
        case "3": self = .Three
        default: fatalError("Invalid literal.")
        }
    }
}
enum Fill: UInt8, Feature {
    case Solid = 1
    case Translucent = 2
    case Outlined = 4
    
    init(stringLiteral value: StringLiteralType) {
        switch value {
        case "S": self = .Solid
        case "T": self = .Translucent
        case "O": self = .Outlined
        default: fatalError("Invalid literal.")
        }
    }
}

extension Feature {
    static func missing(_ lhs: Self, _ rhs: Self) -> Self {
        return .init(rawValue: missing(lhs.rawValue, rhs.rawValue))!
    }
    
    private static func missing(_ n1: UInt8, _ n2: UInt8) -> UInt8 {
        if n1 | n2 == n1 { return n1 }
        return (n1 | n2)^7
    }
}

struct Card: Hashable, ExpressibleByStringLiteral, CustomStringConvertible {
    let quantity: Quantity
    let fill: Fill
    let color: Color
    let shape: Shape

    var description: String { "\(quantity):\(fill):\(color):\(shape)" }
    
    init(stringLiteral value: String) {
        guard value.count == 4 else { fatalError("Invalid literal") }
        let letters = value.map({ $0 })
        quantity = Quantity(stringLiteral: "\(letters[0])")
        fill = Fill(stringLiteral: "\(letters[1])")
        color = Color(stringLiteral: "\(letters[2])")
        shape = Shape(stringLiteral: "\(letters[3])")
    }
    
    init(shape: Shape, color: Color, quantity: Quantity, fill: Fill) {
        self.shape = shape
        self.color = color
        self.quantity = quantity
        self.fill = fill
    }
}


func missing(_ lhs: Card, _ rhs: Card) -> Card {
    let missingShape = Shape.missing(lhs.shape, rhs.shape)
    let missingColor = Color.missing(lhs.color, rhs.color)
    let missingQuantity = Quantity.missing(lhs.quantity, rhs.quantity)
    let missingFill = Fill.missing(lhs.fill, rhs.fill)
    return Card(shape: missingShape, color: missingColor, quantity: missingQuantity, fill: missingFill)
}


let card1 = Card(shape: .Diamond, color: .Green, quantity: .One, fill: .Outlined)
let card2 = Card(shape: .Diamond, color: .Green, quantity: .One, fill: .Outlined)


struct Board {
    let cards: [Card]
    
    init(_ cards: [[Card]]) {
        self.cards = cards.flatMap({ $0 })
    }
}

let board = Board([
    ["3TPS", "2OGD", "2SPD"],
    ["2TGS", "3TRS", "3TGD"],
    ["1TRS", "2SRO", "1OPS"],
    ["3TGO", "1ORS", "1SPO"],
])

struct CardSet: Hashable, CustomStringConvertible {
    let card1: Card
    let card2: Card
    let card3: Card
    
    let set: Set<Card>
    
    var description: String { "(\(card1), \(card2), \(card3))" }
    
    init(_ card1: Card, _ card2: Card, _ card3: Card) {
        self.card1 = card1
        self.card2 = card2
        self.card3 = card3
        self.set = Set([card1, card2, card3])
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.set.union(rhs.set).count == 3
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(set)
    }

}

func allSets(in board: Board) -> SetGroup {
    var matches = SetGroup()
    for card1 in board.cards {
        for card2 in board.cards where card1 != card2 {
            for card3 in board.cards where card3 == missing(card1, card2) && card3 != card1 && card3 != card2 {
                matches.add(set: CardSet(card1, card2, card3))
            }
        }
    }
    return matches
}


let sets = allSets(in: board)

struct SetGroup: Hashable {
    private(set) var group: Set<CardSet>
    private(set) var set: Set<Card>
    
    init(group: Set<CardSet> = []) {
        self.group = group
        self.set = group.reduce(into: Set<Card>(), { $0.formUnion($1.set) })
    }
    
    mutating func add(set: CardSet) {
        group.insert(set)
        self.set.formUnion(set.set)
    }
}

func possibleSetGroups(startingWith groups: Set<SetGroup>, using sets: [CardSet]) -> Set<SetGroup> {
    let possibleGroups = groups.reduce(into: Set<SetGroup>(), { newGroups, group in
        var mutableGroup = group
        for `set` in sets where mutableGroup.set.intersection(`set`.set).isEmpty {
            mutableGroup.add(set: `set`)
            newGroups.insert(mutableGroup)
        }
        if newGroups.isEmpty { newGroups.insert(mutableGroup) }
    })
    return possibleGroups.count != groups.count ? possibleSetGroups(startingWith: possibleGroups, using: sets) : groups
}

let setOfSetGroups: Set<SetGroup> = sets.group.reduce(into: Set<SetGroup>(), {
    $0.insert(SetGroup(group: [$1]))
})
let possible = possibleSetGroups(startingWith: setOfSetGroups, using: sets.group.map({ $0 }))
if let largestSetGroup = possible.max(by: { $0.group.count < $1.group.count }) {

    for `set` in largestSetGroup.group {
        print(`set`)
    }
}

