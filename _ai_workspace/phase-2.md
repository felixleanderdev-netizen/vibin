# Phase 2: 3D Reconstruction + Measurement + Template Fitting

**Goal**: Convert captured scan image sets into accurate patient-specific 3D meshes and body measurements, ready for garment/armor template fitting.

**Status**: Planned (Phase 1 complete)

---

## Phase 2 Scope

1. 3D Reconstruction pipeline (Colmap + point cloud -> mesh)
2. Body measurement extraction (neck, upper/lower arm, thigh, calf gaith)
3. Quality assessment + confidence
4. API endpoints for reconstruction and measurement results
5. Integration with Phase 1 file upload sessions

---

## Phase 2 Success Criteria

- [ ] Raw image set -> valid untextured mesh (`.ply` / `.obj`) for >= 90% of sessions
- [ ] At least 80% accuracy of target girth measurements in pilot set
- [ ] Per-session status endpoint returns `ready|processing|failed`
- [ ] Existing mobile flow extends to retrieve and display measurement data

---

## Detailed Tasks

### Task 2.1: Reconstruction service architecture
- [ ] Design `ReconstructionService` behavior
  - Input: `sessionId` + image directory path
  - Output: mesh file path + metadata
  - Status states: `pending`, `processing`, `succeeded`, `failed`
- [ ] Define configuration (Colmap path, workspace folder)
- [ ] Add new DB-like JSON session file: `recon/{sessionId}/status.json`

### Task 2.2: Backend API endpoints (phase 2)
- [ ] `POST /api/scans/{sessionId}/reconstruct` (start reconstruction)
- [ ] `GET /api/scans/{sessionId}/reconstruct/status` (status + progress)
- [ ] `GET /api/scans/{sessionId}/reconstruct/model` (download mesh)
- [ ] `GET /api/scans/{sessionId}/measurements` (measurement results)

### Task 2.3: Implement Colmap command runner
- [ ] check Colmap installed and accessible
- [ ] run `colmap feature_extractor` on image folder
- [ ] run `colmap exhaustive_matcher`
- [ ] run `colmap mapper` then `model_converter` to `.ply`
- [ ] include error capture logs to `recon/{sessionId}/schedule.log`
- [ ] allow timeout/fail fast based on max runtime per step

### Task 2.4: Mesh generation + clean-up
- [ ] verify `point_cloud.ply` output exists and has points
- [ ] if no points -> set status `failed` with message
- [ ] create simplified mesh if needed using `Python/Open3D` to reduce complexity

### Task 2.5: Body measurement calculations
- [ ] find body axis and key landmarks (neck, chest, waist, hip, arm, thigh)
- [ ] define cross-section plane heuristics (percentage of body height)
- [ ] compute circumference from cross-section contour using Open3D/trimesh
- [ ] produce confidence score (point density & closure)
- [ ] results schema

### Task 2.6: Measurement endpoint + historical data
- [ ] store measurement result JSON in `recon/{sessionId}/measurements.json`
- [ ] `GET /api/scans/{sessionId}/measurements` returns structured result
- [ ] `GET /api/scans/{sessionId}/measurements/history` optional versioning

### Task 2.7: Mobile integration (Phase 1 -> 2 transition)
- [ ] Add new UI flow after successful upload:
  - "Start 3D reconstruction" button
  - Polls `/reconstruct/status`
  - Shows final measurement summary
- [ ] Add estimated reconstruction + measurement KPI to phase 1 screen

### Task 2.8: Test harness
- [ ] sample images (folder + known expected measurements)
- [ ] script to run endpoint flow and verify response
- [ ] performance test for 50-image input
- [ ] baseline measure accuracy with ground truth

### Task 2.9: Phase 2 docs (done by this file)
- [ ] Update docs: `docs/DATA_FLOW.md` with reconstruction add-ons
- [ ] `docs/MEASUREMENTS.md` with measurement formulas
- [ ] `docs/SETUP.md` with Colmap install & Python dependencies

---

## Resources

- Colmap docs: https://colmap.github.io
- Open3D docs: http://www.open3d.org/docs
- Trimesh docs: https://trimsh.org
- Python 3.12+ recommended

---

## Notes

- Keep Phase 1 API stable; add extension endpoints with versioning `/api/v2/...` if needed.
- Start with local filesystem storage; migrate to S3 / object store in Phase 2.2.
- Use edge-case handling for mobile images where user takes too few frames.
