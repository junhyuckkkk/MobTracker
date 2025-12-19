import Foundation
import UserNotifications

class NotificationService {
    static let shared = NotificationService()
    
    private init() {}
    
    // MARK: - Request Permission
    
    func requestPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    print("Notification permission granted")
                    self.scheduleDailyReminder()
                } else {
                    print("Notification permission denied: \(error?.localizedDescription ?? "Unknown")")
                }
                completion(granted)
            }
        }
    }
    
    // MARK: - Schedule Daily Reminder (11:40 PM)
    
    func scheduleDailyReminder() {
        let center = UNUserNotificationCenter.current()
        
        // Remove existing notifications first
        center.removePendingNotificationRequests(withIdentifiers: ["dailyEarningsReminder"])
        
        // Create content
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("notification_title", comment: "")
        content.body = NSLocalizedString("notification_body", comment: "")
        content.sound = .default
        
        // Set trigger for 11:40 PM every day
        var dateComponents = DateComponents()
        dateComponents.hour = 23
        dateComponents.minute = 40
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        // Create request
        let request = UNNotificationRequest(
            identifier: "dailyEarningsReminder",
            content: content,
            trigger: trigger
        )
        
        // Schedule
        center.add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error.localizedDescription)")
            } else {
                print("Daily reminder scheduled for 11:40 PM")
            }
        }
    }
    
    // MARK: - Cancel Notifications
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
