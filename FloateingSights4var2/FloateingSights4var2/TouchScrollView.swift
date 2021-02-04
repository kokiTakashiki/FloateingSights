//
//  TouchScrollView.swift
//  FloateingSights4var2
//
//  Created by takasiki on H30/07/24.
//  Copyright © 平成30年 takasiki. All rights reserved.
//

import UIKit

protocol ScrollViewDelegate{
    func scrollViewTapped(tag: Int)
}

class TouchScrollView: UIScrollView {
    
    var Delegate: ScrollViewDelegate!
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        for touch: UITouch in touches {
            Delegate.scrollViewTapped(tag: touch.view!.tag)
        }
    }
}


