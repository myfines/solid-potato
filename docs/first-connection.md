# 首次 PLC/PLCSIM 连接（只需一次）

代理的日常工程操作不走 GUI。首次连接时，TIA Portal 需要知道 PG/PC 接口和目标设备；这属于 TIA 的连接初始化前置条件。

## 标准流程

1. 启动 TIA Portal V20，并打开目标工程。
2. 对标准 PLCSIM，先启动 PLCSIM V20 并创建/保存一个与项目 CPU 系列匹配的仿真实例。
3. 在 TIA Portal 的 Online/在线菜单进入 Accessible devices/可访问设备。
4. 选择正确的 PG/PC 接口；标准 PLCSIM 使用 TIA 支持的虚拟连接路径，不要把普通 Wi-Fi 网卡当作仿真目标。
5. 扫描并选择目标设备，确认设备地址/实例。
6. 完成一次连接后关闭在线对话框；后续由 MCP 的连接预检、OnlineProvider 和 DownloadProvider 处理。

## 代理行为

- `device_connection_targets`：读取当前配置，不修改。
- `device_capabilities`：判断在线/下载 provider 是否存在。
- `tia_online_status`：读取 provider 状态。
- `tia_go_online`、`tia_download`：必须经过本地确认，且不会替用户猜测目标接口。

如果预检显示没有 PLCSIM 接口或目标地址为空，代理会停下来给出引导，不会自动改 Windows 网卡或覆盖工程连接配置。

安装包内还提供 `scripts\diagnose-connection-v20.ps1` 和 `scripts\scan-connection-v20.ps1`，用于只读查看当前接口、目标槽位和可访问设备。
