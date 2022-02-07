//
//  ViewController.swift
//  presentViewController
//
//  Created by 김지현 on 2022/02/01.
//

import UIKit

class ViewController: UIViewController, SendDataDelegate {
    func sendData(name: String) {
        print(name)
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func codePushButtonClicked(_ sender: Any) {
        
        guard let viewController = self.storyboard?.instantiateViewController(withIdentifier: "CodePushVC") as? CodePushViewController else { return }
        viewController.name = "데이터 전달하기"
        self.navigationController?.pushViewController(viewController, animated: true)
    }
    
    @IBAction func codePresentButtonClicked(_ sender: Any) {
        guard let viewController = self.storyboard?.instantiateViewController(withIdentifier: "CodePresentVC") as? CodePresentViewController else { return }
        viewController.delegate = self
        viewController.modalPresentationStyle = .fullScreen
        self.present(viewController, animated: true, completion: nil)
    }
}

