//
//  NewPlaceViewController.swift
//  Maidenhead restaurants
//
//  Created by Ihor Dolhalov on 24.09.2022.
//

import UIKit

class NewPlaceViewController: UITableViewController, MapViewControllerDelegate {
    func getAddress(_address: String?) {
        placeLocation.text = _address
    }
    
    
    var currentPlace: Place!
    
    var imageIsChanged: Bool = false

    @IBOutlet weak var placeImage: UIImageView!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    @IBOutlet weak var placeName: UITextField!
    @IBOutlet weak var placeLocation: UITextField!
    @IBOutlet weak var placeType: UITextField!
    @IBOutlet weak var ratingControl: RatingControl!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        saveButton.isEnabled = false
        placeName.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged) //отслеживание что поле name не пустое чтоб активировать кнопку save
        
        setupEditScreen()
    }
    // MARK: TableViewDelegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            //выбрана первая ячейка
            let cameraIcon = UIImage(imageLiteralResourceName: "camera")
            let photoIcon = UIImage(imageLiteralResourceName: "photo")
            let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            
            let camera = UIAlertAction(title: "Camera", style: .default) { _ in
                self.chooseImagePicker(source: .camera)
            }
            camera.setValue(cameraIcon, forKey: "image") //добавляем значек камеры в меню
            camera.setValue(CATextLayerAlignmentMode.left, forKey: "titleTextAlignment") //смещаем текст тайтла "Camera" влево
            let photo = UIAlertAction(title: "Photo", style: .default) { _ in
                self.chooseImagePicker(source: .photoLibrary)
            }
            photo.setValue(photoIcon, forKey: "image")
            photo.setValue(CATextLayerAlignmentMode.left, forKey: "titleTextAlignment")
            let cancel = UIAlertAction(title: "Cancel", style: .cancel)
            actionSheet.addAction(camera)
            actionSheet.addAction(photo)
            actionSheet.addAction(cancel)
            
            present(actionSheet, animated: true)
            
        } else {
            view.endEditing(true) //скрыть клаву если тапнуть на любую ячейку кроме первой
        }
    }
    // MARK: Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard
            let identifier = segue.identifier,
            let mapVC = segue.destination as? MapViewController
        else { return }
        
        mapVC.incomeSegueIdentifier = identifier
        mapVC.mapViewControlerDelegate = self // назначаем класс newpalceviewcontroller ответственнм за выполнение методов протокола
  
        if identifier == "showPlace" {
            mapVC.place.name = placeName.text!
            mapVC.place.location = placeLocation.text
            mapVC.place.type = placeType.text
            mapVC.place.imageData = placeImage.image?.pngData()
        }
       
        
        
    }

    func savePlace() { //функція зберігання введених нових даних в модель
        var image: UIImage?
        if imageIsChanged {
            image = placeImage.image
        } else {
            image = UIImage(imageLiteralResourceName: "imagePlaceholder")  // =#imageLiteral()
        }
        let imageData = image?.pngData()
        let newPlace = Place(name: placeName.text!, location: placeLocation.text, type: placeType.text, imageData: imageData, rating: Double(ratingControl.rating))
        if currentPlace != nil {
            try! realm.write {
                currentPlace?.name = newPlace.name
                currentPlace?.location = newPlace.location
                currentPlace?.type = newPlace.type
                currentPlace?.imageData = newPlace.imageData
                currentPlace?.rating = newPlace.rating
            }
        } else {
            StorageManager.saveObject(newPlace)
        }
       
    }
    
    private func setupEditScreen () {  //редактирование заведения
        if currentPlace != nil {
            setupNavigationBar ()
            imageIsChanged = true
            
            
            guard let data  = currentPlace?.imageData, let image = UIImage(data: data) else { return }
            placeImage.image = image
            placeImage.contentMode = .scaleAspectFill
            placeName.text = currentPlace?.name
            placeLocation.text = currentPlace?.location
            placeType.text = currentPlace?.type
            ratingControl.rating = Int(currentPlace.rating)
        }
    }
    
    private func setupNavigationBar () {
        navigationItem.leftBarButtonItem = nil
        title = currentPlace?.name
        saveButton.isEnabled = true
    }
    
    @IBAction func cancelAction(_ sender: Any) {
        dismiss(animated: true)
    }
}
// MARK: TextFieldDelegate
extension NewPlaceViewController: UITextFieldDelegate {
    // скрываем клавиатуру по нажатию на Done
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @objc private func textFieldChanged() {
        if placeName.text?.isEmpty == false {
            saveButton.isEnabled = true
        } else {
            saveButton.isEnabled = false
        }
    }
}


// MARK: Work with images
extension NewPlaceViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func chooseImagePicker(source: UIImagePickerController.SourceType) {
        if UIImagePickerController.isSourceTypeAvailable(source) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.allowsEditing = true
            imagePicker.sourceType = source
            present(imagePicker, animated: true)
        }
    }
    // взяти вибрану картінку і передати її в UIImage в ImageOfPlace
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        placeImage.image = info[.editedImage] as? UIImage
        placeImage.contentMode = .scaleAspectFill
        placeImage.clipsToBounds = true
        imageIsChanged = true
        dismiss(animated: true)
        
    }
}
