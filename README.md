This script is used to perform a series of actions reading CSV for input and generating CSV as output.

This script assumes that the input uses UTF-8 encoding and can accept a byte-order mark, if one is present.

The output uses UTF-8 encoding and, when written to a file, includes a byte-order mark.
Including this byte-order mark allows Microsoft Excel to recognize these as UTF-8 files when opening them.

## Usage

`csvexec [options] filepath`

If the input is a file, interprets it as CSV and uses the specified parser module to perform an action for each row.

If the input is a directory, recursively searches it and returns a CSV row for each directory or regular file found.

**Options:**
    `-h, --help`
        Displays a brief usage statement and exits

    `-c, --check`
        Displays the selected options and exits

    `-d, --dry-run`
        Performs the selected actions without making any changes (such as writing an output file)

    `-v, --verbose`
        Displays additional information while running

    `-i, --input` *filepath*
        The filename or filepath for an input CSV file
        (uses **STDIN** if omitted or invalid)

    `-t, --type` *filetype*
        Indicates the type of file to include in the output
        *f*  regular file (*default*)
        *d*  directory

    `-p, --parser` *module-name*
        Specifies the parser module to use on the input CSV
        If omitted, uses the internal parser module, which copies the input columns to the output and performs no other action

    `-a, --append`
        Include all columns from the input CSV in the output CSV
        This option is particularly useful for piping the results of one execution into another execution

    `-e, --encode` *encoding*
        Specifies the encoding to use for filenames when interacting with the filesystem
            NTFS uses a 16-bit character encoding (UCS-2 or UTF-16)
            FAT variants use an OEM Codepage (CP-437 or CP-1252 by default) for short names
                and a 16-bit encoding (UCS-2 or UTF-16) for long names (UTF-16 since Windows 2000)
            ext4 variants use a NUL-terminated sequence of bytes with no regard for encoding
                Each process can therefore decide for itself what encoding to use for any filenames
                Most Unix-like systems expect processes to use the environment's locale
                Modern Linux systems (such as Ubuntu) typically default to UTF-8 (`utf-8-strict` in perl)
        If omitted, uses 'utf-8-strict' (strict interpretation of UTF-8)

    *filepath*
        The filename or filepath for an output CSV file
        (uses **STDOUT** if omitted or invalid)

## Plug-in Hook Functions

`parser_print_usage`
    Display an additional usage statement

`parser_get_options`
    Read any additional command-line options needed

`parser_print_options`
    Display additional command-line options selected

`parser_init`
    Perform any initialization needed

`parser_final`
    Perform any final cleanup needed

`parser_wanted`
    Process a found file and generate an output data row, if needed

`parser_header_row`
    Process an input header row and generate an output header row

`parser_data_row`
    Process an input data row and generate an output data row
