-- 百度云认证模块
-- @author 卡其色
-- @since  2018.10.01

require('ocr.HMAC-SHA256')

-- 请填写 AK, SK
local accessKeyId     = 'd4739dthisisafakeaksdfn54e4291a2'
local secretAccessKey = 'f48790thisisafakeskb89csdf103aa0'

local BCE_AUTH_VERSION = "bce-auth-v1"
local BCE_PREFIX       = 'x-bce-'
local defaultHeadersToSign = {
    "host"
}

local function IsInTable(value, tbl)
	for k,v in pairs(tbl) do
		if v == value then
			return true
		end
	end
	return false
end

function table.keys(t)
    local keys = {}
    for k, _ in pairs(t) do
        keys[#keys + 1] = k
    end
    return keys
end

local function trim(s)
	local s = tostring(s)
	return (s:gsub("^%s*(.-)%s*", "%1"))
end

local function urlEncode(s)
    -- 以下4个字符不编码
    local except = {'-', '.', '_', '~'}
    s = string.gsub(s, "([^%w%.%- ])", function(c)
        if IsInTable(c, except) then return c end
        return string.format("%%%02X", string.byte(c))
    end)
    return (string.gsub(s, " ", "+"))
end

local function urlEncodeExceptSlash(s)
    return (string.gsub(urlEncode(s), '%%2F', "/"))
end

-- 生成标准化QueryString
local function getCanonicalQueryString(parameters)
    -- 没有参数，直接返回空串
    if not parameters then
        return ''
    end

    local parameterStrings = {}
    for k, v in pairs(parameters) do
        -- 跳过Authorization字段
    	if string.find(k, 'Authorization') == nil then
        	if v then
                -- 对于有值的，编码后放在=号两边
                table.insert(parameterStrings, urlEncode(k) .. '=' .. urlEncode(v))
            else
                -- 对于没有值的，只将key编码后放在=号的左边，右边留空
                table.insert(parameterStrings, urlEncode(k) .. '=')
            end
        end
    end

    -- 按照字典序排序
    table.sort(parameterStrings)

    -- 使用'&'符号连接它们
    return table.concat(parameterStrings, '&')
end

local function isDefaultHeaderToSign(header)
    header = string.lower(trim(header))

    if IsInTable(header, defaultHeadersToSign) then
        return true
    end

    local prefix = string.sub(header, 1, string.len(BCE_PREFIX))
    if prefix == BCE_PREFIX then
        return true
    else
        return false
    end
end

local function getHeadersToSign(headers)
    ret = {}

    for k, v in pairs(headers) do
        if string.len(trim(v)) > 0 then
            if isDefaultHeaderToSign(k) then
                ret[k] = v
            end
        end
    end
    return ret
end

-- 生成标准化http请求头串
local function getCanonicalHeaders(headers)
    -- 如果没有headers，则返回空串
    if not headers then
        return ''
    end

    local headerStrings = {}
    for k, v in pairs(headers) do
        -- 跳过key为nil的
        if k ~= nil then
	        -- 如果value为nil，则赋值为空串
	        if v == nil then
	            v = ''
	        end
	        -- trim后再encode，之后使用':'号连接起来
	        table.insert(headerStrings, urlEncode(string.lower(trim(k))) .. ':' .. urlEncode(trim(v)))
        end
    end

    -- 字典序排序
    table.sort(headerStrings)

    -- 用'\n'把它们连接起来
    return table.concat(headerStrings, "\n")
end

function sign(httpMethod, path, headers, params)
    -- 有效时间
    local expirationInSeconds = 1800

    local timestamp            = os.date("!%Y-%m-%dT%H:%M:%SZ")
    local authString           = BCE_AUTH_VERSION .. '/' .. accessKeyId .. '/' .. timestamp .. '/' .. expirationInSeconds
    local signingKey           = HMAC_SHA256_MAC(secretAccessKey, authString)
    local canonicalURI         = urlEncodeExceptSlash(path)
    local canonicalQueryString = getCanonicalQueryString(params);
    local headersToSign        = getHeadersToSign(headers)
    local canonicalHeader      = getCanonicalHeaders(headersToSign)

    headersToSign = table.keys(headersToSign)
    table.sort(headersToSign)

    -- 整理headersToSign，以';'号连接
    local signedHeaders = string.lower((table.concat(headersToSign, ';')))

    -- 组成标准请求串
    local canonicalRequest = httpMethod .. "\n" .. canonicalURI .. "\n" .. canonicalQueryString .. "\n" .. canonicalHeader
    local signature = HMAC_SHA256_MAC(signingKey, canonicalRequest)
    local authorizationHeader = authString .. '/' .. signedHeaders .. '/' .. signature

    return authorizationHeader
end