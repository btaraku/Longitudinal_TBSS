#!/bin/bash

data_dir=$1
subj=$2
timepoint_list=$3
FA_filename=$4
outfile=$5
kernel=$6

pushd $data_dir

files=""

for timepoint in $(cat $timepoint_list)
do
	files="${subj}${timepoint}/${FA_filename}_coreg_mid ${files}"
done

# Merge files and compute mean
echo "computing single subject template for ${subj}"
fslmerge -t ${subj}_${outfile} ${files}
fslmaths ${subj}_${outfile} -Tmean ${data_dir}/${subj}_${outfile}

# Smooth timepoint average file if smoothing kernel is provided
if [[ "$kernel" != "" ]]
then
	echo "smoothing single subject template with kernel ${kernel}"
	#method to smooth within binary mask only
	fslmaths ${subj}_${outfile} -bin ${data_dir}/${subj}_${outfile}_mask
	fslmaths ${subj}_${outfile} -s ${kernel} -mas ${data_dir}/${subj}_${outfile}_mask ${data_dir}/result1
	fslmaths ${subj}_${outfile}_mask -s ${kernel} -mas ${data_dir}/${subj}_${outfile}_mask ${data_dir}/result2
	fslmaths result1 -div ${data_dir}/result2 ${data_dir}/s${kernel}_${subj}_${outfile}
	rm result1.nii*
	rm result2.nii*
fi

popd
