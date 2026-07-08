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

  // Build a summary of available agents for the tool description
  const agentSummary = agentNames
    .map((name) => `  - ${name}: ${config.agents[name].description}`)
    .join("\n");

  pi.registerTool({
    name: "delegate",
    label: "Delegate to Sub-Agent",
    description: `Delegate a task to a specialized sub-agent. Each sub-agent has its own model and persona. Available agents:\n${agentSummary}\n\nThe sub-agent runs in print mode (pi -p) with its configured model and returns the result. Use this for ALL coding work — do not write code yourself.`,
    promptSnippet: "Delegate tasks to specialized sub-agents (each with its own model)",
    promptGuidelines: [
      "Use delegate for ALL coding work — never write or edit code files yourself.",
      "Use delegate for code review, feature building, refactoring, debugging, testing, and DevOps work.",
      "Choose the sub-agent that best matches the task: frontend-developer for UI, software-engineer for backend/logic, code-reviewer for review, devops-engineer for CI/CD, test-engineer for tests.",
      "When delegating, include all necessary context in the task description — the sub-agent has no memory of the conversation.",
    ],
    parameters: Type.Object({
      agent: StringEnum(agentNames as [string, ...string[]], {
        description: "Which sub-agent to delegate to",
      }),
      task: Type.String({
        description: "The full task description. Include all context the sub-agent needs — file paths, requirements, constraints, relevant code snippets. The sub-agent has no memory of the current conversation.",
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

      // Notify that delegation is starting
      onUpdate?.({
        content: [{
          type: "text",
          text: `Delegating to ${agentConfig.label} (${agentConfig.model})...`,
        }],
      });

      // Build the full prompt: persona + task
      // Include cwd so the sub-agent knows where it's working
      const fullPrompt = [
        agentConfig.persona,
        "",
        `Working directory: ${ctx.cwd}`,
        "",
        "TASK:",
        params.task,
      ].join("\n");

      // Spawn pi in print mode with the specified model
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
          // Stream progress updates
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

        // Handle abort
        signal?.addEventListener("abort", () => {
          proc.kill("SIGTERM");
        });

        proc.on("error", (err) => {
          reject(new Error(`Failed to spawn pi: ${err.message}`));
        });

        proc.on("close", (code) => {
          if (code !== 0) {
            reject(new Error(`pi exited with code ${code}. stderr: ${stderr}`));
          } else {
            resolvePromise(stdout || stderr || "(no output)");
          }
        });

        // Timeout: 10 minutes
        setTimeout(() => {
          if (!proc.killed) {
            proc.kill("SIGTERM");
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

  // Register a command to list available sub-agents
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