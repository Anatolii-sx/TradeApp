//
//  MainVC.swift
//  TemplateOfDealsViewer
//
//  Created by Анатолий Миронов on 04.04.2023.
//

import UIKit

class MainVC: UIViewController {
    
    // MARK: - IB Outlets
    
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var sortingDirectionButton: UIBarButtonItem!
    @IBOutlet private weak var loadingView: UIView!
    
    // MARK: - Private Properties
    
    private let server = Server()
    private var deals: [Deal] = []
    private var currentSegmentIndex = 0
    private var dealsReversed = false
    private var countElementsOnPage = 100
    private weak var timer: Timer?

    private let semaphore = DispatchSemaphore(value: 1) // Семафор для того, чтобы гарантировать, что данные массива deals будут изменяться только одним потоком одновременно (используя методы wait() и signal(), предотвращая конфликты при одновременном доступе к deals с разных потоков
    
    private let globalQueue = DispatchQueue.global(qos: .userInteractive)
    
    // MARK: - Activity Indicator View
    
    private lazy var activityIndicatorFooter: UIActivityIndicatorView = {
        let activityIndicatorFooter = UIActivityIndicatorView()
        activityIndicatorFooter.style = .medium
        activityIndicatorFooter.frame = CGRect(x: 0, y: 0, width: 48, height: 48)
        return activityIndicatorFooter
    }()
    
    deinit {
        timer?.invalidate()
    }
    
    // MARK: - ViewController Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Deals"
        loadingView.isHidden = true
        setupTableView()
        setupTimer()
        getDataFromServer()
    }
    
    // MARK: - IB Actions
    
    @IBAction func sortingDirectionButtonTapped(_ sender: UIBarButtonItem) {
        reverseData()
    }
    
    // MARK: - Timer
    
    private func setupTimer() {
        timer = Timer.scheduledTimer(timeInterval: 2.5, target: self, selector: #selector(timerFunction), userInfo: nil, repeats: true)
        timer?.fire()
    }
    
    @objc
    private func timerFunction() {
        updateData()
    }
    
    // MARK: - Reverse Data

    private func reverseData() {
        loadingView.isHidden = false
        globalQueue.async { [weak self] in
            guard let self = self else { return }
            self.semaphore.wait()
            self.deals = self.deals.reversed()
            self.dealsReversed.toggle()
            self.updateData()
            self.semaphore.signal()
            
            DispatchQueue.main.async {
                self.scrollToTop()
                self.loadingView.isHidden = true
                self.sortingDirectionButton.tintColor = self.dealsReversed ? .systemMint : .systemBlue
            }
        }
    }
    
    // MARK: - Update Data
    
    private func updateData() {
        globalQueue.async { [weak self] in
            self?.semaphore.wait() // перед изменением данных запрашиваем разрешение у семафора
            self?.sortDeals()
            self?.semaphore.signal() // после изменения данных освобождаем разрешение
            
            DispatchQueue.main.async { [weak self] in
                self?.tableView.reloadData()
                self?.loadingView.isHidden = true
            }
        }
    }
    
    // MARK: - Sort Data
    
    private func sortDeals() {
        if dealsReversed {
            switch currentSegmentIndex {
            case 0: deals.sort { $0.dateModifier < $1.dateModifier }  // Date
            case 1: deals.sort { $0.instrumentName > $1.instrumentName } // Name
            case 2: deals.sort { $0.price > $1.price } // Price
            case 3: deals.sort { $0.amount > $1.amount } // Amount
            case 4: deals.sort { $0.side < $1.side } // Side
            default: break
            }
        } else {
            switch currentSegmentIndex {
            case 0: deals.sort { $0.dateModifier > $1.dateModifier }  // Date
            case 1: deals.sort { $0.instrumentName < $1.instrumentName } // Name
            case 2: deals.sort { $0.price < $1.price } // Price
            case 3: deals.sort { $0.amount < $1.amount } // Amount
            case 4: deals.sort { $0.side > $1.side } // Side
            default: break
            }
        }
    }
    
    // MARK: - Scroll To Top

    private func scrollToTop() {
        if tableView.numberOfRows(inSection: 0) > 0 {
            tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
        }
    }
    
}

// MARK: - Getting Data From Server

extension MainVC {
    private func getDataFromServer() {
        server.subscribeToDeals { [weak self] deals in
            guard let self = self else { return }
            self.semaphore.wait()
            self.deals.append(contentsOf: deals)
            self.semaphore.signal()
            print("Количество элементов в массиве deals:", self.deals.count)
            print("Количество элементов в table view:", self.countElementsOnPage)
        }
    }
}

// MARK: - Setup Table View

extension MainVC: UITableViewDataSource, UITableViewDelegate {
    
    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UINib(nibName: DealCell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: DealCell.reuseIdentifier)
        tableView.register(UINib(nibName: HeaderCell.reuseIdentifier, bundle: nil), forHeaderFooterViewReuseIdentifier: HeaderCell.reuseIdentifier)
        tableView.tableFooterView = activityIndicatorFooter
        activityIndicatorFooter.startAnimating()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        deals.prefix(countElementsOnPage).count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: DealCell.reuseIdentifier, for: indexPath) as? DealCell else { return UITableViewCell() }
        let deal = deals[indexPath.row]
        cell.configure(deal)
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let cell = tableView.dequeueReusableHeaderFooterView(withIdentifier: HeaderCell.reuseIdentifier) as? HeaderCell else { return UIView() }
        cell.delegate = { [weak self] segmentIndex in
            self?.loadingView.isHidden = false
            self?.currentSegmentIndex = segmentIndex
            self?.updateData()
            self?.scrollToTop()
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == countElementsOnPage - 1 {
            countElementsOnPage += 100
            tableView.reloadData()
        }
    }
}
