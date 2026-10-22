# Writing A Panel Plugin — Playground

- **ID:** PLAYGROUND
- **Slug:** ats-110-playground-030-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading

A sandbox with Perses v0.54.0, Prometheus and the plugin builder in the namespace `perses`. It stays running so you
can explore the module's topic. Nothing to submit.

## Run it

```sh
astrona run -c .
astrona destroy ats-110-playground-030-01
```

`astrona destroy` takes the environment name (`metadata.name` = `ats-110-playground-030-01`), not
the config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (bootstrap only) |
| `bootstrap/prepare.sh` | Tools, CoreDNS names, Perses, and the module's builder |
| `manifests/` | Perses values, Prometheus and tester, builder manifests |
| `docs/overview.md` | What the environment contains and ideas to try |

The shared pieces of this folder are generated; change them in every
environment of the course, not only here (see the repository `CLAUDE.md`).
