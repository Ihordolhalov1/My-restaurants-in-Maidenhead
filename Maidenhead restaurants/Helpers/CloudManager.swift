//
//  CloudManager.swift
//  Maidenhead restaurants
//
//  Created by Ihor Dolhalov on 31.10.2022.
//

import UIKit
import CloudKit


class CloudManager {
    
    private static let privateCloudDatabase = CKContainer.default().publicCloudDatabase
    
    static func saveDataToCloud(place: Place, image: UIImage)  {
        let (image, url) = prepareImageToSaveToCloud(place: place, image: image)
        
        guard let imageAsset = image, let imageURL = url else { return }
        
        let record = CKRecord(recordType: "Place")
        record.setValue(place.name, forKey: "name")
        record.setValue(place.location, forKey: "location")
        record.setValue(place.type, forKey: "type")
        record.setValue(place.rating, forKey: "rating")
        record.setValue(imageAsset, forKey: "imageData")
        
        privateCloudDatabase.save(record) { _, error in
            if let error = error { print(error); return }
            deleteTempImage(imageURL: imageURL)
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
    
}
