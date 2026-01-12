# Metodologia do Benchmark

## Hardware e Software

### Hardware

[Será preenchido automaticamente durante execução]

### Software

- **OS**: Ubuntu (ou Linux similar)
- **Ruby**: [Versão detectada automaticamente]
- **Node.js**: [Versão detectada automaticamente]
- **PostgreSQL**: [Versão do sistema]
- **Chrome/Chromium**: [Versão detectada automaticamente]
- **Lighthouse**: [Versão detectada automaticamente]
- **k6**: [Versão detectada automaticamente]

## Configuração dos Testes

### Ambiente de Produção

Ambas as aplicações são executadas em modo produção:

- **Rails**: `RAILS_ENV=production`
- **Assets**: Precompilados (`rails assets:precompile`)
- **Vue**: Build de produção (`npm run build`) servido via `vite preview`
- **Logs**: Reduzidos (warn level)

### Dataset

- **Tamanho**: 5000 appointments
- **Data base**: `2026-01-01T00:00:00Z` (fixa, não "hoje")
- **Seed**: `Random.srand(42)` para reprodutibilidade
- **Distribuição**:
  - 50 beneficiários únicos
  - 20 profissionais únicos
  - 5 unidades
  - Status: 40% scheduled, 30% confirmed, 20% done, 10% canceled
  - `starts_at`: ±60 dias a partir da data base

### Equidade entre Aplicações

- **Mesma lib de paginação**: Pagy (25 por página)
- **Mesmas regras de query**: Mesmos escopos, mesmos WHERE, mesmo ILIKE
- **Mesmos índices**: starts_at, status, unit_name, beneficiary_name
- **Mesmo dataset**: seed_data.json compartilhado

## Lighthouse

### Configuração

- **Runs**: 5 execuções por URL
- **Modo**: Headless Chrome
- **Categorias**: Apenas performance
- **Validação SPA**: Verificação de marcador `data-bench-route` para Vue

### URLs Testadas

**Hotwire:**
- `http://127.0.0.1:3100/appointments`
- `http://127.0.0.1:3100/appointments/1`
- `http://127.0.0.1:3100/appointments/new`

**Vue:**
- `http://127.0.0.1:3300/appointments`
- `http://127.0.0.1:3300/appointments/1`
- `http://127.0.0.1:3300/appointments/new`

### Métricas Extraídas

- Performance score
- FCP (First Contentful Paint)
- LCP (Largest Contentful Paint)
- TBT (Total Blocking Time)
- Speed Index
- CLS (Cumulative Layout Shift)
- Total byte weight
- Script transfer size
- Total requests

### Agregação

- **Mediana**: Valor central dos 5 runs (menos sensível a outliers)
- **p95**: Percentil 95 dos 5 runs

## k6

### Configuração

- **Perfis**:
  - Leve: 20 VUs, 60s (10s ramp-up, 50s estável)
  - Moderado: 50 VUs, 60s (10s ramp-up, 50s estável)

### Scripts

**Hotwire (`script_hotwire.js`):**
- GET `/appointments`
- GET `/appointments?status=confirmed&unit_name=Unit%201`
- GET `/appointments/1`
- Apenas GETs (equidade com API)

**API (`script_api.js`):**
- GET `/api/appointments`
- GET `/api/appointments?status=confirmed&unit_name=Unit%201`
- GET `/api/appointments/1`
- POST `/api/appointments` (JSON)

### Métricas Extraídas

- Request duration p95/p99
- HTTP request failed rate
- Throughput (req/s)

## O que foi Medido

### Performance Web

- Métricas de renderização (FCP, LCP)
- Interatividade (TBT)
- Estabilidade visual (CLS)
- Tamanho de payload transferido

### Performance sob Carga

- Latência de requisições (p95/p99)
- Taxa de erros
- Throughput

### Complexidade Objetiva

- Número de dependências (gems, npm packages)
- Tamanho de build

## O que NÃO foi Medido

### UX Qualitativa

- Experiência do usuário
- Facilidade de uso
- Acessibilidade
- Design

### Desenvolvimento

- Tempo de desenvolvimento
- Curva de aprendizado
- Produtividade do desenvolvedor
- Manutenibilidade do código

### Outros Aspectos

- SEO
- Segurança
- Escalabilidade horizontal
- Custo de infraestrutura

## Variações Esperadas

### Entre Runs

- Variações de ±10-20% são normais
- Dependem de:
  - Estado do sistema operacional
  - Cache do navegador
  - Outros processos rodando

### Entre Máquinas

- Hardware diferente resulta em valores diferentes
- CPU, RAM, disco (SSD vs HDD) afetam resultados
- Resultados são relativos, não absolutos

### Entre Ambientes

- Local vs. produção real
- Rede local vs. internet
- Configurações de servidor diferentes

## Justificativas Metodológicas

### Por que Mediana?

A mediana é menos sensível a outliers que a média, sendo mais representativa do comportamento típico.

### Por que 5 Runs?

Balanceia tempo de execução com confiabilidade estatística.

### Por que Headless Chrome?

Reproduzível e consistente entre execuções.

### Por que k6 GET-only para Hotwire?

Evita complexidade de CSRF token, mantendo equidade com API (que usa JSON).

## Limitações

1. **Ambiente Local**: Não reflete produção real (rede, latência, etc.)
2. **Hardware Específico**: Resultados variam entre máquinas
3. **Dataset Específico**: 5000 registros pode não representar todos os casos
4. **Fluxo Específico**: Apenas o domínio Appointments foi testado
5. **Otimizações**: Não considera otimizações adicionais possíveis

## Reproduzibilidade

Para reproduzir este benchmark:

1. Execute `./benchmark/setup_local.sh`
2. Execute `./benchmark/run_all.sh`
3. Compare resultados em `docs/results/REPORT.md`

O dataset é determinístico (data base fixa, seed fixo), garantindo que os mesmos dados sejam usados em cada execução.

