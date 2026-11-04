# Render A Saved Dashboard In A React Application

The first module placed panels in the code of the app: every query and every panel was written by a developer. Teams that use Perses usually already have dashboards, built and edited in the Perses interface, and want the same dashboard inside their own page. This module shows how to load a saved dashboard and render it with the `Dashboard` component, and how its datasources are found.

Keep one sentence in mind: **a saved dashboard is JSON, `DashboardProvider` holds it, `Dashboard` draws it, and `DatasourceStoreProvider` finds the datasource each query names.**

The module has four parts. **What A Saved Dashboard Contains** reads the JSON: metadata, panels, layouts, variables and the duration. **Rendering A Dashboard** adds `DashboardProvider` and `Dashboard` to the providers you know. **Datasources At Three Levels** shows how a query finds its datasource in the dashboard, in the project or globally, and what the `DatasourceApi` has to implement for each. **When A Dashboard Does Not Render** gives a checklist for the failures you will meet. A graded lab follows the fourth part.

## Learning objectives

After this module you can:

- Read a Perses dashboard and say what `metadata`, `spec.panels`, `spec.layouts`, `spec.variables` and `spec.duration` hold.
- Explain how a layout item points at a panel with `$ref`.
- Load a dashboard from the Perses API and render it with `DashboardProvider` and `Dashboard`.
- Say which values of the saved dashboard start the time range, the refresh interval and the variables.
- Name the three places a datasource can be defined, and the order in which they are searched.
- Build the proxy URL for each of the three.
- Implement `getDatasource` and `listDatasources` for a project.
- Find why a saved dashboard does not render.

## Before you start

You should have finished the first module of this section. You need the providers, the `DatasourceApi` and the idea of a panel with a query. Variables from the previous module help, but this module does not depend on them.

Your playground has the same cluster as before: Perses v0.54.0 with the project `inventory`, the global datasource `prometheus`, the project datasource `inventory-prometheus` and a dashboard `overview`; Prometheus; the builder pod `app-builder`; and the nginx server `embed-app`. The app shows two panels written into the code, and its `DatasourceApi` knows global datasources only. Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
