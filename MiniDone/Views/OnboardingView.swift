import SwiftUI

struct OnboardingView: View {
    let language: AppLanguage
    let onComplete: () -> Void

    @State private var selectedIndex = 0

    private var steps: [OnboardingStep] {
        OnboardingStep.steps(for: language)
    }

    private var selectedStep: OnboardingStep {
        steps[selectedIndex]
    }

    private var isFirstStep: Bool {
        selectedIndex == 0
    }

    private var isLastStep: Bool {
        selectedIndex == steps.count - 1
    }

    private var primaryButtonTitle: String {
        isLastStep
            ? LocalizationService.text(.onboardingFinish, language: language)
            : LocalizationService.text(.onboardingNext, language: language)
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()
                .overlay(AppStyle.divider)

            HStack(alignment: .top, spacing: 18) {
                stepContent
                    .frame(maxWidth: .infinity, alignment: .leading)

                OnboardingPreview(step: selectedStep)
                    .frame(width: 218)
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 18)

            Divider()
                .overlay(AppStyle.divider)

            footer
        }
        .frame(width: 680, height: 420)
        .background(AppStyle.windowBackground)
        .accessibilityIdentifier("onboardingSheet")
    }

    private var header: some View {
        HStack(spacing: 12) {
            BrandMarkView(size: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text(LocalizationService.text(.onboardingTitle, language: language))
                    .font(AppStyle.font(17, .semibold))
                    .foregroundStyle(AppStyle.primaryText)
                    .accessibilityIdentifier("onboardingTitle")

                Text(LocalizationService.text(.onboardingSubtitle, language: language))
                    .font(AppStyle.font(11, .medium))
                    .foregroundStyle(AppStyle.secondaryText)
                    .lineLimit(2)
            }

            Spacer()

            Button(LocalizationService.text(.onboardingSkip, language: language)) {
                onComplete()
            }
            .buttonStyle(.plain)
            .font(AppStyle.font(12, .semibold))
            .foregroundStyle(AppStyle.secondaryText)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
            .accessibilityLabel(LocalizationService.text(.onboardingSkip, language: language))
            .accessibilityIdentifier("onboardingSkipButton")
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 14)
    }

    private var stepContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: selectedStep.systemImage)
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(selectedStep.accent)
                .frame(width: 36, height: 36)
                .background(selectedStep.accent.opacity(0.14), in: RoundedRectangle(cornerRadius: 9))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                Text(selectedStep.title)
                    .font(AppStyle.font(22, .semibold))
                    .foregroundStyle(AppStyle.primaryText)
                    .lineLimit(2)
                    .accessibilityIdentifier("onboardingStepTitle")

                Text(selectedStep.body)
                    .font(AppStyle.font(13, .medium))
                    .foregroundStyle(AppStyle.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(1)
            }

            if !selectedStep.examples.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text(LocalizationService.text(.onboardingExampleHint, language: language))
                        .font(AppStyle.font(10, .semibold))
                        .foregroundStyle(AppStyle.mutedText)

                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 102, maximum: 184), spacing: 6, alignment: .leading)],
                        alignment: .leading,
                        spacing: 6
                    ) {
                        ForEach(selectedStep.examples, id: \.self) { example in
                            Text(example)
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundStyle(AppStyle.primaryText)
                                .lineLimit(2)
                                .minimumScaleFactor(0.9)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(AppStyle.fieldBackground, in: RoundedRectangle(cornerRadius: 8))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(AppStyle.fieldBorder, lineWidth: 0.7)
                                }
                        }
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .frame(maxHeight: .infinity, alignment: .topLeading)
    }

    private var footer: some View {
        HStack(spacing: 14) {
            HStack(spacing: 6) {
                ForEach(steps.indices, id: \.self) { index in
                    Capsule()
                        .fill(index == selectedIndex ? selectedStep.accent : AppStyle.fieldBorder)
                        .frame(width: index == selectedIndex ? 18 : 6, height: 6)
                }
            }
            .accessibilityIdentifier("onboardingPageIndicator")
            .accessibilityLabel("\(LocalizationService.text(.onboardingProgress, language: language)) \(selectedIndex + 1)")

            Spacer()

            Button {
                selectedIndex = max(0, selectedIndex - 1)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .accessibilityHidden(true)
                    Text(LocalizationService.text(.onboardingBack, language: language))
                }
            }
            .buttonStyle(.plain)
            .font(AppStyle.font(13, .semibold))
            .foregroundStyle(isFirstStep ? AppStyle.mutedText.opacity(0.5) : AppStyle.secondaryText)
            .disabled(isFirstStep)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(LocalizationService.text(.onboardingBack, language: language))
            .accessibilityIdentifier("onboardingBackButton")

            Button {
                if isLastStep {
                    onComplete()
                } else {
                    selectedIndex = min(steps.count - 1, selectedIndex + 1)
                }
            } label: {
                HStack(spacing: 6) {
                    Text(primaryButtonTitle)
                        .accessibilityIdentifier("onboardingPrimaryButtonText")
                    Image(systemName: isLastStep ? "checkmark" : "chevron.right")
                        .accessibilityHidden(true)
                }
                .font(AppStyle.font(13, .semibold))
                .foregroundStyle(Color.white)
                .padding(.horizontal, 15)
                .padding(.vertical, 8)
                .background(AppStyle.green, in: RoundedRectangle(cornerRadius: 8))
                .contentShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(primaryButtonTitle)
            .accessibilityIdentifier(isLastStep ? "onboardingFinishButton" : "onboardingNextButton")
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 12)
    }
}

