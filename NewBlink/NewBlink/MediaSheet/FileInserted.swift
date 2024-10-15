//
//  FileInserted.swift
//  NewBlink
//
//  Created by Rimah on 08/03/1446 AH.
//
//

// اغراض البي دي اف البريفيو والثامنيل
import SwiftUI
import PDFKit

struct PDFViewer: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        if let document = PDFDocument(url: url) {
            uiView.document = document
        }
    }
}
// فنكشن للثامنيل صورة مصغرة للبي دي اف تطلع لك اول صفحة للبي دي اف
func generatePDFThumbnail(for url: URL, size: CGSize = CGSize(width: 300, height: 300)) -> UIImage? {
    guard let pdfDocument = PDFDocument(url: url),
          let pdfPage = pdfDocument.page(at: 0) else {
        return nil
    }
    
    let pageRect = pdfPage.bounds(for: .mediaBox)
    let renderer = UIGraphicsImageRenderer(size: size)
    let thumbnail = renderer.image { context in
        context.cgContext.translateBy(x: 0.0, y: size.height)
        context.cgContext.scaleBy(x: 1.0, y: -1.0)
        
        let scaleFactor = min(size.width / pageRect.width, size.height / pageRect.height)
        let scaledWidth = pageRect.width * scaleFactor
        let scaledHeight = pageRect.height * scaleFactor
        let xOffset = (size.width - scaledWidth) / 2.0
        let yOffset = (size.height - scaledHeight) / 2.0
        
        context.cgContext.saveGState()
        context.cgContext.translateBy(x: xOffset, y: yOffset)
        context.cgContext.scaleBy(x: scaleFactor, y: scaleFactor)
        pdfPage.draw(with: .mediaBox, to: context.cgContext)
        context.cgContext.restoreGState()
    }
    
    return thumbnail
}
