//
//  SeguePresentViewController.swift
//  presentViewController
//
//  Created by 김지현 on 2022/02/01.
//

import UIKit

protocol SendDataDelegate: AnyObject {
    func sendData(name: String)
}

class SeguePresentViewController: UIViewController {

    weak var delegate: SendDataDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func backButtonClicked(_ sender: Any) {
        self.delegate?.sendData(name: "패캠챌린지~")
        self.dismiss(animated: true, completion: nil)
    }
    
}
