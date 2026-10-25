# A09 - Command History

## 1. Git and GitHub
```bash
git --version
git config --global --list
git status --short
git add ACTIVITY_LOG.md
git commit -m "Add A09 activity log"
git push origin main
git log -10 --oneline
gh auth status
gh run list --limit 10
```

## 2. Project files and reports
```bash
cat 02_SPECIFICATION/interface.md
cat 05_VERIFICATION/verification_report.md
cat 07_TRACEABILITY/RTM.csv
git diff --cached
```

## 3. RTL verification
- RTL module: `a09_abs_sign`
- RTL file: `04_IMPLEMENTATION/rtl/a09_abs_sign.sv`
- Python reference model used.
- RTL simulation: 266 vectors, 0 mismatches.
- Invariant checks: 1597 checks, 0 violations.
- Corner case: `8'h80` represents -128 and asserts overflow.

## 4. Yosys synthesis
- Tool: Yosys.
- Recorded standalone synthesis statistics: 18 cells, 0 flip-flops.
- Recorded standalone synthesis area: 118864 um^2.
- Reports and netlists are stored in the project.

## 5. OpenSTA timing analysis
- Tool: OpenSTA.
- Recorded critical path: `x[0]` to `abs_val[6]`.
- Recorded delay: 0.99 ns.
- Interpret timing results with the documented constraints and limitations.

## 6. OpenLane RTL-to-GDSII
- Flow: OpenLane with Sky130A PDK.
- Run directory: `04_IMPLEMENTATION/openlane1/runs/a09_run1/`
- Final GDS: `04_IMPLEMENTATION/openlane1/runs/a09_run1/results/signoff/a09_abs_sign.gds`

## 7. Physical verification
- DRC report: COUNT = 0.
- LVS report: Total errors = 0.
- Global-route timing is not a substitute for final post-route timing signoff.

## 8. KLayout
- Opened the final GDSII layout in KLayout.
- Screenshot: `06_GDSII/a09_klayout.png`.

## 9. GitHub Actions
- Workflow: `.github/workflows/a09-activity.yml`
- Workflow name: A09 Activity History.
- Triggers: push to main or manual dispatch.
- Displays the activity log and recent Git commits.

## 10. History note
This file summarizes representative commands and verified project milestones. It is not a complete verbatim terminal transcript of every command executed during the five-day project.
