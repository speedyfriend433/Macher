//
//  Disassembler.swift
//  Macher
//
//  Created by 이지안 on 11/28/25.
//

import SwiftUI
import Combine
import Capstone

class DisassemblerEngine: ObservableObject {
    @Published var instructions: [Instruction] = []
    @Published var errorMessage: String?
    
    func disassemble(hexString: String, arch: ArchType) {
        let cleanHex = hexString
            .replacingOccurrences(of: "0x", with: "")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "\n", with: "")
        
        guard let data = hexStringToBytes(cleanHex) else {
            self.errorMessage = "Invalid Hex String"
            self.instructions = []
            return
        }
        
        self.errorMessage = nil
        var result: [Instruction] = []
        
        do {
            let csArch: Architecture = (arch == .arm64) ? .arm64 : .x86
            let csMode: Mode = (arch == .arm64)
                ? [Mode.arm.arm]
                : [Mode.bits.b64]
            
            let capstone = try Capstone(arch: csArch, mode: csMode)
            try capstone.set(option: .detail(value: true))
            let insns = try capstone.disassemble(code: data, address: 0x1000)
            
            for ins in insns {
                let byteStr = ins.bytes.map { String(format: "%02X", $0) }.joined(separator: " ")
                let mnemonic = ins.mnemonic.lowercased()
                let category: InstructionCategory
                
                if ["b", "bl", "br", "blr", "cbz", "cbnz", "tbz", "jmp", "call", "je", "jne"].contains(where: { mnemonic.hasPrefix($0) }) {
                    category = .branch
                } else if ["ret", "retn"].contains(mnemonic) {
                    category = .returnOp
                } else if ["ldr", "str", "ldp", "stp", "mov", "lea"].contains(where: { mnemonic.hasPrefix($0) }) {
                    category = .memory
                } else if ["add", "sub", "mul", "div", "cmp", "xor", "and", "or"].contains(where: { mnemonic.hasPrefix($0) }) {
                    category = .math
                } else {
                    category = .other
                }
                
                let i = Instruction(
                    address: String(format: "0x%X", ins.address),
                    mnemonic: ins.mnemonic,
                    operands: ins.operandsString,
                    bytes: byteStr,
                    category: category
                )
                result.append(i)
            }
            
            self.instructions = result
            
        } catch {
            self.errorMessage = "Error: \(error.localizedDescription)"
        }
    }
    
    private func hexStringToBytes(_ string: String) -> Data? {
        var data = Data()
        var temp = ""
        for char in string {
            temp.append(char)
            if temp.count == 2 {
                if let byte = UInt8(temp, radix: 16) {
                    data.append(byte)
                } else { return nil }
                temp = ""
            }
        }
        return data
    }
}
