# TIA V20 AI 助手全流程测试记录

日期：2026-08-29

## 已通过

- V20 Openness、.NET Framework 4.8、Node.js、PLCSIM、用户组预检通过。
- EXE/Web 服务可启动，左右分栏界面可访问。
- MCP 服务成功发现 73 个工具。
- 模型可在右侧输入框修改并保存，API Key 未回显。
- 只读中文对话通过，能够读取会话、项目元数据并列出工具类别。
- 隔离项目 `E:\AI_MotorStarter_Demo\AI_MotorStarter_Demo.ap20` 已创建，未修改 `E:\simense`。
- 从已有测试工程复制出的隔离副本 `E:\TIA_AI_FullFlow_Copy\SelfHoldRelay.ap20` 可以被打开并读取设备、块、标签。
- `blocks_source_generate_from_block` 已在隔离副本上成功执行。

## 已确认阻塞

1. 空项目自动创建设备目前返回 `NOT_IMPLEMENTED`：硬件目录搜索和订货号校验可用，但 `devices_create` 实际创建能力尚未实现。因此空白电脑/空项目还不能完全自动生成 PLC。
2. 旧版 8765 进程仍使用 8 轮工具上限，复杂任务会提前中断；新版包已改为 16 轮。
3. 新版测试在第 10 轮 DeepSeek 规划后出现请求无响应，未能自然完成编译和备份。需要增加单轮网络超时、重试与重复工具调用熔断，不能让界面无限等待。
4. 当前标准 PLCSIM 的自动绑定、下载、上线闭环仍未通过验证。

## 安全结论

测试只对隔离副本启用写入；没有执行下载、上线或删除；原工程和 `E:\simense` 未作为写入目标。隔离测试目录保留，后续可继续复现。

## 下一步修复

- 给 DeepSeek 请求加超时、重试和取消状态。
- 为重复的 `devices_search_catalog`、`files_get_info` 等调用增加循环检测。
- 优先实现 V20 硬件目录的真实设备创建，再重新跑空项目全流程。
- 设备创建完成后，重新验证 SCL 生成、编译、保存、备份，再验证 PLCSIM。

## 本轮追加结果

- 已按 Siemens V20 官方示例把 devices_create 从占位实现改为 CreateWithItem，编译通过（0 错误）。
- 新版单点测试因旧 MCP/TIA 会话并发占用，在 projects_open 超时；已结束本轮测试进程。
- Web 客户端已增加 DeepSeek 90 秒超时和一次重试，避免无限等待。
- 设备创建修复尚未完成运行态确认，下一轮需在只有一个 MCP/TIA 会话时重新执行。

- 本轮新增：MCP 工具调用增加 120 秒超时；此前仅 DeepSeek 请求有超时。
- inspect-project-v20.ps1 在当前 PowerShell/.NET 宿主下不能直接加载 Openness（ISponsor 类型错误），不作为 V20 API 失败证据；正式 MCP 进程使用独立 .NET Framework 宿主。

## 最新重测结果

- 用户测试安装 `E:\tia-v20-agent-user-test\current` 启动成功，8765/Web/MCP 73 工具和只读对话通过；本轮未再次出现 Openness 授权弹窗。
- 空项目 `E:\AI_MotorStarter_Demo2` 的目录创建、项目创建、打开、硬件目录搜索、`devices_create` 和 `devices_list` 均通过；设备数由 0 变为 1。
- 发现设备创建参数顺序问题：TIA 返回的设备名取第三个参数，代码已修正为让用户指定的名称成为设备名；修复后需在新包中再次确认显示名。
- 已有设备隔离副本 `E:\TIA_AI_FullFlow_Copy\SelfHoldRelay.ap20` 的打开、设备读取、2 个 PLC 块读取、PLC 软件编译和项目保存均通过。
- 备份已真实生成：`E:\TIA_AI_FullFlow_Backup_20260829`，包含 24 个文件且项目文件存在。
- PLCSIM 当前未运行；在线/下载闭环未执行，标准 PLCSIM 仍需人工配置实例和接口后复测。

## 写入/停止回归追加

