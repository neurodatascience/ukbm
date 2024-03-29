import os, sys, argparse


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


def main(arg):
    des = 'Converts UKB encoded file into csv, docs, sas, stata, r, and bulk.'
    parser = argparse.ArgumentParser(prog='tabular_conversion', description=des)
    parser.add_argument('ukbfile',metavar='ukbfile', type=str, help='The data file to process. If ukbunpack is defined, the encoded file is expected. Otherwise, the decoded file (.enc_ukb) is expected.')
    parser.add_argument('-a', '--authkey', metavar='authkey', type=str, default=None, help='The key file supplied by the UKB')
    parser.add_argument('-p', '--ukbunpack', metavar='ukbunpack', type=str,
                        help='The ukbunpack utility downloaded from the UKB', default=None)
    parser.add_argument('-c', '--ukbconv',metavar='ukbconv', type=str,
                        help='The ukbconv utility downloaded from the UKB', default=None)
    parser.add_argument('-o', '--output', metavar='output', type=str,
                        help='Filename prefix for the output; file extensions are set by the format.',
                        default='tabular')
    parser.add_argument('-e', '--encoding',metavar='encoding', type=str,
                        help='The encoding.ukb file downloaded from the UKB site.', default='./encoding.ukb')
    parser.add_argument('-f', '--format', metavar='format', nargs='*',
                        help='The formats to convert to (valid: csv, docs, sas, stata, r, lims, bulk, txt). Defaults \''
                             'to csv, bulk, r, docs, sas, stata',
                        default=['csv', 'bulk','r','docs','sas', 'stata'])

    parsed_args = parser.parse_args(arg)
    # unpack
    if(parsed_args.ukbunpack is not None):
        unpack(encfile=parsed_args.ukbfile, keyfile=parsed_args.authkey, ukbunpack=parsed_args.ukbunpack)
    #unpack(encfile=parser.encfile, keyfile=parser.keyfile, ukbunpack=parser.unpack)
        unpacked_name = parsed_args.ukbfile + '_ukb'
    else:
        unpacked_name = parsed_args.ukbfile
    if(parsed_args.ukbconv is not None):
        convert(ukbfile=unpacked_name, ukbconv=parsed_args.ukbconv, formats=parsed_args.format, outname=parsed_args.output,
            encoding=parsed_args.encoding)


if __name__ == "__main__":
    main(sys.argv[1:])
