import Foundation

func shell(_ command: String) -> String {
    let task = Process()
    let pipe = Pipe()
    task.standardOutput = pipe
    task.standardError = pipe
    task.arguments = ["-c", command]
    task.executableURL = URL(fileURLWithPath: "/bin/bash")
    try! task.run()
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    return String(data: data, encoding: .utf8) ?? ""
}

// Create a new game
let createGameCmd = "curl -s -X POST https://mastermind.darkube.app/game"
let createGameOutput = shell(createGameCmd)

// extract game_id from JSON
let pattern = "\"game_id\"\\s*:\\s*\"([^\"]+)\""
let regex = try! NSRegularExpression(pattern: pattern)
let range = NSRange(createGameOutput.startIndex..., in: createGameOutput)
var gameId: String? = nil
if let match = regex.firstMatch(in: createGameOutput, options: [], range: range) {
    if let swiftRange = Range(match.range(at: 1), in: createGameOutput) {
        gameId = String(createGameOutput[swiftRange])
    }
}
guard let gameID = gameId else {
    print("Could not get game ID. Exiting.")
    exit(1)
}
print("Game started! Game ID: \(gameID)")


var attemp = 0

while true {
    attemp += 1
    print("Enter your guess (4 digits 1-6) or type 'exit': ", terminator: "")
    guard let guess = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines) else { break }
    if guess.lowercased() == "exit" { break }
    if guess.count != 4 || guess.contains(where: { $0 < "1" || $0 > "6" }) {
        print("Invalid input.")
        continue
    }
    let json = """
    {"game_id":"\(gameID)","guess":"\(guess)"}
    """
    let guessCmd = "curl -s -X POST https://mastermind.darkube.app/guess -H 'Content-Type: application/json' -d '\(json)'"
    let guessOutput = shell(guessCmd)
    print("Server response:", guessOutput)
    if guessOutput.contains("\"black\":4") {
        print("Congratulations! You guessed the code in \(attemp) attemp!")
        break
    } 
}
