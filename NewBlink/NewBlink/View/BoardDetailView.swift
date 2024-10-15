//
//  BoardDetailView.swift
//  NewBlink
//
//  Created by rania on 24/02/1446 AH.
//

import SwiftUI
import CloudKit
import PhotosUI
import UniformTypeIdentifiers

struct BoardDetailView: View {
    let board: Board
    
    @State private var boardName: String
    @State private var title: String = ""
    @ObservedObject var viewModel: BoardViewModel
    @ObservedObject var multimediaVM: MultimediaViewModel
    
    @State private var showingBottomSheet = false
    @State private var isLinkSheetPresented = false
    @State private var isTextSheetPresented = false
    @State private var newLink: String = ""
    @State private var newText: String = ""
    
    @State private var selectedText: String = ""
    @State private var selectedLink: String = ""
    @State private var selectedPDFURL: URL? = nil
    @State private var isPDFViewActive = false
    
    // Add a confirmation state for delete
    @State private var showingDeleteConfirmation = false
    @State private var itemToDelete: MultimediaItem?
    
    let columns = [
        GridItem(.adaptive(minimum: 150, maximum: 200)) // Adaptive grid for better responsiveness
    ]
    
    init(viewModel: BoardViewModel, board: Board, multimediaVM: MultimediaViewModel) {
        self.viewModel = viewModel
        self.multimediaVM = multimediaVM
        self.board = board
        _boardName = State(initialValue: board.BoardName)
    }
    
    var body: some View {
        VStack {
            Button("+ Add contents") {
                showingBottomSheet.toggle()
            }
            .frame(width: 250, height: 50.0)
            .bold()
            .foregroundStyle(.white)
            .font(.headline)
            .background(Color.blue)
            .cornerRadius(55)
            .sheet(isPresented: $showingBottomSheet) {
                ContentSheet(
                    isLinkSheetPresented: $isLinkSheetPresented,
                    isTextSheetPresented: $isTextSheetPresented,
                    newLink: $newLink,
                    newText: $newText,
                    multimediaVM: multimediaVM,
                    board: board
                )
            }
            
            ScrollView {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(sortedMultimediaItems()) { item in
                        getMultimediaView(for: item)
                    }
                }
                .padding()
            }
            .onAppear {
                multimediaVM.fetchText(for: board)
                multimediaVM.fetchLinks(for: board)
                multimediaVM.fetchMedia(for: board)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            title = board.BoardName
        }
    }
    
    // Function to sort multimedia items by priority: image > text > file > link
    func sortedMultimediaItems() -> [MultimediaItem] {
        let allItems = multimediaVM.mediaArr.flatMap { getMultimediaItems(from: $0) }
        return allItems.sorted {
            ranking(for: $0.type) < ranking(for: $1.type)
        }
    }
    
    // Ranking system for item types: image > text > file > link
    func ranking(for type: MultimediaType) -> Int {
        switch type {
        case .image:
            return 1
        case .text:
            return 2
        case .file:
            return 3
        case .link:
            return 4
        }
    }
    
