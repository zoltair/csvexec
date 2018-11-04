## csvexec

This script is used to perform an action for each line an input CSV file and generate a line of CSV as output for each result.

This script can accept Unicode input with a byte-order mark, if one is present.

This script uses UTF-8 encoding with a byte-order mark for output. (Including a byte-order mark allows Microsoft Excel to recognize that a CSV file uses Unicode encoding when opening it.)

### Usage

`csvexec [options] [<filepath>]`

If the input is a file or **STDIN**, this script reads the input as CSV, calls hook functions in the specified parser (if any), and generates a line of CSV output for each result.

**Options:**

    -h, --help
        Displays a brief usage statement and exits

    -c, --check
        Displays the selected options and exits

    -d, --dry-run
        Performs the selected actions without making any changes
        (such as writing an output file)

    -v, --verbose
        Displays additional information while running

    -i, --input <filepath>
        The filename or filepath for the input CSV
        (uses STDIN if omitted or invalid)

    -p, --parser <module-name>
        Specifies the plug-in parser module to use on the input CSV
        If omitted, uses the default module, which copies the input
        columns to the output and performs no other action

    -a, --append
        Includes all columns from the input CSV in the output CSV
        (This option is useful when using the output from one
        execution as input for another execution)

    <filepath>
        The filename or filepath for the output CSV
        (uses STDOUT if omitted or invalid)

### Usage (alternate)

`csvexec -i <path> [options] [<filepath>]`

If the input is a directory, this script recursively searches that directory, calls hook functions in the specified parser (if any), and renders a line of CSV output for each file found.

This version accepts all previous options plus the one(s) listed below.

**Options:**

    -t, --type <filetype>
        Indicates the type of file to include in the output
        f  regular file (default)
        d  directory

## Plug-in Parser Hook Functions

Each hook function accepts a single parameter, a hash reference which contains all current options and input values.

<dl>
<dt><code>parser_print_usage()</code></dt>
<dd>Display an additional usage statement</dd>

<dt><code>parser_get_options()</code></dt>
<dd>Read any additional command-line options needed</dd>

<dt><code>parser_print_options()</code></dt>
<dd>Display additional command-line options selected</dd>

<dt><code>parser_init()</code></dt>
<dd>Perform any initialization needed</dd>

<dt><code>parser_final()</code></dt>
<dd>Perform any final cleanup needed</dd>

<dt><code>parser_wanted()</code></dt>
<dd>Process a found file and generate an output data row, if needed</dd>

<dt><code>parser_header_row()</code></dt>
<dd>Process an input header row and generate an output header row</dd>

<dt><code>parser_data_row()</code></dt>
<dd>Process an input data row and generate an output data row</dd>
</dl>
