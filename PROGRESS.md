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

---

## 2026-03-11 – Steuerung komplett neu geschrieben (Take 2)

### Probleme identifiziert
- Vorwärtsrichtung war falsch berechnet (W bewegte Spieler in falsche Richtung)
- Kamera-Yaw-Vorzeichen war inkonsistent zwischen Kamera-Position und Bewegungsberechnung
- Kamera hatte Lag durch `lerp()` beim Folgen → Roblox hat keinen Kamera-Lag
- Pitch-Werte waren negativ (verwirrend), jetzt positiv (5° = fast horizontal, 80° = fast von oben)

### Kamera neu geschrieben
- **Kein Lag mehr:** Kamera folgt Spieler sofort (`global_position = target.global_position`)
- **Pitch jetzt positiv:** 5°-80°, intuitiver
- **Kamera-Position:** Kugelkoordinaten korrekt: `(-sin(yaw)*cos(pitch)*dist, sin(pitch)*dist, cos(yaw)*cos(pitch)*dist)`
- **Pfeiltasten:** Links/Rechts dreht Kamera, Hoch/Runter neigt
- **+/- Tasten:** Zoom rein/raus
- Rechte Maustaste + Maus und Touch-Drag bleiben

### Bewegung neu berechnet
- **Vorwärts-Vektor** korrekt abgeleitet aus Kamera-Position: `(sin(yaw), 0, -cos(yaw))`
- **W-Taste:** `input_dir.y = +1` (nicht mehr -1), konsistent mit Vorwärts
- **Bewegung getestet:** W = weg von Kamera, S = zur Kamera, A = links, D = rechts

---

## 2026-03-11 – Steuerung nach Nutzerwunsch angepasst

### Neue Tastenbelegung
- **Pfeiltasten Links/Rechts:** Kamera um Spieler drehen (Spieler steht still)
- **Pfeil Hoch:** Vorwärts laufen in Kamera-Blickrichtung (Spieler dreht sich dabei)
- **Pfeil Runter:** Umdrehen und rückwärts laufen
- **Ctrl + Pfeiltasten:** Kamera neigen (Hoch/Runter) und schneller drehen (Links/Rechts)
- **WASD:** Alternative Bewegung
- **+/-:** Zoom
- Roblox-Verhalten: Kamera orbitet frei um Spieler, Spieler dreht erst bei Bewegung

---

## 2026-03-11 – Schrittgeräusche überarbeitet

### Problem
- Schrittgeräusche klangen wie Baugeräusche/Hämmern statt wie Laufen im Wald
- Ursache: zu hohe Frequenzen (800-3500 Hz), zu kurze Dauer (0.03-0.16s), Sinus-basiert → mechanisch/metallisch

### Lösung: Komplett neues Sound-Design
- **Laub rascheln (55%):** Doppelt tiefpassgefiltertes Rauschen mit Raschel-Modulation, weich und natürlich
- **Weiche Erde (30%):** Sehr stark gefiltert + tiefe Resonanz (140 Hz), dumpfer Aufprall
- **Zweig knacken (15%):** Kurzer breitbandiger Knack mit leise nachklingendem Rauschen
- Alle Sounds: weiche Attack/Decay-Envelope statt harter Impulse
- Tiefpassfilter statt Sinuswellen → natürlicheres Klangbild
- Längere Dauer (0.06-0.22s) für realistischeres Ausklingen
- Leiserer Gesamtpegel (-10 dB statt -8 dB)

---

## 2026-03-11 – Grafik-Überarbeitung (Roblox-Vorbild)

### Analyse
- Screenshot von "99 Nights in the Forest" (Roblox) als Referenz
- Identifizierte Unterschiede: Bäume zu dünn/klein, Boden zu dunkel, Lagerfeuer zu simpel, keine Dekoration

### Bäume komplett überarbeitet (`forest_generator.gd`)
- **Stämme:** Radius verdoppelt (0.3-0.6 statt 0.1-0.28), Höhe verdoppelt (5-8m statt 2-3.5m)
- **Kronen:** Breiter (2.0-3.5 statt 1.2-2.2), flacher (1.2x Höhe statt 2x) für Roblox-Look
- **Farben:** Dunklere Grüntöne für die Kronen, dunklerer Stamm
- **Abstände:** Vergrößert auf 4.5m zwischen Bäumen, 10m Lichtung um Camp

