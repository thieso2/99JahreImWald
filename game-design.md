# 99 Jahre im Wald – Game Design Dokument

## Vorbild: 99 Nights in the Forest (Roblox)

**Entwickler:** Grandma's Favourite Games | **Plattform:** Roblox (kostenlos)

---

## Technische Entscheidungen

| Entscheidung | Wahl |
|-------------|------|
| **Engine** | Godot 4 (GDScript) |
| **Zielplattform** | iPad (iOS-Export) |
| **Perspektive** | 3D |
| **Multiplayer** | Ja – ab Version 2 (Godot MultiplayerAPI) |
| **Grafikstil** | Low-Poly (einfach zu erstellen, gute Performance auf iPad) |

---

## Entwicklungsplan

### Version 1 – MVP (Minimal Viable Product)

Ziel: Ein spielbarer Prototyp mit den absoluten Kern-Mechaniken.

- [ ] **Spielerwelt:** Kleine 3D-Waldkarte mit Bäumen und Lagerfeuer
- [ ] **Spieler-Steuerung:** Touchscreen-Steuerung (virtueller Joystick + Buttons)
- [ ] **Tag/Nacht-Zyklus:** Automatischer Wechsel, Himmel wird dunkel
- [ ] **Lagerfeuer:** Sichere Zone, Lichtquelle in der Nacht
- [ ] **Ressourcen sammeln:** Holz von Bäumen sammeln (antippen)
- [ ] **1 Gegner:** Der Hirsch – erscheint nachts, jagt den Spieler
- [ ] **Gesundheitssystem:** HP-Leiste, Schaden durch Gegner
- [ ] **1 Crafting-Rezept:** Fackel (Holz → Fackel)

### Version 2 – Multiplayer & Crafting

- [ ] **Multiplayer:** 2-4 Spieler zusammen auf einer Karte
- [ ] **Crafting Bench:** Mehrere Rezepte (Steinaxt, Zaun, Bett)
- [ ] **Base Building:** Einfache Zäune um das Camp
- [ ] **Weitere Gegner:** Wölfe, Kultisten
- [ ] **Inventar-System:** Items aufheben und verwalten

### Version 3 – Vollständiges Spiel

- [ ] **Vermisste Kinder** in Höhlen finden
- [ ] **Biome:** Schnee-Biom und Vulkan-Biom
- [ ] **Alle Monster:** Eule, Widder, Fledermaus, Bären
- [ ] **Klassen-System:** Erste 5 Klassen mit Perks
- [ ] **Rüstung & Waffen:** Nahkampf und Fernkampf

---

## Spielkonzept

Ein **Horror-Survival-Spiel**, in dem Spieler 99 Nächte in einem dunklen Wald überleben müssen. Das Hauptziel: **4 vermisste Kinder retten** und dabei das eigene Camp verteidigen. Jedes gerettete Kind verkürzt die Anzahl der benötigten Nächte.

---

## Kern-Mechaniken

### Tag/Nacht-Zyklus

- **Tagsüber:** Karte erkunden, Ressourcen sammeln, Basis ausbauen
- **Nachts:** Gefahren kommen – das Lagerfeuer dient als sichere Zone vor den meisten Feinden

### Crafting-System

- Ressourcen im **Grinder** zu Schrott und Holz verarbeiten
- Am **Crafting Bench** Gegenstände herstellen
- **4 Workshop-Stufen** – jede Stufe schaltet fortgeschrittenere Rezepte frei:
  - Stufe 1: Grundwerkzeuge (Steinaxt, einfaches Bett)
  - Höhere Stufen: Elfenbögen, Eisenrüstung, mechanische Fallen, Biokraftstoff-Prozessoren
- Materialien: Holz, Schrott, Kultisten-Edelsteine, Edelsteine des Waldes

### Base Building

- Zäune, Strukturen und Verteidigungsanlagen bauen
- Blueprint-System: Rezept auswählen → craften → Blueprint platzieren
- Strukturen mit R drehen vor dem Platzieren
- Zäune als wichtige frühe Verteidigung gegen nächtliche Angriffe

### Klassen-System

