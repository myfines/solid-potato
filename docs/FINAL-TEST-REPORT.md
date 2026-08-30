# TIA V20 AI 助手端到端测试报告

更新时间：2026-08-30

## 已验证通过

- 最新安装包可在独立端口启动，状态接口正常返回。
- TIA Portal V20 Openness、.NET Framework 4.8、Node.js、MCP 服务和 `Siemens TIA Openness` 用户组预检通过。
- MCP 工具发现数量为 81。
- 只读项目、设备、标签和块查询通过。
- 未授权写入会被拦截；无限模式配置可持久化读取。
- 隔离工程 `AI_MotorStarter_Test` 创建、打开和备份通过。
- 底层 MCP 回归脚本通过：环境检查、项目打开、只读查询、未授权编译拦截、SCL 应用和块验证。
- 标准 PLCSIM V20 可由工具启动，进程和 8100 端口可被状态工具检测。
- 中间步骤失败时，网页现在不会再伪报“任务完成”。

## 已发现并修复

- 历史 `blocked` 事件导致权限弹窗重复出现。
- 重复调用熔断被错误显示为权限问题。
- 工具调用失败后 AI 仍返回成功文本。
- 任务历史中断造成的 tool call 消息不完整。

## 尚未通过

- 网页封装的 `tia_apply_scl` 对部分 AI 生成的 SCL 源码仍会返回生成块失败；该失败现在会明确显示，不再被绕行步骤掩盖。
- 标准 PLCSIM V20 当前未向该工程暴露 Online Provider；能力探测为 `compile=true`、`download=false`、`online=false`。
- 尚未验证下载到 PLCSIM 或真实 PLC 在线连接，因此产品暂不能宣称全自动下载上线。

## 关键测试产物

- 安装包：`dist/tia-v20-agent-20260830-211137`
- 隔离工程：`E:/AI_MotorStarter_Test/AI_MotorStarter_Test/AI_MotorStarter_Test.ap20`
- MCP 回归工程：`testdata/Regression-20260830-211325`
- 最新测试记录提交：`c6abfc3`

## 发布判断

当前适合发布为“TIA V20 工程读写、备份、SCL/MCP 自动化测试版”，不适合宣称“标准 PLCSIM/真实 PLC 全自动下载上线版”。发布前仍应修复网页 `tia_apply_scl` 的 SCL 兼容性，并在具备可用 Online Provider 的 PLCSIM Advanced 或明确配置的目标上重新验证下载链路。

## 最新前端全流程复测

单一 8766 前端会话实测通过：项目 `AI_MotorStarter_GoalTest` 创建、S7-1200 创建设备、7 个标签创建、项目保存、外部备份、`tia_apply_scl` 和编译均成功；第 10 轮正常结束，未下载、未上线，未出现权限弹窗或死循环。该结果不改变标准 PLCSIM 在线 Provider 尚未可用的结论。

## 原子电机工作流最终复测

单一 8766 前端会话中，`tia_build_motor_project` 单次调用成功（约 118 秒）。工程 `AI_MotorStarter_FinalVerified2`、外部备份、`Motor_Starter` FB/实例 DB SCL 源文件均已落盘；前端显示“已完成隔离工程创建、备份、SCL 生成和编译”，任务未下载、未上线，未发生重复工具调用。
