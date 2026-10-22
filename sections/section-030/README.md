# Section 030: Writing A Panel Plugin

Everything Perses draws comes from a plugin, and the plugin system is open: you can write a panel the built-in plugins do not offer, and Perses loads it next to its own. This section writes one, the `StatusBadge` panel, from an empty folder to a dashboard that uses it.

**Topic covered:** plugins

## What you will learn

- The plugin types and the plugin module that groups them.
- What a plugin archive holds, and how Perses finds and loads archives at start.
- Generating a panel plugin with `percli plugin generate`.
- Writing a CUE schema the Perses server enforces, and the React component the browser runs.
- Building the archive with `percli plugin build`, and installing it with a Helm values file.
- Checking the result with `/api/v1/plugins` and a dashboard that uses the panel.

## The learning path

The module starts at its landing page, which also launches the playground. The playground has Perses, Prometheus and a builder pod with Node.js, `percli` and `cue`.

### 1. Write And Install A Panel Plugin

1. Plugin Modules And Archives
2. Writing The StatusBadge Plugin
3. Building And Installing The Plugin, followed by the lab **Build And Install The StatusBadge Panel Plugin**
4. Summary

## Section capstone: Ship Version 0.2.0 Of A Panel Plugin

`StatusBadge` 0.1.0 runs in Perses and a dashboard uses it. The team wants a unit after the value. The capstone takes a plugin through a real version change: schema, types, component, archive, and the switch from the old version to the new one. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS110.git -c sections/section-030/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-030/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-110-capstone-030
```
