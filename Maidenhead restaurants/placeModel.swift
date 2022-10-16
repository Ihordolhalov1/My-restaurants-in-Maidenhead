//
//  placeModel.swift
//  Maidenhead restaurants
//
//  Created by Ihor Dolhalov on 24.09.2022.
//

import RealmSwift

class Place: Object {
    @Persisted var name = ""
    @Persisted var location: String?
    @Persisted var type: String?
    @Persisted var imageData: Data?
    @Persisted var date = Date()
    @Persisted var rating = 0.0
    
    //назначаем инициализатор
    convenience init(name: String = "", location: String? = nil, type: String? = nil, imageData: Data? = nil, rating: Double) {
        self.init()
        self.name = name
        self.location = location
        self.type = type
        self.imageData = imageData
        self.rating = rating
    }
}