### Lagerfeuer neu gestaltet (`campfire.gd`)
- **Steinkreis:** 8 Steine um die Feuerstelle
- **Holzscheite:** 3 Scheite im Feuer (übereinander), 4 verstreut drumherum
- **Glühende Basis:** Leuchtender Ember-Ring unter dem Feuer
- **Felsblock:** Große dunkelgraue Steinplattform mit zwei Stufen (wie im Vorbild)

### Beleuchtung & Umgebung
- **Boden:** Helleres, satteres Grün (0.25, 0.55, 0.15 statt 0.15, 0.35, 0.1)
- **Sonnenlicht:** Heller (Energy 1.2 statt 0.8), wärmerer Ton
- **Umgebungslicht:** Stärker (Energy 0.6 statt 0.4)
- **Nebel:** Leicht dichter (0.012 statt 0.008) für Wald-Tiefe
- **Himmel:** Hellere, freundlichere Farben am Tag

### Spieler-Look angepasst (`player_model.gd`)
- **Kleidung:** Dunkles T-Shirt + dunkle Jeans (wie im Roblox-Vorbild statt grünem Hemd)
- **Haare:** Heller orangebraun (wie im Screenshot)

---

## 2026-03-11 – Axt-System implementiert

### Neues Feature: Axt mit Stufen
- **Drei Axt-Stufen:** Stein (Stärke 1, 1s Cooldown), Eisen (Stärke 2.5, 0.7s), Stahl (Stärke 5, 0.45s)
- **Prozedurales Axt-Modell:** Brauner Stiel + Klinge (Farbe je nach Stufe: grau/silber/dunkelstahl)
- **Sichtbar in der Hand:** Axt wird am rechten Arm-Pivot befestigt, bewegt sich mit Geh- und Hack-Animation

### Baum-HP-System
- **Kleine Bäume (Scale < 0.9):** 2 HP, 1 Holz → 2 Hiebe mit Steinaxt
- **Mittlere Bäume (Scale 0.9-1.1):** 4 HP, 2 Holz → 4 Hiebe mit Steinaxt
- **Große Bäume (Scale > 1.1):** 8 HP, 4 Holz → 8 Hiebe mit Steinaxt, nur 2 mit Stahlaxt
- **Shake-Effekt:** Bäume wackeln bei jedem Hieb
- Bäume respawnen weiterhin nach 30s

### Hack-Animation
- **Aushol-Bewegung:** Rechter Arm schwingt nach hinten (30% der Animation)
- **Zuschlag:** Arm schwingt schnell nach vorne/unten (70% der Animation)
- **Körperneigung:** Leichter Vorwärtslean beim Hacken
- Spieler dreht sich automatisch zum Baum beim Hacken

### Steuerung
- **Q-Taste:** Axt ziehen / wegstecken (Toggle)
- **E-Taste:** Baum hacken (wenn Axt gezückt und Baum in Reichweite)
- **HUD-Buttons:** "Axt ziehen/wegstecken" und "Baum hacken" (unten rechts)
- Spieler bekommt beim Start eine Steinaxt

---

## 2026-03-11 – Item-Drops, Setzlinge & verbesserte Animation

### Item-Drops beim Baumfällen (`dropped_item.gd`)
- **3 Holzscheite** fliegen aus dem Baum (zufällige Richtung, Schwerkraft, landen am Boden)
- **1 Setzling** fliegt ebenfalls heraus
- Items schweben leicht und drehen sich am Boden
- **Auto-Pickup:** Spieler läuft über Items, um sie aufzusammeln
- Items verschwinden nach 60 Sekunden
- Holz wird nicht mehr direkt beim Fällen gegeben, sondern über die Drops

### Setzling-System (`sapling.gd`)
- Aufgesammelter Setzling kommt ins Inventar (HUD zeigt Anzahl)
- **F-Taste** oder Pflanz-Button: Setzling 2m vor dem Spieler einpflanzen
- **3 Wachstumsphasen** über 120 Sekunden:
  - Phase 1 (0-30%): Kleiner grüner Trieb wächst
  - Phase 2 (30-100%): Stamm und Krone erscheinen und werden größer
  - Ausgewachsen: Wird zu vollem tree_resource-Baum (fällbar!)
- Setzling-Mesh: Kleiner Topf mit grünem Trieb und Blatt

### Realistischere Hack-Animation
- **Beide Arme** greifen die Axt (nicht nur rechter Arm)
- **3-Phasen-Schwung:**
  - Ausholen: Arme nach hinten über den Kopf, Körper lehnt zurück
  - Zuschlagen: Schneller Schwung nach vorne/unten mit Ease-out
  - Nachschwung: Sanftes Zurückkehren zur Normalposition
