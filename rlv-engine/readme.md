# RLV Furniture Engine v1

A furniture engine for Second Life that utilizes RLV (Restrained Love Viewer) capabilities to control animations and positioning.

## Overview

`rlv-engine-v1.lsl` is the core LSL script that manages furniture behavior, including pose animations, positioning, and RLV-based restrictions.

## ⚠️ Known Issues

**Missing Poses**: The following pose animations are referenced and called within the script but are **not included** in this release:
- `pose1`
- `pose2`
- `pose3`

**Expected Problems**: Without these pose animations, the furniture will not function correctly when attempting to trigger these poses. You will likely experience:
- Animation fails or no animation playing
- Script errors or warnings
- Unpredictable furniture behavior

## Resolution

To resolve these issues, you will need to:
1. Add the missing pose animations to your furniture model
2. Ensure the animation names match exactly (`pose1`, `pose2`, `pose3`)
3. Test the furniture after adding the animations

## Requirements

- Second Life simulator with RLV support
- Compatible viewer with RLV capabilities enabled
- Animation assets included in the furniture build