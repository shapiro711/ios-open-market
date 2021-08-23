//
//  OpenMarket - ViewController.swift
//  Created by yagom. 
//  Copyright © yagom. All rights reserved.
// 

import UIKit

class ViewController: UIViewController, UICollectionViewDelegate {
    
    @IBOutlet weak var collectionView: UICollectionView?
    
    var productList = [Product]()
    let networkManager = NetworkManager()
    let parsingManager = ParsingManager()
    var currentPage = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        
        guard let collectionView = collectionView else { return }
        collectionView.register(MyCollectionViewCell.nib(), forCellWithReuseIdentifier: MyCollectionViewCell.identifier)
        collectionView.collectionViewLayout = layout
        collectionView.delegate = self
        collectionView.dataSource = self
        loadProductList(page: 1)
        view.addSubview(collectionView)
    }
    
    private func loadProductList(page: Int) {
        self.currentPage = page
        let apiModel = GetAPI.lookUpProductList(page: page, contentType: .noBody)
        networkManager.request(apiModel: apiModel) { [self] result in
            switch result {
            case .success(let data):
                guard let parsingData = parsingManager.decodingData(data: data, model: Page.self),
                      !parsingData.products.isEmpty else { return }
                for product in parsingData.products {
                    productList.append(product)
                    collectionView?.dataSource.
                }
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
}

extension ViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 8
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MyCollectionViewCell.identifier, for: indexPath) as! MyCollectionViewCell
        cell.configure()
        return cell
    }
}

extension ViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width/2-10, height: collectionView.frame.height/3)
    }
}
