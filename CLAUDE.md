# Writing style for this repo

All study text here (course pages, lab docs, READMEs, comments in YAML and
scripts) is for people learning a technical subject, often for a
certification exam. Many of them are not native English speakers and have no
university degree.

## Technical documentation in plain English

This is technical documentation. Say exactly what the system does, with the
real technical terms, in clear and simple English. Never hide a concept
behind a metaphor, a made-up name or a vague word: the reader must learn the
words they will meet in the product, the logs and the exam.

Strict guidelines:

1. Use the correct technical term every time (request, response, pod,
   namespace, Service, sidecar proxy, certificate, mTLS, JWT, listener). The
   first time a term appears in a file, define it in one plain sentence that
   says what it is and what it does. Spell out every acronym on first use.
2. No metaphors or analogies in explanations. Not "the communications
   officer", but "the sidecar proxy (Envoy)"; not "a signal", but "a
   request"; not "the planet", but "the namespace".
3. Simple sentences. Target a Flesch-Kincaid Grade Level of 8 or 9 for the
   prose around the terms. Keep sentences direct; split long sentences into
   two. No corporate buzzwords.
4. Use short paragraphs (max 3-4 sentences per paragraph).
5. Use the active voice ("istiod sends the configuration", not "the
   configuration is sent").

## How this applies to course material

- **Know which file you are in.** A module has a short landing page, a few
  deep-dive parts and a summary page. The landing page is a map: goals, what
  to know first, the order of the parts. The real teaching goes in the parts.
  The summary closes the module. A lab
  has a task, a step-by-step solution and a short intro. Keep each file to its
  job. Do not add "Prerequisite: ... Next: ..." navigation lines to pages;
  the landing page and the course outline already give the order.
- **Keep each part short.** One idea per part, about 5 to 8 minutes of
  reading and at most about 8 command blocks, so a learner can finish it with
  the playground in one sitting of about 15 minutes. Split at a natural seam
  where each half ends with something the learner has seen work. Never split
  only to hit a number. When you split, renumber the files, fix every "Part N"
  reference in the module and `astrona.yaml`.
- **Read like a book, not like a web page.** Each part reads as a chapter of
  a technical book. Open with a short paragraph on the problem it solves and
  why it matters. Link each paragraph to the next with a transition sentence.
  Close with a paragraph that sums up what the reader now knows and the
  question still open, before `## Common pitfalls` and the mission. Write
  explanations as prose; keep bullets for real lists (fields, ordered steps,
  options). Use `##` only when the topic changes and `###` only inside a long
  section, never for a single command. Weave hands-on steps into the text:
  one or two sentences on what to run and why, the command, the real output,
  then a sentence or two on what it shows.
- **The module ends with a summary.** The last page of every module is
  `course-0N-summary.md` with the title `# Summary`: a few short prose
  paragraphs on what the reader learned, organised by idea, optionally with
  one short list of key facts. It names no parts, modules, sections or
  chapters, and has no links, lab table, quiz or commands. Its last line is
  `<!-- astrona:playground:destroy -->` on its own line; the platform turns it
  into the step that removes the playground.
- **Every heading gets an intro.** A `##` section that has `###`
  subsections starts with one to three sentences that say what the section
  is about and why it matters, before the first `###`. Never put a `###`
  directly under a `##`.
- **Every module stands on its own.** Never refer to other sections or
  modules: no "see section 040", "as module 3 showed", "you met this in
  section 000", and no links to pages in another module. If the reader needs
  a fact from elsewhere, state the fact directly in one or two sentences.
  This also goes for parts of the same module: never write "Part 2 shows",
  "from Part 1" or "as in Part 3". Say the fact itself ("the commands below
  need the `scout` `DestinationRule` applied"). This includes the summary.
  The landing page does not have a "Where this fits" section.
- **Write words out in full.** Do not use informal short forms in prose:
  write "communications", "configuration", "repository", "administrator",
  "for example" and "that is", never "comms", "config", "repo", "admin",
  "e.g." or "i.e.". Names in code, commands and file paths stay as they are.
- **Exam terms stay.** The product's own names are what the reader must learn
  (for example a resource kind, a field, a command). Use them as they are and
  define each one in plain technical words the first time it appears in a
  file. Spell out acronyms on first use, with a short plain meaning.
- **The space theme is only for examples.** Space appears in two places and
  nowhere else: the names of the example workloads (the Starfleet: `bridge`,
  `scout`, `shuttle`, `probe`, the `starfleet` and `outpost` namespaces) and
  the short scenario that opens a lab task or a practice exercise (for
  example "the `drifter` in `outpost` must keep reaching the probe"). The
  explanation around an example is plain technical text: write "the
  `shuttle` pod sends a request to the `probe` Service", never "the shuttle
  sends a signal to the probe ship". Do not address the reader as an
  astronaut, and do not use space metaphors (communications officer, mission
  control, badge, airlock, guest list, star chart) for Istio or Kubernetes
  concepts. Titles of pages and labs name the technical task ("Require mTLS
  With PeerAuthentication"), not a space story.
- **Show one real example before the rule.** Start with a concrete case the
  reader can run, then give the general rule.
- **Say which part does the work.** Readers often mix up the parts of a system
  that sit close together. Whenever something happens, say which component
  did it.
- **Never change code to fit the style.** Commands, configuration files, field
  names, resource names, log lines and command output stay exactly as they
  are. They were run and checked on a real system. Never make up command
  output. If you shorten it, say that you did.
- **Prose only.** The grade-level and sentence rules apply to explanations.
  They do not apply to code blocks, tables of field names or reference lists
  (those may stay short and dense).
- **Keep the page furniture the same.** Hands-on steps are part of the prose
  (see "Read like a book"), not boxes or headings of their own. A `> [!TIP]` box is
  only for a real tip: advice the reader can reuse beyond this one step (a
  habit, a shortcut, how to spot a problem, an exam habit). Everything else
  is a normal sentence: notes about the current step ("if the log line is
  old, run it again"), background facts, optional extra steps, and plain
  information. Never a command snippet, never two in a row, and most pages
  need zero or one tip. Each part ends with a
  `## Common pitfalls` `> [!WARNING]` block for that part only. Use a Mermaid
  diagram for a flow, an order or a state change, keep it under about 12
  boxes, and follow it with one sentence that says what it shows.
- **Labs come right after the part they practise.** Do not collect all
  graded labs at the end of a module. In `astrona.yaml`, put each lab (its
  `question.md` reading and the `lab` entry) right after the reading part it
  tests. If a part teaches a gradeable skill and no lab covers it, create a
  new lab. That part then ends with a `## Your mission: <lab title>` section:
  one sentence on what the reader can now do, one on what the mission asks,
  then pause the playground (`astrona stop <playground name>`), the
  `astrona run` and `astrona submit` commands, and finally
  `astrona destroy <lab name>` plus `astrona start <playground name>`.
- **Renew the playground before hands-on work.** Every reading part that
  runs commands has `<!-- astrona:playground:renew -->` exactly once, on its
  own line, right before the first hands-on step (the first "Save this as"
  or the first command block), so the playground timer is reset before the
  learner needs the playground. Not on landing pages (they carry
  `<!-- astrona:playground -->`), summary pages (they carry
  `<!-- astrona:playground:destroy -->`) or pages without commands.
- **Mermaid without HTML.** The platform renders Mermaid with HTML labels
  switched off, so `<br/>` and any other HTML tag break the drawing. Rules:
  - One line per box, no `<br/>`, no HTML. Keep the box to the thing's name
    (`"scout-v2"`, `"istiod"`, `"Service: scout"`).
  - Put the logic on the arrows: `E -->|"version: v2"| P2`,
    `I -->|"CDS"| C`, `A -->|"end-user: jason"| B`. Keep edge labels short.
  - Quote every label. Prefer `flowchart TB`; use `LR` only for a short chain.
  - Sequence diagrams: short participant aliases (`participant S as shuttle`)
    and short message text.
  - Anything longer (cluster names, full hostnames) goes in the sentence under
    the diagram.
- **Every course starts with an Introduction.** It lives in `sections/intro/`
  and is the first entry in `astrona.yaml` (`id: module-intro`, title
  "Introduction"). It has exactly these four pages, in this order:
  - `README.md`, `# Introduction`: what the introduction covers and its three
    pages, named in prose (no links), ending with the topic the course starts
    with.
  - `course-01-welcome.md`, `# Welcome To The Course`: who the course is for,
    the exam domain and what the reader can do at the end, the words the
    course uses, the example app, how the course is laid out and how to read
    a page.
  - `course-02-get-your-machine-ready.md`, `# Get Your Machine Ready`: the
    tools to install, the `astrona` commands used every day, and what to do
    when a start goes wrong.
  - `course-03-how-this-course-is-made.md`, `# How This Course Is Made`: how
    content is written and checked, the maintainers, how to report a mistake,
    and the license.
  The Introduction teaches no product content and has no playground, labs or
  summary. Its only links are the repository's contributors page, issues
  page and license.
- **No links to other course files.** A course page (every reading listed in
  `astrona.yaml`, the playground guide `docs/overview.md`, and a lab's
  `question.md` and `solution.md`) never links to or points the reader at
  another page or file of the repository: no links to parts, summaries,
  labs, `question.md`, other modules, sections or the Introduction, and no
  "see `practice.md`" or "open `config.yaml`". The platform shows the pages in
  the order of `astrona.yaml`, so a link only adds a second, often wrong,
  path. Name a thing in plain words when the reader needs it ("the task is on
  the next page"), and state a fact on the page itself instead of sending the
  reader somewhere else. Repository files for authors (the root `README.md`,
  a lab's or playground's `README.md`) may link.
- **No links to outside sources.** Course pages, labs and playground docs do
  not link to or point at outside websites (the one exception is the
  `resources` field of a lab entry in `astrona.yaml`) (official docs, GitHub, blogs,
  RFCs), and they have no "Reference" or "Official docs" lists. Everything the
  reader needs is explained on the page itself. Not affected: addresses the
  reader actually uses in a command or browser (`http://127.0.0.1:9080`,
  `curl https://httpbin.org`), and the Introduction's contributors and
  "report a mistake" links.
- **Configuration goes to a file first.** Whenever the reader should apply
  YAML (course parts, playground docs, labs), use three separate steps:
  1. "Save this as `virtualservice-scout.yaml`:" followed by a plain
     ` ```yaml ` block with only the YAML. No `cat > file <<'EOF'`, no
     `kubectl apply -f - <<EOF`, no shell around it.
  2. "Apply it:" followed by a ` ```sh ` block with only
     `kubectl apply -f virtualservice-scout.yaml`.
  3. "Then check the result:" followed by the check commands, if any.
  The file name says the kind and the object. If a value must come from the
  reader's cluster (an IP address), use a placeholder like `<PARTNER>` in the
  YAML and say how to get the value (`echo $PARTNER`); never put shell
  variables inside YAML. Apply an object the first time its YAML appears; do
  not show it once "to read" and paste it again later. Never tell the reader
  to apply something from the playground's `examples/` folder: they start the
  playground with `astrona run`, so that folder is not on their machine.
- **Helpers have readable names.** Shell helper functions and variables use
  names that say what they do (`check_route`, `count_versions`,
  `$SERVICE_URL`), never single letters.


## About this repo (ATS110 only)

Everything above is general and can be copied to other course repositories. This
section is only true for this one.

### What the student is trying to learn

- **The goal:** master the **Embedded UI Packages & Plugin Development** domain
  of the **Perses** training path (`ATP021`). It is 15% of the path. There is
  no official Perses certification exam; the path's domains and weights are
  Astrona's own, set in `ATP021/path.yaml`.
- **What the domain really tests:** using the Perses npm packages outside the
  Perses server, and extending Perses with a plugin. The student must *do*
  things: pin package versions that fit together, build a React app that
  renders Perses panels with data from a Perses datasource, generate, build
  and install a panel plugin, and use it in a dashboard. Every fix is proved
  by a build that succeeds, an app that is served, a query that answers, or
  a plugin that Perses lists and validates.
- **The sections:**

  | Section | Title | Topic |
  | --- | --- | --- |
  | 010 | The Perses npm Packages | Packages and versions |
  | 020 | Embedding Panels In A React Application | Embedding |
  | 030 | Writing A Panel Plugin | Plugins |

- **The versions:** Perses **v0.54.0** (Helm chart `perses` **0.23.3**,
  Helm **3.22.1**), `percli` v0.54.0, `cue` **v0.17.1**, Node.js
  **22** (`node:22.23.4-alpine3.24`), nginx `1.31.8-alpine`. npm packages,
  pinned exactly:

  | Package | Version | Why this version |
  | --- | --- | --- |
  | `@perses-dev/client`, `components`, `plugin-system`, `dashboards`, `explore` | `0.54.0` | Same release as the server |
  | `@perses-dev/spec` | `0.2.0` | The version those packages depend on |
  | `@perses-dev/prometheus-plugin` | `0.58.0` | `Prometheus-0.58.0` ships in the Perses v0.54.0 archive |
  | `@perses-dev/timeseries-chart-plugin` | `0.13.0` | `TimeSeriesChart-0.13.0` ships with v0.54.0 |
  | `@perses-dev/stat-chart-plugin` | `0.13.0` | `StatChart-0.13.0` ships with v0.54.0 |
  | `react`, `react-dom` | `18.3.1` | Peer range `^17.0.2 \|\| ^18.0.0`; React 19 is not supported |
  | `@mui/material` | `6.5.0` | Peer range `^6.1.10` |
  | `@tanstack/react-query` | `4.44.0` | Peer range `^4.39.1` |
  | `echarts` | `5.5.0` | The plugins require exactly `5.5.0` |
  | `vite`, `@vitejs/plugin-react`, `typescript` | `6.4.5`, `4.7.0`, `5.9.3` | Build tools for the example app |

- **The main sources:** `docs/embedding-panels.md`,
  `docs/ui-package-architecture.md`, `docs/plugins/creation.md`,
  `docs/configuration/load-plugin.md` and the `percli plugin` source
  (`internal/cli/cmd/plugin/`) in `perses/perses` at tag `v0.54.0`, and the
  package metadata on registry.npmjs.org.

### Facts read from the source (v0.54.0) that the pages rely on

- **`@perses-dev/core` is deprecated** (`docs/ui-package-architecture.md`):
  use `@perses-dev/spec` and `@perses-dev/client`. `@perses-dev/plugin-system`
  0.54.0 still depends on `@perses-dev/core` **0.53.0** internally. The example
  app never imports `core`, and a grader rejects it as a direct dependency.
- **The embedding guide is older than the packages.** It imports
  `DatasourceApi` from `@perses-dev/dashboards`; in 0.54.0 it is exported by
  `@perses-dev/client` (`dist/model/datasource-api.d.ts`), with an optional
  `buildProxyUrl({ project, dashboard, name })`. `DurationString` and
  `TimeRangeValue` come from `@perses-dev/spec`. The pages use the real
  locations and say once that the guide differs.
- **The provider props** match the guide: `PluginRegistry`
  (`pluginLoader`, `defaultPluginKinds`), `TimeRangeProvider` (`timeRange`,
  `refreshInterval`, `setTimeRange`, `setRefreshInterval`),
  `DatasourceStoreProvider` (`dashboardResource`, `datasourceApi`),
  `DataQueriesProvider` (`definitions`), `Panel` (`definition`,
  `panelOptions.hideHeader`).
- **The datasource proxy** is `/proxy/globaldatasources/<name>/…`,
  `/proxy/projects/<project>/datasources/<name>/…` and
  `/proxy/projects/<project>/dashboards/<dashboard>/datasources/<name>/…`
  (`internal/api/impl/proxy/proxy.go`). An `HTTPProxy` with no
  `allowedEndpoints` allows every request.
- **Plugin archives:** `percli plugin build` runs `npm ci` only when
  `node_modules` is missing (the generated module has no lockfile, so run
  `npm install` first), then `npm run build`, then `cue mod tidy` (so the `cue`
  binary must be on the PATH and the CUE registry reachable), and writes
  `<mf-manifest name>-<package version>.tar.gz` in the module folder.
  `--archive-format` takes `tar.gz`, `tar` or `zip`.
- **`percli plugin generate`** takes `--module.org`, `--module.name`,
  `--plugin.type` (`Datasource`, `TimeSeriesQuery`, `TraceQuery`,
  `ProfileQuery`, `LogQuery`, `Variable`, `Panel`, `Explore`),
  `--plugin.name` and `--plugin.display-name`; its templates are embedded in
  `percli`, so it works offline. The panel template writes
  `schemas/panels/<name>/<name>.cue` (package `model`), a JSON example, and
  `src/panels/<name>/` with the plugin, component, types and settings editor.
- **Loading plugins:** at start Perses extracts every archive in
  `plugin.archive_path` (default `/etc/perses/plugins-archive` in the
  container, where the bundled plugins already are) into `plugin.path`
  (default `/etc/perses/plugins`, an `emptyDir` in the chart) and serves the
  list at `/api/v1/plugins`. The chart accepts extra `volumes` and
  `volumeMounts`; the course mounts one archive file with `subPath` so the
  bundled archives stay visible.

### Status: built, not yet run

Nothing here has been run. Until a maintainer runs every environment:

- Pages describe results in words. Do not add `text` output blocks until the
  output comes from a real run.
- The first things to check, in order:
  1. that `vite build` of the example app succeeds with these exact versions
     (memory: the builder has a 3 GiB limit and `--max-old-space-size=2048`);
  2. that `percli plugin generate` with `--plugin.name=status-badge` names the
     folders `status-badge` and the plugin `StatusBadge`, and that the module
     name `status-badge` gives the archive `StatusBadge-0.1.0.tar.gz`;
  3. that `cue mod tidy` inside the builder reaches the CUE registry;
  4. that a `subPath` mount of one file into `/etc/perses/plugins-archive`
     keeps the bundled plugins (`TimeSeriesChart` must stay listed);
  5. the JSON shape of `/api/v1/plugins` (graders look for
     `metadata.name == "StatusBadge"` and fall back to a text match);
  6. that Perses refuses a dashboard whose `StatusBadge` spec breaks the CUE
     schema (graders expect a non-2xx answer).
- No grader uses a browser. Embedding labs are graded from the built files,
  the served page, and a query sent through the app's own origin.

### Terms, not metaphors

| Term | First-use definition (example wording) |
| --- | --- |
| npm package | A versioned bundle of JavaScript code from the npm registry, installed with `npm install` into `node_modules` |
| Peer dependency | A package another package needs but does not install itself; the app must provide one compatible copy |
| `@perses-dev/spec` / `client` | The open specification types / the API types and helpers for talking to a Perses server |
| `@perses-dev/components` / `plugin-system` / `dashboards` | Shared UI components / plugin loading and runtime state (time range, variables, datasources) / dashboard providers and the `Panel` component |
| Provider | A React component that makes a value available to every component inside it, for example the time range |
| `DatasourceApi` | The interface an app implements so panels can find datasources and build proxy URLs |
| Plugin module | One npm package that holds one or more Perses plugins, built as an archive |
| Panel plugin | A plugin that draws query results, for example `TimeSeriesChart` |
| Module federation | A way for a web page to load JavaScript modules from a separate build at run time; Perses loads plugins this way |
| CUE schema | The file in package `model` that Perses uses to validate a plugin's `spec` when a dashboard is saved |

### The example workloads

| Name | What it is |
| --- | --- |
| Perses (namespace `perses`) | Perses v0.54.0, Service `perses` on `8080`; project `inventory`; GlobalDatasource `prometheus` (default, `HTTPProxy` to `http://prometheus.observability:9090`) |
| Prometheus, `tester` (namespace `observability`) | As in ATS106 |
| `app-builder` (namespace `embed`, sections 010 and 020) | Node.js 22; the app in `/workspace/app` (an `emptyDir`, copied from the ConfigMap `app-source` at pod start: a restart loses edits and `node_modules`); `npm run deploy` copies `dist/` to the volume `app-dist` at `/srv/dist` |
| `embed-app` (namespace `embed`) | nginx serving `app-dist`, Service `embed-app` port `8081`, forwards `/api/` and `/proxy/` to Perses. Reached as `http://app.localtest.me:8081` |
| `plugin-builder` (namespace `perses`, section 030) | Node.js 22 with `percli` and `cue` in `/tools`; workspace `/workspace` (`emptyDir`); volume `plugin-artifacts` at `/artifacts` |
| `StatusBadge` | The example panel plugin: a coloured badge with the last value of the first series, and `label`, `warning`, `critical` (and `unit` from version 0.2.0) |

Pages send files into the builder pods with a helper, never with `kubectl cp`:

```sh
copy_to_builder() { kubectl -n embed exec -i deploy/app-builder -- sh -c "cat > /workspace/app/$2" < "$1"; }
```

### Environment facts the text must respect

- **Two addresses:** `http://perses.localtest.me:8080` (port-forward
  `svc/perses 8080:8080`) and `http://app.localtest.me:8081` (port-forward
  `-n embed svc/embed-app 8081:8081`). Inside the cluster, CoreDNS
  `rewrite stop` blocks with the answer name rewritten back send both names to
  their Services. Never the one-line `rewrite name` form.
- **Builds run in the cluster**, so the reader's machine needs no Node.js.
  The first `npm install` downloads several hundred megabytes from
  registry.npmjs.org.
- **The app talks to one origin.** nginx forwards `/api/` and `/proxy/` to
  Perses, so the browser never needs CORS and never reaches Prometheus
  directly.
- **Installing a plugin restarts Perses** (`helm upgrade --reuse-values` with
  the plugin values file). The archive must exist on the volume before the
  upgrade: a `subPath` that does not exist yet is created as an empty folder.
- **Generated plumbing.** `bootstrap/`, `testing/`, `solution/`,
  `validation/`, `manifests/`, `config.yaml`, `prerequisites.md` and the author
  `README.md` of all nine environments come from a generator kept outside the
  repository. Change a shared piece in every environment, not only one.

### Lab metadata in `astrona.yaml`

`training:` block: id `ATS110`, domain `Embedded UI Packages & Plugin
Development`, weight `15`. Lab entries carry `title`, `path`, `difficulty`,
`estimated_duration`, `topic`, `task_kind`, `tags`, `learning_goals`,
`resources`, in that order.

- `topic`: exactly one of `packages`, `embedding`, `plugins`.
- `task_kind`: `build`, `troubleshooting` or `migration`.
- `tags`: 4 to 8, only from: `npm`, `peer-dependencies`, `package-versions`,
  `vite`, `react`, `providers`, `datasource-api`, `proxy`, `panel`,
  `time-range`, `plugin-module`, `panel-plugin`, `cue-schema`,
  `percli-plugin`, `plugin-archive`, `module-federation`, `helm-values`,
  `nginx`.
- `resources`: 1 to 4 pages on `perses.dev` or files in
  `github.com/perses/perses` at `v0.54.0`.

### Running things

```bash
astrona run --git ssh://git@github.com/astrona-io/ATS110.git -c sections/section-010/module-01/playground
astrona destroy ats-110-playground-010-01
astrona run --git ssh://git@github.com/astrona-io/ATS110.git -c sections/section-010/module-01/labs/lab-01
astrona submit -c sections/section-010/module-01/labs/lab-01
astrona destroy ats-110-lab-010-01
```

Names: `ats-110-playground-<section>-<module>`, `ats-110-lab-<section>-<module>`,
`ats-110-capstone-<section>`. Graders reject the plausible but wrong fix:
`--legacy-peer-deps` or `--force` to silence peer conflicts, a dependency on
the deprecated `@perses-dev/core`, an app that calls Prometheus directly,
mounting a volume over the whole plugin archive folder, and a schema that
accepts anything.
