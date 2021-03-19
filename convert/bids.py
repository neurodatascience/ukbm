import os, pathlib, zipfile, tempfile, shutil, argparse
from os.path import join


# Workaround to work as module and have __main__. I don't like it, but I haven't found a better way to do it.
if(__package__ is not None):
    from .REL_DICT import ukbb_bids_dict
    from .REL_DICT import ukbb_derivs_toplevel
    from .REL_DICT import ukbb_source_dict
else:
    from REL_DICT import ukbb_bids_dict
    from REL_DICT import ukbb_derivs_toplevel
    from REL_DICT import ukbb_source_dict


def bids_from_zip(zip_filepath: str, raw_dir: str = None, derivatives_dir: str = None, source_dir: str = None):
    '''
    Converts the zip file of NIfTI images downloaded from the UKBB into BIDS.
    NOTE: At the time this code was written, the derivatives/ extension was not part of the specs. As such, derivatives
    are prepended with subject ID and
    Parameters
    ----------
    zip_filepath: str
        Path of the downloaded zip file
    raw_dir : str
        Optional. Path where to place raw data. Output will be saved in 'raw_dir/sub-XXXX'.
        If undefined, raw data will not be extracted.
    derivatives_dir : str
        Optional. Path where to place derivatives (non-raw) data. Output will be saved in 'derivatives_dir/sub-XXX'.
        If undefined, derivatives will not be extracted.
    source_dir : str
        Optional. Path where to place source (raw files used to compute a secondary modality e.g. SWI->QSM). Output
        will be saved in source_dir/sub-XXXX
    Returns
    -------
    None
    '''
    if(raw_dir == derivatives_dir == source_dir == None):
        Warning('Either raw_dir, derivatives_dir, or source_dir must be defined for anything to be done.')
        return
    zip_data = zipfile.ZipFile(zip_filepath)

    # Extract all files into temporary directory (NOTE: extracting all files at once vs. one at a time is ~2x as fast)
    unzipped_dir = tempfile.mkdtemp()
    zip_data.extractall(unzipped_dir)
    # Get filename without leading path
    zip_filename = zip_filepath.split(os.sep)[-1]
    # Format is SUBJECT_DATAFIELD_SESSION_ARRAYIND.zip
    subject, datafield, session, arrayind = zip_filename[:-4].split('_')

    file_list = []

    for path, _, files in os.walk(unzipped_dir):
        for f in files:
            file_list.append(os.path.join(path.replace(unzipped_dir + os.sep, ''), f))
    for file in file_list:
        raw_bids = get_bids_raw_name(subject=subject, file_name=file, session=session)
        source_bids = get_bids_source_name(subject=subject, file_name=file, session=session)
        deriv_bids = get_bids_derivs_name(subject=subject, file_name=file, session=session)
        if(raw_bids is not None and raw_dir is not None):
            # File is raw; put in raw dir
            # zip_data.extract(file, raw_bids)
            bids_name = join(raw_dir, raw_bids)
            bids_path = bids_name[:bids_name.rfind(os.sep)]
            pathlib.Path(bids_path).mkdir(parents=True, exist_ok=True)
            # Check if on the same device for tmp vs. destination
            dev_tmp = os.stat(unzipped_dir).st_dev
            dev_dest = os.stat(raw_dir).st_dev
            if(dev_tmp == dev_dest):
                # Same device; just rename
                os.rename(join(unzipped_dir, file), join(raw_dir, raw_bids))
            else:
                # Diff device; copy
                shutil.copyfile(join(unzipped_dir, file), join(raw_dir, raw_bids))
        elif (source_bids is not None and source_dir is not None):
            # File is source
            bids_name = join(source_dir, source_bids)
            bids_path = bids_name[:bids_name.rfind(os.sep)]
            pathlib.Path(bids_path).mkdir(parents=True, exist_ok=True)
            dev_tmp = os.stat(unzipped_dir).st_dev
            dev_dest = os.stat(source_dir).st_dev
            if (dev_tmp == dev_dest):
                os.rename(join(unzipped_dir, file), join(source_dir, source_bids))
            else:
                shutil.copyfile(join(unzipped_dir, file), join(source_dir, source_bids))
        elif(deriv_bids is not None and derivatives_dir is not None):
            # NOTE: Derivs must be checked last; since there's no standard for derivatives yet, we're placing
            # everything there as-is, but prepended with the subject ID.
            # File is derivatives
            bids_name = join(derivatives_dir, deriv_bids)
            bids_path = bids_name[:bids_name.rfind(os.sep)]
            pathlib.Path(bids_path).mkdir(parents=True, exist_ok=True)
            dev_tmp = os.stat(unzipped_dir).st_dev
            dev_dest = os.stat(derivatives_dir).st_dev
            if(dev_tmp == dev_dest):
                os.rename(join(unzipped_dir, file), join(derivatives_dir, deriv_bids))
            else:
                shutil.copyfile(join(unzipped_dir, file), join(derivatives_dir, deriv_bids))
        else:
            Warning(f'File {file} was not sorted.')

    shutil.rmtree(unzipped_dir)
    return


