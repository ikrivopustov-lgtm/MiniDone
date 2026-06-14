import Foundation

enum L10nKey {
    case addProject
    case allTasks
    case appearance
    case clearCompleted
    case clearedCompleted
    case completed
    case completedTask
    case delete
    case deleteProject
    case deletedTask
    case deadline
    case emptyCompleted
    case emptyMiniTasks
    case emptyProjects
    case emptyTasks
    case english
    case filterAllTags
    case inbox
    case language
    case miniTitle
    case newProjectPlaceholder
    case newTaskPlaceholder
    case noRepeat
    case openMainWindow
    case moveToProject
    case noDeadline
    case onboardingBack
    case onboardingBodyCapture
    case onboardingBodyComplete
    case onboardingBodyMenuBar
    case onboardingBodyOrganize
    case onboardingBodyWelcome
    case onboardingExampleHint
    case onboardingFinish
    case onboardingNext
    case onboardingProgress
    case onboardingShowAgain
    case onboardingSkip
    case onboardingSubtitle
    case onboardingTitle
    case onboardingTitleCapture
    case onboardingTitleComplete
    case onboardingTitleMenuBar
    case onboardingTitleOrganize
    case onboardingTitleWelcome
    case projects
    case quit
    case rename
    case repeatTask
    case repeatDaily
    case repeatWeekly
    case repeatMonthly
    case resizeWindow
    case restore
    case russian
    case save
    case settings
    case showSearch
    case pinned
    case pinTask
    case tasks
    case themeDark
    case themeLight
    case themeSystem
    case today
    case tomorrow
    case undo
    case unpinTask
}

enum LocalizationService {
    static func text(_ key: L10nKey, language: AppLanguage) -> String {
        switch language {
        case .russian:
            russian[key] ?? english[key] ?? ""
        case .english:
            english[key] ?? ""
        }
    }

    static func activeTaskCount(_ count: Int, language: AppLanguage) -> String {
        switch language {
        case .russian:
            "\(count) \(russianPlural(count, one: "активная", few: "активные", many: "активных"))"
        case .english:
            "\(count) active"
        }
    }

    static func completedTaskCount(_ count: Int, language: AppLanguage) -> String {
        switch language {
        case .russian:
            "\(count) \(russianPlural(count, one: "завершенная", few: "завершенные", many: "завершенных"))"
        case .english:
            "\(count) completed"
        }
    }

    private static func russianPlural(_ count: Int, one: String, few: String, many: String) -> String {
        let absCount = abs(count)
        let lastTwo = absCount % 100
        let last = absCount % 10

        if (11...14).contains(lastTwo) {
            return many
        }

        switch last {
        case 1:
            return one
        case 2...4:
            return few
        default:
            return many
        }
    }

    private static let russian: [L10nKey: String] = [
        .addProject: "Добавить проект",
        .allTasks: "Все задачи",
        .appearance: "Тема",
        .clearCompleted: "Очистить завершенные",
        .clearedCompleted: "Завершенные очищены",
        .completed: "Завершенные",
        .completedTask: "Задача завершена",
        .delete: "Удалить",
        .deleteProject: "Удалить проект",
        .deletedTask: "Задача удалена",
        .deadline: "Дедлайн",
        .emptyCompleted: "Завершенных задач нет",
        .emptyMiniTasks: "Здесь пока нет задач",
        .emptyProjects: "Проектов пока нет",
        .emptyTasks: "Задач пока нет",
        .english: "English",
        .filterAllTags: "Все",
        .inbox: "Общие",
        .language: "Язык",
        .miniTitle: "MiniDone",
        .newProjectPlaceholder: "Новый проект",
        .newTaskPlaceholder: "Новая задача...",
        .noRepeat: "Не повторять",
        .openMainWindow: "Открыть окно",
        .moveToProject: "Переместить в проект",
        .noDeadline: "Без дедлайна",
        .onboardingBack: "Назад",
        .onboardingBodyCapture: "Пиши задачу одной строкой: название, тег, проект, срок и повтор. MiniDone сам разложит детали по чипам.",
        .onboardingBodyComplete: "Завершенные задачи уходят из активного списка, но остаются в Completed. Их можно восстановить или удалить окончательно.",
        .onboardingBodyMenuBar: "Мини-окно в строке меню подходит для быстрых задач. В настройках можно сменить язык и тему.",
        .onboardingBodyOrganize: "Проекты, теги, Today, поиск и закрепление помогают держать список коротким и понятным.",
        .onboardingBodyWelcome: "MiniDone держит задачи рядом, но не мешает работе: главное окно для планирования, menu bar для быстрых действий.",
        .onboardingExampleHint: "Попробуй так",
        .onboardingFinish: "Начать пользоваться",
        .onboardingNext: "Дальше",
        .onboardingProgress: "Шаг",
        .onboardingShowAgain: "Показать обучение снова",
        .onboardingSkip: "Пропустить",
        .onboardingSubtitle: "Короткое знакомство с быстрым вводом, тегами, проектами, повторами и menu bar.",
        .onboardingTitle: "Познакомимся с MiniDone",
        .onboardingTitleCapture: "Быстрый ввод",
        .onboardingTitleComplete: "Завершение без страха",
        .onboardingTitleMenuBar: "Menu bar и настройки",
        .onboardingTitleOrganize: "Организация",
        .onboardingTitleWelcome: "Тихий список задач для Mac",
        .projects: "Проекты",
        .quit: "Выйти",
        .rename: "Переименовать",
        .repeatTask: "Повтор",
        .repeatDaily: "Ежедневно",
        .repeatWeekly: "Еженедельно",
        .repeatMonthly: "Ежемесячно",
        .resizeWindow: "Изменить высоту",
        .restore: "Восстановить",
        .russian: "Русский",
        .save: "Сохранить",
        .settings: "Настройки",
        .showSearch: "Поиск",
        .pinned: "Закреплено",
        .pinTask: "Закрепить",
        .tasks: "Задачи",
        .themeDark: "Темная",
        .themeLight: "Светлая",
        .themeSystem: "Системная",
        .today: "Сегодня",
        .tomorrow: "Завтра",
        .undo: "Отменить",
        .unpinTask: "Открепить"
    ]

