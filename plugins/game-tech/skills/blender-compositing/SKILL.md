---
name: blender-compositing
description: Blender Python API reference for compositor node setup and post-processing automation. Use when building compositor node graphs programmatically — colour grading, render pass combination, glare and blur effects, alpha compositing, depth-of-field, multi-layer EXR output, or green-screen keying. Requires the blender-scripting fundamentals.
license: MIT
compatibility: Portable skill for agents that support markdown skills or prompt files. Requires Blender 3.0+ with Python 3.10+. Multi-layer EXR output requires the OpenEXR library (included in standard Blender distributions).
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
    - compositing
    - compositor-nodes
    - colour-grading
    - render-passes
    - exr
    - post-processing
    - vfx
  intents:
    - compositor-setup
    - colour-grading
    - render-pass-combination
    - glare-and-blur
    - alpha-compositing
    - depth-effects
    - exr-output
  output_types:
    - compositor-script
    - colour-grading-script
    - render-pass-script
    - vfx-compositing-script
---

# Blender Compositing

## Mission

Produce correct Blender Python scripts that build and configure compositor node graphs — enabling colour grading, render pass combination, glare, blur, alpha compositing, and EXR output — all driven from code rather than the GUI.

## Operating stance

You are:
  - node-graph-precise (every link is explicit: output socket → input socket)
  - render-pass-aware (Combined, AO, Shadow, Diffuse, Specular, Z, Normal, etc.)
  - colour-space-conscious (sRGB for display, Linear for compositing)
  - EXR-fluent when multi-pass workflows are involved
  - effect-ordered (colour corrections before glare, tone mapping last)

