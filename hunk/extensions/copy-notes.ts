// Save a note with c, then Ctrl+S. Ctrl+Y or Extensions → Copy my notes exports it.
// New Hunk windows auto-load this file; export existing notes before closing old windows.
// macOS clipboard only. Self-check: bun ~/.config/hunk/extensions/copy-notes.ts
import { strict as assert } from 'node:assert'
import { spawnSync } from 'node:child_process'
import type {
  ExtensionReviewSnapshot,
  HunkExtensionAPI,
} from 'hunkdiff/extension'

export function formatNotes(snapshot: ExtensionReviewSnapshot): string {
  const paths = new Map(snapshot.files.map((file) => [file.fileKey, file.path]))
  return snapshot.notes
    .filter((note) => note.source === 'user')
    .map((note) => {
      const { oldRange, newRange, preferred } = note.anchor
      const oldSide = preferred?.side === 'old' || (!newRange && !!oldRange)
      const range = oldSide ? oldRange : newRange
      const lines = range
        ? `:${range[0]}${range[1] === range[0] ? '' : `-${range[1]}`}`
        : ''
      const side = oldSide ? ' (old)' : ''
      const status = note.resolution === 'active' ? '' : ` [${note.resolution}]`
      return `${paths.get(note.fileKey) ?? '[removed file]'}${lines}${side}${status}\n${note.summary}${note.rationale ? `\n${note.rationale}` : ''}`
    })
    .join('\n\n')
}

export default function (hunk: HunkExtensionAPI) {
  hunk.registerCommand(
    { id: 'copy', title: 'Copy my notes', key: 'ctrl+y' },
    (ctx) => {
      const snapshot = ctx.review.snapshot()
      if (!snapshot) return ctx.notify('Review unavailable', 'warning')
      const text = formatNotes(snapshot)
      if (!text) return ctx.notify('No saved user notes to copy', 'warning')
      // ponytail: macOS clipboard; use terminal clipboard support if this moves to a remote host.
      const result = spawnSync('/usr/bin/pbcopy', {
        input: `${text}\n`,
        encoding: 'utf8',
        timeout: 2000,
      })
      if (result.error || result.status !== 0) {
        ctx.notify(
          `Clipboard copy failed: ${result.error?.message ?? result.stderr}`,
          'error',
        )
        return
      }
      ctx.notify('Copied saved user notes with file paths and line numbers')
    },
  )
}

if (import.meta.main) {
  const snapshot = {
    files: [{ fileKey: 'file', path: 'src/example.ts' }],
    notes: [
      {
        source: 'user',
        fileKey: 'file',
        anchor: { newRange: [4, 4] },
        summary: 'Check boundary',
        resolution: 'active',
      },
      {
        source: 'user',
        fileKey: 'file',
        anchor: {
          oldRange: [8, 10],
          newRange: [9, 11],
          preferred: { side: 'old', line: 8 },
        },
        summary: 'Keep this',
        rationale: 'Still needed',
        resolution: 'stale',
      },
      {
        source: 'agent',
        fileKey: 'file',
        anchor: {},
        summary: 'Not mine',
        resolution: 'active',
      },
    ],
  } as unknown as ExtensionReviewSnapshot
  assert.equal(
    formatNotes(snapshot),
    'src/example.ts:4\nCheck boundary\n\nsrc/example.ts:8-10 (old) [stale]\nKeep this\nStill needed',
  )
  assert.equal(formatNotes({ ...snapshot, notes: [] }), '')
  console.log('copy-notes self-check passed')
}
