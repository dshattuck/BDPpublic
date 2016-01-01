
# Masks
Statistics are only computed inside the intersection of brain mask and labels. 

## Diffusion coordinates
* The mask is defined by transfering the T1-mask to diffusion coordinates. 
* The mask is refined by removing voxels which has zeros in b=0 images (estimate_tensors.m)

# Label description xml
* BDP has its own label description file with name brainsuite_labeldescription_BDP.xml. This is used when no custom-xml file is defined. BDP's xml file is derived from BrainSuite's xml file with purpose of shortening/removing a number of ROIs which are not used for reporting stats and to make BDP stats similar/compatible with SVReg's stats.
