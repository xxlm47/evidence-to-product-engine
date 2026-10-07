# Android Quickstart

## Browser-only

The repository is usable from GitHub in a browser. Use the prompts and templates directly when you do not want to run local commands.

## Termux

1. Install Termux from a trusted current source.
2. Clone the repository:

```bash
git clone https://github.com/xxlm47/evidence-to-product-engine.git
cd evidence-to-product-engine
```

3. Make scripts executable:

```bash
chmod +x scripts/*.sh
```

4. Create a project:

```bash
./scripts/new-book.sh
```

or use the more structured initializer:

```bash
./scripts/new-project.sh
```

5. Work inside the generated project directory.

## $0 rule

Do not install paid services just to run the repository. A GitHub account, a browser, and optional Termux are sufficient for the basic workflow.

## Security

Never put API keys, passwords, payment credentials, private customer data, or access tokens into the repository.
