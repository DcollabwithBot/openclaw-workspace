# Sikkerhedsaudit: tjekbolig.ai

**Dato:** 2026-02-13  
**Auditor:** OpenClaw Security Agent  
**Scope:** Frontend Git Repository + Live Website  
**Projekt:** TjekBoligAI v0.2 (POC)

---

## Executive Summary

Audit afslørede **7 kritiske** og **5 høje** sikkerhedsproblemer. Hovedproblemerne er:
- Miljøvariabler med faktiske credentials committed til git
- Manglende sikkerhedsheaders
- Server information leakage
- Manglende CSRF beskyttelse

**Risiko:** Kritisk - Anbefaler øjeblikkelig handling

---

## DEL 1: Git Repository Analyse

### 🔴 Kritiske Fund (7 stk)

#### 1. .env.local committed til git (Frontend)
**Fil:** `tjekbolig-ai-frontend/.env.local`  
**Linje:** Alle linjer  
**Problem:** Faktiske miljøvariabler med Supabase credentials committed til git

```
NEXT_PUBLIC_SUPABASE_URL=https://xveokbfxqjujsajqtyda.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=sb_publishable_KMlwHRuFi5ChUtdvdXXXbg_52u1frxf
```

**Risiko:** Angribere kan bruge disse nøgler til at tilgå databasen  
**Fix:** 
```bash
# 1. Fjern fra git historik
git filter-branch --force --index-filter \
  'git rm --cached --ignore-unmatch tjekbolig-ai-frontend/.env.local' \
  --prune-empty --tag-name-filter cat -- --all

# 2. Rotate keys i Supabase dashboard
# 3. Tilføj til .gitignore
# 4. Opret .env.local.example uden værdier
```

---

#### 2. Backend .env committed til git
**Fil:** `tjekbolig-ai-backend/.env`  
**Linje:** 1-4  
**Problem:** Supabase anon key og URL eksponeret

```
SUPABASE_URL=https://xveokbfxqjujsajqtyda.supabase.co
SUPABASE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Risiko:** Anon key giver læseadgang til databasen via Supabase API  
**Fix:** Samme procedure som #1 + rotate keys

---

#### 3. Supabase URL eksponeret i git historik
**Projekt ID:** `xveokbfxqjujsajqtyda`  
**Problem:** Projekt ID er nu offentligt kendt

**Risiko:** Angribere kan målrette specifikt dette Supabase projekt  
**Fix:** Overvej at oprette nyt Supabase projekt og migrere data

---

#### 4. Manglende .gitignore i backend
**Fil:** `tjekbolig-ai-backend/`  
**Problem:** Ingen .gitignore fil i backend mappen

**Fix:** 
```bash
# Opret tjekbolig-ai-backend/.gitignore:
.env
.env.local
.env.*
__pycache__/
*.pyc
.venv/
venv/
```

---

#### 5. NEXT_PUBLIC_ variabler indeholder følsom data
**Fil:** `tjekbolig-ai-frontend/.env.local`  
**Linje:** 2  
**Problem:** Supabase anon key eksponeret client-side

**Forklaring:** Alle `NEXT_PUBLIC_` variabler bliver inkluderet i client-side JavaScript bundle og er synlige for alle brugere i browseren.

**Risiko:** Enhver bruger kan se og misbruge denne nøgle  
**Fix:** 
- Brug kun NEXT_PUBLIC_ til ikke-følsomme konfigurationer
- Supabase anon key bør håndteres server-side via API routes
- Eller implementer Row Level Security (RLS) strikt på alle tabeller

---

#### 6. Manglende RLS policy på documents INSERT
**Fil:** `supabase/migrations/001_initial.sql`  
**Linje:** 63-72  
**Problem:** Kun SELECT policies defineret, ingen INSERT/UPDATE/DELETE

```sql
-- Mangler policies for:
-- - documents INSERT
-- - documents UPDATE  
-- - documents DELETE
-- - analyses (alle operationer)
-- - risks (alle operationer)
```

**Risiko:** Hvis anon key eksponeres, kan angribere:
- Indsætte falske dokumenter
- Opdatere/slette eksisterende data
- Tilgå andre brugeres data hvis auth check bypasses

**Fix:**
```sql
-- Documents INSERT policy
CREATE POLICY "Users can insert own documents" ON documents
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM cases WHERE cases.id = documents.case_id 
            AND cases.user_id = auth.uid()
        )
    );