- 最新 EXE 对隔离副本执行最小写入测试时，未发生写入崩溃；任务卡在 `projects_open` 的 TIA 冷启动/项目锁等待。
- 点击“停止”实际返回 HTTP 200，并记录 `用户停止了当前任务`；后续修复使当前 MCP `callTool` 和 OnlineHelper 子进程共享 AbortSignal，停止时会同时取消底层工具。
- 本次测试没有出现 `tags_create`、`software_add_block` 或保存成功事件，隔离副本未发现新增测试标签文件。
- 最新隔离修复闭环已通过：`E:\AI_MotorStarter_Test\AI_MotorStarter_Test\AI_MotorStarter_Test.ap20` 先备份到 `E:\AI_MotorStarter_Test\Backup_Remove_MotorControl`，确认并删除损坏块 `Motor_Control`，保留 `MotorControl_Atomic`，随后编译返回 `Success`，diagnostics 为 `No block was compiled. All blocks are up-to-date.` 和 `Compiling finished (errors: 0; warnings: 0)`，项目保存成功。
- 最新最小写入回归已通过：隔离工程 `E:\TIA_AI_FullFlow_Copy\SelfHoldRelay.ap20` 成功写入并保存 `AI_Write_Check`，类型 `Bool`，地址 `%M10.0`；随后使用只读对话重新打开工程并核验到同一标签和绝对路径。写入过程未崩溃。
- 修复了只读模式错误拦截 `projects_open` 的问题，使写入后的二次核验可以安全重新打开工程。
- 浏览器复杂任务回归：通过浏览器启用无限模式并提交“备份工程→创建 SCL 文件→添加外部源→生成块→编译→保存”的隔离任务；在 TIA 冷启动等待期间点击停止，最新包只显示“用户已停止当前任务”，没有进入下一轮，服务保持可用。
- 最新浏览器写入回归：`AI_Browser_Final` 已保存到 `E:\TIA_AI_FullFlow_Copy\SelfHoldRelay.ap20` 的 `默认变量表`，类型 `Bool`，地址 `%M13.0`；左侧显示完整回复，右侧仅显示工具状态和 token 总量。
- 干净 MCP 原子测试在 projects_open 等待超过 60 秒后收到客户端超时；随后 bridge 也因同一隔离副本锁定而无输出。TIA 报告该项目仍被用户 zrk 打开，异常终止后需等待约 2 分钟。未产生备份或新文件。
- 已修复 scripts/build-bridge.ps1 的 PowerShell /out: 参数拼接错误；bridge 现在可以成功编译，但项目锁仍需在单会话、正常关闭条件下复测。

- 预检新增 TIA Portal 运行态检测：发现 Siemens.Automation.Portal.exe 时给出关闭全部 TIA 窗口的明确提示，避免 Openness 项目锁。
- 重测时发现现有白名单仍指向旧包 `115417`；新包需要一次管理员 UAC 才能登记到 V20 Openness 白名单。非管理员运行脚本被 HKLM 拒绝，管理员脚本本轮未完成登记，因此最终 EXE 重测暂停在授权步骤。
- 2026-08-30 端到端复测：通过网页真实提交 AI_MotorStarter_Test 任务。权限模式生效且未出现权限弹窗；环境预检通过（TIA V20 Openness、.NET 4.8、Openness 用户组、MCP、PLCSIM 均可见）。仓库回归脚本 PASS：隔离项目打开、只读查询、未授权写操作拦截、备份、SCL 应用和块验证均通过。
- 同次网页复测发现未完成项：`tia_apply_scl` 返回“ SCL 生成程序块失败”，模型随后绕行到 `software_add_block`/`tia_write_text_file`/`blocks_external_source_add`，因此新版服务已将任何 error/blocked 步骤判为任务未完成，禁止伪成功。尚未证明 PLCSIM 实际启动、下载或在线连接。
- 只读 PLCSIM/在线复核：TIA V20 与 PLCSIM 版本可发现，`device_capabilities` 返回编译可用但 `download=false`、`online=false`；`plcsim_status` 显示标准 PLCSIM 当前未运行，8100/8101 未监听；`device_connection_targets` 返回 `Online provider unavailable for device.`。因此当前机器只能证明安装与 Openness 编译链可用，不能宣称标准 PLCSIM 下载/在线闭环通过。
