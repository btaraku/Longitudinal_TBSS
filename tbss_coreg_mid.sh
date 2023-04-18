#!/bin/bash

# Runs TBSS protocols using the FMRIB58_FA standard-space image as a reference to estimate nonlinear warps
# Modified to incorporate co-registered longitudinal data, by only estimating 1 nonlinear registration per subject
# Nonlinear registration is estimated using a single subject template, which is an averaged image of all co-registered images
#
# Expects as input:
# data_dir: directory where FA data is located
# tbss_dir: directory where tbss is to be run
# FA_filename: name of file containing FA data for each subject. Must be .nii or .nii.gz
# subj_list_coreg: list of Subject IDs with multiple timepoints to be co-resgistered, saved in a text file
# subj_list_nocoreg: list of Subject IDs not to be co-registered with only 1 timepoint, saved in a text file
# timepoint_list: list of subject timepoints saved in a text file, assumed to be appended to subject ID
# template_filename: name of file conataining a single subject template used for each subject with co-registered data (average of all co-registered subject timepoints)
# kernel: smoothing kernel applied to single subject template. Saves an additonal file if provided
#
# Outputs: 
# TBSS directory, which includes final FA skeletons in standard space

data_dir=$1
tbss_dir=$2
FA_filename=$3
subj_list_coreg=$4
subj_list_nocoreg=$5
timepoint_list=$6
template_filename=$7
kernel=$8

if [[ ! -d $tbss_dir ]]
then
	mkdir $tbss_dir
fi

if [[ "$kernel" != "" ]];
then
	temp_pfx="s${kernel}_"
else
	temp_pfx=""
fi

# Copy co-registered data to TBSS directory
for subj_coreg in $(cat $subj_list_coreg)
do
	for tp in $(cat $timepoint_list)
	do
		echo "copying co-registered data for ${subj_coreg}${tp}"
		cp ${data_dir}/${subj_coreg}${tp}/${FA_filename}_coreg_mid.nii.gz ${tbss_dir}/${subj_coreg}${tp}_data.nii.gz
	done
done

# Copy non-co-registered data to TBSS directory if present
for subj_nocoreg in $(cat $subj_list_nocoreg)
do
	echo "copying non co-registered data for ${subj_coreg}"
	cp ${data_dir}/${subj_nocoreg}/${FA_filename}.nii.gz ${tbss_dir}/${subj_nocoreg}_data.nii.gz
done

# Copy single subject template data to TBSS directory
for subj_temp in $(cat $subj_list_coreg)
do
	echo "copying timepoint averaged template for ${subj_temp}"
	cp ${data_dir}/${temp_pfx}${subj_temp}${template_filename}.nii.gz ${tbss_dir}/${subj_temp}m_data.nii.gz
done

#Slightly modified tbss pipeline
pushd ${tbss_dir}/

tbss_1_preproc *.nii.gz
# Estimate warps for only midpoint data that has multi timepoints
echo "Making temporary FA directory"
mkdir FA_temp
echo "using only single subject template images to estimate warps to MNI"

# Move timepoints to temporary directory so that only single subject templates are present for next step
for subj in $(cat $subj_list_coreg)
do
	for tp in $(cat $timepoint_list)
	do
		echo "removing ${subj}${tp} timepoints and only using midpoint for registration"
		mv FA/${subj}${tp}_data_FA.nii.gz FA_temp/${subj}${tp}_data_FA.nii.gz
		mv FA/${subj}${tp}_data_FA_mask.nii.gz FA_temp/${subj}${tp}_data_FA_mask.nii.gz
	done
done

tbss_2_reg -T

# Copy nonlinear warps estimated by each subjects template to every timepoint for each subject
for subj in $(cat $subj_list_coreg)
do
	echo "copying ${subj} midpoint warps to both timepoints"
	for tp in $(cat $timepoint_list)
	do
		# Copy warps estimated by single subject template to each subject timepoint
		cp FA/${subj}m_data_FA_to_target.mat FA/${subj}${tp}_data_FA_to_target.mat
		cp FA/${subj}m_data_FA_to_target.log FA/${subj}${tp}_data_FA_to_target.log
		cp FA/${subj}m_data_FA_to_target_warp.nii.gz FA/${subj}${tp}_data_FA_to_target_warp.nii.gz
		cp FA/${subj}m_data_FA_to_target_warp.msf FA/${subj}${tp}_data_FA_to_target_warp.msf

		# Move subject timepoint data from temporary directory back to FA directory
		mv FA_temp/${subj}${tp}_data_FA.nii.gz FA/${subj}${tp}_data_FA.nii.gz
		mv FA_temp/${subj}${tp}_data_FA_mask.nii.gz FA/${subj}${tp}_data_FA_mask.nii.gz
	done	
	echo "removing subject template data for ${subj}"
	rm FA/${subj}m_data_FA_to_target.mat		
	rm FA/${subj}m_data_FA_to_target.log
	rm FA/${subj}m_data_FA_to_target_warp.nii.gz
	rm FA/${subj}m_data_FA_to_target_warp.msf
	rm FA/${subj}m_data_FA_mask.nii.gz
	rm FA/${subj}m_data_FA.nii.gz
done

echo "Removing temporary FA directory"
rm -r FA_temp

tbss_3_postreg -S
tbss_4_prestats 0.2
