import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";
import { readFileSync, existsSync } from "node:fs";
import { resolve } from "node:path";
import { homedir } from "node:os";

interface AgentConfig {
  model: string;
  label: string;
  description: string;
  persona: string;
}

interface SubAgentsConfig {
  agents: Record<string, AgentConfig>;
}

// Look for sub-agents.json in both global and project-local locations
function findConfigPath(): string | null {
  const paths = [
    resolve(homedir(), ".pi", "agent", "sub-agents.json"),
    resolve(process.cwd(), ".pi", "agent", "sub-agents.json"),
  ];
  for (const p of paths) {
    if (existsSync(p)) return p;
  }
  return null;
}

function loadConfig(): SubAgentsConfig {
  const configPath = findConfigPath();
  if (!configPath) {
    return { agents: {} };
  }
  try {
    const raw = readFileSync(configPath, "utf-8");
    return JSON.parse(raw);
  } catch {
    return { agents: {} };
  }
}

// Extract a clean provider name from the model string (e.g. "anthropic/claude-sonnet-4" -> "Anthropic")
function providerFromModel(model: string): string {
  const provider = model.split("/")[0] ?? "unknown";
  const map: Record<string, string> = {
    anthropic: "Anthropic",
    openai: "OpenAI",
    google: "Google",
    xai: "xAI",
    openrouter: "OpenRouter",
    ollama: "Ollama",
    opencode: "OpenCode",
  };
  return map[provider.toLowerCase()] ?? provider;
}

// Extract a clean model name without the provider prefix
function modelShortName(model: string): string {
  const parts = model.split("/");
  return parts.length > 1 ? parts.slice(1).join("/") : model;
}

// Build a formatted roster string (compact table)
function buildRoster(config: SubAgentsConfig): string {
  const agents = Object.entries(config.agents);
  if (agents.length === 0) {
    return "No sub-agents configured. Add agents to sub-agents.json.";
  }

  // Compute column widths for a clean table
  const nameWidth = Math.max(8, ...agents.map(([name]) => name.length));
  const modelWidth = Math.max(8, ...agents.map(([, a]) => modelShortName(a.model).length));
  const providerWidth = Math.max(8, ...agents.map(([, a]) => providerFromModel(a.model).length));

  const innerWidth = nameWidth + modelWidth + providerWidth + 8;
  const sep = "\u2500".repeat(innerWidth);

  const lines: string[] = [
    "",
    "\u250C" + sep + "\u2510",
    "\u2502" + ` TEAM ROSTER`.padEnd(innerWidth) + "\u2502",
    "\u251C" + sep + "\u2524",
  ];

  // Header row
  const headerName = "Agent".padEnd(nameWidth);
  const headerModel = "Model".padEnd(modelWidth);
  const headerProvider = "Provider".padEnd(providerWidth);
  lines.push("\u2502 " + headerName + " \u2502 " + headerModel + " \u2502 " + headerProvider + " \u2502");

  lines.push("\u251C" + sep + "\u2524");

  for (const [name, agent] of agents) {
    const nameCol = name.padEnd(nameWidth);
    const modelCol = modelShortName(agent.model).padEnd(modelWidth);
    const providerCol = providerFromModel(agent.model).padEnd(providerWidth);
    lines.push("\u2502 " + nameCol + " \u2502 " + modelCol + " \u2502 " + providerCol + " \u2502");
  }

  lines.push("\u2514" + sep + "\u2518");
  lines.push("");
  lines.push(`${agents.length} agent${agents.length === 1 ? "" : "s"} configured.`);
  lines.push("");

  // Add descriptions below the table
  for (const [name, agent] of agents) {
    lines.push(`  ${name} \u2014 ${agent.description}`);
  }

  return lines.join("\n");
}

// Build a detailed view with personas
function buildDetailedRoster(config: SubAgentsConfig): string {
  const agents = Object.entries(config.agents);
  if (agents.length === 0) {
    return "No sub-agents configured. Add agents to sub-agents.json.";
  }

  const lines: string[] = ["", "=== TEAM ROSTER (DETAILED) ===", ""];

  for (const [name, agent] of agents) {
    lines.push(`\u2588\u2588\u2588 ${agent.label} (${name})`);
    lines.push(`    Provider: ${providerFromModel(agent.model)}`);
    lines.push(`    Model:    ${modelShortName(agent.model)}`);
    lines.push(`    Role:     ${agent.description}`);
    lines.push(`    Persona:  ${agent.persona}`);
    lines.push("");
  }

  lines.push(`${agents.length} agent${agents.length === 1 ? "" : "s"} configured.`);
  lines.push("Use 'delegate' tool to assign tasks, or /team for the compact view.");
  return lines.join("\n");
}

export default function (pi: ExtensionAPI) {
  const config = loadConfig();
  const agentNames = Object.keys(config.agents);

  // Register a tool so the orchestrator can query the roster programmatically
  pi.registerTool({
    name: "team_roster",
    label: "Show Team Roster",
    description:
      `Show all configured sub-agents and the model each one uses. ` +
      `Call this when you need to see which agents are available and what models they run. ` +
      `Returns a formatted roster. Available agents: ${agentNames.join(", ") || "none"}.`,
    promptSnippet: "Show the team roster — all sub-agents and their models",
    promptGuidelines: [
      "Call team_roster when you need to see which sub-agents are available and what models they use.",
    ],
    parameters: Type.Object({
      detailed: Type.Boolean({
        description: "If true, include full persona text for each agent. Default: false (compact table).",
        default: false,
      }),
    }),

    async execute(_toolCallId, params) {
      const text = params.detailed ? buildDetailedRoster(config) : buildRoster(config);
      return {
        content: [{ type: "text", text }],
        details: {
          agentCount: agentNames.length,
          agents: agentNames.map((name) => ({
            name,
            model: config.agents[name].model,
            label: config.agents[name].label,
          })),
        },
      };
    },
  });

  // /team — compact table view
  pi.registerCommand("team", {
    description: "Show all working agents and their models (compact table)",
    handler: async (_args, ctx) => {
      ctx.ui.notify(buildRoster(config), "info");
    },
  });

  // /team-detail — detailed view with personas
  pi.registerCommand("team-detail", {
    description: "Show all working agents with full details and personas",
    handler: async (_args, ctx) => {
      ctx.ui.notify(buildDetailedRoster(config), "info");
    },
  });
}
