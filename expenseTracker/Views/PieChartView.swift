import UIKit

protocol PieChartViewDelegate: AnyObject {
    func didSelectSegment(withTitle title: String)
}

struct PieChartSegment {
    let color: UIColor
    let value: Double
    let title: String
}

class PieChartView: UIView {
    
    weak var delegate: PieChartViewDelegate?
    
    var segments: [PieChartSegment] = [] {
        didSet {
            drawChart()
        }
    }
    
    private var shapeLayers: [CAShapeLayer] = []
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupGesture()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupGesture()
    }
    
    private func setupGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        self.addGestureRecognizer(tap)
    }
    
    private var previousBounds: CGRect = .zero
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if bounds != previousBounds {
            previousBounds = bounds
            if !segments.isEmpty {
                drawChart()
            }
        }
    }
    
    private func drawChart() {
        // Remove old layers
        shapeLayers.forEach { $0.removeFromSuperlayer() }
        shapeLayers.removeAll()
        
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = min(bounds.width, bounds.height) / 2.0 - 10
        let total = segments.reduce(0) { $0 + $1.value }
        
        guard total > 0 else { return }
        
        var startAngle: CGFloat = -CGFloat.pi / 2
        let lineWidth: CGFloat = radius * 0.4
        
        for segment in segments {
            let percentage = CGFloat(segment.value / total)
            let endAngle = startAngle + (percentage * 2 * .pi)
            
            let path = UIBezierPath(arcCenter: center, radius: radius - lineWidth/2, startAngle: startAngle, endAngle: endAngle, clockwise: true)
            
            let shapeLayer = CAShapeLayer()
            shapeLayer.path = path.cgPath
            shapeLayer.fillColor = UIColor.clear.cgColor
            shapeLayer.strokeColor = segment.color.cgColor
            shapeLayer.lineWidth = lineWidth
            shapeLayer.name = segment.title // Store title for tap detection
            
            // Animation
            let animation = CABasicAnimation(keyPath: "strokeEnd")
            animation.fromValue = 0
            animation.toValue = 1
            animation.duration = 1.0
            animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
            shapeLayer.add(animation, forKey: "pieAnimation")
            
            self.layer.addSublayer(shapeLayer)
            shapeLayers.append(shapeLayer)
            
            startAngle = endAngle
        }
    }
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: self)
        
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let dx = point.x - center.x
        let dy = point.y - center.y
        let distance = sqrt(dx*dx + dy*dy)
        
        let radius = min(bounds.width, bounds.height) / 2.0 - 10
        let lineWidth = radius * 0.4
        let innerRadius = radius - lineWidth
        
        // Ensure tap is within the donut ring
        guard distance >= innerRadius && distance <= radius else { return }
        
        var angle = atan2(dy, dx)
        if angle < -CGFloat.pi / 2 {
            angle += 2 * .pi
        }
        
        let total = segments.reduce(0) { $0 + $1.value }
        guard total > 0 else { return }
        
        var currentAngle: CGFloat = -CGFloat.pi / 2
        
        for segment in segments {
            let percentage = CGFloat(segment.value / total)
            let endAngle = currentAngle + (percentage * 2 * .pi)
            
            if angle >= currentAngle && angle <= endAngle {
                let haptic = UIImpactFeedbackGenerator(style: .medium)
                haptic.impactOccurred()
                delegate?.didSelectSegment(withTitle: segment.title)
                break
            }
            
            currentAngle = endAngle
        }
    }
}
