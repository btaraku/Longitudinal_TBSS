#!/bin/bash

# Setup path to FSL
FSLDIR=/nafs/apps/fsl/64/6.0.1
. ${FSLDIR}/etc/fslconf/fsl.sh
PATH=${FSLDIR}/bin:${PATH}

# Input variables:
# 
# data_dir: directory where FA data is located
# tbss_dir: directory where tbss is to be run
# FA_filename: name of file containing FA data for each subject. Must be .nii or .nii.gz
# subj_list_coreg: list of Subject IDs with multiple timepoints to be co-resgistered, saved in a text file
# subj_list_nocoreg: list of Subject IDs not to be co-registered with only 1 timepoint, saved in a text file
# timepoint_list: list of subject timepoints saved in a text file, assumed to be appended to subject ID
# template_filename: name of file conataining a single subject template used for each subject with co-registered data (average of all co-registered subject timepoints)
# kernel: smoothing kernel applied to single subject template. Saves an additonal file if provided

data_dir=$1
tbss_dir=$2
FA_filename=$3
subj_list_coreg=$4
subj_list_nocoreg=$5
timepoint_list=$6
template_filename=$7
kernel=$8

for subj in $(cat $subj_list_coreg)
do
	# Run co-registration for all timepoints on each subject
	echo "Co-registering timepoints for ${subj}"
	bash coreg_midtrans_multi_FA.sh $data_dir $subj $timepoint_list $FA_filename
	
	# Create single-subject template
	echo "Creating single subject template for all timepoints for ${subj}"
	bash midpoint_subject_template.sh $data_dir $subj $timepoint_list $FA_filename $template_filename $kernel
done

echo "Running TBSS"
bash tbss_coreg_mid.sh $data_dir $tbss_dir $FA_filename $subj_list_coreg $subj_list_nocoreg $timepoint_list $template_filename $kernel
