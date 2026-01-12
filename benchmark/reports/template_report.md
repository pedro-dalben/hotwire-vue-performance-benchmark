# Benchmark: Rails Hotwire vs Vue 3

## Resumo Executivo

Este benchmark compara duas abordagens de desenvolvimento web:
- **A) Rails 8 + Hotwire** (monolito com server-side rendering)
- **B) Rails 8 API + Vue 3** (frontend separado consumindo JSON)

Ambas as implementações foram testadas com o mesmo domínio (Appointments), mesmo dataset (5000 registros) e mesmas funcionalidades.

## Resultados Lighthouse

### Performance Score

{{LIGHTHOUSE_PERFORMANCE_TABLE}}

![Performance Score](charts/performance_score.png)

### Métricas de Performance

{{LIGHTHOUSE_METRICS_TABLE}}

### Tamanho de Payload

{{BYTE_WEIGHT_TABLE}}

![Total Byte Weight](charts/byte_weight.png)

## Resultados k6

### Latência (p95/p99)

{{K6_LATENCY_TABLE}}

![k6 p95](charts/k6_p95.png)

### Taxa de Erros e Throughput

{{K6_ERRORS_TABLE}}

## Complexidade Objetiva

{{COMPLEXITY_TABLE}}

## Metodologia

- **Hardware/OS**: {{HARDWARE_INFO}}
- **Versões**: Ruby {{RUBY_VERSION}}, Node {{NODE_VERSION}}, Chrome {{CHROME_VERSION}}, Lighthouse {{LIGHTHOUSE_VERSION}}, k6 {{K6_VERSION}}
- **Número de runs**: 5 execuções por URL (mediana reportada)
- **Perfis de carga k6**: Leve (20 VUs) e Moderado (50 VUs), 60s cada
- **Dataset**: 5000 appointments, data base fixa 2026-01-01T00:00:00Z

### O que foi medido

- Performance web (Lighthouse): FCP, LCP, TBT, Speed Index, CLS
- Tamanho de payload transferido (total byte weight, script transfer size)
- Latência de requisições (k6): p95, p99
- Taxa de erros e throughput

### O que NÃO foi medido

- UX qualitativa
- Tempo de desenvolvimento
- Manutenibilidade do código
- Experiência do desenvolvedor

## Limitações

- Benchmark executado localmente (não em ambiente de produção real)
- Variações podem ocorrer entre diferentes máquinas/hardware
- Resultados são específicos para este fluxo e dataset
- Não considera otimizações adicionais que poderiam ser aplicadas

## Reproduzir

```bash
cd benchmark
./setup_local.sh
./start_all.sh
./warmup.sh
./lighthouse/run_lighthouse.sh
./k6/run_k6.sh leve
./k6/run_k6.sh moderado
./reports/aggregate_results.py
./reports/make_charts.py
```

Os resultados estarão em `docs/results/`.

