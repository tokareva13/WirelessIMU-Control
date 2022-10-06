//
//  GradButton.swift
//  app_part2
//
//  Created by Ирина Токарева on 11.10.2021.
//

import UIKit

// Создание класса кнопки
class GradButton: UIButton {
   
    // Создание слоя, отвечающего за градиент
    private lazy var gradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer ()
        let colors:[UIColor] = [#colorLiteral(red: 0, green: 0.9529411765, blue: 0.8509803922, alpha: 1), #colorLiteral(red: 0, green: 0.5764705882, blue: 0.4509803922, alpha: 1)]
        layer.colors = colors.map {
            $0.cgColor // преобразование одного типа цвета ui в другой cg
        }
        layer.locations = [0.0, 1.0]
        return layer
    }()
    
    // Конструктор класса
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    // Конструктор класса для визуального редактора
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    // Позиционирование слоев
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame.size = frame.size
    }
    
    // Настройка интерфейса кнопки
    private func setupUI() {
        layer.addSublayer(gradientLayer)
        layer.cornerRadius = 14
        layer.masksToBounds = true
    }
}
