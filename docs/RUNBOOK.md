# Runbook

## Start a new project

```bash
./new-project.sh
```

Or via CLI flags:

```bash
./new-project.sh -t "AI for Freelancers" -a "Freelancers" -o "Automate tasks" -m full
```

## Resume an existing project

```bash
./new-project.sh --resume <project-slug>
```

## Build or update the stage workspace

```bash
./scripts/run-pipeline.sh <project-slug> all
```

## Run one stage workspace initialization

```bash
./scripts/run-pipeline.sh <project-slug> research
./scripts/run-pipeline.sh <project-slug> opportunity
./scripts/run-pipeline.sh <project-slug> outline
./scripts/run-pipeline.sh <project-slug> drafting
./scripts/run-pipeline.sh <project-slug> fact-check
./scripts/run-pipeline.sh <project-slug> edit
./scripts/run-pipeline.sh <project-slug> packaging
./scripts/run-pipeline.sh <project-slug> launch
```

## Inspect a project report

```bash
./scripts/report.sh <project-slug>
```

## Validate structure

```bash
./scripts/validate-project.sh
```

## Principle

The scripts create and validate the production workspace in `work/<slug>` (or legacy `projects/<slug>`). They do not pretend to have performed web research or generated a manuscript when no research/AI provider has actually been run. Fill artifacts with evidence and use the prompts in `prompts/` to perform each stage.

## Future automation

Provider adapters can later connect the prompt stages to free/local models or other services without changing the project structure. Never hard-code a paid provider as a requirement for the core engine.
