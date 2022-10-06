//
//  GraphView.swift
//  app_part2
//
//  Created by Ирина Токарева on 26.03.2022.
//

import Foundation
import ScrollableGraphView

class GraphView: ScrollableGraphView {
    
    override init(frame: CGRect, dataSource: ScrollableGraphViewDataSource) {
        super.init(frame: frame, dataSource: dataSource)
        delegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard let ctx = UIGraphicsGetCurrentContext() else {
            return
        }
        
        let width = rect.width
        let numberOfLines = Int(ceil(width / dataPointSpacing)) + 4
        
        let offset = contentOffset.x / dataPointSpacing
        let offsetMod = contentOffset.x - floor(offset) * dataPointSpacing
        
        var point = CGPoint(
            x: rect.origin.x + dataPointSpacing / 2 - offsetMod,
            y: topMargin
        )
        
        ctx.setLineWidth(1)
        ctx.setStrokeColor(UIColor.black.withAlphaComponent(0.1).cgColor)
        
        for _ in 0..<numberOfLines {
            ctx.move(to: point)
            ctx.addLine(to: .init(x: point.x, y: rect.height - bottomMargin - 20))
            ctx.strokePath()
    
            point.x += dataPointSpacing
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        setNeedsDisplay()
    }
}
