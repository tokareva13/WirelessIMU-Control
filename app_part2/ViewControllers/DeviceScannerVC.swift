//
//  DeviceScannerVC.swift
//  app_part2
//
//  Created by Ирина Токарева on 05.12.2021.
//

import Foundation
import SnapKit
import Combine
import UIKit
import RxSwift
import RxDataSources

class DeviceScannerVC: UIViewController {
    
    // MARK: - vars
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.tableHeaderView = titleLabel
        tableView.tableFooterView = footerLabel
        tableView.delegate = self
        return tableView
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 3
        label.autoresizingMask = [.flexibleWidth]
        label.font = .systemFont(ofSize: 22, weight: .semibold)
        label.text = "Включите Bluetooth на своем устройстве и выберете имя датчика"
        label.setMargins(margin: 25)
        return label
    }()
    
    private lazy var footerLabel: UILabel = {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 60))
        label.numberOfLines = 3
        label.autoresizingMask = [.flexibleWidth]
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.textColor = .lightGray
        label.text = "Идет поиск устройств"
        label.textAlignment = .center
        return label
    }()
    
    private var viewModel: DeviceScanVMProtocol
    private var cancellables = Set<AnyCancellable>()
    private let disposeBag = DisposeBag()
    
    // MARK: - initialization
    init(viewModel: DeviceScanVMProtocol) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        self.viewModel.view = self
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - viewController liveCycle
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        titleLabel.preferredMaxLayoutWidth = tableView.contentSize.width
        titleLabel.sizeToFit()
        tableView.tableHeaderView = titleLabel
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel.startScanning()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        viewModel.stopScanning()
    }
    
    override func loadView() {
        super.loadView()
        setupUI()
    }
    
    // MARK: - methods
    private func setupUI() {
        view.addSubview(tableView)
        setupConstraints()
        registerCells()
        bindViews()
    }
    
    private func setupConstraints() {
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
        view.setNeedsLayout()
    }
    
    private func bindViews() {
        viewModel.itemsRelay
            .observe(on: MainScheduler.instance)
            .subscribe(on: MainScheduler.instance)
            .compactMap { sections -> Bool? in
                sections.first?.items.isEmpty
            }
            .map { !$0 }
            .bind(to: footerLabel.rx.isHidden)
            .disposed(by: disposeBag)
        
        configureDataSource()
    }
    
    private func configureDataSource() {
        let dataSource = RxTableViewSectionedAnimatedDataSource<DevicesSection>(configureCell: configureCell)
        
        dataSource.titleForHeaderInSection = { dataSource, index in
            return dataSource.sectionModels[index].header
        }
        
        dataSource.animationConfiguration = .init(
            insertAnimation: .top,
            reloadAnimation: .fade,
            deleteAnimation: .fade
        )
        
        viewModel.itemsRelay
            .observe(on: MainScheduler.instance)
            .subscribe(on: MainScheduler.instance)
            .bind(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
    }
    
    private func configureCell(
        dataSource: TableViewSectionedDataSource<DevicesSection>,
        tableView: UITableView,
        indexPath: IndexPath,
        item: DeviceCellVM
    ) -> UITableViewCell {
        guard
            let cell = tableView.dequeueReusableCell(withIdentifier: DeviceScanCell.reuseIdentificator, for: indexPath) as? DeviceScanCell
        else {
            fatalError()
        }
        cell.configure(viewModel: item)
        return cell
    }
    
    private func registerCells() {
        let cellTypes: [UITableViewCell.Type] = [
            DeviceScanCell.self
        ]
        
        cellTypes.forEach {
            tableView.register($0, forCellReuseIdentifier: $0.reuseIdentificator)
        }
    }
}

extension DeviceScannerVC: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        viewModel.didSelectItem(at: indexPath.row)
    }
}