- **Körperbewegung:** Rumpf lehnt sich vor/zurück und dreht sich seitlich
- **Kopf:** Folgt der Körperbewegung leicht verzögert
- Dauer verlängert auf 0.55s für realistischeren Look

---

## 2026-03-11 – Sounds, Säcke & Sammel-Mechanik

### Prozedurale Spielgeräusche (`game_sounds.gd`)
- **Hack-Sound:** Dumpfer Holz-Aufprall + kurzes Knacken bei jedem Hieb
- **Sammel-Sound:** Aufsteigendes "Swoosh" beim Aufsammeln von Items
- **Fäll-Sound:** Langes Krachen + Aufprall wenn ein Baum fällt
- Alle Sounds prozedural via AudioStreamGenerator (keine externen Dateien)

### Sichtbare Säcke statt abstrakte Items (`dropped_item.gd`)
- **Holz-Sack:** Brauner Sack mit kleinem Holzscheit-Icon oben
- **Setzling-Sack:** Grüner Sack mit Trieb-Icon oben
- Größer und sichtbarer als vorher (Sack-Form mit Zipfel)
- Fliegen aus dem Baum, landen am Boden, schweben leicht
- Verschwinden nach 90 Sekunden (statt 60)

### Einsammeln mit E-Taste (kein Auto-Pickup)
- **E-Taste** ist jetzt die universelle Aktionstaste:
  - Wenn Item in der Nähe → aufsammeln (mit Sound)
  - Wenn Baum in der Nähe und Axt aktiv → hacken (mit Sound)
- **Pickup-Button** erscheint im HUD wenn Items in der Nähe
- Items müssen gezielt eingesammelt werden (Reichweite 2.5m)

### Kamera näher und höher
- **Startabstand:** 5.0 statt 8.0 (näher am Spieler)
- **Startwinkel:** 35° statt 25° (mehr von oben schauen)

### Tastenbelegung (aktualisiert)
| Taste | Aktion |
|-------|--------|
| Q | Axt ziehen / wegstecken |
| E | Aufsammeln / Baum hacken |
| F | Setzling pflanzen |
| Pfeiltasten | Bewegen + Kamera drehen |
| Shift+Pfeile | Zoom + Neigung |

---

## 2026-03-11 – FIFO-Inventar & Minecraft-Style Hotbar

### FIFO-Inventar (Reihenfolge beibehalten)
- Jedes aufgesammelte Item wird in einer geordneten Liste gespeichert
- **G-Taste:** Ausgewähltes Item als Sack vor dem Spieler ablegen
- Crafting/Pflanzen entfernt Items korrekt aus dem Inventar

### Inventarleiste (Minecraft-Style) (`inventory_bar.gd`)
- **Hotbar** am unteren Bildschirmrand mit Slot-Kästchen
- Ausgewählter Slot hat goldenen Rahmen und hellen Hintergrund
- **Tab:** Nächsten Slot auswählen
- **Shift+Tab:** Vorherigen Slot auswählen
- **1-9 Tasten:** Direkt zum Slot springen
- Maximal 9 Slots sichtbar, scrollt mit bei mehr Items
- Item-Icons: Holz (braun) und Setzling (grün)
- Item-Name unter dem ausgewählten Slot
- Slot-Nummern in der Ecke

---

## 2026-03-11 – Fackel-System

### Fackel bauen & benutzen
- **Crafting:** 3 Holz → 1 Fackel (wie vorher), Fackel landet jetzt als Item im Inventar
- **T-Taste:** Fackel anzünden / ausmachen (Toggle)
- Fackel ist **sichtbar in der linken Hand** des Spielers (prozedurales Modell)
- **Lichtquelle:** OmniLight3D mit Reichweite 10m, warme Farbe, Schatten, Flacker-Effekt
- Flammen-Mesh: Doppelte Kugel (solide + transparent) für Volumen-Effekt

### Hirsch flieht vor Fackel
- Hirsch erkennt aktive Fackel im Radius von 12m
- Beim Jagen: sofortige Flucht wenn Spieler Fackel aktiviert
- Beim Roaming: Spieler mit Fackel wird nicht angegriffen
- Flucht-Geschwindigkeit = Jagd-Geschwindigkeit (schneller als normales Laufen)
- Fluchtrichtung: Vom Spieler weg (nicht vom Lagerfeuer)

