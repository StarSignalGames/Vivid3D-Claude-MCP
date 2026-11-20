# NodeInteraction (in depth)

A `NodeInteraction` is a script attached to a node that reacts to the **player**: aiming at the node and pressing Interact, clicking it, or walking into a trigger volume. It is the standard way to make doors, buttons, levers, pickups, containers, ladders, terminals, conversation starters and trigger zones. It lives in `node.Interactions` (not a scene child), so it works on **any** node: imported meshes, primitives, GameNodes, collision boxes.

## Callbacks (override what you need)
| method | fires when |
|---|---|
| `Clicked()` | The player aims at the node (center of the screen, within range) and presses **Interact (E)**, or the engine/an event "clicks" it. **E routes through `Clicked`**, so put the main action here. |
| `DoubleClicked()` | Double click on the node. |
| `Used()` | Explicit "Use" (events/scripting call it via `InvokeFirstUsed`). Normally make it call the same method as `Clicked`: `public override void Used() => Clicked();` |
| `Entered()` / `Left()` | The player (or a physics body) enters/leaves a **trigger volume**: needs a `CollisionBoxNode` (see below). Not driven by the crosshair. |
| `UpdateInteraction(float dt)` | **Every frame while the scene is playing** (and the node is visible), regardless of aiming. Use it for animations/timers (a door sliding, a lever rotating). |
| `OnAttach()` / `OnDetach()` | When added to / removed from a node (including scene load). |

Inside, `GetOwnerNode()` (or `Node`) is the node the script is on (`GraphNode?`; check null; cast to `GameNode` if you need GameNode API). `IsActive` on the interaction disables it (an inactive interaction is skipped). Exceptions in callbacks are caught and printed as `[NodeInteraction] Clicked() threw on X: ...`.

## The node flags that make it work (properties of the node, not the script)
Set with `set_property {node, property, value}` (or `attach_script`, which turns `Interaction` on for you):
| property | default | meaning |
|---|---|---|
| `Interaction` | off | The node takes part in aim/Use prompts. **Must be on for Clicked/Used via aiming.** |
| `InteractionRange` | 3 | Max distance (world units, 0.1-100) from the camera at which it can be interacted with. |
| `InteractionCollision` | Tris | What the aim ray tests: `Tris` (exact mesh), `Cube` (world bounding box, cheap, good for thin/complex meshes), `Convex` (convex hull). |
| `UseOnce` | off | Limits Entered/Clicked/DoubleClicked/Used to a single combined fire, and `Left` to one fire after `Entered`. |
| `DisplayInteraction` | on | Draws the `Use:<NodeName>` prompt above the hit point while aimed (and a usable interaction exists). Name your node meaningfully: the prompt shows `node.Name`. |
| `Carryable` / `Pickupable` | off | Carry/pickup items: aiming draws a selection outline; for `Carryable` the E key is owned by the game project, not Clicked. |

The script itself also has `ColliderForPlayer` (bool): for `Entered`/`Left` only react to colliders that are a `GameNode` with `IsPlayer` (e.g. the FPS controller).

## How aiming works (play mode)
Every frame the engine casts a ray through the **center of the play viewport**, up to the largest `InteractionRange` in the scene (min 3). The first hit is walked up its parent chain to the first node that has `Interaction`, `Carryable` or `Pickupable`; if the hit distance is within that node's `InteractionRange` it becomes `NodeInteractionSystem.CurrentTarget`. Pressing E then calls `Clicked()` on **all interactions of the nearest node-or-ancestor that has any** (so you can put the interaction on a parent and aim at any child mesh). A thing blocking the ray (a wall in front) prevents the target. Static state you can read in scripts: `NodeInteractionSystem.CurrentTarget`, `HitPoint`, `CurrentDistance`, `HasTarget`, `LastInteractedNodeName`, `InteractionGeneration`.

