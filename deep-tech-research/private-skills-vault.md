# Private skills vault for Claude Code

Goal: keep a set of skills you built available to you and your team, out of any shared work repo, without disturbing your existing skills setup.

All behaviour here is from https://code.claude.com/docs/en/skills — check it if your Claude Code version is older, since several of these features have minimum versions.

## The mistake to avoid

`.claude/skills/` inside a work repo is the wrong place. The docs list project skills as a *distribution* mechanism: you share them by committing that directory. Anything you put there ends up in the repo, in code review, and on the machine of everyone who clones it.

Personal skills at `~/.claude/skills/` are fine from a privacy standpoint — that's your home directory. The problem with using it alone is portability: nothing there is version-controlled or shareable with your two or three teammates.

The vault pattern below solves both.

## Layout

Keep the real files in one private directory, outside every work repo:

```
~/vault/skills/                      # private git repo, or a folder on an encrypted volume
├── .git/
└── .claude/
    └── skills/
        ├── deep-tech-research/
        │   ├── SKILL.md
        │   ├── references/
        │   └── templates/
        └── another-private-skill/
            └── SKILL.md
```

The `.claude/skills/` nesting inside the vault matters — `--add-dir` looks for exactly that path.

Set up:

```bash
mkdir -p ~/vault/skills/.claude/skills
cd ~/vault/skills
git init
chmod -R 700 ~/vault/skills
```

Move the skill in:

```bash
mv ~/.claude/skills/deep-tech-research ~/vault/skills/.claude/skills/
```

Private remote, so the team can sync:

```bash
git remote add origin git@github.com:yourorg/skills-vault.git   # PRIVATE repo
git add -A && git commit -m "skills vault" && git push -u origin main
```

Teammates clone to the same path and get the same setup. Nothing touches the product repos.

## Loading it — two modes

### Mode A: on demand (most isolated)

```bash
claude --add-dir ~/vault/skills
```

The vault's skills load for that session only. Sessions you start without the flag don't see them at all.

Alias it so you don't have to remember:

```bash
# ~/.zshrc or ~/.bashrc
alias claudev='claude --add-dir ~/vault/skills'
```

**Important:** the `permissions.additionalDirectories` setting in `settings.json` grants file access but does **not** load skills. Only the `--add-dir` flag and the `/add-dir` command do. If you configure it in settings and wonder why nothing loaded, this is why.

`/add-dir ~/vault/skills` also works mid-session.

### Mode B: always available to you (most convenient)

Symlink from your personal skills directory. Claude Code follows symlinks out of the enterprise, personal, and project locations and reads `SKILL.md` from the target.

```bash
ln -s ~/vault/skills/.claude/skills/deep-tech-research ~/.claude/skills/deep-tech-research
```

Verify:

```bash
ls -l ~/.claude/skills/
```

Files stay in the vault under git. They're available in every session. They never enter a work repo. If the same target is reachable from more than one location, Claude Code loads it once, so combining this with `--add-dir` won't double-load.

Symlink all of them at once:

```bash
for d in ~/vault/skills/.claude/skills/*/; do
  ln -sfn "$d" ~/.claude/skills/"$(basename "$d")"
done
```

Windows: use `mklink /D` in an elevated prompt, or Developer Mode, since symlinks need the privilege.

## Editing

Edit the files in the vault directly. Claude Code watches skill directories and picks up `SKILL.md` changes within the current session without a restart — including `.claude/skills/` inside an `--add-dir` directory. Two exceptions: if you create a top-level skills directory that didn't exist when the session started, restart; and live detection covers `SKILL.md` text only.

So the gap-capture loop works in place. Claude edits `references/coverage-checklist.md`, you `git diff` in the vault, you commit. No repackaging.

## Restricting Claude to only your skills

Separate concern from privacy. This controls what Claude *invokes*, not who can read the files.

Put it in `.claude/settings.local.json` in the project where you want the restriction, not in your global `~/.claude/settings.json` — that keeps your normal sessions working.

```json
{
  "disableBundledSkills": true,
  "skillOverrides": {
    "some-other-skill": "off",
    "legacy-context": "name-only"
  }
}
```

`skillOverrides` values:

| Value | Listed to Claude | In the `/` menu |
|---|---|---|
| `"on"` | name and description | yes |
| `"name-only"` | name only | yes |
| `"user-invocable-only"` | hidden | yes |
| `"off"` | hidden | hidden |

A skill absent from `skillOverrides` is treated as `"on"`. Plugin skills are not affected — manage those with `/plugin`.

Faster way to write it: run `/skills`, highlight an entry, press `Space` to cycle states, `Enter` to save. It writes `.claude/settings.local.json` for you.

For a hard allowlist, use permission rules in `/permissions`. Syntax is `Skill(name)` for exact match, `Skill(name *)` for prefix match with arguments:

```
# deny rules — blocks everything
Skill

# allow rules — the exceptions
Skill(deep-tech-research)
Skill(deep-tech-research *)
```

Note `disableBundledSkills` leaves `/doctor` typable. To hide that too, set the `DISABLE_DOCTOR_COMMAND` environment variable or a `skillOverrides` entry of `"doctor": "off"`.

If you'd rather a specific skill never fire automatically and only run when you type it, add `disable-model-invocation: true` to its frontmatter. That removes it from Claude's context entirely.

## Watch the description budget

Claude Code loads a listing of every skill name and description into context. If you accumulate a lot of skills, it shortens descriptions to fit a budget that scales at 1% of the model's context window, dropping them starting with the skills you invoke least. That can strip exactly the keywords `deep-tech-research` needs to trigger.

Check the cost:

```
/doctor
```

If the listing is overflowing, either raise the budget with the `skillListingBudgetFraction` setting (e.g. `0.02` for 2%) or the `SLASH_COMMAND_TOOL_CHAR_BUDGET` environment variable, or set low-priority skills to `"name-only"` in `skillOverrides` to free room. Note that each entry's combined `description` plus `when_to_use` text is capped at 1,536 characters regardless of budget, so put the key use case first.

## What this protects against, and what it doesn't

Protects against:

- your skills landing in a shared work repo, a PR, or a teammate's checkout
- skills leaking through a plugin marketplace
- other people's skills or bundled skills interfering with yours

Does **not** protect against:

- anyone with read access to your disk or your backups. That's filesystem permissions (`chmod 700`) and full-disk encryption, not Claude configuration.
- the content reaching Anthropic's API. When a skill is invoked, its rendered `SKILL.md` enters the conversation context, which means it's sent with the request. No skill setting changes that. If your threat model includes the model provider, a skill file is the wrong container for the secret.
- a private GitHub repo being private forever. Access lists drift. Audit who's on it.

One more: review project skills before trusting a repository. A skill can grant itself broad tool access through `allowed-tools`, which takes effect once you accept the workspace trust dialog. This cuts both ways — it's a reason to keep your own skills out of shared repos, and a reason to read other people's before trusting them.

## Sanity check

```bash
# skill resolves through the symlink
ls -lL ~/.claude/skills/deep-tech-research/SKILL.md

# nothing leaked into the work repo
cd ~/work/your-project && git ls-files | grep -c '\.claude/skills' || echo "clean"

# vault permissions are tight
ls -ld ~/vault/skills
```

Then in a session: `/skills` should list `deep-tech-research`, and `/context` should show a Skills row you can compare against the budget.
