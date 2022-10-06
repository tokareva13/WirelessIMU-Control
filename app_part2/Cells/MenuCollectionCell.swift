//
//  MenuCollectionCell.swift
//  app_part2
//
//  Created by Ирина Токарева on 05.12.2021.
//

import Foundation
import UIKit

class MenuCollectionCell: UICollectionViewCell {
    
    // MARK: - vars
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .clear
        return imageView
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 2
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(viewModel: MenuItemVMProtocol) {
        imageView.image = viewModel.image
        titleLabel.text = viewModel.title
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        titleLabel.text = nil
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.layer.shadowPath = UIBezierPath(rect: self.bounds).cgPath
    }
    
    private func setupUI() {
        contentView.backgroundColor = .white
        contentView.layer.shadowColor = UIColor.black.cgColor
        contentView.layer.shadowRadius = 8
        contentView.layer.shadowOpacity = 0.12
        contentView.layer.shadowOffset = .zero
        contentView.layer.cornerRadius = 8.0
        contentView.addSubview(imageView)
        contentView.addSubview(titleLabel)
        setupConstraints()
    }
    
    private func setupConstraints() {
        imageView.snp.makeConstraints { maker in
            maker.leading.trailing.top.equalToSuperview()
            maker.height.equalTo(imageView.snp.width).multipliedBy(0.6)
        }
        titleLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(8)
            maker.top.equalTo(imageView.snp.bottom).offset(4)
            maker.bottom.equalToSuperview().inset(4)
        }
    }
}