### Inventar-Integration
- Fackel erscheint im Inventar als oranges Icon (Stiel + Flamme)
- Kann mit G-Taste abgelegt werden (deaktiviert Fackel automatisch)
- Item-Name "Fackel" unter ausgewähltem Slot

### Tastenbelegung (aktualisiert)
| Taste | Aktion |
|-------|--------|
| Q | Axt ziehen / wegstecken |
| T | Fackel anzünden / ausmachen |
| E | Aufsammeln / Baum hacken |
| F | Setzling pflanzen |
| G | Ausgewähltes Item ablegen |
| Tab / Shift+Tab | Inventory Slot wechseln |
| 1-9 | Direkt zum Inventory Slot |

---

## 2026-07-04 – Hilfe-Fenster mit Tastaturbefehlen

### Neues Feature: Hilfe-Menü (`help_menu.gd`)
- **?-Taste:** Öffnet/schließt ein Fenster mit allen Tastaturbefehlen
- **Esc:** Schließt das Fenster ebenfalls
- Erkennung über `event.unicode == 63` → funktioniert unabhängig vom Tastatur-Layout (auf Deutsch Shift+ß)
- Gruppiert nach Abschnitten: Bewegung, Kamera, Aktionen, Inventar, Sonstiges
- Stil passend zu Werkbank/Cheat-Menü (PanelContainer, zentriert, blauer Rahmen)
- Einbindung im `game_manager._ready()` wie die anderen Menüs

---

## 2026-07-04 – Hasen & Wölfe

### Hase (`rabbit_animal.gd`)
- Friedliches Tier, hoppelt durch den Wald (kleine Sprünge, wackelnde Nase im Idle)
- Flieht wenn der Spieler näher als 5m kommt
- 1 HP → ein Axthieb erlegt ihn
- **Drops:** 1-2 Fleischstückchen, 30% Chance auf einen Hasenfuß
- Quiek-Laut beim Tod (prozedural)
- Prozedurales Modell: graubraunes Fell, lange Ohren mit rosa Innenseite, weißer Puschel-Schwanz, große Hinterläufe

### Wolf (`wolf_enemy.gd`)
- Feindliches Tier mit KI-Zustandsmaschine (IDLE/PATROLLING/CHASING/ATTACKING)
- Greift an wie der Hirsch: 20 Schaden, Erkennungsradius 10m
- Respektiert die sichere Zone: bricht Verfolgung ab wenn Spieler am Lagerfeuer (`is_safe`)
- 6 HP → 6 Hiebe mit Steinaxt, 3 mit Eisenaxt, 2 mit Stahlaxt
- Wird aggressiv wenn er getroffen wird
- **Drops:** 1 Steak + 2 Fleischklumpen, 25% Chance auf einen Wolfspelz
- Knurren und Biss-Geräusche (prozedural)
- Prozedurales Modell: graues Fell mit dunklem Rückenstreifen, leuchtende gelbe Augen, buschiger Schwanz, Trab-Animation (diagonale Beinpaare)

### Tiere angreifen (E-Taste)
- Neue Funktion `player.try_attack_animal()`: Tiere in Gruppe "animal" im Radius 3m
- E-Taste-Priorität: Aufsammeln → Tier angreifen → Baum hacken
- Axtstärke = Schaden (Stein 1, Eisen 2.5, Stahl 5)
- Spieler dreht sich zum Tier, Hack-Animation und -Sound wie beim Baumfällen

### Neue Items (Drops + Inventar-Icons + Namen)
- **Fleischstückchen** (`meat_small`) – rosa Brocken mit Fettstreifen
- **Fleischklumpen** (`meat_chunk`) – dunkelroter Brocken mit Knochen
- **Steak** (`steak`) – flache Scheibe mit Grillstreifen
- **Hasenfuß** (`rabbit_foot`) – kleiner Fuß mit heller Pfote
- **Wolfspelz** (`wolf_pelt`) – graue Fellmatte mit Rückenstreifen

### Spawning (`game_manager._spawn_animals()`)
- 6 Hasen im Radius 12-45m, 3 Wölfe im Radius 30-60m (fester Seed 77)

---

## 2026-07-04 – Hasen-Verhalten angepasst

