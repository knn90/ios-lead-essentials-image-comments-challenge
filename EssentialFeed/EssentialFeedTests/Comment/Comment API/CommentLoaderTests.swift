//
//  CommentLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Khoi Nguyen on 24/12/20.
//  Copyright © 2020 Essential Developer. All rights reserved.
//

import XCTest
import EssentialFeed

class RemoteCommentLoader {
	private let url: URL
	private let client: HTTPClient
	
	init(url: URL, client: HTTPClient) {
		self.url = url
		self.client = client
	}
	
	func load() {
		client.get(from: url) { _ in }
	}
}



class CommentLoaderTests: XCTestCase {
	func test_init_doesNotRequestComment() {
		let client = ClientSpy()
		_ = RemoteCommentLoader(url: anyURL(), client: client)
		
		XCTAssertTrue(client.requestedURLs.isEmpty, "Expected no requested url upon creation")
	}
	
	func test_load_requestsFromURL() {
		let url = anyURL()
		let client = ClientSpy()
		let sut = RemoteCommentLoader(url: url, client: client)
		
		sut.load()
		
		XCTAssertEqual(client.requestedURLs, [url])
	}
	
	// MARK: - Helpers
	class ClientSpy: HTTPClient {
		
		var requestedURLs: [URL] = []
		
		func get(from url: URL) {
			requestedURLs.append(url)
		}
		
		private class Task: HTTPClientTask {
			func cancel() {
				
			}
		}
		
		func get(from url: URL, completion: @escaping (HTTPClient.Result) -> Void) -> HTTPClientTask {
			requestedURLs.append(url)
			return Task()
		}
	}
}
