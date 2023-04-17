# Longitudinal_TBSS

Requires FSL v5+

Tested on dMRI data from the Human Connectome Project (HCP), preprocessed using the HCP Minimal Preprocessing Pipeline 
https://github.com/Washington-University/HCPpipelines

Modified Tract-Based Spatial Statistics (TBSS) protocol for the analysis of longitudinal Diffusion-weighted MRI data. 
Utilizes existing TBSS protocols in FSL, and employs other tools in FSL prior to running TBSS. Co-registration using rigid body 
transformations is performed on all time-points for each subject, followed by the creation of a single subject template by averaging 
all co-registered images across all timepoints, with an option to perform spatial smoothing. During TBSS processing, only single-subject templates 
are used to estimate non-linear transformations for each subject, but are applied to all timepoints, to ensure consistent warps for each 
timepoint.

Use main.sh to run the entire longitudinal TBSS procedure
