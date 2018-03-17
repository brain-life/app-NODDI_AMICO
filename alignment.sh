#!/bin/bash

noddiImages="FIT_ICVF_NEW.nii.gz FIT_ISOVF_NEW.nii.gz FIT_OD_NEW.nii.gz FIT_dir.nii.gz config.pickle";
noddiFile="NODDI";
num="1 2 3";
mkdir $noddiFile;

echo "Setting file paths"
# Grab the config.json inputs
dwi=`jq -r '.dwi' config.json`;
bvals=`jq -r '.bvals' config.json`;
bvecs=`jq -r '.bvecs' config.json`;
dtiinitDwi=`jq -r '.dtiinitDwi' config.json`;
dtiinitBvals=`jq -r '.dtiinitBvals' config.json`;
echo "Files loaded"

## Align multishell dwi to acpc-aligned single shell dwi from dtiinit
echo "Aligning multishell dwi to acpc-space"
mkdir alignment;
cd ./alignment;

# Create b0 from dtiinit
select_dwi_vols \
	${dtiinitDwi} \
	${dtiinitBvals} \
	nodif_init.nii.gz \
	0;

# Create b0 from multi-shell dwi
select_dwi_vols \
	${dwi} \
	${bvals} \
	nodif_multi.nii.gz \
	0;

# Obtain transformation matrix from nodif_init to nodif_multi
flirt \
	-in nodif_multi.nii.gz \
	-ref nodif_init.nii.gz \
	-out nodif_aligned.nii.gz \
	-omat acpcxform.mat;

# Align multi-shell dwi to nodif_multi
flirt \
	-in ${dwi} \
	-ref nodif_aligned.nii.gz \
	-out dwi.nii.gz \
	-init acpcxform.mat \
	-applyxfm;

# Clean up and change directory
mv dwi.nii.gz ../;
mv acpcxform.mat ../;
cd ..;
rm -rf ./alignment;

echo "alignment complete"
