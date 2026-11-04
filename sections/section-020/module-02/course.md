# Variables And Time Controls In An Embedded App

A page with fixed queries answers one question. Real dashboards let the reader choose: which service, which cluster, which period. Perses calls the first kind of choice a **variable** and the second the **time range**, and both are built from the same packages you used to embed the first panels.

This module adds both to the example app. Keep one sentence in mind: **a variable is a named value in a provider, and a query that contains its name is rewritten with the current value before it is sent.**

The module has four parts. **How Variables Work** explains the two variable kinds, how a name in a query is replaced, and what the formats `csv`, `regex` and `pipe` do. **Adding A Variable To The App** defines a list variable that reads its options from Prometheus and shows it with `VariableList`. **The Time Range In Depth** covers relative and absolute ranges, the ready-made controls, the refresh interval and the step of a query. **When A Variable Or A Panel Stays Empty** gives a checklist for the failures you will meet. A graded lab follows the fourth part.

## Learning objectives

After this module you can:

- Tell a text variable from a list variable, and say where each is defined.
- Write a query that uses `$name`, `${name}` and `${name:format}`, and say what each gives for one value and for several.
- Explain what the "all" value does and what `customAllValue` changes.
- Define a list variable with the `PrometheusLabelValuesVariable` plugin and show it with `VariableList`.
- Read and change the time range and refresh interval with `useTimeRange`, and use `TimeRangeControls`.
- Use `$__interval` and `$__rate_interval` in a Prometheus query.
- Find why a variable has no options or why a panel is empty.

## Before you start

You should have finished the first module of this section: you need the providers, the `DatasourceApi` and the two panels. You should read a PromQL selector such as `up{job="prometheus"}`.

Your playground has the same cluster as before: Perses v0.54.0, the builder pod `app-builder`, the nginx server `embed-app`, and a Prometheus server that scrapes two jobs, `prometheus` and `prometheus-copy`. Both jobs scrape the same server, so each has the same series under a different `job` label; that gives a variable two real values. The app shows two panels, and it has no variable and no time controls yet. Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
