# TIA V20 AI 助手：新手操作教程

这套工具的目标是：你不需要学习 TIA Portal 的菜单和工程结构，只需要告诉 AI 你想做什么。

## 一、你需要准备什么

至少需要：

- Windows 10/11，64 位
- TIA Portal V20
- TIA Portal Openness 组件
- 当前 Windows 用户属于 `Siemens TIA Openness` 用户组

如果要使用仿真，还需要：

- 标准 S7-PLCSIM V20，或
- PLCSIM Advanced（适合完全程序化的仿真测试）

工具包不会携带或替换 Siemens 软件。它会自动检测你电脑上已有的 TIA V20。

## 官方安装源

如果电脑没有 TIA V20，请使用 Siemens 官方 Industry Online Support 下载页：

- [TIA Portal V20 Trial/Download（官方入口，文档 109963850）](https://support.industry.siemens.com/cs/document/109963850/simatic-step-7-incl-safety-s7-plcsim-and-wincc-v20-trial-download)
- [TIA Portal V20 官方安装说明](https://docs.tia.siemens.cloud/r/en-us/v20/installation/starting-installation)

下载时选择与你的系统匹配的 V20 安装介质。安装器会检查下载目录中的 `Start.exe` 或官方安装包，并提示用户选择组件；不会从第三方网盘获取博图安装文件。

注意：官方页面可能要求 Siemens 账号、试用资格或 License Key。代理可以打开官方页面、检测安装源和自动执行安装步骤，但不会代填账号、密码或伪造许可证。

## 二、第一次安装

1. 解压代理压缩包到一个固定目录，例如 `D:\TIA-V20-AI`。
2. 双击或右键运行 `install-agent.ps1`。
3. 安装器会复制代理到用户目录：

   `%LOCALAPPDATA%\TiaV20Agent\<版本时间>`

4. 安装完成后双击生成目录中的 `TiaV20Agent.exe`。不要运行 `start-agent.cmd`，它只给开发人员排查问题。

安装器不会删除旧版本，也不会改动 TIA Portal。

## 三、第一次启动检查

启动后如果需要检查环境，可以运行：

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\scripts\preflight-v20.ps1
```

看到下面内容即可继续：

```text
ready: true
```

如果 `ready` 是 `false`，看 `missing` 和 `nextActions`。工具会告诉你缺少 TIA、Openness、.NET、用户组权限还是其他组件。

## 四、没有 Openness 权限怎么办

如果提示用户不在 `Siemens TIA Openness` 组，最简单的方法是：

1. 关闭 TIA Portal。
2. 点击 Windows 开始菜单，搜索 **计算机管理**，打开它。
3. 左侧依次打开：**系统工具 → 本地用户和组 → 组**。
4. 在右侧找到 **Siemens TIA Openness**。
5. 双击这个组，点击 **添加**。
6. 点击 **高级** → **立即查找**。
7. 在列表中选择你当前登录的 Windows 用户名，点击 **确定**。
8. 连续点击 **确定** 关闭窗口。
9. 注销 Windows，再重新登录。
10. 重新双击 `TiaV20Agent.exe`。

如果你的 Windows 家庭版没有“本地用户和组”，用管理员 PowerShell 执行：

```powershell
Add-LocalGroupMember -Group "Siemens TIA Openness" -Member "$env:USERDOMAIN\$env:USERNAME"
```

然后注销并重新登录。代理也提供半自动修复：

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\scripts\setup-environment.ps1 -RepairUserGroup
```

只有管理员 PowerShell 才能加入用户组；代理不会偷偷提权。

## 五、配置 DeepSeek

最简单的方法是直接运行 `start-agent.cmd`。第一次进入聊天时，工具会提示：

```text
请输入 DeepSeek API Key
```

输入你自己的 Key 即可。Key 只保存到本机：

```text
%APPDATA%\TiaV20Agent\config.json
```

### Openness 授权只做一次

运行安装器时会自动登记正式程序。首次安装可能出现一次 UAC，点击“是”即可；以后同一安装目录通常不会再询问。不要每次换目录或运行开发版 bridge。如果自动登记失败，再在安装目录执行：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\setup-openness-firewall.ps1 -Apply
```

打开 EXE 后，右侧“实时进度”区域有“模型”输入框。默认是 `deepseek-chat`；如果账户支持其他模型，填入服务商提供的模型名并点击“保存模型”，不需要使用命令行。

也可以使用环境变量：

```powershell
$env:DEEPSEEK_API_KEY = "你的 Key"
$env:DEEPSEEK_BASE_URL = "https://api.deepseek.com"
$env:DEEPSEEK_MODEL = "deepseek-chat"
```

如果使用兼容 OpenAI 格式的企业网关，只需要修改 `DEEPSEEK_BASE_URL`。

## 六、第一次打开 TIA 工程

日常不需要你操作 TIA 菜单。第一次连接 PLC 或 PLCSIM 时，TIA 需要知道使用哪条通信路径，这只需要配置一次：

1. 打开 TIA Portal V20。
2. 打开你的 `.ap20` 工程。
3. 如果使用标准 PLCSIM，先启动 PLCSIM 并创建与工程 CPU 系列匹配的实例。
4. 在 TIA 的在线连接设置中选择正确的 PG/PC 或 PLCSIM 虚拟路径。
5. 扫描并确认目标设备。

完成后，关闭在线对话框即可。以后打开工程、读取结构、写 SCL、编译、备份和导出都由 AI/MCP 完成。

注意：标准 PLCSIM 的“创建实例”本身不是公开 Openness API；因此工具不能安全地凭空创建标准仿真实例。PLCSIM Advanced 才适合完全程序化创建、下载和运行。

## 七、怎么和 AI 说话

在聊天窗口直接说中文，例如：

```text
检查当前工程有哪些 PLC 和程序块。
```

```text
打开 E:\\Projects\\Pump\\Pump.ap20，列出所有 PLC 块和标签表。
```

```text
给 CPU_1 增加一个电机启停 SCL 功能块，先备份，生成后编译并告诉我错误。
```

```text
把 SelfHoldRelay 导出成 XML，保存到 D:\\TIA-Exports。
```

```text
先检查工程是否能编译，不要修改任何内容。
```

## 八、遇到确认提示怎么办

读取操作通常可以直接执行。下面这些操作默认会询问确认：

- 写入 SCL/XML
- 创建、删除或移动块
- 修改标签和硬件
- 编译
- 保存工程
- 上线、下线
- 下载到 PLC/PLCSIM

确认前，AI 会说明准备做什么。你输入“确认”才会继续。

熟练用户可以关闭确认：

```powershell
$env:TIA_AGENT_AUTO_APPROVE = "true"
```

不建议新手关闭。

## 九、推荐的新手工作习惯

每次修改都使用这个说法：

```text
先检查，再备份，再修改，再编译；如果有错误不要保存。
```

开发阶段优先让 AI：

1. 读取工程结构。
2. 导出或备份目标块。
3. 生成 SCL/XML。
4. 编译并读取诊断。
5. 确认无错误后保存。

不要一开始就要求下载到真实 PLC。

## 十、常见问题

### 1. AI 说找不到 TIA

确认安装的是 TIA Portal V20，并且安装了 Openness 组件。然后重新运行 `preflight-v20.ps1`。

### 2. AI 说没有权限连接

把当前 Windows 用户加入：

```text
Siemens TIA Openness
```

然后注销 Windows 并重新登录。

### 3. PLCSIM 已启动，但不能上线

检查三件事：

- PLCSIM 实例是否已经创建。
- 实例 CPU 系列是否与工程一致。
- TIA 工程是否选择了正确的 PLCSIM/PG-PC 连接路径。

### 4. 为什么不自动改网卡

因为错误修改网卡可能影响 VPN、办公网络和真实 PLC。工具只诊断并给出建议，危险的网络/下载操作要求确认。

### 5. 工具会删除我的博图吗

不会。代理只读取用户安装路径，并把自己的文件安装到独立目录。

## 十一、为什么 Windows 有时会弹权限提示

正确设计是：

- 安装代理时最多需要一次管理员确认。
- 加入 Openness 用户组时需要一次管理员确认。
- 安装 TIA/PLCSIM 时需要管理员确认，并可能重启。
- 日常打开 `TiaV20Agent.exe` 不应使用“以管理员身份运行”。
- 代理不会关闭、绕过或伪造 Windows UAC。

如果每次启动都弹 UAC，通常是快捷方式勾选了“以管理员身份运行”，请右键 EXE → **属性 → 兼容性**，取消 **以管理员身份运行此程序**。只有安装、用户组修复和 TIA 官方安装阶段才需要管理员权限。

## 十二、最简单的日常流程

```text
启动 start-agent.cmd
  ↓
输入自然语言任务
  ↓
AI 自动检查工程
  ↓
需要修改时先备份并询问确认
  ↓
AI 修改、编译、报告结果
```
