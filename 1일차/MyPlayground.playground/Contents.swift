import Foundation

/// 1, 상수와 변수
///

// 상수
// let 상수명: 데이터 타입 = 값
let a: Int = 100

// 변수
// var 변수명: 데이터 타입 = 값
var b: Int = 200


/// 2. 기본 데이터 타입
///

// Int
var someInt: Int = 100

// Unit
var someUnit: UInt = 200  // -200 은 에러

// Float
var someFloat: Float = 1.1

// Double
var someDouble: Double = 0.5

// Bool
var someBool: Bool = true

// Character
var someChar: Character = "a"

// String
var someString: String = "abcde"

// 타입추론
var some = 100  // 컴파일러가 자동으로 some은 Int형으로 인식

/// 3. 컬렉션 타입
///
// Array
var numbers: Array<Int> = Array<Int>() // 빈 Int Array 생성
// 데이터 추가
numbers.append(1)
numbers.append(2)
// 데이터 접근
numbers[0]
// 데이터 특정 index에 추가
numbers.insert(3, at: 2)
// 데이터 삭제
numbers.remove(at: 1)
numbers
 
// Dictionary
//var dic: Dictionary<String, Int> = Dictionary<String, Int>()
var dic:[String : Int] = ["one" : 1]
dic["two"] = 2
dic["zero"] = 0
dic

// 값 변경
dic["zero"] = -1
dic

// 삭제
dic.removeValue(forKey: "zero")
dic

// Set
var set: Set = Set<Int>() // 축약형 선언없이 이 형태로만 사용할 수 있다.
set.insert(10)
set.insert(20)
set.insert(20)
set

// 삭제
set.remove(20)
set



class Person1 {
    // 1. 아래와 같이 프로퍼티를 생성할 때 값을 초기화 할 수도 있고
    var name: String = ""
    var age: Int = 0

    // 2. 생성자를 통해서도 값을 초기화 시킬 수 있다.
    init() {}

    func introduce() {
        print("\(name) \(age)")
    }
}

// Person 클래스 인스턴스 생성
//var person = Person1()


class Person2 {
    var name: String
    var age: Int

    // 2. 생성자를 통해서도 값을 초기화 시킬 수 있다.
    init(name: String, age: Int) {
        self.name = name
        self.age = age
    }

    func introduce() {
        print("\(name) \(age)")
    }
}

// Person 클래스 인스턴스 생성
var person = Person2(name: "B", age: 25)
