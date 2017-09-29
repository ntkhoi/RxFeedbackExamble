//
//  ViewController.swift
//  RxFeedbackExamble
//
//  Created by Khoi Nguyen on 9/26/17.
//  Copyright © 2017 Khoi Nguyen. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources

extension UIScrollView {
    func  isNearBottomEdge(edgeOffset: CGFloat = 20.0) -> Bool {
        return self.contentOffset.y + self.frame.size.height + edgeOffset > self.contentSize.height
    }
}

class ViewController: UIViewController, UITableViewDelegate  {

    private var disposeBag = DisposeBag()
    private var refeshcontrol: UIRefreshControl?
    let dataSource = RxTableViewSectionedReloadDataSource<SectionModel<String, Movie>>()
    
    @IBOutlet weak var tableView: UITableView! {
        didSet{
            tableView.estimatedRowHeight = 141
            tableView.rowHeight = UITableViewAutomaticDimension
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //----------------------------------------------------------------//
        //----------------------Setup UI----------------------------------//
        let tableView: UITableView = self.tableView
        refeshcontrol = UIRefreshControl()
        tableView.insertSubview(refeshcontrol!, at: 0)
        
        //----------------------------------------------------------------//

        
        
        
        let loadNextPageTrigger: (Observable<MovieState>) -> Observable<()> =  { state in
            tableView.rx.contentOffset.asObservable()
                .withLatestFrom(state)
                .flatMap { state in
                    return tableView.isNearBottomEdge(edgeOffset: 20.0) && !state.shouldLoadNextPage
                        ? Observable.just(())
                        : Observable.empty()
            }
        }
        
        let pullToRequestTrigger: () -> Observable<()> = { [unowned self]  in
            self.refeshcontrol!.rx.controlEvent(.valueChanged)
                .asObservable()
                .observeOn(MainScheduler.instance)
                
        }
        
        let state = loadMovieState(
            loadNextPageTrigger: loadNextPageTrigger ,
            pullToRequestTrigger: pullToRequestTrigger
        )
        
        state.map{ $0.isPullRefreshing }
        .bind(to: refeshcontrol!.rx.isRefreshing)
        .addDisposableTo(disposeBag)
        
        dataSource.configureCell = { (_, tv, ip, movie: Movie) in
            let cell = tv.dequeueReusableCell(withIdentifier: String(describing: MovieCell.self))! as! MovieCell
            cell.movie = movie
            return cell
        }
        
        state
            .map { $0.movies }
            .distinctUntilChanged()
            .map { [SectionModel(model: "Movies", items: $0.value)] }
            .bind(to:tableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
        
        tableView.rx.modelSelected(Movie.self)
            .subscribe(onNext: { movie in
                print("Movie")
            })
            .disposed(by: disposeBag)
    }
    
    fileprivate func configCell() {
        
    }
    
    fileprivate func configDatasource() {
       
    }
}
