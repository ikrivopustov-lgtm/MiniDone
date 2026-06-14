import Foundation

struct ParsedTaskText {
    let title: String
    let tagNames: [String]
    let projectName: String?
    let dueDate: Date?
    let recurrenceRule: TaskRecurrenceRule?
}

enum TaskTextParser {
    static func parse(_ rawText: String, now: Date = .now) -> ParsedTaskText {
        let tokens = commandTokens(in: rawText)

        var titleParts: [String] = []
        var tagNames: [String] = []
        var projectName: String?
        var dueDate: Date?
        var recurrenceRule: TaskRecurrenceRule?
        var seenTags = Set<String>()
        var index = 0

        while index < tokens.count {
            let value = tokens[index]

            if value.hasPrefix("#"), value.count > 1 {
                let tagName = normalizeTag(String(value.dropFirst()))

                if !tagName.isEmpty, !seenTags.contains(tagName) {
                    seenTags.insert(tagName)
                    tagNames.append(tagName)
                }
                index += 1
            } else if value.hasPrefix("/"), value.count > 1 {
                projectName = normalizeProjectName(String(value.dropFirst()))
                index += 1
            } else if value.hasPrefix("!"), value.count > 1 {
                let command = normalizeDueDateCommand(String(value.dropFirst()))
                let followingTokens = tokens.dropFirst(index + 1)

                if let parsedRecurrence = parseRecurrenceCommand(command, followingTokens: followingTokens, now: now) {
                    recurrenceRule = parsedRecurrence.rule
                    if dueDate == nil {
                        dueDate = parsedRecurrence.dueDate
                    }
                    index += 1 + parsedRecurrence.consumedTokens
                } else if let parsedRelativeDate = parseRelativeDueDateCommand(command, followingTokens: followingTokens, now: now) {
                    dueDate = parsedRelativeDate.date
                    index += 1 + parsedRelativeDate.consumedTokens
                } else if let parsedDate = parseDueDateCommand(command, now: now) {
                    dueDate = parsedDate
                    index += 1
                } else {
                    titleParts.append(value)
                    index += 1
                }
            } else {
                titleParts.append(value)
                index += 1
            }
        }

        return ParsedTaskText(
            title: titleParts.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines),
            tagNames: tagNames,
            projectName: projectName,
            dueDate: dueDate,
            recurrenceRule: recurrenceRule
        )
    }

    static func normalizeTag(_ rawTag: String) -> String {
        rawTag
            .trimmingCharacters(in: CharacterSet(charactersIn: "#,.;:!?()[]{}\"'"))
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    static func normalizeProjectName(_ rawProject: String) -> String {
        rawProject
            .trimmingCharacters(in: CharacterSet(charactersIn: "/,.;:!?()[]{}\"'"))
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func normalizeDueDateCommand(_ rawCommand: String) -> String {
        rawCommand
            .trimmingCharacters(in: CharacterSet(charactersIn: "!,;:()[]{}\"'"))
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    static func parseDueDateCommand(_ command: String, now: Date = .now, calendar: Calendar = .current) -> Date? {
        let normalized = normalizeDueDateCommand(command)
        guard !normalized.isEmpty else { return nil }
        let today = calendar.startOfDay(for: now)

        if ["today", "tod", "сегодня", "сег"].contains(normalized) {
            return today
        }

        if ["tomorrow", "tmr", "завтра", "зав"].contains(normalized) {
            return calendar.date(byAdding: .day, value: 1, to: today)
        }

        if ["next", "nextweek", "next-week", "след", "следнед", "след-нед", "следующая-неделя"].contains(normalized) {
            return startOfNextWeek(now: now, calendar: calendar)
        }

        if ["weekend", "выходные"].contains(normalized) {
            return upcomingWeekday(7, now: now, calendar: calendar)
        }

        if let offset = relativeDayOffset(from: normalized) {
            return calendar.date(byAdding: .day, value: offset, to: today)
        }

        if let weekday = weekdayNumber(for: normalized) {
            return upcomingWeekday(weekday, now: now, calendar: calendar)
        }

        let separators = CharacterSet(charactersIn: ".-/")
        let rawParts = normalized
            .components(separatedBy: separators)
            .filter { !$0.isEmpty }
        let parts = rawParts
            .compactMap(Int.init)

        guard parts.count == 2 || parts.count == 3 else { return nil }

        let currentYear = calendar.component(.year, from: now)
        let isISODate = rawParts.count == 3 && rawParts[0].count == 4
        let year = parts.count == 3
            ? normalizedYear(isISODate ? parts[0] : parts[2])
            : currentYear
        let month = parts[1]
        let day = isISODate ? parts[2] : parts[0]
        let components = DateComponents(year: year, month: month, day: day)

        guard let date = calendar.date(from: components) else { return nil }
        let resolvedComponents = calendar.dateComponents([.year, .month, .day], from: date)
        guard resolvedComponents.year == year,
              resolvedComponents.month == month,
              resolvedComponents.day == day else {
            return nil
        }

        return calendar.startOfDay(for: date)
    }

    private static func parseRelativeDueDateCommand(
        _ command: String,
        followingTokens: ArraySlice<String>,
        now: Date,
        calendar: Calendar = .current
    ) -> (date: Date, consumedTokens: Int)? {
        let normalized = normalizeDueDateCommand(command)
        guard ["через", "in", "after"].contains(normalized),
              let firstToken = followingTokens.first else {
            return nil
        }

        let first = normalizeDueDateCommand(firstToken)
        guard let offset = Int(first) ?? leadingInt(in: first) else { return nil }

        var consumedTokens = 1
        if let secondToken = followingTokens.dropFirst().first,
           isDayUnit(normalizeDueDateCommand(secondToken)) {
            consumedTokens = 2
        }

        let today = calendar.startOfDay(for: now)
        guard let date = calendar.date(byAdding: .day, value: offset, to: today) else { return nil }
        return (date, consumedTokens)
    }

    private static func parseRecurrenceCommand(
        _ command: String,
        followingTokens: ArraySlice<String>,
        now: Date,
        calendar: Calendar = .current
    ) -> (rule: TaskRecurrenceRule, dueDate: Date, consumedTokens: Int)? {
        let normalized = normalizeDueDateCommand(command)
        let today = calendar.startOfDay(for: now)

        if let directRule = directRecurrenceRule(for: normalized) {
            return (directRule, today, 0)
        }

        if let compactRecurrence = compactRecurrenceRule(for: normalized, now: now, calendar: calendar) {
            return compactRecurrence
        }

        if ["every", "каждый", "каждую", "каждое", "каждые"].contains(normalized),
           let firstToken = followingTokens.first {
            let first = normalizeDueDateCommand(firstToken)

            if let rule = recurrenceUnitRule(for: first) {
                return (rule, today, 1)
            }

            if let weekday = weekdayNumber(for: first) {
                return (.weekly, upcomingWeekday(weekday, now: now, calendar: calendar) ?? today, 1)
            }
        }

        if ["repeat", "повтор"].contains(normalized),
           let firstToken = followingTokens.first,
           let rule = recurrenceUnitRule(for: normalizeDueDateCommand(firstToken)) {
            return (rule, today, 1)
        }

        if normalized == "раз",
           let firstToken = followingTokens.first,
           ["в", "per"].contains(normalizeDueDateCommand(firstToken)),
           let secondToken = followingTokens.dropFirst().first,
           let rule = recurrenceUnitRule(for: normalizeDueDateCommand(secondToken)) {
            return (rule, today, 2)
        }

        return nil
    }

    private static func directRecurrenceRule(for command: String) -> TaskRecurrenceRule? {
        if ["daily", "everyday", "every-day", "ежедневно", "каждыйдень", "каждый-день"].contains(command) {
            return .daily
        }

        if ["weekly", "everyweek", "every-week", "еженедельно", "каждуюнеделю", "каждую-неделю"].contains(command) {
            return .weekly
        }

        if ["monthly", "everymonth", "every-month", "ежемесячно", "каждыймесяц", "каждый-месяц"].contains(command) {
            return .monthly
        }

        return nil
    }

    private static func compactRecurrenceRule(
        for command: String,
        now: Date,
        calendar: Calendar
    ) -> (rule: TaskRecurrenceRule, dueDate: Date, consumedTokens: Int)? {
        for prefix in ["every", "каждый", "каждую", "каждое", "каждые"] where command.hasPrefix(prefix) {
            let rest = trimCommandSeparators(String(command.dropFirst(prefix.count)))
            guard !rest.isEmpty else { continue }

            if let rule = recurrenceUnitRule(for: rest) {
                return (rule, calendar.startOfDay(for: now), 0)
            }

            if let weekday = weekdayNumber(for: rest) {
                return (.weekly, upcomingWeekday(weekday, now: now, calendar: calendar) ?? calendar.startOfDay(for: now), 0)
            }
        }

        return nil
    }

    private static func recurrenceUnitRule(for value: String) -> TaskRecurrenceRule? {
        if ["day", "days", "d", "д", "день", "дня", "дней", "daily", "ежедневно"].contains(value) {
            return .daily
        }

        if ["week", "weeks", "w", "неделя", "неделю", "недели", "недель", "weekly", "еженедельно"].contains(value) {
            return .weekly
        }

        if ["month", "months", "m", "месяц", "месяца", "месяцев", "monthly", "ежемесячно"].contains(value) {
            return .monthly
        }

        return nil
    }

    private static func relativeDayOffset(from command: String) -> Int? {
        if command.hasPrefix("+"),
           let offset = Int(command.dropFirst()) {
            return offset
        }

        for unit in ["days", "day", "дней", "дня", "день", "d", "д"] where command.hasSuffix(unit) {
            let numberPart = String(command.dropLast(unit.count))
            if let offset = Int(numberPart) {
                return offset
            }
        }

        for prefix in ["через", "in", "after"] where command.hasPrefix(prefix) {
            let rest = trimCommandSeparators(String(command.dropFirst(prefix.count)))
            if let offset = leadingInt(in: rest) {
                return offset
            }
        }

        return nil
    }

    private static func isDayUnit(_ value: String) -> Bool {
        ["day", "days", "d", "д", "день", "дня", "дней"].contains(value)
    }

    private static func leadingInt(in value: String) -> Int? {
        let digits = value.prefix { $0.isNumber }
        guard !digits.isEmpty else { return nil }
        return Int(digits)
    }

    private static func trimCommandSeparators(_ value: String) -> String {
        value.trimmingCharacters(in: CharacterSet(charactersIn: "-_ +"))
    }

    private static func weekdayNumber(for value: String) -> Int? {
        let weekdays: [String: Int] = [
            "sun": 1, "sunday": 1, "вс": 1, "воск": 1, "воскресенье": 1,
            "mon": 2, "monday": 2, "пн": 2, "пон": 2, "понедельник": 2,
            "tue": 3, "tues": 3, "tuesday": 3, "вт": 3, "вторник": 3,
            "wed": 4, "wednesday": 4, "ср": 4, "среда": 4, "среду": 4,
            "thu": 5, "thur": 5, "thurs": 5, "thursday": 5, "чт": 5, "четверг": 5,
            "fri": 6, "friday": 6, "пт": 6, "пятница": 6, "пятницу": 6,
            "sat": 7, "saturday": 7, "сб": 7, "суббота": 7, "субботу": 7
        ]

        return weekdays[value]
    }

    private static func upcomingWeekday(
        _ targetWeekday: Int,
        now: Date,
        calendar: Calendar
    ) -> Date? {
        let today = calendar.startOfDay(for: now)
        let currentWeekday = calendar.component(.weekday, from: today)
        let daysUntilTarget = (targetWeekday - currentWeekday + 7) % 7
        return calendar.date(byAdding: .day, value: daysUntilTarget, to: today)
    }

    private static func startOfNextWeek(now: Date, calendar: Calendar) -> Date? {
        let today = calendar.startOfDay(for: now)
        let currentWeekday = calendar.component(.weekday, from: today)
        let daysUntilMonday = (2 - currentWeekday + 7) % 7
        return calendar.date(byAdding: .day, value: daysUntilMonday == 0 ? 7 : daysUntilMonday, to: today)
    }

    private static func normalizedYear(_ year: Int) -> Int {
        year < 100 ? 2000 + year : year
    }

    static func projectCommandToken(for projectName: String) -> String {
        let name = normalizeProjectName(projectName)
        guard name.contains(where: { $0.isWhitespace }) else {
            return "/\(name)"
        }

        return "/\"\(name.replacingOccurrences(of: "\"", with: ""))\""
    }

    private static func commandTokens(in rawText: String) -> [String] {
        let characters = Array(rawText.trimmingCharacters(in: .whitespacesAndNewlines))
        var tokens: [String] = []
        var index = 0

        while index < characters.count {
            while index < characters.count, characters[index].isWhitespace {
                index += 1
            }

            guard index < characters.count else { break }

            if characters[index] == "/",
               index + 1 < characters.count,
               characters[index + 1] == "\"" {
                index += 2
                var quotedProject = "/"

                while index < characters.count, characters[index] != "\"" {
                    quotedProject.append(characters[index])
                    index += 1
                }

                if index < characters.count {
                    index += 1
                }

                tokens.append(quotedProject)
            } else {
                var token = ""

                while index < characters.count, !characters[index].isWhitespace {
                    token.append(characters[index])
                    index += 1
                }

                if !token.isEmpty {
                    tokens.append(token)
                }
            }
        }

        return tokens
    }
}

