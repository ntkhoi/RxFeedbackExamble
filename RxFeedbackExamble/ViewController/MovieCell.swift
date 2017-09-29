//
//  MovieCell.swift
//  RxFeedbackExamble
//
//  Created by Khoi Nguyen on 9/27/17.
//  Copyright © 2017 Khoi Nguyen. All rights reserved.
//

import UIKit
import SDWebImage

class MovieCell: UITableViewCell {

    @IBOutlet weak var posterImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var overviewLabel: UILabel!
    var movie: Movie? {
        didSet{
            guard let movie = movie else { return }
            titleLabel.text = movie.title
            overviewLabel.text = movie.overview
            posterImageView.sd_setImage(with: movie.posterUrl)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    
}

