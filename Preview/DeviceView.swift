//
//  DeviceView.swift
//  Preview
//
//  Created by zhouziyuan on 2022/9/26.
//

import SwiftUI

struct DeviceView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var deviceManager: DeviceManager
    @StateObject var device: Device
    @State var message: String = ""

    var body: some View {
        VStack(alignment: .leading) {
            Text("设备名称")
            TextField("设备名称", text: $device.name) { _ in
                message = ""
            }

            Text("设备id")
                .padding(.top, 10)
            TextField("UUID", text: $device.uuid) { _ in
                message = ""
            }
            Text(message)
                .colorMultiply(.red)
            HStack {
                Button(action: save) {
                    Text("保存").frame(width: 80, height: 12)
                }
                .niceButton(backgroundColor: .blue)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 10)
        }
        .onAppear {
            device.setHistory()
        }
        .frame(width: 400)
        .padding()
    }

    private func cancel() {
        device.reloadHistory()
        presentationMode.wrappedValue.dismiss()
    }

    private func save() {
        guard !device.name.isEmpty else {
            message = "设备名称不能为空"
            return
        }
        guard !device.uuid.isEmpty else {
            message = "设备UUID不能为空"
            return
        }
        deviceManager.devices.append(device)
        presentationMode.wrappedValue.dismiss()
    }
}

