# FeatherEdge for SketchUp

> **Cursor asset setup:** place a fully transparent PNG named `face_pick_cursor_blank.png` inside `featheredge/assets/`. Use a square image (at least 32×32 pixels) with an RGBA channel and the hotspot at the top-left pixel (0,0). The plugin replaces SketchUp's system cursor with this asset when the face selection tool is active; without it, the tool falls back to the default arrow cursor.

FeatherEdge is a SketchUp 2023–2024 extension that generates parametric bevel siding (featheredge / bevel siding) on any planar face. The plugin follows a data-driven architecture with two parametrisation modes, component-based board reuse, and a responsive HtmlDialog UI with live validation and preview feedback.

## Features

- **Two authoring modes**
  - *От доски* — specify the board geometry (`t_top`, length, bevel angle) and optionally override the derived course step.
  - *От разбиения* — specify the desired number of courses, `t_top`, and bevel angle; the extension derives the step and `t_bot` automatically.
- **Interactive face tool** with custom cursor, hover feedback, orientation flipping (`R`), and LOD previews rendered in `onViewDraw`.
- **Component-driven boards** built once per profile (wedge cross-section extruded along local U), with per-instance metadata for downstream trimming and editing.
- **Stripe tessellator** that clips arbitrary face polygons (including holes) into course polygons and board segments inside each stripe.
- **HtmlDialog UI** with live validation, unit conversion (mm ↔ SketchUp units), warnings, and preview/create actions.
- **Attribute persistence** storing full parameter sets, orientation vectors, and group transforms for round-trip editing.
- **Material helper** providing a default "Cladding — Wood" material with consistent colouring.

## Installation

1. Copy the repository contents into your SketchUp `Plugins` directory (e.g. `~/Library/Application Support/SketchUp 2024/SketchUp/Plugins` on macOS).
2. Ensure the folder is named `featheredge` and includes the root loader `featheredge.rb`.
3. Launch SketchUp (2023 or 2024). The extension registers automatically under **Extensions → FeatherEdge**.

## Usage

1. Activate **Extensions → FeatherEdge → Создать обшивку (featheredge)…** or press the assigned shortcut (default `Shift+F`).
2. Hover over a planar face to see the preview outline, click to select it, then configure parameters in the dialog.
3. Toggle preview LOD or flip orientation (`R`) as needed. The dialog warns about invalid combinations (e.g. negative `t_bot`).
4. Press **Создать** to generate the cladding group. The extension stores metadata inside the group for later editing.
5. To edit existing cladding, select its group, choose **Extensions → FeatherEdge → Правка обшивки…**, adjust parameters, and confirm.

## Repository Structure

```
featheredge.rb                   # Extension loader
featheredge/
├── app.rb                       # Application wiring (dialog/tool/attributes)
├── commands/                    # UI::Command implementations
├── core/                        # Geometry + data pipeline (orientation, tessellation, packing)
├── materials/                   # Material helpers
├── model/                       # Parameter model + validation
├── support/                     # Utilities (logging, units, persistence)
├── tool/                        # FacePickTool implementation
└── ui/                          # HtmlDialog controller and assets
```

## Development Notes

- The geometry pipeline works in local face space (U/V/N) to keep math robust and transforms explicit.
- `Model::Params` normalises input data, provides derived values (`W`, `t_bot`, etc.), and exposes warnings for the UI.
- `Core::StripeTessellator` performs polygon clipping to produce course segments; `Core::CoursePacker` fills each segment with scaled component instances, embedding per-instance metadata for future refinement.
- `Core::Intersector` currently removes boards entirely outside the face polygon and flags partial intersections (future releases can implement precise clipping).
- Long operations run inside a single SketchUp operation for undo/redo safety; the architecture is ready for future batching with timers.

## License

This project is provided as-is under the MIT license. See `LICENSE` (add one if needed) for details.
