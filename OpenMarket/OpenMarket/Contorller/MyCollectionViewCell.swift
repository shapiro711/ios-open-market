//
//  MyCollectionViewCell.swift
//  OpenMarket
//
//  Created by 오승기 on 2021/08/23.
//

import UIKit

class MyCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var productImage: UIImageView!
    @IBOutlet weak var prductNameLabel: UILabel!
    @IBOutlet weak var originPriceLabel: UILabel!
    @IBOutlet weak var discountedPriceLabel: UILabel!
    @IBOutlet weak var stock: UILabel!
    
    static let identifier = "MyCollectionViewCell"
    
    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
    
    private func loadThumbnails(product: Product) {
        if let thumbnail = product.thumbnails.first,
           let thumbnailURL = URL(string: thumbnail),
           let data = try? Data(contentsOf: thumbnailURL) {
            DispatchQueue.main.async { [self] in
                productImage.image = UIImage(data: data)
            }
        }
    }
    
    func configure(_ product: Product) {
        loadThumbnails(product: product)
        prductNameLabel.text = product.title
        originPriceLabel.text = String(product.price)
        discountedPriceLabel.text = product.descriptions
        stock.text = String(product.stock)
        //updateLabels(product: product)
    }
    
    private func updateLabels(product: Product) {
        updateOriginPrice(product: product)
        updateDiscountedPrice(product: product)
        updataeStock(product: product)
    }
    
    private func updateOriginPrice(product: Product) {
        guard let text = originPriceLabel.text else { return }
        let attributedString = NSMutableAttributedString(string: text)
        let range = (text as NSString).range(of: text)
        if product.discountedPrice != nil {
            attributedString.addAttribute(NSAttributedString.Key.strikethroughStyle, value: 1, range: range)
            originPriceLabel.textColor = .red
        }else {
            attributedString.addAttribute(NSAttributedString.Key.strikethroughStyle, value: 0, range: range)
            originPriceLabel.attributedText = attributedString
            originPriceLabel.textColor = .lightGray
        }
    }
    
    private func updateDiscountedPrice(product: Product) {
        if let discountedPrice = product.discountedPrice {
            discountedPriceLabel.text = "\(product.currency)\(discountedPrice)"
            discountedPriceLabel.textColor = .lightGray
        } else {
            discountedPriceLabel.text = nil
        }
    }
    
    private func updataeStock(product: Product) {
        if product.stock == .zero {
            stock.text = "품절"
            stock.textColor = .yellow
        }
    }
    
    override func layoutSubviews() {
        self.layer.borderWidth = 2.0
        self.layer.cornerRadius = 5.0
        self.layer.borderColor = UIColor.lightGray.cgColor
    }
    
    override func prepareForReuse() {
        productImage.image = nil
        prductNameLabel.text = nil
        originPriceLabel.text = nil
        discountedPriceLabel.text = nil
        stock.text = nil
    }
}
