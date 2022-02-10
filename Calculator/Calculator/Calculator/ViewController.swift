//
//  ViewController.swift
//  Calculator
//
//  Created by 김지현 on 2022/02/08.
//

import UIKit

enum Operation {
    case Add
    case Subtract
    case Multifly
    case Divide
    case unkown
}

class ViewController: UIViewController {

    @IBOutlet weak var numberOutputLabel: UILabel!
    
    var displayNumber = ""
    var firstNum = ""
    var secondNum = ""
    var result = ""
    var currentOperation: Operation = .unkown
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }


    @IBAction func numberButtonClicked(_ sender: UIButton) {
        guard let number = sender.title(for: .normal) else {return}
        
        if self.displayNumber.count < 9 {
            self.displayNumber += String(number)
            self.numberOutputLabel.text = self.displayNumber
        }
    }
    
    @IBAction func clearButtonClicked(_ sender: UIButton) {
        self.displayNumber = ""
        self.firstNum = ""
        self.secondNum = ""
        self.result = ""
        self.currentOperation = .unkown
        self.numberOutputLabel.text = "0"
    }
    
    @IBAction func dotButtonClicked(_ sender: UIButton) {
        if self.displayNumber.count < 8, !self.displayNumber.contains(".") {
            self.displayNumber += self.displayNumber.isEmpty ? "0." : "."
            self.numberOutputLabel.text = self.displayNumber
        }
    }
    
    @IBAction func divideButtonClicked(_ sender: UIButton) {
        self.calculate(operation: .Divide)
    }
    
    @IBAction func multiflyButtonClicked(_ sender: UIButton) {
        self.calculate(operation: .Multifly)
    }
    
    @IBAction func minusButtonClicked(_ sender: UIButton) {
        self.calculate(operation: .Subtract)
    }
    
    @IBAction func plusButtonClicked(_ sender: UIButton) {
        self.calculate(operation: .Add)
    }
    
    @IBAction func resultButtonClicked(_ sender: UIButton) {
        self.calculate(operation: self.currentOperation)
    }
    
    func calculate(operation: Operation) {
        
        if self.currentOperation != .unkown {
            
            if !self.firstNum.isEmpty {
                self.secondNum = self.displayNumber
                self.displayNumber = ""
                
                guard let firstNum = Double(self.firstNum) else {return}
                guard let secondNum = Double(self.secondNum) else {return}
                
                switch self.currentOperation {
                case .Add :
                    self.result = "\(firstNum + secondNum)"
                case .Subtract:
                    self.result = "\(firstNum - secondNum)"
                case .Multifly:
                    self.result = "\(firstNum * secondNum)"
                case .Divide:
                    self.result = "\(firstNum / secondNum)"
                default:
                    break
                }
                
                self.firstNum = self.result
                self.numberOutputLabel.text = self.result

            }
            
            self.currentOperation = operation
            
        } else {
            self.firstNum = self.displayNumber
            self.currentOperation = operation
            self.displayNumber = ""
            
        }
    }
}

