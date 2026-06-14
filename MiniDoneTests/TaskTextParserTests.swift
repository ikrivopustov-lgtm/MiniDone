import XCTest
@testable import MiniDone

final class TaskTextParserTests: XCTestCase {
    func testParsesLatinTags() {
        let parsed = TaskTextParser.parse("Update semantic core #seo")

        XCTAssertEqual(parsed.title, "Update semantic core")
        XCTAssertEqual(parsed.tagNames, ["seo"])
        XCTAssertNil(parsed.projectName)
    }

    func testParsesCyrillicTags() {
        let parsed = TaskTextParser.parse("Написать раздел #Диплом /Учеба")

        XCTAssertEqual(parsed.title, "Написать раздел")
        XCTAssertEqual(parsed.tagNames, ["диплом"])
        XCTAssertEqual(parsed.projectName, "Учеба")
    }

    func testRemovesDuplicateTagsCaseInsensitively() {
        let parsed = TaskTextParser.parse("Audit page #SEO #seo #Seo")

        XCTAssertEqual(parsed.title, "Audit page")
        XCTAssertEqual(parsed.tagNames, ["seo"])
    }

    func testNormalizesMixedCaseTags() {
        let parsed = TaskTextParser.parse("Ship flow #MiXeD")

        XCTAssertEqual(parsed.tagNames, ["mixed"])
    }

    func testEmptyInputProducesEmptyParsedText() {
        let parsed = TaskTextParser.parse("   \n\t   ")

        XCTAssertEqual(parsed.title, "")
        XCTAssertEqual(parsed.tagNames, [])
        XCTAssertNil(parsed.projectName)
    }

    func testCleansTitleAfterRemovingTagsAndProjectCommand() {
        let parsed = TaskTextParser.parse("  Write   a   QA   plan   #test,   /Work.  ")

        XCTAssertEqual(parsed.title, "Write a QA plan")
        XCTAssertEqual(parsed.tagNames, ["test"])
        XCTAssertEqual(parsed.projectName, "Work")
    }

    func testParsesQuotedProjectNameWithSpaces() {
        let parsed = TaskTextParser.parse("Собрать материалы #учеба /\"Мой проект\"")

        XCTAssertEqual(parsed.title, "Собрать материалы")
        XCTAssertEqual(parsed.tagNames, ["учеба"])
        XCTAssertEqual(parsed.projectName, "Мой проект")
    }

    func testProjectCommandTokenQuotesNamesWithSpaces() {
        XCTAssertEqual(TaskTextParser.projectCommandToken(for: "Work"), "/Work")
        XCTAssertEqual(TaskTextParser.projectCommandToken(for: "Мой проект"), "/\"Мой проект\"")
    }

