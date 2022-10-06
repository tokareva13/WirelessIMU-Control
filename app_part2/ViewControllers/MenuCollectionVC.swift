//
//  MenuCollectionVC.swift
//  app_part2
//
//  Created by Ирина Токарева on 05.12.2021.
//

import Foundation
import SnapKit
import Combine
import UIKit

class MenuCollectionVC: UIViewController {
    
    // MARK: - vars
    private lazy var collectionViewLayout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        return layout
    }()
    
    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.contentInset = .init(
            top: .zero,
            left: Constants.mediumOffset,
            bottom: 0,
            right: Constants.mediumOffset
        )
        return collectionView
    }()
    
    private var cancellables: Set<AnyCancellable> = []
    private var viewModel: MenuVMProtocol
    
    // MARK: - initialization
    init(viewModel: MenuVMProtocol) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        self.viewModel.view = self
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - viewController liveCycle
    override func loadView() {
        super.loadView()
        setupUI()
    }
    
    // MARK: - methods
    private func setupUI() {
        title = "Меню"
        view.backgroundColor = .white
        view.addSubview(collectionView)
        registerCells()
        setupConstraints()
    }
    
    private func setupConstraints() {
        collectionView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
        view.setNeedsLayout()
    }
    
    private func registerCells() {
        let cellTypes: [UICollectionViewCell.Type] = [
            MenuCollectionCell.self
        ]
        
        cellTypes.forEach {
            collectionView.register($0, forCellWithReuseIdentifier: $0.reuseIdentificator)
        }
    }
    
    private func bindViews() {
        viewModel.itemsPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.collectionView.reloadData()
            }
            .store(in: &cancellables)
    }
}

// MARK: - UICollectionViewDelegate
extension MenuCollectionVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        viewModel.didSelectItem(at: indexPath.item)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let spacing = self.collectionViewLayout.minimumLineSpacing
        let width = (view.frame.size.width - 2 * Constants.mediumOffset - spacing)
        return CGSize(width: width, height: 0.9 * width)
    }
}

// MARK: - UICollectionViewDataSource
extension MenuCollectionVC: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MenuCollectionCell.reuseIdentificator, for: indexPath) as! MenuCollectionCell
        cell.configure(viewModel: viewModel.items[indexPath.item])
        return cell
    }
}

// MARK: - constants
private extension MenuCollectionVC {
    struct Constants {
        static let mediumOffset: CGFloat = 16
        static let buttonHeight: CGFloat = 50
    }
}
