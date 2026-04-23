{ ... }: {
  services.flatpak.packages = [
    "org.blender.Blender"
    "org.freecad.FreeCAD"
    "org.kicad.KiCad"
    "org.librecad.librecad"
    "org.openscad.OpenSCAD"
    "com.connorcode.mslicer"
    "com.prusa3d.PrusaSlicer"
  ];
}
