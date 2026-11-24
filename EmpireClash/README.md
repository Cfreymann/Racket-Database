# Empire Clash

A simple 2D army battler. Build your army one card at a time and auto-battle a random historical
empire each round. Each enemy army grows stronger as you go. Lose once and the campaign ends.

This folder is self-contained: one HTML file with no build step and no dependencies other than two
Google Fonts. It is separate from everything else in this repository. Open `index.html` in a
browser to play.

## The loop

1. **Draft:** start a campaign by choosing 1 of 3 cards. After every victory, choose 1 of 3 more.
   * **Troops:** add Swordsmen, Spearmen, Archers, Knights or Catapults.
   * **Upgrades:** health, attack, range, attack speed or healing.
   * **Treasury:** gold now, gold per win, or cheaper recruiting.
2. **Camp:** your scouts reveal the next enemy empire and its army. Spend gold to recruit more of
   any troop type you own, up to 60 troops.
3. **Battle:** armies fight on their own. Your troops start at the bottom and the enemy's at the
   top. You can speed it up 2× or 3×.
4. **Win:** you get gold and a card pick, then a new random empire (never the same one twice in a
   row). **Lose:** the campaign is over, and your best run is saved.

## Counters

* Spearmen (and Immortals) deal double damage to cavalry and elephants.
* Cavalry deals 1.5× damage to ranged troops and siege.
* Eagle Warriors deal 1.5× damage to ranged troops and siege.
* Catapults, Mangonels and War Elephants hit groups.

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
