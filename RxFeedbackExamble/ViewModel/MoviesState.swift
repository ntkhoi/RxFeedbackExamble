//
//  MoviesState.swift
//  RxFeedbackExamble
//
//  Created by Khoi Nguyen on 9/26/17.
//  Copyright © 2017 Khoi Nguyen. All rights reserved.
//


struct MovieState {
    var movies: Version<[Movie]> // Version is an optimization. When something unrelated changes, we don't want to
    var page: Int
    init() {
        movies = Version([])
        page = 1
    }
}
extension MovieState {
    static let initial = MovieState()
    static func reduce(state: MovieState,command: MovieCommand) -> MovieState {
        switch command {
        case .movieResponseRecieved(let movieResponse):
            switch movieResponse {
            case .success(let movies):
                return state.mutate {
                    $0.movies = Version(state.movies.value + movies )
                    return
                }
            case .failure(_):
                return state
            }
        }
    }
}

extension MovieState: Mutable {
}

import RxSwift
import RxCocoa
import RxFeedback
/**
 This method contains the gist of paginated GitHub search.
 */
func loadMovieState() -> Observable<MovieState> {    
    let searchPerformerFeedback: ( (ObservableSchedulerContext<MovieState>) ) -> Observable<MovieCommand> = { state in
        return state.map{ $0.page }
            .distinctUntilChanged { $0 == $1 }
            .flatMap({ (page) -> Observable<MovieCommand> in
                return NetworkingLayer.fetchRepositories(page: page)
                .asObservable()
                .map(MovieCommand.movieResponseRecieved)
            }).shareReplay(1)
    }
    
    
    return  Observable.system(
        // the initial state of our state machine
        initialState: MovieState.initial,
        // reduce each command to a new state
        reduce: MovieState.reduce,
        // run state machin on main scheduler
        scheduler: MainScheduler.instance,
        // list of feedbacks (command generators)
        scheduledFeedback: [
            searchPerformerFeedback
        ]
    )
}




