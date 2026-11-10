import SwiftUI

struct SwipePinDemoView: View {
    @State private var pinnedMessages: [String] = []
    @State private var rowRevisions: [String: Int] = [:]

    private let messages = (1...20).map { "Message \($0)" }

    private var orderedMessages: [String] {
        pinnedMessages + messages.filter { !pinnedMessages.contains($0) }
    }

    private var rows: [DisplayMessage] {
        orderedMessages.map {
            DisplayMessage(
                title: $0,
                revision: rowRevisions[$0, default: 0]
            )
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(rows) { row in
                    if #available(iOS 27, *) {
                        IOS27PinRow(
                            title: row.title,
                            isPinned: pinnedMessages.contains(row.title),
                            onPinChange: {
                                togglePin(row.title, replaceRow: false)
                            }
                        )
                        
                    } else {
                        OlderIOSPinRow(
                            title: row.title,
                            isPinned: pinnedMessages.contains(row.title),
                            onPinChange: {
                                togglePin(row.title, replaceRow: true)
                            }
                        )
                      
                    }
                }
            }
            .navigationTitle("Messages")
        }
    }

    private func togglePin(_ title: String, replaceRow: Bool) {
        let oldIndex = orderedMessages.firstIndex(of: title)

        withAnimation(.easeInOut(duration: 0.25)) {
            if pinnedMessages.contains(title) {
                pinnedMessages.removeAll { $0 == title }
            } else {
                pinnedMessages.insert(title, at: 0)
            }

            if replaceRow &&
                oldIndex != orderedMessages.firstIndex(of: title) {
                rowRevisions[title, default: 0] += 1
            }
        }
    }
}

private struct DisplayMessage: Identifiable {
    let title: String
    let revision: Int

    var id: String { "\(title)-\(revision)" }
}

private struct MessageContent: View {
    let title: String
    let isPinned: Bool

    var body: some View {
        HStack {
            Text(title)
            Spacer()

            if isPinned {
                Image(systemName: "pin.fill")
                    .foregroundStyle(.orange)
            }
        }
    }
}

@available(iOS 27, *)
private struct IOS27PinRow: View {
    @State private var pendingPinChange = false

    let title: String
    let isPinned: Bool
    let onPinChange: () -> Void

    var body: some View {
        MessageContent(title: title, isPinned: isPinned)
            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                Button(
                    isPinned ? "Unpin" : "Pin",
                    systemImage: isPinned ? "pin.slash" : "pin.fill"
                ) {
                    pendingPinChange = true
                }
                .tint(.orange)
            } onPresentationChanged: { isPresented in
                guard !isPresented && pendingPinChange else { return }

                pendingPinChange = false
                onPinChange()
            }
    }
}

private struct OlderIOSPinRow: View {
    @State private var isWaiting = false

    let title: String
    let isPinned: Bool
    let onPinChange: () -> Void

    var body: some View {
        MessageContent(title: title, isPinned: isPinned)
            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                Button(
                    isPinned ? "Unpin" : "Pin",
                    systemImage: isPinned ? "pin.slash" : "pin.fill"
                ) {
                    guard !isWaiting else { return }
                    isWaiting = true

                    Task { @MainActor in
                        defer { isWaiting = false }

                        do {
                            try await Task.sleep(for: .milliseconds(400))
                        } catch {
                            return
                        }

                        onPinChange()
                    }
                }
                .tint(.orange)
            }
    }
}

#Preview {
    SwipePinDemoView()
}
