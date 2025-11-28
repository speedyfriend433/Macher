//
//  ContentView.swift
//  Macher
//
//  Created by 이지안 on 11/28/25.
//

import SwiftUI

// MARK: - view

struct ContentView: View {
    @StateObject var engine = DisassemblerEngine()
    @State private var inputHex: String = "C0 03 5F D6"
    @State private var selectedArch: ArchType = .arm64
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    Text("Disasm")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                    Spacer()
                    Menu {
                        Section("ARM64 Patterns") {
                            Button("Return (RET)") { loadPreset("C0 03 5F D6", .arm64) }
                            Button("Infinite Loop (B .)") { loadPreset("00 00 00 14", .arm64) }
                            Button("MOV X0, #1") { loadPreset("20 00 80 D2", .arm64) }
                            Button("NOP Sled") { loadPreset("1F 20 03 D5 1F 20 03 D5", .arm64) }
                        }
                        Section("x86_64 Patterns") {
                            Button("Return (RET)") { loadPreset("C3", .x86_64) }
                            Button("NOP Sled") { loadPreset("90 90 90 90", .x86_64) }
                            Button("INT 3 (Breakpoint)") { loadPreset("CC", .x86_64) }
                        }
                        Section("Actions") {
                            Button("Clear Input", role: .destructive) { inputHex = "" }
                        }
                    } label: {
                        Image(systemName: "book.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                            .padding(8)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(Color.white)
                
                ScrollView {
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Label("HEX BYTES", systemImage: "text.alignleft")
                                    .font(.caption).fontWeight(.bold).foregroundColor(.gray)
                                Spacer()
                                Picker("Arch", selection: $selectedArch) {
                                    ForEach(ArchType.allCases) { arch in
                                        Text(arch.rawValue).tag(arch)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .frame(width: 180)
                            }
                            
                            ZStack(alignment: .topLeading) {
                                if inputHex.isEmpty {
                                    Text("Paste hex here...")
                                        .foregroundColor(.gray.opacity(0.5))
                                        .padding(8)
                                }
                                TextEditor(text: $inputHex)
                                    .focused($isInputFocused)
                                    .font(.system(.body, design: .monospaced))
                                    .frame(minHeight: 100)
                                    .scrollContentBackground(.hidden)
                                    .background(Color(uiColor: .secondarySystemBackground))
                                    .cornerRadius(12)
                                    .toolbar {
                                        ToolbarItemGroup(placement: .keyboard) {
                                            Spacer()
                                            Button("Clear") { inputHex = "" }
                                            Button("Done") { isInputFocused = false }
                                                .fontWeight(.bold)
                                        }
                                    }
                            }
                            
                            Button(action: {
                                isInputFocused = false
                                engine.disassemble(hexString: inputHex, arch: selectedArch)
                            }) {
                                HStack {
                                    Image(systemName: "cpu")
                                    Text("Disassemble")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(14)
                                .shadow(color: .blue.opacity(0.3), radius: 5, x: 0, y: 3)
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
                        
                        if let error = engine.errorMessage {
                            Text(error)
                                .foregroundColor(.red)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(10)
                        }
                        
                        if !engine.instructions.isEmpty {
                            LazyVStack(spacing: 12) {
                                ForEach(engine.instructions) { ins in
                                    InstructionRow(ins: ins)
                                        .contextMenu {
                                            Button {
                                                UIPasteboard.general.string = "\(ins.mnemonic) \(ins.operands)"
                                            } label: {
                                                Label("Copy Assembly", systemImage: "doc.on.doc")
                                            }
                                            Button {
                                                UIPasteboard.general.string = ins.address
                                            } label: {
                                                Label("Copy Address", systemImage: "location")
                                            }
                                        }
                                }
                            }
                        }
                        Color.clear.frame(height: 50)
                    }
                    .padding(20)
                }
            }
        }
    }
    
    func loadPreset(_ hex: String, _ arch: ArchType) {
        self.selectedArch = arch
        self.inputHex = hex
        engine.disassemble(hexString: hex, arch: arch)
    }
}

// MARK: - row

struct InstructionRow: View {
    let ins: Instruction
    
    var body: some View {
        HStack(spacing: 15) {
            Text(ins.address.replacingOccurrences(of: "0x", with: ""))
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(.gray)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(ins.mnemonic)
                        .font(.system(size: 17, weight: .black, design: .monospaced))
                        .foregroundColor(Color.primary)
                    
                    Text(ins.operands)
                        .font(.system(size: 17, weight: .regular, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                
                Text(ins.bytes)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.gray.opacity(0.6))
            }
            
            Spacer()
            
            Image(systemName: ins.category.icon)
                .foregroundColor(ins.category.color)
                .padding(8)
                .background(ins.category.color.opacity(0.1))
                .clipShape(Circle())
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
    }
}

// MARK: - UI ext
struct SoftCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
    }
}

extension View {
    func softCard() -> some View {
        self.modifier(SoftCardStyle())
    }
}
