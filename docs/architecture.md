# V20 Agent 架构

```text
桌面聊天客户端
  -> DeepSeek/OpenAI-compatible API
  -> 工具规划与权限确认
  -> MCP stdio server
  -> TIA V20 adapter (C#/.NET Framework)
  -> TIA Portal V20 / PLCSIM V20
```

## 兼容性原则

1. 优先使用用户已有的 TIA Portal 安装；只读注册表和已知安装路径，不覆盖、不删除。
2. 只针对 V20 加载匹配的 `PublicAPI\V20` 程序集。
3. 工程写入前创建旁路备份；下载、覆盖、删除、在线写变量属于高风险动作。
4. 设备类型采用能力探测，不把第一版锁死在单一 CPU 型号；S7-1200、S7-1500 与 PLCSIM 逐项探测。
5. “工程标签”与“在线 PLC 变量”分开建模，避免把离线属性误报为实时值。

## 第一批工具契约

- `environment_doctor`
- `project_open`
- `project_info`
- `devices_list`
- `plc_list`
- `blocks_list`
- `tags_list`
- `scl_import`
- `project_compile`
- `project_save_backup`

后续加入 HMI、LAD/FBD、在线监控和下载，并要求显式确认。

