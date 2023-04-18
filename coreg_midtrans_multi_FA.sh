#!/bin/bash

# Use to Co-register scans from a single subject across multiple timepoints
#
# Takes as input a data directory (data_dir), a subject ID (subj) and
# the names of the timepoints saved in a text file, which are appended to
# the end of the subject ID (timepoint_list) and the name of the file being
# co-regsitered (FA_filename)
#
# Outputs all co-registered scans for all timepoints, as well as the transformation
# matricies to co-registered space

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

# loop through the list of timepoints
for tp1 in $(cat $timepoint_list)
do
	mat_str=""
	for tp2 in $(cat $timepoint_list)
	do	
		# If timepoints are not the same, then we calculate the transformation matrix between the 2 timepoints
		if [[ "${tp1}" != "${tp2}" ]]
		then
			# Estimate linear transformation using flirt and save transformation in .mat
			echo "estimating transformation matrix from ${tp2} to ${tp1}"
			flirt -in ${subj}${tp2}/${FA_filename} -ref ${subj}${tp1}/${FA_filename} -omat ${subj}${tp2}/${subj}${tp2}_to_${tp1}.mat -dof 6
			
			# Save all transformations in a string to estimate midpoint registration from tp1
			mat_str="${mat_str} ${subj}${tp2}/${subj}${tp2}_to_${tp1}.mat"
		fi
	done
	# Estimate midpoint transformation from the saved transformation matricies, using FSL's midtrans
	echo "estimating mid transformation for ${tp1}"
	midtrans -o ${subj}${tp1}/${subj}${tp1}_to_mid.mat ${mat_str} 4x4_identity.mat
	
	# Apply midpoint transformation to tp1
	echo "applying mid transfrom for ${tp1}"
	flirt -in ${subj}${tp1}/${FA_filename} -ref ${subj}${tp1}/${FA_filename} -applyxfm -init ${subj}${tp1}/${subj}${tp1}_to_mid.mat -out ${subj}${tp1}/${FA_filename}_coreg_mid
done
