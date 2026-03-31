#!/usr/bin/env python3
"""
Mesh processing for 3D body scans.
Converts point cloud to smooth mesh and saves in multiple formats for 3D printing.
"""

import sys
import json
import numpy as np
import open3d as o3d

def load_point_cloud(ply_path):
    """Load point cloud from PLY file."""
    try:
        pcd = o3d.io.read_point_cloud(ply_path)
        print(f"Loaded point cloud with {len(pcd.points)} points")
        return pcd
    except Exception as e:
        print(f"Error loading PLY file: {e}", file=sys.stderr)
        sys.exit(1)

def process_mesh(pcd):
    """Process point cloud into smooth printable mesh."""
    try:
        # Remove outliers
        pcd_filtered, _ = pcd.remove_statistical_outlier(nb_neighbors=20, std_ratio=2.0)
        print(f"After outlier removal: {len(pcd_filtered.points)} points")

        # Downsample if too many points (>1M)
        if len(pcd_filtered.points) > 1000000:
            pcd_filtered = pcd_filtered.uniform_down_sample(every=2)
            print(f"After downsampling: {len(pcd_filtered.points)} points")

        # Estimate normals (required for mesh reconstruction)
        pcd_filtered.estimate_normals(
            search_param=o3d.geometry.KDTreeSearchParamHybrid(radius=0.1, max_nn=30)
        )
        print("Estimated normals")

        # Orient normals consistently
        pcd_filtered.orient_normals_consistent_tangent_plane(k=15)
        print("Oriented normals")

        # Poisson surface reconstruction
        print("Running Poisson surface reconstruction...")
        mesh, densities = o3d.geometry.TriangleMesh.create_from_point_cloud_poisson(
            pcd_filtered,
            depth=10,  # Depth of octree; higher = more detail but slower
            width=0,   # Use default
            linear_fit=False,
        )
        print(f"Created mesh with {len(mesh.triangles)} triangles")

        # Remove low density vertices (filter out floating components)
        vertices_to_remove = densities < np.quantile(densities, 0.1)
        mesh.remove_vertices_by_mask(vertices_to_remove)
        print(f"Cleaned mesh: {len(mesh.vertices)} vertices")

        # Compute vertex colors (from original point cloud if available)
        try:
            mesh.compute_vertex_colors()
        except:
            pass

        # Smooth mesh with Laplacian filtering
        mesh = mesh.filter_smooth_laplacian(number_of_iterations=3, lambda_filter=0.5)
        print("Applied Laplacian smoothing")

        # Simplify mesh (decimate)
        original_triangles = len(mesh.triangles)
        mesh = mesh.simplify_quadric_decimation(target_count=50000)
        print(f"Decimated mesh from {original_triangles} to {len(mesh.triangles)} triangles")

        # Remove small isolated components
        mesh_list = mesh.split(remove_degenerate_triangles=True)
        if len(mesh_list) > 1:
            mesh = max(mesh_list, key=lambda x: len(x.triangles))
            print(f"Kept largest mesh component with {len(mesh.triangles)} triangles")

        return mesh

    except Exception as e:
        print(f"Error during mesh processing: {e}", file=sys.stderr)
        sys.exit(1)

def save_mesh(mesh, output_dir):
    """Save mesh in multiple formats."""
    try:
        obj_path = f"{output_dir}/model.obj"
        stl_path = f"{output_dir}/model.stl"
        ply_path = f"{output_dir}/model_mesh.ply"

        o3d.io.write_triangle_mesh(obj_path, mesh)
        print(f"Saved OBJ: {obj_path}")

        o3d.io.write_triangle_mesh(stl_path, mesh)
        print(f"Saved STL: {stl_path}")

        o3d.io.write_triangle_mesh(ply_path, mesh)
        print(f"Saved PLY: {ply_path}")

        return {
            "obj_path": obj_path,
            "stl_path": stl_path,
            "ply_path": ply_path,
            "vertices": len(mesh.vertices),
            "triangles": len(mesh.triangles),
        }

    except Exception as e:
        print(f"Error saving mesh: {e}", file=sys.stderr)
        sys.exit(1)

def main():
    if len(sys.argv) != 3:
        print("Usage: python mesh_processing.py <input_ply> <output_dir>", file=sys.stderr)
        sys.exit(1)

    input_ply = sys.argv[1]
    output_dir = sys.argv[2]

    try:
        # Create output directory if needed
        import os
        os.makedirs(output_dir, exist_ok=True)

        # Load and process
        pcd = load_point_cloud(input_ply)
        mesh = process_mesh(pcd)
        result = save_mesh(mesh, output_dir)

        # Output JSON summary
        print(json.dumps(result))

    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()