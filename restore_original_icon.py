#!/usr/bin/env python3

import os
from PIL import Image
import json

def generate_icons_from_original():
    """Génère toutes les icônes à partir de l'icône originale StravX"""

    # Charger l'icône originale
    original_path = "/Users/jeff/Desktop/StravX_Final/original_icon.png"
    if not os.path.exists(original_path):
        print("❌ Icône originale non trouvée!")
        return

    print("🎨 Chargement de votre belle icône originale...")
    original_icon = Image.open(original_path)

    # Convertir en RGBA si nécessaire
    if original_icon.mode != 'RGBA':
        original_icon = original_icon.convert('RGBA')

    # Si l'image n'est pas carrée, la recadrer
    width, height = original_icon.size
    if width != height:
        size = min(width, height)
        left = (width - size) // 2
        top = (height - size) // 2
        original_icon = original_icon.crop((left, top, left + size, top + size))

    # Redimensionner à 1024x1024 pour avoir une base de haute qualité
    base_icon = original_icon.resize((1024, 1024), Image.Resampling.LANCZOS)

    # Chemin de destination
    assets_path = "/Users/jeff/Desktop/StravX_Final/StravX/StravX/Assets.xcassets"
    icon_path = os.path.join(assets_path, "AppIcon.appiconset")

    if not os.path.exists(icon_path):
        os.makedirs(icon_path)

    # Tailles requises pour iOS
    ios_sizes = [
        (20, 2), (20, 3),    # Notifications
        (29, 2), (29, 3),    # Settings
        (40, 2), (40, 3),    # Spotlight
        (60, 2), (60, 3),    # App
        (20, 1), (29, 1), (40, 1),  # iPad specific
        (76, 1), (76, 2),    # iPad App
        (83.5, 2),           # iPad Pro
        (1024, 1),           # App Store
    ]

    contents = {
        "images": [],
        "info": {
            "author": "xcode",
            "version": 1
        }
    }

    print("🔄 Génération de toutes les tailles...")

    for base_size, scale in ios_sizes:
        actual_size = int(base_size * scale)

        # Redimensionner avec antialiasing de haute qualité
        icon = base_icon.resize((actual_size, actual_size), Image.Resampling.LANCZOS)

        # Nom du fichier
        if base_size == 1024:
            filename = "icon-1024@1x.png"
            idiom = "ios-marketing"
            size_str = "1024x1024"
        else:
            filename = f"icon-{base_size}@{scale}x.png"
            if base_size == 83.5:
                filename = f"icon-83.5@{scale}x.png"

            # Déterminer l'idiom
            if base_size in [76, 83.5]:
                idiom = "ipad"
            elif base_size in [20, 29, 40] and scale == 1:
                idiom = "ipad"
            else:
                idiom = "iphone"

            size_str = f"{base_size}x{base_size}"

        # Sauvegarder l'icône
        icon_file_path = os.path.join(icon_path, filename)
        icon.save(icon_file_path, "PNG", optimize=True, quality=95)
        print(f"   ✅ {filename} ({actual_size}x{actual_size})")

        # Ajouter à Contents.json
        contents["images"].append({
            "filename": filename,
            "idiom": idiom,
            "scale": f"{scale}x",
            "size": size_str
        })

    # Ajouter l'entrée pour iPad 20x20@2x
    contents["images"].insert(9, {
        "filename": "icon-20@2x.png",
        "idiom": "ipad",
        "scale": "2x",
        "size": "20x20"
    })

    # Ajouter l'entrée pour iPad 29x29@2x
    contents["images"].insert(11, {
        "filename": "icon-29@2x.png",
        "idiom": "ipad",
        "scale": "2x",
        "size": "29x29"
    })

    # Ajouter l'entrée pour iPad 40x40@2x
    contents["images"].insert(13, {
        "filename": "icon-40@2x.png",
        "idiom": "ipad",
        "scale": "2x",
        "size": "40x40"
    })

    # Sauvegarder Contents.json
    contents_path = os.path.join(icon_path, "Contents.json")
    with open(contents_path, 'w') as f:
        json.dump(contents, f, indent=2)

    print("\n✅ Contents.json généré")
    print("🎉 Votre belle icône originale a été restaurée !")
    print(f"📍 Emplacement: {icon_path}")

if __name__ == "__main__":
    print("🚀 Restauration de votre icône originale StravX...")
    print("=" * 50)
    try:
        generate_icons_from_original()
        print("\n" + "=" * 50)
        print("🎉 SUCCÈS ! Votre belle icône est de retour !")
        print("\n📱 PROCHAINES ÉTAPES :")
        print("1. Retournez dans Xcode")
        print("2. Clean Build Folder (Cmd+Shift+K)")
        print("3. Build (Cmd+B)")
        print("4. Votre belle icône originale sera visible !")
    except Exception as e:
        print(f"❌ Erreur: {e}")
        import traceback
        traceback.print_exc()