//
//  SYJPulseAnimationView.swift
//  SYJPulseAnimationView
//
//  Created by syj on 2021/8/17.
//

import UIKit

class SYJPulseAnimationView: UIView {
    
    // MARK: - public
    
    /// 是否正在动画
    fileprivate(set) var isAnimating: Bool = false
    
    /// size，默认(100,100)
    public var pulseSize: CGSize = .init(width: 100, height: 100) {
        didSet {
            updateEffectFrame()
        }
    }
    
    /// 圆角，默认10
    public var radius: CGFloat = 10 {
        didSet {
            effect.cornerRadius = radius
        }
    }
    
    /// 颜色
    public var pulseColor: UIColor = UIColor.white {
        didSet {
            effect.backgroundColor = pulseColor.cgColor
        }
    }
    
    /// 圈数，默认1
    public var haloLayerNumber: Int = 1 {
        didSet {
            animationLayer.instanceCount = haloLayerNumber
            animationLayer.instanceDelay = (animationDuration + pulseInterval) / Double(haloLayerNumber)
        }
    }
    
    /// 重复次数，默认无限
    public var repeatCount: Float {
        set {
            animationLayer.repeatCount = newValue
            animationGroup.repeatCount = repeatCount
        } get {
            return animationLayer.repeatCount
        }
    }
    
    /// 动画起始值
    public var fromValueForRadius: Float = 0.0
    /// 透明度起始值
    public var fromValueForAlpha: Float = 1.0
    /// 半透明时机（0 ~ 1）
    public var keyTimeForHalfOpacity: Float = 0.2
    /// 动画持续时间
    public var animationDuration: TimeInterval = 3.0 {
        didSet {
            animationLayer.instanceDelay = (animationDuration + pulseInterval) / Double(haloLayerNumber)
        }
    }
    /// 脉冲动画间隔
    public var pulseInterval: TimeInterval = 0.0
    
    /// 动画开始间隔
    public var startInterval: TimeInterval = 1.0 {
        didSet {
            animationLayer.instanceDelay = startInterval
        }
    }
    
    /// true时，进入前台后将自动恢复动画
    public var shouldResume: Bool = true
    
    /// 使用CAMediaTimingFunction
    public var useTimingFunction: Bool = true
    
    
    /// 开始动画
    public func start() {
        if isAnimating {
            return
        }
        isAnimating = true
        resume()
    }
    
    /// 停止动画
    public func stop() {
        isAnimating = false
        animationLayer.removeAllAnimations()
        animationGroup.delegate = nil
    }
    
