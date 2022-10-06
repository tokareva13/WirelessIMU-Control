//
//  PacientInfoEditorVC.swift
//  app_part1
//
//  Created by Ирина Токарева on 14.11.2021.
//

import UIKit
import SnapKit
import Combine
import RxSwift
import MBProgressHUD

class PacientInfoEditorVC: UIViewController {
   
    // MARK: - vars
    private lazy var collectionViewLayout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.estimatedItemSize = CGSize(width: 100, height: 60)
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
            bottom: 2 * Constants.mediumOffset + Constants.buttonHeight,
            right: Constants.mediumOffset
        )
        return collectionView
    }()
    
    private lazy var saveButton: GradButton = {
        let button = GradButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Сохранить", for: .normal)
        button.addTarget(self, action: #selector(saveHandler), for: .touchUpInside)
        return button
    }()
    
    private let viewModel: PacientInfoEntryVMProtocol
    private var cancellables: Set<AnyCancellable> = []
    private let disposeBag = DisposeBag()
    
    // MARK: - initialization
    init(viewModel: PacientInfoEntryVMProtocol) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - viewController livecycle
    override func loadView() {
        super.loadView()
        setupUI()
    }
    
    // MARK: - methods
    private func setupUI() {
        title = "Анкета пациента"
        view.backgroundColor = .white
        view.addSubview(collectionView)
        view.addSubview(saveButton)
        registerCells()
        setupConstraints()
        setupNotifications()
        bindViews()
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onKeyboardFrameWillChangeNotificationReceived(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
    }
    
    private func setupConstraints() {
        collectionView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
        saveButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(Constants.mediumOffset)
            maker.height.equalTo(Constants.buttonHeight)
            maker.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(Constants.mediumOffset)
        }
        view.layoutIfNeeded()
    }
    
    private func registerCells() {
        let cellTypes: [UICollectionViewCell.Type] = [
            ImagePickerCollectionCell.self,
            TextEntryCollectionCell.self
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
    
    @objc
    private func saveHandler() {
        view.endEditing(true)
        
        let hud = MBProgressHUD.showAdded(to: view, animated: true)
        
        viewModel.saveData()
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak hud] in
                    hud?.hide(animated: true)
                },
                onFailure: { [weak hud] error in
                    
                    hud?.detailsLabel.text = error.localizedDescription
                    hud?.hide(animated: true, afterDelay: 3.0)
                }
            )
            .disposed(by: disposeBag)
    }
}

// MARK: - UICollectionViewDataSource
extension PacientInfoEditorVC: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let model = viewModel.items[indexPath.item]
        
        switch model {
        case let model as ImageSelectionVMProtocol:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ImagePickerCollectionCell.reuseIdentificator, for: indexPath)
            guard let cell = cell as? ImagePickerCollectionCell else {
                return cell
            }
            cell.delegate = self
            cell.configure(viewModel: model)
            return cell
        case let model as TextEntryVMProtocol:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TextEntryCollectionCell.reuseIdentificator, for: indexPath)
            guard let cell = cell as? TextEntryCollectionCell else {
                return cell
            }
            cell.configure(viewModel: model)
            return cell
        default:
            break
        }
        
        fatalError()
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension PacientInfoEditorVC: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.contentSize.width, height: 60)
    }
}

// MARK: - UICollectionViewDataSource
extension PacientInfoEditorVC: ImagePickerCollectionCellDelegate {
    
    func imagePickerCollectionCell(_ sender: ImagePickerCollectionCell, needsToPresent viewController: UIViewController) {
        present(viewController, animated: true)
    }
}

extension PacientInfoEditorVC {
    
    @objc
    private func onKeyboardFrameWillChangeNotificationReceived(_ notification: Notification)
    {
        guard
            let userInfo = notification.userInfo,
            let keyboardFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
        else {
            return
        }

        let keyboardFrameInView = view.convert(keyboardFrame, from: nil)
        let safeAreaFrame = view.safeAreaLayoutGuide.layoutFrame.insetBy(dx: 0, dy: -additionalSafeAreaInsets.bottom)
        let intersection = safeAreaFrame.intersection(keyboardFrameInView)

        let keyboardAnimationDuration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey]
        let animationDuration: TimeInterval = (keyboardAnimationDuration as? NSNumber)?.doubleValue ?? 0
        let animationCurveRawNSN = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber
        let animationCurveRaw = animationCurveRawNSN?.uintValue ?? UIView.AnimationOptions.curveEaseInOut.rawValue
        let animationCurve = UIView.AnimationOptions(rawValue: animationCurveRaw)

        UIView.animate(withDuration: animationDuration,
                       delay: 0,
                       options: animationCurve,
                       animations: {
            self.additionalSafeAreaInsets.bottom = intersection.height
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
}

// MARK: - constants
private extension PacientInfoEditorVC {
    struct Constants {
        static let mediumOffset: CGFloat = 16
        static let buttonHeight: CGFloat = 50
    }
}
