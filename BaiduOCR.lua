-- 百度云文字识别接口调用
-- @author 卡其色
-- @since  2018.10.01

require("ocr.ZZBase64")
require("ocr.BaiduAuthentication")

local bb   = require("badboy")
local json = bb.getJSON()
bb.loadluasocket()

local baiduOCR = {}

local function snapshotRead(x1, y1, x2, y2)
	local filename = '[public]ocr.png'
	snapshot(filename, x1, y1, x2, y2)
	local file = io.open(filename, 'r')
	local retbyte = file:read("*a")
	file:close()
	return retbyte
end

local function urlEncode(s)
    s = string.gsub(s, "([^%w%.%- ])", function(c)
        return string.format("%%%02X", string.byte(c))
    end)
    return (string.gsub(s, " ", "+"))
end

local function has_key(search, t)
	if type(t) ~= 'table' then return false end
    for k, v in pairs(t) do
      if k == search then
          return true
      end
    end
    return false
end

--[[ 获取区域内的文字内容
	@method getText
	@param  int x1, y1, x2, y2 顶点坐标
	@return mixed 成功返回字符串，失败返回nil
--]]
function baiduOCR.getText(x1, y1, x2, y2)
	local imgRaw    = snapshotRead(x1, y1, x2, y2)
	local imgBase64 = ZZBase64.encode(imgRaw)
	local imgData   = urlEncode(imgBase64)

	if imgData == nil or #imgData <= 0 then
		sysLog('[BaiduOCR] 读取截图数据失败')
		return nil
	end

	local host      = 'aip.baidubce.com'               -- 域名
	local path      = '/rest/2.0/ocr/v1/general_basic' -- 请求路径
	local url       = 'http://' .. host .. path        -- URL地址
	local method    = "POST"                           -- 请求方法
	local params    = {}                               -- URL参数项，除特殊情况请不要修改
	local post_data = 'image='..imgData                -- 窗体数据，请按照 key=value 的方式编码
	local headers   = {
			['host']           = host,
	        ['Content-Type']   = 'application/x-www-form-urlencoded',
	        ['Content-Length'] = #post_data,
	}

	-- 使用百度云认证方式来生成签名，需要进行2次SHA运算，根据设备性能耗时200-600毫秒不等
	headers['Authorization'] = sign(method, path, headers, params)

	local http = bb.http
	local response_body = {}
	local res, code = http.request {  
	    url     = url,
	    method  = method,
	    headers = headers,
	    source  = ltn12.source.string(post_data),
	    sink    = ltn12.sink.table(response_body)
	}

	-- 仅返回第一组数据，请根据实际需要修改
	-- 返回格式请参考官方文档：https://cloud.baidu.com/doc/OCR/OCR-API.html#.E8.BF.94.E5.9B.9E.E8.AF.B4.E6.98.8E
	if res == 1 and #response_body > 0 then
		local data = json.decode(response_body[1])
		if has_key('words_result', data) and #data['words_result'] > 0 then
			local text = data['words_result'][1]['words']
			return text
		end
	end

	-- 错误提示
	if res == 0 or #response_body == 0 or response_body[1] == nil then
		sysLog('[BaiduOCR] 网络错误')
	elseif (not has_key('words_result', json.decode(response_body[1]))) then
		sysLog('[BaiduOCR] 接口调用出错: [res]'..response_body[1])
	elseif (#json.decode(response_body[1])['words_result'] == 0) then
		sysLog('[BaiduOCR] 没有识别结果: [res]'..response_body[1])
		return ""
	end

	return nil
end

return baiduOCR