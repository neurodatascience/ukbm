import pandas as pd
import os


def unpack(encfile: str, keyfile: str, ukbunpack: str):
    '''
    Python interface for the UKB utility, 'ukbunpack'
    Parameters
    ----------
    encfile : str
        Filepath for the downloaded encoded file. Downloaded dataset from the UKB site.
    keyfile : str
        Keyfile associated with the encoded file. Sent to delegates by email from the UKB.
    ukbunpack : str
        Filepath for the ukbunpack utility. Downloaded file handler from the UKB site.

    Returns
    -------
    None
    '''
    os.system(f'{ukbunpack} {encfile} {keyfile}')
    return


def convert(ukbfile: str, ukbconv: str, formats: list,
            outname: str = None, encoding: str = 'encoding.ukb'):
    '''
    Python interface for the UKB utility, 'ukbconvert'.
    Parameters
    ----------
    ukbfile : str
        Filepath for the *.enc_ukb file output by ukbunpack.
    ukbconv : str
        Filepath for the ukbconv utility. Downloaded file handler from the UKB site.
    formats : list
        Conversion targets. Valid values are, ['csv','docs','sas','stata','r','lims','bulk','txt']
    outname : str
        Optional. Output name for file. Default is to replace the file extension of the input.
    encoding: str
        Optional. Encoding file. Defaults to 'encoding.ukb'
    Returns
    -------
    None
    '''

    # Sanity checks
    if(type(formats) is str):
        formats = [formats]


    for conv in formats:
        if(outname is None):
            os.system(f'{ukbconv} {ukbfile} {conv} -e{encoding}')
        else:
            os.system(f'{ukbconv} {ukbfile} {conv} -o{outname} -e{encoding}')
    return