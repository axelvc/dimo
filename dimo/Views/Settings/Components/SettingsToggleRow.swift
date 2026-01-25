//
//  SettingsToggleRow.swift
//  dimo
//
//  Created by OpenCode Refactoring on 24/01/26.
//

import SwiftUI

struct SettingsToggleRow: View {
    let title: String
    let isOn: Binding<Bool>

    var body: some View {
        HStack {
            Text(title)
                .font(.headline)

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }
}
