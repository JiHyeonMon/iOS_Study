//
//  ViewController.swift
//  ToDoList
//
//  Created by 김지현 on 2022/02/10.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    var tasks: [Task] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func editButtonPressed(_ sender: UIBarButtonItem) {
    }
    
    @IBAction func plusButtonPressed(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "ToDo", message: nil, preferredStyle: .alert)
        
        // 클로저 선언부에 캡처 목록을 선언해 줄 것.
        // 이유: class 처럼 closure도 참조 타입이기 때문에, 클로저에서 self로 본문의 인스턴스를 캡처할 때, 강항 순환 참조가 발생할 수 있다.
        // ARC의 단점. 두 개의 객체가 상호 참조하는 경우에 강한 순환 참조 발생
        // 이렇게 순환 참조에 연관된 객체들은 reference count가 0에 도달하지 않게 되고 메모리 누수가 발생한다.
        
        // 이것을 해결하는 방법. 클로저의 선언부에서 캡처목록을 정의하는 걸로 해결 가능
        let registerButton = UIAlertAction(title: "Register", style: .default, handler: { [weak self] _ in
            // 해당 버튼 눌렸을 때의 동작을 핸들러로 정의
            guard let title = alert.textFields?[0].text else { return }
            let task = Task(title: title, done: false)
            self?.tasks.append(task)
            self?.tableView.reloadData()
            
        })
        
        let cancelButton = UIAlertAction(title: "Cancel", style: .cancel, handler: nil )
        
        alert.addAction(cancelButton)
        alert.addAction(registerButton)
        alert.addTextField(configurationHandler: { textField in
            textField.placeholder = "할 일을 입력해주세요."
            
        })
        self.present(alert, animated: true, completion: nil)
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.tasks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // 재사용 가능한 Cell 객체 반환 + 이를 테이블 뷰에 추가하는 메서드
        // Queue를 사용해 Cell을 재사용함
        // 안보이게 되면 기존의 cell은 reusable pull 에 들어가게 되고, 나중에 다시 나와야 할 때 deque되며 사용한다.
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let task = self.tasks[indexPath.row]
        cell.textLabel?.text = task.title
        return cell
    }
    
    
}
