import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { StdioClientTransport } from "@modelcontextprotocol/sdk/client/stdio.js";
import readline from "node:readline/promises";
import { stdin as input, stdout as output } from "node:process";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { execFile } from "node:child_process";
import { promisify } from "node:util";
import { existsSync } from "node:fs";
import { readFile, mkdir, writeFile } from "node:fs/promises";

const here = dirname(fileURLToPath(import.meta.url));
const packagedServer = join(here, "..", "runtime", "TiaPortalMcpServer.exe");
const devServer = join(here, "..", "vendor", "chewcw-tia-mcp", "TiaPortalMcpServer", "bin", "Release", "net48", "TiaPortalMcpServer.exe");
const server = process.env.TIA_MCP_SERVER || (existsSync(packagedServer) ? packagedServer : devServer);
const configFile = process.env.TIA_AGENT_CONFIG || join(process.env.APPDATA || here, "TiaV20Agent", "config.json");
let localConfig = {};
try { localConfig = JSON.parse(await readFile(configFile, "utf8")); } catch {}
let apiKey = process.env.DEEPSEEK_API_KEY || localConfig.apiKey || "";
const baseUrl = (process.env.DEEPSEEK_BASE_URL || localConfig.baseUrl || "https://api.deepseek.com").replace(/\/$/, "");
const model = process.env.DEEPSEEK_MODEL || localConfig.model || "deepseek-chat";
const autoApprove = process.env.TIA_AGENT_AUTO_APPROVE === "true";
const client = new Client({ name: "tia-v20-deepseek-chat", version: "0.1.0" });
const transport = new StdioClientTransport({ command: server, args: ["--tia-major-version", "20", "--logging", "none", "--transport", "stdio"] });
const mutating = /create|delete|import|generate|write|apply|compile|save|move|plug|set|open|close|download|online/i;
const execFileAsync = promisify(execFile);
const rl = readline.createInterface({ input, output });
function textOf(result) { return result?.content?.filter(x => x.type === "text").map(x => x.text).join("\n") || JSON.stringify(result); }
async function callTool(name, args) {
  if (mutating.test(name) && !autoApprove) {
    const answer = await rl.question(`\n即将执行可能修改工程或连接设备的工具 ${name}，输入“确认”继续，其他内容取消：`);
    if (answer.trim() !== "确认") return { cancelled: true, tool: name };
  }
  if (name.startsWith("tia_online_") || name === "tia_download") {
    const command = name === "tia_online_status" ? "status" : name === "tia_go_online" ? "online" : name === "tia_go_offline" ? "offline" : "download";
const packagedHelper = join(here, "..", "runtime", "tia-v20-online-helper.exe");
    const devHelper = join(here, "..", "bin", "tia-v20-online-helper.exe");
    const helper = existsSync(packagedHelper) ? packagedHelper : devHelper;
    const argv = [command, args.project]; if (command !== "status") argv.push("--confirm");
    const result = await execFileAsync(helper, argv, { windowsHide: true, timeout: 180000 });
    return { content: [{ type: "text", text: result.stdout.trim() }] };
  }
  return await client.callTool({ name, arguments: args });
}
async function deepseek(messages, tools) {
  const response = await fetch(`${baseUrl}/chat/completions`, { method: "POST", headers: { "content-type": "application/json", authorization: `Bearer ${apiKey}` }, body: JSON.stringify({ model, messages, tools, tool_choice: "auto", temperature: 0.1 }) });
  const data = await response.json(); if (!response.ok) throw new Error(data.error?.message || `DeepSeek HTTP ${response.status}`); return data;
}
await client.connect(transport);
const listed = await client.listTools();
if (process.argv.includes("--doctor")) { console.log(JSON.stringify({ server, toolCount: listed.tools.length, tools: listed.tools.map(x => x.name) }, null, 2)); await client.close(); rl.close(); process.exit(0); }
if (!process.stdin.isTTY) { console.error("交互式终端不可用；MCP 检查已完成，聊天模式需要在终端中启动。"); await client.close(); rl.close(); process.exit(2); }
if (!apiKey) {
  apiKey = (await rl.question("首次启动，请输入 DeepSeek API Key（仅保存到本机）：")).trim();
  if (!apiKey) { console.error("未提供 API Key。"); await client.close(); rl.close(); process.exit(2); }
  await mkdir(join(configFile, ".."), { recursive: true });
  await writeFile(configFile, JSON.stringify({ apiKey, baseUrl, model }, null, 2), "utf8");
  console.log(`API Key 已保存到 ${configFile}`);
}
const toolSchemas = listed.tools.map(t => ({ type: "function", function: { name: t.name, description: t.description || "TIA V20 tool", parameters: t.inputSchema || { type: "object", properties: {} } } }));
toolSchemas.push(
  { type: "function", function: { name: "tia_online_status", description: "Read V20 PLC online/download provider status without changing state", parameters: { type: "object", properties: { project: { type: "string" } }, required: ["project"] } } },
  { type: "function", function: { name: "tia_go_online", description: "Connect a V20 device online; requires local confirmation", parameters: { type: "object", properties: { project: { type: "string" }, confirmed: { type: "boolean" } }, required: ["project", "confirmed"] } } },
  { type: "function", function: { name: "tia_go_offline", description: "Disconnect a V20 device; requires local confirmation", parameters: { type: "object", properties: { project: { type: "string" }, confirmed: { type: "boolean" } }, required: ["project", "confirmed"] } } },
  { type: "function", function: { name: "tia_download", description: "Download a V20 project to the configured target; requires local confirmation", parameters: { type: "object", properties: { project: { type: "string" }, confirmed: { type: "boolean" } }, required: ["project", "confirmed"] } } }
);
const messages = [{ role: "system", content: "你是 TIA Portal V20 工程助手。先读取上下文再修改；任何写入、编译、保存、删除、下载或上线都必须等待本地确认。不要假设工具成功，必须读取返回结果。" }];
console.log(`TIA V20 DeepSeek chat ready; MCP tools=${toolSchemas.length}; confirmations=${autoApprove ? "off" : "on"}. 输入 exit 退出。`);
while (true) {
  const prompt = await rl.question("\n你> "); if (!prompt || prompt.trim().toLowerCase() === "exit") break; messages.push({ role: "user", content: prompt });
  for (let round = 0; round < 8; round++) {
    const reply = (await deepseek(messages, toolSchemas)).choices?.[0]?.message; if (!reply) throw new Error("DeepSeek returned no message"); messages.push(reply);
    if (!reply.tool_calls?.length) { console.log(`\nAI> ${reply.content || ""}`); break; }
    for (const tc of reply.tool_calls) { let args = {}; try { args = JSON.parse(tc.function.arguments || "{}"); } catch (e) { args = { parseError: String(e) }; } const result = await callTool(tc.function.name, args); messages.push({ role: "tool", tool_call_id: tc.id, content: textOf(result) }); }
  }
}
await client.close(); rl.close();
