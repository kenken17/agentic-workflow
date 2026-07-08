import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";
import { StringEnum } from "@earendil-works/pi-ai";
import { readFileSync, existsSync } from "node:fs";
import { resolve } from "node:path";
import { homedir } from "node:os";
import { spawn } from "node:child_process";

interface AgentConfig {
  model: string;
  label: string;
  description: string;
  persona: string;
}

interface SubAgentsConfig {
  agents: Record<string, AgentConfig>;
}

// State tracking for active and completed delegate calls
const activeDelegates = new Map<string, { agent: string; taskPreview: string; startTime: number }>();
const delegateHistory: Array<{ agent: string; taskPreview: string; startTime: number; endTime: number; status: "ok" | "error" | "timeout" | "aborted" }> = [];
const MAX_HISTORY = 50;

function addActive(toolCallId: string, agent: string, task: string) {
  activeDelegates.set(toolCallId, {
    agent,
    taskPreview: task.slice(0, 120),
    startTime: Date.now(),
  });
}

function removeActive(toolCallId: string, status: "ok" | "error" | "timeout" | "aborted") {
  const entry = activeDelegates.get(toolCallId);
  if (!entry) return;
  activeDelegates.delete(toolCallId);
  delegateHistory.unshift({
    agent: entry.agent,
    taskPreview: entry.taskPreview,
    startTime: entry.startTime,
    endTime: Date.now(),
    status,
  });
  if (delegateHistory.length > MAX_HISTORY) delegateHistory.length = MAX_HISTORY;
}

function formatDuration(ms: number): string {
  if (ms < 1000) return `${ms}ms`;
  if (ms < 60000) return `${(ms / 1000).toFixed(1)}s`;
  return `${Math.floor(ms / 60000)}m ${Math.floor((ms % 60000) / 1000)}s`;
}

function buildStatusReport(): string {
  const lines: string[] = [];

  // Header
  lines.push("┌──────────────────────────────────────────────────────────────────────────┐");
  lines.push("│ AGENT STATUS                                      │");
  lines.push("├──────────────────────────────────────────────────────────────────────────┤");

  // Build per-agent status
  const agentStatus = new Map<string, { state: "live" | "idle"; tasks: string[]; elapsed: number }>();
  for (const [id, d] of activeDelegates.entries()) {
    const s = agentStatus.get(d.agent) || { state: "idle" as const, tasks: [], elapsed: 0 };
    s.state = "live";
    s.tasks.push(d.taskPreview.slice(0, 40));
    s.elapsed = Math.max(s.elapsed, Date.now() - d.startTime);
    agentStatus.set(d.agent, s);
  }

  // Get all configured agents so idle ones show too
  const configPath = findConfigPath();
  let allAgents: Record<string, AgentConfig> = {};
  if (configPath) {
    try {
      const raw = readFileSync(configPath, "utf-8");
      allAgents = JSON.parse(raw).agents || {};
    } catch {}
  }

  for (const [name, cfg] of Object.entries(allAgents)) {
    const s = agentStatus.get(name);
    if (s && s.state === "live") {
      const badge = "🔴 LIVE";
      const elapsed = formatDuration(s.elapsed);
      lines.push(`│ ${badge.padEnd(8)} ${(cfg.label || name).slice(0, 18).padEnd(18)} ${elapsed.padStart(10)} │`);
      for (const task of s.tasks.slice(0, 2)) {
        lines.push(`│          → ${task.slice(0, 55).padEnd(55)} │`);
      }
    } else {
      const badge = "⚪ IDLE";
      lines.push(`│ ${badge.padEnd(8)} ${(cfg.label || name).slice(0, 18).padEnd(18)} ${"".padStart(10)} │`);
    }
  }

  if (Object.keys(allAgents).length === 0) {
    lines.push(`│ (no agents configured)                              │`);
  }

  lines.push("└──────────────────────────────────────────────────────────────────────────┘");

  // Recent history
  if (delegateHistory.length > 0) {
    lines.push("");
    lines.push("📋 Recent activity (last 10):");
    for (const h of delegateHistory.slice(0, 10)) {
      const icon = h.status === "ok" ? "✅" : h.status === "aborted" ? "❌" : "⚠️";
      lines.push(`  ${icon} [${h.agent}] ${h.taskPreview.slice(0, 60)} (${formatDuration(h.endTime - h.startTime)})`);
    }
  }

  return lines.join("\n");
}

// Look for sub-agents.json in project-local first, then global
function findConfigPath(): string | null {
  const paths = [
    resolve(process.cwd(), ".pi", "sub-agents.json"),
    resolve(homedir(), ".pi", "agent", "sub-agents.json"),
  ];
  for (const p of paths) {
    if (existsSync(p)) return p;
  }
  return null;
}

function loadConfig(): SubAgentsConfig {
  const configPath = findConfigPath();
  if (!configPath) {
    console.error("sub-agent: sub-agents.json not found in .pi/ or ~/.pi/agent/");
    return { agents: {} };
  }
  try {
    const raw = readFileSync(configPath, "utf-8");
    return JSON.parse(raw);
  } catch (err) {
    console.error(`sub-agent: Failed to load ${configPath}: ${err}`);
    return { agents: {} };
  }
}