    private static let english: [L10nKey: String] = [
        .addProject: "Add project",
        .allTasks: "All tasks",
        .appearance: "Theme",
        .clearCompleted: "Clear completed",
        .clearedCompleted: "Completed cleared",
        .completed: "Completed",
        .completedTask: "Task completed",
        .delete: "Delete",
        .deleteProject: "Delete project",
        .deletedTask: "Task deleted",
        .deadline: "Deadline",
        .emptyCompleted: "No completed tasks",
        .emptyMiniTasks: "No tasks here yet",
        .emptyProjects: "No projects yet",
        .emptyTasks: "No tasks yet",
        .english: "English",
        .filterAllTags: "All",
        .inbox: "Inbox",
        .language: "Language",
        .miniTitle: "MiniDone",
        .newProjectPlaceholder: "New project",
        .newTaskPlaceholder: "New task...",
        .noRepeat: "No repeat",
        .openMainWindow: "Open window",
        .moveToProject: "Move to project",
        .noDeadline: "No deadline",
        .onboardingBack: "Back",
        .onboardingBodyCapture: "Write one line with the title, tag, project, deadline, and recurrence. MiniDone turns the details into clean chips.",
        .onboardingBodyComplete: "Completed tasks leave the active list but stay in Completed. Restore them when needed or delete them for good.",
        .onboardingBodyMenuBar: "The menu bar surface is made for quick tasks. Settings let you switch language and theme any time.",
        .onboardingBodyOrganize: "Projects, tags, Today, search, and pinned tasks keep the list short and easy to scan.",
        .onboardingBodyWelcome: "MiniDone keeps tasks nearby without taking over: the main window is for planning, the menu bar is for quick actions.",
        .onboardingExampleHint: "Try this",
        .onboardingFinish: "Start using MiniDone",
        .onboardingNext: "Next",
        .onboardingProgress: "Step",
        .onboardingShowAgain: "Show intro again",
        .onboardingSkip: "Skip",
        .onboardingSubtitle: "A short guide to quick entry, tags, projects, recurring tasks, and the menu bar.",
        .onboardingTitle: "Meet MiniDone",
        .onboardingTitleCapture: "Fast capture",
        .onboardingTitleComplete: "Complete without worry",
        .onboardingTitleMenuBar: "Menu bar and settings",
        .onboardingTitleOrganize: "Stay organized",
        .onboardingTitleWelcome: "A quiet task list for Mac",
        .projects: "Projects",
        .quit: "Quit",
        .rename: "Rename",
        .repeatTask: "Repeat",
        .repeatDaily: "Daily",
        .repeatWeekly: "Weekly",
        .repeatMonthly: "Monthly",
        .resizeWindow: "Resize",
        .restore: "Restore",
        .russian: "Русский",
        .save: "Save",
        .settings: "Settings",
        .showSearch: "Search",
        .pinned: "Pinned",
        .pinTask: "Pin",
        .tasks: "Tasks",
        .themeDark: "Dark",
        .themeLight: "Light",
        .themeSystem: "System",
        .today: "Today",
        .tomorrow: "Tomorrow",
        .undo: "Undo",
        .unpinTask: "Unpin"
    ]
}
