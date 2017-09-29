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

class ViewController: UIViewController, UITableViewDelegate  {
    var disposeBag = DisposeBag()
   let state = loadMovieState()
    let dataSource = RxTableViewSectionedReloadDataSource<SectionModel<String, Movie>>()
    
    @IBOutlet weak var tableView: UITableView! {
        didSet{
            tableView.estimatedRowHeight = 141
            tableView.rowHeight = UITableViewAutomaticDimension
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configCell()
        configDatasource()
        tableView.rx.modelSelected(Movie.self)
            .subscribe(onNext: { movie in
                print("Movie")
            })
            .disposed(by: disposeBag)
    }
    
    fileprivate func configCell() {
        dataSource.configureCell = { (_, tv, ip, movie: Movie) in
            let cell = tv.dequeueReusableCell(withIdentifier: String(describing: MovieCell.self))! as! MovieCell
            cell.movie = movie
            return cell
        }
    }
    
    fileprivate func configDatasource() {
        state
            .map { $0.movies }
            .distinctUntilChanged()
            .map { [SectionModel(model: "Movies", items: $0.value)] }
            .bind(to:tableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
    }
}
