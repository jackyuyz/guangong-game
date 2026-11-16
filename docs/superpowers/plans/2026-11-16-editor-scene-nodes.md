# Godot editor-visible scene migration

User approved migrating the existing demo's background, actors and UI to authored scene nodes while retaining combat/checkpoint behavior. Work in the current project so the editor the user already opened sees the changes; preserve existing uncommitted files. No commits or external publishing requested.

## File boundaries
- `scenes/main.tscn`: composition root: level, CanvasLayer UI, audio.
- `scenes/levels/dongling_pass.tscn` + `scripts/level_view.gd`: authored backdrop, floor, camera, tutorial props, companions, guards and boss. Cache authored spawn transforms; runtime only applies presentation state.
- `scenes/characters/{guan_yu,guard,kong_xiu}.tscn` + `scripts/actor_view.gd`: real Sprite2D, foot anchor, shadow, attack warning and health bar; static source pixels remain unchanged.
- `scenes/ui/game_ui.tscn` + `scripts/game_ui.gd`: authored Control/Button/Label/ProgressBar nodes, theme, UI action signal and state-to-text updates. Runtime must not reconstruct node layout or overwrite authored offsets.
- `scripts/combat_effects.gd`: procedural blade arcs, trails and particles only.
- `scripts/main.gd`: retain combat/state/checkpoint/save behavior; drive view nodes and consume real button signals instead of hand-drawn click rectangles.

## Steps
1. Run baseline smoke checks. Add a scene integration test that fails on current single-node scene: editor-time instantiated textures/UI present without running scripts, runtime native buttons trigger actions, actor positions/warnings/health reflect game state, hidden modal layers block clicks, wave/checkpoint presentation resets correctly.
2. Author reusable actor and level scenes and migrate world rendering. Use the same selected assets and tune against the original screenshot. Spawn positions come from scene nodes.
3. Author UI scene/theme and replace custom UI drawing/click handling. Keep keyboard input and existing story data. Verify no duplicated Enter handling from Button focus.
4. Run integration and existing gameplay smoke tests, visually inspect the actual editor and runtime, re-export single-thread Web, update project documentation.

## Validation
Godot headless import; `scripts/smoke_test.gd`; `scripts/scene_test.gd`; desktop editor screenshot (without F5); desktop and Web screenshots/input; `git diff --check`.

## Review focus
Authored transforms and UI offsets survive runtime syncing; actual nodes are packed in TSCN rather than generated only at runtime; mouse/keyboard/modal events do not leak; invisible enemies and dead/retried actors don't remain visible; editor scene loading doesn't read saves or play audio.

## User scope extension
User subsequently authorized Claude Fable 5.2 medium or Opus 5.5 high as collaborator, new gameplay beyond the original spec, and more animation frames from existing assets. Claude Code CLI model `claude-opus-5-5`, effort high, implemented the isolated combat_extensions module and tests. Lead integrates K guard/parry, L resource-heavy strike, E one-use roadside rest, and reviews its interactions with checkpoint logic. Built-in imagegen produced three transparent 4x2 reference-based sheets (Guan Yu, guard, Kong Xiu), consumed via real AnimatedSprite2D/SpriteFrames resources; originals stay untouched.

## Progress
- Baseline: 19 original smoke checks passed.
- RED: editor-scene test failed on four missing node hierarchies as expected.
- Scene/UI migration GREEN: 22 integration checks and 19 original checks passed before animation/extension integration.
- Claude module: 54 isolated checks passed; integrated verification still in progress.