    func testParsesTomorrowDeadline() throws {
        let calendar = Calendar.current
        let now = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 6, day: 10, hour: 12)))

        let parsed = TaskTextParser.parse("Обновить семантику #seo /Work !завтра", now: now)

        XCTAssertEqual(parsed.title, "Обновить семантику")
        XCTAssertEqual(parsed.tagNames, ["seo"])
        XCTAssertEqual(parsed.projectName, "Work")
        XCTAssertEqual(parsed.dueDate, calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)))
    }

    func testParsesWeekdayDeadline() throws {
        let calendar = Calendar.current
        let now = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 6, day: 12, hour: 12)))

        let parsed = TaskTextParser.parse("Позвонить !пн", now: now)

        XCTAssertEqual(parsed.title, "Позвонить")
        XCTAssertEqual(parsed.dueDate, calendar.date(from: DateComponents(year: 2026, month: 6, day: 15)))
    }

    func testParsesRelativeDeadline() throws {
        let calendar = Calendar.current
        let now = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 6, day: 12, hour: 12)))

        let parsed = TaskTextParser.parse("Проверить отчёт !через 3 дня", now: now)

        XCTAssertEqual(parsed.title, "Проверить отчёт")
        XCTAssertEqual(parsed.dueDate, calendar.date(from: DateComponents(year: 2026, month: 6, day: 15)))
    }

    func testParsesCompactRelativeDeadline() throws {
        let calendar = Calendar.current
        let now = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 6, day: 12, hour: 12)))

        let parsed = TaskTextParser.parse("Проверить отчёт !+3", now: now)

        XCTAssertEqual(parsed.title, "Проверить отчёт")
        XCTAssertEqual(parsed.dueDate, calendar.date(from: DateComponents(year: 2026, month: 6, day: 15)))
    }

    func testParsesShortDateDeadline() throws {
        let calendar = Calendar.current
        let now = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 6, day: 10, hour: 12)))

        let parsed = TaskTextParser.parse("Submit draft !12.06", now: now)

        XCTAssertEqual(parsed.title, "Submit draft")
        XCTAssertEqual(parsed.dueDate, calendar.date(from: DateComponents(year: 2026, month: 6, day: 12)))
    }

    func testParsesISODateDeadline() throws {
        let calendar = Calendar.current
        let now = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 6, day: 10, hour: 12)))

        let parsed = TaskTextParser.parse("Submit draft !2026-06-12", now: now)

        XCTAssertEqual(parsed.title, "Submit draft")
        XCTAssertEqual(parsed.dueDate, calendar.date(from: DateComponents(year: 2026, month: 6, day: 12)))
    }

    func testParsesRecurringTaskCommand() throws {
        let calendar = Calendar.current
        let now = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 6, day: 10, hour: 12)))

        let parsed = TaskTextParser.parse("Оплатить аренду !01.07 !monthly", now: now)

        XCTAssertEqual(parsed.title, "Оплатить аренду")
        XCTAssertEqual(parsed.dueDate, calendar.date(from: DateComponents(year: 2026, month: 7, day: 1)))
        XCTAssertEqual(parsed.recurrenceRule, .monthly)
    }

    func testParsesEveryWeekdayRecurringTaskCommand() throws {
        let calendar = Calendar.current
        let now = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 6, day: 12, hour: 12)))

        let parsed = TaskTextParser.parse("Call mom !every monday", now: now)

        XCTAssertEqual(parsed.title, "Call mom")
        XCTAssertEqual(parsed.dueDate, calendar.date(from: DateComponents(year: 2026, month: 6, day: 15)))
        XCTAssertEqual(parsed.recurrenceRule, .weekly)
    }

    func testUnknownDeadlineTokenStaysInTitle() {
        let parsed = TaskTextParser.parse("Read paper !soon")

        XCTAssertEqual(parsed.title, "Read paper !soon")
        XCTAssertNil(parsed.dueDate)
    }

    func testInvalidDateDeadlineStaysInTitle() {
        let parsed = TaskTextParser.parse("Prepare slides !31.02")

        XCTAssertEqual(parsed.title, "Prepare slides !31.02")
        XCTAssertNil(parsed.dueDate)
    }

    func testCommandTokenUsesSelectedLanguage() throws {
        let calendar = Calendar.current
        let now = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 6, day: 10, hour: 12)))
        let tomorrow = try XCTUnwrap(calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)))

        XCTAssertEqual(TaskDueDateFormatter.commandToken(for: tomorrow, language: .russian, now: now), "!завтра")
        XCTAssertEqual(TaskDueDateFormatter.commandToken(for: tomorrow, language: .english, now: now), "!tomorrow")
    }

    func testOverdueDateLabel() throws {
        let calendar = Calendar.current
        let now = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 6, day: 12, hour: 12)))
        let yesterday = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 6, day: 11)))

        XCTAssertTrue(TaskDueDateFormatter.isOverdue(yesterday, now: now))
        XCTAssertEqual(TaskDueDateFormatter.label(for: yesterday, language: .russian, now: now), "просрочено")
        XCTAssertEqual(TaskDueDateFormatter.label(for: yesterday, language: .english, now: now), "overdue")
    }
}
