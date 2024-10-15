import SwiftUI
import CloudKit

struct MultimediaKeyboardView: View {
    @StateObject private var viewModel = MultimediaViewModel()
    @Binding var text: String
    var currentBoard: Board? // إضافة currentBoard

    var body: some View {
        VStack {
            if viewModel.mediaArr.isEmpty {
                ProgressView("Loading...")
            } else {
                let multimediaItems = viewModel.mediaArr
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(multimediaItems) { item in
                            // عرض الصور
                            ForEach(item.images, id: \.self) { image in
                                Image(uiImage: image)
                                    .resizable()
                                    .frame(width: 100, height: 100)
                                    .onTapGesture {
                                        copyImageToClipboard(image: image)
                                        text += "[Image]" // تحديث النص
                                    }
                            }
                            // عرض الروابط
                            ForEach(item.LinkInsert, id: \.self) { link in
                                Text(link)
                                    .padding()
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(8)
                                    .onTapGesture {
                                        copyToClipboard(text: link)
                                        text += "[Link]" // تحديث النص
                                    }
                            }
                            // عرض النصوص
                            ForEach(item.TextInsert, id: \.self) { textItem in
                                Text(textItem)
                                    .padding()
                                    .background(Color.blue.opacity(0.2))
                                    .cornerRadius(8)
                                    .onTapGesture {
                                        copyToClipboard(text: textItem)
                                        text += textItem // تحديث النص
                                    }
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            if let board = currentBoard {
                viewModel.fetchMedia(for: board) // تأكد من تمرير currentBoard
            } else {
                print("No current board available")
            }
        }
    }

    func copyToClipboard(text: String) {
        UIPasteboard.general.string = text
        print("Text copied to clipboard!")
    }

    func copyImageToClipboard(image: UIImage) {
        if let imageData = image.pngData() {
            UIPasteboard.general.setData(imageData, forPasteboardType: "public.png")
            print("Image copied to clipboard!")
        }
    }
}
