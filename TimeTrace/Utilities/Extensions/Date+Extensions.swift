//
//  Date+Extensions.swift
//  TimeTrace
//
//  Created by Claude Code on 2/2/26.
//

import Foundation

extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay) ?? self
    }

    var startOfWeek: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: components) ?? self
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }

    var isThisWeek: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .weekOfYear)
    }

    func minutesSince(_ date: Date) -> Int {
        let interval = self.timeIntervalSince(date)
        return Int(interval / 60)
    }

    func formatted(as style: DateFormattingStyle) -> String {
        let formatter = DateFormatter()

        switch style {
        case .time:
            formatter.timeStyle = .short
            formatter.dateStyle = .none
        case .date:
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
        case .dateTime:
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
        case .relative:
            if isToday {
                return "Today"
            } else if isYesterday {
                return "Yesterday"
            } else {
                formatter.dateStyle = .medium
                formatter.timeStyle = .none
            }
        }

        return formatter.string(from: self)
    }

    enum DateFormattingStyle {
        case time
        case date
        case dateTime
        case relative
    }
}
