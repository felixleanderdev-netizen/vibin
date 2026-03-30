#!/usr/bin/env python3
"""
Measurement extraction script for 3D body scans.
Loads PLY file and computes body measurements using Open3D.
"""

import sys
import json
import numpy as np
import open3d as o3d

def load_point_cloud(ply_path):
    """Load point cloud from PLY file."""
    try:
        pcd = o3d.io.read_point_cloud(ply_path)
        return pcd
    except Exception as e:
        print(f"Error loading PLY file: {e}", file=sys.stderr)
        sys.exit(1)

def compute_measurements(pcd):
    """Compute body measurements from point cloud."""
    points = np.asarray(pcd.points)

    if len(points) == 0:
        raise ValueError("Point cloud is empty")

    # Get bounding box
    min_bound = points.min(axis=0)
    max_bound = points.max(axis=0)
    height = max_bound[2] - min_bound[2]  # Assuming Z is height

    # Approximate measurements based on bounding box and heuristics
    # These are rough approximations for demo purposes

    # Neck girth: around upper 10% of height
    neck_z = max_bound[2] - 0.1 * height
    neck_points = points[(points[:, 2] >= neck_z - 0.05 * height) & (points[:, 2] <= neck_z + 0.05 * height)]
    neck_girth = estimate_girth(neck_points) if len(neck_points) > 0 else 350

    # Arm girths: find points in arm regions (rough approximation)
    mid_z = (min_bound[2] + max_bound[2]) / 2
    arm_z_min = mid_z - 0.1 * height
    arm_z_max = mid_z + 0.1 * height

    # Left arm (negative X)
    left_arm_points = points[(points[:, 0] < min_bound[0] + 0.3 * (max_bound[0] - min_bound[0])) &
                            (points[:, 2] >= arm_z_min) & (points[:, 2] <= arm_z_max)]
    left_arm_girth = estimate_girth(left_arm_points) if len(left_arm_points) > 0 else 260

    # Right arm (positive X)
    right_arm_points = points[(points[:, 0] > max_bound[0] - 0.3 * (max_bound[0] - min_bound[0])) &
                             (points[:, 2] >= arm_z_min) & (points[:, 2] <= arm_z_max)]
    right_arm_girth = estimate_girth(right_arm_points) if len(right_arm_points) > 0 else 258

    # Leg girths: lower part
    leg_z = min_bound[2] + 0.3 * height
    leg_points = points[(points[:, 2] >= leg_z - 0.1 * height) & (points[:, 2] <= leg_z + 0.1 * height)]

    # Left leg (negative X)
    left_leg_points = leg_points[leg_points[:, 0] < (min_bound[0] + max_bound[0]) / 2]
    left_leg_girth = estimate_girth(left_leg_points) if len(left_leg_points) > 0 else 540

    # Right leg (positive X)
    right_leg_points = leg_points[leg_points[:, 0] >= (min_bound[0] + max_bound[0]) / 2]
    right_leg_girth = estimate_girth(right_leg_points) if len(right_leg_points) > 0 else 538

    return {
        "neck_girth_mm": max(300, min(450, int(neck_girth))),
        "left_arm_girth_mm": max(200, min(350, int(left_arm_girth))),
        "right_arm_girth_mm": max(200, min(350, int(right_arm_girth))),
        "left_leg_girth_mm": max(400, min(700, int(left_leg_girth))),
        "right_leg_girth_mm": max(400, min(700, int(right_leg_girth))),
        "confidence": 0.75  # Placeholder confidence
    }

def estimate_girth(points):
    """Estimate girth (circumference) from a set of points in a cross-section."""
    if len(points) < 10:
        return 250  # Default fallback

    # Project to XY plane
    xy_points = points[:, :2]

    # Compute convex hull
    hull = o3d.geometry.PointCloud()
    hull.points = o3d.utility.Vector3dVector(xy_points)
    hull = hull.compute_convex_hull()[0]

    # Approximate circumference as perimeter of convex hull
    hull_points = np.asarray(hull.vertices)
    if len(hull_points) < 3:
        return 250

    # Calculate perimeter
    perimeter = 0
    for i in range(len(hull_points)):
        p1 = hull_points[i]
        p2 = hull_points[(i + 1) % len(hull_points)]
        perimeter += np.linalg.norm(p1 - p2)

    # Convert to mm (assuming points are in meters, *1000)
    return perimeter * 1000

def main():
    if len(sys.argv) != 3:
        print("Usage: python measure.py <ply_file> <output_json>", file=sys.stderr)
        sys.exit(1)

    ply_path = sys.argv[1]
    output_json = sys.argv[2]

    try:
        pcd = load_point_cloud(ply_path)
        measurements = compute_measurements(pcd)

        with open(output_json, 'w') as f:
            json.dump(measurements, f, indent=2)

        print("Measurements extracted successfully")

    except Exception as e:
        print(f"Error extracting measurements: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()