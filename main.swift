import Foundation

// Generate a secret 4-digit code (each digit between 1 and 6)
func generateSecretCode() -> [Int] {
    (1...4).map { _ in Int.random(in: 1...6) }
}

// Compare user's guess with secret code and return number of B and W
func checkGuess(secret: [Int], guess: [Int]) -> (black: Int, white: Int) {
    var blacks = 0
    var whites = 0
    var secretFlags = [Bool](repeating: false, count: 4)
    var guessFlags = [Bool](repeating: false, count: 4)
    
    // Step 1: Find B (correct digit and position)
    for i in 0..<4 {
        if secret[i] == guess[i] {
            blacks += 1
            secretFlags[i] = true
            guessFlags[i] = true
        }
    }
    // Step 2: Find W (correct digit, wrong position)
    for i in 0..<4 {
        if guessFlags[i] { continue }
        for j in 0..<4 {
            if !secretFlags[j] && guess[i] == secret[j] {
                whites += 1
                secretFlags[j] = true
                break
            }
        }
    }
    return (blacks, whites)
}

// Read user input and validate it
func readGuess() -> [Int]? {
    print("Enter a 4-digit code (digits 1-6) or type 'exit' to quit: ", terminator: "")
    guard let input = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines) else { return nil }
    if input.lowercased() == "exit" {
        return nil
    }
    if input.count != 4 || input.contains(where: { $0 < "1" || $0 > "6" }) {
        print("Invalid input! Please enter exactly 4 digits between 1 and 6.")
        return readGuess()
    }
    return input.compactMap { Int(String($0)) }
}

// Run the game
func playGame() {
    let secret = generateSecretCode()
    // For debugging: uncomment the next line to see the secret code
    // print("Secret code: \(secret.map(String.init).joined())")
    var attempts = 0
    
    while true {
        guard let guess = readGuess() else {
            print("Goodbye!")
            break
        }
        attempts += 1
        let (b, w) = checkGuess(secret: secret, guess: guess)
        if b == 4 {
            print("Congratulations! You guessed the secret code in \(attempts) attempts 👏")
            break
        } else {
            let result = String(repeating: "B", count: b) + String(repeating: "W", count: w)
            print("Result: \(result)")
        }
    }
}

// Start the game
print("Welcome to the Mastermind game!")
playGame()