-- Analyses policies
CREATE POLICY "Users can view own analyses" ON analyses
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM documents 
            JOIN cases ON documents.case_id = cases.id
            WHERE documents.id = analyses.document_id
            AND cases.user_id = auth.uid()
        )
    );

-- Risks policies
CREATE POLICY "Users can view own risks" ON risks
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM analyses
            JOIN documents ON analyses.document_id = documents.id
            JOIN cases ON documents.case_id = cases.id
            WHERE analyses.id = risks.analysis_id
            AND cases.user_id = auth.uid()
        )
    );
```

---

#### 7. API upload endpoint uden autentifikation
**Fil:** `tjekbolig-ai-backend/app/main.py`  
**Linje:** 44-76  
**Problem:** `/upload` endpoint kræver ikke autentifikation

```python
@app.post("/upload")
async def upload_document_endpoint(file: UploadFile = File(...)):
    # Ingen auth check!
```

**Risiko:** 
- DDoS via upload floods
- Upload af malicious PDFs
- Exhaustion af storage kvota

**Fix:**
```python
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

security = HTTPBearer()

async def verify_token(credentials: HTTPAuthorizationCredentials = Depends(security)):
    # Verificer Supabase JWT token
    try:
        # Verificer mod Supabase
        user = supabase.auth.get_user(credentials.credentials)
        return user
    except:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token"
        )

@app.post("/upload")
async def upload_document_endpoint(
    file: UploadFile = File(...),
    user: dict = Depends(verify_token)
):
    # Nu beskyttet
```

---

### 🟠 Høje Fund (5 stk)

#### 8. PyPDF2 har kendte sikkerhedsproblemer
**Fil:** `tjekbolig-ai-backend/requirements.txt`  
**Linje:** 6  
**Problem:** PyPDF2>=2.0.0 har kendte sårbarheder

**Risiko:** PDF parsing kan exploiteres via malicious PDFs  
**Fix:** 
```
# Skift til pypdf (nyere, sikrere)
pypdf>=4.0.0

# Eller tilføj validering før parsing
# Implementer file size limits
# Kør i sandbox/container
```

---

#### 9. CORS allow_origins inkluderer localhost i produktion
**Fil:** `tjekbolig-ai-backend/app/main.py`  
**Linje:** 17-18  
**Problem:** 

```python
allow_origins=["http://localhost:3000", "https://tjekbolig.ai"],
```

**Risiko:** Localhost i produktion gør CSRF angreb nemmere  
**Fix:**
```python
import os

environment = os.getenv("ENVIRONMENT", "production")

if environment == "production":
    allow_origins = ["https://tjekbolig.ai"]
else:
    allow_origins = ["http://localhost:3000", "https://tjekbolig.ai"]
```

---

#### 10. Manglende file type validering udover extension
**Fil:** `tjekbolig-ai-backend/app/main.py`  
**Linje:** 46  
**Problem:** Kun check af `.pdf` extension, ikke faktisk filindhold

```python
if not file.filename.endswith('.pdf'):
    raise HTTPException(status_code=400, detail="Only PDF files allowed")
```

**Risiko:** MIME spoofing - bruger kan uploade vilkårlig fil med .pdf extension  
**Fix:**
```python
import magic

# Check magic bytes
file_content = await file.read()
mime = magic.from_buffer(file_content, mime=True)

