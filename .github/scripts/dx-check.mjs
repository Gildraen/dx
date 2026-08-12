// Compares DX files of this repo against the canonical reference: Gildraen/dx.
//
// Gildraen/dx is public — no extra PAT needed for reads.
//
// Required:
//   GITHUB_TOKEN  — automatic in Actions, used to open issues in this repo
// Optional:
//   COPILOT_TOKEN — PAT with `copilot` scope for AI analysis
//
// Env: GITHUB_REPOSITORY (auto-set by Actions), DRY_RUN (skip issue creation)

const TOKEN = process.env.GITHUB_TOKEN
if (!TOKEN) { console.error('GITHUB_TOKEN required'); process.exit(1) }

const CURRENT_REPO = process.env.GITHUB_REPOSITORY
if (!CURRENT_REPO) { console.error('GITHUB_REPOSITORY required'); process.exit(1) }

const DX_REPO = 'Gildraen/dx'
const AI_TOKEN = process.env.COPILOT_TOKEN || null

// Same path in dx repo → same path in target repo
const DX_FILES = [
  '.gitattributes',
  '.gitignore',
  'renovate.json',
  '.devcontainer/devcontainer.json',
  '.devcontainer/.gh/.gitignore',
  '.devcontainer/.mcp/.gitignore',
  '.devcontainer/.mcp/github/.gitignore',
  '.agents/rules/git.md',
  '.github/workflows/validate.yml',
  '.github/workflows/maintenance.yml',
  '.github/workflows/dx-coherence.yml',
  '.github/scripts/dx-check.mjs',
]

// Lines containing these tokens are project-specific and excluded from diff.
const IGNORE_PATTERNS = [
  '"name"',
  'OLLAMA_HOST',
  'LLM_API_PORT',
  '--exclude',
]

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
async function fetchFile(repo, filePath, authToken) {
  const url = `https://api.github.com/repos/${repo}/contents/${filePath.split('/').map(encodeURIComponent).join('/')}`
  const res = await fetch(url, {
    headers: {
      Authorization: `Bearer ${authToken}`,
      Accept: 'application/vnd.github+json',
      'X-GitHub-Api-Version': '2022-11-28',
    },
  })
  if (!res.ok) return null
  const data = await res.json()
  return Buffer.from(data.content, 'base64').toString('utf8')
}

function filterLines(content) {
  if (!content) return null
  return content.split('\n').filter(l => !IGNORE_PATTERNS.some(p => l.includes(p))).join('\n')
}

function diffSummary(filePath, ref, local) {
  const r = filterLines(ref)
  const l = filterLines(local)

  if (r === null && l === null) return null
  if (r === null) return `- \`${filePath}\` absent dans **${DX_REPO}** (pas encore canonique)`
  if (l === null) return `- \`${filePath}\` absent dans ce repo (présent dans **${DX_REPO}**)`
  if (r.trim() === l.trim()) return null

  const linesRef = r.split('\n')
  const linesLocal = l.split('\n')
  const onlyInRef = linesRef.filter(ln => ln.trim() && !linesLocal.includes(ln))
  const onlyInLocal = linesLocal.filter(ln => ln.trim() && !linesRef.includes(ln))
  if (!onlyInRef.length && !onlyInLocal.length) return null

  const lines = [`- \`${filePath}\` diffère de la référence:`]
  if (onlyInRef.length) lines.push(`  - manque dans ce repo: \`${onlyInRef.slice(0, 3).join('`, `')}\``)
  if (onlyInLocal.length) lines.push(`  - seulement ici: \`${onlyInLocal.slice(0, 3).join('`, `')}\``)
  return lines.join('\n')
}

async function openIssue(title, body) {
  if (process.env.DRY_RUN) { console.log(`[dry-run] ${title}`); return }
  const res = await fetch(`https://api.github.com/repos/${CURRENT_REPO}/issues`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${TOKEN}`,
      Accept: 'application/vnd.github+json',
      'X-GitHub-Api-Version': '2022-11-28',
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ title, body }),
  })
  if (!res.ok) throw new Error(`Failed to open issue: ${res.status} ${await res.text()}`)
  const data = await res.json()
  console.log(`Issue opened: ${data.html_url}`)
}

async function findOpenDriftIssue() {
  const res = await fetch(`https://api.github.com/repos/${CURRENT_REPO}/issues?state=open&per_page=20`, {
    headers: {
      Authorization: `Bearer ${TOKEN}`,
      Accept: 'application/vnd.github+json',
      'X-GitHub-Api-Version': '2022-11-28',
    },
  })
  if (!res.ok) return null
  const issues = await res.json()
  return issues.find(i => i.title.startsWith('[dx-drift]')) || null
}

async function callModel(prompt) {
  if (!AI_TOKEN) throw new Error('COPILOT_TOKEN not configured')
  const res = await fetch('https://api.githubcopilot.com/chat/completions', {
    method: 'POST',
    headers: { Authorization: `Bearer ${AI_TOKEN}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({
      model: 'gpt-4o-mini',
      messages: [{ role: 'user', content: prompt }],
      max_tokens: 1000,
      temperature: 0.2,
    }),
  })
  if (!res.ok) throw new Error(`Copilot API error ${res.status}: ${await res.text()}`)
  return (await res.json()).choices[0].message.content.trim()
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------
async function main() {
  console.log(`DX check: ${CURRENT_REPO} vs ${DX_REPO}`)

  const diffLines = []
  for (const filePath of DX_FILES) {
    const [ref, local] = await Promise.all([
      fetchFile(DX_REPO, filePath, TOKEN),
      fetchFile(CURRENT_REPO, filePath, TOKEN),
    ])
    const line = diffSummary(filePath, ref, local)
    if (line) diffLines.push(line)
  }

  if (!diffLines.length) {
    console.log('No DX drift detected.')
    return
  }

  console.log(`Drift detected (${diffLines.length} differences)`)

  let analysis = "_Analyse IA indisponible. Pour l'activer, configurez le secret `COPILOT_TOKEN` (PAT avec scope `copilot`)._"
  if (AI_TOKEN) {
    try {
      analysis = await callModel(`
Tu analyses le drift DX de ${CURRENT_REPO} par rapport à la référence ${DX_REPO}.

Différences détectées :
${diffLines.join('\n')}

1. Explique brièvement pourquoi c'est problématique.
2. Actions prioritaires pour aligner (max 3 bullet points).
3. Note si une différence est intentionnelle/acceptable.

Markdown, français, très concis.
`.trim())
    } catch (e) {
      console.warn(`AI skipped: ${e.message}`)
    }
  }

  const existing = await findOpenDriftIssue()
  if (existing) {
    console.log(`Issue already open: ${existing.html_url} — skipping`)
    return
  }

  await openIssue('[dx-drift] Incohérence DX détectée', `## DX drift détecté

> Ce repo dérive de la référence [${DX_REPO}](https://github.com/${DX_REPO}).

### Différences

${diffLines.join('\n')}

---

### Analyse IA

${analysis}

---

*Aligner les fichiers DX avec [${DX_REPO}](https://github.com/${DX_REPO}), puis fermer cette issue.*`)
}

main().catch(e => { console.error(e); process.exit(1) })
