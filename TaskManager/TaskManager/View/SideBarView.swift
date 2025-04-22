//
//  SideBarView.swift
//  TaskManager
//
//  Created by Israel Manzo on 4/21/25.
//

import SwiftUI

struct SideBarView: View {
    @Binding var userCreatorGroup: [TaskGroup]
    @Binding var selectedSection: TaskSection
    var body: some View {
        List(selection: $selectedSection) {
            Section {
                ForEach(TaskSection.allCases) { selection in
                    Label(selection.displayName, systemImage: selection.iconName)
                        .tag(selection)
                }
            } header: {
                Text("Favorites")
            }
            
            Section {
                ForEach($userCreatorGroup) { $group in
                    HStack {
                        Image(systemName: "folder")
                        TextField("New Group", text: $group.title)
                    }
                    .tag(TaskSection.list(group))
                    .contextMenu {
                        Text("one")
                        Text("two")
                        Text("three")
                    }
                }
            } header: {
                Text("My goups")
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                let newGroup = TaskGroup(title: "New Group")
                userCreatorGroup.append(newGroup)
            } label: {
                Label("Add group", systemImage: "plus")
            }
            .buttonStyle(.borderless)
            .foregroundStyle(Color.accentColor)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .keyboardShortcut(KeyEquivalent("a"), modifiers: .command)
        }
    }
}

#Preview {
    SideBarView(
        userCreatorGroup: .constant(TaskGroup.exampples()),
        selectedSection: .constant(.all)
    ).listStyle(.sidebar)
}
