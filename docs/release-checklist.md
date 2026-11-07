# Maintainer release checklist

Run `bash validate-all.sh`; review the canonical Skill and examples. Use
`python scripts/package_skill.py --output <new-file.zip>` to create a local archive.
The package is only `agent-skills-setup/SKILL.md`, references and templates; never
include development Skills, evals, historical notes, repository tooling or old code.

Structural checks and example parsing do not replace real-agent evaluation. Follow
`dev/skills/maintain-agent-skills-setup/references/acceptance.md` before release.
Record exact checks and outstanding limitations in `docs/validation-status.md`.

Use one approved release version and update metadata/changelog together. Do not
publish the `-dev` branch automatically. Recheck marketplace-specific licensing
and metadata against official rules; do not silently relicense contributions.
The canonical repository license remains MIT. Prior distribution records are in
Git history; no claim that a new ClawHub package has been published is made here.

After separately authorized publication, download the package and inspect its
file list, version, frontmatter and resource links. Verify real installation in
the selected host before describing the release as usable there.
