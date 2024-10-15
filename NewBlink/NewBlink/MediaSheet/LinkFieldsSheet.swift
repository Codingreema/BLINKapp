//
//  LinkFieldsSheet.swift
//  NewBlink
//
//  Created by rania on 01/03/1446 AH.
//

import SwiftUI
import CloudKit

struct LinkFieldsSheet: View {
    @Binding var newLink: String
    @Environment(\.dismiss) var dismiss // لإغلاق الـ Sheet
    @ObservedObject var multimediaVM: MultimediaViewModel
    var board: Board
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Enter a Link")
                .font(.headline)

            TextField("Enter link", text: $newLink)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Button("Save Link") {
                multimediaVM.saveLink(newLink, for: board)
                newLink = ""
                dismiss() // إغلاق الـ Sheet بعد الحفظ
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

  
}
