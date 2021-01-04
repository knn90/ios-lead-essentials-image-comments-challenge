//
//  CommentViewControllerTests.swift
//  EssentialFeediOSTests
//
//  Created by Khoi Nguyen on 30/12/20.
//  Copyright © 2020 Essential Developer. All rights reserved.
//

import XCTest
import EssentialFeediOS
import EssentialFeed
import UIKit


public class CommentViewController: UITableViewController {
	private var loader: CommentLoader?
	
	convenience init(loader: CommentLoader) {
		self.init()
		self.loader = loader
	}
	
	public override func viewDidLoad() {
		super.viewDidLoad()
		
		refreshControl = UIRefreshControl()
		refreshControl?.addTarget(self, action: #selector(load), for: .valueChanged)
		refreshControl?.beginRefreshing()
		load()
	}
	
	@objc private func load() {
		loader?.load { [weak self]_ in
			self?.refreshControl?.endRefreshing()
		}
	}
}

class CommentViewControllerTests: XCTestCase {
	
	func test_init_doesNotLoadComment() {
		let (_, loader) = makeSUT()
		
		XCTAssertEqual(loader.loadCallCount, 0)
	}
	
	func test_viewDidLoad_loadsComment() {
		let (sut, loader) = makeSUT()
		
		sut.loadViewIfNeeded()
		
		XCTAssertEqual(loader.loadCallCount, 1)
	}
	
	func test_viewDidLoad_showsLoadingIndicator() {
		let (sut, _) = makeSUT()
		
		sut.loadViewIfNeeded()
		
		XCTAssertTrue(sut.isShowingLoadingIndicator)
	}
	
	func test_viewDidLoad_hidesLoadingIndicatorOnLoaderCompletion() {
		let (sut, loader) = makeSUT()
		
		sut.loadViewIfNeeded()
		loader.completeCommentLoading()
		
		XCTAssertFalse(sut.isShowingLoadingIndicator)
	}
	
	func test_userInitiatedCommentReload_loadComment() {
		let (sut, loader) = makeSUT()
		sut.loadViewIfNeeded()
		
		sut.simulateUserInititateCommentReload()
		XCTAssertEqual(loader.loadCallCount, 2)
		
		sut.simulateUserInititateCommentReload()
		XCTAssertEqual(loader.loadCallCount, 3)
	}
	
	func test_userInitiatedCommentReload_hidesLoadingIndicatorOnLoaderCompletion() {
		let (sut, loader) = makeSUT()
		sut.loadViewIfNeeded()
		
		sut.simulateUserInititateCommentReload()
		loader.completeCommentLoading()
		
		XCTAssertFalse(sut.isShowingLoadingIndicator)
	}
	
	// MARK: - Helpers
	private func makeSUT(file: StaticString = #file, line: UInt = #line) -> (sut: CommentViewController, loader: LoaderSpy) {
		let loader = LoaderSpy()
		let sut = CommentViewController(loader: loader)
		
		trackForMemoryLeaks(sut, file: file, line: line)
		trackForMemoryLeaks(loader, file: file, line: line)
		
		return (sut, loader)
	}
	func trackForMemoryLeaks(_ instance: AnyObject, file: StaticString = #filePath, line: UInt = #line) {
		addTeardownBlock { [weak instance] in
			XCTAssertNil(instance, "Instance should have been deallocated. Potential memory leak.", file: file, line: line)
		}
	}
	
	class LoaderSpy: CommentLoader {
		var loadCallCount: Int {
			return completions.count
		}
		var completions = [(CommentLoader.Result) -> Void]()
		func load(completion: @escaping (CommentLoader.Result) -> Void) {
			completions.append(completion)
		}
		
		func completeCommentLoading(at index: Int = 0) {
			completions[index](.success([]))
		}
	}
}

private extension CommentViewController {
	func simulateUserInititateCommentReload() {
		refreshControl?.simulatePullToRefresh()
	}
	
	var isShowingLoadingIndicator: Bool {
		return refreshControl?.isRefreshing == true
	}
}

private extension UIRefreshControl {
	func simulatePullToRefresh() {
		allTargets.forEach { target in
			actions(forTarget: target, forControlEvent: .valueChanged)?.forEach {
				(target as NSObject).perform(Selector($0))
			}
		}
	}
}

