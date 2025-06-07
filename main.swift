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


func deleteGame(gameID: String) {
    let deleteCmd = "curl -s -o /dev/null -w \"%{http_code}\" -X DELETE https://mastermind.darkube.app/game/\(gameID)"
    let statusCode = shell(deleteCmd).trimmingCharacters(in: .whitespacesAndNewlines)
    if statusCode == "204" {
        print("Game deleted successfully from server.")
    } else if statusCode == "404" {
        print("Game not found on server (maybe already deleted).")
    } else {
        print("Failed to delete game from server (HTTP \(statusCode)).")
    }
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
        print("\nDo you want to delete your game from server? (y/n): ", terminator: "")
        if let answer = readLine(), answer.lowercased() == "y" {
            deleteGame(gameID: gameID)
            print("Goodby!")
            break
        } else {
            print("Game not deleted from server.\n Goodby!")
            break
        }
    } 
}
