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


struct PDFInfo {
    let text: String
    let zipfile: String
    let pdffile: String
}

func getPDFsRecursively(zipfile: URL) -> [PDFInfo] {
    var out = [PDFInfo]()
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
    let enumerator = fileManager.enumerator(atPath: destinationURL.path)
    while let element = enumerator?.nextObject() as? String {
        if element.hasSuffix("pdf") {
            if let text = readPDF(element) {
                out.append(PDFInfo(text: text, zipfile: zipfile.lastPathComponent, pdffile: element))
            }
        }
    }
    let _ = try? fileManager.removeItem(at: destinationURL)
    return out
}

func makeURLLocal(_ filename: String) -> URL {
    let fileManager = FileManager()
    let currentWorkingPath = fileManager.currentDirectoryPath
    var sourceURL = URL(fileURLWithPath: currentWorkingPath)
    sourceURL.appendPathComponent(filename)
    return sourceURL
}


let db = try! Connection("docs.sqlite3")
let documents = Table("documents")
let id = Expression<Int>("id")
let text = Expression<String>("text")
let zipfile = Expression<String>("zipfile")
let pdffile = Expression<String>("pdffile")


try! db.run(documents.create(ifNotExists: true) { t in
               t.column(id, primaryKey: true)
               t.column(text)
               t.column(zipfile)
               t.column(pdffile)
           })

func addToDb(_ pdf: PDFInfo) {
    let insertOperation = documents.insert(text <- pdf.text,
                                           zipfile <- pdf.zipfile,
                                           pdffile <- pdf.pdffile)
    let _ = try! db.run(insertOperation)
}

func ripPDFs(zipfile: URL){
    let texts = getPDFsRecursively(zipfile: zipfile)
    texts.forEach(addToDb)
}

let toRip = makeURLLocal("cardagts.zip")
ripPDFs(zipfile: toRip)

let numRows = try! db.scalar(documents.count)
print(numRows)
