//
//  OpenGraphTests.swift
//  Yep
//
//  Created by NIX on 16/4/28.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import XCTest
@testable import Yep

final class OpenGraphTests: XCTestCase {

    func testBaiduOpenGraph() {

        let baiduURL = NSURL(string: "http://www.baidu.com")!

        let expectation = expectationWithDescription("baidu open graph")

        openGraphWithURL(baiduURL, failureHandler: nil) { openGraph in

            print("baidu openGraph: \(openGraph)")
            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(5, handler: nil)

        XCTAssert(true, "Pass")
    }

    func testItunesOpenGraph() {

        // 单曲
        let iTunesURL = NSURL(string: "https://itunes.apple.com/cn/album/hello-single/id1051365605?i=1051366040&l=en")!

        let queryItem = NSURLQueryItem(name: "at", value: "1010l9k7")

        let expectation = expectationWithDescription("iTunes open graph")

        openGraphWithURL(iTunesURL, failureHandler: nil) { openGraph in

            print("iTunes openGraph: \(openGraph)")

            if openGraph.URL.yeptests_containsQueryItem(queryItem) {
                expectation.fulfill()
            }
        }

        waitForExpectationsWithTimeout(10, handler: nil)
        
        XCTAssert(true, "Pass")
    }
}

