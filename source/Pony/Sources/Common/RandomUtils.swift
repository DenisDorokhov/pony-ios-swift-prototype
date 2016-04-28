//
// Created by Denis Dorokhov on 28/04/16.
// Copyright (c) 2016 Denis Dorokhov. All rights reserved.
//

import Foundation

class RandomUtils {

    static func randomIntFrom(from: Int, to: Int) -> Int {
        return from + Int(arc4random()) % (to - from + 1)
    }

    static func randomDoubleFrom(from: Double, to: Double) -> Double {
        return ((to - from) * (Double(rand()) / Double(RAND_MAX))) + from
    }

    static func randomBool() -> Bool {
        return randomIntFrom(0, to: 99) > 49
    }

    static func randomArrayElement<T>(array: [T]) -> T? {

        if array.count == 0 {
            return nil
        }

        let index = randomIntFrom(0, to: (array.count - 1))

        return array[index]
    }

    static func boolWithProbability(probability: Int) -> Bool {
        return randomIntFrom(1, to: 100) <= min(probability, 100)
    }

    static func shuffleArray<T>(array: [T]) -> [T] {

        var result: [T] = []
        var copy = array

        while (copy.count > 0) {
            let index: Int = Int(arc4random()) % copy.count
            result.append(copy[index])
            copy.removeAtIndex(index)
        }

        return result
    }

    static func uuid() -> String {
        return NSUUID().UUIDString
    }
}
