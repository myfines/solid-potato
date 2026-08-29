# 产品化路线

## 已可复现

- TIA Portal V20 Openness 无界面启动。
- 兼容用户已有安装，自动发现 V20 PublicAPI。
- `.ap20` 工程打开、设备/PLC/块/标签读取。
- SCL 外部源导入、生成 FB/FC/DB/OB，并自动编译。
- 递归编译诊断，编译错误阻止保存。
- 写入/编译/导出/新建工程确认门禁。
- 写入前工程目录备份。
- MCP stdio JSON-RPC 工具服务。
- DeepSeek 聊天端和 API Key 本地配置入口。

## 下一道验证门

1. 区分标准 S7-PLCSIM V20 与 PLCSIM Advanced，再使用专用副本完成匹配产品的下载、启动、停止和状态读取闭环。
2. 在聊天端加入真正的待确认操作卡片；模型不能自行伪造确认。
3. 将 C# bridge 源码迁入本项目，使用可复现的构建脚本和运行时依赖目录。
4. 做不覆盖用户 TIA 安装的独立安装包，并在干净 Windows 环境测试。
5. 增加 S7-1500、HMI、LAD/FBD XML、在线变量读写，并按能力探测降级。

预检将核心 TIA/MCP 可用性与 PLCSIM 可用性分开：没有 PLCSIM 时仍可启动工程自动化，只有仿真相关工具降级。

已加入 `install-agent.ps1`：解压后可将代理复制到 `%LOCALAPPDATA%\TiaV20Agent\<timestamp>` 的版本化目录，不覆盖旧版本、不触碰 TIA 安装。已在隔离目标目录完成安装回归，安装后 portable Node doctor 发现 73 个工具；尚未在全新 Windows 电脑验证。

staging 还会生成 `MANIFEST.sha256.json`，记录代理包内文件的 SHA-256，便于交付后完整性核验。
安装后可运行 `scripts\verify-manifest.ps1 -PackageRoot .` 复核全部文件。

Online/Download spike 已完成：`src/TiaV20.OnlineHelper.cs` 可按 V20 DeviceItem 定位 OnlineProvider/DownloadProvider，并提供确认门禁；当前已验证 provider 状态读取，尚未在 PLCSIM 上执行下载。helper 已纳入代理包，并内置从用户 TIA V20 安装目录解析依赖的 resolver，不携带 Siemens DLL。

安全回归：helper 无参数和未带 `--confirm` 的上线请求均立即返回错误并退出，不进入 TIA 会话。

首次在线连接边界：公开的 TiaCommander 文档说明，PG/PC 到目标 PLC 的首次连接需要在 TIA Portal 的 Accessible devices 中完成一次接口选择、扫描和目标确认；之后才适合由 Openness/MCP 程序化配置和下载。我们的产品应把这一步做成一次性引导，不把 GUI 点击伪装成稳定自动化能力。

## 安全边界

当前不会自动启动真实 PLC 下载，也不会默认写在线变量。PLCSIM 目录和可执行文件存在，只能证明安装文件存在；只有下载并读取仿真状态成功，才算 PLCSIM 闭环通过。
