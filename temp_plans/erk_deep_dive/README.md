# ERK Deep Dive — Complete Investigation Record

## Overview

This directory consolidates all investigation artifacts for the ERK (Enzyme Reaction Kinetics) model failure analysis. ERK is a dual Michaelis-Menten system that represents the hardest test case for ODEPE due to its extreme stiffness and the cascading failures this causes.

**Bottom line**: The ERK estimation pipeline fails because AAAD boundary poles cause 93-13,500× errors in first derivatives at t=0, which propagate through the SIAN algebraic system to produce wildly wrong parameter estimates and initial conditions.

---

## File Index

### Analysis Documents

| File | Description |
|------|------------|
| `full_pipeline_analysis.md` | **START HERE** — Complete trace of a single ERK run with all failure points identified |
| `boundary_derivative_deep_analysis.md` | Root cause analysis: AAAD poles, Froissart doublets, comparison of interpolators |
| `backsolve_fallback_analysis.md` | Analysis of the SIAN re-solve mechanism and cascading substitution |
| `ERK_FAILURE_ANALYSIS.md` | Earlier analysis: backward ODE instability, conservation laws, C1↔C2 symmetry |
| `pole_deflation_results.md` | Pole deflation prototype results and findings |

### Diagnostic Scripts

| File | Description |
|------|------------|
| `aaad_deep_diagnostic.jl` | 7-part AAAD diagnostic: support points, breakflag, poles, boundary sweeps |
| `pole_deflation_test.jl` | Pole deflation prototype: 3 strategies + Fornberg FD + FHD5 benchmark |
| `diagnose_erk.jl` | Earlier diagnostic: conservation laws, eigenvalues, HC.jl solution quality |
| `test_backward_solvers.jl` | Backward ODE solver comparison |
| `run_erk_with_polish.jl` | ERK with BFGS polishing |

### Logs and Output

| File | Description |
|------|------------|
| `ERKlog1_2K_try_more_false.txt` | Full log of ERK run with 2K points, `try_more_methods=false` |
| `aaad_diagnostic_output.txt` | Output from the 7-part AAAD diagnostic |
| `diagnostic_output.log` | Output from `diagnose_erk.jl` |
| `backward_solver_test.log` | Output from backward solver tests |
| `polish_output.log` | Output from polished ERK run |

### Model Definition

| File | Description |
|------|------------|
| `ERK_model.jl` | ERK model definition with true parameters and estimation script |
