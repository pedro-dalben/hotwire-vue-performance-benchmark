# Métricas do Benchmark

Este documento explica cada métrica coletada no benchmark.

## Visualizações

Os gráficos gerados estão disponíveis em `docs/results/charts/`:

- **performance_score.png**: Score geral de performance do Lighthouse (0-100)
- **lcp.png**: Largest Contentful Paint em milissegundos
- **byte_weight.png**: Tamanho total de payload transferido em KB
- **k6_p95.png**: Latência p95 das requisições sob carga (k6) em milissegundos

Todos os gráficos são gerados automaticamente durante a execução do benchmark e incluídos no relatório final (`docs/results/REPORT.md`).

## Lighthouse Metrics

### Performance Score

Score geral de performance (0-100) calculado pelo Lighthouse baseado em várias métricas. Quanto maior, melhor.

### First Contentful Paint (FCP)

Tempo até o primeiro conteúdo renderizado aparecer na tela. Mede a percepção de velocidade inicial.

- **Bom**: < 1.8s
- **Precisa melhorar**: 1.8s - 3.0s
- **Ruim**: > 3.0s

### Largest Contentful Paint (LCP)

Tempo até o maior elemento de conteúdo visível ser renderizado. Principal métrica de percepção de velocidade.

- **Bom**: < 2.5s
- **Precisa melhorar**: 2.5s - 4.0s
- **Ruim**: > 4.0s

### Total Blocking Time (TBT)

Soma de todos os períodos entre FCP e Time to Interactive onde a thread principal foi bloqueada por mais de 50ms. Mede interatividade.

- **Bom**: < 200ms
- **Precisa melhorar**: 200ms - 600ms
- **Ruim**: > 600ms

### Speed Index

Mede a velocidade visual de renderização da página. Quanto menor, melhor.

### Cumulative Layout Shift (CLS)

Mede a estabilidade visual. Quanto menor, melhor (0 = sem shift).

- **Bom**: < 0.1
- **Precisa melhorar**: 0.1 - 0.25
- **Ruim**: > 0.25

### Total Byte Weight

Tamanho total de todos os recursos transferidos (KB). Quanto menor, melhor.

### Script Transfer Size

Tamanho total de JavaScript transferido (KB). Quanto menor, melhor.

### Total Requests

Número total de requisições HTTP. Quanto menor, melhor.

## k6 Metrics

### Request Duration (p95/p99)

Tempo de resposta das requisições:
- **p95**: 95% das requisições foram mais rápidas que este valor
- **p99**: 99% das requisições foram mais rápidas que este valor

Quanto menor, melhor.

### HTTP Request Failed Rate

Taxa de requisições que falharam (0.0 = 0%, 1.0 = 100%). Quanto menor, melhor.

### Throughput

Número de requisições por segundo que o sistema consegue processar. Quanto maior, melhor.

## Complexidade Objetiva

### Gems Count

Número de gems no Gemfile.lock (Rails apps). Indica complexidade de dependências.

### NPM Dependencies Count

Número de pacotes npm no package-lock.json (Vue app). Indica complexidade de dependências.

### Build Size

Tamanho do build de produção (Vue: dist/, Rails: public/assets). Quanto menor, melhor.

## Como Interpretar

### Comparação Hotwire vs Vue

- **Performance Score**: Qual tem melhor score geral?
- **LCP**: Qual carrega o conteúdo principal mais rápido?
- **Byte Weight**: Qual transfere menos dados?
- **k6 p95**: Qual tem menor latência sob carga?

### Variações Esperadas

- Variações de ±10-20% entre runs são normais
- Hardware diferente pode resultar em valores diferentes
- Resultados são relativos, não absolutos

### Conclusões Condicionais

Os resultados devem ser interpretados como:
- "Neste benchmark, neste hardware, com este fluxo..."
- Não como verdades absolutas sobre as tecnologias
