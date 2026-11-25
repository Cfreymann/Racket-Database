# Empire Clash

A simple 2D army battler. Build your army one card at a time and auto-battle a random historical
empire each round. Each enemy army grows stronger as you go. Lose once and the campaign ends.

This folder is self-contained: one HTML file with no build step and no dependencies other than two
Google Fonts. It is separate from everything else in this repository. Open `index.html` in a
browser to play.

## Modes

* **Campaign:** a fixed series of historical battles on hand-made maps, chosen from a pixel-art
  map of the empires' real borders. The first campaign is **Sasanian Persia** (you lead Persia
  against Rome):

  | # | Battle      | Year   | Map                                              | Rome fields |
  |---|-------------|--------|--------------------------------------------------|-------------|
  | 1 | Misiche     | AD 244 | Euphrates across the field, two bridges          | 26 troops   |
  | 2 | Barbalissos | AD 253 | Slanting river, one bridge, rocky banks           | 30 troops   |
  | 3 | Edessa      | AD 260 | City walls with two gates (steppe)               | 30 troops   |
  | 4 | Singara     | AD 344 | Desert, rock ridges with three passes, an oasis  | 36 troops   |
  | 5 | Ctesiphon   | AD 363 | Wide Tigris with three bridges, Rome's biggest army | 40 troops |

  * **Your army:** you start with 25 Persian troops and can grow to 40. Each win gives gold and a card.
  * **Losing:** a loss doesn't end the campaign. Your army regroups and you retry the battle.
  * **Field size:** campaign fields are twice the screen in each direction, with the same troop size.
  * **The map:** it shows the frontier after the Peace of Nisibis (AD 299), including Armenia as a
    buffer kingdom and the Arabian desert. It is drawn at 4 pixels per degree and scrolls sideways.
    Its seas, lakes, rivers (Euphrates, Tigris, Karun, Nile), mountains, forests, deserts, marshes and
    cities come from rough longitude/latitude outlines, rasterized to pixels.
  * **Growing territory:** Persia starts as just Persis (Fars). Each victory annexes a region:
    Mesopotamia, Khuzestan and Media; Atropatene, Rey and Hyrcania; Armenia, Kerman and Khorasan;
    Sakastan, the Kushan lands and Oman; and finally Nisibis and Singara, ceded by Rome. Back on the
    map, your color floods into the new lands from the battle site. See `conquestStage()`.

* **Endless:** the original mode, described below. It has its own save, separate from the campaign.

## Terrain

Campaign maps can have rivers and lakes, bridges, rocks and walls. Troops can't enter water, rocks or
walls. They walk straight when the way is clear and otherwise follow an A* path on a 16px grid. That
is how they find bridges and gates; formations squeeze through and re-form on the other side.
Arrows and artillery fly over everything. Maps are defined in `CAMPAIGNS` as fractions of the field,
so adding a battle means adding a stage with a `map` and an `enemy`.

## The loop

0. **Choose your empire:** play as the Kingdom (your own banner) or as any of the five empires.
   Your army has five slots (infantry, spear, ranged, cavalry and heavy). Your empire decides which
   troop fills each slot and gives you a small perk. You never fight your own empire.

   | Empire   | Infantry        | Spear             | Ranged         | Cavalry    | Heavy        | Perk                                |
   |----------|-----------------|-------------------|----------------|------------|--------------|-------------------------------------|
   | Kingdom  | Swordsman       | Spearman          | Archer         | Knight     | Catapult     | +50 gold to start                   |
   | Rome     | Legionary       | Triarius          | Sagittarius    | Equites    | Ballista     | Infantry +15% health                |
   | Mongols  | Mongol Raider   | Mongol Spearman   | Horse Archer   | Lancer     | Mangonel     | Horse archers and lancers 15% faster |
   | Egypt    | Khopesh Warrior | Egyptian Spearman | Nubian Archer  | Chariot    | Catapult     | Archers +40 range                   |
   | Persia   | Persian Swordsman | Immortal        | Persian Archer | Cataphract | War Elephant | +20 gold per victory                |
   | Aztecs   | Jaguar Warrior  | Aztec Spearman    | Atlatl Thrower | Eagle Warrior | Shorn One | Infantry +15% attack                |

1. **Draft:** start a campaign by choosing 1 of 3 cards. After every victory, choose 1 of 3 more.
   * **Troops:** add Swordsmen, Spearmen, Archers, Knights or Catapults.
   * **Upgrades:** health, attack, range, attack speed or healing.
   * **Treasury:** gold now, gold per win, or cheaper recruiting.
