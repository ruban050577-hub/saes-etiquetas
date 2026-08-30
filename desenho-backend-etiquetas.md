# Desenho do backend — App de Etiquetas (Saes Food Lab)

Documento de decisões fechadas com o Marcelo, para ser entregue ao Claude Code
como ponto de partida da construção. Escrito em português claro, sem jargão.

Este documento é a fonte da verdade. Se algo não estiver aqui, é porque ainda
não foi decidido — nesse caso, PERGUNTAR antes de assumir.

---

## Contexto do projeto

App de impressão de etiquetas de validade para cozinha de restaurante.
Hoje é um arquivo HTML único que roda no navegador e guarda tudo em localStorage
(memória do navegador). Funciona, já foi testado, imprime etiqueta 60×60mm.

Estamos agora adicionando login de verdade e banco de dados na nuvem (Supabase),
para o app deixar de ser uso interno e virar produto vendável, com cada
restaurante tendo seus próprios dados isolados.

O app atual (frontend) NÃO deve ser reescrito do zero. O trabalho é acoplar
autenticação e banco ao que já existe.

---

## As seis decisões (todas fechadas)

### 1. Quem cria as contas
O DONO DO NEGÓCIO (Marcelo) cria as contas dos clientes manualmente, durante um
onboarding assistido presencial. **Não existe auto-cadastro** — não há tela de
"criar minha conta" aberta ao público. Ninguém se registra sozinho.

Consequência prática: precisa existir uma forma de o Marcelo criar um novo
restaurante + a primeira pessoa dele. Pode ser um painel de administrador simples,
ou (no começo) criação manual direto no painel do Supabase. Começar pelo mais
simples que funcione.

### 2. O que é uma "conta" — restaurante e pessoas são coisas separadas
Esta é a decisão mais importante da estrutura. Ler com atenção.

- Um **restaurante** (organização) é onde os dados moram. Todo produto, método,
  etiqueta e registro pertence a UM restaurante.
- Uma **pessoa** (usuário) é quem faz login, com email e senha próprios.
- Uma pessoa pertence a um restaurante. Um restaurante pode ter VÁRIAS pessoas.

No começo, cada restaurante vai ter só UMA pessoa cadastrada (o dono). Mas a
estrutura do banco tem que suportar várias pessoas por restaurante DESDE O
PRIMEIRO DIA, mesmo sem tela para isso ainda.

Motivo: quando um sócio ou funcionário precisar de acesso próprio, deve bastar
adicionar uma pessoa àquele restaurante — sem refazer estrutura. Fazer isso agora
é barato; mudar depois é caro.

Termo técnico para o Claude Code: toda tabela de dados carrega uma coluna que
identifica o restaurante dono do registro (`org_id` / `restaurante_id`). É isso
que isola os dados de um cliente dos dados de outro.

### 3. Recuperação de senha — por email
Quando a pessoa esquecer a senha, recupera por email (link de redefinição).
Isso é padrão no Supabase Auth, que já traz esse fluxo pronto. Usar o fluxo
nativo do Supabase, não construir do zero.

### 4. Migração de dados — não há nada a migrar
O app começa limpo no banco. Nenhum dado de localStorage precisa ser trazido.
Não construir rotina de migração. Começar do zero.

### 5. Hospedagem — Supabase
O backend é o Supabase (banco de dados + autenticação). O dono banca o custo
inicial. Começar no plano gratuito enquanto couber; avaliar upgrade só quando
o volume de clientes justificar.

### 6. Quem executa — Marcelo com o Claude Code
Marcelo é leigo em programação. A construção será feita por ele conversando com
o Claude Code em português. Portanto:
- Explicar cada passo de forma simples, sem assumir conhecimento técnico.
- Antes de qualquer decisão difícil de reverter, avisar explicitamente que é
  difícil de reverter e explicar as opções em português claro.
- Quando surgir uma pergunta de produto (não de código), Marcelo leva de volta
  para a conversa de desenho e traz a resposta. Não decidir produto sozinho.

---

## Regra de trabalho fixa do projeto

Sempre FECHAR a questão (desenhar a solução e obter aprovação explícita do
Marcelo) ANTES de escrever ou alterar qualquer código. Nunca partir direto
para implementação. Vale também dentro do Claude Code.

---

## O que este documento NÃO cobre (ainda a decidir)

Estas coisas ficaram fora de propósito e devem ser tratadas como novas questões
quando chegarem — cada uma fechada antes de virar código:

- Tela de administrador do Marcelo para criar/gerenciar restaurantes e pessoas
- Tela para adicionar uma segunda pessoa a um restaurante existente
- Papéis diferentes de pessoa (dono vs. funcionário com acesso limitado)
- Múltiplas unidades do mesmo restaurante (a coluna `unidade_id` pode ser
  reservada agora junto com `org_id`, mas a tela fica para depois)
- Atualização da tabela de métodos de conservação para a tabela completa do
  Art. 44 da Portaria CVS-3/2026 (isso é do frontend, não do backend, mas
  precisa ser feito antes de rodar no cliente real)

---

## Pendências do frontend, separadas do backend

Para não confundir: além do backend, o app ainda tem estas pendências que NÃO
dependem do login e podem ser resolvidas em paralelo:

- Testar impressão real na impressora Tomate MDK-006 com etiqueta 60×60mm e
  ajustar o CSS se o texto cortar.
- Atualizar a biblioteca de métodos para a tabela completa do Art. 44 (CVS-3/2026),
  já conferida no PDF oficial.
- Corrigir textos do app para nunca prometerem "conformidade" — o app é
  ferramenta; a responsabilidade legal é do responsável técnico / dono do
  estabelecimento (Art. 20 e 23 da CVS-3/2026).

---

## Decisão de tamanho de etiqueta (fechada)

Etiqueta padrão única: 60×60mm, BOPP térmica. Não há escolha de tamanho por
cliente. Cliente com impressora incompatível se adapta ou não é público-alvo.
Isso simplifica: não guardar tamanho de etiqueta por cliente no banco.
