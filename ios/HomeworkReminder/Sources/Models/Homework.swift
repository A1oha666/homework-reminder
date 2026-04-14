import Foundation

struct Homework: Codable {
    let id: String
    let name: String
    let deadline: String
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id, name, deadline
        case createdAt = "created_at"
    }

    var deadlineDate: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: deadline)
    }

    var remainingTimeDescription: String {
        guard let date = deadlineDate else { return "无效日期" }

        let calendar = Calendar.current
        var deadlineWith23 = calendar.date(bySettingHour: 23, minute: 0, second: 0, of: date)!

        let now = Date()
        let remaining = deadlineWith23.timeIntervalSince(now)

        if remaining < 0 {
            return "已截止"
        }

        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60

        if hours > 24 {
            let days = hours / 24
            return "\(days) 天后截止"
        } else if hours > 0 {
            return "\(hours) 小时 \(minutes) 分钟"
        } else {
            return "\(minutes) 分钟后截止"
        }
    }

    var isUrgent: Bool {
        guard let date = deadlineDate else { return false }
        let calendar = Calendar.current
        var deadlineWith23 = calendar.date(bySettingHour: 23, minute: 0, second: 0, of: date)!
        let remaining = deadlineWith23.timeIntervalSince(Date())
        return remaining >= 0 && remaining < 24 * 3600
    }

    var isOverdue: Bool {
        guard let date = deadlineDate else { return false }
        let calendar = Calendar.current
        var deadlineWith23 = calendar.date(bySettingHour: 23, minute: 0, second: 0, of: date)!
        return Date() > deadlineWith23
    }
}

struct APIResponse<T: Codable>: Codable {
    let code: Int
    let data: T?
    let msg: String?
}

struct HomeworkListResponse: Codable {
    let code: Int
    let data: [Homework]?
    let msg: String?
}
