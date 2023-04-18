# Longitudinal_TBSS

Requires FSL v4+

Modified Tract-Based Spatial Statistics (TBSS) protocol for the analysis of longitudinal Diffusion-weighted MRI data on subjects scanned
at multiple timepoints.
Expects FA images for each subject scan timepoint, and a list of subjects and the corresponding timepoints.
Utilizes existing TBSS protocols in FSL, and employs other tools in FSL prior to running TBSS. Co-registration using rigid body 
transformations is performed on all time-points for each subject, followed by the creation of a single subject template by averaging 
all co-registered images across all timepoints, with an option to perform spatial smoothing. During TBSS processing, only single-subject templates 
are used to estimate non-linear transformations for each subject, but are applied to all timepoints, to ensure consistent warps for each 
timepoint.

Use main.sh to run the entire longitudinal TBSS procedure, which includes co-registraion, single subject template creation, and running
of the modified TBSS protocol.

Tested on dMRI data from the Human Connectome Project (HCP) https://www.humanconnectome.org/. 
Data was preprocessed using the HCP Minimal Preprocessing Pipeline https://github.com/Washington-University/HCPpipelines and
Diffusion Tensors were fit to preprocessed data using FSL's DTIFIT https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/FDT/UserGuide, which outputs 
Fractional Anisotropy (FA) maps.

Inspired by the Longitudinal TBSS protocol described in Engvig et al https://onlinelibrary.wiley.com/doi/epdf/10.1002/hbm.21370
