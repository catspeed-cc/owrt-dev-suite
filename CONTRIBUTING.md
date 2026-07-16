# Contributing to `owrt-dev-suite`

Thanks for your interest in contributing! 🐑 This project is a labor of love born out of porting the TRENDnet TEW-829DRU to OpenWRT after its EOL notice, and we welcome help from fellow porters, tinkerers, and OpenWRT developers.

## 🐱 Code of Conduct

Be respectful, be patient, and remember everyone here is volunteering their time. Disagreements happen, keep them technical and constructive.

## 🔍 Before You Start

This project does not yet have a tagged release, and there are no contributors listed. That means:

- APIs, script flags, and directory structures may change without notice.
- There is no guaranteed backwards compatibility yet.
- Now is actually a great time to have outsized influence on the project's direction!

## 🐛 Reporting Bugs

Please use the [GitHub Issues](https://github.com/catspeed-cc/owrt-dev-suite/issues) tracker. A good bug report includes:

1. **Full output logs** from the build script (use `-vv` for extra verbose output where possible).
2. **Steps to reproduce**, including your `etc/config.sh` settings (redact anything sensitive like paths or credentials if needed).
3. **Your environment**: host OS, OpenWRT branch/commit, target SOC/MFR/model.
4. **Expected vs. actual behavior**.

🔍 **Search first**: Please check [existing issues](https://github.com/catspeed-cc/owrt-dev-suite/issues) before opening a new one, to avoid duplicates. Feel free to upvote or add details to an existing thread instead.

## 💡 Suggesting Features

Open an issue describing:

- The problem you're trying to solve (not just the feature itself).
- Any workarounds you're currently using.
- Whether you're willing to help implement it.

Check the **Planned Features** section in the README first, your idea may already be on the roadmap.

## 🛠️ Submitting Pull Requests

1. **Fork** the repository and create a feature branch from `development`.
2. If your change touches submodule behavior, make sure `owrt-dev-suite-utils` changes are submitted to [its own repository](https://github.com/catspeed-cc/owrt-dev-suite-utils) first, then reference the updated submodule commit here.
3. Keep commits focused, one logical change per commit where possible.
4. Test your changes against a real build if you can (ideally on the ipq40xx target or your own device port).
5. Update relevant documentation (`README.md`, or the configuration/setup docs) if your change affects usage.
6. Open the PR against `development` with a clear description of **what** changed and **why**.

### Coding Style

- Emojis are required in: program & readme headers, readme item lists, SUMMARY_OUT & stderr output (visual marker)
- Shell scripts should remain POSIX-compatible where reasonably possible.
- Keep configuration exclusively in `etc/config.sh`, avoid hardcoding config elsewhere.
- Keep dependencies exclusively in `lib/dependencies.sh`, avoid hardcoding them elsewhere.
- Keep functions exclusively in `lib/functions.sh`, avoid hardcoding them elsewhere.
- Add your authorship line for any files you touch onto the end of the authorship list.
- Ensure to create configuration variables, helper functions and keep concerns separated.
- Ensure proper SUMMARY_OUT lines and no spam makes it to stderr or SUMMARY_OUT
- Preserve the existing trapping/cleanup gating logic, don't remove safety nets without discussion.
- Refactoring entire codebase must not be done without prior group discussion with admin/maintainers/developers
- Workflow: `feat-*/fix-*`->testing->`development`->testing->`master`
- When merging into `development` suggest to bump either MAJOR, MINOR, or PATCH (SemVer) in the merge issue ticket
- Maintain an updated readme for your feature sets with the same style

## 📜 Licensing

`owrt-dev-suite` and `owrt-dev-suite-utils` are both licensed under **GPLv2-or-later**. By submitting a contribution, you agree that your contribution will be licensed under the same terms.

## 📢 Staying Updated

Watch the repository or follow the Issues tracker to stay current on releases and changelogs. There is no release yet, so early contributors will help shape the very first tagged version! 🚀

## 🆘 Last Resort Contact

If you've exhausted GitHub Issues and need direct assistance, you may email **mooleshacat@catspeed.cc**. Please use this sparingly, Issues are the preferred and most transparent channel.

## ❤️ Supporting Software Freedom

This project proudly supports the work of the [Software Freedom Conservancy](https://sfconservancy.org/), who fight to uphold GPL compliance so projects like this one remain possible.
