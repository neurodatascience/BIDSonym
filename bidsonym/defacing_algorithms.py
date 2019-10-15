import os
from subprocess import check_call

import nipype.pipeline.engine as pe
from nipype import Function
from nipype.interfaces import utility as niu
from nipype.interfaces.quickshear import Quickshear
from nipype.interfaces.fsl import BET
from shutil import copy, move


# define function for pydeface
def pydeface_cmd(image, outfile):
    from subprocess import check_call
    #pydeface $image --outfile $outfile
    cmd = ["pydeface", image,
           "--out", outfile,
           "--force",
           ]
    check_call(cmd)
    return

def run_pydeface(image, outfile):
    deface_wf = pe.Workflow('deface_wf')
    inputnode = pe.Node(niu.IdentityInterface(['in_file']),
                     name='inputnode')
    pydeface = pe.Node(Function(input_names=['image', 'outfile'],
                                output_names=['outfile'],
                                function=pydeface_cmd),
                                name='pydeface')
    deface_wf.connect([
        (inputnode, pydeface, [('in_file', 'image')]),
        ])
    inputnode.inputs.in_file = image
    pydeface.inputs.outfile = outfile
    res = deface_wf.run()

# define function for mri_deface
def mri_deface_cmd(image, outfile):
    #mri_deface $image $brain_template $face_template $outfile
    cmd = ["mri_deface", image,
                         '/home/fs_data/talairach_mixed_with_skull.gca',
                         '/home/fs_data/face.gca',
                         outfile,
           ]
    check_call(cmd)
    return

def run_mri_deface(image, outfile):
    deface_wf = pe.Workflow('deface_wf')
    inputnode = pe.Node(niu.IdentityInterface(['in_file']),
                     name='inputnode')
    mri_deface = pe.Node(Function(input_names=['image', 'outfile'],
                                output_names=['outfile'],
                                function=mri_deface_cmd),
                                name='pydeface')
    deface_wf.connect([
        (inputnode, mri_deface, [('in_file', 'image')]),
        ])
    inputnode.inputs.in_file = image
    mri_deface.inputs.outfile = outfile
    res = deface_wf.run()


# define function for quickshear
# based on the nipype docs quickshear example
def run_quickshear(image, outfile):
    #quickshear anat_file mask_file defaced_file [buffer]
    deface_wf = pe.Workflow('deface_wf')
    inputnode = pe.Node(niu.IdentityInterface(['in_file']),
                     name='inputnode')
    outputnode = pe.Node(niu.IdentityInterface(['out_file']),
                      name='outputnode')
    bet = pe.Node(BET(mask=True, frac=0.5), name='bet')
    quickshear = pe.Node(Quickshear(buff=50), name='quickshear')
    deface_wf.connect([
        (inputnode, bet, [('in_file', 'in_file')]),
        (inputnode, quickshear, [('in_file', 'in_file')]),
        (bet, quickshear, [('mask_file', 'mask_file')]),
        ])
    inputnode.inputs.in_file = image
    quickshear.inputs.out_file = outfile
    res = deface_wf.run()

# define function for mridefacer
def mridefacer_cmd(image, subject_label):
    cmd = ["mridefacer/mridefacer", "--apply",
                         image]
    check_call(cmd)
    path = os.path.join(args.bids_dir, "sourcedata/bidsonym/sub-%s"%subject_label)
    facemask = os.path.join(args.bids_dir, "sub-%s"%subject_label, "anat/sub-%s_T1w_defacemask.nii.gz"%subject_label)
    if os.path.isdir(path) == True:
        move(facemask, os.path.join(path))
    else:
        os.makedirs(path)
        move(facemask, os.path.join(path))
    return

def run_mridefacer(image, subject_label):
    deface_wf = pe.Workflow('deface_wf')
    inputnode = pe.Node(niu.IdentityInterface(['in_file']),
                     name='inputnode')
    mridefacer = pe.Node(Function(input_names=['image', 'subject_label'],
                                output_names=['outfile'],
                                function=mri_deface_cmd),
                                name='pydeface')
    mridefacer.connect([
        (inputnode, mridefacer, [('in_file', 'image')]),
        ])
    inputnode.inputs.in_file = image
    mridefacer.inputs.subject_label = subject_label
    res = deface_wf.run()
