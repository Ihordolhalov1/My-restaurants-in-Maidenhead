//
//  CloudManager.swift
//  Maidenhead restaurants
//
//  Created by Ihor Dolhalov on 31.10.2022.
//

import UIKit
import CloudKit
import RealmSwift


class CloudManager {
    
    private static let privateCloudDatabase = CKContainer.default().privateCloudDatabase
    private static var records: [CKRecord] = []
    static func saveDataToCloud(place: Place, image: UIImage, clouser: @escaping (String) -> ())  {
        let (image, url) = prepareImageToSaveToCloud(place: place, image: image)
        
        guard let imageAsset = image, let imageURL = url else { return }
        
        let record = CKRecord(recordType: "Place")
        record.setValue(place.placeID, forKey: "placeID")
        record.setValue(place.name, forKey: "name")
        record.setValue(place.location, forKey: "location")
        record.setValue(place.type, forKey: "type")
        record.setValue(place.rating, forKey: "rating")
        record.setValue(imageAsset, forKey: "imageData")
        
        privateCloudDatabase.save(record) { newRecord, error in
            if let error = error { print(error); return }
            if let newRecord = newRecord {
                clouser(newRecord.recordID.recordName)
            }
            deleteTempImage(imageURL: imageURL)
        }
    }
    
    // функція виймання даних з iCloud
    static func fetchDataFromCloud(places: Results<Place>, closure: @escaping (Place) -> ()) {
        
        let query = CKQuery(recordType: "Place", predicate: NSPredicate(value: true)) //создаю запрос в базу, ніяк не обмежуючи
        query.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)] // сортірую по імені по возрастанию
        
       let queryOperation = CKQueryOperation(query: query)
        queryOperation.desiredKeys = ["recordID", "placeID", "name", "location", "type", "rating"]
        queryOperation.resultsLimit = 10
        queryOperation.queuePriority = .veryHigh
        
        queryOperation.recordFetchedBlock = { record in
            
            self.records.append(record)
            let newPlace = Place(record: record)
            
            DispatchQueue.main.async {
                if newCloudRecordIsAvailable(places: places, placeID: newPlace.placeID) {closure(newPlace)}
            }
        }
        queryOperation.queryCompletionBlock = { cursor, error in
            if let error = error { print(error.localizedDescription); return }
            guard let cursor = cursor else { return }
            
            let secondQueryOperation = CKQueryOperation(cursor: cursor)
            secondQueryOperation.recordFetchedBlock = { record in
                self.records.append(record)
                let newPlace = Place(record: record)
                DispatchQueue.main.async {
                    if newCloudRecordIsAvailable(places: places, placeID: newPlace.placeID) {
                        closure(newPlace)
                    }
                }
            }
            secondQueryOperation.queryCompletionBlock = queryOperation.queryCompletionBlock
            privateCloudDatabase.add(secondQueryOperation)
            
        }
        privateCloudDatabase.add(queryOperation)
    }
        
    static func updateCloudDate(place: Place, with image: UIImage) {
            let recordID = CKRecord.ID (recordName: place.recordID)
            let (image, url) = prepareImageToSaveToCloud(place: place, image: image)
            guard let imageAsset = image, let imageURL = url else { return }
        privateCloudDatabase.fetch(withRecordID: recordID) { record, error in
            
            if let record = record, error == nil {
                DispatchQueue.main.async {
                    record.setValue(place.name, forKey: "name")
                    record.setValue(place.location, forKey: "location")
                    record.setValue(place.type, forKey: "type")
                    record.setValue(place.rating, forKey: "rating")
                    record.setValue(imageAsset, forKey: "imageData")
                    
                    privateCloudDatabase.save(record) { _, error in
                        if let error = error { print(error.localizedDescription); return }
                        deleteTempImage(imageURL: imageURL)
                    }
                    
                }
            }
            
        }
            
        }
        
    static func getImageFromCloud(place:Place, closure: @escaping (Data?) -> ()) {
        records.forEach { record in
            if place.recordID == record.recordID.recordName {
                let fetchRecordsOperation = CKFetchRecordsOperation(recordIDs: [record.recordID])
                fetchRecordsOperation.desiredKeys = ["imageData"]
                fetchRecordsOperation.perRecordCompletionBlock = { record, _, error in
                    guard error == nil else { return }
                    guard let record = record else { return }
                    guard let possibleImage = record.value(forKey: "imageData") as? CKAsset else { return }
                    guard let imageData = try? Data(contentsOf: possibleImage.fileURL!) else { return }
                    
                    DispatchQueue.main.async {
                        closure(imageData)
                    }
                }
                privateCloudDatabase.add(fetchRecordsOperation)
            }
        }
    }
    
    static func deleteRecord(recordID: String) {
        let query = CKQuery(recordType: "Place", predicate: NSPredicate(value: true))
        let queryOperation = CKQueryOperation(query: query)
        queryOperation.desiredKeys = ["recordID"]
        queryOperation.queuePriority = .veryHigh
        
        queryOperation.recordFetchedBlock = { record in
            if record.recordID.recordName == recordID {
                print("RecordID found!!!")
                privateCloudDatabase.delete(withRecordID: record.recordID) { (_, error) in
                    if let error = error { print(error) ; return }
                    
                }
            } else {print("recordID WAS NOT FOUND")}
            queryOperation.queryCompletionBlock = { _, error in
                if let error = error { print(error) ; return }
            }
            privateCloudDatabase.add(queryOperation)
        }
    }
    
    
    // MARK: Private Methods
    
    private static func prepareImageToSaveToCloud(place: Place, image: UIImage)  -> (CKAsset?, URL?) {
        // перевірка розміру картінки
        let scale = image.size.width > 1080 ? 1080 / image.size.width : 1   // коефіціент, на скільки умножати розмір, або на 1080/розмір щоб отримати 1080, або на 1
        let scaleImage = UIImage(data: image.pngData()!, scale: scale)  // сжате фото
        let imageFilePath = NSTemporaryDirectory() + place.name         // тимчасова директорія для сберігання
        let imageUrl = URL(fileURLWithPath: imageFilePath)  // повне посилання на файл
       
        
        guard let dataToPath = scaleImage?.jpegData(compressionQuality: 1) else { return (nil, nil) }       //png to jpeg
        
        do {
            try dataToPath.write(to: imageUrl, options: .atomic) // запись файла
        } catch {
            print(error.localizedDescription)
        }
        let imageAsset = CKAsset(fileURL: imageUrl)
        
        return (imageAsset, imageUrl)
        
    }
    
    static private func deleteTempImage(imageURL: URL) {
        do {
           try FileManager.default.removeItem(at: imageURL)  // видалення файла картінки з тимчасового каталога після записа в хмару
        }
        catch {
            print(error.localizedDescription)
        }
    }
    
    private static func newCloudRecordIsAvailable(places: Results<Place>, placeID: String) -> Bool {
        for place in places {
            if place.placeID == placeID {
                return false
            }
        }
                return true
    }
}
