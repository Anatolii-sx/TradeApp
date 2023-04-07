//
//  MainVC.swift
//  TemplateOfDealsViewer
//
//  Created by Анатолий Миронов on 04.04.2023.
//

import UIKit

final class DealCell: UITableViewCell {
    
    @IBOutlet private weak var dateLabel: UILabel!
    @IBOutlet private weak var instrumentNameLabel: UILabel!
    @IBOutlet private weak var priceLabel: UILabel!
    @IBOutlet private weak var amountLabel: UILabel!
    @IBOutlet private weak var sideLabel: UILabel!
    
    static let reuseIdentifier = "DealCell"
    
    func configure(_ deal: Deal) {
        dateLabel.text = getDate(deal.dateModifier)
        instrumentNameLabel.text = deal.instrumentName
        priceLabel.text = getPrice(deal.price)
        sideLabel.text = "\(deal.side)"
        amountLabel.text = getAmount(deal.amount)
        
        priceLabel.textColor = deal.side == .buy ? .systemGreen : .systemPink
        sideLabel.textColor = deal.side == .buy ? .systemGreen : .systemPink
    }
    
    private func getDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss ZZZZ"
        guard let theDate = dateFormatter.date(from: "\(date)") else { return "" }
        
        let newDateFormatter = DateFormatter()
        newDateFormatter.dateFormat = "HH:mm:ss dd.MM.yyyy"
        return newDateFormatter.string(from: theDate)
    }
    
    private func getPrice(_ price: Double) -> String {
        let roundPrice = "\(round(100*price)/100)"
        let priceAfterDot = roundPrice.components(separatedBy: ".").last ?? ""
        let result = priceAfterDot.count == 1 ? roundPrice + "0" : roundPrice
        return result
    }
    
    private func getAmount(_ amount: Double) -> String {
        let roundedAmount = lround(amount)
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.groupingSeparator = " "
        
        guard let roundedAmountWithSpace = numberFormatter.string(from: NSNumber(value: roundedAmount)) else {
            print("⛔️ ERROR NUMBER FORMATTER")
            return "\(roundedAmount)"
        }
        
        return roundedAmountWithSpace
    }
}