    /// 恢复
    public func resume() {
        if isAnimating == false {
            return
        }
        
        if effect.animation(forKey: effectAnimationKey) != nil {
            return
        }
        
        if isExistEffectLayer() == false {
            animationLayer.addSublayer(effect)
        }
        
        let exist = isExistAniamtionLayer()
        if exist.0 == false, let prevSuperlayer = self.prevSuperlayer {
            prevSuperlayer.insertSublayer(animationLayer, at: UInt32(prevLayerIndex))
        }
        
        _setupAnimationGroup()
        effect.add(animationGroup, forKey: effectAnimationKey)
    }
    
    
    /// MARK: - init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _initUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        animationLayer.removeAllAnimations()
        animationGroup.delegate = nil
        NotificationCenter.default.removeObserver(self)
//        debugPrint("释放 ---\(Self.self)")
    }
    
    /// MARK: - UI
    
    private func _initUI() {
        addSubview(contentView)
        self.layer.insertSublayer(animationLayer, below: contentView.layer)
        animationLayer.addSublayer(effect)
        _setupDefaults()
        _registerNotification()
    }
    
    private func _setupDefaults() {
        self.repeatCount = Float.infinity
        self.pulseSize = .init(width: 100, height: 100)
        self.radius = 10
        self.haloLayerNumber = 1
        self.startInterval = 1
        self.pulseColor = .white
    }
    
    /// 更新effect坐标
    private func updateEffectFrame() {
        let effectX: CGFloat = (self.bounds.width - pulseSize.width)/2.0
        let effectY: CGFloat = (self.bounds.height - pulseSize.height)/2.0
        effect.frame = CGRect(x: effectX, y: effectY, width: pulseSize.width, height: pulseSize.height)
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        contentView.frame = self.bounds
        animationLayer.bounds = contentView.bounds
        animationLayer.position = contentView.center
        updateEffectFrame()
    }
    
    
    // MARK: - 通知
    
    /// 注册
    private func _registerNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    /// 即将进入后台，记录superlayer和index
    @objc private func didEnterBackground() {
        prevSuperlayer = animationLayer.superlayer
        if let superlayer = animationLayer.superlayer {
            if let sublayers = superlayer.sublayers {
                for (idx, tempSubLayer) in sublayers.enumerated() {
                    if tempSubLayer == self {
                        prevLayerIndex = idx
                        break
                    }
                }
            }
        }
    }
    
    /// 即将进入前台
    @objc private func willEnterForeground() {
        if shouldResume {
            resume()
        }
    }
    
    /// 是否存在aniamtionLayer
    private func isExistAniamtionLayer() -> (Bool, Int) {
        if let superlayer = animationLayer.superlayer {
            if let sublayers = superlayer.sublayers {
                for (idx, tempSubLayer) in sublayers.enumerated() {
                    if tempSubLayer == self {
                        return (true, idx)
                    }
                }
            }
        }
        return (false, 0)
    }
    
    /// 是否存在effectLayer
    private func isExistEffectLayer() -> Bool {
        if let sublayers = animationLayer.sublayers {
            for (_, tempSubLayer) in sublayers.enumerated() {
                if tempSubLayer == effect {
                    return true
                }
            }
        }
        return false
    }
    
    // MARK: - 创建动画
    
    /// 组合动画
    private func _setupAnimationGroup() {
        animationGroup = CAAnimationGroup()
        animationGroup.duration = animationDuration + pulseInterval
        animationGroup.repeatCount = self.repeatCount
        animationGroup.isRemovedOnCompletion = true
        animationGroup.fillMode = .forwards
        if useTimingFunction {
            let defaultCurve = CAMediaTimingFunction(name: CAMediaTimingFunctionName.default)
            animationGroup.timingFunction = defaultCurve
        }
        
        animationGroup.animations = [_createScaleAnimation(), _createOpacityAnimation()]
        animationGroup.delegate = self
    }
    
    /// 比例放大/缩放动画
    private func _createScaleAnimation() -> CABasicAnimation {
        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale.xy")
        scaleAnimation.fromValue = fromValueForRadius
        scaleAnimation.toValue = 1.0
        scaleAnimation.duration = animationDuration
        scaleAnimation.isRemovedOnCompletion = true
        return scaleAnimation
    }
    
    /// 透明度动画
    private func _createOpacityAnimation() -> CAKeyframeAnimation {
        let opacityAnimation = CAKeyframeAnimation(keyPath: "opacity")
        opacityAnimation.duration = animationDuration
        opacityAnimation.values = [fromValueForAlpha, 0.8, 0]
        opacityAnimation.keyTimes = [0, keyTimeForHalfOpacity as NSNumber, 1]
        opacityAnimation.isRemovedOnCompletion = true
        return opacityAnimation
    }
    
    
    // MARK: - private
    
    private lazy var animationLayer: CAReplicatorLayer = {
        let layer = CAReplicatorLayer.init()
        layer.backgroundColor = UIColor.clear.cgColor
        return layer
    }()
    
    /// 圈
    private let effect: CALayer = {
        let layer = CALayer.init()
        layer.contentsScale = UIScreen.main.scale
        layer.opacity = 0
        return layer
    }()
    
    /// 动画组
    private var animationGroup: CAAnimationGroup = CAAnimationGroup()
    private let effectAnimationKey = "pulse"
    
    /// use for resume
    private weak var prevSuperlayer: CALayer?
    private var prevLayerIndex: Int = 0
    
    private let contentView: UIView = {
        let view = UIView.init()
        return view
    }()
    
}


// MARK: - CAAnimationDelegate

extension SYJPulseAnimationView: CAAnimationDelegate {
    
    /// 动画结束
    public func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        didEnterBackground()
        
        if effect.animationKeys()?.count ?? 0 > 0 {
            effect.removeAllAnimations()
        }
        effect.removeFromSuperlayer()
        animationLayer.removeFromSuperlayer()
        animationGroup.delegate = nil
    }
    
}
