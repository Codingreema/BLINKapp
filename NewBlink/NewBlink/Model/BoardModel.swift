//
//  BoardModel.swift
//  NewBlink
//
//  Created by rania on 21/02/1446 AH.
//

import Foundation
import CloudKit

struct Board: Identifiable {
    let id: CKRecord.ID
    var BoardName: String

    init(record: CKRecord) {
        self.id = record.recordID
        self.BoardName = record["BoardName"] as? String ?? "UnTiteld"
    }
}
