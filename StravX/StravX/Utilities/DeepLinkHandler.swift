//
//  DeepLinkHandler.swift
//  StravX
//
//  Created by Claude Code
//  Copyright © 2026 StravX. All rights reserved.
//

import Foundation
import SwiftUI

enum DeepLink: Equatable {
    case joinTeam(code: String)
    case joinCompetition(id: String)
    case none
}

@Observable
class DeepLinkHandler {
    var activeDeepLink: DeepLink = .none

    /// Parse une URL et retourne le DeepLink correspondant
    func handleURL(_ url: URL) -> DeepLink {
        guard url.scheme == "stravx" else {
            return .none
        }

        let path = url.path
        let components = path.components(separatedBy: "/").filter { !$0.isEmpty }

        guard components.count >= 2 else {
            return .none
        }

        let action = components[0] // "join"
        let type = components[1] // "team" ou "competition"

        switch (action, type) {
        case ("join", "team"):
            if components.count >= 3 {
                let code = components[2]
                print("📲 Deep link: Rejoindre team avec code \(code)")
                return .joinTeam(code: code)
            }

        case ("join", "competition"):
            if components.count >= 3 {
                let id = components[2]
                print("📲 Deep link: Rejoindre compétition \(id)")
                return .joinCompetition(id: id)
            }

        default:
            break
        }

        return .none
    }

    /// Active un deep link pour qu'il soit traité par l'UI
    func activateDeepLink(_ deepLink: DeepLink) {
        activeDeepLink = deepLink
    }

    /// Réinitialise le deep link actif
    func clearDeepLink() {
        activeDeepLink = .none
    }
}
