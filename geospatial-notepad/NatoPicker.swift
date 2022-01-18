import UIKit

protocol SelectedSymbolDelegate: AnyObject {
    func setSymbol(_ symbol: UIImage)
}

/*
  Since it's a text list, it's not worth setting up the infra to load in json
 */
let unitList = ["Airborne Artillery", "Airborne Infantry", "Antitank", "Armor", "Artillery", "Attack, Fixed Wing", "Attack Helicopter", "Cavalry", "Drone", "Engineering", "Fixed Wing", "Fuel", "Helicopter", "Hospital", "Infantry", "Mech Cavalry", "Mech Infantry", "Mountain Infantry", "Rocket Artillery", "Self Propelled Artillery", "Special Forces", "Tank Destroyer"]

class NatoPicker: UITableViewController {
    weak var delegate: SelectedSymbolDelegate?
    var symbols = [SymbolData]()
    
    struct SymbolData {
        let unitName: String
        let unitDescription: String
        let isFriendly: Bool
        let unitImage: UIImage
    }
    
    // determines which unit an icon is from
    private func unitMap(_ unit: String, _ isBlufor: Bool) -> String {
        if (isBlufor) {
            if unit.contains("Airborne") {
                return "82nd Airborne Division"
            } else if unit.contains("Mech") || unit.contains("Cavalry") || unit.contains("Armor") {
                return "1st Armored Division"
            } else if unit.contains("Special") {
                return "10th Special Forces Group"
            } else {
                return "2nd Infantry Division"
            }
        } else {
            if unit.contains("Airborne") {
                return "76th Guards Air Assault Division"
            } else if unit.contains("Mech") || unit.contains("Cavalry") || unit.contains("Armor") {
                return "4th Guards Tank Division"
            } else if unit.contains("Special") {
                return "KSSO"
            } else {
                return "42nd Guards Motor Rifle Division"
            }
        }
    }
    
    private func fetchUnits() {
        // load friendly units
        for unit in unitList {
            let unitImageLink = "Nato_Friendly/" +  unit.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: ",", with: "").lowercased()
            let unitDescriptor = unitMap(unit, true)
            let unitImage: UIImage = UIImage(named: unitImageLink)!;
            let unitSymbol = SymbolData(unitName: unit, unitDescription: unitDescriptor, isFriendly: true, unitImage: unitImage)
            symbols.append(unitSymbol)
        }
        
        // load enemy units
        for unit in unitList {
            let unitImageLink = "Nato_Hostile/" +  unit.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: ",", with: "").lowercased()
            let unitDescriptor = unitMap(unit, false)
            let unitImage: UIImage = UIImage(named: unitImageLink)!;
            let unitSymbol = SymbolData(unitName: unit, unitDescription: unitDescriptor, isFriendly: true, unitImage: unitImage)
            symbols.append(unitSymbol)
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let symbol = symbols[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "natoIdentifier") as! NatoPickerCell
        cell.unitName.text = symbol.unitName
        cell.unitDescription.text = symbol.unitDescription
        cell.unitImage.image = symbol.unitImage
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.delegate?.setSymbol(symbols[indexPath.row].unitImage)
        dismiss(animated: true, completion: nil);
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return symbols.count
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50.0
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        self.dismiss(animated: true, completion: nil)
        if segue.identifier == "detailSegue" {
            let index = tableView.indexPathForSelectedRow?.row
            if index == nil {
                return
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchUnits()
        self.tableView.reloadData();
    }
}

