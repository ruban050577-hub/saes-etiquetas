-- ============================================================
-- SAES FOOD LAB — OPERAÇÃO SEGURA
-- Fase 9-A: SEED (dados iniciais)
--
-- Rode DEPOIS de supabase/temperatura.sql.
-- Pode rodar mais de uma vez: é IDEMPOTENTE (não duplica).
--
-- Parte 1 — a norma CVS-3/2026 em forma de dados (global)
-- Parte 2 — a organização Tacomex e seus 13 pontos de medição
-- ============================================================


-- ============================================================
-- PARTE 1 — PORTARIA CVS-3/2026
--
-- vigente_desde = 06/07/2026, a data de PUBLICAÇÃO.
-- A vigência plena começa por volta de 04/10/2026, mas o app já
-- trabalha com esta tabela desde agora — é o mesmo critério que o
-- app de etiquetas já usa. Se você preferir a data de vigência,
-- é um update de uma linha.
-- ============================================================

insert into temperature_standards
  (norma, artigo, contexto, categoria, temp_min, temp_max, validade_dias, tempo_max_horas, vigente_desde)
values
  -- ---------- Art. 30 — recebimento de mercadorias ----------
  ('CVS-3/2026','Art. 30','RECEBIMENTO','Congelados',                                        null, -12, null, null, '2026-07-06'),
  ('CVS-3/2026','Art. 30','RECEBIMENTO','Refrigerados: pescados',                               2,   3, null, null, '2026-07-06'),
  ('CVS-3/2026','Art. 30','RECEBIMENTO','Refrigerados: preparações com pescados ou carnes cruas',0,  5, null, null, '2026-07-06'),
  ('CVS-3/2026','Art. 30','RECEBIMENTO','Refrigerados: carnes e derivados',                      4,   7, null, null, '2026-07-06'),
  ('CVS-3/2026','Art. 30','RECEBIMENTO','Refrigerados: demais produtos',                         4,  10, null, null, '2026-07-06'),
  ('CVS-3/2026','Art. 30','RECEBIMENTO','Aquecidos',                                            60, null, null, null, '2026-07-06'),

  -- ---------- Art. 44 I — armazenamento congelado ----------
  -- a temperatura é que define a validade
  ('CVS-3/2026','Art. 44 I','ARMAZENAMENTO','Congelado 0 a -5 °C',      -5,   0,  10, null, '2026-07-06'),
  ('CVS-3/2026','Art. 44 I','ARMAZENAMENTO','Congelado -6 a -10 °C',   -10,  -6,  20, null, '2026-07-06'),
  ('CVS-3/2026','Art. 44 I','ARMAZENAMENTO','Congelado -11 a -18 °C',  -18, -11,  30, null, '2026-07-06'),
  ('CVS-3/2026','Art. 44 I','ARMAZENAMENTO','Congelado abaixo de -18 °C', null, -18, 90, null, '2026-07-06'),

  -- ---------- Art. 44 II — armazenamento resfriado ----------
  ('CVS-3/2026','Art. 44 II','ARMAZENAMENTO','Pescados e manipulados crus',                              null, 2, 3, null, '2026-07-06'),
  ('CVS-3/2026','Art. 44 II','ARMAZENAMENTO','Pescados pós-cocção',                                      null, 2, 1, null, '2026-07-06'),
  ('CVS-3/2026','Art. 44 II','ARMAZENAMENTO','Alimentos pós-cocção, exceto pescados',                    null, 4, 3, null, '2026-07-06'),
  ('CVS-3/2026','Art. 44 II','ARMAZENAMENTO','Carnes bovina, suína e aves, e manipulados crus',          null, 4, 3, null, '2026-07-06'),
  ('CVS-3/2026','Art. 44 II','ARMAZENAMENTO','Espetos mistos, bife rolê, carnes temperadas cruas, preparações com carne moída', null, 4, 2, null, '2026-07-06'),
  ('CVS-3/2026','Art. 44 II','ARMAZENAMENTO','Frios e embutidos fatiados, picados ou moídos',            null, 4, 3, null, '2026-07-06'),
  ('CVS-3/2026','Art. 44 II','ARMAZENAMENTO','Maionese e misturas de maionese',                          null, 4, 2, null, '2026-07-06'),
  ('CVS-3/2026','Art. 44 II','ARMAZENAMENTO','Sobremesas, confeitaria com cobertura ou recheio, preparações com laticínios', null, 4, 3, null, '2026-07-06'),
  ('CVS-3/2026','Art. 44 II','ARMAZENAMENTO','Demais alimentos preparados',                              null, 4, 3, null, '2026-07-06'),
  ('CVS-3/2026','Art. 44 II','ARMAZENAMENTO','Frutas, verduras e legumes higienizados ou fracionados; sucos e polpas', null, 5, 3, null, '2026-07-06'),

  -- ---------- Art. 60 — exposição e distribuição ----------
  -- temperatura + tempo máximo de exposição
  ('CVS-3/2026','Art. 60','EXPOSICAO','Quentes, no mínimo 60 °C',                          60, null, null, 6, '2026-07-06'),
  ('CVS-3/2026','Art. 60','EXPOSICAO','Quentes, abaixo de 60 °C',                        null,   60, null, 1, '2026-07-06'),
  ('CVS-3/2026','Art. 60','EXPOSICAO','Frios, até 10 °C',                                null,   10, null, 4, '2026-07-06'),
  ('CVS-3/2026','Art. 60','EXPOSICAO','Frios, entre 10 e 21 °C',                           10,   21, null, 2, '2026-07-06'),
  ('CVS-3/2026','Art. 60','EXPOSICAO','Preparações com pescados e carnes cruas, até 5 °C', null,   5, null, 2, '2026-07-06'),

  -- ---------- processos pontuais ----------
  ('CVS-3/2026','Art. 59','PROCESSO','Cocção: centro geométrico',                          75, null, null, null, '2026-07-06'),
  ('CVS-3/2026','Art. 68','PROCESSO','Reaquecimento: todas as partes',                     75, null, null, null, '2026-07-06'),
  ('CVS-3/2026','Art. 67','PROCESSO','Resfriamento: de 60 °C para 10 °C',                null,   10, null, 2, '2026-07-06'),
  ('CVS-3/2026','Art. 67','PROCESSO','Após resfriar: refrigerado',                       null,    5, null, null, '2026-07-06'),
  ('CVS-3/2026','Art. 67','PROCESSO','Após resfriar: congelado',                         null,  -18, null, null, '2026-07-06'),
  ('CVS-3/2026','Art. 53','PROCESSO','Descongelamento sob refrigeração (proibido em temperatura ambiente)', null, 5, null, null, '2026-07-06'),
  ('CVS-3/2026','Art. 54','PROCESSO','Dessalga sob refrigeração',                         null,    5, null, null, '2026-07-06'),
  ('CVS-3/2026','Art. 55','PROCESSO','Manipulação de perecível animal: área climatizada', null,   16, null, 2, '2026-07-06'),
  ('CVS-3/2026','Art. 55','PROCESSO','Manipulação de perecível animal: temperatura ambiente', null, null, null, 0.5, '2026-07-06'),
  ('CVS-3/2026','Art. 61','PROCESSO','Fritura: temperatura do óleo',                      null,  180, null, null, '2026-07-06'),
  ('CVS-3/2026','Art. 99','PROCESSO','Guarda de amostra',                                  -18,    4, null, 96, '2026-07-06'),
  ('CVS-3/2026','Art. 99','PROCESSO','Guarda de amostra líquida (só refrigerada)',        null,    4, null, 96, '2026-07-06')
