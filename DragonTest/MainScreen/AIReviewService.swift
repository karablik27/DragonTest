//
//  AIReviewService.swift
//  DragonTest
//
//  Created by Верховный Маг on 25.09.2025.
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
    private let apiKey = "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" // 🔑 твой ключ OpenRouter

    func reviewAnswers(_ answers: [StudentAnswer], questions: [Questions]) async throws -> [StudentAnswer] {
        let url = URL(string: "https://openrouter.ai/api/v1/chat/completions")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        // Готовим prompt
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
        Если ответа нет, ставь { "score": 0, "comment": "Ответ отсутствует" }.
        
        Формат:
        [
          { "questionId": "id", "score": 0–10, "comment": "текст комментария" }
        ]

        Входные данные:
        [\(qaPairs)]
        """

        let body: [String: Any] = [
            "model": "deepseek/deepseek-r1",
            "messages": [
                ["role": "system", "content": "Ты ассистент-проверяющий тесты."],
                ["role": "user", "content": userPrompt]
            ]
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: req)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        guard let text = (((json?["choices"] as? [[String: Any]])?.first?["message"] as? [String: Any])?["content"] as? String)
        else {
            throw NSError(domain: "AIReviewService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Нет контента от DeepSeek"])
        }

        print("⚡️ RAW DeepSeek response:\n\(text)\n")

        // --- Попытка 1: напрямую декодировать ---
        if let result = try? decodeReviews(from: text) {
            print("✅ Parsed as JSON directly: \(result)")
            return mergeEnsuringCompleteness(answers, with: result)
        }

        // --- Попытка 2: найти JSON внутри текста ---
        if let extracted = extractJSON(from: text),
           let result = try? decodeReviews(from: extracted) {
            print("✅ Parsed after JSON extraction: \(result)")
            return mergeEnsuringCompleteness(answers, with: result)
        }

        throw NSError(domain: "AIReviewService", code: 2, userInfo: [NSLocalizedDescriptionKey: "DeepSeek вернул некорректный JSON"])
    }

    // MARK: - Helpers
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

    /// Объединяем ответы с результатами LLM, добавляем заглушки для пропущенных
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
