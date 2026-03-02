//
//  AIReviewService.swift
//  DragonTest
//
//  Created by Карабельников Степан on 25.09.2025.
//

import Foundation

struct LLMReview: Codable {
    let questionId: String
    let score: Int
    let comment: String
}

protocol AIReviewServiceProtocol {
    func reviewAnswers(_ answers: [StudentAnswer], questions: [Questions]) async throws -> [StudentAnswer]
}

final class AIReviewService: AIReviewServiceProtocol {
    private let apiKeys: [String] = [
        Secrets.aiApiKey1,
        Secrets.aiApiKey2,
        Secrets.aiApiKey3,
        Secrets.aiApiKey4,
        Secrets.aiApiKey5
    ]

    func reviewAnswers(_ answers: [StudentAnswer], questions: [Questions]) async throws -> [StudentAnswer] {
        guard !answers.isEmpty else { return answers }

        if !hasMeaningfulAnswer(in: answers) {
            return missingAnswerFallback(for: answers)
        }

        var lastError: Error?

        for key in apiKeys {
            do {
                return try await performReview(answers, questions: questions, apiKey: key)
            } catch {
                if isRateLimitError(error) {
                    lastError = error
                    continue
                } else {
                    throw error
                }
            }
        }

        throw lastError ?? NSError(
            domain: "AIReviewService",
            code: 999,
            userInfo: [NSLocalizedDescriptionKey: "Все ключи исчерпали лимит запросов"]
        )
    }

    private func performReview(_ answers: [StudentAnswer], questions: [Questions], apiKey: String) async throws -> [StudentAnswer] {
        let url = URL(string: Secrets.aiUrlKey)!
        var req = URLRequest(url: url)

        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let qaPairs = answers.map { ans -> String in
            let qText = questions.first(where: { $0.id == ans.questionId })?.text ?? "???"
            let aText = ans.textAnswer ?? (ans.selectedIndex.map { "Вариант №\($0+1)" } ?? "—")
            return """
            {
              "questionId": "\(ans.questionId)",
              "question": "\(qText)",
              "answer": "\(aText)"
            }
            """
        }.joined(separator: ",\n")

        let userPrompt = """
        Ты проверяешь ответы студентов. Верни строго JSON-массив с результатами для каждого ответа.
        ⚠️ ВАЖНО: в массиве должен быть объект для КАЖДОГО вопроса из входных данных.
        Если ответа нет, ставь { "questionId": "id", "score": 0, "comment": "Ответ отсутствует" }.
        
        Формат:
        [
          { "questionId": "id", "score": 0–10, "comment": "текст комментария" }
        ]

        Входные данные:
        [\(qaPairs)]
        """

        let body: [String: Any] = [
            "model": "qwen/qwen-2.5-7b-instruct",
            "messages": [
                ["role": "system", "content": "Ты ассистент-проверяющий тесты."],
                ["role": "user", "content": userPrompt]
            ]
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: req)

        // Проверка лимитов по HTTP статусу
        if let http = response as? HTTPURLResponse, http.statusCode == 429 {
            throw NSError(
                domain: "AIReviewService",
                code: 429,
                userInfo: [NSLocalizedDescriptionKey: "Лимит запросов по ключу исчерпан"]
            )
        }

        let rawResponse = String(data: data, encoding: .utf8) ?? ""
        let candidates = extractResponseCandidates(from: data, rawResponse: rawResponse)

        for candidate in candidates {
            if let parsed = parseReviews(from: candidate) {
                print("⚡️ RAW DeepSeek response:\n\(candidate)\n")
                print("✅ Parsed after normalization: \(parsed)")
                return mergeEnsuringCompleteness(answers, with: parsed)
            }
        }

        throw NSError(
            domain: "AIReviewService",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Нет контента от DeepSeek"]
        )
    }

    private func isRateLimitError(_ error: Error) -> Bool {
        let ns = error as NSError
        return ns.domain == "AIReviewService" && ns.code == 429
    }

    private func hasMeaningfulAnswer(in answers: [StudentAnswer]) -> Bool {
        answers.contains { answer in
            if answer.selectedIndex != nil { return true }
            let text = (answer.textAnswer ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            return !text.isEmpty && text != "—"
        }
    }

    private func missingAnswerFallback(for answers: [StudentAnswer]) -> [StudentAnswer] {
        answers.map { answer in
            var updated = answer
            updated.llmScore = 0
            updated.llmComment = "Ответ отсутствует"
            return updated
        }
    }

    private func parseReviews(from text: String) -> [LLMReview]? {
        if let direct = try? decodeReviews(from: text) {
            return direct
        }

        if let extracted = extractJSON(from: text),
           let extractedResult = try? decodeReviews(from: extracted) {
            return extractedResult
        }

        return nil
    }

    private func extractResponseCandidates(from data: Data, rawResponse: String) -> [String] {
        var candidates: [String] = []

        if let object = try? JSONSerialization.jsonObject(with: data) {
            candidates.append(contentsOf: collectCandidateStrings(from: object))
        }

        if !rawResponse.isEmpty {
            candidates.append(rawResponse)
        }

        var seen = Set<String>()
        var unique: [String] = []
        for candidate in candidates {
            let trimmed = candidate.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            guard !seen.contains(trimmed) else { continue }
            seen.insert(trimmed)
            unique.append(trimmed)
        }
        return unique
    }

    private func collectCandidateStrings(from node: Any) -> [String] {
        switch node {
        case let text as String:
            return [text]

        case let dictionary as [String: Any]:
            var collected: [String] = []

            if let content = dictionary["content"] as? String {
                collected.append(content)
            }

            if let parts = dictionary["content"] as? [[String: Any]] {
                for part in parts {
                    if let text = part["text"] as? String {
                        collected.append(text)
                    }
                    if let text = part["content"] as? String {
                        collected.append(text)
                    }
                }
            }

            if let reasoning = dictionary["reasoning_content"] as? String {
                collected.append(reasoning)
            }
            if let reasoning = dictionary["reasoning"] as? String {
                collected.append(reasoning)
            }

            for value in dictionary.values {
                collected.append(contentsOf: collectCandidateStrings(from: value))
            }
            return collected

        case let array as [Any]:
            return array.flatMap { collectCandidateStrings(from: $0) }

        default:
            return []
        }
    }

    private func decodeReviews(from text: String) throws -> [LLMReview] {
        guard let data = text.data(using: .utf8) else {
            throw NSError(domain: "AIReviewService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Пустая строка"])
        }
        return try JSONDecoder().decode([LLMReview].self, from: data)
    }

    private func extractJSON(from text: String) -> String? {
        guard let start = text.firstIndex(of: "["),
              let end = text.lastIndex(of: "]") else {
            return nil
        }
        return String(text[start...end])
    }

    private func mergeEnsuringCompleteness(_ answers: [StudentAnswer], with reviews: [LLMReview]) -> [StudentAnswer] {
        return answers.map { ans in
            var updated = ans
            if let review = reviews.first(where: { $0.questionId == ans.questionId }) {
                updated.llmScore = review.score
                updated.llmComment = review.comment
            } else {
                updated.llmScore = 0
                updated.llmComment = "ИИ не вернул оценку → автоматически помечено как 'Ответ отсутствует'"
            }
            return updated
        }
    }
}
