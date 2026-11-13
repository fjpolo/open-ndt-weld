// =============================================================================
// OpenNDT Weld Inspector - Tier 1 Dual-Sensor MFL Gradiometer Probe Housing
// =============================================================================
// Material: Print in NON-MAGNETIC PLA, PETG, or ABS (0.2 mm layer height, 25%+ infill)
// Geometry:
//   - Mild Steel Yoke:   55 x 12 x 3 mm (top pocket at Z = mag_thick)
//   - 2x NdFeB Magnets:  20 x 10 x 5 mm each (15 mm center gap => 20 + 15 + 20 = 55 mm)
//   - 2x S49E Sensors:   Flat TO-92 face parallel to weld (Z = 2.7..4.3 mm, fits under 5 mm yoke)
//                        5.0 mm center-to-center axial spacing (4-6 mm spec)
//   - Open magnet bottoms so poles contact workpiece through thin Kapton/PTFE tape
// =============================================================================

/* [Print & Component Tolerances] */
tol = 0.30;               // XY fit clearance for 3D printing (mm)

/* [Yoke Dimensions (Mild Steel)] */
yoke_len   = 55.0;        // X axis
yoke_wid   = 12.0;        // Y axis
yoke_thick = 3.0;         // Z axis

/* [Magnet Dimensions (NdFeB N35)] */
mag_len    = 20.0;        // X axis
mag_wid    = 10.0;        // Y axis
mag_thick  = 5.0;         // Z axis (set to 10.0 if stacking 2x magnets per pole)
air_gap    = 15.0;        // Distance between inner faces of Magnet 1 & Magnet 2

/* [Dual S49E Hall Sensor Gradiometer] */
sensor_spacing = 5.0;     // Center-to-center axial spacing (4-6 mm spec)
sensor_liftoff = 2.7;     // Recess above bottom plane of magnets (2.5-3.0 mm spec)
to92_w         = 4.2;     // TO-92 body width (along Y)
to92_h         = 3.2;     // TO-92 body length (along X)
to92_t         = 1.6;     // TO-92 body thickness (along Z, flat face down)

/* [Housing Shell] */
wall       = 2.5;         // Outer wall thickness
yoke_lip   = 1.5;         // Top retention rim height around steel yoke

total_len  = yoke_len + 2 * wall;
total_wid  = yoke_wid + 2 * wall;
total_h    = mag_thick + yoke_thick + yoke_lip;

module s49e_flat_slot() {
    // Flat TO-92 pocket (sensing face parallel to weld surface, leads exiting +Y)
    translate([-(to92_h + tol)/2, -(to92_w + tol)/2, 0])
        cube([to92_h + tol, to92_w + tol, to92_t + 0.3]);

    // 3-pin lead channel exiting out the +Y side wall below the steel yoke
    translate([-2.0, (to92_w + tol)/2 - 0.5, 0])
        cube([4.0, total_wid/2 + 2.0, to92_t + 0.5]);
}

module probe_housing() {
    difference() {
        // 1. Main outer housing block
        translate([-total_len/2, -total_wid/2, 0])
            cube([total_len, total_wid, total_h]);

        // 2. Top pocket for Mild Steel Backing Yoke (55 x 12 x 3 mm)
        translate([-(yoke_len + tol)/2, -(yoke_wid + tol)/2, mag_thick])
            cube([yoke_len + tol, yoke_wid + tol, yoke_thick + yoke_lip + 1.0]);

        // 3. Left Magnet Pocket (open at bottom & open to yoke at top)
        translate([-(air_gap/2 + mag_len + tol/2), -(mag_wid + tol)/2, -0.5])
            cube([mag_len + tol, mag_wid + tol, mag_thick + 1.0]);

        // 4. Right Magnet Pocket (open at bottom & open to yoke at top)
        translate([air_gap/2 - tol/2, -(mag_wid + tol)/2, -0.5])
            cube([mag_len + tol, mag_wid + tol, mag_thick + 1.0]);

        // 5. Central Sensor 1 Slot (GP26) - recessed by sensor_liftoff (2.7 mm)
        translate([-sensor_spacing/2, 0, sensor_liftoff])
            s49e_flat_slot();

        // 6. Central Sensor 2 Slot (GP27) - recessed by sensor_liftoff (2.7 mm)
        translate([sensor_spacing/2, 0, sensor_liftoff])
            s49e_flat_slot();

        // 7. Bottom sensing window under the two sensors (open down to Z=0)
        translate([-(sensor_spacing + to92_h)/2 - 0.5, -(to92_w + tol)/2, -0.5])
            cube([sensor_spacing + to92_h + 1.0, to92_w + tol, sensor_liftoff + 0.6]);
    }
}

probe_housing();
