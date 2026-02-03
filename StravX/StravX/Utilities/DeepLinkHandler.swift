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
    /// Supporte à la fois les Custom URL Schemes (stravx://) et les Universal Links (https://)
    func handleURL(_ url: URL) -> DeepLink {
        print("🔗 [DeepLinkHandler] Handling URL: \(url.absoluteString)")
        print("🔗 [DeepLinkHandler] Scheme: \(url.scheme ?? "nil"), Host: \(url.host ?? "nil"), Path: \(url.path)")

        // Supporter les deux formats:
        // 1. Custom URL: stravx://join/team/ABC123
        // 2. Universal Link: https://join-stravx.vercel.app/join/team/ABC123

        guard url.scheme == "stravx" || url.scheme == "https" || url.scheme == "http" else {
            print("❌ [DeepLinkHandler] Unsupported URL scheme: \(url.scheme ?? "nil")")
            return .none
        }

        // Pour Universal Links, vérifier que c'est bien notre domaine
        if url.scheme == "https" || url.scheme == "http" {
            guard let host = url.host,
                  (host == "stravx-links.vercel.app" || host.hasSuffix(".vercel.app") || host.contains("stravx")) else {
                print("❌ [DeepLinkHandler] Invalid host for Universal Link: \(url.host ?? "nil")")
                return .none
            }
        }

        let path = url.path
        let components = path.components(separatedBy: "/").filter { !$0.isEmpty }

        print("🔍 [DeepLinkHandler] Path components: \(components)")

        guard components.count >= 2 else {
            print("❌ [DeepLinkHandler] Not enough path components")
            return .none
        }

        let action = components[0] // "join"
        let type = components[1] // "team" ou "competition"

        switch (action, type) {
        case ("join", "team"):
            if components.count >= 3 {
                let code = components[2]
                print("✅ [DeepLinkHandler] Join team with code: \(code)")
                return .joinTeam(code: code)
            }

        case ("join", "competition"):
            if components.count >= 3 {
                let id = components[2]
                print("✅ [DeepLinkHandler] Join competition: \(id)")
                return .joinCompetition(id: id)
            }

        default:
            print("❌ [DeepLinkHandler] Unknown action/type: \(action)/\(type)")
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