on conflict (norma, artigo, categoria) do nothing;


-- ============================================================
-- PARTE 2 — TACOMEX
--
-- Cria a organização (se ainda não existir) e os 13 pontos.
-- "Restaurante Teste" não é tocada.
--
-- Tacomex = o CNPJ operacional, a cozinha física. As marcas
-- (Lupi/Luego, Rockaway Burger, Cozinha 353, Tacomex Fresca)
-- operam na mesma cozinha e NÃO são organizações separadas.
--
-- area e ordem_rodada saem com valores provisórios: 'Cozinha' e
-- sequência 1..13. Você corrige pela tela, andando pela cozinha.
-- ============================================================

do $seed$
declare
  v_org       uuid;
  v_congelado uuid;
  v_resfriado uuid;
  n           integer := 0;
begin
  select id into v_org from organizacoes where nome = 'Tacomex';
  if v_org is null then
    insert into organizacoes (nome) values ('Tacomex') returning id into v_org;
    raise notice 'Organizacao Tacomex criada: %', v_org;
  else
    raise notice 'Organizacao Tacomex ja existia: %', v_org;
  end if;

  -- faixas herdadas da norma para os pontos sanitários
  select id into v_congelado from temperature_standards
   where norma='CVS-3/2026' and artigo='Art. 44 I' and categoria='Congelado abaixo de -18 °C';

  select id into v_resfriado from temperature_standards
   where norma='CVS-3/2026' and artigo='Art. 44 II' and categoria='Demais alimentos preparados';

  -- se a Parte 1 não rodou, para aqui com mensagem clara em vez de
  -- deixar passar ponto sem faixa
  if v_congelado is null or v_resfriado is null then
    raise exception 'A norma nao foi semeada. Rode a PARTE 1 deste arquivo antes da PARTE 2.';
  end if;

  -- ---------- SANITARIO: cobrados na rodada obrigatória ----------
  insert into temperature_points (org_id, nome, area, regime, criticidade, standard_id, ordem_rodada)
  select v_org, p.nome, 'Cozinha', 'EQUIPAMENTO', 'SANITARIO', p.std, p.ord
    from (values
      ('Freezer horizontal 1',  v_congelado,  1),
      ('Freezer horizontal 2',  v_congelado,  2),
      ('Freezer vertical 1',    v_congelado,  3),
      ('Freezer vertical 2',    v_congelado,  4),
      ('Freezer vertical 3',    v_congelado,  5),
      ('Freezer vertical 4',    v_congelado,  6),
      ('Balcão refrigerado 1',  v_resfriado,  7),
      ('Balcão refrigerado 2',  v_resfriado,  8),
      ('Balcão refrigerado 3',  v_resfriado,  9),
      ('Balcão refrigerado 4',  v_resfriado, 10)
    ) as p(nome, std, ord)
   where not exists (
     select 1 from temperature_points t where t.org_id = v_org and t.nome = p.nome
   );

  -- ---------- OPERACIONAL: fora da rodada obrigatória ----------
  -- Bebida industrializada lacrada não é alvo do Art. 48. Monitorar
  -- com o mesmo rigor infla a carga de registro em 23% sem ganho
  -- sanitário e aumenta a chance de a rodada ser abandonada no meio.
  -- Ficam no app por interesse operacional: perda de produto e
  -- quebra de equipamento.
  -- A faixa 0 a 10 °C é provisória, definida pelo estabelecimento
  -- (não há norma para isto). Ajuste pela tela de Pontos.
  insert into temperature_points (org_id, nome, area, regime, criticidade, temp_min, temp_max, ordem_rodada)
  select v_org, p.nome, 'Cozinha', 'EQUIPAMENTO', 'OPERACIONAL', 0, 10, p.ord
    from (values
      ('Geladeira de bebidas 1', 11),
      ('Geladeira de bebidas 2', 12),
      ('Geladeira de cerveja',   13)
    ) as p(nome, ord)
   where not exists (
     select 1 from temperature_points t where t.org_id = v_org and t.nome = p.nome
   );

  select count(*) into n from temperature_points where org_id = v_org;
  raise notice 'Pontos cadastrados na Tacomex: %', n;