## Trigger volumes: Entered / Left
1. `create_node {kind:"collision_box", name:"AlarmZone", position, scale}` (a `CollisionBoxNode`).
2. Turn its `Interaction` property on (`attach_script` does this) and attach the interaction (`ZoneAlarm`) to **that box**.
3. Anything that overlaps the box counts if it is an active `GameNode` that is the player (`IsPlayer`), an `FPSController`, or a physics-enabled node (`PhysicsType != None`). Probe size is about 0.35 x the node's largest scale (min 0.15), or the capsule for an FPS controller. With `ColliderForPlayer = true` only the player triggers it.
`Entered` fires once on overlap start, `Left` once when it ends (only after an `Entered`).

## Patterns
**Door / drawer / lever (animate in UpdateInteraction):** toggle a flag in `Clicked`, ease a value towards 0/1 in `UpdateInteraction`, write the owner's `LocalPosition`/`EulerRotation` from the closed pose captured the first time. (Template in script-templates.md.)

**Pickup:** `Clicked()` -> give the item to your game system, then remove it: `CurrentScene.Destroy(GetOwnerNode())` or hide with `owner.IsVisible = false`.

**Button that drives something else:** find the target at click time and call its script: `var door = CurrentScene.FindNodeByName("Door"); door?.GetInteraction<SlideDoor>()?.Clicked();` (`GraphNode.GetInteraction<T>()`, `GetLogic<T>()`, `GetComponent<T>()`).

**Run an event file:** the engine class `NodeInteractionEvent` (property `EventPath`, a project-relative `.event` asset) starts that event on Clicked/Used. `attach_script {script:"NodeInteractionEvent", node, values:{EventPath:"content/events/intro.event"}}` (engine types attach the same way). Subclass it to add a gate: override `Clicked()` and call `StartBoundEvent()` when your condition holds.

**One-shot:** set the node's `UseOnce` property instead of writing your own flag.

**Several interactions on one node** all fire on Clicked; order = attach order. Use `InvokeFirst*` if only the first should run.

## Calling interactions from code
`NodeInteractionSystem.InvokeClicked(node)` (all interactions of the owner), `InvokeFirstClicked/InvokeFirstUsed/InvokeFirstDoubleClicked(node)` (first only), `InvokeEntered(node)` / `InvokeLeft(node)`. The MCP tool `invoke_interaction {node, mode:"click"|"use"|"doubleclick"|"entered"|"left"}` wraps these for testing.

## Gotchas
- `UpdateInteraction` **does not run in edit mode**: a click made while stopped changes state but nothing animates until you `play start`. When testing, `play start` first, then `invoke_interaction`.
- Hidden nodes (`IsVisible = false`, or a hidden ancestor) are **not ticked**.
- The player and held items are excluded from aiming (`IsPlayerNode`).
- Don't capture the owner in a field once and trust it forever; call `GetOwnerNode()` (it can be null when detached).
- State in instance fields resets when play stops (the scene is reloaded from its snapshot).
- Forgetting `Interaction = true` on the node is the #1 reason "nothing happens on E". Second: the node is farther than `InteractionRange`, or the aim ray is blocked.
- Fix the visible prompt text by renaming the node (`rename_node`), not by editing the script.

## Test recipe with the MCP tools
1. `create_node {kind:"cube", name:"Door", position:[0,1,-5], scale:[2,2,0.2]}`
2. `attach_script {script:"SlideDoor", node:"Door", values:{Amount:2.5}}` -> `node_detail {node:"Door"}` shows it under `interactions` with its properties.
3. `play {action:"start"}`; `invoke_interaction {node:"Door", mode:"click"}`; wait a second; `exec_csharp` -> `Find("Door").LocalPosition` (or `screenshot`).
4. `console` for your `Console.WriteLine`/`Log` lines; `play {action:"stop"}`.
5. Tweak a value without recompiling: `set_property {node:"Door", interaction:"SlideDoor", property:"Amount", value:4}` (undoable).
