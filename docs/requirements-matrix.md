# 目标验收矩阵

| 目标 | 当前状态 | 证据 |
|---|---|---|
| V20 Openness 环境发现 | 已验证 | `scripts/preflight-v20.ps1` |
| 工程/设备/PLC/程序块读取 | 已验证 | `scripts/regression-v20.ps1`、GitHub MCP doctor |
| 标签读取/管理 | 主 MCP 已提供工具契约 | `tags_list` 等 73 工具；待真实工程会话测试 |
| SCL 导入与生成块 | 已验证 | MCP 回归，新增 `AiSelfHoldTest` |
| 编译与诊断 | 已验证 | V20 编译返回 0 错误；主 MCP 有 `compilation_software` |
| 自动备份/回滚 | 部分验证 | SCL 测试备份通过；主基线提供回滚事务 |
| 权限确认 | 已验证基础门禁 | DeepSeek CLI 默认确认；`TIA_AGENT_AUTO_APPROVE=true` 可显式关闭 |
| HMI/LAD/FBD | 工具契约已存在 | 主 MCP 工具表；待 V20 工程实测 |
| PLCSIM 启动/实例创建 | 已验证 | PLCSIM 进程、端口和 Standard S7-1200 实例已确认 |
| TIA 与 PLCSIM 握手 | 未验证 | 当前工程仍绑定 Wi-Fi，GoOnline 失败 |
| PLC 下载/运行/在线变量 | 未验证 | Online helper 已编译，未执行下载 |
| 空白电脑安装 | 隔离目录已验证 | `install-agent.ps1` 安装后 doctor 73 工具、manifest 通过 |
| 全新 Windows 安装 | 未验证 | 需要独立干净系统或虚拟机 |

