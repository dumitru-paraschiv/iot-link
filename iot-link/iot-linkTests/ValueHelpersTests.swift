//
//  ValueHelpersTests.swift
//  iot-linkTests
//

import Testing
@testable import iot_link

@Suite("Shared value helpers")
struct ValueHelpersTests {

    @Test("Optional presence flags")
    func optionalPresence() {
        let some: Int? = 3
        let none: Int? = nil

        #expect(some.isSome && !some.isNone)
        #expect(none.isNone && !none.isSome)
    }

    @Test("Optional fallbacks: orFalse and orEmpty")
    func optionalFallbacks() {
        let noBool: Bool? = nil
        let noArray: [Int]? = nil

        #expect(noBool.orFalse == false)
        #expect((true as Bool?).orFalse == true)
        #expect(noArray.orEmpty == [])
        #expect(([1, 2] as [Int]?).orEmpty == [1, 2])
    }

    @Test("Collection.isNotEmpty and Bool.isFalse")
    func collectionAndBoolFlags() {
        #expect([1].isNotEmpty)
        #expect([Int]().isNotEmpty == false)
        #expect(false.isFalse)
        #expect(true.isFalse == false)
    }

    @Test("Sequence.unique keeps the first occurrence, preserving order")
    func sequenceUnique() {
        let values = [1, 2, 1, 3, 2]

        #expect(values.unique { $0 == $1 } == [1, 2, 3])
        #expect(values.unique(by: { $0 }) == [1, 2, 3])
    }

    @Test("Sequence.notContains")
    func sequenceNotContains() {
        #expect([1, 2, 3].notContains(4))
        #expect([1, 2, 3].notContains(2) == false)
    }

    @Test("String helpers")
    func stringHelpers() {
        #expect(String.space == " ")
        #expect("home".wrappedIntoBrackets == "[home]")
    }

    @Test("Array helpers")
    func arrayHelpers() {
        #expect([2, 3].prepending(1) == [1, 2, 3])
        #expect(["a", "b"].joined("-") == "a-b")
    }
}
