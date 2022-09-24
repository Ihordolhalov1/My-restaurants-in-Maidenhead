//
//  placeModel.swift
//  Maidenhead restaurants
//
//  Created by Ihor Dolhalov on 24.09.2022.
//

import Foundation

struct Place {
    var name: String
    var location: String
    var type: String
    var image: String
    
    
    static let restaurantNames = [
        "The Cricketers", "The Boathouse at Boulters Lock", "The Fat Buddha", "Gandhi's Restaurant", "The Beehive White Waltham",
        "The Crown - Burchetts Green", "The Pinkneys Arms", "The Belgian Arms", "Hurley House Hotel"]
    
    static func getPlaces() -> [Place] {
        var places = [Place]()
        
        for place in restaurantNames {
            places.append(Place(name: place, location: "Maidenhead", type: "Pub", image: place))
        }
        return places
    }
}
