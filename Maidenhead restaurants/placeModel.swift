//
//  placeModel.swift
//  Maidenhead restaurants
//
//  Created by Ihor Dolhalov on 24.09.2022.
//

import RealmSwift
import CloudKit

class Place: Object {
    @Persisted(primaryKey: true) var placeID = UUID().uuidString
  //  @Persisted var placeID = UUID().uuidString // назначаю головний ідентифікатор бази (унікальний номер елеиента бази)
    @Persisted var recordID = ""
    @Persisted var name = ""
    @Persisted var location: String?
    @Persisted var type: String?
    @Persisted var imageData: Data?
    @Persisted var date = Date()
    @Persisted var rating = 0.0
    
    //назначаем инициализатор convinience значит не обязательный
    convenience init(name: String = "", location: String? = nil, type: String? = nil, imageData: Data? = nil, rating: Double) {
        self.init()
        self.name = name
        self.location = location
        self.type = type
        self.imageData = imageData
        self.rating = rating
    }
    
    convenience init(record: CKRecord) { //ініціалізуємо значення моделі з бази iCloud
        self.init()
        
        let image = UIImage(imageLiteralResourceName: "imagePlaceholder")
        let imageData = image.pngData()
        
        self.placeID = record.value(forKey: "placeID") as! String
        self.recordID = record.recordID.recordName
        self.name = record.value(forKey: "name") as! String
        self.location = record.value(forKey: "location") as? String
        self.type = record.value(forKey: "type") as? String
        self.imageData = imageData
        self.rating = record.value(forKey: "rating") as! Double
    }
    
    static override func primaryKey() -> String? {
        return "placeID"
    }
   /* class Project: Object {
        @Persisted(primaryKey: true) var id = 0
        @Persisted var name = "" */
    
}