    // Function to get the right view for each multimedia item
    @ViewBuilder
    func getMultimediaView(for item: MultimediaItem) -> some View {
        VStack {
            switch item.type {
            case .text(let text):
                Text(text)
                    .padding()
                    .frame(minHeight: 120)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                    .onTapGesture {
                        selectedText = text
                        isTextSheetPresented.toggle()
                    }
                
            case .link(let link):
                Text(link)
                    .foregroundColor(.blue)
                    .underline()
                    .padding()
                    .frame(minHeight: 120)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                    .onTapGesture {
                        selectedLink = link
                        isLinkSheetPresented.toggle()
                    }
                
            case .image(let image):
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(minHeight: 150)
                    .cornerRadius(8)
                    .padding()
                
            case .file(let fileURL):
                if let thumbnail = generatePDFThumbnail(for: fileURL) {
                    VStack {
                        Image(uiImage: thumbnail)
                            .resizable()
                            .frame(width: 150, height: 150)
                        
                        Button("Open PDF") {
                            selectedPDFURL = fileURL
                            isPDFViewActive = true
                        }
                        .background(
                            NavigationLink(destination: PDFDetailView(url: fileURL), isActive: $isPDFViewActive) {
                                EmptyView()
                            }
                                .hidden()
                        )
                    }
                    .frame(width: 170, height: 170)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                }
            }
            
            Button(action: {
                print("Delete button tapped for item: \(item.id)") // Debugging print
                // deleteMultimediaItem هذي موجوده في modelview multimedia
                multimediaVM.deleteMultimediaItem(recordID: item.recordID) // Ensure item has a recordID
            }) {
                Text("Delete")
                    .foregroundColor(.red)
                    .font(.footnote)
                    .padding(5)
            }



        }
    }
// deletes
    // Function to return multimedia items in a format that can be used in the grid
    func getMultimediaItems(from multimedia: Multimedia) -> [MultimediaItem] {
        var items: [MultimediaItem] = []
        
        // Add text items
        for text in multimedia.TextInsert {
            items.append(MultimediaItem(id: UUID(), type: .text(text), recordID: multimedia.id)) // Use the multimedia's recordID
        }
        
        // Add link items
        for link in multimedia.LinkInsert {
            items.append(MultimediaItem(id: UUID(), type: .link(link), recordID: multimedia.id)) // Use the multimedia's recordID
        }
        
        // Add image items
        for image in multimedia.images {
            items.append(MultimediaItem(id: UUID(), type: .image(image), recordID: multimedia.id)) // Use the multimedia's recordID
        }
        
        // Add file items
        if let fileURLs = multimedia.fileInsert?.compactMap({ $0.fileURL }) {
            for fileURL in fileURLs {
                items.append(MultimediaItem(id: UUID(), type: .file(fileURL), recordID: multimedia.id)) // Use the multimedia's recordID
            }
        }
        
        return items
    }




    
    
    
    
    // Enum for multimedia types
    enum MultimediaType {
        case text(String)
        case link(String)
        case image(UIImage)
        case file(URL)
    }
    
    // Struct for multimedia items
    struct MultimediaItem: Identifiable, Hashable {
        let id: UUID
        let type: MultimediaType
        let recordID: CKRecord.ID  // Ensure this property exists

        static func == (lhs: MultimediaItem, rhs: MultimediaItem) -> Bool {
            return lhs.id == rhs.id
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }


    
    
    struct ContentSheet: View {
        @Binding var isLinkSheetPresented: Bool
        @Binding var isTextSheetPresented: Bool
        @Binding var newLink: String
        @Binding var newText: String
        var multimediaVM: MultimediaViewModel
        var board: Board
        
        @State private var selectedItems: [PhotosPickerItem] = [] // State to hold PhotosPicker items
        @State private var selectedImages: [UIImage] = [] // Store selected images
        @State private var showImagePicker: Bool = false
        @State private var showDocumentPicker: Bool = false // State for document picker
        @State private var selectedFileURL: URL? // Store selected file URL
        @State private var isLoading: Bool = false
        