private struct OnboardingPreview: View {
    let step: OnboardingStep

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Circle()
                    .fill(step.accent)
                    .frame(width: 8, height: 8)

                Text(step.previewTitle)
                    .font(AppStyle.font(11, .semibold))
                    .foregroundStyle(AppStyle.secondaryText)
                    .lineLimit(1)
            }

            VStack(spacing: 7) {
                ForEach(step.previewTasks) { task in
                    OnboardingPreviewTask(task: task)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxHeight: .infinity, alignment: .topLeading)
        .background(AppStyle.rowBackground, in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppStyle.fieldBorder, lineWidth: 0.7)
        }
    }
}

private struct OnboardingPreviewTask: View {
    let task: OnboardingPreviewTaskModel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .stroke(task.isCompleted ? Color.clear : AppStyle.fieldBorder, lineWidth: 1.8)
                        .frame(width: 16, height: 16)

                    if task.isCompleted {
                        Circle()
                            .fill(AppStyle.green)
                            .frame(width: 16, height: 16)

                        Image(systemName: "checkmark")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(Color.white)
                    }
                }

                Text(task.title)
                    .font(AppStyle.font(11, .semibold))
                    .foregroundStyle(task.isCompleted ? AppStyle.mutedText : AppStyle.primaryText)
                    .strikethrough(task.isCompleted, color: AppStyle.mutedText)
                    .lineLimit(1)
            }

            if !task.chips.isEmpty {
                HStack(spacing: 4) {
                    ForEach(task.chips, id: \.self) { chip in
                        Text(chip)
                            .font(AppStyle.font(8, .semibold))
                            .foregroundStyle(AppStyle.secondaryText)
                            .lineLimit(1)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(AppStyle.panelBackground, in: RoundedRectangle(cornerRadius: 5))
                            .overlay {
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(AppStyle.fieldBorder.opacity(0.7), lineWidth: 0.5)
                            }
                    }
                }
                .padding(.leading, 24)
            }
        }
        .padding(8)
        .background(AppStyle.fieldBackground, in: RoundedRectangle(cornerRadius: 9))
        .overlay {
            RoundedRectangle(cornerRadius: 9)
                .stroke(AppStyle.fieldBorder.opacity(0.8), lineWidth: 0.6)
        }
    }
}

private struct OnboardingStep {
    let title: String
    let body: String
    let systemImage: String
    let accent: Color
    let examples: [String]
    let previewTitle: String
    let previewTasks: [OnboardingPreviewTaskModel]

