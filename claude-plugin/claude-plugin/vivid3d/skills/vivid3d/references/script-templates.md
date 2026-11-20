# Script templates

All templates below compile against the current engine (checked in a live editor). Adjust namespaces to match the project's existing scripts. File name = class name. After writing: `recompile_scripts`, `list_scripts`, `attach_script`.

## NodeInteraction: sliding door (`Code/Interactions/SlideDoor.cs`)
```csharp
using System;
using System.ComponentModel;
using OpenTK.Mathematics;
using Vivid3D.UI;
using Vivid3D.World;

/// <summary>Slides the owner node along its local X when used (E / click).</summary>
public class SlideDoor : NodeInteraction
{
    [DisplayName("Amount"), Description("Distance the door slides when open (metres).")]
    [Range(-10f, 10f)]
    public float Amount { get; set; } = 2f;

    [DisplayName("Duration"), Description("Seconds for a full open/close.")]
    public float Duration { get; set; } = 0.5f;

    private bool _open, _ready;
    private float _t, _from, _to, _u;
    private Vector3 _closedPos;

    public SlideDoor() { Name = "SlideDoor"; }

    public override void Clicked() => Toggle();     // E / click
    public override void Used() => Toggle();        // explicit Use

    private void Toggle()
    {
        GraphNode? owner = GetOwnerNode();
        if (owner == null) return;
        if (!_ready) { _closedPos = owner.LocalPosition; _ready = true; }
        _open = !_open;
        _from = _u; _to = _open ? 1f : 0f; _t = 0f;
    }

    public override void UpdateInteraction(float dt)   // runs every frame while playing
    {
        GraphNode? owner = GetOwnerNode();
        if (owner == null || !_ready) return;
        _t = Math.Min(1f, _t + dt / Math.Max(0.01f, Duration));
        _u = _from + (_to - _from) * _t;
        owner.LocalPosition = _closedPos + new Vector3(Amount * _u, 0f, 0f);
    }
}
```

## NodeInteraction: trigger zone (`Code/Interactions/ZoneAlarm.cs`), attach to a `collision_box` node
```csharp
using System;
using Vivid3D.World;

public class ZoneAlarm : NodeInteraction
{
    public string Message { get; set; } = "Intruder!";
    public ZoneAlarm() { Name = "ZoneAlarm"; ColliderForPlayer = true; }   // only the player triggers it
    public override void Entered() => Console.WriteLine($"[ZoneAlarm] ENTER: {Message}");
    public override void Left()    => Console.WriteLine("[ZoneAlarm] LEFT");
}
```

## NodeInteraction: pickup
```csharp
using Vivid3D.World;

public class PickupItem : NodeInteraction
{
    public string ItemName { get; set; } = "Key";
    public PickupItem() { Name = "PickupItem"; }
    public override void Clicked()
    {
        GraphNode? owner = GetOwnerNode();
        if (owner == null) return;
        // give the item to the project's inventory system here, then take it out of the world:
        CurrentScene.Destroy(owner);
    }
    public override void Used() => Clicked();
}
```

## NodeInteraction: button that triggers another node's interaction
```csharp
using Vivid3D.World;

public class DoorButton : NodeInteraction
{
    public string TargetName { get; set; } = "Door";
    public DoorButton() { Name = "DoorButton"; }
    public override void Clicked()
    {
        GraphNode? target = CurrentScene.FindNodeByName(TargetName);
        target?.GetInteraction<SlideDoor>()?.Clicked();
    }
}
```

## NodeLogic: continuous behaviour (`Code/Logic/Spinner.cs`)
```csharp
using OpenTK.Mathematics;
using Vivid3D.World;

public class Spinner : NodeLogic
{
    public float DegreesPerSecond { get; set; } = 90f;
    public Spinner() { Name = "Spinner"; }
    public override void OnPlay() => Log("start spinning");         // Log prefixes the type and owner name
    public override void OnUpdate(float dt)                        // only while playing
    {
        EulerRotation += new Vector3(0f, DegreesPerSecond * dt, 0f);   // NodeLogic has transform shortcuts
    }
}
```
`NodeLogic` shortcuts: `Node`/`Owner`, `Graph`, `IsPlaying`, `DeltaTime`, `LocalPosition`, `WorldPosition`, `EulerRotation`, `LocalScale`, `Forward`, `Visible`, `GetComponent<T>()`, `GetInteraction<T>()`, `GetLogic<T>()`, `FindChild(name)`, `FindNodeByName(name)`, `FindNode<T>()`, `FindNodesWithTag(tag)`, `HasTag/AddTag/RemoveTag`, `PlayAnimation(name)`, `Log(msg)`.

## GameComponent (`Code/Components/Bobber.cs`), attach to a **GameNode**
```csharp
using System;
using OpenTK.Mathematics;
using Vivid3D.World;

public class Bobber : GameComponent
{
    public float Height { get; set; } = 0.5f;
    public float Speed { get; set; } = 2f;
    private float _time, _baseY; private bool _init;
    public Bobber() { Name = "Bobber"; }

    public override void OnUpdate(float dt)
    {
        var node = Node;                       // the owning GameNode (null if the owner is a plain node)
        if (node == null || !node.IsPlaying) { _init = false; return; }
        if (!_init) { _baseY = node.LocalPosition.Y; _time = 0f; _init = true; }
        _time += dt;
        var p = node.LocalPosition;
        node.LocalPosition = new Vector3(p.X, _baseY + MathF.Sin(_time * Speed) * Height, p.Z);
    }
}
```
`GameComponent.Node` is `Owner as GameNode`. Attaching a GameComponent to a plain node returns an error unless you pass `upgrade:true` (the editor then swaps the node for a GameNode copy: not undoable, new object). Prefer attaching to GameNodes, or use a `NodeLogic`/`NodeComponent` if you do not need `GameNode` API.

## GameNode: a scene node with behaviour (`Code/Nodes/Pacer.cs`)
```csharp
using System;
using OpenTK.Mathematics;
using Vivid3D.UI;      // ShowInEditor
using Vivid3D.World;

public class Pacer : GameNode
{
    [ShowInEditor] public float Range { get; set; } = 3f;     // GameNode subclasses: [ShowInEditor] to show in the inspector
    [ShowInEditor] public float Speed { get; set; } = 1.5f;
    private float _t; private Vector3 _origin;

    public Pacer() { Name = "Pacer"; }

    public override void OnInit()               // on play start and when created from the script
    {
        base.OnInit();
        _origin = LocalPosition;
        // SetStaticMesh("content/mesh/crate.fbx");  or SetSkeletalMesh(...)/SetBlendSpace(...) to give it a model
    }

    public override void Update(float dt)
    {
        base.Update(dt);
        if (!IsPlaying) return;
        _t += dt * Speed;
        LocalPosition = _origin + new Vector3(MathF.Sin(_t) * Range, 0f, 0f);
    }
}
```
`OnPlacedInEditor()` runs only when the node is created from the script (not on scene load); `OnPositionedInEditor()` runs after it has its position (good place to snap to ground).

## Everything at once
`list_scripts` shows the kinds the editor found; `attach_script` puts each where it belongs: GameNode/GraphNode -> new scene node; NodeInteraction/NodeLogic/Component -> onto `node`. Use `values` to set properties; use `set_property {interaction|logic|component}` later; `detach_script` removes; `delete_node` removes a scene node.
