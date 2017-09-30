//
//  MovieCommand.swift
//  RxFeedbackExamble
//
//  Created by Khoi Nguyen on 9/26/17.
//  Copyright © 2017 Khoi Nguyen. All rights reserved.
//

import Foundation
import Alamofire
enum MovieCommand {
    case movieResponseRecieved(Result<[Movie]>)
    case loadMoreItems
    case pullToRequest(Result<[Movie]>)
}
