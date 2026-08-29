# 已验证能力

验证日期：2026-08-28，TIA Portal V20。

## 环境

- Openness DLL：`E:\simense\Portal V20\PublicAPI\V20\Siemens.Engineering.dll`
- PLCSIM：`E:\simense\PLCSIM_V20`
- PLCSIM 启动入口：已验证 `S7PLCSIMV20.exe` 与 `plcsim.exe` 可启动并被状态工具发现
- PLCSIM 实例创建：通过 PLCSIM V20“从库中添加实例”创建 2 个 Standard S7-1200 实例，界面地址显示 `192.168.0.1`；未删除或停止
- 实例界面状态：两个实例均显示“未组态的 PLC”；地址存在不等于已完成 TIA 硬件配置下载
- PLCSIM 工作区持久化：已将当前测试工作区保存为 `tia-v20-agent-test`；两个实例仍保留
- Windows 用户已在 `Siemens TIA Openness` 组中。

## 工程验证

测试工程：`SelfHoldRelay.ap20`，设备为 S7-1200。

- 无界面创建 TIA Portal 实例：通过
- 打开 `.ap20`：通过
- 读取设备/PLC：通过
- 读取块 `Main`、`SelfHoldRelay`：通过
- C# Openness 编译：通过，0 错误、0 警告
- MCP JSON-RPC stdio：通过
- 未确认时拒绝编译/写入：通过
- SCL 导入并生成 `AiSelfHoldTest`：通过
- SCL 导入后编译：通过，0 错误、1 警告
- 导入前自动备份：通过
- 重新打开副本并读取新增块：通过
- 设备能力探测：PLC 软件/编译/Download/Online provider 均可用；当前 OnlineState 为空，尚未连接
- 连接配置诊断：`PLC_1` 的 `ConnectionConfiguration.IsConfigured=True`，但没有完成在线目标握手；不能据此宣称已连接 PLCSIM
- 隔离副本上线尝试：实际进入 `OnlineProvider.GoOnline()`，返回 `Changing to online mode failed`；说明仍需配置/选择具体仿真实例
- 连接对象明细：`PN/IE` 当前绑定 `Intel(R) Wi-Fi 6 AX101`，无可用地址；PLCSIM 虚拟目标未出现在该 Openness 配置中，因此上线失败原因已收敛为接口映射/目标选择
- V20 `GetAccessibleDevices()` 扫描：当前暴露 `aTrustXtun Userspace Tunnel` 与 `Intel(R) Wi-Fi 6 AX101`，两者均返回 0 个可访问设备；标准 PLCSIM 实例不通过此 DCP 扫描出现
- PLCSIM Advanced API 检测：未发现 Advanced 安装或 `Siemens.Simatic.Simulation.Runtime.Api.x64.dll`；当前环境只有标准 S7-PLCSIM V20
- MCP 连接目标读取：已返回 `PN/IE -> Intel(R) Wi-Fi 6 AX101 -> 1 X1`，未发现 `PLCSIM` PC interface；官方 Openness 示例的目标选择方式是 `PcInterfaces.Find("PLCSIM", 1)` 后查找 `TargetInterfaces`
- 产品差异说明：上述 `PLCSIM` PC interface 示例主要面向 PLCSIM Advanced；本机是标准 S7-PLCSIM V20，不能直接套用 Advanced 的实例管理 API。标准 PLCSIM 的虚拟在线连接仍需通过 TIA 的虚拟连接路径完成
- PLCSIM 启动后复查：前端监听 `127.0.0.1:8100`，底层服务监听 `127.0.0.1:8101`；这些是内部通信端口，不作为公开 REST API 使用
- DeepSeek 聊天端本地启动：首页 HTTP 200，状态接口正常，未配置 API Key 时不发起外部请求

## 尚未完成

- 实机 PLC 下载和在线变量读写
- PLCSIM 实际运行/下载闭环（实例已创建，但 TIA 目标接口尚未映射）
- HMI、LAD/FBD 原生生成
- 安装器在全新空白电脑上的验证
- C# 桥源码迁入本项目并脱离 `E:\simense` 开发目录
