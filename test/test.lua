-- Set up paths
local testdir = "./"..arg[0]:gsub("test.lua","")
package.path = testdir.."../src/?.lua;"..package.path

-- 5.1 compatible
local unpack = table.unpack or unpack
flatfile = require("flatfile")

testfile1 = assert(io.open(testdir.."test1.txt"))
f = assert(flatfile.open(testfile1))

-- Default mode is read
assert(f.source == testfile1 and f.mode == "r")

-- Simple column definition
f:columns(1,4, 5,4, 9,4)
assert(f.fieldsdefined and #f.definition == 3)

-- Return an array
testlines1 = {}
r = assert(f:read())
assert(#r == 3)
testlines1[#testlines1+1] = r
; -- Return values
(function(...)
    assert(select('#', ...) == 3)
    testlines1[#testlines1+1] = {...}
end)(assert(f:read(true)))

-- Iterator
reader,self = assert(f:rows())
assert(self == f)
r = reader(self)
assert(#r == 3)
testlines1[#testlines1+1] = r

-- Attempts to read past end-of-file should be safe
assert(reader(self) == nil)
assert(f:read() == nil)

f = nil
collectgarbage("collect")
testfile1:seek("set")

-- File-like interface
memfile = {
    write = function(self, ...)
        self[#self+1] = table.concat{...}
        return true
    end
}
f = assert(flatfile.open(memfile, "w"))
f:columns(1,4, 5,4, 9,4)
for _,r in ipairs(testlines1) do
    assert(f:write(unpack(r)))
end
f:close()

-- Written file should be same as what was read
assert(testfile1:read("*a") == table.concat(memfile))

f = nil
memfile = nil
collectgarbage("collect")
testfile1:seek("set")

function deepcompare(t1, t2)
    if t1 == t2 then
        return true
    end
    if type(t1) == 'table' and type(t2) == 'table' then
        if #t1 == #t2 then
            local k1,v1, k2,v2
            repeat
                k1,v1 = next(t1, k1)
                k2,v2 = next(t2, k2)
                if k1 ~= k2 or not deepcompare(v1, v2) then
                    return false
                end
            until k1 == nil
            return true
        end
    end
    return false
end

-- Read entire table
f = assert(flatfile.open(testfile1))
f:columns(1,4, 5,4, 9,4)
testlines2 = assert(f:read("all"))
assert(deepcompare(testlines1, testlines2))

f = nil
testfile1 = nil
testlines1 = nil
testlines2 = nil
collectgarbage("collect")

-- Named columns
testfile2 = assert(io.open(testdir.."test2.txt"))
f = assert(flatfile.open(testfile2))
f:columns("Time", "Note", "ID")
assert(f:header(1))

r = f:read()
assert(r.Note == "abcdefghijklmnopqrst" and r.ID == "13")

f = nil
collectgarbage("collect")
testfile2:seek("set")

-- Optional names
f = assert(flatfile.open(testfile2))
f:columns("Time", "Name?", "Note", "IDCode?")
assert(f:header(1))
r = f:read()
assert(r.Time ~= nil and r.Note ~= nil and r.IDCode ~= nil and r.Name == nil)
r = f:read()
assert(r.IDCode == "123450")
r = {f:read(true)}
assert(#r == 4)
assert(r[2] == "")
r = {}
assert(f:readinto(r) == r)
assert(r.Time ~= nil and r.Note ~= nil and r.IDCode ~= nil and r.Name == nil)
assert(f:readinto(function(...)
    assert(select('#',...) == 4)
    return testdir
end, true) == testdir)

f = nil
collectgarbage("collect")
testfile2:seek("set")

-- Wildcard
f = assert(flatfile.open(testfile2))
f:columns("Time", "ID", "?")
assert(f:header(1))
r = f:read()
assert(r.Time ~= nil
   and r.Location ~=nil
   and r.IDCode ~= nil
   and r.Note ~= nil
   and r.ID ~= nil)

-- Uneven lines, make sure it doesn't read the CR

c = 1
for r in f:rows() do
    c = c + 1
    assert(string.match(r.ID, "^%d*$"), "row "..c)
end

f = nil
collectgarbage("collect")
testfile2:seek("set")

-- Header with unnamed fields
f = assert(flatfile.open(testfile2))
f:columns(4,8, 25,6)
assert(f:header(1, "Time"))
r = f:read()
assert(#r == 2)
r = f:read()
assert(r[2] == "123450")

f = nil
testfile2 = nil
collectgarbage("collect")

-- Append to file
f = assert(flatfile.open(assert(io.open(testdir.."test0.txt", "w")), "w"))
f:columns("X",1,4, "Y",5,4, "Z",9,4)
f:header("Test")
f:write("A1","B1","C1")
f = nil
collectgarbage("collect")
f = assert(flatfile.open(assert(io.open(testdir.."test0.txt", "a+")), "a"))
f:columns("X", "Y", "Z")
assert(f:header(1) == "Test")
assert(f:write("A2","B2","C2"))
f = nil
collectgarbage("collect")
f = assert(io.open(testdir.."test0.txt", "r")):read("*a")
assert(f == [[Test
X   Y   Z   
A1  B1  C1  
A2  B2  C2  
]])
os.remove(testdir.."test0.txt")
