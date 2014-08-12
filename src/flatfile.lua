
--[====[ helper functions ]====]

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


--[====[ module contents ]====]

local flatfile = {}
local reader = {}
local writer = {}

--- Open a file to read or write table data from fixed-length records.
--  
--  @param  source  string|file
--  @param  mode    string
--  @return object
function flatfile.open(source, mode)
    if mode then
        mode = string.sub(mode, 1, 1)
        if mode ~= 'r' and mode ~= 'w' and mode ~= 'a' then
            return nil, "invalid mode"
        end
    else
        mode = 'r'
    end
    if type(source) == 'string' then
        local iomode, errmsg, errnum
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
        local typ = io.type(source) or type(source)
        if typ ~= 'file' then
            return nil, "cannot open file from type `"..typ.."'"
        end
    end

    local meta
    if mode == 'r' then
        meta = reader
    else
        meta = writer
    end
    return setmetatable({source=source, mode=mode, columns={}}, meta)
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
    local skipped = {}
    for i = 1,skip do
        skipped[i] = self.source:read()
    end
end

--- Write a header.
--  
--  @param  string...
--  @return number
function writer:header(...)
    if self.mode == 'a' then
        return
    end
    return writelines(self.source, 0, ...)
end

--- Read one line as a list of values.
--  
--  @return string...
local function readrowexpand(self)
end

--- Read one line as a table.
--  
--  @param  dest    table (optional)
--  @return table
local function readrowtable(self, dest)
    dest = dest or {}
    return dest
end

local function _readrowtable(self)
    return readrowtable(self)
end

--- Iterator interface to reading lines from the file.
--  
--  @param  expand  boolean (optional)
--  @return function|object
function reader:rows(expand)
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
    if what == 'r' then
        if expand then
            return readrowexpand(self)
        else
            return readrowtable(self)
        end
    elseif what == 'a' then
        local all = {}
        local row, errmsg, errnum = readrowtable(self)
        while row do
            all[#all+1] = row
            row = readrowtable(self)
        end
        if errmsg then
            return nil, errmsg, errnum
        end
        return all
    else
        return nil, "invalid option"
    end
end

--- Read a line and store the results in a table.
--  
--  @param  destination table|function
--  @param  expand      boolean (optional)
--  @return table|...
function reader:readinto(destination, expand)
    if type(destination) == 'function' then
        if expand then
            return destination(assert(readrowexpand(self)))
        else
            return destination(assert(readrowtable(self)))
        end
    else
        return readrowtable(self, destination)
    end
end

--- Write a line to the file.
--  
--  @param  string...
--  @return number
function writer:write(...)
end

-- DELETME not needed, just call write(object)
--function writer:writefrom(object)
--end

return flatfile
