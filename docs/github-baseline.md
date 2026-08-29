# GitHub 基线审查

主候选：`Fanqi-dev/tia-v20-unified-mcp`；功能补充候选：`chewcw/tia-portal-openness-mcpserver`

主服务来源：<https://github.com/chewcw/tia-portal-openness-mcpserver>
事务参考：<https://github.com/Fanqi-dev/tia-v20-unified-mcp>

## 选择理由

- 明确针对 TIA Portal V20，不把 V21 DLL 布局混入默认路线。
- 独立 .NET Framework 4.8 MCP stdio 服务。
- 已有 XML 快照、工程树、PLC/块/类型/标签、SCL 外部源、编译、回滚和安全事务结构。
- 支持 XML、SCL 和结构化 LAD 方向，覆盖面明显大于当前 PowerShell 探针。
- 仓库明确禁止交付 Siemens 安装文件、Openness DLL 和本地工程资产，适合做“检测用户已有博图”的安装器。

## 横向比较

`chewcw/tia-portal-openness-mcpserver`（[GitHub](https://github.com/chewcw/tia-portal-openness-mcpserver)）本机也能构建，并通过标准 MCP Client 发现 73 个工具，覆盖工程、设备、块、SCL、标签、HMI、文件和会话管理；它的若干工具带 `Destructive`/`ReadOnly` 标记，适合作为功能覆盖参考。

发布主服务现采用 `chewcw/tia-portal-openness-mcpserver`，因为它在 V20 上有更完整的标签/HMI/设备/会话工具表（73 个）。`Fanqi-dev/tia-v20-unified-mcp` 保留为 V20 XML 事务、回滚和文档边界参考，不直接混合两套服务进同一安装包。

两套候选当前都不应被宣传为完整在线调试工具：本机列出的工具中没有成熟的 PLC 下载、GoOnline 或在线变量读写接口。Online/Download 需要另做 V20 适配层，并以 PLCSIM 实例完成验证后才能开放。

## 本机证据

在 `vendor/chewcw-tia-mcp` 中执行：

```powershell
dotnet restore .\server\TiaMcpServer.csproj --ignore-failed-sources
dotnet build .\server\TiaMcpServer.csproj --no-restore -c Release
dotnet restore .\tests\TiaMcpServer.Unit\TiaMcpServer.Unit.csproj --ignore-failed-sources
dotnet test .\tests\TiaMcpServer.Unit\TiaMcpServer.Unit.csproj --no-restore -c Release
```

结果：

- V20 服务构建成功，0 warning / 0 error。
- 离线单元测试通过 2/2。
- 本机 V20 Openness 程序集由 `E:\simense\Portal V20\PublicAPI\V20` 解析。
- 使用标准 MCP Client 连接发布构建成功，发现 40 个工具。
- 只读 `GetState` 调用成功，返回服务正常、当前无已连接工程。
- 尝试在 TIA 仅处于启动页时调用 `Connect`：60 秒超时；符合该仓库需要可附着的已打开工程会话的前置条件，未强行通过 GUI 打开工程。

## 集成策略

1. 将该仓库作为 V20 Openness/MCP 主基线。
2. 在其上增加 DeepSeek/OpenAI-compatible 聊天客户端。
3. 通过独立的确认层拦截写入、编译、保存、下载和在线操作。
4. 保留当前项目的 preflight、回归测试和 PLCSIM 诊断作为外层验证。
5. 不把 Siemens DLL、TIA 安装包或真实工程提交到交付仓库。

## DeepSeek 集成验证

`chat/` 下的 CLI 客户端通过标准 MCP Client 连接本基线，并将 MCP 工具转换为 DeepSeek function tools。构建/检查结果：MCP 工具发现 40 个、`npm install` 成功、依赖审计 0 漏洞、Node 语法检查通过。API Key 未配置时客户端不发送外部请求。

## 包 staging 验证

`scripts/stage-package.ps1` 已生成代理专用目录，并在 staging 后运行 `chat\npm run doctor` 成功；客户端从相对路径 `runtime\TiaPortalMcpServer.exe` 找到服务。staging 会拒绝 Siemens DLL、TIA 工程和工程归档进入交付目录。

最新 staging 已压缩为 `dist\tia-v20-agent-20260828-214944.zip`，大小约 6.6 MB；压缩包内容扫描通过，没有 `.ap20`、`.zap20`、`.s7dcl`、`.s7res` 或 Siemens Openness DLL。

最新包 `dist\tia-v20-agent-20260828-215242.zip` 已用包内外部 MCP Client 验证：runtime 服务启动成功，发现 40 个工具，`GetState` 返回成功。

最新包 `dist\tia-v20-agent-20260828-215453.zip` 增加了 `TIA_AGENT_AUTO_APPROVE` 配置开关：默认确认保持开启，用户明确设置为 `true` 才关闭；压缩包禁止专有文件扫描通过。

最新代理包 `dist\tia-v20-agent-20260828-221716.zip` 的主 MCP 为 `TiaPortalMcpServer.exe`，便携 Node doctor 成功发现 73 个工具；Online/Download helper 仍作为独立补充，实际上线/下载待 PLCSIM 目标映射后验证。

最新发布回归包：`dist\tia-v20-agent-20260828-222138.zip`。包内 doctor 发现 73 个工具，preflight 返回 `ready=true`，便携 Node、Online helper 和第三方许可证均存在。

当前主服务切换后的依赖审计通过：`npm audit --omit=dev` 返回 0 vulnerabilities；最新 runtime 包含 `TiaPortalMcpServer.exe`、MCP/Collaboration 通用依赖和 portable Node，未包含 `Siemens.Engineering*.dll`。

chewcw 主服务非集成测试通过 2/2；测试范围为工具契约/离线服务行为，不代表 TIA 工程在线连接或 PLC 下载已通过。

Online/Download 参考：`a4webdev/tiacommander-mcp`（[GitHub](https://github.com/a4webdev/tiacommander-mcp)）明确提供 `configure_connection`、`download_check`、`download_to_device`、`go_online`、`get_plc_status`、`scan_devices` 和 live-data 工具，覆盖面最接近完整目标；但其 EULA 明确禁止修改、反向工程、再分发和开发竞争产品，因此不直接打包、复制代码或逆向，仅参考其公开文档中的 V20 连接配置、确认字符串、失败分层和在线数据模型。

该方案的 EULA 已在本地审查确认；因此它不是本项目的依赖或发布来源。

进一步检索 `AnyAutomationStudio`、`feelautom/tia-copilot-genai-bridge` 和 PLCSIM 相关项目后，未发现同时满足“开源可再分发、标准 S7-PLCSIM V20、无 GUI 首次绑定、在线下载/变量控制”的现成方案。完整在线/仿真控制通常依赖 proprietary 产品或 PLCSIM Advanced；本项目不能把这些能力的存在当成可直接复用。

在当前已有 TIA Portal 启动页/多进程状态下，标准 MCP Client 调用 `projects_open` 会达到 60 秒请求超时；后续集成测试需要干净的 TIA 会话或已打开且可附着的工程。未通过终止进程或 GUI 强行绕过该前置条件。

最新发布包内的便携 `runtime\node.exe` 已直接执行 `chat\deepseek-chat.mjs --doctor`，成功发现 40 个 V20 MCP 工具并以 0 退出；未使用系统 Node，也未访问 DeepSeek。
