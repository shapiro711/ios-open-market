//
//  OpenMarket - ViewController.swift
//  Created by yagom. 
//  Copyright © yagom. All rights reserved.
// 

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView?
    @IBOutlet weak var loadListIndicator: UIActivityIndicatorView!
    
    var productList = [Product]()
    let networkManager = NetworkManager()
    let parsingManager = ParsingManager()
    var currentPage = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationItem()
        configureCollectionView()
        loadListIndicator.hidesWhenStopped = true
        loadProductList(page: currentPage)
    }
    
    private func configureNavigationItem() {
        self.navigationItem.title = "야아 마켓"
        let addBarButton = UIBarButtonItem(barButtonSystemItem: .add, target: nil, action: nil)
        self.navigationItem.rightBarButtonItem = addBarButton
    }
    
    private func configureCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        
        guard let collectionView = collectionView else { return }
        collectionView.register(MyCollectionViewCell.nib(), forCellWithReuseIdentifier: MyCollectionViewCell.identifier)
        
        collectionView.collectionViewLayout = layout
        collectionView.delegate = self
        collectionView.dataSource = self
        view.addSubview(collectionView)
    }
    
    private func loadProductList(page: Int) {
        loadListIndicator.startAnimating()
        self.currentPage = page + 1
        let apiModel = GetAPI.lookUpProductList(page: page, contentType: .noBody)
        networkManager.request(apiModel: apiModel) { [self] result in
            switch result {
            case .success(let data):
                guard let parsingData = parsingManager.decodingData(data: data, model: Page.self),
                      !parsingData.products.isEmpty else { return }
                for product in parsingData.products {
                    productList.append(product)
                    DispatchQueue.main.async {
                        loadListIndicator.stopAnimating()
                        self.collectionView?.reloadData()
                    }
                }
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
}

extension ViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView,
                        didEndDisplaying cell: UICollectionViewCell,
                        forItemAt indexPath: IndexPath) {
        if indexPath.item == self.productList.count - 20 {
            loadProductList(page: currentPage)
        }
    }
}

extension ViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return productList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MyCollectionViewCell.identifier, for: indexPath) as! MyCollectionViewCell
        if productList.count == indexPath.row {
            loadProductList(page: currentPage)
        }
        cell.configure(productList[indexPath.row])
        return cell
    }
}



extension ViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width/2-10, height: collectionView.frame.height/3)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                       layout collectionViewLayout: UICollectionViewLayout,
                       insetForSectionAt section: Int) -> UIEdgeInsets {
        let inset = UIEdgeInsets(top: 2, left: 5, bottom: 2, right: 5)
        return inset
    }
}
