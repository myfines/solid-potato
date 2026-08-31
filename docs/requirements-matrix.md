# 目标验收矩阵

| 目标 | 当前状态 | 证据 |
|---|---|---|
| V20 Openness 环境发现 | 已验证 | `scripts/preflight-v20.ps1` |
| 工程/设备/PLC/程序块读取 | 已验证 | `scripts/regression-v20.ps1`、GitHub MCP doctor |
| 标签读取/管理 | 已验证 | 浏览器真实创建电机/输送带工程并完成物理 I/Q 标签创建 |
| SCL 导入与生成块 | 已验证 | MCP 回归，新增 `AiSelfHoldTest` |
| 编译与诊断 | 已验证 | V20 编译返回 0 错误；主 MCP 有 `compilation_software` |
| 自动备份/回滚 | 部分验证 | SCL 测试备份通过；主基线提供回滚事务 |
| 权限确认 | 已验证基础门禁 | DeepSeek CLI 默认确认；`TIA_AGENT_AUTO_APPROVE=true` 可显式关闭 |
| HMI/LAD/FBD | LAD 已验证，HMI/FBD 未验证 | 浏览器真实导入 Main/OB1 LAD，返回 imported/replaced/verified=true；HMI/FBD 仍待实测 |
| PLCSIM 启动/实例创建 | 已验证 | PLCSIM 进程、端口和 Standard S7-1200 实例已确认 |
| TIA 与 PLCSIM 握手 | 未验证 | 当前工程仍绑定 Wi-Fi，GoOnline 失败 |
| PLC 下载/运行/在线变量 | 未验证 | Online helper 已编译，未执行下载 |
| 空白电脑安装 | 隔离目录已验证 | `install-agent.ps1` 安装后 doctor 73 工具、manifest 通过 |
| 全新 Windows 安装 | 未验证 | 需要独立干净系统或虚拟机；当前仅完成安装包、脚本和隔离目录验证 |

## 浏览器 Agent 全流程回归

- 电机启停工程：真实创建隔离工程、CPU、标签、SCL、实例 DB、Main/OB1 LAD、保存和离线编译，0 错误 0 警告。
- 输送带工程：第一次 LAD 参数错误后由 Agent 获取错误并自动修复；最终工程、备份、LAD XML 均存在，编译成功。
- 连续第二工程：同一服务进程关闭旧会话并创建第二个隔离工程，路径和产物均存在。
- 停止后续任务：浏览器点击停止后，下一条只读任务可立即开始。
- 权限恢复：确认模式阻止写入并显示前端提示；重新开启无限模式后写入任务成功。
- 真实性门禁：最终 `.ap20`、备份和 LAD 文件不存在时禁止报告成功。
