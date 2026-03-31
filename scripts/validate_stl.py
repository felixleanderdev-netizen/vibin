#!/usr/bin/env python3
"""
STL validation and export optimization for 3D printing.
Validates mesh integrity and exports print-ready files.
"""

import sys
import struct
import numpy as np

def validate_stl_file(stl_path):
    """Validate STL file integrity and structure."""
    try:
        with open(stl_path, 'rb') as f:
            # Read header
            header = f.read(80)
            if len(header) < 80:
                return False, "Invalid header: file too small"

            # Read number of triangles
            num_triangles_bytes = f.read(4)
            if len(num_triangles_bytes) < 4:
                return False, "Invalid triangle count"

            num_triangles = struct.unpack('I', num_triangles_bytes)[0]

            # Validate file size
            expected_size = 80 + 4 + (num_triangles * 50)  # 50 bytes per triangle
            actual_size = len(header) + len(num_triangles_bytes) + len(f.read())
            
            if actual_size < expected_size:
                return False, f"File too small: expected {expected_size}, got {actual_size}"

            # Reset and validate triangles
            f.seek(84)  # Skip header and triangle count
            valid_triangles = 0
            
            for i in range(min(num_triangles, 1000)):  # Sample first 1000 triangles
                tri_data = f.read(50)
                if len(tri_data) < 50:
                    break
                
                # Unpack: normal (3 floats) + 3 vertices (9 floats) + attribute (1 short)
                try:
                    normal = struct.unpack('fff', tri_data[0:12])
                    v1 = struct.unpack('fff', tri_data[12:24])
                    v2 = struct.unpack('fff', tri_data[24:36])
                    v3 = struct.unpack('fff', tri_data[36:48])
                    
                    # Check for NaN or Inf
                    for val in normal + v1 + v2 + v3:
                        if not (-1e10 < val < 1e10):
                            return False, f"Invalid vertex coordinate detected"
                    
                    valid_triangles += 1
                except:
                    return False, f"Invalid triangle data at index {i}"

        if valid_triangles > 0:
            return True, f"STL valid: {num_triangles} triangles, {valid_triangles} sampled OK"
        else:
            return False, "No valid triangles found"

    except Exception as e:
        return False, f"Validation error: {str(e)}"

def estimate_print_stats(stl_path):
    """Estimate printing statistics from STL file."""
    try:
        with open(stl_path, 'rb') as f:
            f.seek(84)  # Skip header and triangle count
            
            vertices = []
            for _ in range(1000):  # Sample first 1000 triangles
                tri_data = f.read(50)
                if len(tri_data) < 50:
                    break
                
                v1 = struct.unpack('fff', tri_data[12:24])
                v2 = struct.unpack('fff', tri_data[24:36])
                v3 = struct.unpack('fff', tri_data[36:48])
                
                vertices.extend([v1, v2, v3])
            
            if not vertices:
                return None
            
            vertices = np.array(vertices)
            
            # Calculate bounding box
            mins = vertices.min(axis=0)
            maxs = vertices.max(axis=0)
            dimensions = maxs - mins
            
            # Estimate volume (rough approximation)
            volume_mm3 = np.prod(dimensions) * 0.3  # Rough estimate
            weight_grams = volume_mm3 / 1000  # Approximate density of plastic
            
            return {
                "dimensions_mm": [float(d) for d in dimensions],
                "estimated_weight_grams": float(weight_grams),
                "estimated_print_time_hours": float(weight_grams / 10),  # ~10g per hour
            }
    except:
        return None

def main():
    if len(sys.argv) != 2:
        print("Usage: python validate_stl.py <stl_file>", file=sys.stderr)
        sys.exit(1)

    stl_path = sys.argv[1]

    try:
        is_valid, message = validate_stl_file(stl_path)
        
        result = {
            "valid": is_valid,
            "message": message,
        }
        
        if is_valid:
            stats = estimate_print_stats(stl_path)
            if stats:
                result["print_stats"] = stats
        
        print(json.dumps(result))
        sys.exit(0 if is_valid else 1)

    except Exception as e:
        print(json.dumps({
            "valid": False,
            "message": f"Error: {str(e)}"
        }))
        sys.exit(1)

if __name__ == "__main__":
    import json
    main()