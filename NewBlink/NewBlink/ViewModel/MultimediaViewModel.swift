//
//  MultimediaViewModel.swift
//  NewBlink
//
//  Created by rania on 29/02/1446 AH.
//
import Foundation
import CloudKit
import PhotosUI
import UIKit

class MultimediaViewModel: ObservableObject {
    @Published var boards: [Board] = []
    @Published var mediaArr: [Multimedia] = []
    
    // MARK: - Fetch Multimedia
    // General function for fetching multimedia with optional filters
    func fetchMultimedia(for board: Board, filterKey: String? = nil) {
        self.mediaArr = [] // Clear previous data
        
        let predicate = NSPredicate(format: "boardReference == %@", board.id)
        let query = CKQuery(recordType: "Multimedia", predicate: predicate)
        let operation = CKQueryOperation(query: query)
        
        operation.recordMatchedBlock = { recordId, result in
            DispatchQueue.main.async {
                switch result {
                case .success(let record):
                    let media = Multimedia(record: record)
                    
                    // Check if there's a filter (for example, only links or only text)
                    if let filterKey = filterKey {
                        if let value = record[filterKey] as? String, !value.isEmpty {
                            if !self.mediaArr.contains(where: { $0.id == media.id }) {
                                self.mediaArr.append(media)
                            }
                        }
                    } else {
                        if !self.mediaArr.contains(where: { $0.id == media.id }) {
                            self.mediaArr.append(media)
                        }
                    }
                    
                case .failure(let error):
                    print("Error fetching multimedia: \(error.localizedDescription)")
                }
            }
        }
        
        operation.queryResultBlock = { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    print("Successfully fetched multimedia")
                case .failure(let error):
                    print("Error completing multimedia fetch: \(error.localizedDescription)")
                }
            }
        }
        
        CKContainer(identifier: "iCloud.BlinkData").privateCloudDatabase.add(operation)
    }
    
    // MARK: - Convenience Functions for Specific Types
    func fetchLinks(for board: Board) {
        fetchMultimedia(for: board, filterKey: "LinkInsert")
    }
    
    func fetchText(for board: Board) {
        fetchMultimedia(for: board, filterKey: "TextInsert")
    }
    
    func fetchMedia(for board: Board) {
        fetchMultimedia(for: board) // No filter, fetch all multimedia
    }
    
    // MARK: - Save Media
    // General save function to reduce duplication
    func saveMedia(type: String, value: Any, for board: Board) {
        let newRecord = CKRecord(recordType: "Multimedia")
        
        // Ensure the value conforms to CloudKit types
        if let stringArray = value as? [String] {
            newRecord[type] = stringArray as CKRecordValue // Handle String arrays
        } else if let assetArray = value as? [CKAsset] {
            newRecord[type] = assetArray as CKRecordValue // Handle CKAsset arrays
        }
        
        // Create a reference to the board
        let boardReference = CKRecord.Reference(recordID: board.id, action: .none)
        newRecord["boardReference"] = boardReference
        
        // Save the new record to CloudKit
        CKContainer(identifier: "iCloud.BlinkData").privateCloudDatabase.save(newRecord) { [weak self] record, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error saving new \(type): \(error.localizedDescription)")
                } else {
                    print("Successfully saved new \(type)")
                    // Optionally, update the local `mediaArr` if needed
                    if let record = record {
                        let media = Multimedia(record: record)
                        self?.mediaArr.append(media)
                    }
                }
            }
        }
    }

    
    // MARK: - Specific Save Functions
    func saveLink(_ link: String, for board: Board) {
        saveMedia(type: "LinkInsert", value: [link], for: board) // Wrap link in an array
    }

    
    func saveText(_ userText: String, for board: Board) {
        saveMedia(type: "TextInsert", value: [userText], for: board) // Wrap text in an array
    }

    
    // MARK: - Save File
    func saveFile(_ fileURL: URL, for board: Board) {
        saveAsset(fileURL: fileURL, assetKey: "fileInsert", for: board)
    }
    
    // MARK: - Save Image
    func saveImage(_ image: UIImage, for board: Board) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".jpg")
        
        do {
            try imageData.write(to: tempURL)
            saveAsset(fileURL: tempURL, assetKey: "AssetInsert", for: board)
        } catch {
            print("Error writing image to temporary URL: \(error)")
        }
    }
    
    // MARK: - Save CKAsset (Common for files and images)
    private func saveAsset(fileURL: URL, assetKey: String, for board: Board) {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + fileURL.pathExtension)
        
        do {
            // Copy the file to the temporary URL
            try FileManager.default.copyItem(at: fileURL, to: tempURL)
            let asset = CKAsset(fileURL: tempURL)
            
            // Save asset to CloudKit
            let newRecord = CKRecord(recordType: "Multimedia")
            
            // **Wrap the asset in an array**
            newRecord[assetKey] = [asset] as CKRecordValue
            
            let boardReference = CKRecord.Reference(recordID: board.id, action: .none)
            newRecord["boardReference"] = boardReference
            
            CKContainer(identifier: "iCloud.BlinkData").privateCloudDatabase.save(newRecord) { [weak self] record, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("Error saving \(assetKey): \(error.localizedDescription)")
                    } else {
                        print("Successfully saved \(assetKey)")
                        if let record = record {
                            let media = Multimedia(record: record)
                            self?.mediaArr.append(media)
                        }
                    }
                    // Clean up temporary file
                    try? FileManager.default.removeItem(at: tempURL)
                }
            }
        } catch {
            print("Error copying file to temporary URL: \(error.localizedDescription)")
        }
    }

    
    // MARK: - Delete Multimedia
    func deleteMultimedia(_ multimedia: Multimedia) {
        let recordID = multimedia.id
        
        // Delete from CloudKit
        CKContainer(identifier: "iCloud.BlinkData").privateCloudDatabase.delete(withRecordID: recordID) { [weak self] recordID, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error deleting multimedia: \(error.localizedDescription)")
                } else {
                    print("Successfully deleted multimedia")
                    
                    // Remove the item from the local array after successful deletion
                    if let index = self?.mediaArr.firstIndex(where: { $0.id == recordID }) {
                        self?.mediaArr.remove(at: index)
                    }
                }
            }
        }
    }
    
    // MARK: - Delete Multimedia Item
    func deleteMultimediaItem(recordID: CKRecord.ID) {
        let privateDatabase = CKContainer(identifier: "iCloud.BlinkData").privateCloudDatabase
        
        privateDatabase.delete(withRecordID: recordID) { [weak self] deletedRecordID, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error deleting record: \(error.localizedDescription)")
                } else {
                    print("Successfully deleted record with ID: \(deletedRecordID)")
                    // Remove the item from the local array
                    self?.mediaArr.removeAll { $0.id == recordID }
                }
            }
        }
    }
    
    
    
    // MARK: - Delete Specific Text from Multimedia
    func deleteTextFromMultimedia(_ multimedia: Multimedia, textToDelete: String) {
        let privateDatabase = CKContainer(identifier: "iCloud.BlinkData").privateCloudDatabase
        
        // Fetch the record first
        privateDatabase.fetch(withRecordID: multimedia.id) { record, error in
            if let record = record {
                // Modify the TextInsert field by removing the specific text
                if var textArray = record["TextInsert"] as? [String] {
                    textArray.removeAll { $0 == textToDelete } // Remove the text item
                    record["TextInsert"] = textArray.isEmpty ? nil : textArray
                    
                    // Save the updated record
                    privateDatabase.save(record) { savedRecord, saveError in
                        if let saveError = saveError {
                            print("Error saving updated record: \(saveError.localizedDescription)")
                        } else {
                            print("Successfully updated record with removed text.")
                        }
                    }
                }
            } else if let error = error {
                print("Error fetching record: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Delete Specific Image from Multimedia
    func deleteImageFromMultimedia(_ multimedia: Multimedia, imageToDelete: UIImage) {
        let privateDatabase = CKContainer(identifier: "iCloud.BlinkData").privateCloudDatabase
        
        privateDatabase.fetch(withRecordID: multimedia.id) { record, error in
            if let record = record {
                if var assetArray = record["AssetInsert"] as? [CKAsset] {
                    // Find the image to delete by comparing the fileURLs or image data
                    assetArray.removeAll { asset in
                        if let fileURL = asset.fileURL,
                           let data = try? Data(contentsOf: fileURL),
                           let image = UIImage(data: data) {
                            return image == imageToDelete // Compare images
                        }
                        return false
                    }
                    
                    record["AssetInsert"] = assetArray.isEmpty ? nil : assetArray
                    
                    // Save the updated record
                    privateDatabase.save(record) { savedRecord, saveError in
                        if let saveError = saveError {
                            print("Error saving updated record: \(saveError.localizedDescription)")
                        } else {
                            print("Successfully updated record with removed image.")
                        }
                    }
                }
            } else if let error = error {
                print("Error fetching record: \(error.localizedDescription)")
            }
        }
    }
}
 
