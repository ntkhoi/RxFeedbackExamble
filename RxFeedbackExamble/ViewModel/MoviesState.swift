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
    var shouldLoadNextPage: Bool
    var isPullRefreshing: Bool    
    init() {
        movies = Version([])
        page = 1
        shouldLoadNextPage = true
        isPullRefreshing = false
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
                    $0.shouldLoadNextPage = false
                    $0.isPullRefreshing = false
                    return
                }
            case .failure(_):
                return state
            }
        case .loadMoreItems:
            return state.mutate {
                $0.shouldLoadNextPage = true
                $0.page += 1
            }
        case .pullToRequest:
            return state.mutate{
                $0.movies = Version([])
                $0.isPullRefreshing = true
                $0.page = 1
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
func loadMovieState(
    loadNextPageTrigger: @escaping (Observable<MovieState>) -> Observable<()>,
    pullToRequestTrigger: @escaping () -> Observable<()>
    ) -> Observable<MovieState> {
    
    let searchPerformerFeedback: ( (ObservableSchedulerContext<MovieState>) ) -> Observable<MovieCommand> = { state in
        return state.map{ ($0.page , $0.shouldLoadNextPage , $0.isPullRefreshing) }
            .distinctUntilChanged { $0 == $1 }
            .flatMap({ (page, shouldLoadNextPage,shoulPullToRequest) -> Observable<MovieCommand> in
                return NetworkingLayer.fetchRepositories(page: page)
                .asObservable()
                .map(MovieCommand.movieResponseRecieved)
            }).shareReplay(1)
    }
    
    // this is degenerated feedback loop that doesn't depend on output state
    let inputFeedbackLoop: (ObservableSchedulerContext<MovieState>) -> Observable<MovieCommand> = { stateContext in
        let loadNextPage =  loadNextPageTrigger(stateContext.source).map{ _ in MovieCommand.loadMoreItems }
        let pullToRequest = pullToRequestTrigger().map{ MovieCommand.pullToRequest }
        return Observable.merge(loadNextPage,pullToRequest)
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
            searchPerformerFeedback,
            inputFeedbackLoop
        ]
    )
}


// Implement `Equatable` for `distinctUntilChanged()` to work
func ==(lhs: MovieState, rhs: MovieState) -> Bool {
    return lhs.shouldLoadNextPage == rhs.shouldLoadNextPage
    && lhs.page == rhs.page
    && lhs.isPullRefreshing == rhs.isPullRefreshing
    
    
}
