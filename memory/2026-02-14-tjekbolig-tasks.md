# TjekBoligAI Tasks - Assignees & Dependencies

## Del 1: Task Assignments (Todoist)

### Fase 1 - Danny (OAuth apps)
| # | Task | Assignee | Dependencies |
|---|------|----------|--------------|
| 1 | Opret Google OAuth app | **Danny** | - |
| 2 | Opret Facebook OAuth app | **Danny** | - |

### Fase 1 - Rene (Kodning)
| # | Task | Assignee | Dependencies |
|---|------|----------|--------------|
| 3 | Installer Auth.js v5 | **Rene** | 1,2 |
| 4 | Implementer login page | **Rene** | 3 |
| 5 | Setup middleware | **Rene** | 3 |
| 6 | Test SSO flow | **Rene** | 4,5 |

### Fase 2 - Rene (Mock data)
| # | Task | Assignee | Dependencies |
|---|------|----------|--------------|
| 7 | Design mock data struktur | **Rene** | - |
| 8 | Opret 5 demo rapporter | **Rene** | 7 |
| 9 | Generer sample PDF | **Rene** | 7 |
| 10 | Implementer mock data provider | **Rene** | 7 |
| 11 | Opret 'Load Demo Data' | **Rene** | 8-10 |

### Fase 3 - Rene (UI)
| # | Task | Assignee | Dependencies |
|---|------|----------|--------------|
| 12 | Dashboard med auth | **Rene** | 6 |
| 13 | Rapport viewer | **Rene** | 12 |
| 14 | AI analyse display | **Rene** | 12 |
| 15 | Demo mode toggle | **Rene** | 11 |
| 16 | Mobile responsive | **Rene** | 12-15 |

## Opsummering af Assignees

| Person | Antal Tasks | Faser |
|--------|-------------|-------|
| **Danny** | 2 | OAuth Setup (Fase 1) |
| **Rene** | 14 | Implementation, Mock Data, UI (Faser 1-3) |
| **Anders** | - | Verifikation (Fase 3) |

## Verifikation Workflow

Se `AGENTS.md` → **TjekBoligAI Verifikation Workflow** for fuld beskrivelse.

## Status

- ✅ Verifikation workflow dokumenteret i AGENTS.md
- ✅ Task assignments dokumenteret
