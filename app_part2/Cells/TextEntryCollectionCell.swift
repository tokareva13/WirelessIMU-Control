//
//  TextEntryCollectionCell.swift
//  app_part1
//
//  Created by Ирина Токарева on 14.11.2021.
//

import UIKit
import SnapKit
import MaterialComponents

class TextEntryCollectionCell: UICollectionViewCell {
    
    // MARK: - vars
    private lazy var textField: OutlinedTextField = {
        let textField = OutlinedTextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.setOutlineColor(.textFieldActiveColor, for: [.normal, .editing])
        textField.setOutlineColor(.textFieldInactiveColor, for: .normal)
        textField.outlineWidth = 2
        textField.addTarget(self, action: #selector(textFieldHandler), for: .editingChanged)
        return textField
    }()
    
    private var viewModel: TextEntryVMProtocol?
    
    // MARK: - initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("Method not implemented")
    }
    
    // MARK: - methods
    func configure(viewModel: TextEntryVMProtocol) {
        textField.placeholder = viewModel.placeholder
        textField.text = viewModel.text
        textField.label.text = viewModel.labelText
        textField.setNeedsDisplay()
        self.viewModel = viewModel
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        textField.text = nil
        textField.placeholder = nil
        textField.label.text = " "
    }
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
       
        guard
            let attributes = layoutAttributes.copy() as? UICollectionViewLayoutAttributes,
            let scrollView = superview as? UIScrollView
        else {
            return super.preferredLayoutAttributesFitting(layoutAttributes)
        }
        var targetWidth = scrollView.contentSize.width
        
        if viewModel?.isHalfSized == true {
            targetWidth /= 2
            targetWidth -= 5
        }
        
        let newSize = contentView.systemLayoutSizeFitting(CGSize(width: targetWidth, height: 0))
        
        attributes.frame.size = CGSize(width: targetWidth, height: newSize.height)
        
        return attributes
    }
    
    private func setupUI() {
        contentView.addSubview(textField)
        setupConstraints()
    }
    
    private func setupConstraints() {
        textField.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
    }
    
    // MARK: - actions
    @objc
    private func textFieldHandler() {
        viewModel?.text = textField.text
    }
}