    static func steps(for language: AppLanguage) -> [OnboardingStep] {
        [
            OnboardingStep(
                title: LocalizationService.text(.onboardingTitleWelcome, language: language),
                body: LocalizationService.text(.onboardingBodyWelcome, language: language),
                systemImage: "checkmark.circle",
                accent: AppStyle.green,
                examples: [],
                previewTitle: LocalizationService.text(.allTasks, language: language),
                previewTasks: [
                    OnboardingPreviewTaskModel(title: "Plan launch", chips: ["#work", "tomorrow"]),
                    OnboardingPreviewTaskModel(title: "Review notes", chips: ["today"]),
                    OnboardingPreviewTaskModel(title: "Ship build", chips: ["completed"], isCompleted: true)
                ]
            ),
            OnboardingStep(
                title: LocalizationService.text(.onboardingTitleCapture, language: language),
                body: LocalizationService.text(.onboardingBodyCapture, language: language),
                systemImage: "text.cursor",
                accent: AppStyle.blue,
                examples: language == .russian
                    ? ["Запустить релиз #work !завтра", "Оплатить аренду !ежемесячно"]
                    : ["Plan launch #work !tomorrow", "Pay rent #home !monthly"],
                previewTitle: LocalizationService.text(.newTaskPlaceholder, language: language),
                previewTasks: [
                    OnboardingPreviewTaskModel(title: language == .russian ? "Запустить релиз" : "Plan launch", chips: ["#work", language == .russian ? "завтра" : "tomorrow"]),
                    OnboardingPreviewTaskModel(title: language == .russian ? "Оплатить аренду" : "Pay rent", chips: [language == .russian ? "ежемесячно" : "monthly"])
                ]
            ),
            OnboardingStep(
                title: LocalizationService.text(.onboardingTitleOrganize, language: language),
                body: LocalizationService.text(.onboardingBodyOrganize, language: language),
                systemImage: "folder.badge.gearshape",
                accent: AppStyle.mint,
                examples: language == .russian
                    ? ["#учеба", "/\"Мой проект\"", "Today"]
                    : ["#docs", "/\"Client Work\"", "Today"],
                previewTitle: LocalizationService.text(.projects, language: language),
                previewTasks: [
                    OnboardingPreviewTaskModel(title: language == .russian ? "Черновик" : "Draft", chips: ["#docs", "Pinned"]),
                    OnboardingPreviewTaskModel(title: language == .russian ? "Созвон" : "Call", chips: [language == .russian ? "сегодня" : "today"])
                ]
            ),
            OnboardingStep(
                title: LocalizationService.text(.onboardingTitleComplete, language: language),
                body: LocalizationService.text(.onboardingBodyComplete, language: language),
                systemImage: "arrow.uturn.backward.circle",
                accent: AppStyle.purple,
                examples: [
                    LocalizationService.text(.restore, language: language),
                    LocalizationService.text(.delete, language: language),
                    LocalizationService.text(.clearCompleted, language: language)
                ],
                previewTitle: LocalizationService.text(.completed, language: language),
                previewTasks: [
                    OnboardingPreviewTaskModel(title: language == .russian ? "Проверить сборку" : "Check build", chips: [LocalizationService.text(.restore, language: language)], isCompleted: true),
                    OnboardingPreviewTaskModel(title: language == .russian ? "Закрыть заметки" : "Close notes", chips: [LocalizationService.text(.delete, language: language)], isCompleted: true)
                ]
            ),
            OnboardingStep(
                title: LocalizationService.text(.onboardingTitleMenuBar, language: language),
                body: LocalizationService.text(.onboardingBodyMenuBar, language: language),
                systemImage: "menubar.rectangle",
                accent: AppStyle.pink,
                examples: [
                    LocalizationService.text(.openMainWindow, language: language),
                    "\(LocalizationService.text(.language, language: language)): RU / EN",
                    LocalizationService.text(.themeSystem, language: language)
                ],
                previewTitle: LocalizationService.text(.miniTitle, language: language),
                previewTasks: [
                    OnboardingPreviewTaskModel(title: language == .russian ? "Быстрая задача" : "Quick task", chips: ["menu bar"]),
                    OnboardingPreviewTaskModel(title: LocalizationService.text(.settings, language: language), chips: ["RU / EN", LocalizationService.text(.themeDark, language: language)])
                ]
            )
        ]
    }
}

private struct OnboardingPreviewTaskModel: Identifiable {
    let id = UUID()
    let title: String
    let chips: [String]
    var isCompleted = false
}
