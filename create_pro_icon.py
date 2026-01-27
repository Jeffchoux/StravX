#!/usr/bin/env python3

import os
from PIL import Image, ImageDraw, ImageFont
import json
import math

def create_professional_icon(size=1024):
    """Crée une icône professionnelle pour StravX"""
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Fond gradient dynamique (orange vers rouge sportif)
    for y in range(size):
        # Gradient diagonal pour plus de dynamisme
        for x in range(size):
            # Calcul de la position dans le gradient
            gradient_pos = (x + y) / (size * 2)

            # Couleurs du gradient : Orange (FF6B35) vers Rouge sportif (FF3B30)
            r = int(255)
            g = int(107 - gradient_pos * 48)  # De 107 à 59
            b = int(53 - gradient_pos * 23)    # De 53 à 30

            draw.point((x, y), fill=(r, g, b, 255))

    # Cercle blanc semi-transparent pour le fond du logo
    margin = size // 6
    circle_color = (255, 255, 255, 230)
    draw.ellipse([margin, margin, size-margin, size-margin],
                 fill=circle_color)

    # Dessiner le logo "S" stylisé pour StravX
    center_x = size // 2
    center_y = size // 2

    # Créer un "S" moderne et fluide
    s_width = size // 12
    s_color = (255, 107, 53)  # Orange StravX

    # Points pour le S stylisé (courbe Bézier simulée)
    points = []
    for i in range(50):
        t = i / 49
        # Courbe en S
        if t < 0.5:
            # Partie haute du S
            angle = math.pi * (1 - t * 2)
            x = center_x + math.cos(angle) * size // 4 + size // 8
            y = center_y - size // 4 + t * size // 2
        else:
            # Partie basse du S
            angle = math.pi * ((t - 0.5) * 2)
            x = center_x - math.cos(angle) * size // 4 - size // 8
            y = center_y - size // 4 + t * size // 2

        points.append((x, y))

    # Dessiner le S avec épaisseur
    for i in range(len(points) - 1):
        draw.line([points[i], points[i+1]], fill=s_color, width=s_width)

    # Ajouter des points de vitesse (effet de mouvement)
    speed_lines = [
        (center_x - size // 3, center_y - size // 6),
        (center_x - size // 3, center_y),
        (center_x - size // 3, center_y + size // 6),
    ]

    for i, (x, y) in enumerate(speed_lines):
        length = size // 4 - i * size // 20
        opacity = 200 - i * 40
        draw.line([(x, y), (x - length, y)],
                 fill=(255, 107, 53, opacity),
                 width=s_width // 2 - i * 2)

    # Ajouter une ombre portée subtile
    shadow_img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow_img)

    # Ombre du cercle principal
    shadow_offset = size // 50
    shadow_draw.ellipse([margin + shadow_offset,
                        margin + shadow_offset,
                        size - margin + shadow_offset,
                        size - margin + shadow_offset],
                       fill=(0, 0, 0, 50))

    # Combiner l'ombre avec l'image principale
    final_img = Image.alpha_composite(shadow_img, img)

    return final_img

def generate_all_pro_icons():
    """Génère toutes les icônes avec le nouveau design"""

    assets_path = "/Users/jeff/Desktop/StravX_Final/StravX/StravX/Assets.xcassets"
    icon_path = os.path.join(assets_path, "AppIcon.appiconset")

    if not os.path.exists(icon_path):
        os.makedirs(icon_path)

    # Créer l'icône professionnelle
    print("🎨 Création de l'icône professionnelle StravX...")
    base_icon = create_professional_icon(1024)

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
        print(f"✅ Généré: {filename} ({actual_size}x{actual_size})")

        # Ajouter à Contents.json
        contents["images"].append({
            "filename": filename,
            "idiom": idiom,
            "scale": f"{scale}x",
            "size": size_str
        })

    # Sauvegarder Contents.json
    contents_path = os.path.join(icon_path, "Contents.json")
    with open(contents_path, 'w') as f:
        json.dump(contents, f, indent=2)

    print(f"\n✅ Contents.json généré")
    print(f"🎨 Icône professionnelle créée avec succès !")
    print(f"📍 Emplacement: {icon_path}")

    # Sauvegarder aussi l'icône principale sur le bureau pour référence
    desktop_icon = os.path.join("/Users/jeff/Desktop", "StravX_Icon_1024.png")
    base_icon.save(desktop_icon, "PNG", optimize=True, quality=95)
    print(f"\n📱 Icône principale sauvegardée sur le Bureau : StravX_Icon_1024.png")

if __name__ == "__main__":
    print("🚀 Génération de l'icône professionnelle StravX...")
    print("=" * 50)
    try:
        generate_all_pro_icons()
        print("\n" + "=" * 50)
        print("🎉 SUCCÈS ! Votre nouvelle icône est prête !")
        print("\n📱 PROCHAINES ÉTAPES :")
        print("1. Retournez dans Xcode")
        print("2. Clean Build Folder (Cmd+Shift+K)")
        print("3. Build (Cmd+B)")
        print("4. L'icône professionnelle sera visible !")
    except Exception as e:
        print(f"❌ Erreur: {e}")