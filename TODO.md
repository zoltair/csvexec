# TODO

* Add documentation
* Add --version option
* Add --usage option
* Add output file encoding option(s)
* Add '-' to indicate STDIN/STDOUT for --input and --output options
* Review STDIN/STDOUT acquisition/release methods
* Convert CSV_Exec::IO module into a class (using Moose/Moo)
* Cleanup parser loading and handling
  * Differentiate CSV input parsers from file finding parsers
  * Convert parser modules into parser classes (using Moose/Moo)
  * Create base/rolse classes for each parser class type
* Change error handling to use exception throwing/catching instead of true/false return values
  * Review autodie module (replaces Fatal)
  * Review try/catch modules (Try::Tiny, TryCatch, etc.)
  * Review exception class modules (Exception::Class, Throwable, etc.)
  * Create CSV_Exec::Exception module
