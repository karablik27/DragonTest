//
//  ProfilePresenter.swift
//  DragonTest
//
//  Created by Крючков Сергей on 27.09.2025.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

final class ProfilePresenter: ProfilePresenterProtocol {

    // MARK: - DI
    private let di = DependencyInjection.shared
    private let db: Firestore
    private let auth: Auth

    // MARK: - Weak view
    private weak var view: ProfileViewProtocol?

    // MARK: - State
    private var currentUser: User?

    // Notifications
    private var notifications: [String] = []
    private var processedResultIds = Set<String>()
    private var teacherNotifiedResultIds = Set<String>()
    private var didEmitInitialTests = false
    private var didEmitInitialResults = false

    // Stats accumulators
    private var dragonsCount = 0
    private var excellentStudentsCount = 0
    private var studentTestsCount = 0
    private var teacherTestsCount = 0
    private var studentTeachersCount = 0
    private var teacherStudentsCount = 0
    private var studentAverageScorePercent = 0.0
    private var teacherStudentsAverageScorePercent = 0.0

    // Calendar
    private var studentActivityDates = Set<String>()
    private var teacherActivityDates = Set<String>()

    // Rating
    private var allStudentsRating: [(studentId: String, name: String, totalScore: Int, place: Int)] = []
    private var avatarsCache: [String: UIImage] = [:]

    // Listeners
    private var dragonsListener: ListenerRegistration?
    private var testsListener: ListenerRegistration?
    private var resultsListener: ListenerRegistration?
    private var studentTestsListener: ListenerRegistration?
    private var teacherTestsListener: ListenerRegistration?
    private var studentTeachersListener: ListenerRegistration?
    private var teacherStudentsListener: ListenerRegistration?
    private var studentScoreListener: ListenerRegistration?
    private var teacherScoreListener: ListenerRegistration?
    private var studentActivityListener: ListenerRegistration?
    private var teacherActivityListener: ListenerRegistration?
    private var studentsListener: ListenerRegistration?
    private var usersListener: ListenerRegistration?

    // MARK: - Init
    init(db: Firestore = Firestore.firestore(), auth: Auth = Auth.auth()) {
        self.db = db
        self.auth = auth
    }

    // MARK: - Lifecycle
    func attach(view: ProfileViewProtocol) { self.view = view }

    func viewDidLoad() {
        loadCurrentUser()
        fetchNotifications()
        fetchResultNotifications()
        // calendar data flows start inside setupStatsPipelines
    }

    func viewWillDisappear() { removeAllListeners() }

    // MARK: - Intents
    func didTapBell() {
        // Panel animation handled by View; nothing to do
    }

    func clearNotifications() {
        notifications.removeAll()
        processedResultIds.removeAll()
        teacherNotifiedResultIds.removeAll()
        didEmitInitialTests = false
        didEmitInitialResults = false
        DispatchQueue.main.async { self.view?.setNotifications([]) }
    }

    func calendarViewChanged(isWeekView: Bool) {
        // View recalculates its grid; we just ensure activity sets are fresh
        DispatchQueue.main.async { self.view?.reloadCalendar() }
    }

    // MARK: - Private: User & Avatar
    private func loadCurrentUser() {
        Task { [weak self] in
            guard let self else { return }
            do {
                guard let user = try await di.currentUser.getCurrentUser() else {
                    await MainActor.run {
                        self.view?.showAlert(title: "Ошибка", message: "Пользователь не найден")
                    }
                    return
                }

                self.currentUser = user

                let display = "\(user.surname) \(user.name)"
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                await MainActor.run {
                    self.view?.setWelcomeName(display.isEmpty ? "Пользователь" : display)
                }

                await self.loadAvatar(for: user.id)       // если у вашей модели id называется иначе, используйте его (например user.uid)
                self.setupStatsPipelines(for: user)
                self.loadRatingData()

            } catch {
                await MainActor.run {
                    self.view?.showAlert(title: "Ошибка",
                                         message: "Не удалось загрузить профиль: \(error.localizedDescription)")
                }
            }
        }
    }


