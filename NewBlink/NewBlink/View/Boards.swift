//
//  Boards.swift
//  NewBlink
//
//  Created by rania on 22/02/1446 AH.
//
import SwiftUI
import CloudKit

struct Boards: View {
    @StateObject private var BoardVM = BoardViewModel()
    @StateObject private var multimediaVM = MultimediaViewModel()
    @State private var thumbnails: [CKRecord.ID: UIImage] = [:]

    private let flexibleColumn = [
        GridItem(.flexible(minimum: 100, maximum: 200)),
        GridItem(.flexible(minimum: 100, maximum: 200))
    ]

    var body: some View {
        NavigationView { // إضافة NavigationView لتفعيل التنقل بين الشاشات
            VStack {
                // زر إضافة بورد جديدة
                Button(action: {
                    BoardVM.createBoard()
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.headline)
                }
                .padding()

                // عرض قائمة البوردات
                ScrollView {
                    LazyVGrid(columns: flexibleColumn, spacing: 20) {
                       
                        ForEach(BoardVM.boards) { board in
                        NavigationLink(destination:
                                        BoardDetailView(viewModel: BoardVM, board: board, multimediaVM: multimediaVM)) {
                        
                       // استخدام NavigationLink هنا
                                ZStack {
                                    // عرض الصورة المصغرة إذا كانت متوفرة، وإلا عرض صورة افتراضية
                                    if let thumbnail = thumbnails[board.id] {
                                        Image(uiImage: thumbnail)
                                            .resizable()
                                            .frame(width: 155, height: 155)
                                            .cornerRadius(10)
                                    } else {
                                        Image("defaultImg") // تأكد من إضافة صورة افتراضية في الأصول
                                            .resizable()
                                            .frame(width: 155, height: 155)
                                            .cornerRadius(10)
                                    }

                                    // عرض اسم البورد
                                    Text(board.BoardName)
                                        .foregroundColor(.black)
                                        .frame(width: 157, height: 55)
                                        .background(Color(red: 240/255, green: 242/255, blue: 255/255))
                                        .cornerRadius(10)
                                        .padding(.top, 100)
                                }
                                .onAppear {
                                    // جلب الصورة المصغرة لكل بورد عند ظهوره
                                    BoardVM.fetchBoardThumbnail(for: board) { image in
                                        if let image = image {
                                            DispatchQueue.main.async {
                                                thumbnails[board.id] = image
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .onAppear {
                BoardVM.fetchBoards() // جلب جميع البوردات عند ظهور الواجهة
            }
        }
    }
}

struct Boards_Previews: PreviewProvider {
    static var previews: some View {
        Boards()
    }
}
