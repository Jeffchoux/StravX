#!/usr/bin/env python3

import os
from PIL import Image, ImageDraw, ImageFont
import json

# Créer une icône de base avec un design simple
def create_base_icon(size=1024):
    """Crée l'icône de base StravX"""
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Fond gradient (orange vers rouge)
    for i in range(size):
        color_r = int(255 - (i / size) * 50)  # De 255 à 205
        color_g = int(107 - (i / size) * 50)   # De 107 à 57
        color_b = 53
        draw.rectangle([0, i, size, i+1], fill=(color_r, color_g, color_b, 255))

    # Cercle blanc pour le logo
    margin = size // 8
    draw.ellipse([margin, margin, size-margin, size-margin],
                 fill=(255, 255, 255, 255))

    # Dessiner un coureur stylisé
    center_x = size // 2
    center_y = size // 2
    runner_size = size // 4

    # Tête
    head_radius = runner_size // 4
    draw.ellipse([center_x - head_radius, center_y - runner_size,
                  center_x + head_radius, center_y - runner_size + head_radius*2],
                 fill=(255, 107, 53, 255))

    # Corps et jambes (forme de "S" pour suggérer le mouvement)
    draw.line([center_x, center_y - runner_size + head_radius*2,
               center_x + runner_size//3, center_y + runner_size//2],
              fill=(255, 107, 53, 255), width=size//20)
    draw.line([center_x + runner_size//3, center_y + runner_size//2,
               center_x - runner_size//3, center_y + runner_size],
              fill=(255, 107, 53, 255), width=size//20)

    # Bras
    draw.line([center_x, center_y - runner_size//3,
               center_x - runner_size//2, center_y],
              fill=(255, 107, 53, 255), width=size//25)
    draw.line([center_x, center_y - runner_size//3,
               center_x + runner_size//2, center_y - runner_size//2],
              fill=(255, 107, 53, 255), width=size//25)

    return img

# Tailles requises pour iOS
ios_sizes = [
    # iPhone
    (20, 2),   # 40x40
    (20, 3),   # 60x60
    (29, 2),   # 58x58
    (29, 3),   # 87x87
    (40, 2),   # 80x80
    (40, 3),   # 120x120
    (60, 2),   # 120x120
    (60, 3),   # 180x180
    # iPad
    (20, 1),   # 20x20
    (20, 2),   # 40x40
    (29, 1),   # 29x29
    (29, 2),   # 58x58
    (40, 1),   # 40x40
    (40, 2),   # 80x80
    (76, 1),   # 76x76
    (76, 2),   # 152x152
    (83.5, 2), # 167x167
    # App Store
    (1024, 1), # 1024x1024
]

def generate_all_icons():
    """Génère toutes les icônes nécessaires"""

    # Créer le dossier AppIcon.appiconset s'il n'existe pas
    assets_path = "/Users/jeff/Desktop/StravX_Final/StravX/StravX/Assets.xcassets"
    icon_path = os.path.join(assets_path, "AppIcon.appiconset")

    if not os.path.exists(icon_path):
        os.makedirs(icon_path)

    # Créer l'icône de base
    base_icon = create_base_icon(1024)

    # Générer toutes les tailles
    contents = {
        "images": [],
        "info": {
            "author": "xcode",
            "version": 1
        }
    }

    for base_size, scale in ios_sizes:
        actual_size = int(base_size * scale)

        # Redimensionner l'icône
        icon = base_icon.resize((actual_size, actual_size), Image.Resampling.LANCZOS)

        # Nom du fichier
        if base_size == 1024:
            filename = "icon-1024@1x.png"
            idiom = "ios-marketing"
            size_str = "1024x1024"
        else:
            filename = f"icon-{int(base_size)}@{scale}x.png"
            idiom = "ipad" if base_size in [76, 83.5] or (base_size == 20 and scale == 1) or (base_size == 29 and scale == 1) or (base_size == 40 and scale == 1) else "iphone"
            size_str = f"{int(base_size)}x{int(base_size)}"

        # Sauvegarder l'icône
        icon_file_path = os.path.join(icon_path, filename)
        icon.save(icon_file_path, "PNG")
        print(f"✅ Généré: {filename} ({actual_size}x{actual_size})")

        # Ajouter à Contents.json
        contents["images"].append({
            "filename": filename,
            "idiom": idiom,
            "scale": f"{scale}x",
            "size": size_str
        })

    # Ajouter les entrées pour iPad spécifiques
    # 76x76@2x pour iPad
    contents["images"].append({
        "filename": "icon-76@2x.png",
        "idiom": "ipad",
        "scale": "2x",
        "size": "76x76"
    })

    # 83.5x83.5@2x pour iPad Pro
    contents["images"].append({
        "filename": "icon-83.5@2x.png",
        "idiom": "ipad",
        "scale": "2x",
        "size": "83.5x83.5"
    })

    # Sauvegarder Contents.json
    contents_path = os.path.join(icon_path, "Contents.json")
    with open(contents_path, 'w') as f:
        json.dump(contents, f, indent=2)

    print(f"\n✅ Contents.json généré")
    print(f"📱 Toutes les icônes ont été générées dans:")
    print(f"   {icon_path}")

if __name__ == "__main__":
    print("🎨 Génération des icônes StravX...")
    try:
        generate_all_icons()
        print("\n🎉 SUCCÈS! Toutes les icônes ont été créées.")
        print("\n📱 PROCHAINE ÉTAPE:")
        print("1. Retournez dans Xcode")
        print("2. Clean Build Folder (Cmd+Shift+K)")
        print("3. Build (Cmd+B)")
        print("4. Les erreurs d'icônes devraient disparaître!")
    except Exception as e:
        print(f"❌ Erreur: {e}")
        print("\nVérifiez que Pillow est installé:")
        print("pip3 install Pillow")