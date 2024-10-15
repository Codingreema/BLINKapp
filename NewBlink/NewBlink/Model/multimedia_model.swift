
import Foundation
import CloudKit
import SwiftUI
// Multimedia Model



struct Multimedia: Identifiable {
    let id: CKRecord.ID
    let TextInsert: [String]
    let LinkInsert: [String]
    let AssetInsert: [CKAsset]?
    let boardReference: CKRecord.Reference? // مرجع للـ Board المرتبط
    let fileInsert: [CKAsset]?
    let board: CKRecord.Reference?
    let fileURL: URL?

    // file to import
    var firstFileURL: URL? {
        fileInsert?.first?.fileURL
    }
    
    var images: [UIImage] {
        return AssetInsert?.compactMap { asset in
            if let fileURL = asset.fileURL, let data = try? Data(contentsOf: fileURL), let image = UIImage(data: data) {
                return image
            }
            return nil
        } ?? []
    }

    
    init(record: CKRecord) {
        self.id = record.recordID
        self.TextInsert = record["TextInsert"] as? [String] ?? []
        self.LinkInsert = record["LinkInsert"] as? [String] ?? []
        self.AssetInsert = record["AssetInsert"] as? [CKAsset]
        self.boardReference = record["boardReference"] as? CKRecord.Reference // تعيين المرجع
        self.fileInsert = record["fileInsert"] as? [CKAsset]
        self.board = record["board"] as? CKRecord.Reference
        self.fileURL = record["fileURL"] as? URL
    }
}

