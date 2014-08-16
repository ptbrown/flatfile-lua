local testdir = "./"..arg[0]:gsub("test.lua","")
package.path = testdir.."../src/?.lua;"..package.path

local unpack = table.unpack or unpack
flatfile = require("flatfile")

testfile1 = assert(io.open(testdir.."test1.txt"))
f = assert(flatfile.open(testfile1))
assert(f.source == testfile1 and f.mode == "r")

f:columns(1,4, 5,4, 9,4)
assert(f.fieldsdefined and #f.definition == 3)

testlines = {}
r = f:read()
assert(#r == 3)
testlines[#testlines+1] = r
;
(function(...)
    assert(select('#', ...) == 3)
    testlines[#testlines+1] = {...}
end)(f:read(true))

reader,self = f:rows()
assert(self == f)
r = reader(self)
assert(#r == 3)
testlines[#testlines+1] = r

assert(reader(self) == nil)
assert(f:read() == nil)

f = nil
collectgarbage("collect")
testfile1:seek("set")

memfile = {
    write = function(self, ...)
        self[#self+1] = table.concat{...}
    end
}
f = flatfile.open(memfile, "w")
f:columns(1,4, 5,4, 9,4)
for _,r in ipairs(testlines) do
    f:write(unpack(r))
end
f:close()

assert(testfile1:read("*a") == table.concat(memfile))