    private func loadAvatar(for userId: String) async {
        do {
            let snap = try await db.collection("profilePhoto").document(userId).getDocument()
            if let base64 = snap.data()?["photoBase64"] as? String,
               !base64.isEmpty,
               let img = decodeBase64ToImage(base64) {
                await MainActor.run { self.view?.setAvatar(img) }
            } else {
                await MainActor.run { self.view?.setAvatarPlaceholder() }
            }
        } catch {
            await MainActor.run { self.view?.setAvatarPlaceholder() }
        }
    }

    private func decodeBase64ToImage(_ base64: String) -> UIImage? {
        guard let data = Data(base64Encoded: base64) else { return nil }
        return UIImage(data: data)
    }

    // MARK: - Stats pipelines
    private func setupStatsPipelines(for user: User) {
        if user.role == .student {
            loadDragonsCount(userId: user.id)
            loadStudentTestsCount(userId: user.id)
            loadStudentTeachersCount(userId: user.id)
            loadStudentAverageScore(userId: user.id)
            loadStudentActivityDates(userId: user.id)
        } else {
            loadExcellentStudentsCount(teacherId: user.id)
            loadTeacherTestsCount(teacherId: user.id)
            loadTeacherStudentsCount(teacherId: user.id)
            loadTeacherStudentsAverageScore(teacherId: user.id)
            loadTeacherActivityDates(teacherId: user.id)
        }
    }
    
    private func loadExcellentStudentsCount(teacherId: String) {
        teacherTestsListener?.remove()
        db.collection("tests")
            .whereField("teacherId", isEqualTo: teacherId)
            .addSnapshotListener { [weak self] snap, _ in
                guard let self else { return }
                var allStudentIds = Set<String>()
                snap?.documents.forEach { doc in
                    if let arr = doc.data()["studentIds"] as? [String] {
                        allStudentIds.formUnion(arr)
                    }
                }

                guard !allStudentIds.isEmpty else {
                    self.excellentStudentsCount = 0
                    self.pushStats()
                    return
                }

                self.db.collection("results")
                    .whereField("studentId", in: Array(allStudentIds))
                    .addSnapshotListener { [weak self] resultsSnap, _ in
                        guard let self else { return }
                        var excellent = Set<String>()
                        resultsSnap?.documents.forEach { d in
                            let data = d.data()
                            if let sid = data["studentId"] as? String,
                               let score = data["totalScore"] as? Int,
                               score >= 320 {
                                excellent.insert(sid)
                            }
                        }
                        self.excellentStudentsCount = excellent.count
                        self.pushStats()
                    }
            }
    }


    private func pushStats() {
        guard let user = currentUser else { return }
        let vm = ProfileStatsViewModel(
            isStudent: user.role == .student,
            dragonsCount: dragonsCount,
            studentTestsCount: studentTestsCount,
            studentTeachersCount: studentTeachersCount,
            studentAveragePercent: studentAverageScorePercent,
            excellentStudentsCount: excellentStudentsCount,
            teacherTestsCount: teacherTestsCount,
            teacherStudentsCount: teacherStudentsCount,
            teacherStudentsAveragePercent: teacherStudentsAverageScorePercent
        )
        DispatchQueue.main.async { self.view?.setStats(vm) }
    }

    private func loadDragonsCount(userId: String) {
        dragonsListener?.remove()
        dragonsListener = db.collection("results")
            .whereField("studentId", isEqualTo: userId)
            .whereField("capturedDragon", isEqualTo: true)
            .addSnapshotListener { [weak self] snap, _ in
                guard let self else { return }
                self.dragonsCount = snap?.documents.count ?? 0
                self.pushStats()
            }
    }

    private func loadStudentTestsCount(userId: String) {
        studentTestsListener?.remove()
        studentTestsListener = db.collection("results")
            .whereField("studentId", isEqualTo: userId)
            .addSnapshotListener { [weak self] snap, _ in
                guard let self else { return }
                let unique = Set(snap?.documents.compactMap { $0.data()["testId"] as? String } ?? [])
                self.studentTestsCount = unique.count
                self.pushStats()
            }
    }

    private func loadTeacherTestsCount(teacherId: String) {
        teacherTestsListener?.remove()
        teacherTestsListener = db.collection("tests")
            .whereField("teacherId", isEqualTo: teacherId)
            .addSnapshotListener { [weak self] snap, _ in
                guard let self else { return }
                self.teacherTestsCount = snap?.documents.count ?? 0
                self.pushStats()
            }
    }

