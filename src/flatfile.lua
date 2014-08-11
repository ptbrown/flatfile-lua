
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

--[[ Open a file to read or write table data from fixed-length records.

    @arg    source  string|file
    @arg    mode    string
    @return object
  ]]
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

local function definecolumns(self, ...)
end

reader.columns = definecolumns
writer.columns = definecolumns

function reader:header(skip, columnname)
end

function writer:header(...)
    if self.mode == 'a' then
        return
    end
    return writelines(self.source, 0, ...)
end

local function readrowexpand(self)
end

local function readrowtable(self)
end

function reader:rows(expand)
    if expand then
        return readrowexpand, self
    else
        return readrowtable, self
    end
end

function reader:read(what, expand)
    if expand == nil then
        if type(what) == 'boolean' then
            what,expand = 'r', what
        end
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

function reader:readinto(destination, expand)
end

function writer:write(...)
end

-- DELETME not needed, just call write(object)
--function writer:writefrom(object)
--end

return flatfile
