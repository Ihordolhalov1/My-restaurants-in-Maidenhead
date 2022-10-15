//
//  StorageManager.swift
//  Maidenhead restaurants
//
//  Created by Ihor Dolhalov on 09.10.2022.
//

import RealmSwift
let realm = try! Realm()
class StorageManager {
    
    static func saveObject(_ place: Place) {
        try! realm.write {
            realm.add(place)
        }
    }
    
    static func deleteObject(_ place: Place) {
        try! realm.write {
            realm.delete(place)
        }
    }
}
