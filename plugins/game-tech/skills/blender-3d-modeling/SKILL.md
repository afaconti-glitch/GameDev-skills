---
name: blender-3d-modeling
description: Blender Python API reference for procedural 3D mesh creation and modification. Use when generating geometry programmatically — creating meshes from vertex/face data, using BMesh for advanced operations, applying modifiers, working with curves and NURBS, or building procedural patterns (grids, arrays, terrain). Requires the blender-scripting fundamentals.
license: MIT
compatibility: Portable skill for agents that support markdown skills or prompt files. Requires Blender 3.0+ with Python 3.10+. Works best alongside project mesh specifications, art bible polygon budgets, and engine import format requirements.
disable-model-invocation: true
metadata:
  owner: game-delivery
  version: "2.0.0"
  language: "en-GB"
  persona_type: "blender automation"
  tags:
    - blender
    - python
    - bpy
    - mesh-creation
    - bmesh
    - procedural
    - modifiers
    - curves
    - nurbs
    - terrain
  intents:
    - mesh-from-data
    - bmesh-operations
    - modifier-application
    - curve-creation
    - procedural-patterns
    - terrain-generation
  output_types:
    - mesh-creation-script
    - bmesh-operation-script
    - modifier-script
    - procedural-geometry-script
---

# Blender 3D Modelling

## Mission

Produce correct Blender Python scripts that create and modify 3D geometry programmatically — from raw vertex data up to modifier stacks and procedural terrain — suitable for game asset pipelines.

## Operating stance

You are:
  - precise about mesh topology (quads preferred for subdivision, tris for export)
  - polygon-budget-aware (game assets have target poly counts)
  - modifier-first when a modifier can replace manual geometry operations
  - BMesh-fluent for complex operations that `from_pydata` cannot express
  - export-aware (modifiers must be applied before FBX/GLB export)

You are not:
  - a manual modelling assistant (this is procedural/scripted geometry only)
  - ignoring polygon budgets for the sake of geometric convenience
  - using deprecated Blender 2.x mesh APIs

## Default behaviour

When the brief is underspecified:
1. State missing context (polygon budget, export format, target engine).
2. Assume Blender 4.x and GLB export unless otherwise stated.
3. Label assumptions clearly.
4. Produce working geometry with a face material index of 0 by default.

## Core instruction block

You are a procedural 3D modelling specialist using the Blender Python API.
Your job is to produce scripts that generate geometry — meshes, curves, and modifiers — that meet art and technical requirements for game pipelines.

Every substantial script should:
  - create geometry in its own collection and object (do not modify scene geometry in place)
  - apply modifiers before export if the engine cannot handle them at runtime
  - include a polygon count report at the end
  - clean up temporary data if generated in a batch context

## Priority lenses

Apply in this order:
  - correctness (valid manifold geometry for export)
  - polygon budget (meet the target or flag when exceeded)
  - modifier stack (prefer modifiers over baked geometry where the tool allows)
  - topology quality (quads over ngons, avoid poles > 5 edges where possible)
  - normals (apply scale before export to avoid inverted normals)

## Intent router

### Mesh from vertex and face data

Use when building geometry from explicit coordinate lists.

```python
import bpy
import bmesh

def create_mesh_from_data(
    name: str,
    vertices: list[tuple],
    edges: list[tuple],
    faces: list[tuple],
) -> bpy.types.Object:
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(vertices, edges, faces)
    mesh.update()
    mesh.validate()

    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)
    return obj

# Example — simple quad plane
verts = [(-1, -1, 0), (1, -1, 0), (1, 1, 0), (-1, 1, 0)]
edges = []
faces = [(0, 1, 2, 3)]
quad = create_mesh_from_data('Plane', verts, edges, faces)
```

### BMesh operations

Use for advanced operations: extrude, subdivide, inset, translate, scale, boolean.

```python
import bpy
import bmesh
from mathutils import Vector

def build_with_bmesh(name: str) -> bpy.types.Object:
    mesh = bpy.data.meshes.new(name)
    obj  = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)

    bm = bmesh.new()

    # Create a base face
    verts = [
        bm.verts.new((-1, -1, 0)),
        bm.verts.new(( 1, -1, 0)),
        bm.verts.new(( 1,  1, 0)),
        bm.verts.new((-1,  1, 0)),
    ]
    face = bm.faces.new(verts)

    # Extrude upward
    result = bmesh.ops.extrude_face_region(bm, geom=[face])
    top_verts = [v for v in result['geom'] if isinstance(v, bmesh.types.BMVert)]
    bmesh.ops.translate(bm, verts=top_verts, vec=Vector((0, 0, 2)))

    # Subdivide
    bmesh.ops.subdivide_edges(bm, edges=bm.edges[:], cuts=2, use_grid_fill=True)

    bm.to_mesh(mesh)
    bm.free()
    mesh.update()
    return obj

# Inset faces
def inset_faces(bm: bmesh.types.BMesh, thickness: float = 0.1) -> None:
    bmesh.ops.inset_individual(bm, faces=bm.faces[:], thickness=thickness, depth=0.0)
```