2. **Camp:** your scouts reveal the next enemy empire and its army. Spend gold to recruit more of
   any troop type you own, up to 60 troops. Then set your **battle plan**:
   * **Zones:** each troop type starts in the Left flank, Center, Right flank or Rear. Tap the zone
     button on a troop row to change it.
   * **Routes:** on the plan board, swipe from a zone to give its troops a route. Each swipe adds a
     step, up to 3 (for example, toward the enemy's middle, then their rear). Troops march the
     steps in order and only stop for enemies right next to them. After the last step they fight
     the nearest enemy. Undo and Clear are on the board, and the plan carries over between battles.
   * **Formation:** infantry and archers march as a block and keep their starting shape. They break
     formation only to fight enemies close by, then fall back into place. Riders move freely.
   * **Strict / Loose:** with Strict, troops push along their route and only fight enemies right in
     their way (good for flanking around the enemy). With Loose, they stop to fight enemies they pass
     near, then carry on along the route.
   * **Enemy formation:** infantry in the center, cavalry split across both flanks, and archers
     and siege at the rear.
3. **Battle:** armies fight on their own. Your troops start at the bottom and the enemy's at the
   top. You can speed it up 2× or 3×. The battlefield grows with the number of troops (up to twice
   the screen in each direction). The camera follows the fighting, you can drag to look around, and a
   minimap shows the whole field.
4. **Win:** you get gold and a card pick, then a new random empire (never the same one twice in a
   row). **Lose:** the campaign is over, and your best run is saved.

## Counters

* Spearmen (and Immortals) deal double damage to cavalry and elephants.
* Cavalry deals 1.5× damage to ranged troops and siege.
* Eagle Warriors deal 1.5× damage to ranged troops and siege.
* Artillery (Catapult, Mangonel, Ballista) fires at the ground where its target is standing. The shot
  takes about a second to land (the ballista bolt about 0.7s), and a blinking ring marks the spot.
  Then it explodes for area damage: full in the middle, half at the edge. Troops can walk out of
  the ring before it lands.
* War Elephants also hit everyone around their target.
* Horse Archers back away slowly from melee troops that reach them, and keep shooting as they go.

## The five empires

| Empire            | Years            | Troops                                        |
|-------------------|------------------|-----------------------------------------------|
| Roman Empire      | 27 BC – AD 476   | Legionary, Equites, Ballista                  |
| Mongol Empire     | 1206 – 1368      | Horse Archer, Lancer, Mangonel                |
| New Kingdom Egypt | 1550 – 1070 BC   | Khopesh Warrior, Chariot, Nubian Archer       |
| Sasanian Persia   | AD 224 – 651     | Immortal, Cataphract, War Elephant            |
| Aztec Empire      | 1428 – 1521      | Jaguar Warrior, Eagle Warrior, Atlatl Thrower |

Enemy armies have `4 + 1.5 × battle` troops (capped at 40), and their stats grow 10% per battle.

## Tuning

All the numbers are at the top of the script in `index.html`: `UNITS`, `EMPIRES`, `CARDS`,
`ENEMY_CAP`, `ARMY_CAP`, `victoryGold`, `recruitCost` and the scaling in `makeEnemy`.

## Art and animation

**Sprites:** troops are hand-authored pixel grids (one character per pixel) in `index.html`:
`BODY`, `HEADS`, `SHIELDS`, `WEAPONS`, `HORSE_A/B`, `CART`, `ELEPHANT`, `SIEGE_BASE`,
`CAT_ARM` and `BALLISTA_TOP`. `getSprite()` builds each troop from those parts and recolors them
with the empire's palette. The weapon and the catapult arm are separate pieces, so they can swing.

**Animation:** the `FX` object is a motion layer that knows nothing about the art. It only outputs
a pose: an offset, squash and stretch, a rotation, a weapon swing angle, a catapult arm angle, a
flash amount and whether the troop is visible. `drawSprite()` applies that pose to whatever sprite
it is given, so the art can be redrawn in a new style and every animation still works.

* Movement: hops with squash on landing and stretch in the air, a gallop for riders, idle breathing.
* Attacks: a melee lunge with a wind-up and weapon swing, and a pull-back for archers.
* Hits: a white flash plus spring knockback.
* Artillery: the shot kicks the engine back, then it rolls back and forth on a soft spring.
* Deaths: the troop pops up, topples over, bounces and blinks out.
* Victory: the winning side hops in celebration.
* Effects: dust, sparks, impact bursts and screen shake come from the battle's particle list.
