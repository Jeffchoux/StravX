//
//  TeamManager.swift
//  StravX
//
//  Created by Claude Code
//  Copyright © 2026 StravX. All rights reserved.
//

import Foundation
import SwiftData
import Observation

@Observable
class TeamManager {
    // MARK: - Properties

    private var modelContext: ModelContext
    private var currentUser: User?

    // Cache
    var myTeams: [Team] = []
    var myCompetitions: [Competition] = []

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadCurrentUser()
    }

    // MARK: - User Management

    private func loadCurrentUser() {
        let descriptor = FetchDescriptor<User>()
        let users = (try? modelContext.fetch(descriptor)) ?? []
        currentUser = users.first
    }

    func getCurrentUser() -> User? {
        return currentUser
    }

    // MARK: - Team Management

    /// Crée une nouvelle team
    func createTeam(name: String) -> Team? {
        guard let user = currentUser else { return nil }

        let team = Team(name: name, creatorID: user.id.uuidString)
        modelContext.insert(team)

        // Ajouter la team à l'utilisateur
        var userTeams = user.teamList
        userTeams.append(team.id.uuidString)
        user.teamList = userTeams

        do {
            try modelContext.save()
            print("✅ Team created: \(team.name) with code: \(team.code)")
            loadMyTeams()
            return team
        } catch {
            print("❌ Error creating team: \(error)")
            return nil
        }
    }

    /// Rejoint une team avec un code
    func joinTeam(code: String) -> (success: Bool, message: String, team: Team?) {
        guard let user = currentUser else {
            return (false, "Utilisateur non trouvé", nil)
        }

        // Chercher la team par code
        let descriptor = FetchDescriptor<Team>(
            predicate: #Predicate { team in
                team.code == code
            }
        )

        guard let team = try? modelContext.fetch(descriptor).first else {
            return (false, "Code invalide", nil)
        }

        // Vérifier si déjà membre
        if team.memberIDs.contains(user.id.uuidString) {
            return (false, "Vous êtes déjà membre", team)
        }

        // Vérifier si la team est pleine
        guard team.addMember(user.id.uuidString) else {
            return (false, "Team complète (\(team.maxMembers) membres max)", nil)
        }

        // Ajouter la team à l'utilisateur
        var userTeams = user.teamList
        userTeams.append(team.id.uuidString)
        user.teamList = userTeams

        do {
            try modelContext.save()
            print("✅ Joined team: \(team.name)")
            loadMyTeams()
            return (true, "Bienvenue dans \(team.name) !", team)
        } catch {
            print("❌ Error joining team: \(error)")
            return (false, "Erreur lors de la sauvegarde", nil)
        }
    }

    /// Quitte une team
    func leaveTeam(_ team: Team) -> Bool {
        guard let user = currentUser else { return false }

        // Vérifier que ce n'est pas le créateur
        guard team.creatorID != user.id.uuidString else {
            print("❌ Cannot leave team: you are the creator")
            return false
        }

        // Retirer de la team
        _ = team.removeMember(user.id.uuidString)

        // Retirer de la liste de l'utilisateur
        var userTeams = user.teamList
        if let index = userTeams.firstIndex(of: team.id.uuidString) {
            userTeams.remove(at: index)
            user.teamList = userTeams
        }

        do {
            try modelContext.save()
            print("✅ Left team: \(team.name)")
            loadMyTeams()
            return true
        } catch {
            print("❌ Error leaving team: \(error)")
            return false
        }
    }

    /// Supprime une team (seulement le créateur)
    func deleteTeam(_ team: Team) -> Bool {
        guard let user = currentUser else { return false }
        guard team.creatorID == user.id.uuidString else {
            print("❌ Cannot delete team: you are not the creator")
            return false
        }

        // Retirer de tous les membres
        for memberID in team.memberIDs {
            if let member = fetchUser(by: memberID) {
                var memberTeams = member.teamList
                if let index = memberTeams.firstIndex(of: team.id.uuidString) {
                    memberTeams.remove(at: index)
                    member.teamList = memberTeams
                }
            }
        }

        modelContext.delete(team)

        do {
            try modelContext.save()
            print("✅ Team deleted: \(team.name)")
            loadMyTeams()
            return true
        } catch {
            print("❌ Error deleting team: \(error)")
            return false
        }
    }

    /// Charge les teams de l'utilisateur
    func loadMyTeams() {
        guard let user = currentUser else {
            myTeams = []
            return
        }

        let teamIDs = user.teamList
        var teams: [Team] = []

        for teamID in teamIDs {
            if let team = fetchTeam(by: teamID) {
                teams.append(team)
            }
        }

        myTeams = teams
    }

    /// Récupère une team par son ID
    private func fetchTeam(by id: String) -> Team? {
        guard let uuid = UUID(uuidString: id) else { return nil }

        let descriptor = FetchDescriptor<Team>(
            predicate: #Predicate { team in
                team.id == uuid
            }
        )

        return try? modelContext.fetch(descriptor).first
    }

    /// Récupère un utilisateur par son ID
    private func fetchUser(by id: String) -> User? {
        guard let uuid = UUID(uuidString: id) else { return nil }

        let descriptor = FetchDescriptor<User>(
            predicate: #Predicate { user in
                user.id == uuid
            }
        )

        return try? modelContext.fetch(descriptor).first
    }

    /// Récupère les membres d'une team
    func getTeamMembers(_ team: Team) -> [(id: String, username: String, stats: (distance: Double, activities: Int))] {
        var members: [(id: String, username: String, stats: (distance: Double, activities: Int))] = []

        for memberID in team.memberIDs {
            if let user = fetchUser(by: memberID) {
                members.append((
                    id: user.id.uuidString,
                    username: user.username,
                    stats: (distance: user.totalDistance, activities: user.totalActivities)
                ))
            }
        }

        return members
    }

    /// Génère un leaderboard pour une team
    func getTeamLeaderboard(_ team: Team, metric: CompetitionMetric = .distance) -> [LeaderboardEntry] {
        let members = getTeamMembers(team)

        var entries = members.map { member -> LeaderboardEntry in
            let score: Double
            switch metric {
            case .distance:
                score = member.stats.distance / 1000 // Convertir en km
            case .activities:
                score = Double(member.stats.activities)
            case .territories:
                if let user = fetchUser(by: member.id) {
                    score = Double(user.territoriesOwned)
                } else {
                    score = 0
                }
            case .xp:
                if let user = fetchUser(by: member.id) {
                    score = Double(user.totalXP)
                } else {
                    score = 0
                }
            }

            return LeaderboardEntry(
                id: member.id,
                name: member.username,
                score: score,
                rank: 0 // Sera calculé après tri
            )
        }

        // Trier par score décroissant
        entries.sort { $0.score > $1.score }

        // Assigner les rangs
        entries = entries.enumerated().map { index, entry in
            LeaderboardEntry(
                id: entry.id,
                name: entry.name,
                score: entry.score,
                rank: index + 1
            )
        }

        return entries
    }

    // MARK: - Competition Management

    /// Crée une nouvelle compétition
    func createCompetition(name: String, type: CompetitionType, metric: CompetitionMetric, duration: CompetitionDuration) -> Competition? {
        guard let user = currentUser else { return nil }

        let competition = Competition(
            name: name,
            creatorID: user.id.uuidString,
            type: type,
            metric: metric,
            duration: duration
        )

        modelContext.insert(competition)

        do {
            try modelContext.save()
            print("✅ Competition created: \(competition.name)")
            loadMyCompetitions()
            return competition
        } catch {
            print("❌ Error creating competition: \(error)")
            return nil
        }
    }

    /// Charge les compétitions de l'utilisateur
    func loadMyCompetitions() {
        guard let user = currentUser else {
            myCompetitions = []
            return
        }

        let descriptor = FetchDescriptor<Competition>()
        let allCompetitions = (try? modelContext.fetch(descriptor)) ?? []

        // Filtrer les compétitions où l'utilisateur est participant
        myCompetitions = allCompetitions.filter { competition in
            competition.participantIDs.contains(user.id.uuidString)
        }
    }
}
