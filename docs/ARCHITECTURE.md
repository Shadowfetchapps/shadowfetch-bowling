# Architecture

`BowlScorer` is the source of truth for ten-pin scoring. Strikes add the next two rolls. Spares add the next roll. The tenth frame can be two or three balls.

`BowlEngine` wraps the scorer with mode, standing pins, and two-player turn changes. Practice clears a finished card and keeps rolling.

`BowlPins.spots` is a regulation triangle. Standing uses up-dot, height, and pit bounds so a pin that drops through the floor or flies into the pit cannot score again.

The live lane is Jolt. The recorded pin count is the standing-mask delta after settle. CCD, velocity caps, and a thick under-lane slab keep bodies in the world.
