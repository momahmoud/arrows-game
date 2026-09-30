# Arrow visual system

How board arrows are drawn. Rendering only: gameplay, level data, paths,
hit testing and movement rules are defined elsewhere and are not affected
by anything here.

- Renderer: `lib/game/components/arrow_component.dart` (Flame `ArrowComponent.render`)
- Constants: `lib/game/components/arrow_visual_config.dart` (`ArrowVisualConfig`)

## Visual language

A thin, high-contrast line that winds through the grid and ends in a compact
filled arrowhead. No gradients, no 3D, no outlines, no icons. Default arrows
use the theme's ink colour (`AppColors.arrowUp`: dark on light boards, light
on dark boards). Only arrows that belong to a colour group are coloured.

## Geometry

An arrow's path is a list of cell centres: `path[0]` is the head,
`path.last` is the tail. The renderer never changes these coordinates; it
only decides how to draw a line through them.

Every size is a ratio of the cell size (`ArrowVisualConfig.unit(cellSize)`),
so arrows keep the same proportions on every board and device. `unit` only
grows past the real cell size when the shaft would drop below the 2 px
hairline floor (`minShaftWidth`); the head scales with it, so proportions
never break.

| Constant                 | Value | Meaning                                         |
| ------------------------ | ----- | ----------------------------------------------- |
| `shaftWidthRatio`        | 0.16  | Stroke width of the shaft                       |
| `cornerRadiusRatio`      | 0.28  | Centre-line radius of every bend                |
| `arrowHeadLengthRatio`   | 0.34  | Tip to base of the head                         |
| `arrowHeadWidthRatio`    | 0.44  | Full width across the head base                 |
| `arrowHeadRoundingRatio` | 0.09  | Stroke over the head that rounds its corners    |
| `arrowHeadInsetFraction` | 0.7   | Share of the head length the shaft reaches into |

### Shaft

One continuous `Path`, stroked once with `StrokeCap.round` and
`StrokeJoin.round`. The thickness is identical on horizontal and vertical
segments because it is one stroke, not a set of rectangles.

The shaft starts inside the head: the path is trimmed by
`headInset` measured along the path itself (`ArrowVisualConfig.trimStart`).
Trimming along the path rather than along the heading means the shaft never
backtracks when the head sits right next to a bend.

A one-cell arrow has no second point, so it gets a short stub behind the head
(`singleCellTailFraction` head lengths).

### Corners

Each turn is replaced by a true circular arc (`roundedPolyline`, a conic with
weight `cos(turn / 2)`). The radius is the same for every arrow and level.
It is capped so two consecutive one-cell turns never overlap: inner segments
give at most half their length to each bend, while end segments may be used
up completely (an arrow halfway round a corner mid-slide). Straight runs and
zero-length segments pass through untouched, so the line never spikes or
doubles back.

### Arrowhead

A symmetric triangle built on the heading: tip on the head cell centre, base
`headLength` behind it, `headHalfWidth` either side. It is filled, then
stroked with the same colour at `headRounding` width so the three corners are
round. The shaft end sits `0.7` of the head length inside the triangle, so
head and shaft overlap with no seam or gap and read as one shape.

## Colour and groups

Colour is resolved once per frame in `_color()`, in this order:

1. Blocked (state or bump animation): `blockedColor`
2. Blocker of a failed move: pulsing red
3. Hint: yellow
4. Ruler highlight: green
5. Colour group: `AppColors.getGroupColor(colorGroup)`
6. Otherwise: default ink `AppColors.arrowUp`

Then the active arrow skin tints it (`BoardStyle.tintArrow`).

### Paired / grouped arrows

Groups come from the existing `ArrowModel.colorGroup` field. The renderer
only reads it; it never creates, merges or renames groups.

Both arrows of a group must look identical apart from their path. For group
arrows the skin tint is salted by the group number, not the arrow id, so
every arrow in a group gets exactly the same colour under every skin.
Ungrouped arrows keep the per-arrow salt, which gives skins their variety.

Colour never changes geometry: shaft width, corner radius and head
proportions are the same constants for every group and for ungrouped arrows.

Colour-lock arrows (`SnakeMechanic.colorLock`) also carry a small white ring
with a colour centre on the tail, sized by `lockRingOuterRatio` and
`lockRingInnerRatio`.

## States

| State                    | Rendering                                                                                                                      |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------ |
| Idle                     | Static cached path                                                                                                             |
| Pressed                  | Scales to `pressedScale` around the path centre, eased by `pressResponse`                                                      |
| Blocked                  | Bump toward the blocker and back, a damped rotation shake (`blockShakeAngle`, `blockShakeFrequency`), temporary `blockedColor` |
| Colour-locked tap        | Short sideways rattle                                                                                                          |
| Blocker of a failed move | Pulsing red glow under the shaft (`blockerGlowWidthRatio`)                                                                     |
| Hint                     | Pulsing yellow glow (`hintGlowWidthRatio`)                                                                                     |
| Exiting                  | Colour lightened by `exitLighten` plus a flash (`exitFlashLighten`), a soft trail behind the tail                              |
| Erased                   | Fades out and shrinks slightly                                                                                                 |

None of these change the arrow's geometry permanently; the path is redrawn
unchanged once the effect ends.

## Movement

Movement reuses the existing track: a precomputed polyline from off-board
(following any deflection dots) through the arrow's cells. Each frame the
visible slice between the animated head and tail distances is taken, and the
same shaft and head builders draw it, so bends are rounded while moving too.

The head points along the first vertex behind it that is not sitting on the
tip, so it follows the real direction after a deflector instead of falling
back to the model's original direction. While moving, the heading eases onto
the new direction at `headTurnRate` per second, so a 90° deflection turns
smoothly instead of snapping. Shaft and head use the same heading in a frame.

## Performance

- Idle arrows reuse a cached shaft `Path`; it is rebuilt only when the cell
  size, path, direction or state changes.
- Moving arrows build one shaft path and one head path per frame; nothing else.
- Shaft, head and glow `Paint` objects are fields on the component and reused
  every frame.
- An arrow draws with three calls: shaft stroke, head fill, head stroke.
- Blur is used only for short-lived feedback (hint, blocker, exit), never for
  idle arrows.