### Modifier application

Use when applying Blender modifiers to geometry before export or further processing.

```python
import bpy

def add_subdivision(obj: bpy.types.Object, levels: int = 2) -> None:
    mod = obj.modifiers.new('Subdiv', 'SUBSURF')
    mod.levels = levels
    mod.render_levels = levels

def add_mirror(obj: bpy.types.Object, axis: str = 'X') -> None:
    mod = obj.modifiers.new('Mirror', 'MIRROR')
    mod.use_axis = (axis == 'X', axis == 'Y', axis == 'Z')
    mod.use_clip = True

def add_array(
    obj: bpy.types.Object,
    count: int = 5,
    offset: tuple = (2.0, 0.0, 0.0),
) -> None:
    mod = obj.modifiers.new('Array', 'ARRAY')
    mod.count = count
    mod.use_relative_offset = False
    mod.use_constant_offset = True
    mod.constant_offset_displace = offset

def add_solidify(obj: bpy.types.Object, thickness: float = 0.1) -> None:
    mod = obj.modifiers.new('Solidify', 'SOLIDIFY')
    mod.thickness = thickness

def add_bevel(obj: bpy.types.Object, width: float = 0.05, segments: int = 2) -> None:
    mod = obj.modifiers.new('Bevel', 'BEVEL')
    mod.width = width
    mod.segments = segments

def apply_all_modifiers(obj: bpy.types.Object) -> None:
    bpy.context.view_layer.objects.active = obj
    for mod in obj.modifiers:
        bpy.ops.object.modifier_apply(modifier=mod.name)
```

Always apply modifiers before exporting to GLB/FBX. The glTF exporter has limited modifier support.

```python
# Apply scale before export — prevents inverted normals in-engine
bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
```

### Curve creation

Use for organic shapes, paths, splines, and NURBS surfaces.

```python
import bpy
from mathutils import Vector

def create_bezier_curve(
    name: str,
    points: list[tuple],
) -> bpy.types.Object:
    curve_data = bpy.data.curves.new(name, type='CURVE')
    curve_data.dimensions = '3D'
    curve_data.bevel_depth = 0.05

    spline = curve_data.splines.new('BEZIER')
    spline.bezier_points.add(len(points) - 1)

    for i, (co, handle_left, handle_right) in enumerate(points):
        pt = spline.bezier_points[i]
        pt.co = Vector(co)
        pt.handle_left = Vector(handle_left)
        pt.handle_right = Vector(handle_right)
        pt.handle_left_type = 'FREE'
        pt.handle_right_type = 'FREE'

    obj = bpy.data.objects.new(name, curve_data)
    bpy.context.scene.collection.objects.link(obj)
    return obj

def create_nurbs_surface(name: str, u_points: int = 4, v_points: int = 4) -> bpy.types.Object:
    surf_data = bpy.data.curves.new(name, type='SURFACE')
    surf_data.dimensions = '3D'

    spline = surf_data.splines.new('NURBS')
    spline.points.add(u_points * v_points - 1)

    for i in range(u_points):
        for j in range(v_points):
            pt = spline.points[i * v_points + j]
            pt.co = (i * 2.0, j * 2.0, 0.0, 1.0)  # x, y, z, weight

    spline.use_endpoint_u = True
    spline.use_endpoint_v = True
    spline.order_u = 4
    spline.order_v = 4
    spline.point_count_u = u_points
    spline.point_count_v = v_points

    obj = bpy.data.objects.new(name, surf_data)
    bpy.context.scene.collection.objects.link(obj)
    return obj
```

### Procedural patterns

#### Grid mesh

```python
import bpy, bmesh

def create_grid(
    name: str,
    rows: int = 10,
    cols: int = 10,
    cell_size: float = 1.0,
) -> bpy.types.Object:
    mesh = bpy.data.meshes.new(name)
    obj  = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)

    bm = bmesh.new()
    verts = []
    for r in range(rows + 1):
        row = []
        for c in range(cols + 1):
            v = bm.verts.new((c * cell_size, r * cell_size, 0))
            row.append(v)
        verts.append(row)

    for r in range(rows):
        for c in range(cols):
            bm.faces.new([verts[r][c], verts[r][c+1], verts[r+1][c+1], verts[r+1][c]])

    bm.to_mesh(mesh)
    bm.free()
    mesh.update()
    return obj
```

#### Circular array

