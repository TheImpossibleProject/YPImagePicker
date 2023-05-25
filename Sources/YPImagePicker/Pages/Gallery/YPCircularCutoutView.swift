import UIKit

class YPCircularCutoutView: UIView {
    
    private let shapeLayer = CAShapeLayer()
    private let insetMultiplier: CGFloat = 0.95
    
    var fillColor: UIColor = .lightGray.withAlphaComponent(0.7) {
        didSet {
            setNeedsLayout()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        shapeLayer.fillColor = fillColor.cgColor
        shapeLayer.fillRule = .evenOdd
        layer.addSublayer(shapeLayer)
        isUserInteractionEnabled = false
        alpha = 0
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let side = min(bounds.width, bounds.height)
        let originX = (side - (side * insetMultiplier)) * 0.5
        let originY = (bounds.height - (side * insetMultiplier)) * 0.5
        let frame = CGRect(x: originX,
                           y: originY,
                           width: side * insetMultiplier ,
                           height: side * insetMultiplier)
        
        let path = UIBezierPath(ovalIn: frame)
        path.append(UIBezierPath(rect: bounds))
        path.usesEvenOddFillRule = true
        
        shapeLayer.fillColor = fillColor.cgColor
        shapeLayer.path = path.cgPath
        shapeLayer.frame = bounds
    }
}

