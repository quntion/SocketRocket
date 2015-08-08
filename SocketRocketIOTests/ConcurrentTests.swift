//
//  ConcurrentTests.swift
//  SocketRocket
//
//  Created by Mike Lewis on 8/7/15.
//
//

@testable import SocketRocketIO
import XCTest

class ConcurrentTests: XCTestCase {
    func testOnce_simple() {
        var once = Once()
        
        let e2 = expectationWithDescription("All done")
        
        let g = dispatch_group_create()
        let g2 = dispatch_group_create()
        
        dispatch_group_enter(g)
        dispatch_group_notify(g2, Queue.defaultGlobalQueue.queue) {
            e2.fulfill()
        }
        
        for bit in 0..<8 {
            let e = expectationWithDescription("Once filled")
            for _ in 0..<1000 {
                dispatch_group_enter(g2)
                dispatch_group_notify(g, Queue.defaultGlobalQueue.queue) {
                    once.doMaybe(bit, block: {
                        e.fulfill()
                    })
                    dispatch_group_leave(g2)
                }
            }
        }
        
        dispatch_group_leave(g)
        waitForExpectations()
    }

    func testPGroup_noerr() {
        var p = PGroup<Int>(queue: Queue.mainQueue)
        
        p.resolve(3)
        
        for i in 0..<20 {
            let e = self.expectationWithDescription("e \(i)")
            p.then { v in
                XCTAssertFalse(v.hasError)
                e.fulfill()
            }
        }
        
        self.waitForExpectations()
    }

    func testPGroup_after() {
        let p = PGroup<Int>(queue: Queue.mainQueue)

        for i in 0..<20 {
            let e = self.expectationWithDescription("e \(i)")
            p.then { v in
                XCTAssertFalse(v.hasError)
                e.fulfill()
                switch v {
                case let .Some(val):
                    XCTAssertEqual(val, 3)
                default:
                    XCTFail()
                }
            }
        }

        p.resolve(3)

        self.waitForExpectations()
    }
    
    func testPGroup_calledOnce() {
        let p = PGroup<Int>(queue: Queue.mainQueue)
        
        for i in 0..<20 {
            let e = self.expectationWithDescription("e \(i)")
            p.then { v in
                switch v {
                case let .Some(val):
                    XCTAssertEqual(val, 3)
                default:
                    XCTFail()
                }
                e.fulfill()
            }
        }
        
        
        p.resolve(3)
        p.resolve(4)
        p.reject(Error.Canceled)
        
        self.waitForExpectations()
    }
    
    func testPGroup_canceled() {
        var p = PGroup<Int>(queue: Queue.mainQueue)
        
        for i in 0..<20 {
            let e = self.expectationWithDescription("e \(i)")
            p.then { v in
                switch v {
                case .Error(Error.Canceled):
                    break
                default:
                    XCTFail()
                }
                e.fulfill()
            }
        }
        
        p.cancel()

        p.resolve(3)
        p.resolve(4)
        p.reject(Error.Canceled)
        
        self.waitForExpectations()
    }
}
