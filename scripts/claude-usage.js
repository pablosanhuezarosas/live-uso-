#!/usr/bin/env node
// Reads the most recently active Claude Code session transcript and computes
// real cost (from exact token usage Claude Code writes per message) using
// current official per-model pricing. Cost is a sum across the session;
// context-window usage is a snapshot from the last message only.

const fs = require("fs");
const path = require("path");
const os = require("os");

const PROJECTS_DIR = path.join(os.homedir(), ".claude", "projects");

// $ per million tokens: [input, output]. Intro pricing where applicable (through 2026-08-31).
const PRICING = {
  "claude-sonnet-5": { in: 2.0, out: 10.0, ctx: 1_000_000 },
  "claude-sonnet-4-6": { in: 3.0, out: 15.0, ctx: 1_000_000 },
  "claude-sonnet-4-5": { in: 3.0, out: 15.0, ctx: 1_000_000 },
  "claude-opus-4-8": { in: 5.0, out: 25.0, ctx: 1_000_000 },
  "claude-opus-4-7": { in: 5.0, out: 25.0, ctx: 1_000_000 },
  "claude-opus-4-6": { in: 5.0, out: 25.0, ctx: 1_000_000 },
  "claude-opus-4-5": { in: 5.0, out: 25.0, ctx: 1_000_000 },
  "claude-haiku-4-5": { in: 1.0, out: 5.0, ctx: 200_000 },
  "claude-fable-5": { in: 10.0, out: 50.0, ctx: 1_000_000 },
  "claude-mythos-5": { in: 10.0, out: 50.0, ctx: 1_000_000 },
};
const DEFAULT_PRICE = { in: 3.0, out: 15.0, ctx: 1_000_000 };

function findLatestTranscript() {
  let latest = null;
  let latestMtime = 0;
  const projectDirs = fs.readdirSync(PROJECTS_DIR, { withFileTypes: true });
  for (const dir of projectDirs) {
    if (!dir.isDirectory()) continue;
    const dirPath = path.join(PROJECTS_DIR, dir.name);
    let files;
    try {
      files = fs.readdirSync(dirPath);
    } catch {
      continue;
    }
    for (const f of files) {
      if (!f.endsWith(".jsonl")) continue;
      const fullPath = path.join(dirPath, f);
      const stat = fs.statSync(fullPath);
      if (stat.mtimeMs > latestMtime) {
        latestMtime = stat.mtimeMs;
        latest = fullPath;
      }
    }
  }
  return latest;
}

function priceFor(model) {
  return PRICING[model] || DEFAULT_PRICE;
}

function main() {
  const file = findLatestTranscript();
  if (!file) {
    console.log(JSON.stringify({ error: "no_transcript" }));
    return;
  }

  const lines = fs.readFileSync(file, "utf8").split("\n").filter(Boolean);

  let totalCost = 0;
  let lastUsage = null;
  let lastModel = null;

  for (const line of lines) {
    let entry;
    try {
      entry = JSON.parse(line);
    } catch {
      continue;
    }
    const usage = entry?.message?.usage;
    const model = entry?.message?.model;
    if (!usage || !model) continue;

    const price = priceFor(model);
    const inputTok = usage.input_tokens || 0;
    const outputTok = usage.output_tokens || 0;
    const cacheRead = usage.cache_read_input_tokens || 0;
    const cache5m = usage.cache_creation?.ephemeral_5m_input_tokens ?? usage.cache_creation_input_tokens ?? 0;
    const cache1h = usage.cache_creation?.ephemeral_1h_input_tokens ?? 0;

    totalCost +=
      (inputTok * price.in) / 1e6 +
      (outputTok * price.out) / 1e6 +
      (cache5m * price.in * 1.25) / 1e6 +
      (cache1h * price.in * 2) / 1e6 +
      (cacheRead * price.in * 0.1) / 1e6;

    lastUsage = usage;
    lastModel = model;
  }

  let ctxPct = 0;
  if (lastUsage && lastModel) {
    const price = priceFor(lastModel);
    const ctxTokens =
      (lastUsage.input_tokens || 0) +
      (lastUsage.cache_creation_input_tokens || 0) +
      (lastUsage.cache_read_input_tokens || 0);
    ctxPct = Math.round((ctxTokens / price.ctx) * 100);
  }

  console.log(
    JSON.stringify({
      cost_usd: Number(totalCost.toFixed(4)),
      ctx_pct: ctxPct,
      model: lastModel,
    })
  );
}

main();
