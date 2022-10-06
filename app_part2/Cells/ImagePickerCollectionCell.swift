//
//  ImagePickerCollectionCell.swift
//  app_part2
//
//  Created by Ирина Токарева on 28.11.2021.
//

import UIKit
import Material
import SnapKit

protocol ImagePickerCollectionCellDelegate: AnyObject {
    func imagePickerCollectionCell(_ sender: ImagePickerCollectionCell, needsToPresent viewController: UIViewController)
}

class ImagePickerCollectionCell: UICollectionViewCell {
    
    // MARK: - vars
    weak var delegate: ImagePickerCollectionCellDelegate? = nil
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = Constants.titleLabelFont
        label.textAlignment = .left
        return label
    }()
    
    private lazy var iconButton: IconButton = {
        let button = IconButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.image = Icon.add
        button.addTarget(self, action: #selector(addHandler), for: .touchUpInside)
        return button
    }()
    
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .lightGrayColor
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = Constants.addButtonSize.width / 2.0
        return imageView
    }()
    
    private var viewModel: ImageSelectionVMProtocol?
    
    // MARK: - initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - methods
    func configure(viewModel: ImageSelectionVMProtocol) {
        titleLabel.text = viewModel.title
        imageView.image = viewModel.image
        self.viewModel = viewModel
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        viewModel = nil
        imageView.image = nil
        titleLabel.text = ""
    }
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
       
        guard
            let attributes = layoutAttributes.copy() as? UICollectionViewLayoutAttributes,
            let scrollView = superview as? UIScrollView
        else {
            return super.preferredLayoutAttributesFitting(layoutAttributes)
        }
        let targetWidth = scrollView.contentSize.width
        let newSize = contentView.systemLayoutSizeFitting(CGSize(width: targetWidth, height: 0))
        attributes.frame.size = CGSize(width: targetWidth, height: newSize.height)
        return attributes
    }
    
    private func setupUI() {
        contentView.addSubview(titleLabel)
        contentView.addSubview(imageView)
        contentView.addSubview(iconButton)
        setupConstraints()
    }
    
    private func setupConstraints(){
        titleLabel.snp.makeConstraints { maker in
            maker.leading.centerY.equalToSuperview()
        }
        iconButton.snp.makeConstraints { maker in
            maker.top.trailing.bottom.equalToSuperview()
            maker.leading.equalTo(titleLabel.snp.trailing).offset(Constants.mediumOffset)
            maker.size.equalTo(Constants.addButtonSize)
        }
        imageView.snp.makeConstraints { maker in
            maker.top.trailing.bottom.equalToSuperview()
            maker.leading.equalTo(titleLabel.snp.trailing).offset(Constants.mediumOffset)
            maker.size.equalTo(Constants.addButtonSize)
        }
        layoutIfNeeded()
    }
    
    // MARK: - actions
    @objc
    private func addHandler() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        delegate?.imagePickerCollectionCell(self, needsToPresent: imagePicker)
    }
}

// MARK: - UIImagePickerControllerDelegate
extension ImagePickerCollectionCell: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
    ) {
        let image = info[.originalImage] as? UIImage
        imageView.image = image
        viewModel?.image = image
        picker.dismiss(animated: true)
    }
}

// MARK: - constants
private extension ImagePickerCollectionCell {
    struct Constants {
        static let titleLabelFont = UIFont.systemFont(ofSize: 22, weight: .semibold)
        static let mediumOffset: CGFloat = 16
        static let addButtonSize = CGSize(width: 79, height: 79)
    }
}
