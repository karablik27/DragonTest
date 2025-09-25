//
//  AppDelegate.swift
//  DragonTest
//
//  Created by Карабельников Степан on 16.09.2025.
//

import UIKit
import RealityKit
import FirebaseCore
import FirebaseAppCheck
import UserNotifications
import FirebaseFirestore

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // Предзагрузка всех .usdz в память (один раз на старте)
        Task { @MainActor in
            await DependencyInjection.shared.dragonCache.preload()
        }
        
        // Firebase
        FirebaseApp.configure()

        // Запрос разрешений на отправку локальных/удаленных уведомлений
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Ошибка при запросе разрешений на уведомления: \(error.localizedDescription)")
            } else if granted {
                print("Разрешения на уведомления предоставлены.")
            } else {
                print("Разрешения на уведомления не предоставлены.")
            }
        }
        
        UNUserNotificationCenter.current().delegate = self

        NotificationCenter.default.addObserver(self, selector: #selector(handleNewTestNotification), name: .newTestNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleNewResultNotification), name: .newResultNotification, object: nil)

        return true
    }
    
    private func scheduleLocalNotification(title: String, body: String) {
        guard let userRole = DependencyInjection.shared.currentUser.role else { return }
        if (userRole == .teacher) { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Ошибка при добавлении уведомления: \(error.localizedDescription)")
            } else {
                print("Уведомление запланировано")
            }
        }
    }
    
    @objc func handleNewTestNotification() {
        scheduleLocalNotification(title: "Ios зовет ботать...", body: "Вас добавили в новый тест!")
    }

    @objc func handleNewResultNotification() { // + добавить
        scheduleLocalNotification(title: "Результаты", body: "Ваш тест проверен!")
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }

    // MARK: UISceneSession Lifecycle
    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration",
                                    sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {}
}
