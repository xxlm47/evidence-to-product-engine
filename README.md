# Evidence-to-Product Engine

An evidence-first, mobile-friendly workflow for finding real problems, evaluating demand, creating useful digital products, launching responsibly, and learning from real outcomes.

**Free-first by design. Human approval before publication. No guaranteed-income claims.**

## Why this project exists

The project has evolved beyond book publishing. Books remain one possible output, but the goal is broader: use evidence to decide which problems are worth solving, choose a useful format, build a quality product, and measure whether people actually want it.

The current repository is strongest as a local-first research, project-scaffolding, writing, quality-review, and publishing workflow. Some scripts and templates remain book-oriented; broader formats such as toolkits, checklists, templates, and calculators may require adapting the generated project materials. The engine does not autonomously perform market research or guarantee sales.

## Core loop

`Problem -> Evidence -> Opportunity decision -> Product -> Quality review -> Launch -> Measure -> Improve or stop`

## Principles

- Evidence before production; distinguish observed facts from assumptions.
- No invented demand, reviews, testimonials, statistics, or sources.
- No full production investment before the opportunity passes its documented gate.
- No unverified factual claims in a product marked ready for publication.
- Human approval is required before publication.
- No paid API, advertising, hosting, or outsourcing is required for the core local workflow.
- Record real sales and feedback; never treat scores as sales forecasts.
- Keep the workflow usable on Android/Termux and in a browser where practical.

## Quick start

```bash
chmod +x scripts/*.sh
./scripts/new-project.sh
```

Open `app/index.html` in a browser for the local-first workspace. See `docs/ANDROID-QUICKSTART.md` and `docs/RUNBOOK.md` for setup and workflow guidance.

## What is included

- Project scaffolding and structured workspace files
- Research, demand-evidence, and competitor-gap prompts
- Opportunity and outline templates
- Drafting, fact-checking, editing, packaging, and launch checklists
- A browser workspace with local storage and JSON import/export
- GitHub Actions for repository validation and Pages deployment

## Current limitations

This is an assistive workflow, not a fully autonomous research or publishing system. Scripts can create stage artifacts and check repository structure; they do not automatically prove demand, perform comprehensive fact-checking, publish products, or validate commercial success. Quality gates must be completed honestly, and any claim of readiness requires review of the actual artifacts.

The current templates still emphasize nonfiction books and marketplaces such as Amazon KDP and Gumroad. Use the product-first mission as the direction for future improvements, not as a claim that every digital-product format is already fully automated.

## Testing

```bash
bash scripts/validate-project.sh
python -m json.tool config/settings.json >/dev/null
```

## Repository history

This project was previously called **Book Revenue Engine**. The new name reflects the wider problem-to-product direction without implying that revenue is guaranteed.

## License

MIT
