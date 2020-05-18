//
//  ErrorNotifyingSpec.swift
//  LaunchDarklyTests
//
//  Copyright © 2019 Catamorphic Co. All rights reserved.
//

import Foundation
import Quick
import Nimble
@testable import LaunchDarkly

final class ErrorNotifierSpec: QuickSpec {

    struct Constants {
        static let errorObserverCount = 3
        static let errorIdentifier = "com.launchdarkly.test.errorNotifierSpec.errorIdentifier"
    }

    struct TestContext {
        var errorNotifier: ErrorNotifier
        var errorObservers = [ErrorObserver]()

        var nextErrorObserverOwner = ErrorOwnerMock()
        var nextErrorObserver: ErrorObserver

        var originalObserverCount = 0
        var observersPerOwner = 0

        fileprivate var errorMock: ErrorMock

        init() {
            errorNotifier = ErrorNotifier()
            nextErrorObserver = ErrorObserver(owner: nextErrorObserverOwner, errorHandler: nextErrorObserverOwner.handle)
            errorMock = ErrorMock(with: Constants.errorIdentifier)
        }

        init(observerCount: Int) {
            self.init()
            errorObservers = ErrorObserver.createObservers(count: observerCount)
            errorNotifier = ErrorNotifier(observers: errorObservers)
            originalObserverCount = errorObservers.count
            observersPerOwner = observerCount
        }

        init(ownerCount: Int, observersPerOwner: Int) {
            self.init()

            // create ownerCount owners, then observersPerOwner observers for each owner
            let owners = (0..<ownerCount).map { _ in ErrorOwnerMock() }
            owners.forEach { owner in
                errorObservers += ErrorObserver.createObservers(count: observersPerOwner, using: owner)
            }

            errorNotifier = ErrorNotifier(observers: errorObservers)
            originalObserverCount = errorObservers.count
            self.observersPerOwner = observersPerOwner
        }

        var ownerToRemove: ErrorOwnerMock? {
            let owners = errorNotifier.errorOwners
            guard !owners.isEmpty
            else {
                return nil
            }
            if owners.count <= 2 {
                return owners.last
            }
            return owners[owners.count / 2] //pick an owner near the middle
        }
    }

    override func spec() {
        initSpec()
        addSpec()
        removeObserversSpec()
        notifyObserversSpec()
    }

    private func initSpec() {
        var testContext: TestContext!
        describe("init") {
            context("without error observers") {
                beforeEach {
                    testContext = TestContext()
                }
                it("creates an empty observers list") {
                    expect(testContext.errorNotifier.errorObservers.isEmpty).to(beTrue())
                }
            }
        }
    }

    private func addSpec() {
        var testContext: TestContext!
        describe("addErrorObserver") {
            context("first observer") {
                beforeEach {
                    testContext = TestContext()
                    testContext.errorNotifier.addErrorObserver(testContext.nextErrorObserver)
                }
                it("adds the observer") {
                    expect(testContext.errorNotifier.errorObservers.count) == 1
                    expect(testContext.errorNotifier.errorObservers.last) == testContext.nextErrorObserver
                }
            }
            context("not the first observer") {
                beforeEach {
                    testContext = TestContext(observerCount: Constants.errorObserverCount)
                    testContext.errorNotifier.addErrorObserver(testContext.nextErrorObserver)
                }
                it("adds the observer") {
                    expect(testContext.errorNotifier.errorObservers.count) == Constants.errorObserverCount + 1
                    expect(testContext.errorNotifier.errorObservers.last) == testContext.nextErrorObserver
                }
            }
        }
    }

