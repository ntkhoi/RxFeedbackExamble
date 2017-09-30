//
//  SVprogress+Rx.swift
//  RxFeedbackExamble
//
//  Created by Khoi Nguyen on 9/30/17.
//  Copyright © 2017 Khoi Nguyen. All rights reserved.
//

import SVProgressHUD
import RxSwift
import RxCocoa
import UIKit

extension Reactive where Base: SVProgressHUD {
    /// Bindable sink for `text` property.
     public var isProgressing: UIBindingObserver<Base, Bool> {
        return UIBindingObserver(UIElement: self.base) { svprogress, isProgressing in
            if isProgressing {
                SVProgressHUD.show()
            }else {
                SVProgressHUD.dismiss()
            }
        }
    }
    
}
