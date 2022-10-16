//
//  RatingControl.swift
//  Maidenhead restaurants
//
//  Created by Ihor Dolhalov on 15.10.2022.
//

import UIKit

@IBDesignable class RatingControl: UIStackView {
    
    //кількість кнопок і рейтінг
    private var ratingButtons = [UIButton]()
    var rating = 0 {
        didSet {updateButtonSelectionState()}
    }
    
    @IBInspectable var starSize: CGSize = CGSize(width: 44, height: 44) {
        didSet {SetupButtons()}}
    @IBInspectable var starCount:Int = 5 {
        didSet {SetupButtons()}}
    
    
    
    
    // MARK: Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        SetupButtons()
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        SetupButtons()
        }
    
    // button action
    @objc func ratingButtonTapped(button: UIButton) {
        guard let index = ratingButtons.firstIndex(of: button) else {return}
        let selectedRating = index + 1
        if selectedRating == rating { rating = 0 }
        else { rating = selectedRating }
    }
    
    
    // приватный метод создания кнопки в виде звезды
    
    private func SetupButtons() {
        //load button image
        let bundle = Bundle(for: type(of: self))
        let filledStar = UIImage(named: "filledStar", in: bundle, compatibleWith: self.traitCollection)
        let emptyStar = UIImage(named: "emptyStar", in: bundle, compatibleWith: self.traitCollection)
        let highliteredStar = UIImage(named: "highlightedStar", in: bundle, compatibleWith: self.traitCollection)
        
        for _ in 1...starCount {
            // створюємо кнопки
            let button = UIButton()
            // встанавлюємо колір кнопки
            
            button.setImage(emptyStar, for: .normal)
            button.setImage(filledStar, for: .selected)
            button.setImage(highliteredStar, for: .highlighted)
            button.setImage(highliteredStar, for: [.highlighted, .selected])
            
            //constraints:
            button.translatesAutoresizingMaskIntoConstraints = false //откоючить  автоматическое определение констрейтов
            button.heightAnchor.constraint(equalToConstant: starSize.height).isActive = true
            button.widthAnchor.constraint(equalToConstant: starSize.width).isActive = true
        
            //setup the button action
            button.addTarget(self, action: #selector(ratingButtonTapped(button:)), for: .touchUpInside)
            
            // add to the stack
            addArrangedSubview(button)
            
            // add the new button to the rating button array
            ratingButtons.append(button)
        }
        updateButtonSelectionState()
    }
    
    private func updateButtonSelectionState() {
        for (index, button) in ratingButtons.enumerated() {
            button.isSelected = index < rating
        }
    }
}