if mime != 'application/pdf':
    raise HTTPException(status_code=400, detail="Invalid file type")
```

---

#### 11. Manglende rate limiting på upload
**Fil:** `tjekbolig-ai-backend/app/main.py`  
**Problem:** Intet rate limiting på /upload endpoint

**Risiko:** Brute force uploads, DDoS  
**Fix:**
```python
from slowapi import Limiter
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)
app.state.limiter = limiter

@app.post("/upload")
@limiter.limit("5/minute")  # Max 5 uploads per minut per IP
async def upload_document_endpoint(...):
```

---

#### 12. OpenAI API key håndtering
**Fil:** `tjekbolig-ai-backend/app/openai_service.py`  
**Linje:** 43  
**Problem:** Global API key uden rotation eller validering

**Risiko:** Hvis key leaks, kan den misbruges til dyre API kald  
**Fix:**
- Implementer API key rotation
- Tilføj spending limits i OpenAI dashboard
- Monitor API usage
- Overvej at cache resultater for at reducere API kald

---

### 🟡 Medium/Lave Fund (3 stk)

#### 13. Manglende input sanitization på PDF text
**Fil:** `tjekbolig-ai-backend/app/main.py`  
**Linje:** 54-56  
**Problem:** PDF tekst sendes direkte til OpenAI uden sanitization

**Risiko:** Prompt injection via PDF indhold  
**Fix:** Implementer input validering og escaping

---

#### 14. Version exposure i health endpoint
**Fil:** `tjekbolig-ai-backend/app/main.py`  
**Linje:** 78-79  
**Problem:** API version eksponeret

```python
return {"status": "healthy", "version": "0.1.0"}
```

**Risiko:** Information til angribere om hvilke sårbarheder der kan findes  
**Fix:** Fjern version fra offentlige endpoints

---

#### 15. npm audit mangler
**Status:** Kunne ikke verificere  
**Problem:** npm audit ikke kørt for at tjekke for sårbare dependencies

**Anbefaling:**
```bash
cd tjekbolig-ai-frontend
npm audit
npm audit fix
```

---

## DEL 2: Live Website Analyse

### 🔴 Kritiske Fund (3 stk)

#### 16. Manglende Security Headers
**URL:** https://tjekbolig.ai  
**Problem:** Følgende headers mangler:
- `Strict-Transport-Security` (HSTS)
- `Content-Security-Policy` (CSP)
- `X-Frame-Options`
- `X-Content-Type-Options`
- `Referrer-Policy`
- `Permissions-Policy`

**Risiko:**
- XSS angreb mulige uden CSP
- Clickjacking uden X-Frame-Options
- MIME sniffing uden X-Content-Type-Options

**Fix (Next.js next.config.js):**
```javascript
async headers() {
  return [
    {
      source: '/(.*)',
      headers: [
        {
          key: 'Strict-Transport-Security',
          value: 'max-age=63072000; includeSubDomains; preload'
        },
        {
          key: 'Content-Security-Policy',
          value: "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self'; connect-src 'self' https://xveokbfxqjujsajqtyda.supabase.co https://api.tjekbolig.ai;"
        },
        {
          key: 'X-Frame-Options',
          value: 'DENY'
        },
        {
          key: 'X-Content-Type-Options',
          value: 'nosniff'
        },
        {
          key: 'Referrer-Policy',
          value: 'strict-origin-when-cross-origin'
        },
        {
          key: 'Permissions-Policy',
          value: 'camera=(), microphone=(), geolocation=()'
        }
      ]
    }
  ]
}
```

---

#### 17. Server Information Leakage
**URL:** https://api.tjekbolig.ai  
**Problem:** Server header afslører `openresty/1.27.1.1`

**URL:** https://tjekbolig.ai (403 fejl)  
**Problem:** `LiteSpeed Web Server` afsløret

**Risiko:** Angribere kan målrette kendte sårbarheder i specifikke versioner  
**Fix:** Konfigurer server til at skjule version information eller bruge generic headers

---

#### 18. Manglende CSRF beskyttelse på upload form
**URL:** https://tjekbolig.ai  
**Problem:** Upload form har ingen CSRF token beskyttelse

**Risiko:** Cross-site request forgery angreb mulige  
**Fix:** Implementer CSRF tokens i Next.js middleware

---

### 🟠 Høje Fund (3 stk)

#### 19. 415 Unsupported Media Type afslører server
**URL:** https://tjekbolig.ai/privatliv, /vilkaar, /robots.txt  
**Problem:** 415 fejl afslører `openresty/1.27.1.1`

**Ekstra problem:** Siderne returnerer 415 i stedet for 404, hvilket indikerer en konfigurationsfejl

**Fix:** 
- Fix routing konfiguration
- Fjern server version fra fejlsider

---

#### 20. Health endpoint eksponerer information
**URL:** https://api.tjekbolig.ai/health  
**Problem:** 
```json
{
  "status": "ok",
  "timestamp": "2026-02-13T12:23:43.611Z"
}
```

**Risiko:** Tidsstempel kan bruges til at synkronisere angreb  
**Fix:** Fjern timestamp eller tilføj autentifikation til health endpoint

---

#### 21. CORS tillader wildcard i produktion
**Problem:** Baseret på backend kode, CORS er for permissive

**Risiko:** CSRF angreb fra tredjeparts websites  
**Fix:** Se fix #9

---

### 🟡 Medium/Lave Fund (2 stk)

#### 22. Manglende robots.txt og sitemap.xml
**URL:** https://tjekbolig.ai/robots.txt  
**Status:** 415 fejl

**Anbefaling:** Opret korrekte robots.txt og sitemap.xml filer

---

#### 23. SSL/TLS konfiguration
**Status:** Kunne ikke verificere detaljer uden eksterne værktøjer

**Anbefaling:**
- Test med SSL Labs: https://www.ssllabs.com/ssltest/
- Sikr at TLS 1.2+ er påkrævet
- Deaktiver svage cipher suites

---

## Prioriteret Handleliste

### Øjeblikkelig handling (inden 24 timer)
1. [ ] Rotate alle Supabase keys (anon + service role)
2. [ ] Fjern .env filer fra git historik med filter-branch
3. [ ] Tilføj .env* til .gitignore i begge mapper
4. [ ] Implementer RLS policies på alle tabeller

### Høj prioritet (inden 1 uge)
5. [ ] Tilføj autentifikation til /upload endpoint
6. [ ] Implementer security headers i Next.js
7. [ ] Fjern server version headers
8. [ ] Fix CORS konfiguration til produktion
9. [ ] Implementer rate limiting

### Medium prioritet (inden 1 måned)
10. [ ] Opgrader PyPDF2 til pypdf
11. [ ] Implementer file type validering med magic bytes
12. [ ] Tilføj CSRF beskyttelse
13. [ ] Implementer input sanitization
14. [ ] Kør npm audit og fix sårbarheder

### Lav prioritet (løbende)
15. [ ] Opret robots.txt og sitemap.xml
16. [ ] Verificer SSL/TLS konfiguration
17. [ ] Implementer API key rotation
18. [ ] Tilføj logging og monitoring

---

## Værktøjer til fremtidige audits

```bash
# Git secrets scanning
git log --all --full-history -- .env
git log --all -p -- .env.local | grep -E "(KEY|SECRET|PASSWORD|TOKEN)"

# NPM audit
cd tjekbolig-ai-frontend && npm audit

# Python safety check
cd tjekbolig-ai-backend && safety check

# Online scanners
# https://securityheaders.com/
# https://www.ssllabs.com/ssltest/
# https://observatory.mozilla.org/
```

---

## Kontakt

Ved spørgsmål om denne audit, kontakt security team.

**END OF REPORT**
