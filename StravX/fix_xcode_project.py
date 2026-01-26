#!/usr/bin/env python3
"""
Script pour ajouter automatiquement tous les fichiers Swift au projet Xcode
"""

import os
import uuid

# Chemin du projet
project_path = "StravX.xcodeproj/project.pbxproj"

# Liste des fichiers à ajouter
files_to_add = [
    ("StravX/Managers/LocationManager.swift", "Managers"),
    ("StravX/Models/Activity.swift", "Models"),
    ("StravX/Views/Activity/ActivityDetailView.swift", "Views/Activity"),
    ("StravX/Views/Activity/NewActivityView.swift", "Views/Activity"),
    ("StravX/Views/Activity/ActivityView.swift", "Views/Activity"),
    ("StravX/Views/Map/MapView.swift", "Views/Map"),
    ("StravX/Views/Profile/SettingsView.swift", "Views/Profile"),
    ("StravX/Views/Profile/ProfileView.swift", "Views/Profile"),
    ("StravX/Info.plist", "StravX"),
]

print("🔧 Ajout automatique des fichiers au projet Xcode...")

# Lire le fichier projet
with open(project_path, 'r') as f:
    content = f.read()

# Générer des UUIDs uniques pour chaque fichier
file_refs = []
build_files = []

for file_path, group in files_to_add:
    file_ref_uuid = str(uuid.uuid4()).replace('-', '')[:24].upper()
    build_file_uuid = str(uuid.uuid4()).replace('-', '')[:24].upper()

    filename = os.path.basename(file_path)

    file_refs.append(f"\t\t{file_ref_uuid} /* {filename} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {filename}; sourceTree = \"<group>\"; }};\n")

    if filename.endswith('.swift'):
        build_files.append(f"\t\t{build_file_uuid} /* {filename} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref_uuid} /* {filename} */; }};\n")

print(f"✅ {len(file_refs)} fichiers préparés")
print("📝 Modification du fichier projet...")

# Trouver où insérer les références
begin_section = "/* Begin PBXBuildFile section */"
if begin_section in content:
    pos = content.find(begin_section) + len(begin_section) + 1
    content = content[:pos] + ''.join(build_files) + content[pos:]
    print("✅ Build files ajoutés")

begin_section = "/* Begin PBXFileReference section */"
if begin_section in content:
    pos = content.find(begin_section) + len(begin_section) + 1
    content = content[:pos] + ''.join(file_refs) + content[pos:]
    print("✅ File references ajoutés")

# Sauvegarder
with open(project_path, 'w') as f:
    f.write(content)

print("✅ Projet Xcode modifié avec succès !")
print("\n🚀 Rouvre Xcode maintenant :")
print("   open StravX.xcodeproj")