def get_bids_source_name(subject: str, file_name: str, session: str = '2'):
    '''
    Given a subject ID and filename, will return the BIDS-like name for source data. Note that the 'source' folder is
    not currently restricted under BIDS.
    Parameters
    ----------
    subject : str
        Subject ID
    file_name : str
        Name of the file relative to top-level of downloaded zip.
    session : str
        Value for session (2 & 3 are imaging)
    Returns
    -------
        BIDS-like path for new file
    '''
    try:
        bids_source_name = ukbb_source_dict[file_name].format(subject=subject, session=session)
        return bids_source_name
    except(KeyError):
        return None


def get_bids_raw_name(subject: str, file_name: str, session: str = '2'):
    '''
    Given a subject ID and filename, will return the BIDS name for raw data
    Parameters
    ----------
    subject : str
        Subject ID
    file_name : str
        Name of the file relative to top-level of downloaded zip.
    session : str
        Value for session (2 & 3 are imaging)

    Returns
    -------
        BIDS path for new file
    '''
    # Returns BIDS filename, relative to top-level directory ( OUTPUT_DIRECTORY/ )
    # Split filename according to subject
    # file_split = file_name.split(subject + '/')[-1]
    try:
        bids_name = ukbb_bids_dict[file_name].format(subject=subject, session=session)
        return bids_name
    except KeyError:
        return None


def get_bids_derivs_name(subject: str, file_name: str, session: str = '2'):
    """
    Given a subject ID and filename, will return a BIDS-like name for derivative data

    Parameters
    ----------
    subject : str
        Subject ID
    file_name : str
        Name of the file relative to top-level of downloaded zip.
    session : str
        Value for session (2 & 3 are imaging)
    Returns
    ----------
    str
        BIDS-like path for new file
    """
    # First get top-level directory
    try:
        top_level = file_name.split(os.sep)[0]
        bids_top_level = ukbb_derivs_toplevel[top_level].format(subject=subject,session=session)
        file_path = os.path.join(*file_name.split(os.sep)[1:])
        return os.path.join(bids_top_level + file_path)
    except(KeyError):
        return None


def main():
    parser = argparse.ArgumentParser('Convert .zip file downloaded from UKBB to BIDS')
    parser.add_argument('--zip_filepath', help='name of the file to convert')
    parser.add_argument('--raw_dir', help='destination for raw BIDS data')
    parser.add_argument('--source_dir', help='destination for source data')
    parser.add_argument('--derivatives_dir', help='destination for derivative data')
    parser.add_argument('--zip_filelist', help='text file containing the filepaths of the zip files')
    args = parser.parse_args()
    if(args.zip_filelist is not None):
        f = open(args.zip_filelist, 'r')
        zlist = f.read().splitlines()
        f.close()
        for z in zlist:
            bids_from_zip(z, raw_dir=args.raw_dir, derivatives_dir=args.derivatives_dir,
                          source_dir=args.source_dir)
    else:
        bids_from_zip(args.zip_filepath, raw_dir=args.raw_dir, derivatives_dir=args.derivatives_dir,
                      source_dir=args.source_dir)
    return


if __name__ == '__main__':
    main()