//
//  FileOp.swift
//  reteach
//
//  Created by Antariksh Verma on 17/07/25.
//

import Foundation

func createNotesDirectoryIfDoesntExist() {
    // For debug: Prints the data directory of the simulator on the physical computer. Is to check whether files are saved there.
    print(NSHomeDirectory())
    
    // Fetch documents folder and create a new folder, if it doesn't already exist
    let fileManager = FileManager.default
    let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    
    if !fileManager.fileExists(atPath: documentsURL.appendingPathComponent("reteach-notes").path) {
        do {
            try fileManager.createDirectory(at: documentsURL.appendingPathComponent("reteach-notes"), withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("Error creating notes directory: \(error.localizedDescription)")
        }
    }
}

func createNewFile(fileName: String) {
    // Hyphenize the fileName, to ensure no spaces exist
    let fileNameWithHyphen = fileName.replacingOccurrences(of: " ", with: "-")
    
    // Fetch reteach-notes folder
    let fileManager = FileManager.default
    let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    let dirUrl = documentsURL.appendingPathComponent("reteach-notes")
    
    // Set file's url
    let fileUrl = dirUrl.appendingPathComponent(fileNameWithHyphen + ".drawing")
    
    // Create file
    fileManager.createFile(atPath: fileUrl.path, contents: nil, attributes: nil)
}

func deleteFile(fileName: String) {
    // Hyphenize the fileName, to ensure no spaces exist
    let fileNameWithHyphen = fileName.replacingOccurrences(of: " ", with: "-")
    
    // Fetch reteach-notes folder
    let fileManager = FileManager.default
    let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    let dirUrl = documentsURL.appendingPathComponent("reteach-notes")
    
    let fileUrl = dirUrl.appendingPathComponent(fileNameWithHyphen + ".drawing")
    
    do {
        try fileManager.removeItem(at: fileUrl)
        print("File deleted successfully")
    } catch {
        print("Error deleting file: \(error.localizedDescription)")
    }
}

func getFilePath(fileName: String) -> URL {
    // Hyphenize the fileName, to ensure no spaces exist
    let fileNameWithHyphen = fileName.replacingOccurrences(of: " ", with: "-")
    
    // Fetch reteach-notes folder
    let fileManager = FileManager.default
    let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    let dirUrl = documentsURL.appendingPathComponent("reteach-notes")
    
    let fileUrl = dirUrl.appendingPathComponent(fileNameWithHyphen + ".drawing")
    
    return fileUrl
}
