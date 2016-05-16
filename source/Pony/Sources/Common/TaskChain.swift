//
// Created by Denis Dorokhov on 16/05/16.
// Copyright (c) 2016 Denis Dorokhov. All rights reserved.
//

import Foundation

class TaskChain {

    typealias Task = (next: Void -> Void, cancel: Void -> Void) -> Void

    let maxConcurrentTasks: Int
    let runTaskImmediately: Bool

    private(set) var runningTasksCount = 0

    private var queue: [Task] = []
    private var running = false

    init(maxConcurrentTasks: Int = 1, runTaskImmediately: Bool = true) {
        assert(maxConcurrentTasks >= 1)
        self.maxConcurrentTasks = maxConcurrentTasks
        self.runTaskImmediately = runTaskImmediately
    }

    func addTask(task: Task) {
        queue.append(task)
        if runTaskImmediately {
            run()
        }
    }

    func removeAll() {
        queue.removeAll()
    }

    func run() {
        // Avoid recursion.
        if running {
            return
        }
        running = true
        while runningTasksCount < maxConcurrentTasks {
            if queue.count > 0 {
                runningTasksCount += 1
                queue.removeFirst()(next: {
                    self.runningTasksCount -= 1
                    self.run()
                }, cancel: {
                    self.runningTasksCount -= 1
                    self.removeAll()
                })
            } else {
                break
            }
        }
        running = false
    }
}
