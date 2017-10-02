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
    var isLoading: Bool
    init() {
        movies = Version([])
        page = 1
        shouldLoadNextPage = true
        isPullRefreshing = false
        isLoading = true
        
    }
}
extension MovieState {
    
    static var initial = MovieState()
    static func reduce(state: MovieState,command: MovieCommand) -> MovieState {
        switch command {
        case .movieResponseRecieved(let movieResponse):
            switch movieResponse {
            case .success(let movies):
                return state.mutate {
                    $0.movies = Version(state.movies.value + movies )
                    $0.shouldLoadNextPage = false
                    $0.isPullRefreshing = false
                    $0.isLoading = false
                    return
                }
            case .failure(_):
                return state.mutate {
                    $0.isLoading = false
                    return
                }
            }
        case .loadMoreItems:
            return state.mutate {
                $0.shouldLoadNextPage = true
                $0.page += 1
                $0.isLoading = true
            }
        case .pullToRequest(let movieResponse):
            switch movieResponse {
            case .success(let movies):
                return state.mutate {
                    $0.movies = Version(movies)
                    $0.page = 1
                    $0.isLoading = false
                    return
                }
            case .failure(_):
                return state.mutate {
                    $0.isLoading = false
                    return
                }
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
    
    let loadMoviePerformerFeedback: ( (ObservableSchedulerContext<MovieState>) ) -> Observable<MovieCommand> = { state in
        let activityIndicator = ActivityIndicator()
        return
            state
            .map{ ($0.page , $0.shouldLoadNextPage ) }
            .distinctUntilChanged { $0 == $1 } // Refesh network when state change . $0 == $1 Implement == function on what field
            .flatMapLatest({ (page, shouldLoadNextPage) -> Observable<MovieCommand> in
                if !shouldLoadNextPage {
                    return Observable.empty()
                }
                return NetworkingLayer.fetchMovies(page: page).trackActivity(activityIndicator)
                .asObservable()
                .shareReplay(1)
                .map(MovieCommand.movieResponseRecieved)
            })
    }
    
    // this is degenerated feedback loop that doesn't depend on output state
    let inputFeedbackLoop: (ObservableSchedulerContext<MovieState>) -> Observable<MovieCommand> = { stateContext in
        let loadNextPage =  loadNextPageTrigger(stateContext.source).map{ _ in MovieCommand.loadMoreItems }
        let pullToRefesh = pullToRequestTrigger().flatMap({ () -> Observable<MovieCommand> in
            return  NetworkingLayer.fetchMovies() // Net set state.isloading = true to starting loading . But still don't know to modify state here because state is immutable
                .asObservable()
                .shareReplay(1)
                .map(MovieCommand.pullToRequest)
        })
        return Observable.merge(loadNextPage, pullToRefesh).shareReplay(1)
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
            loadMoviePerformerFeedback,
            inputFeedbackLoop
        ]
    )
}


// Implement `Equatable` for `distinctUntilChanged()` to work
func ==(lhs: MovieState, rhs: MovieState) -> Bool {
    return lhs.shouldLoadNextPage == rhs.shouldLoadNextPage
}






