---
name: m365-agents-ts
description: |
  Microsoft 365 Agents SDK for TypeScript/Node.js. Build multichannel agents for Teams/M365/Copilot Studio with AgentApplication routing, Express hosting, streaming responses, and Copilot Studio client integration. Triggers: "Microsoft 365 Agents SDK", "@microsoft/agents-hosting", "AgentApplication", "startServer", "streamingResponse", "Copilot Studio client", "@microsoft/agents-copilotstudio-client".
package: "@microsoft/agents-hosting, @microsoft/agents-hosting-express, @microsoft/agents-activity, @microsoft/agents-copilotstudio-client"
disable-model-invocation: true
---

# Microsoft 365 Agents SDK (TypeScript)

Build enterprise agents for Microsoft 365, Teams, and Copilot Studio using the Microsoft 365 Agents SDK with Express hosting, AgentApplication routing, streaming responses, and Copilot Studio client integrations.

## Before implementation
- Use the microsoft-docs MCP to verify the latest API signatures for AgentApplication, startServer, and CopilotStudioClient. The SDK moves quickly; the samples below are shape, not source of truth.
- Confirm package versions on npm before wiring up samples or templates.

Environment: `PORT`, `AZURE_RESOURCE_NAME` / `AZURE_API_KEY` / `AZURE_OPENAI_DEPLOYMENT_NAME`, `TENANT_ID` / `CLIENT_ID` / `CLIENT_SECRET`, `COPILOT_ENVIRONMENT_ID` / `COPILOT_SCHEMA_NAME` / `COPILOT_CLIENT_ID` / `COPILOT_BEARER_TOKEN`.

## Core Workflow: Express-hosted AgentApplication

```typescript
import { AgentApplication, TurnContext, TurnState } from "@microsoft/agents-hosting";
import { startServer } from "@microsoft/agents-hosting-express";

const agent = new AgentApplication<TurnState>();

agent.onConversationUpdate("membersAdded", async (context: TurnContext) => {
  await context.sendActivity("Welcome to the agent.");
});

agent.onMessage("hello", async (context: TurnContext) => {
  await context.sendActivity(`Echo: ${context.activity.text}`);
});

startServer(agent);
```

## Streaming responses with Azure OpenAI

```typescript
import { azure } from "@ai-sdk/azure";
import { AgentApplication, TurnContext, TurnState } from "@microsoft/agents-hosting";
import { startServer } from "@microsoft/agents-hosting-express";
import { streamText } from "ai";

const agent = new AgentApplication<TurnState>();

agent.onMessage("poem", async (context: TurnContext) => {
  context.streamingResponse.setFeedbackLoop(true);
  context.streamingResponse.setGeneratedByAILabel(true);
  context.streamingResponse.setSensitivityLabel({
    type: "https://schema.org/Message",
    "@type": "CreativeWork",
    name: "Internal",
  });

  await context.streamingResponse.queueInformativeUpdate("starting a poem...");

  const { fullStream } = streamText({
    model: azure(process.env.AZURE_OPENAI_DEPLOYMENT_NAME || "gpt-4o-mini"),
    system: "You are a creative assistant.",
    prompt: "Write a poem about Apollo.",
  });

  try {
    for await (const part of fullStream) {
      if (part.type === "text-delta" && part.text.length > 0) {
        await context.streamingResponse.queueTextChunk(part.text);
      }
      if (part.type === "error") {
        throw new Error(`Streaming error: ${part.error}`);
      }
    }
  } finally {
    await context.streamingResponse.endStream();
  }
});

startServer(agent);
```

## Invoke activity handling

```typescript
import { Activity, ActivityTypes } from "@microsoft/agents-activity";
import { AgentApplication, TurnContext, TurnState } from "@microsoft/agents-hosting";

const agent = new AgentApplication<TurnState>();

agent.onActivity("invoke", async (context: TurnContext) => {
  const invokeResponse = Activity.fromObject({
    type: ActivityTypes.InvokeResponse,
    value: { status: 200 },
  });

  await context.sendActivity(invokeResponse);
  await context.sendActivity("Thanks for submitting your feedback.");
});
```

## Copilot Studio client (Direct to Engine)

Construct `CopilotStudioClient(settings, tokenProvider)` with `environmentId` / `schemaName` / `clientId` and an async token provider. **`startConversationAsync` / `askQuestionAsync` are deprecated**; look up the current streaming API (`startConversationStreaming` / `sendActivityStreaming`, which return activities rather than a conversation object) via the microsoft-docs MCP before writing calls. WebChat integration goes through `CopilotStudioWebChat.createConnection(client, opts)` as a Direct Line substitute.

Reuse CopilotStudioClient instances and cache tokens in the token provider. Call `endStream` in a `finally` block.

## References

- [references/acceptance-criteria.md](references/acceptance-criteria.md): import paths, hosting pipeline, streaming, and Copilot Studio patterns (CORRECT / INCORRECT examples). Check the result against it before finishing.
- https://learn.microsoft.com/en-us/microsoft-365/agents-sdk/ and https://github.com/microsoft/Agents/tree/main/samples/nodejs
