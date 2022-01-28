import Foundation

// Function
func sum(a: Int, b: Int) -> Int {
    return a+b
}

sum(a: 3, b: 5)

// 함수 매개변수의 기본값
// 매개변수의 기본값을 지정해두면 함수 호출시 파라미터로 전달 안해도 된다.
func greeting(friend: String, me: String = "B") {
    print("friend: \(friend) me: \(me)")
}

greeting(friend: "A")

// 함수 전달인자 레이블
// 매개변수 역할 명확 -> 코드 가독성 높
// 레이블 사용 원치 않으면 와일드카드 키워드 _ 사용할 수 있다.
func  sendMessage(from myName: String, to name: String) -> String {
    return "hello \(name)! I am \(myName)"
}

sendMessage(from: "B", to: "A")

// Swift에서는 매개변수로 값이 몇 개 들어올지 모를때, 가변 매개변수를 사용할 수 있다.
// 가변 매개변수는 0개 이상의 값을 받아올 수 있고, 가변 매개변수 값은 함수처럼 사용할 수 있다.
// 함수마다 가변 매개변수는 한 개만 가질 수 있다.
func  sendMessage2(me: String, friends: String...) -> String {
    return "hello \(friends)! I am \(me)"
}

sendMessage2(me: "B", friends: "A", "C", "D")

// if 문
let age = 25
if age > 19 {
    print("으른")
}
// Switch
// For
// Swift에선 For in

// while
// repeat while
