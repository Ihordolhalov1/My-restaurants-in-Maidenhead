//
//  MainViewController.swift
//  Maidenhead restaurants
//
//  Created by Ihor Dolhalov on 22.09.2022.
//

import UIKit
import RealmSwift

class MainViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    private let searchController = UISearchController(searchResultsController: nil)
    private var places: Results<Place>!
    private var ascendingSorting = true
    private var filteredPlaces: Results<Place>! //колекция результата пошуку в вигляді масиву
    private var searchBarIsEmpry: Bool {
        guard let text = searchController.searchBar.text else
        { return false}
        return text.isEmpty
    }
    private var isFiltering: Bool {
        return searchController.isActive && !searchBarIsEmpry //true если поисковая строка активирована и не пустая
    }
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var reversedSortingButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        places = realm.objects(Place.self)
        
        //настраиваю searchController
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search"
        navigationItem.searchController = searchController //интегрируем строку поиска в навигейшн бар
        definesPresentationContext = true
    }
    
    // MARK: - Table view data source
    
   
     func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
         if isFiltering {
             return filteredPlaces.count
         }
        return places.count
    }
 
    
     func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! CustomTableViewCell
        var place = Place()
         if isFiltering {  //показувати або масів результата пошуку або увесь масив даних
             place = filteredPlaces[indexPath.row]
         } else {
             place = places[indexPath.row]
         }
        //let place = places[indexPath.row]
        cell.nameLabel.text = place.name
        cell.locationLabel.text = place.location
        cell.typeLabel.text = place.type
        cell.imageOfRestaurant.image = UIImage(data: place.imageData!)
     
        cell.imageOfRestaurant.layer.cornerRadius = 85/20
        cell.imageOfRestaurant.clipsToBounds = true
        
        return cell //заполняем таблицю лейбелами і фото
    }
    
    
    // MARK: - Tableview Delegate
    //снятие выделения ячейки когда не надо
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // отработка свайпа
     func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let place = places[indexPath.row]
        let deleteAction = UITableViewRowAction(style: .default, title: "Delete") { (_, _) in
            StorageManager.deleteObject(place)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
        return [deleteAction]
    }
    
    /*  override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
     return 85 //висота строк
     } */
    
    
     // MARK: - Navigation
     
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
         if segue.identifier == "showDetail" {
             guard let indexPath = tableView.indexPathForSelectedRow else { return }
             let place: Place
             if isFiltering {
                 place = filteredPlaces[indexPath.row]
             } else {
                 place = places[indexPath.row]}
             let newPlaceVC = segue.destination as! NewPlaceViewController
             newPlaceVC.currentPlace = place
         }
     }
        
    @IBAction func unwindSegue (_ segue: UIStoryboardSegue) {
        guard let newPlaceVC = segue.source as? NewPlaceViewController else {return}
        newPlaceVC.savePlace()
  
        tableView.reloadData()
    }
    
    
    @IBAction func sortSelection(_ sender: UISegmentedControl) {
       sorting()
    }
    
    @IBAction func reversedSorting(_ sender: UIBarButtonItem) {
        ascendingSorting.toggle() //меняет значение переменной на противоположный
        if ascendingSorting == true {
            reversedSortingButton.image = UIImage(imageLiteralResourceName: "AZ")
        } else {
            reversedSortingButton.image = UIImage(imageLiteralResourceName: "ZA")
        }
        sorting()
    }
    
    
    private func sorting() {
        
        if segmentedControl.selectedSegmentIndex == 0 {
            places = places.sorted(byKeyPath: "date", ascending: ascendingSorting)
        } else {
            places = places.sorted(byKeyPath: "name", ascending: ascendingSorting)
        }
        
        tableView.reloadData()
    }
}

extension MainViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text!)
    }
    private func filterContentForSearchText (_ searchText:String) {
        filteredPlaces = places.filter("name CONTAINS[c] %@ OR location CONTAINS[c] %@", searchText, searchText) // це з мануала з Realm розділ queries, filtering імя чи локейшн має в будь якому регістрі перемінну %@, та що searchText
        tableView.reloadData()
    }
    
}
