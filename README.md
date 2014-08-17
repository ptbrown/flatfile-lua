Flat File Reader/Writer for Lua
===============================

This module reads and writes tables as files with fixed-width records.

Functions
---------

### open

        flatfile.open(source, mode)

Creates a new object for reading or writing a file. The source is either an
open file object or a filename to be opened. The mode is either `"r"`, `"w"`,
or `"a"` to read, write, or append to the file. When passing an open file as the
source, the mode must be compatible with the existing handle. A handle to be
used for appending must allow both reading and writing.

The new file object will not have any columns defined. You must use `columns`
or `header` to set the column widths.

### columns

        reader:columns(...)
        writer:columns(...)

Define the keys of the table. The definitions may be:

1. Column numbers only. Each field is defined by a pair of numbers: the first
and last columns in the file. Records are returned with integer keys. This
format completely defines the columns.

2. Names only. Each field is identified by name. The columns will be
determined when the header is read. This column definition is incomplete.

3. Names and numbers. Each field is identified by name and the start and end
columns in the file. This format completely defines the columns.

A field name will be used as the key in the output table. Any character that
is printable is allowed in the field name, including spaces. Spaces at the
beginning or end of the name will not be included in the key.

All defined fields must be present in each record. When reading by name,
optional or unknown fields are allowed. Add a `"?"` to the end of a field name
to make it optional. That field will be included if it is found in the header,
or skipped if not. If you need to read a field that ends with `"?"` then add a
space character after the question mark. A field name that is just `"?"`
indicates that unknown fields should be returned. 

The use of optional or unknown fields makes the column definitions incomplete.
The header must be read. By default, a newly opened file will read all fields
in the header. This is the same as if you called `reader:columns("?")`.

### header (reading)

        reader:header([skip] [,columnname])

Read the existing header from a file and set the column definitions from it.
The function may be called with either, both, or neither argument.

The `skip` argument is the number of lines at the beginning of the file that
will be ignored. These lines will be returned as a list of values.

The `columnname` argument is a field name that must be in the file header.
Lines from the file (after those ignored) will be read until this string
is found. The found line will then be used to determine the names and column
widths of fields in the file. The function will return an error message if
the header can't be found.

It is neccessary to call this function if the columns are not completely
defined by the `columns` function. If the columns were defined by number only,
then the `columnname` argument will be used to locate the header, but the
header will not be parsed as the programmed columns will be assumed correct.
If any names were given in the call to `columns`, then the `columnname`
argument will be ignored. The `header` function will then search for the
defined field names and fail if not all non-optional names are in the file.

This form of the `header` function should also be used when appending to
a file.

### header (writing)
        writer:header(...)

Write the header with optional lines. This function writes a line with the
defined field names at the appropriate column widths. The fields must have
been completely defined by a call to `columns`. The arguments to this
function are lines that will be written before the header. You do not need
to include newline characters, they will be added automatically.

### rows

        reader:rows([expand])

Returns an iterator for reading rows from the file. Each record will be
returned as a table with the defined keys. If the `expand` argument is given,
then the iterator function will return the fields as individual values.

### read

        reader:read([what] [,expand])

Read records from the file. The `what` argument is either `"row"` to read one
record, or `"all"` to read the entire file. A single record will be returned
as a table with the defined keys, or if `expand` is true as a list of values.
Reading multiple records will return a table of tables and the `expand`
argument is ignored.

Optional fields that are missing from the file will be `nil` in the returned
table. When returning the values without a table, missing fields will be an
empty string.

### readinto

        reader:readinto(destination [,expand])

Read a record and pass the result to `destination` which can be a table or
function. If a table, the fields will be stored as keys by the field name.
If the destination is a function, then a table of fields will be passed
as the argument. If `expand` is true, then the fields will be passed to the
function as individual arguments. The return value of `readinto` is the
`destination` table or the return value from the function.

### write

        writer:write(...)

Write a row to the file with the passed values as fields. The arguments must
be strings or numbers. A single table may be passed to read the fields from
the keys of the table.
