# Section 020: Embedding Panels In A React Application

A Perses panel is a React component, so any React application can show one. It cannot stand alone, though: it needs a theme, a plugin registry, a time range, a place to find datasources and a list of queries. This section builds that setup step by step and connects it to a real Perses server, so the panels show live data without the browser ever talking to Prometheus.

**Topic covered:** embedding panels

## What you will learn

- The providers a panel needs, what each one supplies, and the order they nest in.
- The `DatasourceApi` interface: how panels find a datasource, and how `buildProxyUrl` sends their queries through the Perses proxy.
- Why the app serves itself and the Perses API from one origin.
- Rendering several panels, each with its own queries, under one time range and refresh interval.
- Using the `TimeSeriesChart` and `StatChart` panel plugins.

## The learning path

The module starts at its landing page, which also launches the playground. The playground has Perses, Prometheus, and an app built the way the official embedding guide writes it, with a hard-coded datasource.

### 1. Embed Perses Panels In A React Application

1. The Providers A Panel Needs
2. A DatasourceApi That Uses The Perses Proxy
3. Panels, Queries And The Time Range, followed by the lab **Embed Two Panels That Query Through Perses**
4. Summary

## Section capstone: Make An Embedded Dashboard Show Data

An embedded dashboard was moved to a new cluster, and both of its panels are empty. The app builds and loads. The faults sit between the browser and Prometheus: in the app's proxy URLs, in nginx, and in Perses itself. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS110.git -c sections/section-020/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-020/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-110-capstone-020
```
