# Progress – 99 Jahre im Wald

Fortlaufende Dokumentation aller Entwicklungsschritte und wichtigen Entscheidungen.

---

## 2026-03-11 – Projektstart & MVP

### Recherche
- Roblox-Spiel "99 Nights in the Forest" als Vorbild analysiert
- Kern-Features identifiziert: Tag/Nacht-Zyklus, Lagerfeuer als sichere Zone, unsterblicher Hirsch-Boss, Holz sammeln, Crafting, Base Building, Klassen-System, Biome
- Ergebnisse in `game-design.md` dokumentiert

### Technologie-Entscheidungen
- **Engine:** Godot 4 (GDScript) – kostenlos, open-source, einsteigerfreundlich
- **Plattform:** iPad (iOS) als Zielplattform, PC zum Entwickeln/Testen
- **Grafik:** 3D, Low-Poly Stil
- **Multiplayer:** Geplant ab Version 2, nicht im MVP
- **Renderer:** Mobile-Renderer für iPad-Kompatibilität

### MVP implementiert
- Spieler-Steuerung (WASD + Touch-Joystick)
- Tag/Nacht-Zyklus mit Sonnenauf-/-untergang und Farbübergängen
- Lagerfeuer mit flackerndem Licht als sichere Zone
- Hirsch-Monster mit KI-Zustandsmaschine (patrouilliert, jagt, greift an, flieht vor Feuer)
- Bäume zum Holz sammeln (respawnen nach 30s)
- Fackel-Crafting (3 Holz → 1 Fackel)
- HP-System mit Respawn am Lagerfeuer
- HUD: HP-Leiste, Holz-Zähler, Tag/Nacht-Anzeige, Nachrichten

### Bug-Fixes nach erstem Test
- **GDScript Typ-Inferenz:** `var x := obj.method()` funktioniert nicht bei dynamischen Typen in Godot 4.6 → überall explizite Typen verwendet (`var x: float = ...`)
- **Ungültige Scene-UID:** `uid://main_scene` war kein gültiges Format → entfernt
- **GPUParticles3D:** Fehlte `ParticleProcessMaterial` → hinzugefügt
- **Sub-Resource IDs:** Von Nummern zu lesbaren Namen geändert für Godot 4.6 Kompatibilität

---

## 2026-03-11 – Wald, Kamera & Musik

### Probleme behoben
- **Bewegungs-Glitch:** Kamera war Kind des Spielers → Drehung verursachte Rückkopplungsschleife bei der Bewegungsrichtung. **Lösung:** Kamera als separates `CameraController`-Node, folgt dem Spieler sanft per `lerp()`
- **Drehung zu schnell:** `rotation_speed` von 10.0 auf 3.0 reduziert
- **Tree-Node-Fehler:** `@onready $CollisionShape3D` schlug fehl bei prozedural erzeugten Bäumen. **Lösung:** Dynamische Suche per `get_children()` Loop

### Großer Wald
- `ForestGenerator` erstellt: Platziert 300 Bäume prozedural im Radius von 80m
- Fester Seed (42) für konsistenten Wald bei jedem Start
- Variation: unterschiedliche Größen (0.7x-1.4x), 5 verschiedene Grüntöne, zufällige Rotation
- Mindestabstand: 6m zum Camp (Lichtung), 3m zwischen Bäumen
- Nebeldichte erhöht für Waldatmosphäre

### Kamera-System
- **Entscheidung:** Separate Kamera statt Spieler-Kind → verhindert Bewegungs-Glitches
- Orbit-Kamera mit Rotation und Zoom
- Zoom bis First-Person (Spieler-Mesh wird ausgeblendet)
- Steuerung:
  - **Pfeiltasten:** Kamera drehen und neigen
  - **Shift + Hoch/Runter:** Zoom rein/raus
  - **Mausrad:** Zoom
  - **Rechte Maustaste + Maus:** Rotation
  - **iPad:** Touch-Drag (rechte Seite) und Pinch-Zoom
- Bewegungsrichtung relativ zur Kamera-Rotation (Spieler bewegt sich dorthin wo man schaut)

### Gruselige Ambient-Musik
- **Entscheidung:** Prozedural generiert statt Audio-Dateien → keine externen Assets nötig
- Tiefe Drone-Töne (55 Hz + 58.3 Hz = schwebende Dissonanz)
- LFO-gesteuertes Pulsieren
- Wind-artiges Rauschen
- Zufällige "Knarz"-Geräusche alle 4-12 Sekunden

---

## 2026-03-11 – Spielerfigur überarbeitet

### Neues Spieler-Modell (`player_model.gd`)
- **Entscheidung:** Modell komplett prozedural in GDScript gebaut (keine externen 3D-Assets nötig)
- Körper: Oberkörper (grünes Outdoor-Hemd), Hose (braun), Schuhe (dunkelbraun)
- Kopf: Hautfarbe, braune Haare oben
- Gesicht: Weiße Augen mit dunklen Pupillen, Nase, Mund
- Arme: Mit Händen (Hautfarbe), schwingen beim Gehen
- Beine: Mit Schuhen, schwingen gegenläufig zu den Armen
- Altes Capsule-Mesh entfernt, neues Modell wird per Script in `_ready()` erstellt

### Gehanimation
- Beine und Arme schwingen gegenläufig (natürlicher Gang)
- Körper wippt leicht vertikal und seitlich
- Kopf wippt dezent mit
- Sanftes Zurückkehren zur Ruheposition beim Stehenbleiben
- Leichte Atem-Animation im Idle

### Schrittgeräusche (`footstep_sounds.gd`)
- **Entscheidung:** Prozedural generiert via AudioStreamGenerator
- Drei Schritttypen, zufällig gemischt:
  - Laub rascheln (häufigster, 50%)
  - Weicher Waldboden (dumpfer Aufprall, 30%)
  - Ast knacken (kurzer Knack, 20%)
- Leichte Timing-Variation zwischen Schritten (0.32-0.42s)
- Nur aktiv wenn der Spieler sich bewegt

---

## 2026-03-11 – Roblox-Style Steuerung

### Recherche
- Roblox-Standardsteuerung analysiert: Bewegung relativ zur Kamera, rechte Maustaste für Kamera-Rotation, Mausrad Zoom, Touch-Joystick + Screen-Drag auf iPad

### Kamera komplett neu geschrieben
- **Entscheidung:** `_unhandled_input` statt `_input` → UI-Buttons blockieren Kamera-Input korrekt
- **PC:** Rechte Maustaste gedrückt + Maus = Kamera drehen (wie Roblox)
- **PC:** Mausrad = Zoom, Shift+Pfeiltasten = Zoom
- **iPad:** Touch-Drag (nicht auf Joystick) = Kamera drehen
- **iPad:** Pinch = Zoom
- Kamera schaut auf Spieler-Brusthöhe (Y=1.2) statt auf den Boden
- Joystick-Bereich (links unten) wird korrekt ausgespart

### Bewegung Roblox-Style
- **W** = vorwärts in Kamera-Blickrichtung (nicht Welt-Norden)
- **S** = rückwärts, **A/D** = seitlich relativ zur Kamera
- Charakter-Drehgeschwindigkeit von 3.0 auf 15.0 erhöht (fast sofortige Drehung wie in Roblox)
- Gleiche Logik für Touch-Joystick
