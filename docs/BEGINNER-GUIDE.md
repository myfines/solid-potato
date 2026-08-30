# TIA V20 AI 助手：新手操作教程

## 如果你完全不会用电脑

你只需要做三件事：

1. 把收到的压缩包解压出来。
2. 双击 `install-agent.cmd`，安装时如果弹出 Windows 询问，点击“是”。
3. 双击安装目录里的 `TiaV20Agent.exe`，在左侧输入你想做的事，点击“发送”。

示例：

```text
打开我的 TIA V20 工程，创建一个电机启停程序，先备份，生成 SCL，编译成功后下载到 PLCSIM。
```

右侧会实时显示 AI 正在做什么。第一次建议保持“确认模式”；确认整个流程没问题后，可以在右侧勾选“无限模式”，点击“保存模式”，以后同一会话不再逐次询问。

无限模式会允许 AI 自动修改工程、编译、保存和下载。只对测试工程开启，真实 PLC 下载前必须确认目标设备。

## 在浏览器界面完成一次写入

打开 `TiaV20Agent.exe` 后，会自动打开本机助手页面。按下面顺序操作：

1. 看右侧是否显示 **MCP 工具：77**。
2. 点击右侧 **无限模式：自动写入/编译/下载**，再点击 **保存模式**。
3. 在左侧大输入框粘贴任务，例如：

   ```text
   请只操作隔离工程 E:\TIA_AI_FullFlow_Copy\SelfHoldRelay.ap20，创建一个 Bool 标签 AI_Browser_Final，地址 M13.0，保存工程；不要编译、下载、上线或删除。最后返回工程绝对路径、设备名、标签表、标签名、类型、地址和保存结果。
   ```

4. 点击 **发送**。
5. 左侧会显示完整 AI 回复，右侧只显示工具步骤和成功/失败状态；token 碎片不会再堆满右侧。
6. 如果任务异常，点击左下方 **停止**，Agent 会停止当前任务并保留页面。

示例验证后的成品路径是：`E:\TIA_AI_FullFlow_Copy\SelfHoldRelay.ap20`；标签表为 `默认变量表`，标签 `AI_Browser_Final` 为 `Bool`，地址 `%M13.0`，工程保存成功。

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
9. 注销 Windows，再重新登录。或者直接重启电脑。
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
# 重要限制与常见情况

## 版本与安装

- 当前首要支持 TIA Portal V20；V21 或更高版本不能直接保证兼容。
- 必须安装 TIA Portal V20 Openness 组件，并确认本机存在 V20 PublicAPI。
- Windows 用户必须加入 `Siemens TIA Openness` 用户组；加入后通常需要注销或重启才能生效。
- TIA Portal、PLCSIM 和本代理必须使用相容的管理员/普通用户权限环境。不要一会儿用管理员启动，一会儿用普通用户启动同一个工程。

## 工程与会话

- 一个 TIA Openness 会话通常只能安全操作一个当前工程。
- 如果 TIA UI 已打开其他工程，自动化工具不会强行关闭或覆盖它；请先保存并关闭，或明确选择复用当前工程。
- 创建工程后 TIA 可能需要几秒释放文件锁；工具会等待并重试，但不能保证第三方插件或杀毒软件立即释放锁。
- 不要同时启动多个代理包、多个 MCP 服务或多个 TIA 自动化进程；它们可能争用 COM 会话并表现为“工具卡死”。
- 工程、备份和 SCL 源文件必须放在代理安装目录之外，避免递归复制和文件锁冲突。

## LAD、OB1、FB 与地址

- 生成 FB 不等于工程可运行；必须在 Main/OB1 中调用 FB，并绑定正确的实例 DB。
- `tia_build_lad` 使用结构化 LAD XML，不模拟鼠标拖拽；复杂指令、特殊 OB 类型和不同 TIA Update 版本可能需要额外模板。
- OB 的块号和 `SecondaryType` 必须匹配；OB1 通常使用 `ProgramCycle`，不能使用块号 0。
- LAD 网络中的 `%I/%Q/%M` 地址必须与 PLC 标签数据类型一致；用 `false/true` 常量代替实际 I/Q 接线只能作为演示，不能当作现场程序。
- TIA 项目缺少 `en-US` 文化时，导入的注释文化必须使用项目已有文化，例如 `zh-CN`。
- 导入 LAD XML 前必须确保网络不为空、触点/线圈类型合法、引用的 DB 和块已经存在。

## 编译、仿真与在线

- 编译成功只表示工程代码通过编译，不表示 PLC 已下载、已运行或现场接线正确。
- 标准 S7-PLCSIM V20 可以启动，但不一定向 Openness 暴露可用的 Online Provider；PLCSIM Advanced 的 API 能力不能直接套用于 Standard。
- 下载或上线可能改变真实 PLC 状态，默认不会自动执行；启用无限模式后，用户必须自行承担误下载、覆盖程序和设备停机风险。
- 在线目标、PG/PC 接口、虚拟网卡和仿真实例必须匹配。普通 Wi-Fi 网卡不等于 PLCSIM 虚拟接口。
- 没有真实 PLC 或匹配的仿真实例时，只能验证工程生成和编译，不能声称在线闭环通过。

## AI 行为限制

- AI 会根据工具返回结果继续规划，但 TIA COM 操作可能耗时几十秒到数分钟；期间不要重复提交同一任务。
- 工具失败后代理会停止危险的绕行写入，并在右侧显示错误；这比继续猜测参数更安全。
- token 数是模型接口返回或估算值，不等于 TIA 执行时间，也不代表工程质量。
- 用户停止任务后，正在执行的 TIA COM 调用可能需要少量时间才能释放；不要立即启动第二个代理实例。
