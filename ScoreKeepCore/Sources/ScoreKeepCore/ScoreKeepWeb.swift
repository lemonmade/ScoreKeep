//
//  ScoreKeepWeb.swift
//  ScoreKeep
//
//  Created by Chris Sauve on 2025-11-09.
//

import Foundation
import ScoreKeepCore

struct ScoreKeepWeb {
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
    struct ShareResponse: Codable {
        let url: URL

        // Support servers that return url as a string; Foundation will decode URL from string automatically.
        // If the API sometimes returns invalid URLs, callers should catch decoding errors.
    }

    enum WebError: Error {
        case badURL
        case encodingFailed
        case decodingFailed
        case invalidResponse
        case serverError(statusCode: Int, body: String?)
    }

    // MARK: - Mapping helpers

    private func makeShareableMatch(from match: Match) -> ShareableMatch {
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

    /// Shares a match with the ScoreKeep web service by posting a simplified JSON payload.
    /// The payload conforms to the provided zod schema.
    /// - Parameter match: Your app's `Match` model instance.
    /// - Returns: Raw `Data` from the server response, which you can decode as needed.
    /// - Throws: `WebError` or underlying `URLError`.
    @discardableResult
    func share(match: Match) async throws -> ShareResponse {
        guard let url = URL(string: "https://scorekeep.watch/.internal/share-match") else {
            throw WebError.badURL
        }

        // Build payload per schema: { match: { ... } }
        let shareable = makeShareableMatch(from: match)
        let requestBody = ShareableRequest(match: shareable)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let body = try? encoder.encode(requestBody) else {
            throw WebError.encodingFailed
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw WebError.invalidResponse
        }

        guard (200..<300).contains(http.statusCode) else {
            let bodyString = String(data: data, encoding: .utf8)
            throw WebError.serverError(statusCode: http.statusCode, body: bodyString)
        }
        
        let decoder = JSONDecoder()
        // If server sends ISO8601 dates elsewhere in future, this keeps consistency.
        decoder.dateDecodingStrategy = .iso8601
        do {
            let response = try decoder.decode(ShareResponse.self, from: data)
            return response
        } catch {
            throw WebError.decodingFailed
        }
    }
}
