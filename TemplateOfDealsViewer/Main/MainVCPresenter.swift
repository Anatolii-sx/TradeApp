//
//  MainVCPresenter.swift
//  TemplateOfDealsViewer
//
//  Created by Анатолий Миронов on 07.04.2023.
//

import Foundation

// MARK: - MainVCPresenterProtocol (Connection View -> Presenter)

protocol MainVCPresenterProtocol {
    var title: String { get }
    
    init(view: MainVCProtocol)
    
    func viewDidLoad()
    func didDeinit()
    func directionButtonTapped()
    func getNumberOfRowsInSection() -> Int
    func getDealForCell(_ rowNumber: Int) -> Deal
    func willDisplayCell(_ rowNumber: Int)
    func segmentControlTapped(_ index: Int)
}

class MainVCPresenter: MainVCPresenterProtocol {
    
    // MARK: - Private Properties

    private let server = Server()
    private var deals: [Deal] = []
    private var dealsReversed = false
    private var currentSegmentIndex = 0
    private var countElementsOnPage = 100
    private weak var timer: Timer?

    private let semaphore = DispatchSemaphore(value: 1) // Семафор для того, чтобы гарантировать, что данные массива deals будут изменяться только одним потоком одновременно (используя методы wait() и signal(), предотвращая конфликты при одновременном доступе к deals с разных потоков
    
    private let globalQueue = DispatchQueue.global(qos: .userInteractive)
    
    private unowned let view: MainVCProtocol
    
    // MARK: - Realization MainVCPresenterProtocol
    
    var title = "Deals"
    
    required init(view: MainVCProtocol) {
        self.view = view
    }
    
    func viewDidLoad() {
        view.setupStartSettings()
        setupTimer()
        getDataFromServer()
    }
    
    func directionButtonTapped() {
        reverseData()
    }
    
    func didDeinit() {
        timer?.invalidate()
    }
    
    func getNumberOfRowsInSection() -> Int {
        deals.prefix(countElementsOnPage).count
    }
    
    func getDealForCell(_ rowNumber: Int) -> Deal {
        deals[rowNumber]
    }
    
    func willDisplayCell(_ rowNumber: Int) {
        if rowNumber == countElementsOnPage - 1 {
            countElementsOnPage += 100
            view.reloadData()
        }
    }
    
    func segmentControlTapped(_ index: Int) {
        view.changeLoadingView(isHidden: false)
        currentSegmentIndex = index
        updateData()
        view.scrollToTop()
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
        view.changeLoadingView(isHidden: false)
        
        globalQueue.async { [weak self] in
            guard let self = self else { return }
            self.semaphore.wait()
            self.deals = self.deals.reversed()
            self.dealsReversed.toggle()
            self.updateData()
            self.semaphore.signal()
            
            DispatchQueue.main.async {
                self.view.scrollToTop()
                self.view.changeLoadingView(isHidden: true)
                self.view.changeDirectionButtonColor(self.dealsReversed ? .systemMint : .systemBlue)
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
                self?.view.reloadData()
                self?.view.changeLoadingView(isHidden: true)
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
    
    
}

// MARK: - Getting Data From Server

extension MainVCPresenter {
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