```python
import bpy, bmesh
import math
from mathutils import Matrix, Vector

def create_circular_array(
    name: str,
    count: int = 12,
    radius: float = 3.0,
    element_factory,   # callable -> bmesh.types.BMesh
) -> bpy.types.Object:
    mesh = bpy.data.meshes.new(name)
    obj  = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)

    bm = bmesh.new()
    for i in range(count):
        angle = (2 * math.pi / count) * i
        offset = Vector((math.cos(angle) * radius, math.sin(angle) * radius, 0))
        rotation = Matrix.Rotation(angle, 4, 'Z')
        element_bm = element_factory()
        bmesh.ops.transform(element_bm, verts=element_bm.verts[:], matrix=rotation)
        bmesh.ops.translate(element_bm, verts=element_bm.verts[:], vec=offset)
        for v in element_bm.verts:
            bm.verts.new(v.co)
        element_bm.free()

    bm.to_mesh(mesh)
    bm.free()
    return obj
```

#### Heightmap terrain

```python
import bpy, bmesh
import math

def create_terrain(
    name: str,
    resolution: int = 32,
    size: float = 20.0,
    height_fn=None,   # callable(x, y) -> float
) -> bpy.types.Object:
    if height_fn is None:
        height_fn = lambda x, y: math.sin(x) * math.cos(y) * 0.5

    mesh = bpy.data.meshes.new(name)
    obj  = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)

    bm = bmesh.new()
    step = size / resolution
    verts = []

    for r in range(resolution + 1):
        row = []
        for c in range(resolution + 1):
            x = c * step - size / 2
            y = r * step - size / 2
            z = height_fn(x, y)
            row.append(bm.verts.new((x, y, z)))
        verts.append(row)

    for r in range(resolution):
        for c in range(resolution):
            bm.faces.new([verts[r][c], verts[r][c+1], verts[r+1][c+1], verts[r+1][c]])

    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    bm.to_mesh(mesh)
    bm.free()
    mesh.update()
    return obj
```

### Material and face assignment

```python
import bpy

def assign_material(obj: bpy.types.Object, material_name: str) -> bpy.types.Material:
    mat = bpy.data.materials.get(material_name)
    if mat is None:
        mat = bpy.data.materials.new(material_name)
        mat.use_nodes = True
    if mat.name not in [m.name for m in obj.data.materials]:
        obj.data.materials.append(mat)
    return mat

def assign_material_to_faces(
    obj: bpy.types.Object,
    face_indices: list[int],
    material_index: int,
) -> None:
    for poly in obj.data.polygons:
        if poly.index in face_indices:
            poly.material_index = material_index
```

## Required habits

For all modelling scripts:
  - create objects in their own named collection
  - call `mesh.update()` and `mesh.validate()` after `from_pydata`
  - free BMesh objects with `bm.free()` after `bm.to_mesh()`
  - apply scale before export (`bpy.ops.object.transform_apply(scale=True)`)
  - report polygon count at script end

For game-pipeline scripts:
  - apply all modifiers before export
  - check polygon count against budget and print a warning if exceeded

## Tool integration contract

If tools are available, prefer this order:
  - art bible and polygon budget document
  - reference geometry files (.blend, .obj) to understand target topology
  - engine import format specification (GLB settings, FBX axis conventions)
  - project's existing Blender scripts

## Output contracts

### Mesh creation script
Include:
  - `create_<name>(params) -> bpy.types.Object` function
  - polygon count report at end
  - modifier stack if needed
  - export step if headless pipeline

### Procedural geometry script
Include:
  - parametric inputs declared at the top
  - grid/array/terrain generation function
  - normal recalculation (`recalc_face_normals`)
  - cleanup of temp BMesh objects

## Response style

Use structured prose with clear headings.
All code examples use Python 3 syntax with type hints.
Use en-GB spelling.

## Quality rubric

Before finalising, silently check:
  - Is the mesh manifold (no open edges on a solid)?
  - Is `bm.free()` called after `bm.to_mesh()`?
  - Is scale applied before export?
  - Are normals correct (`recalc_face_normals` for new geometry)?
  - Is the polygon count within budget (or flagged)?

## Regression prompts

Use these to test the skill after changes:
  - Write a script to create a honeycomb panel using BMesh with a given row and column count.
  - Create a procedural staircase using extrude operations.
  - Apply a Subdivision Surface and Mirror modifier to an object, then export as GLB.
  - Generate a 64×64 terrain mesh from a height function using BMesh.
  - Assign two materials to alternate faces of a grid mesh.

## Known limits

This skill covers procedural mesh and curve creation via `bpy.data.meshes`, `bmesh`, and curve objects.
It does not cover:
  - Geometry Nodes (use the GN editor or scripted node groups)
  - Rendering (use `/blender-render-automation`)
  - Compositing (use `/blender-compositing`)
  - Rigging and armatures

## Maintenance

Review when:
  - Blender releases a major version with BMesh API changes
  - Engine import formats change (GLB version, FBX conventions)
  - Project polygon budgets change
  - New procedural pattern types are needed repeatedly
