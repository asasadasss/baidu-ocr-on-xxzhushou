-- 模拟位运算
-- @author 卡其色
-- @since  2018.10.01

bit = {
    data32 = {},
    data64 = {}
}

for i = 1, 32 do
    bit.data32[i] = 2 ^ (32 - i)
    bit.data64[i] = 2 ^ (64 - i)
end
 
function bit:d2b(arg)
    local tr = {}

    if arg > self.data64[32] then
        for i = 1, 32 do
            if arg >= self.data64[i] then
                arg = arg - self.data64[i]
                if arg < self.data64[32] then break end
            end
        end
    end

    for i = 1, 32 do
        if arg >= self.data32[i] then
            arg = arg - self.data32[i]
            tr[i] = 1
        else
            tr[i] = 0
        end
    end

    return tr
end

function bit:b2d(arg)
    local nr = 0
    for i = 1, 32 do
        if arg[i] == 1 then
            nr = nr + 2 ^ (32 - i)
        end
    end
    return nr
end

function bit:to32(arg)
    if arg >= self.data64[32] then
        for i = 1, 32 do
            if arg >= self.data64[i] then
                arg = arg - self.data64[i]
                if arg < self.data64[32] then break end
            end
        end
    end

    return arg
end

function bit:to8(arg)
    if arg >= self.data64[32] then
        for i = 1, 32 do
            if arg >= self.data64[i] then
                arg = arg - self.data64[i]
                if arg < self.data64[32] then break end
            end
        end
    end

    if arg >= self.data32[24] then
        for i = 1, 24 do
            if arg >= self.data32[i] then
                arg = arg - self.data32[i]
                if arg < self.data32[24] then break end
            end
        end
    end

    return arg
end

function bit:to4(arg)
    if arg >= self.data64[32] then
        for i = 1, 32 do
            if arg >= self.data64[i] then
                arg = arg - self.data64[i]
                if arg < self.data64[32] then break end
            end
        end
    end

    if arg >= self.data32[28] then
        for i = 1, 28 do
            if arg >= self.data32[i] then
                arg = arg - self.data32[i]
                if arg < self.data32[28] then break end
            end
        end
    end

    return arg
end

-- 异或
function bit:_xor(a,b)
    local op1 = self:d2b(a)
    local op2 = self:d2b(b)
    local r = {}
 
    for i = 1, 32 do
        if op1[i] == op2[i] then
            r[i] = 0
        else
            r[i] = 1
        end
    end
    return self:b2d(r)
end

-- 与
function bit:_and(a,b)
    local op1 = self:d2b(a)
    local op2 = self:d2b(b)
    local r = {}
    
    for i = 1, 32 do
        if op1[i] == 1 and op2[i] == 1 then
            r[i] = 1
        else
            r[i] = 0
        end
    end
    return self:b2d(r)
end

-- 或
function bit:_or(a,b)
    local op1 = self:d2b(a)
    local op2 = self:d2b(b)
    local r = {}
    
    for i = 1, 32 do
        if op1[i] == 1 or op2[i] == 1 then
            r[i] = 1
        else
            r[i] = 0
        end
    end

    return self:b2d(r)
end

-- 或 连续4次
function bit:_or4(a,b,c,d)
    local op1 = self:d2b(a)
    local op2 = self:d2b(b)
    local op3 = self:d2b(c)
    local op4 = self:d2b(d)
    local r = {}
    
    for i = 1, 32 do
        if op1[i] == 1 or op2[i] == 1 or op3[i] == 1 or op4[i] == 1 then
            r[i] = 1
        else
            r[i] = 0
        end
    end
    return self:b2d(r)
end

-- 左移
function bit:_lshift(a, n)
    return a * (self.data32[32 - n])
end
 
-- 右移
function bit:_rshift(a, n)
    return math.floor(a / (self.data32[32 - n]))
end





-- 以下为针对性优化
function bit:b_xor(a,b)
    local op1 = a
    local op2 = b
    local r = {}
 
    for i = 1, 32 do
        if op1[i] == op2[i] then
            r[i] = 0
        else
            r[i] = 1
        end
    end
    return self:b2d(r)
end
function bit:_xor_b(a,b)
    local op1 = self:d2b(a)
    local op2 = self:d2b(b)
    local r = {}
 
    for i = 1, 32 do
        if op1[i] == op2[i] then
            r[i] = 0
        else
            r[i] = 1
        end
    end
    return r
end
function bit:b_xor_b(a,b)
    local op1 = a
    local op2 = b
    local r = {}
 
    for i = 1, 32 do
        if op1[i] == op2[i] then
            r[i] = 0
        else
            r[i] = 1
        end
    end
    return r
end
function bit:b1_xor_b(a,b)
    local op1 = a
    local op2 = self:d2b(b)
    local r = {}
 
    for i = 1, 32 do
        if op1[i] == op2[i] then
            r[i] = 0
        else
            r[i] = 1
        end
    end
    return r
end
function bit:_or_b(a,b)
    local op1 = self:d2b(a)
    local op2 = self:d2b(b)
    local r = {}
    
    for i = 1, 32 do
        if op1[i] == 1 or op2[i] == 1 then
            r[i] = 1
        else
            r[i] = 0
        end
    end

    return r
end
function bit:b2_and_b(a,b)
    local op1 = self:d2b(a)
    local op2 = b
    local r = {}
    
    for i = 1, 32 do
        if op1[i] == 1 and op2[i] == 1 then
            r[i] = 1
        else
            r[i] = 0
        end
    end
    return r
end
function bit:b2_xor(a,b)
    local op1 = self:d2b(a)
    local op2 = b
    local r = {}
 
    for i = 1, 32 do
        if op1[i] == op2[i] then
            r[i] = 0
        else
            r[i] = 1
        end
    end
    return self:b2d(r)
end
function bit:_and_b(a,b)
    local op1 = self:d2b(a)
    local op2 = self:d2b(b)
    local r = {}
    
    for i = 1, 32 do
        if op1[i] == 1 and op2[i] == 1 then
            r[i] = 1
        else
            r[i] = 0
        end
    end
    return r
end