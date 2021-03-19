# This file has been modified from its original form.
# Parts of the data was originally taken from: https://git.fmrib.ox.ac.uk/falmagro/UK_biobank_pipeline_v_1/blob/master/bb_data/UKBB_to_BIDS.json
# It was modified to default to relative pathing (without "BIDS/" top-level directory)

ukbb_bids_dict = {'T1/T1.nii.gz': 'sub-{subject}/ses-{session}/anat/sub-{subject}_ses-{session}_T1w.nii.gz',
'dMRI/raw/PA.nii.gz': 'sub-{subject}/ses-{session}/dwi/sub-{subject}_ses-{session}_acq-PA_dwi.nii.gz',
'dMRI/raw/PA.bval': 'sub-{subject}/ses-{session}/dwi/sub-{subject}_ses-{session}_acq-PA_dwi.bval',
'fMRI/tfMRI_SBREF.nii.gz': 'sub-{subject}/ses-{session}/func/sub-{subject}_ses-{session}_task-hariri_sbref.nii.gz',
'fMRI/rfMRI_SBREF.nii.gz': 'sub-{subject}/ses-{session}/func/sub-{subject}_ses-{session}_task-rest_sbref.nii.gz',
'dMRI/raw/AP.bvec': 'sub-{subject}/ses-{session}/dwi/sub-{subject}_ses-{session}_acq-AP_dwi.bvec',
'T2_FLAIR/T2_FLAIR.nii.gz': 'sub-{subject}/ses-{session}/anat/sub-{subject}_ses-{session}_FLAIR.nii.gz',
'dMRI/raw/AP.nii.gz': 'sub-{subject}/ses-{session}/dwi/sub-{subject}_ses-{session}_acq-AP_dwi.nii.gz',
'fMRI/rfMRI.nii.gz': 'sub-{subject}/ses-{session}/func/sub-{subject}_ses-{session}_task-rest_bold.nii.gz',
'raw/T1_notNorm.nii.gz': 'sub-{subject}/ses-{session}/anat/sub-{subject}_ses-{session}_acq-notNorm_T1w.nii.gz',
'dMRI/raw/PA.bvec': 'sub-{subject}/ses-{session}/dwi/sub-{subject}_ses-{session}_acq-PA_dwi.bvec',
'raw/PA_SBREF.nii.gz': 'sub-{subject}/ses-{session}/dwi/sub-{subject}_ses-{session}_acq-PA_sbref.nii.gz',
'raw/T2_FLAIR_notNorm.nii.gz': 'sub-{subject}/ses-{session}/anat/sub-{subject}_ses-{session}_acq-notNorm_FLAIR.nii.gz',
'fMRI/tfMRI.nii.gz': 'sub-{subject}/ses-{session}/func/sub-{subject}_ses-{session}_task-hariri_bold.nii.gz',
'raw/AP_SBREF.nii.gz': 'sub-{subject}/ses-{session}/dwi/sub-{subject}_ses-{session}_acq-AP_sbref.nii.gz',
'dMRI/raw/AP.bval': 'sub-{subject}/ses-{session}/dwi/sub-{subject}_ses-{session}_acq-AP_dwi.bval'
}

# Include .json files
tmp_dict = {}
for k, v in ukbb_bids_dict.items():
    json_key = k.replace('.nii.gz', '.json')
    json_value = v.replace('.nii.gz','.json')
    tmp_dict[json_key] = json_value
for k, v in tmp_dict.items():
    ukbb_bids_dict[k] = v

ukbb_derivs_toplevel = {'T2_FLAIR': 'sub-{subject}/ses-{session}/anat/sub-{subject}_ses-{session}_',
                        'T1': 'sub-{subject}/ses-{session}/anat/sub-{subject}_ses-{session}_',
                        'fieldmap': 'sub-{subject}/ses-{session}/fmap/sub-{subject}_ses-{session}_',
                        'fMRI': 'sub-{subject}/ses-{session}/func/sub-{subject}_ses-{session}_',
                        'dMRI': 'sub-{subject}/ses-{session}/dwi/sub-{subject}_ses-{session}_',
                        'SWI': 'sub-{subject}/ses-{session}/swi/sub-{subject}_ses-{session}_'
                        }

ukbb_nifti_datafields = ['20227', '20249', '20250','20251','20252', '20253']
# 20227: rfMRI
# 20249: tfMRI
# 20250: dwi
# 20251: swi
# 20252: t1
# 20253: t2

# As of this writing, SWI was an inactive BEP with last contributions from several months ago. We're putting them in the
# source folder since there's no specs for the format.
# https://docs.google.com/document/d/1kyw9mGgacNqeMbp4xZet3RnDhcMmf4_BmRgKaOkO2Sc/view#

ukbb_source_dict = {
'SWI/SWI_TOTAL_PHA.nii.gz': 'sub-{subject}/ses-{session}/swi/sub-{subject}_ses-{session}_acq-phaTotalEcho1_SWImagandphase.nii.gz',
'SWI/SWI_TOTAL_MAG.nii.gz': 'sub-{subject}/ses-{session}/swi/sub-{subject}_ses-{session}_acq-magTotalEcho1_SWImagandphase.nii.gz',
'SWI/SWI_TOTAL_MAG_TE2.nii.gz': 'sub-{subject}/ses-{session}/swi/sub-{subject}_ses-{session}_acq-magTotalEcho2_SWImagandphase.nii.gz',
'SWI/SWI_TOTAL_PHA_TE2.nii.gz': 'sub-{subject}/ses-{session}/swi/sub-{subject}_ses-{session}_acq-phaTotalEcho2_SWImagandphase.nii.gz',
'raw/SWI_TOTAL_MAG_notNorm_TE2.nii.gz': 'sub-{subject}/ses-{session}/swi/sub-{subject}_ses-{session}_acq-magTotalNotNormEcho2_SWImagandphase.nii.gz',
'raw/SWI_TOTAL_MAG_notNorm.nii.gz': 'sub-{subject}/ses-{session}/swi/sub-{subject}_ses-{session}_acq-magTotalNotNormEcho1_SWImagandphase.nii.gz',
}