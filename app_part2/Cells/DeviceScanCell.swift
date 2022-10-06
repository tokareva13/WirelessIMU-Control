//
//  DeviceScanCell.swift
//  app_part2
//
//  Created by Ирина Токарева on 05.12.2021.
//

import UIKit
import SnapKit

class DeviceScanCell: UITableViewCell {
    
    // MARK: - vars
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .black
        return label
    }()
    
    private lazy var stateLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .right
        label.textColor = .lightGray
        return label
    }()
    
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.isHidden = true
        return activityIndicator
    }()
    
    // MARK: - initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - methods
    func configure(viewModel: DeviceCellVM) {
        titleLabel.text = viewModel.deviceName
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        activityIndicator.stopAnimating()
        activityIndicator.isHidden = true
        stateLabel.isHidden = false
    }
    
    private func setupUI() {
        contentView.addSubview(titleLabel)
        contentView.addSubview(stateLabel)
        contentView.addSubview(activityIndicator)
        setupConstraints()
    }
    
    private func setupConstraints() {
        titleLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().inset(16)
            maker.centerY.equalToSuperview()
        }
        activityIndicator.snp.makeConstraints { maker in
            maker.trailing.equalToSuperview().inset(16)
            maker.centerY.equalToSuperview()
        }
        stateLabel.snp.makeConstraints { maker in
            maker.trailing.equalToSuperview().inset(16)
            maker.centerY.equalToSuperview()
        }
        contentView.setNeedsLayout()
    }
    
}
