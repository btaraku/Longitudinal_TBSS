#!/bin/bash

data_dir=$1
subj=$2
timepoint_list=$3
FA_filename=$4

pushd ${data_dir}
echo $subj

# Create 4x4 identity matrix to use for FSL's midtrans command
echo 1  0  0  0 > 4x4_identity.mat
echo 0  1  0  0 >> 4x4_identity.mat
echo 0  0  1  0 >> 4x4_identity.mat
echo 0  0  0  1 >> 4x4_identity.mat

for tp1 in $(cat $timepoint_list)
do
	mat_str=""
	for tp2 in $(cat $timepoint_list)
	do
		if [[ "${tp1}" != "${tp2}" ]]
		then
			echo "estimating transformation matrix from ${tp2} to ${tp1}"
			flirt -in ${subj}${tp2}/${FA_filename} -ref ${subj}${tp1}/${FA_filename} -omat ${subj}${tp2}/${subj}${tp2}_to_${tp1}.mat -dof 6
			mat_str="${mat_str} ${subj}${tp2}/${subj}${tp2}_to_${tp1}.mat"
		fi
	done
	echo "estimating mid transformation for ${tp1}"
	midtrans -o ${subj}${tp1}/${subj}${tp1}_to_mid.mat ${mat_str} 4x4_identity.mat
	echo "applying mid transfrom for ${tp1}"
	flirt -in ${subj}${tp1}/${FA_filename} -ref ${subj}${tp1}/${FA_filename} -applyxfm -init ${subj}${tp1}/${subj}${tp1}_to_mid.mat -out ${subj}${tp1}/${FA_filename}_coreg_mid
done
