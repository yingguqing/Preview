//
//  ProvisionView.swift
//  Preview
//
//  Created by zhouziyuan on 2022/9/26.
//

import SwiftUI

struct ProvisionView: View {
    @Environment(\.presentationMode) var presentationMode
    /// 需要特殊标明的测试设备
    @State var devices: [Device] = Device.userDevices()
    @State var sorting = [KeyPathComparator(\Device.name)]
    @State var selecting = Set<Device.ID>()
    @State var newDevice: Device? = nil
    @State var selectDevice: Device?
    @State var message = ""
    private let xcodeQLPaths = [
        "/Applications/Xcode.app/Contents/Library/QuickLook/DVTProvisioningProfileQuicklookGenerator.qlgenerator",
        "/Applications/Xcode.app/Contents/PlugIns/ProvisoningProfileQuicklookExtension.appex"
    ]

    private var xcodeQLExists: Bool {
        !xcodeQLPaths.filter({ $0.fileExists }).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("添加需要特殊标识的测试设备")
                .padding(.bottom, 10)
            Table(devices, selection: $selecting, sortOrder: $sorting) {
                TableColumn("名称", value: \.name) { entity in
                    Text("\(entity.name)")
                }.width(120)
                TableColumn("UUID", value: \.uuid) { entity in
                    Text(entity.uuid)
                }
            }
            .border()
            .onChange(of: sorting) { devices.sort(using: $0) }
            HStack(spacing: 2) {
                Button("新增", action: {
                    selectDevice = Device()
                    newDevice = selectDevice
                    selecting.removeAll()
                })
                Button("编辑", action: {
                    guard let device = devices.first(where: { selecting.contains($0.id) }) else { return }
                    selectDevice = device
                    selecting.removeAll()
                })
                Button("删除", action: {
                    devices.removeAll(where: { selecting.contains($0.id) })
                    selecting.removeAll()
                })
                Spacer()
            }
            .padding(.top, 5)
            HStack {
                Spacer()
                Text(message).foregroundColor(.red)
                Spacer()
            }
            HStack {
                Spacer()
                Button(action: save) {
                    Text("保存").frame(width: 40, height: 12)
                }
                .niceButton(backgroundColor: .blue)
                Spacer().frame(width: 40)
                Button(action: cancel) {
                    Text("取消").frame(width: 40, height: 12)
                }
                .keyboardShortcut(.cancelAction)
                .niceButton()
                Spacer()
            }
            HStack {
                Text("描述文件优先使用Xcode的Quick Look插件，如有需要，删除Xcode的插件即可。")
                Spacer()
                Button("打开", action: {
                    guard let path = xcodeQLPaths.first(where: { $0.fileExists }) else { return }
                    NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: "")
                })
            }
            .disabled(!xcodeQLExists)
            .padding(.top, 20)
        }
        .padding()
        .frame(width: 600, height: 400)
        .sheet(item: $selectDevice, onDismiss: {
            defer { newDevice = nil }
            guard let newDevice = newDevice, newDevice.isValid, newDevice.isNew else { return }
            devices.append(newDevice)
        }, content: { device in
            DeviceView().environmentObject(device)
        })
    }

    private func cancel() {
        presentationMode.wrappedValue.dismiss()
    }

    private func save() {
        guard Set(devices.map({ $0.uuid })).count == devices.count else {
            message = "有相同UUID的设备"
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.message = ""
            }
            return
        }
        presentationMode.wrappedValue.dismiss()
        Device.save(devices: devices)
    }
}

struct ProvisionView_Previews: PreviewProvider {
    static var previews: some View {
        ProvisionView()
    }
}
