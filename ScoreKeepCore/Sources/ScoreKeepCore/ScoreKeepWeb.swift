//
//  ScoreKeepWeb.swift
//  ScoreKeep
//
//  Created by Chris Sauve on 2025-11-09.
//

import Foundation

public struct ScoreKeepWeb {
    // Payloads that mirror the zod schemas:
    // ShareMatchTeamSchema, ShareMatchSportSchema, ShareMatchGameSchema,
    // ShareMatchSetSchema, ShareMatchMatchSchema, ShareMatchRequestSchema
    private struct ShareableRequest: Codable {
        let match: ShareableMatch
    }

    private struct ShareableMatch: Codable {
        let sport: String // enum rawValue from MatchSport
        let startedAt: Date
        let endedAt: Date?
        let sets: [ShareableSet]
        let winner: String? // "us" | "them"
    }

    private struct ShareableSet: Codable {
        let startedAt: Date
        let endedAt: Date?
        let games: [ShareableGame]
        let winner: String? // "us" | "them"
    }

    private struct ShareableGame: Codable {
        let startedAt: Date
        let endedAt: Date?
        let scoreUs: Int
        let scoreThem: Int
        let winner: String? // "us" | "them"
    }
    
    // Response payload: { url: string }
    public struct ShareResponse: Codable {
        public let url: URL

        // Support servers that return url as a string; Foundation will decode URL from string automatically.
        // If the API sometimes returns invalid URLs, callers should catch decoding errors.
    }

    public enum WebError: Error {
        case badURL
        case encodingFailed
        case decodingFailed
        case invalidResponse
        case serverError(statusCode: Int, body: String?)
    }
    
    public init() {}

    /// Shares a match with the ScoreKeep web service by posting a GraphQL mutation.
    /// The mutation is named `createMatch` and accepts various parameters for the match.
    /// - Parameter match: Your app's `ScoreKeepMatch` model instance.
    /// - Returns: A `ShareResponse` containing the URL constructed from the returned match ID.
    /// - Throws: `WebError` or underlying `URLError`.
    @discardableResult
    public func share(match: ScoreKeepMatch) async throws -> ShareResponse {
        guard let url = URL(string: "https://scorekeep.watch/graphql") else {
            throw WebError.badURL
        }

        let iso8601 = ISO8601DateFormatter()
        iso8601.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        // Prepare variables conforming to the mutation input signature
        let sport = match.sport.rawValue
        let startedAt = iso8601.string(from: match.startedAt)
        let endedAt = match.endedAt.map { iso8601.string(from: $0) }
        let winner = match.winner?.rawValue

        let sets: [[String: Any]] = match.sets.map { set in
            let setStartedAt = iso8601.string(from: set.startedAt)
            let setEndedAt = set.endedAt.map { iso8601.string(from: $0) }
            let setWinner = set.winner?.rawValue

            let games: [[String: Any]] = set.games.map { game in
                var gameDict: [String: Any] = [
                    "startedAt": iso8601.string(from: game.startedAt),
                    "scoreUs": game.scoreUs,
                    "scoreThem": game.scoreThem
                ]
                if let endedAt = game.endedAt {
                    gameDict["endedAt"] = iso8601.string(from: endedAt)
                }
                if let winner = game.winner?.rawValue {
                    gameDict["winner"] = winner
                }
                return gameDict
            }

            var setDict: [String: Any] = [
                "startedAt": setStartedAt,
                "games": games
            ]
            if let endedAt = setEndedAt {
                setDict["endedAt"] = endedAt
            }
            if let winner = setWinner {
                setDict["winner"] = winner
            }
            return setDict
        }

        let variables: [String: Any?] = [
            "sport": sport,
            "startedAt": startedAt,
            "endedAt": endedAt as Any,
            "winner": winner as Any,
            "sets": sets,
            "userId": nil
        ]

        let query = """
        mutation CreateMatch($sport: MatchSport!, $startedAt: String!, $endedAt: String, $winner: MatchTeam, $sets: [MatchSetInput!]!, $userId: ID) {
          createMatch(sport: $sport, startedAt: $startedAt, endedAt: $endedAt, winner: $winner, sets: $sets, userId: $userId) {
            match {
              id
            }
            errors {
              message
            }
          }
        }
        """

        // Remove nil values from variables dictionary
        let cleanedVariables = variables.compactMapValues { $0 }

        let requestBody: [String: Any] = [
            "query": query,
            "variables": cleanedVariables
        ]

        let bodyData: Data
        do {
            bodyData = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        } catch {
            throw WebError.encodingFailed
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyData

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw WebError.invalidResponse
        }

        guard (200..<300).contains(http.statusCode) else {
            let bodyString = String(data: data, encoding: .utf8)
            throw WebError.serverError(statusCode: http.statusCode, body: bodyString)
        }

        // Response expected:
        // {
        //   "data": {
        //     "createMatch": {
        //       "match": { "id": String },
        //       "errors": [ { "message": String }, ... ]
        //     }
        //   }
        // }

        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            guard
                let dict = jsonObject as? [String: Any],
                let dataDict = dict["data"] as? [String: Any],
                let createMatchDict = dataDict["createMatch"] as? [String: Any]
            else {
                throw WebError.decodingFailed
            }

            if let errors = createMatchDict["errors"] as? [[String: Any]], !errors.isEmpty {
                let messages = errors.compactMap { $0["message"] as? String }.joined(separator: "; ")
                throw WebError.serverError(statusCode: http.statusCode, body: messages)
            }

            guard
                let matchDict = createMatchDict["match"] as? [String: Any],
                let id = matchDict["id"] as? String,
                let url = URL(string: "https://scorekeep.watch/match/\(id)")
            else {
                throw WebError.decodingFailed
            }

            return ShareResponse(url: url)
        } catch {
            throw WebError.decodingFailed
        }
    }
    
    
    // MARK: - Mapping helpers

    private func makeShareableMatch(from match: ScoreKeepMatch) -> ShareableMatch {
        let sportRaw = match.sport.rawValue // matches zod enum
        let sets = match.sets.map { set in
            ShareableSet(
                startedAt: set.startedAt,
                endedAt: set.endedAt,
                games: set.games.map { game in
                    ShareableGame(
                        startedAt: game.startedAt,
                        endedAt: game.endedAt,
                        scoreUs: game.scoreUs,
                        scoreThem: game.scoreThem,
                        winner: game.winner?.rawValue
                    )
                },
                winner: set.winner?.rawValue
            )
        }

        return ShareableMatch(
            sport: sportRaw,
            startedAt: match.startedAt,
            endedAt: match.endedAt,
            sets: sets,
            winner: match.winner?.rawValue
        )
    }

    /// Converts a Codable ShareableMatch into a dictionary suitable for GraphQL variables.
    /// Uses JSONEncoder -> JSONSerialization to produce [String: Any].
    private func convertToDictionary(_ shareableMatch: ShareableMatch) throws -> [String: Any] {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(shareableMatch)
        let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
        guard let dict = jsonObject as? [String: Any] else {
            throw WebError.encodingFailed
        }
        return dict
    }

}
