# End of chain
const EOC = 0x0F_FF_FF_FF
# Begin table flag, added for completness
const TABLE_MAGIC = 0x0F_FF_FF_F0

struct RandomAccessFile
    path::String
    filename::String
    blocksize::UInt32
    allocationtable::Array{UInt32, 1}
end

fullpath(f::RandomAccessFile) = f.path + f.filepath

function RandomAccessFile(path, size, blocksize)
    RandomAccessFile(path, Array{UInt32, 1}(undef, size), open(path))
end

function readallocationtable(fileptr, size, blocksize)
    tablesize = (div(size, blocksize) + 1) * 4
    table = Array{UInt32}(undef, tablesize)
    lindian =  read(fileptr, UInt8, tablesize)
    for c = 1:div(tablesize, 4)
        i = c * 4 + 1
        j = (c + 1) * 4 + 1
        clptr = lindian[i:j]
        table[c] = 0
        for x = 0:3
            table[c] <<= 8
            table[c] |= clptr[4-x]
        end
    end
    table
end

function createallocationtable(size, blocksize)
    tz = tablesize(size, blocksize)
    table = Array{UInt32}(undef, tz)
    table[1] = TABLE_MAGIC
    for i = 2:tz
        table[i] = 0x00_00_00_00
    end
    table
end

function writeallocationtable(f::RandomAccessFile)
    open(fullpath(f), "w") do file
        map(f.allocationtable) do e
            write(file, swapendianess(e))
        end
    end
end


tablesize(size, blocksize) = (div(size, blocksize) + 1)

function swapendianess(x)
    mask = 0xFF
    ans::UInt32 = 0x0
    for c = 0:3
        ans <<= 8
        ans |= x & mask
        x >>= 8
    end
    ans
end