### Änderungen nach Nutzer-Feedback
- **Hasen fliehen nicht mehr vor dem Spieler** – man kann direkt zu ihnen hinlaufen
- **Flucht nur nach Angriff:** HP von 1 auf 2 erhöht → mit der Steinaxt braucht es 2 Treffer, nach dem ersten quiekt der Hase und flieht (Eisen-/Stahlaxt erlegen weiterhin mit einem Hieb)
- **Spawnen nah am Lagerfeuer:** Radius 9-13m statt 12-45m (Schutzzone ist 8m)
- **Heimatpunkt-System:** Hasen hoppeln um ihren Spawn-Punkt herum statt zufällig wegzudriften; Hüpfziele bleiben außerhalb der Lagerfeuer-Zone (8,5m)

---

## 2026-07-04 – Höhle entfernt, Portal & Unterwelt

### Höhle entfernt
- `cave.gd` gelöscht, Spawn-Code und `_cut_ground_hole()` aus dem game_manager entfernt
- Der Boden ist wieder durchgehend (kein Loch mehr bei 40/-30)

### Portal (`portal.gd`)
- Steinbogen mit zwei Säulen, leuchtenden Runen und wirbelnder lila Magie-Scheibe
- Pulsierendes OmniLight, heller Kern in der Mitte
- Steht wo früher der Höhleneingang war (40, 0, -30)
- **Durchgehen teleportiert** in die Unterwelt (Area3D-Trigger)
- 2s Cooldown verhindert sofortiges Zurück-Teleportieren
- Magisches Teleport-Geräusch (prozedural, aufsteigender Ton)
- Minimap zeigt jetzt ein lila Portal-Symbol statt der Höhle

### Unterwelt (`underground_world.gd`)
- Große Kaverne (70x70m, 13m hoch) bei y=-100 tief unter der Karte
- Leuchtende Kristall-Gruppen (blau/türkis, 5 davon mit echtem Licht wegen Mobile-Renderer)
- Stalagmiten und Stalaktiten, 16 leuchtende Pilze
- **Feinde:** 3 Fledermäuse + 3 Kultisten (Scripts von der Höhle wiederverwendet)
- **Rück-Portal** (grün) bringt den Spieler zurück in den Wald

### Cheat-Menü angepasst
- "Zum Portal teleportieren" und "In die Unterwelt teleportieren" statt der Höhlen-Teleports

---

## 2026-07-04 – Vermisste Kinder, bessere Unterwelt-Grafik & Speichersystem

### Die 4 vermissten Kinder (`lost_child.gd`)
- **Das Hauptziel des Spiels ist jetzt drin:** 4 Kinder sind in Holzkäfigen in den Ecken der Unterwelt versteckt
- Jedes Kind hat eine eigene Hemdfarbe (rot, blau, gelb, rosa) mit leichtem Leuchten
- **Leises Schluchzen** alle 5-10s als Audio-Hinweis zum Finden im Dunkeln
- **E-Taste befreit** das Kind (Käfig verschwindet, fröhlicher Dreiklang erklingt)
- **Jede Rettung verkürzt die Nächte um 20:** 99 → 79 → 59 → 39 → 19
- Gerettete Kinder sitzen danach am Lagerfeuer
- HUD zeigt jetzt "Tag X / Y | Kinder Z/4"

### Bessere Unterwelt-Grafik
- **Prozedurale Fels-Texturen:** FastNoiseLite + NoiseTexture2D (Albedo-Variation + Normal-Maps) mit Triplanar-Mapping – Wände/Boden/Decke sehen aus wie echter Fels statt flacher Farbflächen
- **40 unregelmäßige Felsbrocken** entlang der Wände (verzerrte, rotierte Kugeln)
- **30 Felsplatten** ragen aus dem Boden (bricht die ebene Fläche auf)
- **22 Baumwurzeln** hängen von der Decke (mehrsegmentig, verjüngend – wir sind unter dem Wald!)
- **120 schwebende Staubpartikel** (GPUParticles3D) mit leichtem Glühen
- **Kristalle verbessert:** halbtransparent, glänzend (metallic/roughness), stärkere Emission

### Speichersystem (`save_system.gd`)
- **Autosave alle 10 Sekunden** + beim Schließen des Spiels (WM_CLOSE_REQUEST)
- Datei: `user://savegame.json`
- **Gespeichert wird:** Spieler-Position/Rotation/HP, Inventar, Holz/Setzling-Zähler, Axt (Stufe), Fackel, Tag/Uhrzeit/Nacht-Status, verkürzte Nächte, gerettete Kinder (welche!), platzierte Strukturen (Bett/Zaun/Wand/Truhe mit Position)
- **Beim Start wird geladen:** Man steht wieder genau da, wo man aufgehört hat; gerettete Kinder sitzen am Lagerfeuer, ihre Käfige in der Unterwelt sind weg; nachts geladen → Hirsch sofort aktiv
- **Reset:** Cheat-Menü (F1) → roter Button "SPIEL ZURÜCKSETZEN" löscht den Spielstand und startet neu
- Platzierte Items sind jetzt in der Gruppe "placeable" (für das Speichersystem)

