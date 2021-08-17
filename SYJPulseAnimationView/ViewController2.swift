//
//  ViewController2.swift
//  SYJPulseAnimationView
//
//  Created by syj on 2021/8/17.
//

import UIKit

class ViewController2: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.addSubview(animationView)
        DispatchQueue.main.asyncAfter(deadline: .now()+0.5) {
            self.animationView.start() //开始动画
        }
        
    }
    
    deinit {
        animationView.stop()
        debugPrint("释放 ---\(Self.self)")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        animationView.resume()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        animationView.frame = .init(x: 100, y: 200, width: 150, height: 150)
        
    }
    
    lazy var animationView: SYJPulseAnimationView = {
        let view = SYJPulseAnimationView.init(frame: .zero)
        view.backgroundColor = UIColor.orange.withAlphaComponent(0.1)
        view.pulseColor = .green
        view.fromValueForRadius = Float(200.0/(200.0+30.0)) - 0.05
        view.haloLayerNumber = 4
        view.fromValueForAlpha = 0.8
        view.radius = 20
        view.pulseSize = .init(width: 150+30, height: 150+30)
        return view
    }()
    

    
}
