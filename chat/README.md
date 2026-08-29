# DeepSeek CLI 客户端

这是连接 GitHub V20 MCP 服务的最小聊天客户端。它使用标准 MCP Client，不走 GUI；写入、编译、保存、删除、上线和下载类工具在本地要求输入 `确认`。

```powershell
cd E:\vibecoding\tia-v20-agent\chat
npm install
npm run doctor
$env:DEEPSEEK_API_KEY = "你的 DeepSeek API Key"
npm start
```

也可以直接运行 `npm start`，首次启动会在终端中询问 API Key，并保存到本机 `%APPDATA%\TiaV20Agent\config.json`；不会打印 Key 内容。

可选配置：`DEEPSEEK_BASE_URL`（默认 `https://api.deepseek.com`）和 `DEEPSEEK_MODEL`（默认 `deepseek-chat`），用于 OpenAI 兼容网关或代理地址。

也可以用 `TIA_MCP_SERVER` 指定另一份已构建的 V20 MCP 服务。

默认会对工程写入、编译、保存、删除、上线和下载询问确认。熟练用户可明确设置 `$env:TIA_AGENT_AUTO_APPROVE="true"` 关闭本地确认，后果由用户自行承担。

客户端还会把本地 Online helper 暴露为 `tia_online_status`、`tia_go_online`、`tia_go_offline` 和 `tia_download`；当前默认仅允许状态读取，其他操作仍需确认。

发布包约定将 MCP 服务放在包根目录的 `runtime\TiaPortalMcpServer.exe`；服务运行时从用户本机已安装的 TIA Portal V20 解析 Openness 程序集。
发布包也可携带 `runtime\node.exe`，启动脚本会优先使用它；若未携带则回退到系统 Node.js。
