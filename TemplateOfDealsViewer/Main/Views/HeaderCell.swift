//
//  MainVC.swift
//  TemplateOfDealsViewer
//
//  Created by Анатолий Миронов on 04.04.2023.
//

import UIKit

final class HeaderCell: UITableViewHeaderFooterView {
    
    @IBOutlet private weak var segmentedControl: UISegmentedControl!
    @IBOutlet private weak var instrumentNameLabel: UILabel!
    @IBOutlet private weak var priceLabel: UILabel!
    @IBOutlet private weak var amountLabel: UILabel!
    @IBOutlet private weak var sideLabel: UILabel!
    
    static let reuseIdentifier = "HeaderCell"
    var delegate: ((Int) -> Void)?
    
    @IBAction func segmentTapped() {
        delegate?(segmentedControl.selectedSegmentIndex)
    }
}
