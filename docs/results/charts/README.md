# Gráficos do Benchmark

Este diretório contém os gráficos gerados automaticamente pelo benchmark.

## Gráficos Disponíveis

- `performance_score.png`: Comparação de Performance Score (Lighthouse)
- `lcp.png`: Comparação de Largest Contentful Paint (LCP)
- `byte_weight.png`: Comparação de Total Byte Weight
- `k6_p95.png`: Comparação de latência p95 (k6)

Os gráficos são gerados pelo script `benchmark/reports/make_charts.py` após a execução dos testes.
