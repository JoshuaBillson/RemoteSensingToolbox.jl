function _read_bit(x, pos; bits=16)
    return UInt8.((x .<< (bits - pos)) .>> 15)
end
