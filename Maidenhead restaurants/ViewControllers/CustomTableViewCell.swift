//
//  CustomTableViewCell.swift
//  Maidenhead restaurants
//
//  Created by Ihor Dolhalov on 24.09.2022.
//

import UIKit

class CustomTableViewCell: UITableViewCell {

    @IBOutlet weak var imageOfRestaurant: UIImageView!
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var typeLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func configureCell(place: Place) {
        nameLabel.text = place.name
        locationLabel.text = place.location
        typeLabel.text = place.type
        imageOfRestaurant.image = UIImage(data: place.imageData!)
     
        imageOfRestaurant.layer.cornerRadius = 85/20
        imageOfRestaurant.clipsToBounds = true
         
       
    }
}
