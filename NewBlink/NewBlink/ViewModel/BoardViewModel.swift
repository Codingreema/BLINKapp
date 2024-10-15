//
//  BoardViewModel.swift
//  NewBlink
//
//  Created by rania on 22/02/1446 AH.
//

import Foundation
import CloudKit
import SwiftUI

class BoardViewModel: ObservableObject {
    @Published var boards: [Board] = []
    private var database = CKContainer.default().privateCloudDatabase
    
    init() {
        // Set the container to the correct identifier once in the initializer
        let container = CKContainer(identifier: "iCloud.BlinkData")
        self.database = container.privateCloudDatabase
    }
    
    
 
    func createBoard() {
          let newBoard = CKRecord(recordType: "Board")
          newBoard["BoardName"] = "Untitled"
          
          database.save(newBoard) { record, error in
              if let error = error {
                  print("Error saving board: \(error.localizedDescription)")
              } else if let record = record {
                  DispatchQueue.main.async {
                      // Add the new board to the local list after it's saved successfully
                      let board = Board(record: record)
                      self.boards.append(board)
                  }
              }
          }
      }
    // Fetch boards
    func fetchBoards() {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "Board", predicate: predicate)
        let operation = CKQueryOperation(query: query)

        operation.recordMatchedBlock = { recordId, result in
            DispatchQueue.main.async {
                switch result {
                case .success(let record):
                    let board = Board(record: record)
                    if !self.boards.contains(where: { $0.id == board.id }) {
                        self.boards.append(board)
                    }
                case .failure(let error):
                    print("\(error.localizedDescription)")
                }
            }
        }

        CKContainer(identifier:"iCloud.BlinkData").privateCloudDatabase.add(operation)
    }
    
     
    // ميثود تعرض البورد بشكل مصغر
    func fetchBoardThumbnail(for board: Board, completion: @escaping (UIImage?) -> Void) {
        let predicate = NSPredicate(format: "boardReference == %@", CKRecord.Reference(recordID: board.id, action: .none))
        let query = CKQuery(recordType: "Multimedia", predicate: predicate)
        let operation = CKQueryOperation(query: query)
        
        var foundImage: UIImage?

        operation.recordMatchedBlock = { recordId, result in
            DispatchQueue.main.async {
                switch result {
                case .success(let record):
                    let multimedia = Multimedia(record: record)
                    if let firstImage = multimedia.images.first {
                        foundImage = firstImage
                    }
                case .failure(let error):
                    print("Error fetching multimedia: \(error.localizedDescription)")
                }
            }
        }

        operation.queryCompletionBlock = { cursor, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error completing multimedia fetch: \(error.localizedDescription)")
                }
                completion(foundImage)
            }
        }

        CKContainer(identifier: "iCloud.BlinkData").privateCloudDatabase.add(operation)
    }


   
    
    func updateBoardName(_ board: Board, newName: String) {
        let recordID = board.id
        let predicate = NSPredicate(format: "recordID == %@", recordID)
        let query = CKQuery(recordType: "Board", predicate: predicate)
        let operation = CKQueryOperation(query: query)

        operation.recordMatchedBlock = { recordID, result in
            switch result {
            case .success(let record):
                record["BoardName"] = newName

                self.database.save(record) { savedRecord, saveError in
                    if let saveError = saveError {
                        print("Error saving updated board name: \(saveError.localizedDescription)")
                    } else {
                        DispatchQueue.main.async {
                            if let index = self.boards.firstIndex(where: { $0.id == board.id }) {
                                self.boards[index].BoardName = newName
                            }
                        }
                    }
                }

            case .failure(let error):
                print("Error fetching board: \(error.localizedDescription)")
            }
        }

        CKContainer(identifier: "iCloud.BlinkData").privateCloudDatabase.add(operation)
    }

    
    
    }


