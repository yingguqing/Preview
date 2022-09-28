//
//  DeviceView.swift
//  Preview
//
//  Created by zhouziyuan on 2022/9/26.
//

import SwiftUI

struct DeviceView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var device: Device
    @State var message: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("设备名称")
            TextField("设备名称", text: $device.name) { _ in
                message = ""
            }

            Text("设备id")
                .padding(.top, 20)
            TextField("UUID", text: $device.uuid) { _ in
                message = ""
            }
            Text(message)
                .colorMultiply(.red)
            HStack {
                Spacer()
                Button(action: save) {
                    Text("保存").frame(width: 40, height: 12)
                }
                .niceButton(backgroundColor: .blue)
                Button("取消", action: cancel)
                    .frame(width: 0)
                    .hidden()
                    .keyboardShortcut(.cancelAction)
                Spacer()
            }
            .padding(.top, 40)
        }
        .onAppear {
            device.setHistory()
        }
        .frame(width: 600, height: 200)
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
        presentationMode.wrappedValue.dismiss()
    }
}

struct DeviceView_Previews: PreviewProvider {
    static var previews: some View {
        DeviceView().environmentObject(Device(name: "影孤清", uuid: "00008030-001E0DD43AFA802E"))
    }
}
