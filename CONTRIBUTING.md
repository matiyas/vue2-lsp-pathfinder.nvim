# Contributing to vue2-lsp-pathfinder.nvim

First off, thank you for considering contributing! Your help is greatly appreciated.

This project is a community-driven effort, and we welcome contributions of all kinds, from simple bug reports to new features.

## Code of Conduct

By participating in this project, you agree to abide by our [Code of Conduct](CODE_OF_CONDUCT.md). Please read it before contributing.

## How Can I Contribute?

### Reporting Bugs

If you find a bug, please open a [Bug Report](https://github.com/matiyas/vue2-lsp-pathfinder.nvim/issues/new?template=bug_report.md).
Please include:
- A clear and descriptive title.
- Steps to reproduce the behavior.
- What you expected to happen.
- What actually happened.
- Your environment details (Neovim version, plugin version, LSP setup).

### Suggesting Enhancements

If you have an idea for a new feature or an improvement, please open a [Feature Request](https://github.com/matiyas/vue2-lsp-pathfinder.nvim/issues/new?template=feature_request.md).
- Explain the problem you're trying to solve.
- Describe the solution you'd like to see.
- If possible, provide examples of how it would work.

### Pull Requests

We welcome pull requests! If you're ready to contribute code, please follow these steps:

1.  **Fork the repository** and clone it to your local machine.
2.  **Create a new branch** for your changes: `git checkout -b feature/your-amazing-feature`.
3.  **Set up your development environment**. You'll need `busted` for testing and `stylua` and `luacheck` for linting.
    ```bash
    # Install test and lint dependencies
    luarocks install busted
    luarocks install luassert
    luarocks install luacheck
    # stylua is often installed via a package manager or from releases
    ```
4.  **Make your changes**.
5.  **Run the tests** to ensure you haven't broken anything.
    ```bash
    busted tests/ --verbose
    ```
6.  **Format and lint your code**.
    ```bash
    # Check formatting
    stylua --check lua/ plugin/

    # Run linter
    luacheck lua/ plugin/
    ```
7.  **Commit your changes** with a clear and descriptive commit message.
    ```bash
    git commit -m "feat: Add amazing new feature"
    ```
    We follow the [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) specification.
8.  **Push your branch** to your fork: `git push origin feature/your-amazing-feature`.
9.  **Open a Pull Request** to the `main` branch of this repository.
    - Fill out the pull request template with details about your changes.
    - Ensure all automated checks (CI) are passing.

Thank you for your contribution!
