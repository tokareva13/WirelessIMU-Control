//
//  TextEntryVM.swift
//  app_part1
//
//  Created by Ирина Токарева on 14.11.2021.
//

import Foundation

protocol TextEntryVMProtocol {
    var labelText: String { get }
    var placeholder: String { get }
    var text: String? { get set }
    var isHalfSized: Bool { get }
    var checkableText: String? { get }
    var floatValue: Float? { get }
}

class TextEntryVM: TextEntryVMProtocol {
    
    // MARK: - vars
    let labelText: String
    let placeholder: String
    let isHalfSized: Bool
    var text: String?
    
    var checkableText: String? {
        guard
            let text = text,
            !text.isEmpty
        else {
            return nil
        }
        return text
    }
    
    var floatValue: Float? {
        guard let text = checkableText else {
            return nil
        }
        return Float(text)
    }
    
    // MARK: - initialization
    init(labelText: String, placeholder: String, text: String? = nil, isHalfSized: Bool = false) {
        self.labelText = labelText
        self.placeholder = placeholder
        self.text = text
        self.isHalfSized = isHalfSized
    }
    
}
