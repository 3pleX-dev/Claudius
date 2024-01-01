
open Claudius

(* ----- *)

type point = {
  x : float ;
  y : float ;
  z : float ;
}

let rotate_x (a : float) (p : point) : point =
  { p with
    y = (p.y *. (cos (a))) -. (p.z *. sin(a)) ;
    z = (p.y *. sin(a)) +. (p.z *. cos(a)) ;
  }

let rotate_y (a : float) (p : point) : point =
  { p with
    x = (p.x *. cos(a)) -. (p.z *. sin(a)) ;
    z = (p.x *. sin(a)) +. (p.z *. cos(a)) ;
  }
    
let rotate_z (a : float) (p : point) : point =
  { p with
    x = (p.x *. cos(a)) -. (p.y *. sin(a)) ;
    y = (p.x *. sin(a)) +. (p.y *. cos(a)) ;
  }

let translate_x (d : float) (p : point) : point = 
  { p with x = p.x +. d }
  
let point_z_cmp (a : point) (b : point) : int =
  if a.z == b.z then 0
  else if a.z < b.z then 1 else -1

(* ----- *)

let _generate_torus (ft : float) : point list =
  let o = sin (ft /. 20.) in
  let offset = if o < 0. then ((0. -. o) *. 20.0) else 0. in
  let thickness_radius = 10. 
  and dots_per_slice = 25
  and torus_radius = 20.
  and slices_per_torus = 70 in 
  let nested = Array.init slices_per_torus (fun s -> 
    let slice_angle = (2. *. (Float.of_int s) *. Float.pi /. (Float.of_int slices_per_torus)) in
    Array.init dots_per_slice (fun i -> 
      let fi = Float.of_int i in
      let a = (2. *. fi *. Float.pi /. (Float.of_int dots_per_slice)) in
      {
        x = (thickness_radius +. offset) *. cos a ;
        y = (thickness_radius +. offset) *. sin a ;
        z = 0. ;
      } |> translate_x (torus_radius +. offset) |> rotate_y (slice_angle +. sin (ft *. 0.05))
    ) 
  ) in
  let lested = Array.to_list nested in
  Array.to_list (Array.concat lested)

let generate_sphere (_tf : float) : point list =
  let slices = 18
  and lats = 8
  and radius = 35.
  and offset = 0.
  and max_dots_per_lat = 60.
  and dots_per_slice = 31 in
  let nested_slices = Array.init slices (fun s -> 
    let slice_angle = (2. *. (Float.of_int s) *. Float.pi /. (Float.of_int slices)) in
    Array.init dots_per_slice (fun i -> 
      let fi = Float.of_int i in
      let a = (2. *. fi *. Float.pi /. (Float.of_int dots_per_slice)) in
      {
        x = (radius +. offset) *. cos a ;
        y = (radius +. offset) *. sin a ;
        z = 0. ;
      } 
      |> rotate_y (slice_angle)
    ) 
  ) in
  let nested_lats = Array.init lats (fun lat -> 
    let lh = radius *. cos (((Float.of_int lat) *. Float.pi) /. (Float.of_int lats)) in
    let dots_per_lat = Int.of_float(max_dots_per_lat *.sin (((Float.of_int lat) *. Float.pi) /. (Float.of_int lats))) in
    Array.init dots_per_lat (fun l -> 
      let fl = Float.of_int l in
      let r = radius *. sin (((Float.of_int lat) *. Float.pi) /. (Float.of_int lats)) in
      let a = (2. *. fl *. Float.pi /. (Float.of_int dots_per_lat)) in
      {
        x = (r +. offset) *. cos a ;
        y = lh ;
        z = (r +. offset) *. sin a ;
      }
    )
  ) in
  let lested = Array.to_list (Array.append nested_slices nested_lats) in
  Array.to_list (Array.concat lested)

let render_to_primatives (ft : float) (screen : Tcc.screen) (points : point list) : Primatives.t list =
  let m = 2000. +. cos(ft /. 30.) *. 600. in
  List.map (fun e ->
    Primatives.Pixel ({
      x = ((screen.width / 2) + int_of_float(m *. e.x /. (e.z +. 400.))) ; 
      y = ((screen.height / 2) + int_of_float(m *. e.y /. (e.z +. 400.))) ;
    }, ((Palette.size screen.palette) - 1))
  ) points

(* ----- *)

let tick (t : int) (screen : Tcc.screen) (prev : Framebuffer.t) : Framebuffer.t =
  let buffer = Array.map (fun row -> 
    Array.map (fun pixel ->
      if pixel > 2 then (pixel - 2) else 0
    ) row
  ) prev in

  let ft = Float.of_int t in

  generate_sphere ft 
  |> List.map (fun p ->
    rotate_y (0.02 *. ft) p |> rotate_x (0.01 *. ft) |> rotate_z (0.005 *. ft)
  ) 
  |> List.sort point_z_cmp 
  |> render_to_primatives ft screen 
  |> Framebuffer.render buffer;

  buffer

(* ----- *)

let () =
  let screen : Tcc.screen = {
    width = 640 ;
    height = 480 ;
    scale = 1 ;
    palette = Palette.generate_mono_palette 16 ;
  } in
  Tcc.tcc_init screen "Genuary Day 1: Particals" None tick
