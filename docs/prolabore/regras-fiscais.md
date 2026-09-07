# Pró-labore e Fator R — regras de negócio

> Documento de domínio do módulo de pró-labore. Registra o que foi discutido e
> decidido em 2026-09-06/07, antes de qualquer código.
>
> **Atenção:** os valores numéricos abaixo (alíquotas, tabelas, teto do INSS,
> tabela do IRRF) foram levantados de memória durante a conversa e servem para
> dimensionar o problema, **não como fonte da verdade**. Antes de virarem seed do
> sistema, precisam ser conferidos pela contadora contra a legislação vigente.

## Contexto

- **Quem opera:** uma contadora.
- **Quantas empresas:** 2, cada uma com **apenas o dono do CNPJ**, sem funcionários.
- **Empresa A:** já está no Anexo V pelo CNAE, fatura ~R$17.000/mês
  (RBT12 ~R$204.000), e **hoje não paga pró-labore** — todo o faturamento é
  tributado pela tabela cara e o dono retira o resto como distribuição de lucros.
- **Empresa B:** será aberta e entra no Anexo V em 2027.

## Objetivo do módulo

O módulo **não é uma folha de pagamento**. É um **otimizador de fator R** que
produz folha como subproduto.

A finalidade é reduzir a carga tributária migrando as empresas do **Anexo V
(caro)** para o **Anexo III (barato)** via pagamento de pró-labore, e depois
manter essa condição mês a mês.

## Conceitos

| Termo | Significado |
|---|---|
| **RBT12** | Receita bruta acumulada dos últimos 12 meses. Base do cálculo. |
| **Anexo** | Tabela de alíquotas do Simples. III = barato, V = caro, IV = regra própria. |
| **Pró-labore** | Remuneração que o sócio recebe pelo trabalho na própria empresa. |
| **Distribuição de lucros** | Retirada do lucro pelo sócio. Isenta de IR pessoal (ver ressalva de 2026). |
| **Fator R** | Folha dos últimos 12 meses ÷ RBT12. `>= 28%` → Anexo III; `< 28%` → Anexo V. |

## Regras de cálculo

### Composição da folha para o fator R

Para uma empresa com **apenas o sócio**, a folha do fator R é o **pró-labore
bruto**:

- A CPP (contribuição patronal, 20%) está **dentro do DAS** nos Anexos III e V,
  então não há contribuição patronal "efetivamente recolhida" para somar.
- Não há FGTS (sócio não é empregado).
- **A CPP de 20% só é devida à parte no Anexo IV**, que não é o caso aqui.

### Alíquota efetiva

Nunca usar a alíquota nominal da faixa. Sempre:

```
aliquota_efetiva = (RBT12 * aliquota_nominal - parcela_a_deduzir) / RBT12
```

A empresa A, com RBT12 de R$204.000, está na **segunda faixa** dos dois anexos —
por isso as efetivas são ~15,79% e ~6,61%, e não os 15,5% / 6% da primeira faixa.

### Encargos sobre o pró-labore

- **INSS:** 11% retido do sócio, **limitado ao teto** vigente. Acima do teto o
  custo marginal do pró-labore cai para só IRRF.
- **IRRF:** tabela progressiva, comparando deduções legais (INSS + dependentes)
  contra o desconto simplificado e aplicando a menor. Sob as regras de 2026,
  pró-labore até ~R$5.000/mês fica isento.
- **Não existe** FGTS, 13º nem férias sobre pró-labore. "13º de sócio" é
  pró-labore adicional na competência, não verba própria.
- **Piso:** havendo retirada, o pró-labore não pode ser inferior a um salário
  mínimo.

## O fator R é um degrau, não uma rampa

**Regra mais importante do módulo.** Não existe crédito parcial:

- Pró-labore = 0 → Anexo V, sem custo de INSS/IRRF.
- Pró-labore entre 0 e 28% do RBT12 → **pior cenário possível**: paga INSS e IRRF
  e **continua no Anexo V**.
- Pró-labore = 28% do RBT12 → Anexo III. Ponto ótimo.
- Pró-labore > 28% → nenhum benefício adicional; só custo.

**O ótimo é exatamente 28%, ou nada.** A UI precisa deixar isso evidente, porque é
o erro mais caro que dá para cometer aqui.

## Janela móvel de 12 meses

Tanto o RBT12 quanto a folha do fator R são **janelas móveis apuradas mensalmente**.
Consequências:

- Começar a pagar pró-labore hoje **não muda o anexo no mês seguinte** — a
  migração é gradual, conforme a janela se preenche.
- O anexo pode **oscilar** mês a mês se o faturamento subir e o pró-labore não
  acompanhar. Isso exige alerta ativo, não conta pontual.
