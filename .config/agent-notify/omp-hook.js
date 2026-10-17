// Local desktop alerts only for the interactive main session, never subagents.
export default function (pi) {
  async function notify(ctx, event) {
    if (ctx.mode !== "tui" || ctx.agent.kind !== "main" || !process.env.TMUX_PANE) return;
    const result = await pi.exec(`${process.env.HOME}/.local/bin/agent-notify`, ["omp", event]);
    if (result.code !== 0) pi.logger.warn(`agent-notify: ${result.stderr}`);
  }
  pi.on("session_stop", async (_event, ctx) => {
    if (!ctx.hasPendingMessages()) await notify(ctx, "done");
  });
  pi.on("tool_approval_requested", async (_event, ctx) => { await notify(ctx, "attention"); });
  pi.on("plan_review_requested", async (_event, ctx) => { await notify(ctx, "attention"); });
  pi.on("tool_call", async (event, ctx) => {
    if (event.toolName === "ask") await notify(ctx, "attention");
  });
}
