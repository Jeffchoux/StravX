//
//  ShareHelper.swift
//  StravX
//
//  Created by Claude Code
//  Copyright © 2026 StravX. All rights reserved.
//

import UIKit
import SwiftUI

class ShareHelper {
    // Domaine Vercel pour les Universal Links
    static let universalLinkDomain = "stravx-links.vercel.app"

    /// Partage un code d'invitation team via WhatsApp
    static func shareTeamToWhatsApp(team: Team) {
        let universalLink = "https://\(universalLinkDomain)/join/team/\(team.code)"
        let message = """
        🏃‍♂️ Rejoins ma team StravX !

        Team : \(team.name)

        👉 Clique ici pour rejoindre :
        \(universalLink)
        """

        shareToWhatsApp(message: message)
    }

    /// Partage une compétition via WhatsApp
    static func shareCompetitionToWhatsApp(competition: Competition) {
        let universalLink = "https://\(universalLinkDomain)/join/competition/\(competition.id.uuidString)"
        let message = """
        🏆 Rejoins ma compétition StravX !

        Compétition : \(competition.name)
        Type : \(competition.type.displayName)
        Métrique : \(competition.metric.displayName)

        👉 Clique ici pour rejoindre :
        \(universalLink)
        """

        shareToWhatsApp(message: message)
    }

    /// Partage un message via WhatsApp
    static func shareToWhatsApp(message: String) {
        let urlString = "whatsapp://send?text=\(message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"

        guard let url = URL(string: urlString) else { return }

        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            // WhatsApp n'est pas installé, utiliser le partage standard
            shareViaActivityController(message: message)
        }
    }

    /// Partage via UIActivityViewController (fallback)
    static func shareViaActivityController(message: String) {
        let activityVC = UIActivityViewController(
            activityItems: [message],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            // Pour iPad - éviter crash
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = rootVC.view
                popover.sourceRect = CGRect(x: rootVC.view.bounds.midX, y: rootVC.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            rootVC.present(activityVC, animated: true)
        }
    }

    /// Génère un Universal Link pour une team
    static func generateTeamDeepLink(team: Team) -> String {
        return "https://\(universalLinkDomain)/join/team/\(team.code)"
    }

    /// Génère un Universal Link pour une compétition
    static func generateCompetitionDeepLink(competition: Competition) -> String {
        return "https://\(universalLinkDomain)/join/competition/\(competition.id.uuidString)"
    }

    /// Génère un lien court pour affichage (sans https://)
    static func generateShortTeamLink(team: Team) -> String {
        return "\(universalLinkDomain)/join/team/\(team.code)"
    }

    /// Génère un lien court pour affichage (sans https://)
    static func generateShortCompetitionLink(competition: Competition) -> String {
        return "\(universalLinkDomain)/join/competition/\(competition.id.uuidString)"
    }
}

// MARK: - SwiftUI View Extension

extension View {
    /// Modifier pour partager vers WhatsApp
    func whatsAppShareButton(message: String, label: String = "Partager sur WhatsApp") -> some View {
        Button {
            ShareHelper.shareToWhatsApp(message: message)
        } label: {
            Label(label, systemImage: "phone.bubble.left.fill")
        }
    }
}