    private func loadStudentTeachersCount(userId: String) {
        studentTeachersListener?.remove()
        studentTeachersListener = db.collection("tests")
            .whereField("studentIds", arrayContains: userId)
            .addSnapshotListener { [weak self] snap, _ in
                guard let self else { return }
                let unique = Set(snap?.documents.compactMap { $0.data()["teacherId"] as? String } ?? [])
                self.studentTeachersCount = unique.count
                self.pushStats()
            }
    }

    private func loadTeacherStudentsCount(teacherId: String) {
        teacherStudentsListener?.remove()
        teacherStudentsListener = db.collection("tests")
            .whereField("teacherId", isEqualTo: teacherId)
            .addSnapshotListener { [weak self] snap, _ in
                guard let self else { return }
                var all = Set<String>()
                snap?.documents.forEach { doc in
                    if let arr = doc.data()["studentIds"] as? [String] { all.formUnion(arr) }
                }
                self.teacherStudentsCount = all.count
                self.pushStats()
            }
    }

    private func loadStudentAverageScore(userId: String) {
        studentScoreListener?.remove()
        studentScoreListener = db.collection("results")
            .whereField("studentId", isEqualTo: userId)
            .addSnapshotListener { [weak self] snap, _ in
                guard let self else { return }
                guard let docs = snap?.documents, !docs.isEmpty else {
                    self.studentAverageScorePercent = 0
                    self.pushStats(); return
                }
                let total = docs.reduce(0) { $0 + (($1.data()["totalScore"] as? Int) ?? 0) }
                let avg = Double(total) / Double(docs.count)
                self.studentAverageScorePercent = max(0, min(100, (avg / 400.0) * 100.0))
                self.pushStats()
            }
    }

    private func loadTeacherStudentsAverageScore(teacherId: String) {
        teacherScoreListener?.remove()
        teacherScoreListener = db.collection("tests")
            .whereField("teacherId", isEqualTo: teacherId)
            .addSnapshotListener { [weak self] snap, _ in
                guard let self else { return }
                var all = Set<String>()
                snap?.documents.forEach { doc in
                    if let arr = doc.data()["studentIds"] as? [String] { all.formUnion(arr) }
                }
                guard !all.isEmpty else {
                    self.teacherStudentsAverageScorePercent = 0
                    self.pushStats(); return
                }
                self.db.collection("results").whereField("studentId", in: Array(all)).getDocuments { snapshot, _ in
                    guard let docs = snapshot?.documents, !docs.isEmpty else {
                        self.teacherStudentsAverageScorePercent = 0; self.pushStats(); return
                    }
                    var studentScores: [String: [Int]] = [:]
                    for d in docs {
                        let data = d.data()
                        guard let sid = data["studentId"] as? String, let s = data["totalScore"] as? Int else { continue }
                        studentScores[sid, default: []].append(s)
                    }
                    let avgs = studentScores.values.compactMap { arr -> Double? in
                        guard !arr.isEmpty else { return nil }
                        return Double(arr.reduce(0, +)) / Double(arr.count)
                    }
                    let overall = avgs.isEmpty ? 0.0 : avgs.reduce(0, +) / Double(avgs.count)
                    self.teacherStudentsAverageScorePercent = max(0, min(100, (overall / 400.0) * 100.0))
                    self.pushStats()
                }
            }
    }

    private func loadStudentActivityDates(userId: String) {
        studentActivityListener?.remove()
        studentActivityListener = db.collection("attempts")
            .whereField("studentId", isEqualTo: userId)
            .addSnapshotListener { [weak self] snap, _ in
                guard let self else { return }
                var dates = Set<String>()
                let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"
                snap?.documents.forEach { doc in
                    if let ts = doc.data()["submittedAt"] as? Timestamp {
                        dates.insert(fmt.string(from: ts.dateValue()))
                    }
                }
                self.studentActivityDates = dates
                DispatchQueue.main.async {
                    self.view?.setActivityDates(student: self.studentActivityDates, teacher: self.teacherActivityDates)
                    self.view?.reloadCalendar()
                }
            }
    }