end
$seed$;


-- Conferência do que entrou (o resultado desta consulta é o que
-- aparece na tela do SQL Editor depois do Run).
select
  (select count(*) from temperature_standards where norma='CVS-3/2026')            as linhas_da_norma,
  (select count(*) from temperature_points p join organizacoes o on o.id=p.org_id
     where o.nome='Tacomex')                                                        as pontos_tacomex,
  (select count(*) from temperature_points p join organizacoes o on o.id=p.org_id
     where o.nome='Tacomex' and p.criticidade='SANITARIO')                          as sanitarios,
  (select count(*) from temperature_points p join organizacoes o on o.id=p.org_id
     where o.nome='Tacomex' and p.criticidade='OPERACIONAL')                        as operacionais,
  (select id from organizacoes where nome='Tacomex')                                as org_id_tacomex;


-- ============================================================
-- PARTE 3 — A PESSOA (já resolvido em 30/08/2026)
--
-- Não é preciso fazer nada aqui. Ficou assim:
--
-- O usuário admtacomex@hotmail.com JÁ EXISTIA e já era o login
-- do app de etiquetas. O perfil dele apontava para uma
-- organização chamada "Restaurante Teste".
--
-- Como uma pessoa pertence a UMA organização só, manter duas
-- (uma com as etiquetas, outra com os pontos de temperatura)
-- deixaria o mesmo login sem enxergar metade do produto.
--
-- Decisão: a organização existente foi RENOMEADA para 'Tacomex'
-- e os 13 pontos foram migrados para ela. A organização
-- 'Tacomex' vazia, criada pela Parte 2, foi removida.
--
-- Estado final — uma organização só:
--   nome     Tacomex
--   org_id   05f4b25d-51d7-4084-aed9-6bea5cc41c68
--   pessoas  1  (admtacomex@hotmail.com, papel 'dono')
--   produtos, histórico de etiquetas e 13 pontos, juntos.
--
-- Por isso a Parte 2 acima é idempotente: rodada de novo, ela
-- encontra a organização 'Tacomex' já existente e não duplica
-- nem a organização nem os pontos.
--
-- Para adicionar OUTRA pessoa a esta organização no futuro:
--   1) Authentication → Users → Add user
--   2) copie o UID e rode:
--      insert into perfis (id, org_id, nome, papel)
--      select 'COLE_O_UID_AQUI', id, 'Nome da pessoa', 'dono'
--        from organizacoes where nome = 'Tacomex';
--   3) peça para ela usar "Esqueci minha senha" no app, para
--      definir a senha dela mesma — assim você não precisa
--      mandar senha por mensagem.
-- ============================================================
