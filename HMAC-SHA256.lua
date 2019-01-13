-- HMAC-SHA256 运算模块
-- @author 卡其色
-- @since  2018.10.01

require("ocr.bit")

-- 数组拷贝
local function TableCopy(object)
    local NewTable = {}

    for k, v in pairs(object) do
        NewTable[k] = v
    end

    return NewTable
end

-- 数组连接
local function concat(a, b)
	for k, v in pairs(b) do
		table.insert(a,v)
	end
end

-- 字符串切割
local function split(str, reps)
    local resultStrList = {}
    string.gsub(str,'[^'..reps..']+', function ( w )
        table.insert(resultStrList, w)
    end)
    return resultStrList
end

-- 左移
local function left_nav(a, n)
	return bit:_lshift(a, n)
end

-- 左移 32位
local function left(a, n)
	return bit:to32(bit:_lshift(a, n))
end

-- 左移 8位
local function left_to8(a, n)
	return bit:to8(bit:_lshift(a, n))
end

-- 右移
local function right(a, n)
	return bit:_rshift(a, n)
end

local function SHA256_init()
	SHA256_H = {0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19}
	SHA256_buf = {}
	SHA256_len = 0
end

local function SHA256_sigma0(x)
  return bit:b_xor(bit:_or_b(right(x, 7), left_nav(x, 25)), bit:b1_xor_b(bit:_or_b(right(x, 18), left_nav(x, 14)), right(x, 3)))
end

local function SHA256_sigma1(x)
  return bit:b_xor(bit:_or_b(right(x, 17), left_nav(x, 15)), bit:b1_xor_b(bit:_or_b(right(x, 19), left_nav(x, 13)), right(x, 10)))
end

local function SHA256_Sigma0(x)
  return bit:b_xor(bit:_or_b(right(x, 2), left_nav(x, 30)), bit:b_xor_b(bit:_or_b(right(x, 13), left_nav(x, 19)), bit:_or_b(right(x, 22), left_nav(x, 10))))
end

local function SHA256_Sigma1(x)
  return bit:b_xor(bit:_or_b(right(x, 6), left_nav(x, 26)), bit:b_xor_b(bit:_or_b(right(x, 11), left_nav(x, 21)), bit:_or_b(right(x, 25), left_nav(x, 7))))
end

local function SHA256_Ch(x, y, z)
  return bit:b2_xor(z, bit:b2_and_b(x, bit:_xor_b(y, z)))
end

local function SHA256_Maj(x, y, z)
  return bit:b_xor(bit:_and_b(x, y), bit:b2_and_b(z, bit:_xor_b(x, y)))
end

local function SHA256_Hash_Word_Block(H, W)
	for i = 17, 64, 1 do
		W[i] = bit:to32((SHA256_sigma1(W[i - 2]) +  W[i - 7] + SHA256_sigma0(W[i - 15]) + W[i - 16]))
	end

	local state = TableCopy(H)

	for i = 1, 64, 1 do
		local T1 = state[8] + SHA256_Sigma1(state[5]) + SHA256_Ch(state[5], state[6], state[7]) + SHA256_K[i] + W[i]
		local T2 = SHA256_Sigma0(state[1]) + SHA256_Maj(state[1], state[2], state[3])
		table.remove(state)
		table.insert(state, 1, bit:to32((T1 + T2)))
		state[5] = bit:to32((state[5] + T1))
	end

	for i = 1, 8, 1 do
		H[i] = bit:to32((H[i] + state[i]))
	end
end

local function SHA256_Hash_Byte_Block(H, w)
	local W = {}
	for i = 1, 16, 1 do
		if type(w[4 * (i - 1) + 4]) == "string" then
			w[4 * (i - 1) + 4] = tonumber(w[4 * (i - 1) + 4])
		end

		W[i] = bit:_or4(left(w[4 * (i - 1) + 1], 24), left(w[4 * (i - 1) + 2], 16), left(w[4 * (i - 1) + 3], 8), w[4 * (i - 1) + 4])
	end
	SHA256_Hash_Word_Block(H, W);
end

local function string_to_array(str)
	local len = string.len(str)

	local res = {}
	for i = 1, len, 1 do
		res[i] = str:byte(i)
	end
	return res
end