enum TaskDueDateFormatter {
    static func label(for date: Date, language: AppLanguage, now: Date = .now, calendar: Calendar = .current) -> String {
        let dueDay = calendar.startOfDay(for: date)
        let today = calendar.startOfDay(for: now)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)

        if dueDay == today {
            return language == .russian ? "сегодня" : "today"
        }

        if dueDay < today {
            return language == .russian ? "просрочено" : "overdue"
        }

        if dueDay == tomorrow {
            return language == .russian ? "завтра" : "tomorrow"
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: language == .russian ? "ru_RU" : "en_US")
        formatter.dateFormat = calendar.component(.year, from: dueDay) == calendar.component(.year, from: today)
            ? "d MMM"
            : "d MMM yyyy"
        return formatter.string(from: dueDay)
    }

    static func isOverdue(_ date: Date, now: Date = .now, calendar: Calendar = .current) -> Bool {
        calendar.startOfDay(for: date) < calendar.startOfDay(for: now)
    }

    static func commandToken(
        for date: Date,
        language: AppLanguage = .russian,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> String {
        let dueDay = calendar.startOfDay(for: date)
        let today = calendar.startOfDay(for: now)

        if dueDay == today {
            return language == .english ? "!today" : "!сегодня"
        }

        if dueDay == calendar.date(byAdding: .day, value: 1, to: today) {
            return language == .english ? "!tomorrow" : "!завтра"
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = calendar.component(.year, from: dueDay) == calendar.component(.year, from: today)
            ? "'!'dd.MM"
            : "'!'dd.MM.yyyy"
        return formatter.string(from: dueDay)
    }
}

enum TaskRecurrenceFormatter {
    static func label(for rule: TaskRecurrenceRule, language: AppLanguage) -> String {
        switch (rule, language) {
        case (.daily, .russian):
            return "ежедневно"
        case (.daily, .english):
            return "daily"
        case (.weekly, .russian):
            return "еженедельно"
        case (.weekly, .english):
            return "weekly"
        case (.monthly, .russian):
            return "ежемесячно"
        case (.monthly, .english):
            return "monthly"
        }
    }

    static func commandToken(for rule: TaskRecurrenceRule, language: AppLanguage) -> String {
        switch (rule, language) {
        case (.daily, .russian):
            return "!ежедневно"
        case (.daily, .english):
            return "!daily"
        case (.weekly, .russian):
            return "!еженедельно"
        case (.weekly, .english):
            return "!weekly"
        case (.monthly, .russian):
            return "!ежемесячно"
        case (.monthly, .english):
            return "!monthly"
        }
    }
}
