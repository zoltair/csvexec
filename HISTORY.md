# History

In the beginning, I needed to reorganize a very large number of
files in several directories into an all-new structure based on
information that was (mostly) contained within the original filenames.
These filenames were *mostly* consistent - consistent enough to
make regular expressions seem like a plausible solution, but not
quite consistent enough to make it a reliable one.

What I needed was a way to parse out these filenames, propose new
folders and filenames for each source file, but alloow for a
manual review before performing the actual move and rename process.

To that end, I created three scripts. One (`readfiles`) to find
all files in a given directory and return one line of CSV for
each file found. Another (`parsefiles`) to parse out data elements
from the filenames (and folder structure) and generate a CSV
file which could be loaded into Microsoft Excel for manual review.
And a third (`movefiles`) to perform the actual move and rename
process, using the CSV file exported from Excel to determine
the source and destination for each file.

This led to issues with non-ASCII characters, what Unicode
encodings Microsoft Excel can import and export, and how different
filesystems encode (or don't encode) their filenames.
(Spoiler alert: It's a mess all 'round.)

The idea worked well enough, but I needed to change or create a
new `parsefiles` script for every directory with an even
slightly different naming convention. Realizing that most of
the process would stay the same, I factored out the functions
which needed to change using a bare-bones plug-in system.

In doing so, I realized that the `movefiles` process could work
just as well as a plug-in - it just performed an action for each
line of CSV data in addition to generating a line of CSV data for
its results. So, "MoveFiles" became the first `parsefiles` plug-in.

Adding the ability to accept input on STDIN and generate output
to STDOUT allowed me to daisy-chain instances of `parsefiles`,
each using a differnt plug-in. In turn, this also allowed me to
refactor my plug-ins into smaller units.

Having reduced the number of scripts from three down to two, I
decided to fold the `readfiles` script into the `parsefiles`
system. It couldn't be a plug-in because (at that time) they were
locked into producing one line of output for each line of input,
but one directory path would need to generate multiple lines of
output. So `readfiles` was folded directly into the `parsefiles`
script, changing its behavior depending on whether the `--input`
option referred to an existing path or an existing file.

It seemed like a good idea at the time, but everytime I went to
use it afterwards, my first point of confusion was always: Where's
my `readfiles` script? How do I get my list of files? So, if it
hasn't been split out already, I will most likely do that at some
point in the future.

Since then, this script and its plug-ins have been rewritten and
renamed several times, but a few references to the original names,
`readfiles`, `parsefiles`, and `movefiles`, are still present.
And the plug-in system has allowed me to turn this into a more
generally useful tool for driving any sort of action based on CSV
input.
