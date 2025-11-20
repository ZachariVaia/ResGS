# Branch Descriptions

## Branch: BlurGS
**Purpose:** Investigate the effect of applying spatial blur to the Gaussian splats in ResGS.  
We will test varying blur kernel sizes or standard deviations, measure reconstruction error,  
and compare to the baseline ResGS implementation.

## Branch: multi_res_scale
**Purpose:** Introduce multi-resolution scaling into ResGS.  
This includes building two (or more) levels of Gaussian grids:  
- a coarse scale for global structure  
- a fine scale for high-detail recovery  
Evaluation will be performed on the standard ResGS datasets.

## Branch: main
**Purpose:** Baseline implementation of ResGS as forked from the original repository.  
All validated experimental branches (BlurGS, multi_res_scale, etc.) will eventually  
merge back into `main`.