export default function (pi: ExtensionAPI) {
  const config = loadConfig();
  const agentNames = Object.keys(config.agents);

  if (agentNames.length === 0) {
    console.error("sub-agent: No agents configured in sub-agents.json");
    return;
  }

  const agentSummary = agentNames
    .map((name) => `  - ${name}: ${config.agents[name].description}`)
    .join("\n");

  pi.registerTool({
    name: "delegate",
    label: "Delegate to Sub-Agent",
    description: `Delegate a task to a specialized sub-agent. Available agents:\n${agentSummary}\n\nThe sub-agent runs in print mode (pi -p) with its configured model and returns the result.`,
    promptSnippet: "Delegate tasks to specialized sub-agents (each with its own model)",
    promptGuidelines: [
      "Use delegate for ALL coding work — never write or edit code files yourself.",
      "When delegating, include all necessary context in the task description.",
      "Choose the sub-agent that best matches the task.",
    ],
    parameters: Type.Object({
      agent: StringEnum(agentNames as [string, ...string[]], {
        description: "Which sub-agent to delegate to",
      }),
      task: Type.String({
        description: "The full task description. The sub-agent has no memory of the current conversation.",
      }),
    }),

    async execute(toolCallId, params, signal, onUpdate, ctx) {
      const agentConfig = config.agents[params.agent];
      if (!agentConfig) {
        return {
          content: [{
            type: "text",
            text: `Unknown agent: ${params.agent}. Available: ${agentNames.join(", ")}`,
          }],
          details: { error: "unknown_agent" },
        };
      }

      addActive(toolCallId, params.agent, params.task);

      onUpdate?.({
        content: [{
          type: "text",
          text: `🔴 [${agentConfig.label}] Starting...`,
        }],
      });

      const fullPrompt = [
        agentConfig.persona,
        "",
        `Working directory: ${ctx.cwd}`,
        "",
        "TASK:",
        params.task,
      ].join("\n");

      const result = await new Promise<string>((resolvePromise, reject) => {
        const proc = spawn("pi", ["-p", "--model", agentConfig.model, fullPrompt], {
          cwd: ctx.cwd,
          env: { ...process.env },
          stdio: ["pipe", "pipe", "pipe"],
        });

        let stdout = "";
        let stderr = "";

        proc.stdout.on("data", (data) => {
          stdout += data.toString();
          const lines = data.toString().split("\n").filter((l: string) => l.trim());
          if (lines.length > 0) {
            onUpdate?.({
              content: [{ type: "text", text: lines[lines.length - 1] }],
            });
          }
        });

        proc.stderr.on("data", (data) => {
          stderr += data.toString();
        });

        signal?.addEventListener("abort", () => {
          proc.kill("SIGTERM");
        });

        proc.on("error", (err) => {
          removeActive(toolCallId, "error");
          reject(new Error(`Failed to spawn pi: ${err.message}`));
        });

        proc.on("close", (code) => {
          if (code !== 0) {
            removeActive(toolCallId, code === null ? "aborted" : "error");
            reject(new Error(`pi exited with code ${code}. stderr: ${stderr}`));
          } else {
            removeActive(toolCallId, "ok");
            resolvePromise(stdout || stderr || "(no output)");
          }
        });

        setTimeout(() => {
          if (!proc.killed) {
            proc.kill("SIGTERM");
            removeActive(toolCallId, "timeout");
            reject(new Error("Sub-agent timed out after 10 minutes"));
          }
        }, 600000);
      });

      return {
        content: [{ type: "text", text: result }],
        details: {
          agent: params.agent,
          model: agentConfig.model,
          label: agentConfig.label,
        },
      };
    },
  });

  pi.registerTool({
    name: "delegate_status",
    label: "Delegate Status",
    description: "Show currently active delegate calls and recent history. Shows 🔴 LIVE / ⚪ IDLE for each configured agent.",
    promptSnippet: "Show active delegates and recent history",
    promptGuidelines: [
      "Call delegate_status to check what sub-agents are currently running.",
      "Call delegate_status after a long-running delegation to verify it completed.",
    ],
    parameters: Type.Object({}),
    async execute() {
      return {
        content: [{ type: "text", text: buildStatusReport() }],
        details: {
          activeCount: activeDelegates.size,
          historyCount: delegateHistory.length,
        },
      };
    },
  });

  pi.registerCommand("delegates", {
    description: "Show active sub-agents and recent delegate history",
    handler: async (_args, ctx) => {
      ctx.ui.notify(buildStatusReport(), "info");
    },
  });

  pi.registerCommand("agents", {
    description: "List available sub-agents",
    handler: async (_args, ctx) => {
      const lines = ["Available sub-agents:", ""];
      for (const [name, agent] of Object.entries(config.agents)) {
        lines.push(`  ${name}`);
        lines.push(`    Model: ${agent.model}`);
        lines.push(`    ${agent.description}`);
        lines.push("");
      }
      lines.push("Use 'delegate' tool to assign tasks to sub-agents.");
      ctx.ui.notify(lines.join("\n"), "info");
    },
  });
}