- **33 Klassen** (29 Standard + 2 Event-Klassen)
- Jede Klasse hat eigene Startgegenstände und 3 einzigartige Perks
- **3 Level pro Klasse** – Aufstieg durch spezifische Aufgaben (Kills, Fähigkeiten nutzen)
- Beispiele:
  - **Cyborg** – gilt als stärkste Klasse, konsistent für Solo und Team
  - **Beastmaster / Necromancer** – Beschwörungs-fokussiert
  - **Medic** – Support-Gameplay
- Klassen werden im Lobby-Shop mit Diamanten gekauft, täglicher Stock-Rotation

---

## Gegner & Monster

### Unsterbliche Bosse (können nicht getötet werden)

| Monster | Beschreibung |
|---------|-------------|
| **Der Hirsch** | Hauptantagonist – zweibeinig, jagt Spieler nachts |
| **Die Eule** | Sekundärer Antagonist |
| **Der Widder** | Sekundärer Antagonist |
| **Die Fledermaus** | Riesig, blind, patrouilliert die Fledermaushöhle, Schall-Attacke, beschwört Kultisten |

### Feindliche NPCs

| Gegner | Beschreibung |
|--------|-------------|
| **Kultisten** | Greifen ca. alle 3 Nächte das Camp an |
| **Gefrorene Kultisten** | Variante im Schnee-Biom |

### Tiere (jagdbar / feindlich)

| Tier | Drops / Verhalten |
|------|-------------------|
| **Wölfe** | 2 kleine Fleischstücke, 1 Steak, Chance auf Wolfsfell |
| **Alpha-Wölfe** | Stärkere Variante |
| **Bären** | Sehr stark, bewachen Höhlen mit vermissten Kindern |
| **Hasen** | Friedlich, jagdbar |
| **Polarfüchse** | Im Schnee-Biom |
| **Polarbären** | Im Schnee-Biom |
| **Mammuts** | Im Schnee-Biom, sehr gefährlich |

---

## Biome

| Biom | Besonderheiten |
|------|----------------|
| **Standard-Wald** | Hauptgebiet, Startpunkt mit Lagerfeuer |
| **Vulkan-Biom** | Gefährlicher, besserer Loot |
| **Schnee-Biom** | Temperatur-Mechanik (Erfrierungsgefahr), eigene Tierwelt |

---

## Items & Ausrüstung

### Waffen

- **Nahkampf:** Äxte, Schwerter etc.
- **Fernkampf:** Bögen (z.B. Elfenbogen), Schusswaffen

### Rüstung

- Tragbare Items, die erlittenen Schaden reduzieren
- Von einfacher bis Eisenrüstung

### Werkzeuge & Sonstiges

- **Taschenlampen:** Lichtquelle für Nachterkundung und Monster-Abwehr
- **Steinaxt:** Beschleunigt Holzsammeln erheblich
- **Einfaches Bett:** Verhindert Fortschrittsverlust bei Tod

---

## Spielziel & Progression

1. **Hauptziel:** 99 Nächte überleben ODER alle 4 vermissten Kinder retten (verkürzt die nötige Nächteanzahl)
2. **Kinder** befinden sich in Höhlen, die von Bären bewacht werden
3. **Klassen** durch Aufgaben hochleveln (Max. Level 3)
4. **Workshop** stufenweise upgraden für bessere Crafting-Rezepte
5. **Koop-Modus:** Mit Freunden zusammen spielen

---

## Quellen

- [Roblox-Spielseite](https://www.roblox.com/games/79546208627805/99-Nights-in-the-Forest)
- [Fandom Wiki](https://99-nights-in-the-forest.fandom.com/wiki/99_Nights_in_the_Forest_Wiki)
- [Crafting Guide – TheGamer](https://www.thegamer.com/roblox-99-nights-in-the-forest-craftable-items-use-guide/)
- [Survival Guide – BlueStacks](https://www.bluestacks.com/blog/game-guides/roblox/rl-99-nights-in-the-forest-survival-guide-en.html)
- [Classes – PC Gamer](https://www.pcgamer.com/roblox/99-nights-in-the-forest-classes/)
- [Entities – Fandom Wiki](https://99-nights-in-the-forest.fandom.com/wiki/Entities)
- [Tipps – PC Gamer](https://www.pcgamer.com/games/roblox/99-nights-in-the-forest-tips/)
