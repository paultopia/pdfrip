import Quartz
import Foundation
import ZIPFoundation
import SQLite

func readPDF(_ file: String) -> String? {
    guard let pdata = try? NSData(contentsOfFile: file) as Data else {
        print("failed to open file")
        return nil
    }
    guard let pdf = PDFDocument(data: pdata) else {
        print("failed to read data as pdf")
        return nil
    }
    guard let text = pdf.string else {
        print("no text in pdf")
        return nil
    }
    return text
}

// print(readPDF("MasterCard_Consumer_Credit_Card_Agreement.pdf"))


func getPDFsRecursively(zipfile: URL) {
    let fileManager = FileManager()
    let currentWorkingPath = fileManager.currentDirectoryPath
    var destinationURL = URL(fileURLWithPath: currentWorkingPath)
    destinationURL.appendPathComponent("tempOut")
    do {
        try fileManager.createDirectory(at: destinationURL, withIntermediateDirectories: true, attributes: nil)
        try fileManager.unzipItem(at: zipfile, to: destinationURL)
    } catch {
        print("Extraction of ZIP archive failed with error:\(error)")
    }
    let enumerator = fileManager.enumerator(at: destinationURL, includingPropertiesForKeys: nil)
    print(enumerator)
    while let element = enumerator?.nextObject() as? String {
        print(element)
        if element.hasSuffix("pdf") { // checks the extension
            print(element)
        }
    }
}

func makeURLLocal(_ filename: String) -> URL {
    let fileManager = FileManager()
    let currentWorkingPath = fileManager.currentDirectoryPath
    var sourceURL = URL(fileURLWithPath: currentWorkingPath)
    sourceURL.appendPathComponent(filename)
    return sourceURL
}

let zipfile = makeURLLocal("cardagts.zip")
print(zipfile)

getPDFsRecursively(zipfile: zipfile)