    private func loadTeacherActivityDates(teacherId: String) {
        teacherActivityListener?.remove()
        teacherActivityListener = db.collection("tests")
            .whereField("teacherId", isEqualTo: teacherId)
            .addSnapshotListener { [weak self] snap, _ in
                guard let self else { return }
                var dates = Set<String>()
                let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"
                snap?.documents.forEach { doc in
                    if let ts = doc.data()["time"] as? Timestamp {
                        dates.insert(fmt.string(from: ts.dateValue()))
                    }
                }
                self.teacherActivityDates = dates
                DispatchQueue.main.async {
                    self.view?.setActivityDates(student: self.studentActivityDates, teacher: self.teacherActivityDates)
                    self.view?.reloadCalendar()
                }
            }
    }

    // MARK: - Notifications
    private func fetchNotifications() {
        guard let userId = di.currentUser.userId else { return }
        db.collection("tests")
            .whereField("studentIds", arrayContains: userId)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self else { return }
                guard let snapshot = snapshot else { return }

                if !self.didEmitInitialTests {
                    self.didEmitInitialTests = true
                    let items = snapshot.documents.map { doc -> String in
                        let data = doc.data()
                        let testTitle = data["title"] as? String ?? "Тест"
                        return "Вы приглашены в тест:\n\(testTitle)"
                    }
                    self.prependNotifications(items)
                    DispatchQueue.main.async { self.view?.setNotifications(self.notifications) }
                    return
                }

                let added = snapshot.documentChanges.filter { $0.type == .added }
                guard !added.isEmpty else { return }

                let newItems = added.map { change -> String in
                    let data = change.document.data()
                    let testTitle = data["title"] as? String ?? "Тест"
                    return "Вы приглашены в тест:\n\(testTitle)"
                }

                self.prependNotifications(newItems)
                DispatchQueue.main.async {
                    self.view?.setNotifications(self.notifications)
                    NotificationCenter.default.post(name: .newTestNotification, object: nil)
                }
            }
    }

    private func fetchResultNotifications() {
        guard let userId = di.currentUser.userId else { return }
        db.collection("results")
            .whereField("studentId", isEqualTo: userId)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self else { return }
                guard let snapshot = snapshot else { return }

                if !self.didEmitInitialResults {
                    self.didEmitInitialResults = true
                    let group = DispatchGroup()
                    var built: [String] = []

                    for doc in snapshot.documents {
                        let resultId = doc.documentID
                        if self.processedResultIds.contains(resultId) { continue }
                        self.processedResultIds.insert(resultId)

                        let data = doc.data()
                        let testScore = data["totalScore"] as? Int ?? 0
                        let testId = data["testId"] as? String ?? ""
                        let teacherComment = data["teacherComment"] as? String
                        let hasTeacher = (teacherComment?.isEmpty == false)

                        group.enter()
                        self.fetchTestNameByTestId(testId: testId) { testTitle in
                            let title = testTitle ?? "Не найдено!"
                            if hasTeacher {
                                self.fetchTeacherShortNameByTestId(testId: testId) { teacherShort in
                                    let teacher = teacherShort ?? "Преподаватель"
                                    built.append("Итоговая оценка\nТест: \(title)\nПроверено: \(teacher)\nВаш балл: \(testScore)")
                                    self.teacherNotifiedResultIds.insert(resultId)
                                    group.leave()
                                }
                            } else {
                                built.append("Предварительная оценка\nТест: \(title)\nПроверено: Автоматическая проверка\nВаш балл: \(testScore)")
                                group.leave()
                            }
                        }
                    }

                    group.notify(queue: .main) {
                        guard !built.isEmpty else { return }
                        self.prependNotifications(built)
                        self.view?.setNotifications(self.notifications)
                    }
                    return
                }

                // Added
                let added = snapshot.documentChanges.filter { $0.type == .added }
                if !added.isEmpty {
                    let group = DispatchGroup()
                    var built: [String] = []

                    for change in added {
                        let doc = change.document
                        let resultId = doc.documentID
                        if self.processedResultIds.contains(resultId) { continue }
                        self.processedResultIds.insert(resultId)

                        let data = doc.data()
                        let testScore = data["totalScore"] as? Int ?? 0
                        let testId = data["testId"] as? String ?? ""
                        let teacherComment = data["teacherComment"] as? String
                        let hasTeacher = (teacherComment?.isEmpty == false)

                        group.enter()
                        self.fetchTestNameByTestId(testId: testId) { testTitle in
                            let title = testTitle ?? "Не найдено!"
                            if hasTeacher {
                                self.fetchTeacherShortNameByTestId(testId: testId) { teacherShort in
                                    let teacher = teacherShort ?? "Преподаватель"
                                    built.append("Итоговая оценка\nТест: \(title)\nПроверено: \(teacher)\nВаш балл: \(testScore)")
                                    self.teacherNotifiedResultIds.insert(resultId)
                                    group.leave()
                                }
                            } else {
                                built.append("Предварительная оценка\nТест: \(title)\nПроверено: Автоматическая проверка\nВаш балл: \(testScore)")
                                group.leave()
                            }
                        }
                    }

                    group.notify(queue: .main) {
                        guard !built.isEmpty else { return }
                        self.prependNotifications(built)
                        self.view?.setNotifications(self.notifications)
                        NotificationCenter.default.post(name: .newResultNotification, object: nil)
                    }
                }

                // Modified (teacher finalization)
                let modified = snapshot.documentChanges.filter { $0.type == .modified }
                if !modified.isEmpty {
                    let group = DispatchGroup()
                    var built: [String] = []

                    for change in modified {
                        let doc = change.document
                        let resultId = doc.documentID

                        let data = doc.data()
                        let testScore = data["totalScore"] as? Int ?? 0
                        let testId = data["testId"] as? String ?? ""
                        let teacherComment = data["teacherComment"] as? String
                        let hasTeacher = (teacherComment?.isEmpty == false)

                        guard hasTeacher, !self.teacherNotifiedResultIds.contains(resultId) else { continue }
                        self.teacherNotifiedResultIds.insert(resultId)

                        group.enter()
                        self.fetchTestNameByTestId(testId: testId) { testTitle in
                            let title = testTitle ?? "Не найдено!"
                            self.fetchTeacherShortNameByTestId(testId: testId) { teacherShort in
                                let teacher = teacherShort ?? "Преподаватель"
                                built.append("Итоговая оценка\nТест: \(title)\nПроверено: \(teacher)\nВаш балл: \(testScore)")
                                group.leave()
                            }
                        }
                    }

                    group.notify(queue: .main) {
                        guard !built.isEmpty else { return }
                        self.prependNotifications(built)
                        self.view?.setNotifications(self.notifications)
                        NotificationCenter.default.post(name: .newResultNotification, object: nil)
                    }
                }
            }
    }

    private func prependNotifications(_ items: [String]) {
        guard !items.isEmpty else { return }
        for item in items.reversed() { notifications.insert(item, at: 0) }
    }

    // MARK: - Helpers (test & teacher names)
    private func fetchTestNameByTestId(testId: String, completion: @escaping (String?) -> Void) {
        guard !testId.isEmpty else { completion(nil); return }
        let tests = db.collection("tests")
        tests.document(testId).getDocument { doc, _ in
            if let doc = doc, doc.exists {
                completion(doc.data()?["title"] as? String)
            } else {
                tests.whereField("testId", isEqualTo: testId).getDocuments { snap, _ in
                    completion(snap?.documents.first?.data()["title"] as? String)
                }
            }
        }
    }

    private func shortTeacherName(name: String?, surname: String?, lastname: String?) -> String {
        let s = (surname ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let n = (name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let l = (lastname ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        var initials: [String] = []
        if let f = n.first { initials.append("\(f).") }
        if let f = l.first { initials.append("\(f).") }
        if s.isEmpty && initials.isEmpty { return "Преподаватель" }
        if s.isEmpty { return initials.joined(separator: " ") }
        if initials.isEmpty { return s }
        return "\(s) \(initials.joined(separator: " "))"
    }

    private func fetchTeacherShortNameByTestId(testId: String, completion: @escaping (String?) -> Void) {
        guard !testId.isEmpty else { completion(nil); return }
        func build(from teacherId: String) {
            db.collection("users").document(teacherId).getDocument { doc, _ in
                guard let data = doc?.data() else { completion(nil); return }
                completion(self.shortTeacherName(name: data["name"] as? String,
                                                 surname: data["surname"] as? String,
                                                 lastname: data["lastname"] as? String))
            }
        }
        let tests = db.collection("tests")
        tests.document(testId).getDocument { doc, _ in
            if let data = doc?.data(), let tid = data["teacherId"] as? String {
                build(from: tid)
            } else {
                tests.whereField("testId", isEqualTo: testId).limit(to: 1).getDocuments { snap, _ in
                    if let tid = snap?.documents.first?.data()["teacherId"] as? String { build(from: tid) }
                    else { completion(nil) }
                }
            }
        }
    }

    // MARK: - Rating
    private func loadRatingData() {
        studentsListener?.remove()
        studentsListener = db.collection("results")
            .whereField("teacherComment", isGreaterThan: "")
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self, let docs = snapshot?.documents else { return }
                var totals: [String: Int] = [:]
                for d in docs {
                    let data = d.data()
                    guard let sid = data["studentId"] as? String,
                          let score = data["totalScore"] as? Int else { continue }
                    totals[sid, default: 0] += score
                }
                self.processStudentScores(totals)
            }
    }

    private func processStudentScores(_ totals: [String: Int]) {
        guard !totals.isEmpty else {
            DispatchQueue.main.async {
                self.allStudentsRating = []
                self.avatarsCache = [:]
                self.view?.setRating([], avatars: [:])
            }
            return
        }
        let group = DispatchGroup()
        var enriched: [(studentId: String, name: String, totalScore: Int, avatar: UIImage?)] = []

        for (sid, score) in totals {
            group.enter()
            db.collection("users").document(sid).getDocument { [weak self] doc, _ in
                guard let self else { group.leave(); return }
                let data = doc?.data() ?? [:]
                let display = self.formatStudentName(
                    name: data["name"] as? String ?? "",
                    surname: data["surname"] as? String ?? "",
                    lastname: data["lastname"] as? String ?? ""
                )
                self.db.collection("profilePhoto").document(sid).getDocument { photoDoc, _ in
                    var avatar: UIImage? = nil
                    if let p = photoDoc?.data(),
                       let b64 = p["photoBase64"] as? String,
                       !b64.isEmpty,
                       let img = self.decodeBase64ToImage(b64) {
                        avatar = img
                    }
                    enriched.append((sid, display, score, avatar))
                    group.leave()
                }
            }
        }

        group.notify(queue: .main) {
            let sorted = enriched.sorted { $0.totalScore > $1.totalScore }
            self.allStudentsRating = sorted.enumerated().map { idx, s in
                (s.studentId, s.name, s.totalScore, idx + 1)
            }
            self.avatarsCache = [:]
            for s in enriched { if let img = s.avatar { self.avatarsCache[s.studentId] = img } }
            let items = self.allStudentsRating.map {
                RatingItem(studentId: $0.studentId, displayName: $0.name, totalScore: $0.totalScore, place: $0.place)
            }
            self.view?.setRating(items, avatars: self.avatarsCache)
        }
    }

    private func formatStudentName(name: String, surname: String, lastname: String) -> String {
        let s = surname.trimmingCharacters(in: .whitespacesAndNewlines)
        let n = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let l = lastname.trimmingCharacters(in: .whitespacesAndNewlines)
        var initials: [String] = []
        if let f = n.first { initials.append("\(f).") }
        if let f = l.first { initials.append("\(f).") }
        if s.isEmpty && initials.isEmpty { return "Студент" }
        if s.isEmpty { return initials.joined(separator: " ") }
        if initials.isEmpty { return s }
        return "\(s) \(initials.joined(separator: " "))"
    }

    // MARK: - Cleanup
    private func removeAllListeners() {
        dragonsListener?.remove()
        testsListener?.remove()
        resultsListener?.remove()
        studentTestsListener?.remove()
        teacherTestsListener?.remove()
        studentTeachersListener?.remove()
        teacherStudentsListener?.remove()
        studentScoreListener?.remove()
        teacherScoreListener?.remove()
        studentActivityListener?.remove()
        teacherActivityListener?.remove()
        studentsListener?.remove()
        usersListener?.remove()
    }
}
