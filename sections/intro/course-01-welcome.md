# Welcome To The Course

This course trains you for the **Embedded UI Packages & Plugin Development** part of the Astrona **Perses** training path. That part is 15% of the path. This page tells you who the course is for, what you can do at the end, which words and example setup it uses, and how its pages fit together.

## Who this course is for

You know your way around Kubernetes: namespaces, Deployments, Services, ConfigMaps, `kubectl exec` and `kubectl logs`. You can read a small React component written in TypeScript, and you know what `npm install` does. You do not need to know Perses well. Each new idea is explained the first time it appears.

## What you can do at the end

Perses is a dashboard server, but its user interface is also published as a set of npm packages, so other web applications can show Perses panels. Perses can also be extended with plugins. This course asks you to do both: build a React application that shows Perses panels, and write a panel plugin that Perses loads. It has three topics.

The first topic is **the Perses npm packages**. You will learn to:

- Name the `@perses-dev` packages and say what each one is for.
- Pin package versions that fit the Perses server and each other, and read an npm peer dependency error.
- Build a React application inside the cluster and serve it with nginx.

The second topic is **embedding panels in a React application**. You will learn to:

- Wrap a Perses panel in the providers it needs.
- Write a `DatasourceApi` that finds datasources on the Perses server and sends queries through the Perses proxy.
- Show several panels with their own queries and one shared time range.

The third topic is **writing a panel plugin**. You will learn to:

- Generate a plugin module with `percli plugin generate`.
- Write the plugin's CUE schema and React component.
- Build the plugin archive with `percli plugin build`, install it into Perses, and use it in a dashboard.

Everything is written for **Perses v0.54.0** and the `@perses-dev` packages of the same release.

## The words this course uses

The pages use Perses', npm's, React's and Kubernetes' own terms, because those are the words you meet in the code, the logs and the documentation. Each term gets a short, plain definition the first time it appears on a page. A few terms come back on almost every page, so here they are up front.

An **npm package** is a versioned bundle of JavaScript code from the npm registry. A **peer dependency** is a package that another package needs but does not install itself: your application must provide one copy that fits. A **provider** is a React component that makes a value, such as the time range, available to every component inside it. A **plugin** is the code that draws a panel or runs a query; Perses itself is built from plugins.

| Thing | What it is in this course |
| --- | --- |
| Panel | One chart or value on a dashboard, drawn by a panel plugin such as `TimeSeriesChart` |
| Datasource | A connection to a data backend; here a Prometheus server |
| Proxy | The Perses endpoint that forwards a panel's query to the datasource |
| Plugin module | One npm package with one or more plugins, built as an archive Perses can load |

## The example setup in your playground

Every playground and lab runs the same small setup. Perses runs in the namespace `perses`, with a project called `inventory` and a global datasource called `prometheus` that points at a Prometheus server in the namespace `observability`. A `tester` pod there sends test requests.

For the embedding topics, a builder pod with Node.js builds a small React application, and an nginx server shows it at `http://app.localtest.me:8081`. For the plugin topic, a builder pod with Node.js, `percli` and `cue` builds the example panel plugin `StatusBadge`, a coloured badge that shows one value. All builds run in the cluster, so your machine needs no Node.js. Many labs start with something broken on purpose. That is the material, not a fault in the course.

## How the course is laid out

The course has three sections. It starts with the packages, then uses them to embed panels, and ends with writing a plugin of your own.

| Section | What it covers |
| --- | --- |
| 010 | The Perses npm Packages |
| 020 | Embedding Panels In A React Application |
| 030 | Writing A Panel Plugin |

Each section has one or more **modules**, and each module teaches one skill. A module brings together four kinds of material:

| What | What it is for | Graded? |
| --- | --- | --- |
| **Reading** | A short landing page, a few chapters that teach one idea each, and a summary | No |
| **Playground** | A small cluster on your own machine, to try everything you read | No |
| **Lab** | A cluster in a starting state, a task, and a grader that checks your work | Yes |
| **Capstone** | The last lab in a section, with several faults at once | Yes |

The best order is simple: read the chapters with the playground open next to them, take each lab when a chapter sends you to it, and finish each section with its capstone. The next part of this page explains how a module's pages guide you through that order.

## How to read a page

A module starts with a **landing page**. It says what the module teaches, what you should know first, and the order of its chapters. At the bottom of the landing page you start the module's playground, and you keep it running while you read.

The chapters (the parts of a module) read like the chapters of a technical book. Each one opens with the problem it solves, explains one idea in connected paragraphs, and closes with what you now know. The hands-on steps sit right in the text: a sentence or two on what to run and why, the command, and then what the result shows. Run each step in your playground as you reach it. You learn more from one real result than from a page of text.

Every chapter ends with a box of common pitfalls, the mistakes people make most often with what the chapter taught, and how to spot them. Now and then a page also has a tip box with a habit or shortcut you can use again, well beyond that page. The two boxes look like this:

> [!TIP]
> **A tip.** A habit or shortcut you can use again, well beyond this one page.

> [!WARNING]
> **Common pitfalls.** The mistakes people make most often with what you just learned, and how to spot them. Every chapter ends with one.

When a graded lab tests what a chapter taught, that chapter ends with a **Your mission** section. It tells you what the lab asks, then gives every command you need, in order: pause the playground with `astrona stop`, start the lab with `astrona run`, and send your work for grading with `astrona submit`. Solve the lab on your own before you look at its solution. When the lab is done, remove it with `astrona destroy` and start the playground again with `astrona start`, so you can carry on reading where you left off.

The last page of every module is the **Summary**. It sums up what you learned in a few short paragraphs, organised by idea. It also ends the module's hands-on work: the Summary page removes the playground, so your machine is clean before the next module.

One rule holds on every page. Code blocks are exactly what you type. Never change a command to make it "look right". If the result is different from what the page describes, that difference is the lesson.
