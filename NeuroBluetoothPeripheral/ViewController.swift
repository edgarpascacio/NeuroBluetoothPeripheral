import UIKit
import CoreBluetooth

class PeripheralViewController: UIViewController, UITableViewDataSource {
    
    var dataArray: [String] = []
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            
        // Set the text label for the cell
        cell.textLabel?.text = dataArray[indexPath.row]
            
        return cell
    }
    
    func scrollToBottom(){
        DispatchQueue.main.async {
            let indexPath = IndexPath(row: self.dataArray.count-1, section: 0)
            self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }
    

    @IBOutlet weak var tableView: UITableView!
    // MARK: - Properties
    
    private var peripheralManager: CBPeripheralManager!
    private var transferCharacteristic: CBMutableCharacteristic?
    private var dataToSend: Data?

    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.dataSource = self
        // Set up the peripheral manager
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }

    // MARK: - Peripheral Management
    
    private func setupService() {
        let transferCharacteristicUUID = CBUUID(string: "2EA5E5C0-47D9-4EA9-8E58-2C2E09ACF6F0")
        let transferCharacteristic = CBMutableCharacteristic(type: transferCharacteristicUUID, properties: .write, value: nil, permissions: .writeable)

        let transferServiceUUID = CBUUID(string: "D61F4A28-9C8B-4E78-A72A-6F42119E02BE")
        let transferService = CBMutableService(type: transferServiceUUID, primary: true)
        transferService.characteristics = [transferCharacteristic]

        // Add the notify property to the characteristic
        transferCharacteristic.properties.insert(.notify)

        peripheralManager.add(transferService)
        self.transferCharacteristic = transferCharacteristic
    }
    
    // Respond to write requests and send notifications
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        for request in requests {
            if request.characteristic.uuid == transferCharacteristic?.uuid {
                // Update the value of the characteristic
                transferCharacteristic?.value = request.value

                // Send a notification to the central
                peripheralManager.updateValue(request.value!, for: transferCharacteristic!, onSubscribedCentrals: nil)
            }
        }
    }
    
    

    // MARK: - IBActions

    @IBAction func sendButtonTapped(_ sender: UIButton) {
        let randomNumber = Int.random(in: 1...100)
            let data = Data("\(randomNumber)".utf8)
            let success = peripheralManager.updateValue(data, for: transferCharacteristic!, onSubscribedCentrals: nil)
            if success {
                self.dataArray.append("Sent integer: \(randomNumber)")
                self.tableView.reloadData()
                scrollToBottom()
            } else {
                self.dataArray.append("Failed to send integer: \(randomNumber)")
                self.tableView.reloadData()
                scrollToBottom()
            }
    }
}

// MARK: - CBPeripheralManagerDelegate

extension PeripheralViewController: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if peripheral.state == .poweredOn {
            setupService()
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        self.dataArray.append("Central subscribed to characteristic")
        self.tableView.reloadData()
        scrollToBottom()
    }
    
    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        
    }
}