---

## 2026-07-04 – Unterwelt-Gegner besiegbar

### Problem (Nutzer-Frage)
- Kultisten und Fledermäuse waren mit der Axt NICHT angreifbar: nur Tiere in der Gruppe "animal" wurden getroffen
- Fledermäuse hatten gar kein HP-System (unsterblich)

### Lösung
- **Kultisten:** in Gruppe "animal", HP von 40 auf 10 reduziert (10 Steinaxt / 4 Eisen / 2 Stahl), werden bei Treffern sofort aggressiv, droppen 1 **Kultisten-Edelstein** (neues Item, leuchtender lila Kristall)
- **Fledermäuse:** 3 HP + take_damage() ergänzt (3 Steinaxt / 2 Eisen / 1 Stahl), droppen 1 Fleischstückchen. Angreifbar wenn sie zum Angriff heruntergeflogen kommen
- E-Taste trifft jetzt alle Gegner in Reichweite (3m)

### Bug-Fix: Drops in der Unterwelt
- Gedroppte Items hatten die Ruhehöhe y=0.25 hart-codiert (Waldboden) → Drops in der Unterwelt wären zur Oberfläche teleportiert
- Neue `rest_height`-Logik: Spawn unterhalb y=-50 → Ruhehöhe -99.75 (Unterwelt-Boden)

---

## 2026-07-04 – Echte Foto-Texturen (CC0 von ambientCG)

### Texturen heruntergeladen
- **Quelle:** ambientCG.com, alle CC0 (Public Domain) – Lizenz in `game/assets/textures/LICENSE.md`
- `grass_color/normal.jpg` (Grass001), `rock_color/normal.jpg` (Rock030), `bark_color/normal.jpg` (Bark012)
- Jeweils 1K-Auflösung, Color- + Normal-Map

### Angewendet auf
- **Waldboden & Wiesen:** Gras-Textur mit verschiedenen Grün-Tönungen (Boden, Wiesen, Plateaus, hohes/kurzes Gras)
- **Unterwelt:** Fels-Textur ersetzt die prozeduralen Noise-Texturen (Wände, Boden, Decke, Felsbrocken, Stalagmiten, Stalaktiten)
- **Bäume:** Stämme mit Rinden-Textur
- **Unterwelt-Wurzeln:** ebenfalls Rinden-Textur
- **Landschafts-Steine & Plateau-Seiten:** Fels-Textur

### Technik
- `_textured_mat()`-Helper: Albedo-Textur + Normal-Map + Farbton (albedo_color multipliziert die Textur)
- **World-Triplanar-Mapping:** Textur liegt verzerrungsfrei auf allen prozeduralen Meshes, unabhängig von deren UVs und Skalierung

---

## 2026-07-04 – Fleisch braten & hellere Beleuchtung

### Fleisch braten am Lagerfeuer
- **C-Taste** (am Lagerfeuer): brät rohes Fleisch aus dem Inventar
  - Bevorzugt das ausgewählte Hotbar-Item, sonst das erste rohe Fleisch
  - Fleischstückchen → Gebratenes Fleischstückchen (+15 HP)
  - Fleischklumpen → Gebratener Fleischklumpen (+30 HP)
  - Steak → Gebratenes Steak (+50 HP)
- **V-Taste:** isst gebratenes Fleisch und heilt HP (bei voller Gesundheit wird nicht gegessen)
- Gebratene Varianten mit eigenen Drop-Modellen (braun) und Inventar-Icons
- Hilfe-Fenster (?) um C und V ergänzt

### Beleuchtung heller (Nutzer-Feedback: Texturen kaum sichtbar, Nacht zu dunkel)
- Nacht-Lichtintensität 0.15 → 0.35, Nachtlicht-Farbe heller (0.4/0.4/0.6)
- Nachthimmel heller (0.18/0.18/0.35)
- Tag: Mittagshelligkeit 1.0 → 1.25, Morgen startet bei 0.65 statt 0.5
- Umgebungslicht: Faktor 0.7 → 0.9 mit Mindestwert 0.35 (Texturen bleiben immer sichtbar)
