local testdir = "./"..arg[0]:gsub("test.lua","")
package.path = testdir.."../src/?.lua;"..package.path

local unpack = table.unpack or unpack
flatfile = require("flatfile")

testfile1 = assert(io.open(testdir.."test1.txt"))
f = assert(flatfile.open(testfile1))
assert(f.source == testfile1 and f.mode == "r")

f:columns(1,4, 5,4, 9,4)
assert(f.fieldsdefined and #f.definition == 3)

testlines1 = {}
r = assert(f:read())
assert(#r == 3)
testlines1[#testlines1+1] = r
;
(function(...)
    assert(select('#', ...) == 3)
    testlines1[#testlines1+1] = {...}
end)(assert(f:read(true)))

reader,self = assert(f:rows())
assert(self == f)
r = reader(self)
assert(#r == 3)
testlines1[#testlines1+1] = r

assert(reader(self) == nil)
assert(f:read() == nil)

f = nil
collectgarbage("collect")
testfile1:seek("set")

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

f = assert(flatfile.open(testfile1))
f:columns(1,4, 5,4, 9,4)
testlines2 = assert(f:read("all"))
assert(deepcompare(testlines1, testlines2))

f = nil
testfile1 = nil
testlines1 = nil
testlines2 = nil
collectgarbage("collect")
