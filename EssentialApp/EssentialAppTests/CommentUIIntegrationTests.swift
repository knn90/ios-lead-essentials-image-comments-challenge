//
//  CommentUIIntegrationTests.swift
//  EssentialFeediOSTests
//
//  Created by Khoi Nguyen on 30/12/20.
//  Copyright © 2020 Essential Developer. All rights reserved.
//

import XCTest
import EssentialFeediOS
import EssentialFeed
import UIKit
import EssentialApp

class CommentUIIntegrationTests: XCTestCase {
	
	func test_loadView_hasLocalizedTitle() {
		let (sut, _) = makeSUT()
		XCTAssertEqual(sut.title, localized("COMMENT_VIEW_TITLE"))
	}
	
	func test_loadCommentAction_requestsCommentFromLoader() {
		let (sut, loader) = makeSUT()
		XCTAssertEqual(loader.loadCallCount, 0, "Expected no loading request before the view is loaded")
		
		sut.loadViewIfNeeded()
		XCTAssertEqual(loader.loadCallCount, 1, "Expected a request once the view is loaded")
		
		sut.simulateUserInititateCommentReload()
		XCTAssertEqual(loader.loadCallCount, 2, "Expected another request once user initiates a load")
		
		sut.simulateUserInititateCommentReload()
		XCTAssertEqual(loader.loadCallCount, 3, "Expected a third request once user initiates another load")
	}
	
	func test_loadingCommentIndicator_isVisibleWhileLoadingComment() {
		let (sut, loader) = makeSUT()
		
		sut.loadViewIfNeeded()
		XCTAssertTrue(sut.isShowingLoadingIndicator, "Expected loading indicator once view is loaded")
	
		loader.completeCommentLoading(at: 0)
		XCTAssertFalse(sut.isShowingLoadingIndicator, "Expected no loading indicator once loading is completed")
		
		sut.simulateUserInititateCommentReload()
		XCTAssertTrue(sut.isShowingLoadingIndicator, "Expected loading indicator once user intiates a reload")
		
		loader.completeCommentLoadingWithError(at: 1)
		XCTAssertFalse(sut.isShowingLoadingIndicator, "Expected no loading indicator once user intitiated reload failures")
	}
	
	func test_loadCommentCompletion_rendersSuccessfullyLoadedComment() {
		let comment0 = makeComment(message: "a messages", createAt: Date(), author: "an author")
		let comment1 = makeComment(message: "another messages", createAt: Date(), author: "another author")
		let comment2 = makeComment(message: "a third messages", createAt: Date(), author: "a third  author")
		let comment3 = makeComment(message: "a fourth messages", createAt: Date(), author: "a fourth author")
		
		let (sut, loader) = makeSUT()
		
		sut.loadViewIfNeeded()
		assertThat(sut, isRendering: [])
		
		loader.completeCommentLoading(with: [comment0.model])
		assertThat(sut, isRendering: [comment0.presentableModel])
		
		loader.completeCommentLoading(with: [comment0.model, comment1.model, comment2.model, comment3.model])
		assertThat(sut, isRendering: [comment0.presentableModel, comment1.presentableModel, comment2.presentableModel, comment3.presentableModel])
	}
	
	func test_loadCommentCompletion_doesNotAlterCurrentRenderingStateOnError() {
		let comment0 = makeComment(message: "a messages", createAt: Date(), author: "an author")
		let (sut, loader) = makeSUT()
		
		sut.loadViewIfNeeded()
		loader.completeCommentLoading(with: [comment0.model], at: 0)
		assertThat(sut, isRendering: [comment0.presentableModel])
		
		sut.simulateUserInititateCommentReload()
		loader.completeCommentLoadingWithError(at: 1)
		assertThat(sut, isRendering: [comment0.presentableModel])
	}
	
	func test_errorView_rendersErrorViewOnLoaderFailure() {
		let (sut, loader) = makeSUT()
		sut.loadViewIfNeeded()
		XCTAssertFalse(sut.isShowingErrorView, "Expected no error view when view is loaced")
		
		loader.completeCommentLoadingWithError(at: 0)
		XCTAssertTrue(sut.isShowingErrorView, "Expected error view when load failures")
		
		sut.simulateUserInititateCommentReload()
		XCTAssertFalse(sut.isShowingErrorView, "Expected no error message when user initiates reload")
		
		loader.completeCommentLoading(with: [], at: 1)
		XCTAssertFalse(sut.isShowingErrorView, "Expected no error when reload completes successfully")
		
		sut.simulateUserInititateCommentReload()
		loader.completeCommentLoadingWithError(at: 2)
		XCTAssertTrue(sut.isShowingErrorView, "Expected error view when load failures")
		sut.simulateUserTapOnErrorView()
		XCTAssertFalse(sut.isShowingErrorView, "Expected no error when user tap on error view")
	}
	
	func test_deinit_cancelsLoadOnViewDisappearance() {
		let loader = LoaderSpy()
		var sut: CommentViewController?
		autoreleasepool {
			sut = CommentUIComposer.commentComposeWith(loader: loader)
			sut?.loadViewIfNeeded()
		}
		
		XCTAssertEqual(loader.cancelCallCount, 0)
		sut = nil
		XCTAssertEqual(loader.cancelCallCount, 1)
	}
	
	func test_loadCommentCompletion_dispatchesFromBackgroundToMainThread() {
		let (sut, loader) = makeSUT()
		sut.loadViewIfNeeded()
		
		let exp = expectation(description: "Wait for background queue")
		DispatchQueue.global().async {
			loader.completeCommentLoading(at: 0)
			exp.fulfill()
		}
		wait(for: [exp], timeout: 1.0)
	}
	
	// MARK: - Helpers
	private func makeSUT(file: StaticString = #file, line: UInt = #line) -> (sut: CommentViewController, loader: LoaderSpy) {
		let loader = LoaderSpy()
		let sut = CommentUIComposer.commentComposeWith(loader: loader)
		
		trackForMemoryLeaks(sut, file: file, line: line)
		trackForMemoryLeaks(loader, file: file, line: line)
		
		return (sut, loader)
	}
	
	private class LoaderSpy: CommentLoader {
		
		var loadCallCount: Int {
			return completions.count
		}
		
		private(set) var cancelCallCount = 0
		private var completions = [(CommentLoader.Result) -> Void]()
		
		private struct Task: CommentLoaderTask {
			let callback: () -> Void
			func cancel() {
				callback()
			}
		}
		
		func load(completion: @escaping (CommentLoader.Result) -> Void) -> CommentLoaderTask {
			completions.append(completion)
			return Task { [weak self] in
				self?.cancelCallCount += 1
			}
		}
		
		func completeCommentLoading(with comments: [Comment] = [], at index: Int = 0) {
			completions[index](.success(comments))
		}
		
		func completeCommentLoadingWithError(at index: Int = 0) {
			completions[index](.failure(NSError(domain: "error", code: 0)))
		}
	}
	
	private func makePresentableComment(comment: Comment) -> PresentableComment {
		return CommentViewModel(comments: [comment]).presentableComments[0]
	}
	
	private func makeComment(message: String, createAt: Date, author: String) -> (model: Comment, presentableModel: PresentableComment) {
		let id = UUID()
		let model = Comment(id: id, message: message, createAt: createAt, author: CommentAuthor(username: author))
		let presentableModel = makePresentableComment(comment: model)
		return (model, presentableModel)
	}
}