local function SHA256_write(msg)
	if (type(msg) == "string") then
		concat(SHA256_buf, string_to_array(msg));
	else
		concat(SHA256_buf, msg);
	end

	temp = 1
	for i = 1, #SHA256_buf - 64 + 1, 64 do
		temp = temp + 64
		SHA256_Hash_Byte_Block(SHA256_H, split(table.concat(SHA256_buf, ',' ,(i - 1) + 1, (i - 1) + 64), ','))
	end
	SHA256_buf = split(table.concat(SHA256_buf, ',' ,temp), ',')
	SHA256_len = SHA256_len + #msg;
end

local function SHA256_finalize(a)
	SHA256_buf[#SHA256_buf + 1] = 0x80

	if (#SHA256_buf > 64 - 8) then
		for i = #SHA256_buf + 1, 64, 1 do
			SHA256_buf[i] = 0
		end
		SHA256_Hash_Byte_Block(SHA256_H, SHA256_buf)
		SHA256_buf = {}
	end

	for i = #SHA256_buf + 1, 64 - 5, 1 do
		SHA256_buf[i] = 0
	end

	SHA256_buf[60] = bit:to8(right(SHA256_len, 29))
	SHA256_buf[61] = bit:to8(right(SHA256_len, 21))
	SHA256_buf[62] = bit:to8(right(SHA256_len, 13))
	SHA256_buf[63] = bit:to8(right(SHA256_len, 5))
	SHA256_buf[64] = left_to8(SHA256_len, 3)
	SHA256_Hash_Byte_Block(SHA256_H, SHA256_buf)

	local res = {}
	for i = 1, 8, 1 do
		res[4 * (i - 1) + 1] = right(SHA256_H[i], 24)
		res[4 * (i - 1) + 2] = bit:to8(right(SHA256_H[i], 16))
		res[4 * (i - 1) + 3] = bit:to8(right(SHA256_H[i], 8))
		res[4 * (i - 1) + 4] = bit:to8(SHA256_H[i])
	end

	SHA256_H = nil
	SHA256_buf = nil
	SHA256_len = nil
	return res
end

local function HMAC_SHA256_finalize()
	local md = SHA256_finalize(1)

	for i = 1, 64, 1 do
		HMAC_SHA256_key[i] = bit:b2_xor(HMAC_SHA256_key[i], bit:_xor_b(0x36, 0x5c))
	end

	SHA256_init()
	SHA256_write(HMAC_SHA256_key)
	SHA256_write(md)

	HMAC_SHA256_key = nil
	return SHA256_finalize(2)
end

local function array_to_hex_string(ary)
	local res = ""
	for i = 1, #ary, 1 do
		res = res .. SHA256_hexchars[right(ary[i], 4) + 1] .. SHA256_hexchars[bit:to4(ary[i]) + 1]
	end
	return res
end

local function HMAC_SHA256_init(key)
	HMAC_SHA256_key = string_to_array(key)

	if (#HMAC_SHA256_key > 64) then
		SHA256_init();
		SHA256_write(HMAC_SHA256_key);
		HMAC_SHA256_key = SHA256_finalize();
	end

	for i = #HMAC_SHA256_key + 1, 64, 1 do
		HMAC_SHA256_key[i] = 0;
	end

	for i = 1, 64, 1 do
		HMAC_SHA256_key[i] = bit:_xor(HMAC_SHA256_key[i], 0x36);
	end
	SHA256_init();
	SHA256_write(HMAC_SHA256_key);
end

SHA256_hexchars = {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f'}

SHA256_K = {
	0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1,
	0x923f82a4, 0xab1c5ed5, 0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
	0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174, 0xe49b69c1, 0xefbe4786,
	0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
	0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147,
	0x06ca6351, 0x14292967, 0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
	0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85, 0xa2bfe8a1, 0xa81a664b,
	0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
	0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a,
	0x5b9cca4f, 0x682e6ff3, 0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
	0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
};

local function HMAC_SHA256_write(msg)
	SHA256_write(msg);
end

function HMAC_SHA256_MAC(key, msg)
	local res
	HMAC_SHA256_init(key)
	HMAC_SHA256_write(msg)
	res = HMAC_SHA256_finalize()
	return array_to_hex_string(res)
end

local function HMAC_SHA256_TEST(key, msg)
	local mac_hex = HMAC_SHA256_MAC(key, msg)
	print(mac_hex)
end