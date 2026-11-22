import SwiftUI

struct TabSwitcherView: View {
    @EnvironmentObject private var store: BrowserStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(store.tabs) { tab in
                    TabRow(
                        tab: tab,
                        isSelected: tab.id == store.selectedID,
                        select: {
                            store.select(tab)
                            dismiss()
                        },
                        close: {
                            store.close(tab)
                        }
                    )
                }
            }
            .navigationTitle("Tabs (\(store.tabs.count)/\(Config.maxTabs))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                }
                ToolbarItem(placement: .bottomBar) {
                    Button {
                        store.newTab()
                        dismiss()
                    } label: {
                        Label("Neuer Tab", systemImage: "plus")
                    }
                    .disabled(store.tabs.count >= Config.maxTabs)
                }
            }
        }
    }
}

struct TabRow: View {
    @ObservedObject var tab: TabModel
    let isSelected: Bool
    let select: () -> Void
    let close: () -> Void

    private var titleText: String {
        if tab.showsStartPage { return "Neuer Tab" }
        if !tab.title.isEmpty { return tab.title }
        return tab.urlText
    }

    private var subtitleText: String {
        if tab.showsStartPage { return "Startseite" }
        return URL(string: tab.urlText)?.host ?? ""
    }

    var body: some View {
        HStack {
            Button(action: select) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(titleText)
                        .font(.headline)
                        .lineLimit(1)
                    Text(subtitleText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundStyle(.tint)
            }
            Button(action: close) {
                Image(systemName: "xmark")
            }
        }
        .buttonStyle(.borderless)
    }
}
