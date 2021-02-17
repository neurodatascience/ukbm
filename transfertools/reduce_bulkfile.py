import os, sys, argparse

def reduce_bulkfile(bulk_file: str, out_file: str, data_dir: str = './', field: str = None, verbose: bool = False):
    '''
    This function verifies the data directory and compares it against the input bulk file. Missing data is placed
    in a new bulkfile.
    Parameters
    ----------
    bulk_file : str
        Path to the bulk file to reduce.
    out_file : str
        Path to the output bulk file.
    data_dir : str
        Optional. Path to the directory containing the (potentially-incomplete) data. Default to current working dir.
    field : str
        Optional. If specified, limit checks to specific field.
    verbose : bool
        Optional. Whether to print out reduction info before returning.

    Returns
    -------
    None
    '''
    # Get data
    f = open(bulk_file,'r')
    bulk_list = f.read().splitlines()
    f.close()
    spl = [s.split(' ') for s in bulk_list]

    # Split into subject / datafield
    if(field is None):
        sub_bulk = [s[0] for s in spl]
        datafield_bulk = [s[1] for s in spl]
    else:
        sub_bulk = [s[0] for s in spl if field in s[1]]
        datafield_bulk = [s[1] for s in spl if field in s[1]]

    # Get fetched
    fetched_files = os.listdir(data_dir)
    # Default format is [subject]_[datafield]_[session]_[arrayidx]
    spl = [s.split('_') for s in fetched_files if '_' in s]
    # Split into subject / datafield
    if(field is None):
        sub_fetched = [s[0] for s in spl]
        datafield_fetched = ['_'.join(s[1:]).split('.')[0] for s in spl]
    else:
        sub_fetched = [s[0] for s in spl if field in '_'.join(s[1:])]
        datafield_fetched = ['_'.join(s[1:]).split('.')[0] for s in spl if field in '_'.join(s[1:])]

    # Convert to sets for quick comparison
    set_bulk = set([sb + '_' + db for sb, db in zip(sub_bulk, datafield_bulk)])
    set_fetched = set([sf + '_' + df for sf, df in zip(sub_fetched, datafield_fetched)])
    diff = set_bulk.difference(set_fetched)

    f = open(out_file,'w')
    for d in diff:
        sub_ind = d.find('_')
        f.write(f'{d[:sub_ind]} {d[sub_ind+1:]}\n')
    f.close()
    if(verbose):
        print(f'Reduced bulk file from {len(sub_bulk)} to {len(diff)} entries (reduced by {len(sub_bulk)-len(diff)})')
    return

def main(args):
    des = 'Creates a new UKBB bulkfile without already-fetched data'
    parser = argparse.ArgumentParser(prog='reduce_bulkfile', description=des)
    parser.add_argument('bulk', metavar='bulkfile', type=str, help='The bulkfile to reduce')
    parser.add_argument('out', metavar='output', type=str, help='The path for the new bulkfile')
    parser.add_argument('-f', '--field', metavar='field', type=str,
                        help='Field to which to limit the comparison', default=None)
    parser.add_argument('-d', '--datadir', metavar='datadir', type=str,
                        help='Location of the fetched data', default=None)
    parser.add_argument('-v', '--verbose', help='Whether to print out reduction info',
                        action='store_true', default=False)
    args = parser.parse_args(args)
    reduce_bulkfile(args.bulk, args.out, field=args.field, data_dir=args.datadir, verbose=args.verbose)


if __name__ == '__main__':
    main(sys.argv[1:])
