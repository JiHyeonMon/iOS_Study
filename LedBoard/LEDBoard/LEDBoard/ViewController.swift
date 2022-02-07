//
//  ViewController.swift
//  LEDBoard
//
//  Created by 김지현 on 2022/02/07.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var ledLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let settingVC = segue.destination as? SettingViewController else {
            return
        }
        
        settingVC.delegate = self
        settingVC.ledText = self.ledLabel.text!
        settingVC.textColor = self.ledLabel.textColor ?? .red
        settingVC.bgColor = self.view.backgroundColor ?? .black
    }

}

extension ViewController: LEDBoardSettingDelegate {
    func sendLEDSetting(text: String, textColor: UIColor, backgroundColor: UIColor) {
        self.ledLabel.text = text
        self.ledLabel.textColor = textColor
        self.view.backgroundColor = backgroundColor
    }
}
