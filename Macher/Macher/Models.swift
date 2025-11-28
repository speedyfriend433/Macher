//
//  Models.swift
//  Macher
//
//  Created by 이지안 on 11/28/25.
//

import Foundation
import SwiftUI

// MARK: - models

enum ArchType: String, CaseIterable, Identifiable {
    case arm64 = "ARM64 (iOS)"
    case x86_64 = "x86_64 (PC)"
    var id: String { self.rawValue }
}

enum InstructionCategory {
    case branch, memory, math, returnOp, other
    
    var icon: String {
        switch self {
        case .branch: return "arrow.triangle.branch"
        case .memory: return "memorychip"
        case .math: return "function"
        case .returnOp: return "arrow.uturn.left"
        case .other: return "cpu"
        }
    }
    
    var color: Color {
        switch self {
        case .branch: return .orange
        case .memory: return .blue
        case .math: return .green
        case .returnOp: return .red
        case .other: return .gray
        }
    }
}

struct Instruction: Identifiable {
    let id = UUID()
    let address: String
    let mnemonic: String
    let operands: String
    let bytes: String
    let category: InstructionCategory
}
