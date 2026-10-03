# ClawHub browser acceptance: v0.10.0

Observed on 2026-10-03 (Asia/Shanghai), using anonymous desktop Chrome through
CUA. This record describes rendered pages, real controls, and a completed
browser download. It is separate from HTTP/SSR checks and native IDE acceptance.

Targets: [ClawHub skill](https://clawhub.ai/luckycat133/skills/agent-skills-setup),
[security audit](https://clawhub.ai/luckycat133/skills/agent-skills-setup/security-audit),
and [GitHub release](https://github.com/Luckycat133/skills-repo/releases/tag/v0.10.0).
The GitHub page resolves to commit
`12d56c84407ff91847b0c9afe1c970f90818a102`.

| Check | Result | Observed evidence |
| --- | --- | --- |
| Public metadata | PASS | Skill title, publisher, current version `v0.10.0`, and `MIT-0` are visible without signing in. |
| SKILL.md | PASS | Title, permissions, workflow table, authorization rules, and supported/manual boundaries render legibly. |
| Skill Card | PASS after one reload | Overview, version `0.10.0`, `MIT-0`, use case, risks/mitigations, output behavior, and references render. |
| Files | PASS | File tree lists 121 files, including the generated card. Card and registry file contents load in the viewer; line wrapping works. |
| Versions | PASS | `v0.10.0` has the Latest label; `v0.9.3` and earlier releases remain listed. The new changelog expands. |
| Diff | PASS | Previous `v0.9.3` and latest `v0.10.0` compare; SKILL.md additions/deletions render. The side-by-side control becomes selected. |
| Requirements | PASS | Required tools are displayed as `bash` and `python3`. |
| Browser download | PASS | The visible `v0.10.0` download link produces a completed ZIP download. All 120 submitted package files match the staged release bytes. |
| Security presentation | PASS | Audit version `0.10.0` and Outcome Pass are visible; the SkillSpector section retains 112 findings and their severity/detail views. Presentation acceptance is not a clean security verdict. |
| GitHub release | PASS | Release title, Latest, tag, commit, release notes, runtime archive, checksum, and two source archives render. The displayed archive digest matches the release checksum. |
| Raw reference-link navigation | NOT_RUN | Chrome reports `ERR_BLOCKED_BY_CLIENT` for direct navigation to the actual registry file URL. The same registry content is readable through Files. Browser protections were preserved. |

## Loading behavior and boundaries

The first Skill Card visit displayed a missing-card message despite the card
being listed in Files. After one reload and completion of client loading, the
card displayed correctly. Initial Versions and GitHub Assets observations were
also empty/loading states; Versions completed loading and reopening Assets once
showed the files. These transient captures are retained alongside the final
successful views.

The downloaded ZIP contains 122 entries: 120 submitted files, generated
`skill-card.md`, and platform `_meta.json`. Files shows 121 because it includes
the card and omits the platform metadata. The generated card digest matches the
official verification record:
`7ae74f51bed68dae9e2e72d73912f3469d8741ae4f2dfef4fb7f0a8d5fc7d183`.
The browser ZIP SHA-256 is
`b5805233f6cd62708d6461af542dc49453d254debb6d569bf10a7deb18cf43e2`.

The SKILL.md profile-path placeholders render as links to a reference directory
on the platform. This browser session does not establish direct navigation to
those placeholders or all reference links. The registry's concrete profile
routing and the Files viewer remain available; no release payload was changed
for a directory placeholder.

No login, install command, migration, MCP connection, publishing, account change,
or paid action was performed. This desktop-browser check does not establish
native application acceptance or every browser/viewport combination.

## Evidence identifiers

Screenshots, DOM/AX snapshots, download assertions, and a SHA-256 manifest are
kept as local verification artifacts outside the publishable Skill. The following
identifiers allow the final views to be distinguished from transient captures.

| Screenshot | SHA-256 |
| --- | --- |
| `13-permissions.jpg` | `a24b2b6d413c7da9a7b6710da3b938aa84559d8954f9e041d5e3867967c1d0ac` |
| `05-card-after-hydration.jpg` | `c96e95a861475d95556d316de23d73074603bced973d31b81755fb30dc24cbd3` |
| `06-versions-loaded.jpg` | `3d3f5054dec199bf48ce003bb69d4966b9e94681ed70617bc4c2943ad792842e` |
| `09-security-findings.jpg` | `fdbe76149a787c5338657c8e7a2522829a25b01f17f9146e3718b597b45b4b86` |
| `16-github-assets.jpg` | `1125de03a7ef6d48cf919ea8779b4180f9ca16266227d94955b521493ce287d7` |
