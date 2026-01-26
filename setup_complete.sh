#!/bin/bash
# Script de création COMPLÈTE du projet StravX
# Par Claude Code - 2026

set -e

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}╔═══════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   StravX - Setup Automatique Complet             ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════╝${NC}"
echo ""

PROJECT_DIR="/Users/jeff/Desktop/StravX_Final"
SOURCE_DIR="/Users/jeff/Desktop/StravX"

cd "$PROJECT_DIR"

echo -e "${YELLOW}📦 Copie des fichiers sources...${NC}"

# Créer structure propre
mkdir -p StravX/{Models,Views/{Activity,Map,Profile},Managers,Assets.xcassets}

# Copier tous les fichiers Swift
cp "$SOURCE_DIR/StravXApp.swift" StravX/
cp "$SOURCE_DIR/ContentView.swift" StravX/
cp "$SOURCE_DIR/Info.plist" StravX/
cp "$SOURCE_DIR/Models/Activity.swift" StravX/Models/
cp "$SOURCE_DIR/Managers/LocationManager.swift" StravX/Managers/
cp "$SOURCE_DIR/Views/Activity/"*.swift StravX/Views/Activity/
cp "$SOURCE_DIR/Views/Map/"*.swift StravX/Views/Map/
cp "$SOURCE_DIR/Views/Profile/"*.swift StravX/Views/Profile/

echo -e "${GREEN}✅ Fichiers copiés${NC}"

echo ""
echo -e "${BLUE}╔═══════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   ✅ SETUP TERMINÉ !                             ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}📋 PROCHAINES ÉTAPES :${NC}"
echo ""
echo -e "1. ${GREEN}Ouvre Xcode${NC}"
echo -e "   ${BLUE}File → New → Project → iOS App${NC}"
echo ""
echo -e "2. ${GREEN}Configuration :${NC}"
echo -e "   Product Name: ${YELLOW}StravX${NC}"
echo -e "   Team: ${YELLOW}Jeff CHOUX${NC}"
echo -e "   Organization Identifier: ${YELLOW}com.jf${NC}"
echo -e "   Bundle Identifier: ${YELLOW}com.jf.StravX${NC}"
echo -e "   Interface: ${YELLOW}SwiftUI${NC}"
echo -e "   Storage: ${YELLOW}SwiftData${NC}"
echo ""
echo -e "3. ${GREEN}Sauvegarde dans :${NC}"
echo -e "   ${BLUE}$PROJECT_DIR${NC}"
echo -e "   ${YELLOW}(Remplace le dossier StravX existant)${NC}"
echo ""
echo -e "4. ${GREEN}Les fichiers sont prêts dans :${NC}"
echo -e "   ${BLUE}$PROJECT_DIR/StravX/${NC}"
echo ""
echo -e "5. ${GREEN}Ajoute-les au projet Xcode${NC}"
echo ""
echo -e "${YELLOW}Tout est prêt ! 🚀${NC}"
echo ""
