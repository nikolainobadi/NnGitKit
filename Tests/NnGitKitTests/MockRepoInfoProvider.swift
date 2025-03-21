//
//  MockRepoInfoProvider.swift
//  NnGitKit
//
//  Created by Nikolai Nobadi on 3/21/25.
//

import Foundation
@testable import GitShellKit

final class MockRepoInfoProvider {
    private let details: String
    private let projectName: String
    private let visibility: RepoVisibility
    private let canUploadNonMainBranch: Bool
    
    init(projectName: String, details: String, visibility: RepoVisibility, canUploadNonMainBranch: Bool) {
        self.projectName = projectName
        self.details = details
        self.visibility = visibility
        self.canUploadNonMainBranch = canUploadNonMainBranch
    }
}


// MARK: - RepoInfoProvider
extension MockRepoInfoProvider: RepoInfoProvider {
    func getProjectName() throws -> String {
        return projectName
    }
    
    func getProjectDetails() throws -> String {
        return details
    }
    
    func getVisibility() throws -> RepoVisibility {
        return visibility
    }
    
    func canUploadFromNonMainBranch() throws -> Bool {
        return canUploadNonMainBranch
    }
}