    private func removeObserversSpec() {
        var testContext: TestContext!
        var ownerToRemove: ErrorOwnerMock!
        describe("removeObservers") {
            context("observer owner is observing") {
                context("one observer") {
                    context("without other observers") {
                        beforeEach {
                            testContext = TestContext(ownerCount: 1, observersPerOwner: 1)
                            ownerToRemove = testContext.ownerToRemove!

                            testContext.errorNotifier.removeObservers(for: ownerToRemove)
                        }
                        it("empties the observer list") {
                            expect(testContext.errorNotifier.errorObservers.isEmpty).to(beTrue())
                        }
                    }
                    context("among other observers") {
                        beforeEach {
                            testContext = TestContext(ownerCount: 3, observersPerOwner: 1)
                            ownerToRemove = testContext.ownerToRemove!

                            testContext.errorNotifier.removeObservers(for: ownerToRemove)
                        }
                        it("removes the observer from the observer list") {
                            expect(testContext.errorNotifier.errorObservers.count) == testContext.originalObserverCount - testContext.observersPerOwner
                            expect(testContext.errorNotifier.observers(for: ownerToRemove).isEmpty).to(beTrue())
                        }
                    }
                }
                context("multiple observers") {
                    context("without other observers") {
                        beforeEach {
                            testContext = TestContext(ownerCount: 1, observersPerOwner: 3)
                            ownerToRemove = testContext.ownerToRemove!

                            testContext.errorNotifier.removeObservers(for: ownerToRemove)
                        }
                        it("empties the observer list") {
                            expect(testContext.errorNotifier.errorObservers.isEmpty).to(beTrue())
                        }
                    }
                    context("among other observers") {
                        beforeEach {
                            testContext = TestContext(ownerCount: 3, observersPerOwner: 3)
                            ownerToRemove = testContext.ownerToRemove!

                            testContext.errorNotifier.removeObservers(for: ownerToRemove)
                        }
                        it("removes the observer from the observer list") {
                            expect(testContext.errorNotifier.errorObservers.count) == testContext.originalObserverCount - testContext.observersPerOwner
                            expect(testContext.errorNotifier.observers(for: ownerToRemove).isEmpty).to(beTrue())
                        }
                    }
                }
            }
            context("observer owner is not observing") {
                beforeEach {
                    testContext = TestContext(ownerCount: 3, observersPerOwner: 3)
                    ownerToRemove = ErrorOwnerMock()

                    testContext.errorNotifier.removeObservers(for: ownerToRemove)
                }
                it("does nothing to the observer list") {
                    expect(testContext.errorNotifier.errorObservers.count) == testContext.originalObserverCount
                    expect(testContext.errorNotifier.observers(for: ownerToRemove).isEmpty).to(beTrue())
                }
            }
        }
    }

    private func notifyObserversSpec() {
        var testContext: TestContext!
        var ownerToRemove: ErrorOwnerMock!
        describe("notifyObservers") {
            context("observer owners all exist") {
                beforeEach {
                    testContext = TestContext(ownerCount: 3, observersPerOwner: 3)

                    testContext.errorNotifier.notifyObservers(of: testContext.errorMock)
                }
                it("notifies each observer") {
                    testContext.errorNotifier.errorOwners.forEach { owner in
                        expect(owner.errors.count) == testContext.observersPerOwner
                        owner.errors.forEach { expect(($0 as? ErrorMock)?.identifier) == Constants.errorIdentifier }
                    }
                }
            }
            context("an observer owner doesn't exist") {
                beforeEach {
                    testContext = TestContext(ownerCount: 3, observersPerOwner: 3)
                    ownerToRemove = testContext.ownerToRemove!
                    testContext.errorNotifier.erase(owner: ownerToRemove)

                    testContext.errorNotifier.notifyObservers(of: testContext.errorMock)
                }
                it("notifies existing owner observers") {
                    testContext.errorNotifier.errorOwners.forEach { owner in
                        if owner === ownerToRemove {
                            expect(owner.errors.count) == 0
                        } else {
                            expect(owner.errors.count) == testContext.observersPerOwner
                            owner.errors.forEach { expect(($0 as? ErrorMock)?.identifier) == Constants.errorIdentifier }
                        }
                    }
                }
            }
        }
    }
}

extension ErrorNotifier {
    var errorOwners: [ErrorOwnerMock] { errorObservers.compactMap { $0.owner as? ErrorOwnerMock } }
    func observers(for owner: ErrorOwnerMock) -> [ErrorObserver] {
        errorObservers.filter { $0.owner === owner }
    }
}

private struct ErrorMock: Error {
    let identifier: String

    init(with identifier: String) {
        self.identifier = identifier
    }
}
