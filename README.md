# Longitudinal_TBSS

Requires FSL v5+

Modified Tract-Based Spatial Statistics (TBSS) protocol for the analysis of longitudinal Diffusion-weighted MRI data. 
Utilizes existing TBSS protocols in FSL, and employs other tools in FSL prior to running TBSS. Co-registration using rigid body 
transformations is performed on all time-points for each subject. A single subject template is created by averaging all co-registered
images across all timepoints, with an option to smooth. During TBSS processing, only single-subject templates are used to estimate non-linear
transformations for each subject, but are applied to all timepoints, to ensure consistent warps for each timepoint.
