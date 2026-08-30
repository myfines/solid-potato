# LAD 适配器设计

## 目标

在现有 TIA V20 Openness MCP 之上增加结构化 LAD 网络生成能力，使 AI 可以创建可查看、可编译的 `Main/OB1` 或 FB/FC，而不是只生成孤立 SCL FB。

## 参考方案

参考 GitHub MIT 项目 `eponce00/tiaopen-mcp` 的 `build_lad_block` 数据模型：网络由 `flow` 或 `rungs` 描述，支持常开/常闭触点、线圈、并联分支、指令块和 `%I/%Q/%M` 地址。该项目还明确记录了 TIA V20 `FlgNet` XML 的导入约束。

## 本项目适配边界

- 复用公开的结构化数据模型和 XML 生成思路，不复制 Siemens 程序集或专有二进制。
- 通过当前 TIA V20 MCP 会话执行导入、保存和编译。
- 生成前验证每个网络至少有一个有效指令/触点，禁止空网络。
- 地址只接受规范的 `%I0.0`、`%Q0.0`、`%M0.0`、`%IW4` 等格式。
- OB1 电机示例必须包含实际 I/Q 参数，不允许最终网络使用 `false`/`true` 常量代替接线；带参数的 FB Call XML 已加入生成器，但在 V20 用户包中暂不作为默认路径，需单独通过兼容性测试后启用。

## 首个验收用例

创建 `Main [OB1]` 的 LAD 网络：

1. `Start_Button`（`%I0.0`）与 `Stop_Button`（`%I0.1`，常闭）构成启停条件；
2. `Emergency_Stop`（`%I0.2`，常闭）串联到安全条件；
3. 通过 FB 实例 DB 调用 `Motor_Starter`；
4. `Motor_Run`、`Run_Lamp`、`Fault_Lamp` 分别连接 `%Q0.0`、`%Q0.1`、`%Q0.2`；
5. 导入后重新读取块语言、网络数量、引用地址并编译，结果必须为 0 错误。

## 当前状态

当前实现已包含 `tia_build_lad` 和同一 MCP 会话内的 `blocks_import_xml`；LAD XML 生成器、OB1 元数据、OB 接口段和项目文化已通过修正。网页端原子工作流已实测通过，TIA V20 中实际打开的 `Main [OB1]` 已显示非空 LAD 网络，编译结果为 0 错误、0 警告。工程创建、SCL、标签、备份、LAD 导入和编译均走 MCP/Openness；桌面 UI 只用于最终只读验收，不参与工程操作。

最新前端目录查询已通过懒加载路径，确认 CPU 订货号 `6ES7 214-1BG40-0XB0`、Type Identifier `OrderNumber:6ES7 214-1BG40-0XB0/V4.7`。完整电机工作流已在干净单实例环境中通过：项目创建/打开、设备、I/Q 标签、Motor_Starter FB/实例 DB、Main/OB1 LAD、备份和编译均成功。
