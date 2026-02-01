# StravX - Release Notes v1.1

## 📱 Version Information
- **Version**: 1.1
- **Build**: 2
- **Date**: 1er Février 2026
- **Previous Version**: 1.0 (Build 1)

---

## 🆕 Nouvelles Fonctionnalités

### 1. 🎨 Mode Sombre
- Interface adaptative avec 3 modes : Automatique, Clair, Sombre
- Respect des préférences système
- Paramétrage dans les Réglages de l'app

### 2. 👥 Système Social (Following)
- **Suivez vos amis** : Découvrez et suivez d'autres athlètes
- **Profils publics** : Consultez les statistiques et exploits de vos amis
- **Feed d'activités** : Voyez les activités récentes des personnes suivies
- **Paramètres de confidentialité** :
  - Profil public/privé
  - Autorisation des followers
- **3 onglets** : Following, Followers, Découvrir

### 3. 🔔 Notifications Push
- **Alertes de territoire** : Soyez notifié quand vos zones sont attaquées ou perdues
- **Progression** : Notifications de badges débloqués et montées de niveau
- **Rappels quotidiens** : Encouragements pour maintenir votre série d'activités
- **Social** : Notification quand quelqu'un vous suit
- **Contrôle total** : Activez/désactivez dans les Réglages

---

## 🔧 Améliorations Techniques

### Optimisations
- **Batterie** : Réduction de 50% de la consommation GPS en arrière-plan
- **Performance** : Mode économie activé automatiquement hors activité
- **Localisation** : Précision adaptative (haute précision uniquement pendant le tracking)

### Corrections de bugs
- Fix : Warnings de compilation résolus
- Fix : API deprecated mise à jour (iOS 17+)
- Fix : Gestion améliorée de la mémoire
- Fix : Sauvegarde correcte des données utilisateur

### Base de données
- Ajout du champ `userID` aux activités pour le système social
- Tables `followingIDs` et `followerIDs` pour les relations sociales
- Historique complet des activités accessible aux amis

---

## 🔐 Permissions et Confidentialité

### Nouvelles permissions requises
- **Notifications** : Pour les alertes de territoire et encouragements
  - Description : "StravX vous envoie des notifications pour vous alerter quand vos territoires sont attaquués, quand vous débloquez des badges, et pour vos rappels d'activité quotidienne."

### Permissions existantes (inchangées)
- ✅ Localisation "Pendant l'utilisation"
- ✅ Localisation "Toujours" (optionnel, pour tracking en arrière-plan)
- ✅ Mouvement (pour améliorer précision)

### Confidentialité renforcée
- Contrôle total sur la visibilité du profil
- Paramètres pour bloquer les followers
- Aucune donnée partagée avec des tiers
- Politique de confidentialité : https://jeffchoux.github.io/StravX/privacy-policy.html

---

## 📊 Métriques de Qualité

### Build Status
- ✅ **Build Release** : SUCCÈS
- ⚠️ **Warnings** : 3 mineurs (non bloquants)
- ❌ **Erreurs** : 0

### Tests
- ✅ Compilation Release OK
- ✅ Toutes les icônes présentes
- ✅ Permissions configurées correctement
- ✅ Info.plist valide
- ✅ Deep linking fonctionnel

### Compatibilité
- **iOS Minimum** : 17.0+
- **Devices** : iPhone, iPad
- **Orientations** : Portrait, Paysage

---

## 📝 Notes pour Review Apple

### Points d'attention
1. **Background Location** : Utilisé uniquement pendant les activités sportives actives
2. **Notifications** : Permission demandée uniquement si activée dans Réglages
3. **Social Features** : Aucune modération requise (profils privés par défaut)
4. **No In-App Purchases** : Application 100% gratuite
5. **No External SDKs** : Code 100% natif Swift/SwiftUI

### Conformité
- ✅ App Store Review Guidelines 2.3 (Performance)
- ✅ Guidelines 5.1.1 (Privacy - Data Collection)
- ✅ Guidelines 4.5 (Location Services)
- ✅ Guidelines 3.1 (Payments - Free app)

### Test Accounts
Aucun compte test requis - L'app fonctionne immédiatement après installation.

---

## 🎯 Roadmap Futur (v1.2+)

- [ ] Export des activités (GPX, TCX)
- [ ] Statistiques avancées par période
- [ ] Challenges mensuels automatiques
- [ ] Intégration Apple Health
- [ ] Apple Watch companion app

---

## 📞 Support

- **Email** : contact@stravx.dev
- **GitHub** : https://github.com/Jeffchoux/StravX
- **Privacy Policy** : https://jeffchoux.github.io/StravX/privacy-policy.html

---

**Développé avec ❤️ en Swift et SwiftUI**
