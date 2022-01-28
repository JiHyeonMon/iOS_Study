//
//  ViewController.swift
//  CH01_01
//
//  Created by 김지현 on 2022/01/27.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var quoteLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    
    let quotes = [
        Quote(content: "분노는 바보들의 가슴속에서만 살아간다.", name: "아인슈타인"),
        Quote(content: "분노는 바보들의 가슴속에서만 살아간다.", name: "아인슈타인"),
        Quote(content: "분노는 바보들의 가슴속에서만 살아간다.", name: "아인슈타인")
    ]
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func tapQuoteGenerator(_ sender: Any) {
        
        // 0~4 사이의 난수 생성
        let random = Int(arc4random_uniform(5))
        let quote = quotes[random]
        
        self.quoteLabel.text = quote.content
        self.nameLabel.text = quote.name
    }
    
}

