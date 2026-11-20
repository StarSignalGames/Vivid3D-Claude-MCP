# Scripting API cheat-sheet

Everything here was compiled against the current engine. Namespaces: `OpenTK.Mathematics` (Vector3, Matrix4, Quaternion, MathHelper), `Vivid3D.Core` (ProjectInfo, RunMode, GameManager), `Vivid3D.World` (GraphNode, GameNode, CurrentScene, RayCastHit, ...), `Vivid3D.Input` (GameInput), `Vivid3D.UI` (attributes). Conventions: Y up, **forward is -Z**, `EulerRotation` in **degrees** (all `...Radians` parameters are radians), world units are meters.

## Node transform basics (any `GraphNode`)
`LocalPosition`, `WorldPosition`, `EulerRotation` (local, degrees), `LocalRotation` (Matrix4), `WorldRotation` (Matrix4), `LocalScale`, `WorldMatrix`, `Forward` (-Z world), `Right`. Change `LocalPosition`/`EulerRotation`/`LocalScale` directly. `Parent`, `Children`, `GraphChildren` (typed iteration), `Name`, `IsVisible`, `IsActive`, tags: `AddTag(string)`, `RemoveTag`, `HasTag`, `ClearTags`.

## Move / rotate / align / look (GameNode helpers)
| need | call |
|---|---|
| world-space position | `WorldPosition`, `SetWorldPosition(Vector3)` |
| step towards a point | `MoveToward(worldTarget, maxDistanceThisFrame)` |
| move along a direction | `MoveAlong(direction, distance, TransformSpace.World \| Local)` |
| distance / direction | `GetDistanceTo(worldPos)`, `GetDistanceSquaredTo`, `GetDirectionTo(worldTarget, space)` |
| point forward at target | `LookAt(worldTarget)`, `LookAt(worldTarget, worldUp)`, `AlignToPoint(worldTarget)` |
| smooth turning | `SmoothLookAt(worldTarget, maxRadiansThisFrame)`, `RotateToward(worldDirection, maxRadiansThisFrame)` |
| face a direction | `FaceDirection(direction, space)`, `AlignToVector(direction, space)`, `AlignToVector(direction, twistReference, space)`, `AlignAxisToVector(localAxis, direction, twistReference?)` |
| rotate about an axis | `RotateAround(worldAxis, radians)` |
| absolute world rotation | `SetWorldRotation(Quaternion)` / `SetWorldRotation(Matrix4)` |
| orbit / follow | `Orbit(target, yawRadiansDelta, distance, height)`, `Follow(target, localOffset, smoothing, dt)` |
| space conversion | `TransformPosition(p, space)`, `TransformVector`, `TransformNormal`, `TransformDirection`; inverse: `InverseTransformPosition(worldPoint)`, `InverseTransformVector/Normal/Direction`; `GetRelativePosition(worldPos, space)` |
| ground | `SnapToGround(maxDistance, offset)`, `IsGrounded(probeDistance)` |
| parenting | `AttachTo(newParent, keepWorld: true)`, `Detach(keepWorld: true, addAsSceneRoot: true)` |
`TransformSpace.Local` on the "Transform*" helpers means "input is local, return world"; `World` means "input is world, return local".
Plain `GraphNode` scripts (NodeLogic/Interaction) can do the same through the owner: cast with `GetOwnerNode() as GameNode`, or set `LocalPosition/EulerRotation/LocalScale` directly.

Alignment of *several* nodes at edit time is an editor job: use `align_nodes`, `place_on_ground`, `align_to_node`, `look_at` (MCP tools); in script code use the helpers above and `CurrentScene.TryGetWorldBounds(node, out BoundingBox b)` (`b.Min`, `b.Max`) for bounds.

## Raycasts and picking
Result type `RayCastHit`: `Hit`, `Distance`, `Fraction`, `Position`, `Normal`, `BackFacing`, `RayOrigin`, `RayDirection`, `HitNode`, `HitComponent`, `TriangleIndex`, `HitGameNode`.
| from | call |
|---|---|
| a node | `RayCast(direction, maxDistance, space)`, `bool RayCast(direction, maxDistance, out RayCastHit hit, space)`, `RayCastTo(Vector3)`, `RayCastTo(GraphNode)`, `RayCastForward(d)`, `RayCastDown(d)`, `RayCastUp(d)`, `RayCastWorldUp(d)` |
| the scene | `CurrentScene.RayCast(from, to)`, `RayCastBatch(starts, ends)`, `GroundCast(origin, maxDistance)`, `TryGetGround(origin, out hit, maxDistance)` |
| the camera / mouse | `CurrentScene.MousePick()`, `MousePick(Vector2 screen)`, `CameraPick(screen)`, `CameraRayCast(maxDistance)`, `CursorRayCast()`, `TryScreenToWorldRay(screen, out origin, out end)` |
| visibility | `CurrentScene.HasLineOfSight(from, to, ignoreNodes?)`, `HasLineOfSight(GraphNode, GraphNode)` |
Always check `hit.Hit` before using the rest.

