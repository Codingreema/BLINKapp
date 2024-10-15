//
//  TextFieldsSheet.swift
//  NewBlink
//
//  Created by rania on 04/03/1446 AH.
//

import SwiftUI

struct TextFieldsSheet: View {
    @Binding var newText: String
    @Environment(\.dismiss) var dismiss
    @ObservedObject var multimediaVM: MultimediaViewModel
    var board: Board
    var originalText: String? = nil // Optional original text for editing
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Enter a Text")
                .font(.headline)

            TextField("Enter Text", text: $newText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Button("Save Text") {
                multimediaVM.saveText(newText, for: board)
                dismiss() // Close the sheet after saving
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}


