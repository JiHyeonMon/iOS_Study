//
//  SettingViewController.swift
//  LEDBoard
//
//  Created by 김지현 on 2022/02/07.
//

import UIKit

protocol LEDBoardSettingDelegate: NSObject {
    func sendLEDSetting(text: String, textColor: UIColor, backgroundColor: UIColor)
}

class SettingViewController: UIViewController {

    @IBOutlet weak var ledTextField: UITextField!
    
    @IBOutlet weak var redTextButton: UIButton!
    @IBOutlet weak var yelloTextButton: UIButton!
    @IBOutlet weak var purpleTextButton: UIButton!
    
    @IBOutlet weak var blackBackgroundButton: UIButton!
    @IBOutlet weak var blueBackgroundButton: UIButton!
    @IBOutlet weak var greenBackgroundButton: UIButton!
    
    public weak var delegate: LEDBoardSettingDelegate!
    
    var ledText: String = ""
    var textColor: UIColor = UIColor.yellow
    var bgColor: UIColor = UIColor.black
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        redTextButton.layer.borderColor = UIColor.gray.cgColor
        yelloTextButton.layer.borderColor = UIColor.gray.cgColor
        purpleTextButton.layer.borderColor = UIColor.gray.cgColor
        blackBackgroundButton.layer.borderColor = UIColor.gray.cgColor
        blueBackgroundButton.layer.borderColor = UIColor.gray.cgColor
        greenBackgroundButton.layer.borderColor = UIColor.gray.cgColor


        self.configure()
    }
    
    @IBAction func textColorButtonClicked(_ sender: UIButton) {
        switch sender {
        case redTextButton:
            changeTextColor(color: UIColor.red)
            textColor = UIColor.red
            
        case yelloTextButton:
            changeTextColor(color: UIColor.yellow)
            textColor = UIColor.yellow
            
        case purpleTextButton:
            changeTextColor(color: UIColor.purple)
            textColor = UIColor.purple
        default: break
        }
    }
    
    
    @IBAction func backgroundColorButtonClicked(_ sender: UIButton) {
        switch sender {
        case blackBackgroundButton:
            changeBackgroundColor(color: UIColor.black)
            bgColor = UIColor.black
            
        case blueBackgroundButton:
            changeBackgroundColor(color: UIColor.blue)
            bgColor = UIColor.blue

        case greenBackgroundButton:
            changeBackgroundColor(color: UIColor.green)
            bgColor = UIColor.green

        default: break
        }
    }
    
    @IBAction func saveButtonClicked(_ sender: UIButton) {
        self.delegate.sendLEDSetting(text: ledTextField.text!, textColor: textColor, backgroundColor: bgColor)
        self.navigationController?.popViewController(animated: true)
    }
    
    private func configure() {
        self.ledTextField.text = self.ledText
        changeTextColor(color: self.textColor)
        changeBackgroundColor(color: self.bgColor)
    }
    
    private func changeTextColor(color: UIColor) {
        self.redTextButton.layer.borderWidth = color == UIColor.red ? 1 : 0
        self.yelloTextButton.layer.borderWidth = color == UIColor.yellow ? 1 : 0
        self.purpleTextButton.layer.borderWidth = color == UIColor.purple ? 1 : 0
    }
    
    private func changeBackgroundColor(color: UIColor) {
        self.blackBackgroundButton.layer.borderWidth = color == UIColor.black ? 1 : 0
        self.blueBackgroundButton.layer.borderWidth = color == UIColor.blue ? 1 : 0
        self.greenBackgroundButton.layer.borderWidth = color == UIColor.green ? 1 : 0
    }
}