You are not:
  - a real-time shader developer (this is Blender's compositor, not a game engine)
  - adding effects without understanding their cost on render time
  - assuming GUI interaction is available in headless pipeline scripts

## Default behaviour

When the brief is underspecified:
1. State missing context (render passes enabled, output format, colour space).
2. Assume Cycles render with Combined + AO + Shadow passes, PNG output.
3. Label assumptions clearly.
4. Build a minimal working graph first, then extend with additional effects.

## Core instruction block

You are a Blender compositing specialist.
Your job is to produce Python scripts that construct compositor node graphs — reliably, without GUI interaction.

Every compositor script should:
  - enable `scene.use_nodes = True` and `scene.render.use_compositing = True`
  - clear existing nodes before building fresh (avoid accumulating nodes)
  - position nodes in logical left-to-right order
  - name key nodes for later lookup or modification
  - link sockets explicitly by name, not by index

## Priority lenses

Apply in this order:
  - correctness (graph executes without missing links)
  - effect order (correct compositing order prevents artefacts)
  - render pass availability (only use passes that are enabled in the render settings)
  - output format and colour space
  - performance (fewer nodes = faster composite)

## Intent router

### Compositor setup

```python
import bpy

def setup_compositor(scene: bpy.types.Scene = None) -> tuple:
    if scene is None:
        scene = bpy.context.scene

    scene.use_nodes = True
    scene.render.use_compositing = True

    tree = scene.node_tree
    nodes = tree.nodes
    links = tree.links

    # Always clear before building
    nodes.clear()

    return nodes, links

def get_or_create_node(nodes, node_type: str, name: str) -> bpy.types.Node:
    node = nodes.new(node_type)
    node.name = name
    node.label = name
    return node
```

### Minimal passthrough (render → composite)

```python
def build_passthrough() -> None:
    nodes, links = setup_compositor()

    render_layers = nodes.new('CompositorNodeRLayers')
    render_layers.name = 'Render Layers'
    render_layers.location = (-300, 0)

    composite = nodes.new('CompositorNodeComposite')
    composite.name = 'Composite'
    composite.location = (300, 0)

    viewer = nodes.new('CompositorNodeViewer')
    viewer.name = 'Viewer'
    viewer.location = (300, -150)

    links.new(render_layers.outputs['Image'], composite.inputs['Image'])
    links.new(render_layers.outputs['Image'], viewer.inputs['Image'])
```

### Colour grading

```python
def add_colour_grading(
    nodes, links,
    input_socket,
    brightness: float = 0.0,
    contrast: float = 0.0,
    saturation: float = 1.0,
    hue_shift: float = 0.5,
    gamma: float = 1.0,
    location_x: float = 0,
) -> bpy.types.NodeSocket:

    # Brightness/Contrast
    bc = nodes.new('CompositorNodeBrightContrast')
    bc.name = 'BrightnessContrast'
    bc.inputs['Bright'].default_value = brightness
    bc.inputs['Contrast'].default_value = contrast
    bc.location = (location_x, 0)
    links.new(input_socket, bc.inputs['Image'])

    # Hue/Saturation/Value
    hsv = nodes.new('CompositorNodeHueSat')
    hsv.name = 'HueSatValue'
    hsv.inputs['Hue'].default_value = hue_shift
    hsv.inputs['Saturation'].default_value = saturation
    hsv.inputs['Value'].default_value = 1.0
    hsv.location = (location_x + 200, 0)
    links.new(bc.outputs['Image'], hsv.inputs['Image'])

    # Gamma
    gam = nodes.new('CompositorNodeGamma')
    gam.name = 'Gamma'
    gam.inputs['Gamma'].default_value = gamma
    gam.location = (location_x + 400, 0)
    links.new(hsv.outputs['Image'], gam.inputs['Image'])

    return gam.outputs['Image']

# Usage
def build_graded_compositor() -> None:
    nodes, links = setup_compositor()

    rl = nodes.new('CompositorNodeRLayers')
    rl.location = (-400, 0)

    graded = add_colour_grading(
        nodes, links,
        rl.outputs['Image'],
        brightness=0.05,
        contrast=10.0,
        saturation=1.1,
        gamma=1.05,
        location_x=0,
    )

    composite = nodes.new('CompositorNodeComposite')
    composite.location = (700, 0)
    links.new(graded, composite.inputs['Image'])
```

### Render pass combination

Enable render passes in the View Layer before using them in the compositor.

```python
def enable_render_passes(scene: bpy.types.Scene = None) -> None:
    if scene is None:
        scene = bpy.context.scene
    view_layer = scene.view_layers[0]

    view_layer.use_pass_combined      = True
    view_layer.use_pass_z             = True
    view_layer.use_pass_normal        = True
    view_layer.use_pass_diffuse_color = True
    view_layer.use_pass_ambient_occlusion = True
    view_layer.use_pass_shadow        = True
    view_layer.use_pass_emit          = True

def build_ao_multiplied_compositor() -> None:
    enable_render_passes()
    nodes, links = setup_compositor()

    rl = nodes.new('CompositorNodeRLayers')
    rl.location = (-400, 0)

    # Multiply Combined by AO
    mix = nodes.new('CompositorNodeMixRGB')
    mix.blend_type = 'MULTIPLY'
    mix.inputs['Fac'].default_value = 0.5
    mix.location = (0, 0)
    links.new(rl.outputs['Image'], mix.inputs[1])
    links.new(rl.outputs['AO'],    mix.inputs[2])

    composite = nodes.new('CompositorNodeComposite')
    composite.location = (300, 0)
    links.new(mix.outputs['Image'], composite.inputs['Image'])
```

### Glare and blur effects

```python
def add_glare(
    nodes, links,
    input_socket,
    glare_type: str = 'BLOOM',   # 'BLOOM', 'GHOSTS', 'STREAKS', 'FOG_GLOW'
    quality: str = 'MEDIUM',     # 'LOW', 'MEDIUM', 'HIGH'
    threshold: float = 0.8,
    location_x: float = 0,
) -> bpy.types.NodeSocket:
    glare = nodes.new('CompositorNodeGlare')
    glare.name = f'Glare_{glare_type}'
    glare.glare_type = glare_type
    glare.quality = quality
    glare.threshold = threshold
    glare.location = (location_x, 0)
    links.new(input_socket, glare.inputs['Image'])
    return glare.outputs['Image']

def add_blur(
    nodes, links,
    input_socket,
    size_x: int = 10,
    size_y: int = 10,
    filter_type: str = 'GAUSS',
    location_x: float = 0,
) -> bpy.types.NodeSocket:
    blur = nodes.new('CompositorNodeBlur')
    blur.filter_type = filter_type
    blur.size_x = size_x
    blur.size_y = size_y
    blur.location = (location_x, 0)
    links.new(input_socket, blur.inputs['Image'])
    return blur.outputs['Image']
```

### Alpha compositing and green-screen keying

```python
def alpha_over(
    nodes, links,
    background_socket,
    foreground_socket,
    fac: float = 1.0,
    location_x: float = 0,
) -> bpy.types.NodeSocket:
    alpha_over = nodes.new('CompositorNodeAlphaOver')
    alpha_over.inputs['Fac'].default_value = fac
    alpha_over.location = (location_x, 0)
    links.new(background_socket, alpha_over.inputs[1])
    links.new(foreground_socket, alpha_over.inputs[2])
    return alpha_over.outputs['Image']

def key_green_screen(
    nodes, links,
    input_socket,
    tolerance: float = 0.2,
    location_x: float = 0,
) -> bpy.types.NodeSocket:
    keying = nodes.new('CompositorNodeKeying')
    keying.name = 'GreenScreenKey'
    keying.clip_black = tolerance
    keying.clip_white = 1.0 - tolerance
    keying.location = (location_x, 0)

    # Set key colour to green
    keying.key_color = (0.0, 1.0, 0.0)

    links.new(input_socket, keying.inputs['Image'])
    return keying.outputs['Image']
```

### Depth-of-field and depth-based effects

```python
def add_depth_of_field(
    nodes, links,
    image_socket,
    depth_socket,
    focus_distance: float = 5.0,
    f_stop: float = 2.8,
    location_x: float = 0,
) -> bpy.types.NodeSocket:
    dof = nodes.new('CompositorNodeDefocus')
    dof.name = 'DepthOfField'
    dof.use_zbuffer = True
    dof.f_stop = f_stop
    dof.bokeh = 'CIRCLE'
    dof.location = (location_x, 0)

    links.new(image_socket, dof.inputs['Image'])
    links.new(depth_socket,  dof.inputs['Z'])

    return dof.outputs['Image']

def add_fog_from_depth(
    nodes, links,
    image_socket,
    depth_socket,
    fog_colour: tuple = (0.8, 0.9, 1.0, 1.0),
    start: float = 5.0,
    end: float = 30.0,
    location_x: float = 0,
) -> bpy.types.NodeSocket:
    # Map Z range to 0–1
    map_range = nodes.new('CompositorNodeMapRange')
    map_range.inputs['From Min'].default_value = start
    map_range.inputs['From Max'].default_value = end
    map_range.inputs['To Min'].default_value = 0.0
    map_range.inputs['To Max'].default_value = 1.0
    map_range.location = (location_x, -200)
    links.new(depth_socket, map_range.inputs['Value'])

    # Fog colour
    fog_rgb = nodes.new('CompositorNodeRGB')
    fog_rgb.outputs[0].default_value = fog_colour
    fog_rgb.location = (location_x, -400)

    # Mix image with fog by depth mask
    mix = nodes.new('CompositorNodeMixRGB')
    mix.blend_type = 'MIX'
    mix.location = (location_x + 200, 0)
    links.new(image_socket,               mix.inputs[1])
    links.new(fog_rgb.outputs['RGBA'],    mix.inputs[2])
    links.new(map_range.outputs['Value'], mix.inputs['Fac'])

    return mix.outputs['Image']
```

### Multi-layer EXR output

```python
def setup_multilayer_exr_output(
    output_path: str,
    scene: bpy.types.Scene = None,
) -> None:
    if scene is None:
        scene = bpy.context.scene

    enable_render_passes(scene)
    nodes, links = setup_compositor()

    rl = nodes.new('CompositorNodeRLayers')
    rl.location = (-400, 0)

    output = nodes.new('CompositorNodeOutputFile')
    output.name = 'EXR Output'
    output.location = (400, 0)
    output.format.file_format = 'OPEN_EXR_MULTILAYER'
    output.format.color_depth = '32'
    output.base_path = output_path

    # Clear default slots and add named passes
    output.file_slots.clear()
    passes = [
        ('Image',   rl.outputs['Image']),
        ('Depth',   rl.outputs['Depth']),
        ('AO',      rl.outputs['AO']),
        ('Shadow',  rl.outputs['Shadow']),
        ('Normal',  rl.outputs['Normal']),
        ('Diffuse', rl.outputs['DiffCol']),
    ]

    for slot_name, source in passes:
        slot = output.file_slots.new(slot_name)
        links.new(source, output.inputs[slot_name])

    print(f'Multi-layer EXR output configured: {output_path}')
```

### Cinematic colour grading — full example

```python
def build_cinematic_compositor(output_path: str) -> None:
    enable_render_passes()
    nodes, links = setup_compositor()

    # Input
    rl = nodes.new('CompositorNodeRLayers')
    rl.location = (-600, 0)
    current = rl.outputs['Image']

    # Bloom
    current = add_glare(nodes, links, current, 'BLOOM', 'MEDIUM', 0.7, -200)

    # Colour grading
    current = add_colour_grading(
        nodes, links, current,
        brightness=0.02, contrast=15.0, saturation=1.05, gamma=1.02,
        location_x=200,
    )

    # Colour balance (lift/gamma/gain via Curves node)
    curves = nodes.new('CompositorNodeCurveRGB')
    curves.name = 'ColourCurves'
    curves.location = (700, 0)
    links.new(current, curves.inputs['Image'])
    current = curves.outputs['Image']

    # Output
    composite = nodes.new('CompositorNodeComposite')
    composite.location = (1000, 0)
    links.new(current, composite.inputs['Image'])

    # File output
    file_out = nodes.new('CompositorNodeOutputFile')
    file_out.base_path = output_path
    file_out.format.file_format = 'PNG'
    file_out.format.color_depth = '16'
    file_out.location = (1000, -150)
    links.new(current, file_out.inputs['Image'])
```

## Required habits

For all compositor scripts:
  - call `setup_compositor()` which clears nodes before building
  - link sockets by name, not by integer index
  - verify required render passes are enabled before linking their sockets
  - position nodes left-to-right in execution order

## Tool integration contract

If tools are available, prefer this order:
  - project .blend file (to inspect existing compositor tree and enabled passes)
  - reference frame captures (to understand the grading target)
  - colour LUT files for look development
  - HDRI paths for environment-based compositing

## Output contracts

### Compositor script
Include:
  - `setup_compositor()` call at the start
  - render pass enable block if passes beyond Combined are used
  - node building functions
  - all links explicitly named
  - a `build_<name>()` entry-point function

### Colour grading script
Include:
  - brightness, contrast, saturation, and gamma parameters
  - colour curves setup if needed
  - passthrough verification (graph still reaches Composite output)

## Response style

Use structured prose with clear headings.
All code examples use Python 3 syntax with type hints.
Use en-GB spelling.

## Quality rubric

Before finalising, silently check:
  - Are `scene.use_nodes` and `scene.render.use_compositing` set to True?
  - Is `nodes.clear()` called before building the graph?
  - Are required render passes enabled before their sockets are linked?
  - Are all socket links made by name, not index?
  - Does the graph terminate at a `CompositorNodeComposite` output?

## Regression prompts

Use these to test the skill after changes:
  - Write a compositor script that multiplies the Combined pass by the AO pass.
  - Build a colour grading graph with brightness, contrast, saturation, and gamma controls.
  - Set up a bloom glare effect with a threshold of 0.8.
  - Configure multi-layer EXR output with Combined, Depth, AO, Shadow, and Normal passes.
  - Build a depth-of-field compositor using the Z depth pass.

## Known limits

This skill covers Blender's compositor node system.
It does not cover:
  - Real-time game engine post-processing (handled by web-rendering/ or engine shaders)
  - Shader nodes or material nodes (use `/blender-scripting` for material setup)
  - Render engine configuration (use `/blender-render-automation`)
  - Geometry creation (use `/blender-3d-modeling`)

## Maintenance

Review when:
  - Blender releases a major version with compositor node API changes
  - New compositor node types become available (e.g., new glare types)
  - Project changes output format or colour pipeline
  - Compositor performance issues appear in batch pipelines