        var body: some View {
            VStack {
                HStack {
                    // Add new Link Button
                    Button(action: { isLinkSheetPresented = true }) {
                        VStack {
                            Image(systemName: "link")
                                .font(.system(size: 20))
                                .foregroundColor(Color.blue)
                            Text("Link")
                                .font(.caption)
                                .foregroundColor(Color.blue)
                        }
                        .frame(width: 70, height: 75)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(15)
                    }
                    .sheet(isPresented: $isLinkSheetPresented) {
                        LinkFieldsSheet(newLink: $newLink, multimediaVM: multimediaVM, board: board)
                    }
                    
                    // Add new Text Button
                    Button(action: { isTextSheetPresented = true }) {
                        VStack {
                            Image(systemName: "text.justify")
                                .font(.system(size: 20))
                                .foregroundColor(Color.blue)
                            Text("Text")
                                .font(.caption)
                                .foregroundColor(Color.blue)
                        }
                        .frame(width: 70, height: 75)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(15)
                    }
                    .sheet(isPresented: $isTextSheetPresented) {
                        TextFieldsSheet(newText: $newText, multimediaVM: multimediaVM, board: board)
                    }
                    
                    // Add new Photo Button
                    PhotosPicker(selection: $selectedItems, matching: .images, photoLibrary: .shared()) {
                        VStack {
                            Image(systemName: "photo")
                                .font(.system(size: 20))
                                .foregroundColor(Color.blue)
                            Text("Photo")
                                .font(.caption)
                                .foregroundColor(Color.blue)
                        }
                        .frame(width: 70, height: 75)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(15)
                    }
                    .onChange(of: selectedItems) { newItems in
                        loadImages(from: newItems)
                    }
                    
                    // Add new File Button for PDF/DOC uploads
                    Button(action: { showDocumentPicker.toggle() }) {
                        VStack {
                            Image(systemName: "doc")
                                .font(.system(size: 20))
                                .foregroundColor(Color.blue)
                            Text("File")
                                .font(.caption)
                                .foregroundColor(Color.blue)
                        }
                        .frame(width: 70, height: 75)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(15)
                    }
                    .sheet(isPresented: $showDocumentPicker) {
                        DocumentPickerView { url in
                            handleSelectedFile(fileURL: url)
                        }
                    }
                }
            }
            .presentationDetents([.height(300)])
        }
        
        // Function to load selected images
        private func loadImages(from items: [PhotosPickerItem]) {
            isLoading = true
            let dispatchGroup = DispatchGroup()
            
            for item in items {
                dispatchGroup.enter()
                item.loadTransferable(type: Data.self) { result in
                    switch result {
                    case .success(let data):
                        if let data = data, let image = UIImage(data: data) {
                            DispatchQueue.main.async {
                                selectedImages.append(image)
                                multimediaVM.saveImage(image, for: board) // Save image to CloudKit
                            }
                        }
                    case .failure(let error):
                        print("Error loading image: \(error)")
                    }
                    dispatchGroup.leave()
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                isLoading = false
            }
        }
        
        // Function to handle selected file (PDF, DOC)
        private func handleSelectedFile(fileURL: URL) {
            selectedFileURL = fileURL
            
            guard selectedFileURL?.startAccessingSecurityScopedResource() == true else {
                print("Failed to access security-scoped resource.")
                return
            }
            
            // Try to load the file data
            do {
                let fileData = try Data(contentsOf: selectedFileURL!)
                //decode JSON data
                print("File data loaded successfully.")
                
                // Save file to CloudKit
                multimediaVM.saveFile(fileURL, for: board)
            } catch {
                print("Error accessing file data: \(error.localizedDescription)")
            }
            
            // Stop accessing the security-scoped resource
            selectedFileURL?.stopAccessingSecurityScopedResource()
        }
        
    }
    
    struct PDFDetailView: View {
        let url: URL
        
        var body: some View {
            VStack {
                PDFViewer(url: url)
                    .edgesIgnoringSafeArea(.all) // Display PDF full-screen
            }
            .navigationTitle(url.lastPathComponent) // Set the title to the PDF's file name
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    // Document picker for selecting PDFs/DOCs
    struct DocumentPickerView: UIViewControllerRepresentable {
        var onPickFile: (URL) -> Void
        
        func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
            let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf, .plainText, .rtf, .item])
            documentPicker.delegate = context.coordinator
            return documentPicker
        }
        
        func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
        
        func makeCoordinator() -> Coordinator {
            Coordinator(self)
        }
        
        class Coordinator: NSObject, UIDocumentPickerDelegate {
            var parent: DocumentPickerView
            
            init(_ parent: DocumentPickerView) {
                self.parent = parent
            }
            
            func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
                guard let pickedURL = urls.first else { return }
                parent.onPickFile(pickedURL)
            }
        }
    }
}
