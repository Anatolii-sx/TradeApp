//
//  MainVC.swift
//  TemplateOfDealsViewer
//
//  Created by Анатолий Миронов on 04.04.2023.
//

import UIKit

// MARK: - MainVC (Connection Presenter -> View)

protocol MainVCProtocol: AnyObject {
    func setupStartSettings()
    func reloadData()
    func changeLoadingView(isHidden: Bool)
    func changeDirectionButtonColor(_ color: UIColor)
    func scrollToTop()
}

class MainVC: UIViewController {
    
    // MARK: - IB Outlets
    
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var sortingDirectionButton: UIBarButtonItem!
    @IBOutlet private weak var loadingView: UIView!
    
    // MARK: - Presenter
    
    private var presenter: MainVCPresenterProtocol!
    
    // MARK: - Activity Indicator View
    
    private lazy var activityIndicatorFooter: UIActivityIndicatorView = {
        let activityIndicatorFooter = UIActivityIndicatorView()
        activityIndicatorFooter.style = .medium
        activityIndicatorFooter.frame = CGRect(x: 0, y: 0, width: 48, height: 48)
        return activityIndicatorFooter
    }()
    
    deinit {
        presenter.didDeinit()
    }
    
    // MARK: - ViewController Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        presenter = MainVCPresenter(view: self)
        presenter.viewDidLoad()
    }
    
    // MARK: - IB Actions
    
    @IBAction func sortingDirectionButtonTapped(_ sender: UIBarButtonItem) {
        presenter.directionButtonTapped()
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
        presenter.getNumberOfRowsInSection()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: DealCell.reuseIdentifier, for: indexPath) as? DealCell else { return UITableViewCell() }
        cell.configure(presenter.getDealForCell(indexPath.row))
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let cell = tableView.dequeueReusableHeaderFooterView(withIdentifier: HeaderCell.reuseIdentifier) as? HeaderCell else { return UIView() }
        cell.delegate = { [weak self] segmentIndex in
            self?.presenter.segmentControlTapped(segmentIndex)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        presenter.willDisplayCell(indexPath.row)
    }
}

// MARK: - Realization MainVCProtocol Methods (Connection Presenter -> View)

extension MainVC: MainVCProtocol {
    
    func setupStartSettings() {
        title = presenter.title
        loadingView.isHidden = true
        setupTableView()
    }
    
    func reloadData() {
        tableView.reloadData()
    }
    
    func changeLoadingView(isHidden: Bool) {
        loadingView.isHidden = isHidden
    }
    
    func changeDirectionButtonColor(_ color: UIColor) {
        sortingDirectionButton.tintColor = color
    }
    
    func scrollToTop() {
        if tableView.numberOfRows(inSection: 0) > 0 {
            tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
        }
    }
}
