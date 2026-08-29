# 全流程自动安装设计

## 可以自动化的部分

用户提供合法的 TIA Portal V20 安装源后，代理安装器可以自动完成：

1. 检查管理员权限、磁盘空间和 Windows 版本。
2. 检测已有 TIA V20，避免重复安装和覆盖。
3. 启动 TIA Setup，并选择 STEP 7、WinCC、PLCSIM 和 TIA Portal Openness 组件。
4. 等待安装、重启和安装后服务恢复。
5. 检查 `PublicAPI\V20\Siemens.Engineering.dll`。
6. 检查/引导当前用户加入 `Siemens TIA Openness` 用户组。
7. 安装本代理、便携 Node 和 MCP 服务。
8. 写入 DeepSeek/MCP 配置。
9. 运行 preflight、MCP doctor 和版本完整性校验。

每一步都在安装器界面或日志中显示阶段、当前动作、成功/失败结果和下一步。需要重启时保存断点，重启后从上一个未完成阶段继续；日常运行不请求管理员权限。

## 不能由代理绕过的部分

- 不能破解或伪造 Siemens License Key。
- 不能把 TIA/PLCSIM 安装包重新打包进公开代理压缩包，除非分发授权明确允许。
- 不能替用户接受不明确的许可条款或输入许可证密钥。
- 标准 PLCSIM 的首次实例/连接初始化可能仍需要用户确认目标；PLCSIM Advanced 才适合完全程序化实例控制。

## 两种用户模式

### 模式 A：用户已有 TIA

```text
检测已有 V20
  -> 不安装 TIA
  -> 自动安装/配置代理
  -> 运行 doctor
  -> 开始聊天
```

### 模式 B：空白电脑 + 用户提供安装源

```text
选择 TIA V20 安装源
  -> 安装器检查许可/组件
  -> 自动安装 TIA + Openness + PLCSIM
  -> 重启后继续安装
  -> 安装代理
  -> preflight/doctor
  -> 开始聊天
```

## 官方依据

- TIA Portal V20 Openness 通过 TIA Setup 的 Openness 选项安装，并生成 `Siemens TIA Openness` 用户组。
- STEP 7 Basic/Professional 和 WinCC 产品使用相应的 License Key。

参考：[Installing TIA Portal Openness](https://docs.tia.siemens.cloud/r/en-us/v20/tia-portal-openness-api-for-automation-of-engineering-workflows/basics/installation/installing-tia-portal-openness)、[Licensing STEP 7 and WinCC](https://docs.tia.siemens.cloud/r/en-us/v20/installation/licensing/licensing-step-7-and-wincc)

官方安装源入口：[TIA Portal V20 Trial/Download](https://support.industry.siemens.com/cs/document/109963850/simatic-step-7-incl-safety-s7-plcsim-and-wincc-v20-trial-download)。

## 当前原型状态

代理自动安装链已经可以自动完成代理、便携 Node、MCP、预检和配置；TIA 本体的自动安装器接口尚未纳入发布包，当前仍要求用户提供合法安装源并在许可提示处确认。
