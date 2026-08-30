-- ============================================================
-- SAES FOOD LAB — OPERAÇÃO SEGURA
-- Fase 9-A: Monitoramento de Temperatura
--
-- Referência: Portaria CVS-3, de 03/07/2026 (CVS/SP).
-- Publicada em 06/07/2026, vigência a partir de ~04/10/2026,
-- revogando a CVS-5/2013.
--
-- Como usar: Supabase → SQL Editor → New query → colar → Run.
-- Pode rodar mais de uma vez: é ADITIVO e IDEMPOTENTE.
-- Não contém nenhum DROP de tabela existente.
-- ============================================================

-- ############################################################
-- #  REGRA FIXA DESTE PROJETO — LEIA ANTES DE CRIAR QUALQUER
-- #  TABELA NOVA NO SUPABASE:
-- #
-- #  Toda tabela nova nasce SEM row level security. Enquanto
-- #  ela estiver assim, a chave publicável do app — que é
-- #  pública, está no código e no GitHub Pages — dá acesso de
-- #  leitura E escrita a qualquer pessoa da internet.
-- #
-- #  Portanto: "enable row level security" + política explícita
-- #  são OBRIGATÓRIOS antes de qualquer dado entrar na tabela.
-- #
-- #  Isto já aconteceu neste projeto: a tabela `avaliacoes`
-- #  ficou aberta e foi fechada em 30/08/2026.
-- ############################################################


-- ============================================================
-- 1. TABELAS
-- ============================================================

-- ---------- temperature_standards ----------
-- A norma, em forma de dados. Global: não pertence a nenhum
-- restaurante, porque lei é pública.
-- Quando a norma mudar, trocam-se LINHAS, não código.
-- O campo `artigo` é o que sai impresso no registro e é o que
-- dá valor probatório numa fiscalização.
create table if not exists temperature_standards (
  id              uuid primary key default gen_random_uuid(),
  norma           text not null,
  artigo          text not null,
  contexto        text not null check (contexto in ('RECEBIMENTO','ARMAZENAMENTO','EQUIPAMENTO','EXPOSICAO','PROCESSO')),
  categoria       text not null,
  temp_min        numeric,
  temp_max        numeric,
  validade_dias   integer,
  tempo_max_horas numeric,
  vigente_desde   date not null,
  vigente_ate     date,
  created_at      timestamptz not null default now(),
  unique (norma, artigo, categoria)
);

-- ---------- temperature_points ----------
-- Onde se mede. Um ponto por equipamento ou local.
create table if not exists temperature_points (
  id            uuid primary key default gen_random_uuid(),
  org_id        uuid not null references organizacoes(id) on delete cascade,
  unidade_id    uuid,
  nome          text not null,
  area          text,
  regime        text not null check (regime in ('RECEBIMENTO','ARMAZENAMENTO','EQUIPAMENTO','EXPOSICAO')),
  criticidade   text not null check (criticidade in ('SANITARIO','OPERACIONAL')),
  standard_id   uuid references temperature_standards(id),
  temp_min      numeric,
  temp_max      numeric,
  ordem_rodada  integer not null default 0,
  ativo         boolean not null default true,
  created_at    timestamptz not null default now(),
  constraint ponto_precisa_de_faixa
    check (standard_id is not null or temp_min is not null or temp_max is not null)
);

-- ---------- temperature_rounds ----------
-- Uma passagem pela cozinha. Art. 48 exige no mínimo 2 por dia.
create table if not exists temperature_rounds (
  id                 uuid primary key default gen_random_uuid(),
  org_id             uuid not null references organizacoes(id) on delete cascade,
  unidade_id         uuid,
  turno              text not null check (turno in ('MANHA','TARDE','NOITE','EXTRA')),
  iniciada_em        timestamptz not null default now(),
  finalizada_em      timestamptz,
  status             text not null default 'EM_ANDAMENTO'
                       check (status in ('EM_ANDAMENTO','COMPLETA','INCOMPLETA')),
  pontos_esperados   integer not null,
  pontos_registrados integer not null default 0,
  executada_por      uuid not null default auth.uid()
);

-- ---------- temperature_readings ----------
-- O registro sanitário em si. NÃO SE EDITA E NÃO SE APAGA.
-- Correção de valor errado = nova leitura com observação.
create table if not exists temperature_readings (
  id                uuid primary key default gen_random_uuid(),
  org_id            uuid not null references organizacoes(id) on delete cascade,
  unidade_id        uuid,
  round_id          uuid not null references temperature_rounds(id),
  point_id          uuid not null references temperature_points(id),
  temperatura       numeric not null,
  status            text not null check (status in ('OK','ALERTA','CRITICO')),
  temp_min_snapshot numeric,
  temp_max_snapshot numeric,
  standard_snapshot text not null,
  acao_corretiva    text,
  observacao        text,
  registrado_por    uuid not null,
  registrado_em     timestamptz not null,
  constraint fora_da_faixa_exige_acao
    check (status = 'OK' or (acao_corretiva is not null and length(btrim(acao_corretiva)) > 0))
);

create index if not exists temperature_points_org_idx     on temperature_points (org_id, ativo, ordem_rodada);
create index if not exists temperature_rounds_org_idx     on temperature_rounds (org_id, iniciada_em desc);
create index if not exists temperature_readings_org_idx   on temperature_readings (org_id, registrado_em desc);
create index if not exists temperature_readings_round_idx on temperature_readings (round_id);
create index if not exists temperature_readings_point_idx on temperature_readings (point_id, registrado_em desc);


