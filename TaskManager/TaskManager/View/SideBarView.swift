//
//  SideBarView.swift
//  TaskManager
//
//  Created by Israel Manzo on 4/21/25.
//

import SwiftUI

struct SideBarView: View {
    let userCreatorGroup: [TaskGroup]
    @State private var selectedSection: TaskSection = .all
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
                ForEach(userCreatorGroup) { group in
                    Label(group.title, systemImage: "folder")
                }
            } header: {
                Text("My goups")
            }
        }
    }
}

#Preview {
    SideBarView(userCreatorGroup: TaskGroup.exampples())
        .listStyle(.sidebar)
}
