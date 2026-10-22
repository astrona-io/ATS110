# Embed Perses Panels In A React Application

The official Perses guide for embedding shows one panel with a hard-coded Prometheus address. That is enough to see a chart, but not enough for a real application, which should use the datasources configured in Perses and should not need the browser to reach Prometheus at all. This module takes the guide's app and turns it into one that does both.

Keep one sentence in mind: **a panel draws, the providers around it supply everything else, and the `DatasourceApi` decides where its queries go.**

The module has three parts. **The Providers A Panel Needs** goes through the nested providers one by one. **A DatasourceApi That Uses The Perses Proxy** replaces the hard-coded datasource with one read from Perses, and sends every query through the Perses proxy. **Panels, Queries And The Time Range** puts several panels on the page with their own queries and one shared time range. A graded lab follows the third part.

## Learning objectives

After this module you can:

- Name the providers a Perses panel needs and say what each one supplies.
- Explain why the order of the providers matters.
- Implement the `DatasourceApi` interface from `@perses-dev/client` against a Perses server.
- Build proxy URLs in the format the Perses server serves them.
- Explain why the app and the Perses API share one origin.
- Render a `TimeSeriesChart` and a `StatChart` panel, each with its own query.
- Set the time range and the refresh interval for every panel at once.

## Before you start

You need to read and change short React components written in TypeScript, and to run commands with `kubectl exec`. You do not need Node.js on your machine; the builder pod runs every build.

Your playground has:

| Part | Where | What it is |
| --- | --- | --- |
| Perses v0.54.0 | namespace `perses` | The project `inventory` and the global datasource `prometheus`, the default, which forwards to Prometheus |
| Prometheus | namespace `observability` | The metrics server |
| `app-builder` | namespace `embed` | Node.js 22; the app in `/workspace/app`, installed and built |
| `embed-app` | namespace `embed` | nginx; serves the app at `http://app.localtest.me:8081` and forwards `/api/` and `/proxy/` to Perses |

The app in the playground follows the official guide: one panel, and a datasource written into the code that points at the public Prometheus demo server. Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
