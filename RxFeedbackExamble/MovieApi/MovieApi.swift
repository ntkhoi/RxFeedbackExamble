//
//  NetworkingLayer.swift
//  MovieRxSwift
//
//  Created by Khoi Nguyen on 9/26/17.
//  Copyright © 2017 Khoi Nguyen. All rights reserved.
//

import Foundation
import Foundation
import RxCocoa
import RxSwift
import RxAlamofire
import Alamofire
import ObjectMapper

enum CommonError : Error {
    
    case parsingError
    case networkError
}
typealias JsonObject = [String: Any]
typealias MovieResponse = Driver<Result<[Movie]>>



struct NetworkingLayer {
    static func fetchRepositories(page: Int = 1) -> MovieResponse {
        return requestJSON(.get, "https://api.themoviedb.org/3/movie/now_playing?api_key=a07e22bc18f5cb106bfe4cc1f83ad8ed&page=\(page)").debug()
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
            .map { (response, json) -> Result<[Movie]> in
                if response.statusCode == 200 {
                    guard let json = json as? JsonObject else {
                        return .failure(CommonError.parsingError)
                    }
                    guard let moviesJson = json["results"] as? [JsonObject] else {
                        return .failure(CommonError.parsingError)
                    }
                    
                    if let movies = Mapper<Movie>().mapArray(JSONObject: moviesJson){
                        return .success(movies)
                    } else {
                        return .failure(CommonError.parsingError)
                    }
                } else {
                    return .failure(CommonError.networkError)
                }
            }
            .observeOn(MainScheduler.instance) // switch to MainScheduler, UI updates
            .do(onNext: { _ in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            })
            .asDriver(onErrorJustReturn: .failure(CommonError.parsingError))
    }
}