-- ============================================================
-- 2. TRIGGERS — o que o app NÃO decide
--
-- O celular da cozinha não decide se a temperatura está fora da
-- faixa, e não decide que horas são. Hora errada em aparelho de
-- cozinha é comum, e isto aqui é documento sanitário.
-- ============================================================

create or replace function temperature_readings_preencher()
returns trigger
language plpgsql
security definer
set search_path = public
as $fn$
declare
  v_org     uuid;
  v_unidade uuid;
  v_std     uuid;
  v_pmin    numeric;
  v_pmax    numeric;
  s_min     numeric;
  s_max     numeric;
  s_norma   text;
  s_artigo  text;
  vmin      numeric;
  vmax      numeric;
  desvio    numeric := 0;
  margem    constant numeric := 2;
begin
  select org_id, unidade_id, standard_id, temp_min, temp_max
    into v_org, v_unidade, v_std, v_pmin, v_pmax
    from temperature_points
   where id = new.point_id;

  if v_org is null then
    raise exception 'Ponto de medição não encontrado.';
  end if;

  new.org_id         := v_org;
  new.unidade_id     := v_unidade;
  new.registrado_em  := now();
  new.registrado_por := auth.uid();

  if v_std is not null then
    select temp_min, temp_max, norma, artigo
      into s_min, s_max, s_norma, s_artigo
      from temperature_standards
     where id = v_std;
  end if;

  vmin := coalesce(v_pmin, s_min);
  vmax := coalesce(v_pmax, s_max);

  new.temp_min_snapshot := vmin;
  new.temp_max_snapshot := vmax;
  new.standard_snapshot := case
    when s_norma is null then 'Faixa definida pelo estabelecimento'
    when v_pmin is null and v_pmax is null then s_norma || ' ' || s_artigo
    else s_norma || ' ' || s_artigo || ' (faixa do fabricante)'
  end;

  if vmin is not null and new.temperatura < vmin then
    desvio := vmin - new.temperatura;
  end if;
  if vmax is not null and new.temperatura > vmax then
    desvio := greatest(desvio, new.temperatura - vmax);
  end if;

  new.status := case
    when desvio = 0       then 'OK'
    when desvio <= margem then 'ALERTA'
    else 'CRITICO'
  end;

  return new;
end
$fn$;

drop trigger if exists trg_readings_preencher on temperature_readings;
create trigger trg_readings_preencher
  before insert on temperature_readings
  for each row execute function temperature_readings_preencher();


create or replace function temperature_rounds_progresso()
returns trigger
language plpgsql
security definer
set search_path = public
as $fn$
declare
  v_total     integer;
  v_esperados integer;
begin
  select count(*) into v_total
    from temperature_readings where round_id = new.round_id;

  select pontos_esperados into v_esperados
    from temperature_rounds where id = new.round_id;

  update temperature_rounds
     set pontos_registrados = v_total,
         status        = case when v_total >= v_esperados then 'COMPLETA' else status end,
         finalizada_em = case when v_total >= v_esperados then now() else finalizada_em end
   where id = new.round_id;

  return null;
end
$fn$;

drop trigger if exists trg_rounds_progresso on temperature_readings;
create trigger trg_rounds_progresso
  after insert on temperature_readings
  for each row execute function temperature_rounds_progresso();


-- ============================================================
-- 3. ISOLAMENTO ENTRE RESTAURANTES (RLS)
--
-- Mesmo padrão já validado no app de etiquetas:
-- org_id da linha = org_id do perfil de quem está logado.
-- ============================================================

alter table temperature_standards enable row level security;
alter table temperature_points    enable row level security;
alter table temperature_rounds    enable row level security;
alter table temperature_readings  enable row level security;

-- standards: norma é pública. Quem está logado lê; ninguém escreve
-- pelo app (mudança de norma é feita por você, aqui no SQL Editor).
drop policy if exists "ler norma publica" on temperature_standards;
create policy "ler norma publica" on temperature_standards
  for select to authenticated using (true);

-- points e rounds: acesso completo dentro do próprio restaurante.
-- Sem papel/role: qualquer pessoa da org edita.
drop policy if exists "acesso pontos da propria org" on temperature_points;
create policy "acesso pontos da propria org" on temperature_points
  for all using (org_id = (select org_id from perfis where id = auth.uid()))
      with check (org_id = (select org_id from perfis where id = auth.uid()));

drop policy if exists "acesso rodadas da propria org" on temperature_rounds;
create policy "acesso rodadas da propria org" on temperature_rounds
  for all using (org_id = (select org_id from perfis where id = auth.uid()))
      with check (org_id = (select org_id from perfis where id = auth.uid()));

-- readings: LER e CRIAR. Nada mais.
-- Não existe política de UPDATE nem de DELETE, de propósito.
-- Registro sanitário não se edita e não se apaga (Art. 181 manda
-- guardar por no mínimo 180 dias). Corrigir = nova leitura.
drop policy if exists "ler leituras da propria org" on temperature_readings;
create policy "ler leituras da propria org" on temperature_readings
  for select using (org_id = (select org_id from perfis where id = auth.uid()));

drop policy if exists "criar leitura na propria org" on temperature_readings;
create policy "criar leitura na propria org" on temperature_readings
  for insert with check (org_id = (select org_id from perfis where id = auth.uid()));

-- Segunda camada: mesmo que alguém crie uma política de update ou
-- delete por engano no futuro, o papel usado pelo app não tem a
-- permissão no nível da tabela.
revoke update, delete on temperature_readings from authenticated;
revoke update, delete on temperature_readings from anon;

-- ============================================================
-- Fim da estrutura.
-- O seed da norma e dos pontos está em: temperatura-seed.sql
-- ============================================================
