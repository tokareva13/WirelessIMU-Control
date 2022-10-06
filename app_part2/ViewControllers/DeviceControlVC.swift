//
//  DeviceControlVC.swift
//  app_part2
//
//  Created by Ирина Токарева on 12.12.2021.
//

import Foundation
import UIKit
import Material
import SnapKit
import ScrollableGraphView
import RxSwift
import MBProgressHUD
import StepsProcessor

class DeviceControlVC: UIViewController {
    
    // MARK: - Types
    
    enum AxisDisplayType {
        case x
        case y
        case z
    }
    
    enum DisplayType {
        case gyro
        case accel
    }
    
    // MARK: - vars
    private let viewModel: DeviceControlVMProtocol
    
    private var hud: MBProgressHUD? = nil
    
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = 8
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        return stackView
    }()
    
    private lazy var verticalUnitLabel: UILabel = {
        let label = UILabel()
        
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .lightGray
        label.transform = .init(rotationAngle: -.pi / 2)
        label.text = "Акселерометр X (g)"
        
        return label
    }()
    
    private lazy var horizontalUnitLabel: UILabel = {
        let label = UILabel()
        
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .lightGray
        label.text = "Номер измерения (семпл)"
        
        return label
    }()
    
    private lazy var referenceLines: ReferenceLines = {
        let referenceLines = ReferenceLines()
        referenceLines.referenceLineNumberOfDecimalPlaces = 2
        referenceLines.referenceLineColor = .textFieldInactiveColor
        referenceLines.dataPointLabelColor = .textFieldInactiveColor
        return referenceLines
    }()
    
    private lazy var graphView: GraphView = {
        
        let graphView = GraphView(frame: .zero, dataSource: self)
        graphView.translatesAutoresizingMaskIntoConstraints = false
        graphView.rangeMin = -2.0
        graphView.rangeMax = 2.0
        graphView.shouldAnimateOnAdapt = false
        graphView.shouldAnimateOnAdapt = false
        graphView.addReferenceLines(referenceLines: referenceLines)
        graphView.borderWidthPreset = .border1
        graphView.cornerRadiusPreset = .cornerRadius1
        graphView.borderColor = .black.withAlphaComponent(0.2)
        graphView.backgroundFillColor = .clear
        graphView.backgroundColor = .white
        graphView.dataPointSpacing = 100
        graphView.maximumZoomScale = 4
        return graphView
    }()
    
    private lazy var processButon: GradButton = {
        let button = GradButton()
        
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Обработать данные", for: .normal)
        
        return button
    }()
    
    private let disposeBag = DisposeBag()
    
    private var currentAxisType: AxisDisplayType = .x {
        didSet {
            updateGraphView()
        }
    }
    
    private var currentDataType: DisplayType = .accel {
        didSet {
            updateGraphView()
        }
    }
    
    // MARK: - initialization
    init(viewModel: DeviceControlVMProtocol) {
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        isModalInPresentation = true
        viewModel.viewDidAppear()
        hud = MBProgressHUD.showAdded(to: view, animated: true)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        viewModel.viewDidDisappear()
    }
    
    // MARK: - methods
    private func setupUI() {
        title = "Управление"
        view.backgroundColor = .systemGroupedBackground
        [
            "ic_start",
            "ic_stop",
            "ic_calibrate",
            "ic_file"
        ].enumerated().forEach {
            let button = makeButton(image: $0.element, tag: $0.offset)
            stackView.addArrangedSubview(button)
        }
        view.addSubview(stackView)
        view.addSubview(graphView)
        view.addSubview(verticalUnitLabel)
        view.addSubview(horizontalUnitLabel)
        view.addSubview(processButon)
        
        setupConstraints()
        setupBindings()
    }
    
    private func setupConstraints() {
        stackView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(16)
            maker.top.equalTo(view.safeAreaLayoutGuide.snp.top).inset(16)
            maker.height.equalTo(stackView.snp.width).multipliedBy(0.25).offset(-8.0)
        }
        graphView.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().inset(35)
            maker.trailing.equalToSuperview().inset(16)
            maker.top.equalTo(stackView.snp.bottom).offset(16)
            maker.height.equalTo(300)
        }
        verticalUnitLabel.snp.makeConstraints { maker in
            maker.centerY.equalTo(graphView)
            maker.centerX.equalTo(view.snp.leading).offset(verticalUnitLabel.font.lineHeight)
        }
        horizontalUnitLabel.snp.makeConstraints { maker in
            maker.centerX.equalTo(graphView)
            maker.top.equalTo(graphView.snp.bottom).offset(8.0)
        }
        processButon.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(16)
            maker.top.equalTo(horizontalUnitLabel.snp.bottom).offset(16)
            maker.height.equalTo(60)
        }
        view.setNeedsLayout()
    }
    
    private func setupBindings() {
        let plot = LinePlot(identifier: "ax")
        plot.lineColor = .textFieldActiveColor
        graphView.addPlot(plot: plot)
        
        processButon.rx
            .controlEvent(.touchUpInside)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] in
                    guard let self = self else {
                        return
                    }
                    self.hud = MBProgressHUD.showAdded(to: self.view, animated: true)
                }
            )
            .disposed(by: disposeBag)
        
        processButon.rx
            .controlEvent(.touchUpInside)
            .flatMap { [weak self] _ -> Single<StepsInfo> in
                guard let self = self else {
                    throw NSError(domain: "Unexcepted deallocation", code: -1)
                }
                return self.processData()
            }
            .map { info -> Result<StepsInfo, Error> in
               return .success(info)
            }
            .catch {
                Single.just(Result<StepsInfo, Error>.failure($0))
                    .asObservable()
            }
            .observe(on: MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] item in
                    self?.hud?.hide(animated: true)
                    let message: String
                    switch item {
                    case let .success(info):
                        let l = String(format: "%.3f м", info.averageLength)
                        let h = String(format: "%.3f м", info.averageHeight)
                        message = "Средняя длина шага: \(l)\nСредняя высота шага: \(h)\nКоллличество шагов: \(Int(info.stepsCount))"
                    case let .failure(error):
                        message = error.localizedDescription
                    }
                    let alert = UIAlertController(title: "Информация о ходьбе", message: message, preferredStyle: .alert)
                    alert.addAction(.init(title: "Ok", style: .default))
                    self?.present(alert, animated: true)
                }
            )
            .disposed(by: disposeBag)
        
        viewModel.measurments
            .skip(1)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] measurments in
                    guard let self = self else { return }
                    MBProgressHUD.hide(for: self.view, animated: true)
                    self.graphView.reload()
                }
            )
            .disposed(by: disposeBag)
        
        viewModel.measurments
            .observe(on: SerialDispatchQueueScheduler(qos: .background))
            .map {
                !$0.isEmpty
            }
            .bind(to: processButon.rx.isEnabled)
            .disposed(by: disposeBag)
        
        viewModel.isPeripheralConnected
            .skip(2)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] state in
                    guard let self = self else { return }
                    if state {
                        MBProgressHUD.hide(for: self.view, animated: true)
                    } else {
                        self.navigationController?.popViewController(animated: true)
                    }
                }
            )
            .disposed(by: disposeBag)
        
        viewModel.errorRelay
            .observe(on: MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] errorString in
                    guard let self = self else { return }
                    self.hud?.label.text = errorString
                    self.hud?.hide(animated: true, afterDelay: 5.0)
                }
            )
            .disposed(by: disposeBag)
        
        viewModel.downloadProgressRelay
            .observe(on: MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] progress in
                    guard let self = self else { return }
                    self.hud?.mode = .determinate
                    self.hud?.label.text = "Скачивание"
                    self.hud?.progressObject = progress
                }
            )
            .disposed(by: disposeBag)
        
    }
    
    private func makeButton(image: String, tag: Int) -> FlatButton {
        let button = FlatButton()
        button.image = UIImage(named: image)
        button.backgroundColor = .white
        button.borderColor = .black.withAlphaComponent(0.1)
        button.borderWidthPreset = .border1
        button.tag = tag
        
        if tag == 2 {
            button.menu = makeMenu()
            button.showsMenuAsPrimaryAction = true
        } else {
            button.addTarget(self, action: #selector(handleButton), for: .touchUpInside)
        }
        
        return button
    }
    
    private func updateGraphView() {
        
        switch currentDataType {
        case .gyro:
            graphView.rangeMin = -600.0
            graphView.rangeMax = 600.0
        case .accel:
            graphView.rangeMin = -2.0
            graphView.rangeMax = 2.0
        }
  
        switch (currentDataType, currentAxisType) {
        case (.accel, .x):
            verticalUnitLabel.text = "Акселерометр X (g)"
        case (.accel, .y):
            verticalUnitLabel.text = "Акселерометр Y (g)"
        case (.accel, .z):
            verticalUnitLabel.text = "Акселерометр Z (g)"
        case (.gyro, .x):
            verticalUnitLabel.text = "Гироскоп X (рад/сек)"
        case (.gyro, .y):
            verticalUnitLabel.text = "Гироскоп Y (рад/сек)"
        case (.gyro, .z):
            verticalUnitLabel.text = "Гироскоп Z (рад/сек)"
        }
        
        graphView.reload()
    }
    
    // MARK: - actions
    @objc
    private func handleButton(_ sender: FlatButton) {
        switch sender.tag {
        case 0:
            viewModel.startSampling()
        case 1:
            viewModel.endSampling()
        case 2:
            viewModel.beginCalibration()
        case 3:
            viewModel.requestFile()
            if let hud = hud {
                hud.hide(animated: false)
                self.hud = MBProgressHUD.showAdded(to: view, animated: false)
            } else {
                hud = MBProgressHUD.showAdded(to: view, animated: true)
            }
           
        default:
            break
        }
    }
    
    private func makeActions(for type: DisplayType) -> [UIAction] {
        let x = UIAction(title: "X") { [weak self] _ in
            self?.currentDataType = type
            self?.currentAxisType = .x
        }
        let y = UIAction(title: "Y") { [weak self] _ in
            self?.currentDataType = type
            self?.currentAxisType = .y
        }
        let z = UIAction(title: "Z") { [weak self] _ in
            self?.currentDataType = type
            self?.currentAxisType = .z
        }
        return [x, y, z]
    }
    
    private func makeMenu() -> UIMenu {
  
        let accel = UIMenu(
            title: "Акселерометр",
            image: nil,
            identifier: nil,
            options: .singleSelection,
            children: makeActions(for: .accel)
        )
        
        let gyro = UIMenu(
            title: "Гироскоп",
            image: nil,
            identifier: nil,
            options: .singleSelection,
            children: makeActions(for: .gyro)
        )
        
        return UIMenu(
            title: "Источник данных",
            image: nil,
            identifier: nil,
            options: .singleSelection,
            children: [
                accel,
                gyro
            ]
        )
    }
    
    private func processData() -> Single<StepsInfo> {
        return Single.create { [weak self] promise in
            let disposables = Disposables.create()
            
            guard let self = self else {
                promise(
                    .failure(
                        NSError(domain: "Unexcepted deallocation", code: -1)
                    )
                )
                return disposables
            }
            
            do {
                let info = try StepsProcessor.process(input: self.viewModel.measurments.value)
                promise(.success(info))
            } catch {
                promise(.failure(error))
            }
            
            return disposables
        }
        .subscribe(on: SerialDispatchQueueScheduler(qos: .utility))
    }
}

extension DeviceControlVC: ScrollableGraphViewDataSource {
    func value(forPlot plot: Plot, atIndex pointIndex: Int) -> Double {
        guard let mesurment = viewModel.measurments.value[safe: pointIndex] else {
            return .zero
        }
    
        switch (currentDataType, currentAxisType) {
        case (.accel, .x):
            return Double(mesurment.ax)
        case (.accel, .y):
            return Double(mesurment.ay)
        case (.accel, .z):
            return Double(mesurment.az)
        case (.gyro, .x):
            return Double(mesurment.gx)
        case (.gyro, .y):
            return Double(mesurment.gy)
        case (.gyro, .z):
            return Double(mesurment.gz)
        }
    }
    
    func label(atIndex pointIndex: Int) -> String {
        return "\(pointIndex)"
    }
    
    func numberOfPoints() -> Int {
        return viewModel.measurments.value.count
    }
}
