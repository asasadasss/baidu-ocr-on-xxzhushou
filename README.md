2019.01.13 更新 v1.4：
  1. 优化部分计算代码，小幅提升性能；
  2. 优化代码逻辑，增加了错误提示；
  3. 完善一些不合理的地方。
2019.01.10 更新 v1.3：
  1. 修复了一个可能导致崩溃的问题。 感谢 @人鱼情未了 测试及提供修复思路
2018.11.26 更新 v1.2：
  1. 深度优化HMAC编码逻辑，速度提升50%。
2018.11.21 更新 v1.1：
  1. 优化代码逻辑；
  2. 优化位运算库，速度提升500%。
2018.11.20 发布 v1.0：
  1. 经过测试，可以稳定运行。


特性：
  1. 针对叉叉引擎1.X制作，在1.9.2版本上测试可用
  2. 客户端直接请求API，无需服务器中转
  3. 使用HTTP连接，不需要HTTPS

依赖模块：
  1. badboy  https://github.com/boyliang/lua_badboy

使用说明：
  1. 解压后将ocr目录置于src目录，打开BaiduAuthentication.lua并填写你的AK、SK（注意：AK指的是Access Key，不是API Key！）。AK/SK获取位置：管理控制台——右上角头像——安全认证；
  2. 默认只返回识别结果的第一项，有需要可修改baiduOCR模块的getText方法。
  3. 如对接口调用与返回值有任何疑问，请参考官方文档：https://cloud.baidu.com/doc/OCR/OCR-API.html#.E8.BF.94.E5.9B.9E.E8.AF.B4.E6.98.8E

使用示例：
```
init("0", 1)
local ocr = require("ocr.BaiduOCR")
text = ocr.getText(300, 200, 700, 600) -- 成功时返回识别文字，失败返回nil
```