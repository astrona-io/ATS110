# ATS110 — Embedded UI Packages & Plugin Development (Perses)

Course material for the **Embedded UI Packages & Plugin Development** domain
of the Astrona Perses training path ([ATP021](https://github.com/astrona-io/ATP021)),
which is **15% of the path**. Written for **Perses v0.54.0** and the
`@perses-dev` npm packages of the same release.

> **Status: draft, not yet run.** Every page, playground and lab was written
> from the Perses v0.54.0 documentation, its source code and the published npm
> packages. None has been started on a cluster, and no lab has passed
> `astrona test` yet. See `CLAUDE.md` for the first things to check.

The course opens with an Introduction in `sections/intro/`. Each section has
modules (landing page, parts, summary, playground, a graded lab placed right
after the part it tests) and a capstone.

---

## Sections

| Section | Title | Modules | Labs | Topic |
| --- | --- | --- | --- | --- |
| [010](sections/section-010) | The Perses npm Packages | 2 | 2 + capstone | Packages and versions |
| [020](sections/section-020) | Embedding Panels In A React Application | 3 | 3 + capstone | Embedding |
| [030](sections/section-030) | Writing A Panel Plugin | 3 | 3 + capstone | Plugins |

---

## Modules

| Module | Reader | Parts | Labs |
| --- | --- | --- | --- |
| 010-01 | [Use The Perses npm Packages](sections/section-010/module-01/course.md) | 4 | [lab-01](sections/section-010/module-01/labs/lab-01) |
| 010-02 | [Keep The Dependencies Reproducible](sections/section-010/module-02/course.md) | 4 | [lab-01](sections/section-010/module-02/labs/lab-01) |
| 020-01 | [Embed Perses Panels In A React Application](sections/section-020/module-01/course.md) | 4 | [lab-01](sections/section-020/module-01/labs/lab-01) |
| 020-02 | [Add Variables And Time Controls To An Embedded App](sections/section-020/module-02/course.md) | 4 | [lab-01](sections/section-020/module-02/labs/lab-01) |
| 020-03 | [Render A Saved Dashboard In A React Application](sections/section-020/module-03/course.md) | 4 | [lab-01](sections/section-020/module-03/labs/lab-01) |
| 030-01 | [Write And Install A Panel Plugin](sections/section-030/module-01/course.md) | 4 | [lab-01](sections/section-030/module-01/labs/lab-01) |
| 030-02 | [Constrain And Test Plugin Schemas](sections/section-030/module-02/course.md) | 4 | [lab-01](sections/section-030/module-02/labs/lab-01) |
| 030-03 | [Query And Datasource Plugins](sections/section-030/module-03/course.md) | 4 | [lab-01](sections/section-030/module-03/labs/lab-01) |

## Capstones

| Capstone | Scenario | Faults |
| --- | --- | --- |
| [010](sections/section-010/capstone/labs/lab-01) | Rescue A Starter App That Never Built | React 19, ECharts 5.6.0, a Vite base path nginx does not serve |
| [020](sections/section-020/capstone/labs/lab-01) | Make An Embedded Dashboard Show Data | proxy URL pointing at Prometheus, no `/proxy/` route in nginx, no default datasource `prometheus` |
| [030](sections/section-030/capstone/labs/lab-01) | Ship Version 0.2.0 Of A Panel Plugin | an optional schema field, a version bump, and swapping the mounted archive |

---

## The lab environment

Every environment is a **kind** cluster with Perses v0.54.0 (Helm chart 0.23.3),
Prometheus, and one builder pod: `app-builder` plus an nginx server in the
namespace `embed` for sections 010 and 020, or `plugin-builder` (with `percli`
and `cue`) in the namespace `perses` for section 030. All builds run in the
cluster; the reader's machine needs no Node.js. Perses answers at
`http://perses.localtest.me:8080` and the app at `http://app.localtest.me:8081`,
through port-forwards on the reader's machine and CoreDNS rewrites inside the
cluster. Builds download npm packages and need internet access.

```bash
astrona run --git ssh://git@github.com/astrona-io/ATS110.git -c sections/<section>/<module>/playground
astrona run --git ssh://git@github.com/astrona-io/ATS110.git -c sections/<section>/<module>/labs/lab-01
astrona submit -c sections/<section>/<module>/labs/lab-01
astrona destroy <name>
```

Graders reject the plausible but wrong fix: `--legacy-peer-deps`, a direct
dependency on the deprecated `@perses-dev/core`, an app that sends the browser
to Prometheus, a mount that hides the bundled plugins, and a schema that
accepts anything.
