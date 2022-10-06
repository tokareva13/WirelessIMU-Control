//
//  OutlinedTextField.swift
//  app_part2
//
//  Created by Ирина Токарева on 14.11.2021.
//

import UIKit
import Material

class OutlinedTextField: UITextField {
    
    // MARK: - types
    struct State: OptionSet, Hashable {
        var rawValue: Int
        
        static let normal = State(rawValue: 1 << 0)
        static let editing = State(rawValue: 1 << 1)
        static let error = State(rawValue: 1 << 2)
        static let disabled = State(rawValue: 1 << 3)
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(rawValue)
        }
    }
    
    // MARK: - vars
    var cornerRadius: CGFloat = Constants.defaultCornerRadius {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var outlineWidth: CGFloat = Constants.defaultOutlineWidth {
        didSet {
            setNeedsDisplay()
        }
    }
    
    override var isEnabled: Bool {
        didSet {
            if isEnabled {
                controlState.remove(.disabled)
            } else {
                controlState.insert(.disabled)
            }
        }
    }
    
    private var controlState: State = .normal {
        didSet {
            guard !controlState.isEmpty else {
                controlState = .normal
                return
            }
            updateValuesForCurrentState()
            setNeedsDisplay()
        }
    }
    
    private(set) lazy var label: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = Constants.defaultLabelFont
        return label
    }()
    
    private lazy var outlineView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        return view
    }()
    
    private lazy var containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        return view
    }()
    
    private var textInsets: UIEdgeInsets {
        UIEdgeInsets(
            top: Constants.mediumOffset + label.frame.height / 2,
            left: Constants.mediumOffset,
            bottom: Constants.mediumOffset,
            right: Constants.mediumOffset
        )
    }
    
    private var outlineColors: [State: UIColor] = [
        .normal: Constants.defaultOutlineColor
    ]
    
    // MARK: - initialization
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return super.textRect(forBounds: bounds).inset(by: textInsets)
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return super.editingRect(forBounds: bounds).inset(by: textInsets)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - methods
    func setOutlineColor(_ color: UIColor, for state: State) {
        outlineColors[state] = color
        updateValuesForCurrentState()
    }
    
    func outlineColor(for state: State) -> UIColor {
        return outlineColors[state] ?? outlineColors[.normal] ?? Constants.defaultOutlineColor
    }
    
    override func becomeFirstResponder() -> Bool {
        controlState.insert(.editing)
        return super.becomeFirstResponder()
    }
    
    override func resignFirstResponder() -> Bool {
        controlState.remove(.editing)
        return super.resignFirstResponder()
    }
    
    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else {
            return
        }
        let labelFrame = label.frame.inset(by: .init(
                top: .zero,
                left: -Constants.defaultLabelToBorderInset,
                bottom: .zero,
                right: -Constants.defaultLabelToBorderInset
            )
        )
        let roundedRect = rect.inset(by: .init(
                top: labelFrame.midY,
                left: outlineWidth,
                bottom: outlineWidth,
                right: outlineWidth
            )
        )
        let outlineWidth = controlState == .editing ? self.outlineWidth : 1
        let outlineColor = outlineColor(for: controlState).cgColor
        let path = UIBezierPath(roundedRect: roundedRect, cornerRadius: cornerRadius)
        ctx.addPath(path.cgPath)
        
        ctx.setStrokeColor(outlineColor)
        ctx.setLineWidth(outlineWidth)
        ctx.strokePath()
        ctx.clear(labelFrame)
    }
    
    private func setupUI() {
        addSubview(label)
        setupConstraints()
        updateValuesForCurrentState()
    }
    
    private func setupConstraints() {
        label.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().inset(16)
            maker.top.equalToSuperview()
        }
        setNeedsDisplay()
    }
    
    private func updateValuesForCurrentState() {
        label.textColor = outlineColor(for: controlState)
        setNeedsDisplay()
    }
}

private extension OutlinedTextField {
    struct Constants {
        static let defaultCornerRadius: CGFloat = 8
        static let defaultOutlineWidth: CGFloat = 1.5
        static let defaultLabelTextSize: CGFloat = 15
        static let defaultLabelToBorderInset: CGFloat = 4
        static let mediumOffset: CGFloat = 16.0
        static let defaultOutlineColor = UIColor.lightGray
        static let defaultLabelFont = UIFont.systemFont(ofSize: 12, weight: .medium)
    }
}
