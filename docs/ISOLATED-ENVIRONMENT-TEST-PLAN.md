# 隔离环境验收方案

## 目的

验证用户从空白 Windows 环境解压、安装、配置 API Key，到通过浏览器创建 TIA V20 工程的完整路径；另外单独验证标准 PLCSIM 的离线编译、在线握手、下载和运行闭环。

## 全新 Windows 验收

使用没有 TIA Portal、Node.js、旧 Agent、旧 MCP 和旧配置的 Windows 10/11 虚拟机快照。安装顺序：

1. 安装 Siemens TIA Portal V20 及需要的标准 PLCSIM 组件。
2. 确认用户加入 `Siemens TIA Openness` 组，并重新登录 Windows。
3. 解压用户 ZIP 到固定目录，运行 `install-agent.cmd`。
4. 只接受首次白名单登记的一次 UAC；安装完成后重复启动不应再次申请。
5. 运行 `preflight-v20.ps1`，保存 JSON 结果。
6. 启动 `TiaV20Agent.exe`，在浏览器填写用户自己的 DeepSeek API Key。
7. 开启无限模式后提交电机示例任务，核对工程 `.ap20`、备份、SCL、LAD 和编译诊断。

通过标准：没有手动安装 Node.js，没有复制 DLL，没有打开第二个 Agent；工程路径、备份路径和程序块必须在磁盘上真实存在。

## 标准 PLCSIM 闭环验收

标准 PLCSIM 实例的显示地址不能单独证明已连接。必须同时获得：

- TIA 项目的实际在线目标接口；
- Openness `OnlineProvider.GoOnline()` 成功；
- DownloadProvider 下载成功；
- 在线读取或写入一个测试变量成功；
- 断开上线后工程仍能离线重新打开并编译。

如果 `GetAccessibleDevices()` 返回空集合，必须记录网卡、接口类型和 PLCSIM 版本，停止在线步骤并报告环境边界；禁止把启动 PLCSIM、端口监听或 `192.168.0.1` 当作握手成功。

## 不允许的替代验证

- 不用后台直接生成工程文件替代浏览器对话流程。
- 不用强杀 TIA 或 MCP 进程制造“任务完成”。
- 不下载到真实 PLC，不把在线失败改写成成功。
- 不把旧工程、旧包或旧端口的结果当作当前包结果。