## Scene queries (`CurrentScene`)
`FindNodeByName(name, recursive: true)`, `FindNode<T>()`, `FindNodes<T>()`, `FindNodesWithTag(tag)`, `FindNearest<T>(position, maxDistance)`, `FindInRadius<T>(position, radius)`, `OverlapSphere(center, radius, ignore?)`, `OverlapBox(center, halfExtents, ignore?)`, `AllGameNodes()`. Node-relative: `FindChildByName`, `FindChild<T>()`, `FindChildList<T>()`, `GetChild<T>()`, `GetChildList<T>()`, `GetComponent<T>()`, `GetComponentList<T>()`, `FindComponent<T>()` (recursive), `GetOrAddComponent<T>()`, and on any node `GetInteraction<T>()`, `GetLogic<T>()`, `Interactions`, `Logics`.
Creating/removing: `CurrentScene.Spawn<T>(position, name)` (T : GraphNode), `SpawnModel(path, position, name)`, `Destroy(node)`, `Load(scenePath)` / `Open(...)`.

## Physics
- Collider setup on the node (properties): `PhysicsType` (Cube, Sphere, Capsule, TriMesh, Convex, Terrain, Vehicle, None), `IsStatic`, `Mass` ("Weight", kg; 0 = from shape), `Friction` (0-1, default 0.2), `Restitution` (0-1, default 0.6), `CollisionLayer`. Set them with `set_property` at edit time or in `OnInit`. Physics bodies exist while playing.
- Motion on a `GameNode`: `LinearVelocity`, `AngularVelocity` (get/set), `AddImpulse(v[, space])`, `AddForce(v[, space])`, `AddTorque(v[, space])`, `AddAngularImpulse(v[, space])`, `ForceDynamicPhysics()`, `GetPhysicsRotation()`, `EnableSpacePhysics(mass, linearDamping, angularDamping)`, `EnableStaticSphereBody(restitution, friction[, radius[, bodyWorldY]])`.
- Collision callback: override `OnCollisionEntered(GraphNode other, in CollisionContact contact)` in a GraphNode/GameNode subclass; `contact.Point`, `contact.ImpactStrength`. Collision FX/sound can also be configured on the node (`CollisionFxPath`, `CollisionSoundPath`).
- Trigger volumes: `CollisionBoxNode` + a NodeInteraction (Entered/Left): see node-interactions.md. Overlap queries: `OverlapSphere/OverlapBox`.

## Timing and tweens (GameNode)
`InvokeAfter(seconds, Action)` (returns an id), `TweenTo(worldTarget, duration, onComplete)`, `TryUseCooldown(name, seconds)` (true and starts the cooldown if ready), `IsOnCooldown(name)`. Per-frame code receives `dt` (seconds); multiply speeds by it.

## Input (`GameInput`)
Actions (work only in game-mouse mode, i.e. not while a GUI has the cursor): `IsActionDown/Pressed/Released("Jump" (Space) | "Fire" (LMB) | "Interact" (E) | "ShowQuestPath" (Q) | "Sprint" (Shift) | "Crouch" (C/Alt))`, `GetMovement()` (WASD as Vector2), `GetLook()` (mouse delta), `GetAxisValue("Horizontal"|"Vertical"|"LookHorizontal"|"LookVertical"|"MouseX"|"MouseY")`. Raw: `IsKeyDown/IsKeyPressed(Keys.X)` (`using OpenTK.Windowing.GraphicsLibraryFramework;`), `IsButtonDown/Pressed/Released((int)MouseButton.Left)`, `MouseX`, `MouseY`, `MouseScrollDelta`. `GameInput.BlocksGameplayInput` is true when the mouse is in GUI mode; `GameInput.SetMouseMode(MouseMode.Game | GUI)` switches.

## Effects, audio, camera, animation
`CurrentScene.PlayFX(fxAssetPath, worldPosition)`, `PlaySound(path, volume)`, `PlaySoundAt(path, position, volume, maxDistance)`, `Shake(amplitude, seconds)`, `ActiveCamera`; `node.PlayAnimation(name)`, `SetStaticMesh(path)`, `SetSkeletalMesh(path)`, `SetBlendSpace(path)`; `NavAgent` / `NavMeshComponent` exist for pathfinding (look at the project's own AI scripts for usage). `ProjectInfo.CurrentRunMode` (`Stopped|Playing|Paused`) tells you if the scene is playing.

## Idioms
- Guard null and `Hit`: `var hit = RayCastForward(5f); if (hit.Hit && hit.HitNode != null) { ... }`.
- Frame-rate independence: `pos += dir * speed * dt`.
- Prefer queries by tag over hard-coded names: `node.AddTag("Enemy")` in `OnInit`, `CurrentScene.FindNodesWithTag("Enemy")`.
- Don't allocate every frame in `Update`/`OnUpdate`: cache lists and nodes.
- Keep per-frame work in `Update`/`OnUpdate`/`UpdateInteraction`; use callbacks for one-off events.
- Log with `Console.WriteLine` (or `Log` in NodeLogic): it appears in the editor console and the MCP `console` tool.
