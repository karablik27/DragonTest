import UIKit

// MARK: - UIViewController Localization Extension
extension UIViewController {
    
    func setupAutoLocalization() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleLanguageChange),
            name: .languageChanged,
            object: nil
        )
    }
    
    @objc private func handleLanguageChange() {
        updateLocalization()
    }
    
    @objc open func updateLocalization() {
        if let title = self.title, !title.isEmpty {
            if title.contains(".") {
                self.title = title.localized
            }
        }
    }
    
    @objc func removeLocalizationObserver() {
        NotificationCenter.default.removeObserver(self, name: .languageChanged, object: nil)
    }
} 