//
//  Device.swift
//  Preview
//
//  Created by zhouziyuan on 2022/9/26.
//

import SwiftUI

class Device: ObservableObject, Identifiable {
    @Published var name: String
    @Published var uuid: String

    var id: String {
        return uuid
    }

    var history: Device?
    
    var isNew:Bool = false
    
    var isValid:Bool {
        return !name.isEmpty && !uuid.isEmpty
    }

    init(name: String = "", uuid: String = "") {
        self.name = name
        self.uuid = uuid
        self.isNew = name.isEmpty && uuid.isEmpty
    }

    func setHistory() {
        self.history = Device(name: name, uuid: uuid)
    }

    func reloadHistory() {
        guard let history = history else { return }
        self.name = history.name
        self.uuid = history.uuid
    }
}

extension Device {
    class func userDevices() -> [Device] {
        let divices = UserDefaults.share?.load(key: .Provision) as? [String: String] ?? [:]
        return divices.map({ Device(name: $0.1, uuid: $0.0) })
    }
    
    class func save(devices:[Device]) {
        let dic = Dictionary(uniqueKeysWithValues: devices.map({ ($0.uuid, $0.name) }))
        UserDefaults.share?.save(key: .Provision, value: dic)
    }
}

extension Device: Equatable {
    static func ==(lhs: Device, rhs: Device) -> Bool {
        return lhs.uuid == rhs.uuid
    }
}

extension Device: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }
}
