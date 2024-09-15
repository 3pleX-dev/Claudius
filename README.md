# Claudius - A fantasy retro computer library.

Claudius started out trying to be a functional library that works like a fantasy console system like [TIC-80](https://tic80.com)or [PICO-8](https://www.lexaloffle.com/pico-8.php): A way to do some retro-style demo graphics progeramming but in OCaml rather than in LUA. In its current form it doesn't do nearly as much as those fantasy consoles, instead just concentrating on enabling you to make graphical demos, and lacks things like audio, expressive input support, sprite editors and so forth. But if your goal is to enter something like [Tiny Code Christmas](https://tcc.lovebyte.party) or [Genuary](https://genuary.art), then Claudius is designed for that use case.

# Key concepts

As mentioned alread, Claudius takes inspiration from existing fantasy console environments, whilst trying to encourage a more functional approach to working within such constrains. This section covers the basic concepts that Claudius relies on.

One of the main differences is that rather than work with a memory map layout of the virtual computer (e.g., see TIC-80's [docs](https://tic80.com/learn) where it describes the memory layout it uses), Claudius works with a `Framebuffer.t` type, which is an ADT that manages the pixels in a palette based colour space. You can generate new framebuffers when you like, or recycle old ones. By not treating them as memory mapped as in TIC-80, we can encourage a more functional access approach (as described below).

## Tick and Boot

Similar to both TIC-80, and embedded development systems like [Arduino](https://arduino.cc), Claudius programs have two main entry points, functions that you must provide to Claudius: an optional one called `boot` and a mandator one called `tick`.

### Boot

This function is called once, and at its minimum is used to set an initial screen state, though it can also be used by your code to initialise any other state that your program maintains. If you're happy with just a blank screen (using palette entry 0, see screen details below for more on this), then you don't need to provide a `boot` function.

### Tick

the `tick` function is mandator, and will be called once per frame redraw by Claudius. This will be where you either generate a new set of screen contents of you can modify the old screen contents and provide that back to Claudius. The tick function will be provided with a monotomically incrementing counter `t` that can be used to derive a particular frame update.

## Styles of working with Claudius

To support this there's three primary modes of working with Claudius for generating visual effects and demos:

- Pixel functional
- Screen functional
- Imperative

### Pixel Functional

Often visual effects can be encoded as "pixel functional" - that is to draw the screen you just need to provide a function that takes the `x` and `y` coordinate of the pixel and then generates it's value. A classic example of this would be a [Mandelbrot Fractal](https://en.wikipedia.org/wiki/Mandelbrot_set). To encourage this, the most common way to generate a blank canvas in Claudius is:

```ocaml
open Claudius

let fb = Framebuffer.init (640, 480) (fun _x _y -> 0)
```

You can also modify an existing framebuffer by providing a shader style function. For example, this shader is used to fade out the previous frame:

```ocaml
let faded_fb = Framebuffer.shader (fun pixel -> if pixel > 1 then (pixel - 1) else 0) fb
```

Done too much this can be expensive in memory allocations, and so there is also a `shader_inplace` variation that does an update on the provided framebuffer - this is less functional, but is sometimes a pragmatic compromise based on performance.

### Screen Functional

Whilst pixel functional effects can be fun, they can also be quite limiting, and often you will want to build up bigger scenes to be rendered at once. For this we encourage a functional pipeline style of processing, which we refer to as "Screen Functional" - each frame is a function of time t. To support this Claudius has a primatives library, whereby you can render objects to a framebuffer:

```ocaml
let w, h = Screen.dimensions s in
let palsize = Palette.size (Screen.palette s) in

(* generate some points *)
List.init 42 (fun _ -> (Random.int w, Random.int h))
(* Convert those circle primatives in different colours *)
|> List.mapi (fun idx (x, y) -> Primitive.Circle ({x ; y } ; 3.0 ; idx mod palsize))
(* Draw to framebuffer *)
|> Framebuffer.render fb
```

More complicated examples for say a 3D-style pipeline you often end up writing pipelines that look like:

```ocaml
(* generate some points for the model *)
generate_model_points ()
(* Advance the model by time t *)
|> update_points t
(* Convert points to 2D *)
|> project_points
(* Convert to primatives *)
|> convert_to_primatives
(* Finally render to framebuffer *)
|> Framebuffer.render fb
```

You can see an example of this in practice in [example/day1](/example/day1/bin/main.ml).

### Imperative

Finally, if you just want to get some shapes on screen, then all primatives can be directly rendered to a framebuffer like so:

```ocaml
Framebuffer.draw_line x0 y0 x1 y1 col buffer
```

## The framebuffer

# Screen modes

Claudius isn't as restrictive as a dedicated fantasy console, which typically offers one or a few dedicated modes (e.g., 240x180x16 for TIC-80), but rather you specify a screen as having a resolution and palette of your choosing. Currently palettes are only configurate at start-of-day, and not yet modifiable whilst an effect is running, but the ability to have palettes of arbitary sizes does offset this limitation somewhat, but is probably something that will be addressed in a future release.

## Palettes

Palettes are defined as sets of 24bit red, green, blue values. You can thus create a 5 entry palette of black, red, green, blue, white by doing the following:

```ocaml
open Claudius

let p = Palette.of_list [0x000000 ; 0xFF0000; 0x00FF00; 0x0000FF ; 0xFFFFFF]
```

To assist with some common fancy palettes, there are some helper functions that will save you some code. For instance, you can create a 256 entry monochromatic palette like so:

```ocaml
open Claudius

let p = Palette.generate_mono_palette 256
```

Or a plasma colour palette like this:

```ocaml
open Claudius

let p = Palette.generate_plasma_palette 16
```

You can also turn a palette back into a list of integers, to say create a palette that has black and white and 14 plasma colours:

```ocaml
open Claudius

let = p Palette.generate_plasma_palette 14
|> Palette.to_list
|> List.concat [0x000000;0xFFFFFF]
|> Palette.of_list
```

## Screens

Once you have a colour palette defined, you can now create the screen mode you want:

```ocaml
open Claudius

let s = Screen.create 640 480 1 (Palette.generate_mono_palette 16)
```

The first two arguments are the width and height of the emulated screen mode, and final argument is the palette. The third argument is a scaling factor when displayed; if you're trying to work at resolutions like 320x200 (old-school VGA 256 colour), then things can get quite small on modern displays, so you might want to bump that up a bit, for example making it display at three times the size:

```ocaml
open Claudius

let s = Screen.create 320 200 3 (Palette.generate_plasma_palette 256)
```
