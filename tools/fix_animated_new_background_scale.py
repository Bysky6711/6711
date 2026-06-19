from pathlib import Path

OLD_BACKGROUNDS = [
    "assets/images/backgrounds/miasto.jpg",
    "assets/backgrounds/miasto.jpg",
    "assets/images/backgrounds/background.jpg",
    "assets/images/backgrounds/bg.jpg",
]


def find_class_block(text: str, class_name: str, start_pos: int = 0):
    start = text.find(f"class {class_name}", start_pos)
    if start == -1:
        return None
    brace = text.find("{", start)
    if brace == -1:
        return None
    depth = 0
    for i in range(brace, len(text)):
        if text[i] == "{":
            depth += 1
        elif text[i] == "}":
            depth -= 1
            if depth == 0:
                end = i + 1
                while end < len(text) and text[end] in " \t\r\n":
                    end += 1
                return start, end
    return None


def replace_class(text: str, class_name: str, replacement: str):
    block = find_class_block(text, class_name)
    if block is None:
        return text
    start, end = block
    return text[:start] + replacement.strip() + "\n\n" + text[end:]


def remove_class(text: str, class_name: str):
    while True:
        block = find_class_block(text, class_name)
        if block is None:
            return text
        start, end = block
        text = text[:start] + text[end:]


def ensure_import(text: str, import_line: str):
    if import_line in text:
        return text
    lines = text.splitlines()
    last_import = -1
    for i, line in enumerate(lines):
        if line.startswith("import "):
            last_import = i
    if last_import >= 0:
        lines.insert(last_import + 1, import_line)
        return "\n".join(lines) + "\n"
    return import_line + "\n" + text


def patch_paths(text: str):
    for old in OLD_BACKGROUNDS:
        text = text.replace(old, "assets/images/backgrounds/new_background.jpg")
    return text


def main():
    root = Path.cwd()
    lib = root / "lib"
    if not lib.exists():
        raise SystemExit("Uruchom skrypt w głównym folderze projektu Flutter.")

    # 1. Dodaj nowy widget tła.
    widgets = lib / "widgets"
    widgets.mkdir(parents=True, exist_ok=True)
    source = Path(__file__).with_name("animated_new_background.dart")
    (widgets / "animated_new_background.dart").write_text(source.read_text(encoding="utf-8"), encoding="utf-8")

    # 2. Podmień ścieżki starych backgroundów.
    for dart_file in lib.rglob("*.dart"):
        text = dart_file.read_text(encoding="utf-8")
        patched = patch_paths(text)
        if patched != text:
            dart_file.write_text(patched, encoding="utf-8")

    # 3. MafiaIOSBackground.
    ios = lib / "ui_system" / "mafia_ios_system.dart"
    if ios.exists():
        text = ios.read_text(encoding="utf-8")
        text = ensure_import(text, "import '../widgets/animated_new_background.dart';")
        for cls in ["_NewMafiaRainOverlay", "_NewMafiaRainOverlayState", "_NewMafiaRainPainter", "_MafiaIOSBackgroundState"]:
            text = remove_class(text, cls)
        text = replace_class(text, "MafiaIOSBackground", """
class MafiaIOSBackground extends StatelessWidget {
  const MafiaIOSBackground({
    super.key,
    required this.child,
    this.darkOverlay = 0.04,
    this.rain = true,
    this.lightning = true,
  });

  final Widget child;
  final double darkOverlay;
  final bool rain;
  final bool lightning;

  @override
  Widget build(BuildContext context) {
    return AnimatedNewBackground(
      darkOverlay: darkOverlay,
      rain: rain,
      child: child,
    );
  }
}
""")
        ios.write_text(text, encoding="utf-8")

    # 4. MafiaPhoneBackground.
    phone = lib / "ui_system" / "mafia_phone_ui.dart"
    if phone.exists():
        text = phone.read_text(encoding="utf-8")
        text = ensure_import(text, "import '../widgets/animated_new_background.dart';")
        text = remove_class(text, "MafiaPhoneBackground")
        text = remove_class(text, "_MafiaPhoneBackgroundState")
        text = text.rstrip() + "\n\n" + """
class MafiaPhoneBackground extends StatelessWidget {
  const MafiaPhoneBackground({
    super.key,
    required this.child,
    this.darkOverlay = 0.08,
  });

  final Widget child;
  final double darkOverlay;

  @override
  Widget build(BuildContext context) {
    return AnimatedNewBackground(
      darkOverlay: darkOverlay,
      child: child,
    );
  }
}
"""
        phone.write_text(text, encoding="utf-8")

    # 5. Klasyczny MafiaBackground.
    mb = lib / "widgets" / "mafia_background.dart"
    mb.write_text("""import 'package:flutter/material.dart';

import 'animated_new_background.dart';

class MafiaBackground extends StatelessWidget {
  const MafiaBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedNewBackground(child: child);
  }
}
""", encoding="utf-8")

    # 6. Ekran losowania karty, jeśli ma lokalny _RevealBackground.
    card = lib / "data" / "card.dart"
    if card.exists():
        text = card.read_text(encoding="utf-8")
        text = ensure_import(text, "import '../widgets/animated_new_background.dart';")
        text = replace_class(text, "_RevealBackground", """
class _RevealBackground extends StatelessWidget {
  const _RevealBackground();

  @override
  Widget build(BuildContext context) {
    return const AnimatedNewBackground(
      darkOverlay: 0.10,
      child: SizedBox.expand(),
    );
  }
}
""")
        for cls in ["_SoftRainOverlay", "_SoftRainOverlayState", "_RainPainter"]:
            text = remove_class(text, cls)
        card.write_text(text, encoding="utf-8")

    print("OK: tło ma poprawną skalę, delikatny ruch/parallax i deszcz.")


if __name__ == "__main__":
    main()
