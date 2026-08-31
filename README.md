# TIA V20 AI 助手

这是一个面向 TIA Portal V20 的中文 AI 工程助手。用户用自然语言描述任务，助手通过 MCP/Openness 检查工程、读取设备和程序块、生成 SCL/XML、编译并返回诊断。

## 最简单的使用方法

1. 没有 TIA 时，从 Siemens 官方入口获取 V20：[TIA Portal V20 Trial/Download](https://support.industry.siemens.com/cs/document/109963850/simatic-step-7-incl-safety-s7-plcsim-and-wincc-v20-trial-download)。
2. 解压本代理包到固定目录。
3. 双击 `install-agent.cmd`（这是最简单的安装入口；不要担心黑色窗口）。
4. 打开安装后目录里的 `TiaV20Agent.exe`。
5. 第一次运行时输入 DeepSeek API Key。
6. 直接用中文聊天。

`start-agent.cmd` 仅用于开发和故障排查，普通用户使用 EXE。

### 首次 Openness 授权（安装器自动完成）

运行 `install-agent.cmd` 时，安装器会自动检查并登记正式程序。首次安装可能只显示一次 UAC，请点击“是”；以后同一安装目录和同一版本不会重复询问。通常不需要手动执行 PowerShell。若自动登记失败，再在管理员 PowerShell 中运行：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\setup-openness-firewall.ps1 -Apply
```

不要每次重新解压到新目录或直接运行开发目录中的 `tia-agent-bridge.exe`；路径、文件时间或 SHA256 变化会被 TIA 识别为新应用并再次询问。

## 可以怎么说

```text
检查当前工程有哪些 PLC、程序块和标签表。
打开 E:\Projects\Pump\Pump.ap20，列出 CPU 和所有程序块。
给 CPU_1 增加一个电机启停 SCL 功能块，先备份，生成后编译并报告错误。
把 SelfHoldRelay 导出成 XML，保存到 D:\TIA-Exports。
```

## API Key 和模型

首次启动会在本地输入 API Key，并保存到 `%APPDATA%\TiaV20Agent\config.json`。也支持 `DEEPSEEK_API_KEY`、`DEEPSEEK_BASE_URL` 和 `DEEPSEEK_MODEL` 环境变量，兼容 OpenAI 格式网关。

打开 EXE 后，右侧“实时进度”面板中的“模型”输入框可以直接改模型并点击“保存模型”；例如 `deepseek-chat` 或服务商实际提供的模型名，保存后立即对后续对话生效。

## 安全确认

修改、创建、删除、导入、编译、保存、上线、下线和下载都会先询问确认。熟练用户可以明确设置 `$env:TIA_AGENT_AUTO_APPROVE="true"` 关闭确认，新手不要关闭。

## 环境问题

检查环境：

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\scripts\preflight-v20.ps1
```

自动安装代理依赖并构建服务：

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\scripts\setup-environment.ps1
```

需要修复 Openness 用户组时，用管理员 PowerShell 加 `-RepairUserGroup`；加入后注销并重新登录 Windows。

安装/修复过程会按阶段显示 `[1/5]` 到 `[5/5]`，遇到重启、管理员权限、许可证或安装源问题会停下来明确提示。日常 `TiaV20Agent.exe` 不需要管理员权限；若每次弹 UAC，请取消快捷方式属性中的“以管理员身份运行此程序”。

## TIA/PLCSIM 首次连接

日常操作不依赖 GUI。第一次使用真实 PLC 或标准 PLCSIM 时，TIA 需要初始化一次 PG/PC 或虚拟连接路径，请阅读：[首次连接说明](docs/first-connection.md)。之后由 MCP/Openness 完成工程操作。

标准 PLCSIM 的实例级自动创建/绑定能力有限；助手会自动寻找 PLCSIM/virtual/softbus 连接路径，找不到时停止并提示，不会擅自把 Wi‑Fi 网卡当作仿真目标。PLCSIM Advanced 更适合完全程序化仿真。

## 安装安全

- 不覆盖已有 TIA Portal，代理安装到版本化用户目录。
- TIA/PLCSIM 安装源只从 Siemens 官方入口获取。
- 不代填账号、密码或许可证密钥，不破解许可证。
- 公开代理包不包含 Siemens 安装包、Openness DLL 或用户工程。
- 安装失败不会删除旧版本。

## 文档

- [新手完整教程](docs/BEGINNER-GUIDE.md)
- [用户安装与使用说明](docs/USER-INSTALL-GUIDE.md)
- [自动安装设计](docs/AUTO-INSTALL-DESIGN.md)
- [首次连接说明](docs/first-connection.md)
- [需求验收矩阵](docs/requirements-matrix.md)
- [验证记录](docs/validation.md)
- [路线图](docs/roadmap.md)

## 当前边界

工程读写、SCL/XML、标签/HMI、编译、备份、确认门、DeepSeek、安装器和预检已经具备。标准 PLCSIM 首次目标绑定、真实下载/运行和在线变量闭环仍需在匹配环境中继续验证。
