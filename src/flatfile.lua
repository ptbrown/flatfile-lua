
--[====[ helper functions ]====]

-- Outputs arbitrary lines. Returns the number of lines written.
local function writelines(file, count, line, ...)
    if not line then
        return count
    end
    local ok, errmsg, errnum = file:write(line, "\n")
    if not ok then
        return nil, errmsg, errnum
    end
    return writelines(file, count+1, ...)
end

-- Raise an error on bad arguments, but with a level parameter.
local function libraryassert(level, ...)
    local success, errmsg = ...
    if not success then
        error(errmsg, level+1)
    end
    return ...
end


--[====[ module contents ]====]

-- Object function tables.
local flatfile = {}
local reader = {}
local writer = {}

--- Closes the file handle.
local function closeflatfile(self)
    self.source = nil
end

reader.close = closeflatfile
write.close = closeflatfile

--- Open a file to read or write table data from fixed-length records.
--  
--  @param  source  string|file
--  @param  mode    string
--  @return object
function flatfile.open(source, mode)
    -- Sanitize the mode string.
    if mode then
        mode = string.sub(mode, 1, 1)
        if mode ~= 'r' and mode ~= 'w' and mode ~= 'a' then
            return nil, "invalid mode"
        end
    else
        mode = 'r'
    end
    -- Open the file if a name is given.
    if type(source) == 'string' then
        local iomode, errmsg, errnum
        -- Append files need to read the header.
        if mode == 'a' then
            iomode = 'a+'
        else
            iomode = mode
        end
        source, errmsg, errnum = io.open(source, iomode)
        if not source then
            return nil, errmsg, errnum
        end
    else
        -- Just check for the needed function.
        local typ = io.type(source) or type(source)
        --if typ ~= 'file' then
        if ((mode == 'w' or mode == 'a') and not source.write)
        or ((mode == 'r' or mode == 'a') and not source.read)
            return nil, "cannot open file from type `"..typ.."'"
        end
    end

    local meta
    if mode == 'r' then
        meta = reader
    else
        meta = writer
    end
    return setmetatable({
        source=source,
        mode=mode,
        columns={},
        fieldsdefined=false,
        extrafields=true,
    }, meta)
end

--- Define the names of columns.
--  
--  1. A list of numbers: start1, end1, start2, end2, ...
--  2. A list of names: field1, field2, ...
--  3. A list of names and numbers: field1, start1, end1, ...
local function definecolumns(self, ...)
end

reader.columns = definecolumns
writer.columns = definecolumns

--- Read the header lines.
--  
--  @param  skip        number (optional)
--  @param  columnname  string (optional)
--  @return string...
function reader:header(skip, columnname)
    if columnname == nil and type(skip) == 'string' then
        columnname,skip = skip,0
    elseif skip == nil then
        skip = 0
    end
    -- Save the skipped lines to be returned later.
    local skipped = {}
    for i = 1,skip do
        skipped[i] = self.source:read()
    end
    -- Read until a header line is found. These lines are discarded.
    -- Are there files with arbitrary header lines that need to be read?
    -- I think most would have a fixed prologue.
    -- FIXME TODO
end

--- Write a header.
--  
--  @param  string...
function writer:header(...)
    if self.mode == 'a' then
        -- FIXME should call reader:header
        return
    end
    if not self.fieldsdefined then
        error("cannot write to file before columns are defined", 2)
    end
    writelines(self.source, 0, ...)
    -- FIXME TODO
end

--- Read one line as a list of values.
--  
--  @return string...
local function readrowexpand(self)
    local line, errmsg, errnum = self.source:read()
    -- FIXME TODO
end

--- Read one line as a table.
--  
--  @param  dest    table (optional)
--  @return table
local function readrowtable(self, dest)
    dest = dest or {}
    local line, errmsg, errnum = self.source:read()
    -- FIXME TODO
    return dest
end

-- Shim to call readrowtable without extra arguments.
local function _readrowtable(self)
    return readrowtable(self)
end

--- Iterator interface to reading lines from the file.
--  
--  @param  expand  boolean (optional)
--  @return function|object
function reader:rows(expand)
    if not self.fieldsdefined then
        error("cannot read from file before columns are defined", 2)
    end
    if expand then
        return readrowexpand, self
    else
        return _readrowtable, self
    end
end

--- Read one or more lines from the file.
--  
--  @param  what    string (optional)
--  @param  expand  boolean (optional)
--  @return table|string...
function reader:read(what, expand)
    if expand == nil and type(what) == 'boolean' then
        expand,what = what, 'r'
    end
    what = what and strsub(what, 1, 1) or 'r'
    -- The check of fieldsdefined is moved down so a bad argument
    -- will emit an error first.
    if what == 'r' then
        if not self.fieldsdefined then
            error("cannot read from file before columns are defined", 2)
        end
        -- Read one line.
        if expand then
            return readrowexpand(self)
        else
            return readrowtable(self)
        end
    elseif what == 'a' then
        if not self.fieldsdefined then
            error("cannot read from file before columns are defined", 2)
        end
        -- Collect all lines into a table.
        local all = {}
        local row, errmsg, errnum = readrowtable(self)
        while row do
            all[#all+1] = row
            row, errmsg, errnum = readrowtable(self)
        end
        if errmsg then
            return nil, errmsg, errnum
        end
        return all
    else
        return error("invalid option", 2)
    end
end

--- Read a line and store the results in a table.
--  
--  @param  destination table|function
--  @param  expand      boolean (optional)
--  @return table|...
function reader:readinto(destination, expand)
    if not self.fieldsdefined then
        error("cannot read from file before columns are defined", 2)
    end
    -- The expand option only makes sense when calling a function.
    if type(destination) == 'function' then
        if expand then
            return destination(libraryassert(2, readrowexpand(self)))
        else
            return destination(libraryassert(2, readrowtable(self)))
        end
    else
        return libraryassert(2, readrowtable(self, destination))
    end
end

--- Write a line to the file.
--  
--  @param  string...
--  @return number
function writer:write(...)
    if not self.fieldsdefined then
        error("cannot write to file before columns are defined", 2)
    end
end

-- DELETME not needed, just call write(object)
--function writer:writefrom(object)
--end

return flatfile