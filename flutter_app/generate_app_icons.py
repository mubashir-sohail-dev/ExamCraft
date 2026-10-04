import os
from PIL import Image

def generate_icons():
    base_dir = os.path.dirname(os.path.abspath(__file__))
    logo_path = os.path.join(base_dir, "logo.png")
    res_dir = os.path.join(base_dir, "android", "app", "src", "main", "res")

    if not os.path.exists(logo_path):
        print(f"Error: logo.png not found at {logo_path}")
        return

    img = Image.open(logo_path).convert("RGBA")
    print(f"Loaded logo.png: size={img.size}")

    # Legacy icon sizes (ic_launcher.png)
    legacy_sizes = {
        "mipmap-mdpi": (48, 48),
        "mipmap-hdpi": (72, 72),
        "mipmap-xhdpi": (96, 96),
        "mipmap-xxhdpi": (144, 144),
        "mipmap-xxxhdpi": (192, 192),
    }

    # Adaptive foreground sizes (ic_launcher_foreground.png)
    foreground_sizes = {
        "mipmap-mdpi": (108, 108),
        "mipmap-hdpi": (162, 162),
        "mipmap-xhdpi": (216, 216),
        "mipmap-xxhdpi": (324, 324),
        "mipmap-xxxhdpi": (432, 432),
    }

    for folder, size in legacy_sizes.items():
        folder_path = os.path.join(res_dir, folder)
        os.makedirs(folder_path, exist_ok=True)

        # Save legacy ic_launcher.png
        resized = img.resize(size, Image.Resampling.LANCZOS)
        out_path = os.path.join(folder_path, "ic_launcher.png")
        resized.save(out_path, "PNG")
        print(f"Generated {out_path} ({size[0]}x{size[1]})")

    for folder, size in foreground_sizes.items():
        folder_path = os.path.join(res_dir, folder)
        os.makedirs(folder_path, exist_ok=True)

        # Create centered foreground image with padding for safe zone (72dp in 108dp canvas)
        canvas = Image.new("RGBA", size, (0, 0, 0, 0))
        target_icon_size = (int(size[0] * 0.72), int(size[1] * 0.72))
        resized_icon = img.resize(target_icon_size, Image.Resampling.LANCZOS)
        offset = ((size[0] - target_icon_size[0]) // 2, (size[1] - target_icon_size[1]) // 2)
        canvas.paste(resized_icon, offset, resized_icon)

        out_path = os.path.join(folder_path, "ic_launcher_foreground.png")
        canvas.save(out_path, "PNG")
        print(f"Generated {out_path} ({size[0]}x{size[1]})")

    # Create mipmap-anydpi-v26
    anydpi_dir = os.path.join(res_dir, "mipmap-anydpi-v26")
    os.makedirs(anydpi_dir, exist_ok=True)

    adaptive_xml = """<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
</adaptive-icon>
"""
    with open(os.path.join(anydpi_dir, "ic_launcher.xml"), "w", encoding="utf-8") as f:
        f.write(adaptive_xml)
    with open(os.path.join(anydpi_dir, "ic_launcher_round.xml"), "w", encoding="utf-8") as f:
        f.write(adaptive_xml)

    # Create values/ic_launcher_background.xml
    values_dir = os.path.join(res_dir, "values")
    os.makedirs(values_dir, exist_ok=True)

    bg_xml = """<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">#FFFFFF</color>
</resources>
"""
    with open(os.path.join(values_dir, "ic_launcher_background.xml"), "w", encoding="utf-8") as f:
        f.write(bg_xml)

    print("App icon generation complete!")

if __name__ == "__main__":
    generate_icons()