- **Empresa em início de atividade** (caso da empresa B) não tem 12 meses de
  histórico: RBT12 e fator R usam **proporcionalização** pelos meses de atividade.
  Deve nascer no motor, não virar remendo.

## Dimensionamento da empresa A

Com RBT12 de R$204.000 e pró-labore de R$4.760/mês (28%):

| | Hoje | Com pró-labore |
|---|---|---|
| Alíquota efetiva | 15,79% (Anexo V) | 6,61% (Anexo III) |
| DAS no ano | R$32.220 | R$13.488 |
| INSS sobre pró-labore | R$0 | R$6.283 |
| IRRF | R$0 | R$0 (dentro da isenção de 2026) |
| **Total no ano** | **R$32.220** | **R$19.771** |

**Economia líquida ≈ R$12.450/ano.** O pró-labore em si não é custo — o dinheiro
chegaria ao sócio de qualquer forma; o que muda é a porta de saída. O INSS ainda
retorna como tempo de contribuição.

## Ponto de virada

A vantagem **não é infinita**. Conforme o faturamento cresce, o pró-labore de 28%
ultrapassa a faixa de isenção do IRRF e a alíquota de 27,5% passa a corroer o
ganho, enquanto a diferença entre os anexos diminui.

**A inversão fica na ordem de R$600 mil/ano de faturamento** (~R$50k/mês) —
aproximado, sensível ao teto do INSS e à tabela do IRRF. A empresa A, em R$204k,
está muito longe disso.

Por ser sensível a parâmetros que mudam todo ano, **essa conta deve ser refeita
pelo sistema**, nunca cravada como regra fixa.

## Classificação nos anexos

Não existe lista oficial de "CNAEs do Anexo III". A LC 123 lista **atividades por
descrição**; o CNAE é apenas o código que registra a atividade. Três grupos:

1. **Sempre Anexo III**, independente do fator R — escolas e cursos, agências de
   viagem, agências lotéricas, autoescolas, instalação/reparo/manutenção,
   escritórios de contabilidade, fisioterapia.
2. **Fator R decide** (`>= 28%` → III, senão V) — software e licenciamento,
   engenharia, arquitetura, medicina, odontologia, psicologia, veterinária,
   publicidade, jornalismo, consultoria, auditoria, gestão, design, representação
   comercial, perícia, academias, laboratórios.
3. **Anexo IV**, fator R não se aplica — construção civil, advocacia, vigilância,
   limpeza e conservação.

Listas **exemplificativas, não exaustivas**. Na prática, **estar no Anexo V já
significa estar no grupo 2**: o Anexo V é o destino de quem tem fator R abaixo de
28%, não uma tabela onde a empresa fica presa. Não há troca de CNAE envolvida no
plano.

## Escopo decidido

### Dentro

- Cadastro de empresas (anexo **com histórico de vigência**) e sócios.
- Tabelas de Anexo III, Anexo V, INSS e IRRF **versionadas por vigência**.
- Fator R com janela móvel de 12 meses + variante proporcional de início de atividade.
- Simulador reverso: pró-labore mínimo para fechar 28%, com comparativo
  economia × custo.
- Alerta de proximidade do limite (empresa saindo do trilho).
- Saídas mensais: recibo de pró-labore, INSS a recolher, e a "cola" do que a
  contadora lança no portal do eSocial.

### Fora

- **Transmissão de eSocial e DCTFWeb.** Descartado deliberadamente: 2 empresas
  significam ~2 eventos/mês digitados no portal. Não justifica certificado
  ICP-Brasil no servidor, assinatura XMLDSig, SOAP com TLS mútuo e manutenção
  perpétua de leiaute. Os portais oficiais são gratuitos; o custo real é o
  certificado e-CNPJ.
- Empregados CLT, FGTS, férias, 13º, rescisão.
- Regimes fora do Simples Nacional.

## A confirmar com a contadora

- [ ] Valores das tabelas dos Anexos III e V (alíquotas e parcelas a deduzir).
- [ ] Teto do INSS e tabela do IRRF vigentes, incluindo a regra de isenção de 2026.
- [ ] Salário mínimo vigente (piso do pró-labore).
- [ ] CNAE da empresa A e CNAE pretendido da empresa B.
- [ ] Como a tributação de dividendos acima de R$50 mil/mês (a partir de 2026)
      afeta a comparação pró-labore × distribuição neste perfil de cliente.

## Fontes a checar

- Lei Complementar 123/2006, art. 18 (classificação nos anexos e fator R).
- Resolução CGSN 140/2018 (regulamentação e tabelas).
- Lei 15.270/2025 (isenção de IRPF até R$5.000 e tributação de dividendos, 2026).
