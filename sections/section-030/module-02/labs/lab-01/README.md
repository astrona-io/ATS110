---
estimated_duration: 30m
---

# Constrain And Test The StatusBadge Schema

- **ID:** LAB
- **Slug:** ats-110-lab-030-02
- **Author:** Paris Nakita Kejser
- **Type:** Astrona graded lab

Read `question.md` for the task; `solution.md` is the walkthrough.

## Run it

```sh
astrona run -c .
astrona submit
astrona destroy ats-110-lab-030-02
```

`astrona destroy` takes the environment name (`metadata.name` = `ats-110-lab-030-02`), not
the config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition, bootstrap and grading |
| `question.md` | The task |
| `solution.md` | Step-by-step walkthrough |
| `prerequisites.md` | Assumed knowledge and what the environment provides |
| `bootstrap/` | Environment preparation run once at startup |
| `manifests/` | Perses values, Prometheus and tester, builder manifests |
| `solution/` | Reference solution used by `astrona test` |
| `validation/` | Grading scripts, one per check |

The shared pieces of this folder are generated; change them in every
environment of the course, not only here (see the repository `CLAUDE.md`).
