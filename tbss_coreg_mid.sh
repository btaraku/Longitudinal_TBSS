#!/bin/bash

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

for subj_coreg in $(cat $subj_list_coreg)
do
	for tp in $(cat $timepoint_list)
	do
		echo "copying co-registered data for ${subj_coreg}${tp}"
		cp ${data_dir}/${subj_coreg}${tp}/${FA_filename}_coreg_mid.nii.gz ${tbss_dir}/${subj_coreg}${tp}_data.nii.gz
	done
done
for subj_nocoreg in $(cat $subj_list_nocoreg)
do
	echo "copying non co-registered data for ${subj_coreg}"
	cp ${data_dir}/${subj_nocoreg}/${FA_filename}.nii.gz ${tbss_dir}/${subj_nocoreg}_data.nii.gz
done
for subj_temp in $(cat $subj_list_coreg)
do
	echo "copying timepoint averaged template for ${subj_temp}"
	cp ${data_dir}/${temp_pfx}${subj_temp}${template_filename}.nii.gz ${tbss_dir}/${subj_temp}m_data.nii.gz
done


pushd ${tbss_dir}/
#Slightly modified tbss pipeline
tbss_1_preproc *.nii.gz
# Estimate warps for only midpoint data that has multi timepoints
echo "Making temporary FA directory"
mkdir FA_temp
echo "using only single subject template images to estimate warps to MNI"
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
