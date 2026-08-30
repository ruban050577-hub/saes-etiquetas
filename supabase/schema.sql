-- ============================================================
-- SAES FOOD LAB — Etiquetas de Validade
-- Schema do banco (Supabase / Postgres) — v2 (acompanha o app v3,
-- com métodos de conservação como cadastro editável por restaurante)
--
-- Como usar: Supabase → seu projeto → SQL Editor → New query →
-- colar este arquivo inteiro → Run.
-- ============================================================

-- ---------- organizacoes (restaurantes) ----------
-- Um restaurante = onde os dados moram. Cada cliente é uma linha aqui.
create table if not exists organizacoes (
  id                 uuid primary key default gen_random_uuid(),
  nome               text not null,
  cnpj               text,
  responsavel_padrao text,
  created_at         timestamptz not null default now()
);

-- ---------- perfis (pessoas que fazem login) ----------
-- Uma pessoa pertence a um restaurante. Um restaurante pode ter várias
-- pessoas (a estrutura já suporta isso, mesmo sem tela ainda).
-- O id daqui é o MESMO id do usuário criado em Authentication > Users.
create table if not exists perfis (
  id         uuid primary key references auth.users(id) on delete cascade,
  org_id     uuid not null references organizacoes(id) on delete cascade,
  nome       text,
  papel      text not null default 'dono',
  created_at timestamptz not null default now()
);

-- ---------- métodos de conservação (cadastro editável por restaurante) ----------
-- Cada restaurante tem sua própria lista, semeada automaticamente pelo app
-- (biblioteca padrão CVS-3/2026) no primeiro acesso, e livremente editável.
drop table if exists metodos cascade;
create table metodos (
  id         uuid primary key default gen_random_uuid(),
  org_id     uuid not null references organizacoes(id) on delete cascade,
  nome       text not null,
  familia    text not null,
  horas      integer not null,
  created_at timestamptz not null default now()
);

-- ---------- produtos cadastrados ----------
-- Cada produto guarda a lista de métodos em que pode ser conservado,
-- com prazo próprio (override) opcional por método: [{mid, horas}, ...]
drop table if exists produtos cascade;
create table produtos (
  id         uuid primary key default gen_random_uuid(),
  org_id     uuid not null references organizacoes(id) on delete cascade,
  unidade_id uuid, -- reservado para múltiplas unidades (não usado ainda)
  nome       text not null,
  grupo      text,
  sif        text,
  fabricante text,
  marca      text,
  metodos    jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ---------- histórico de etiquetas impressas ----------
drop table if exists historico_impressoes cascade;
create table historico_impressoes (
  id          uuid primary key default gen_random_uuid(),
  org_id      uuid not null references organizacoes(id) on delete cascade,
  unidade_id  uuid, -- reservado para múltiplas unidades (não usado ainda)
  tipo        text not null default 'produto', -- 'produto' ou 'avulso'
  produto     text not null,
  metodo      text, -- nome do método usado, guardado como texto (histórico não muda se o método for editado depois)
  responsavel text,
  sif         text,
  lote        text,
  qtd         integer not null default 1,
  preparo     timestamptz,
  validade    timestamptz,
  created_at  timestamptz not null default now()
);

-- índices para as consultas mais comuns (listar dados de um restaurante)
create index if not exists metodos_org_id_idx on metodos (org_id);
create index if not exists produtos_org_id_idx on produtos (org_id);
create index if not exists historico_impressoes_org_id_idx on historico_impressoes (org_id);
create index if not exists perfis_org_id_idx on perfis (org_id);

-- ============================================================
-- ISOLAMENTO ENTRE CLIENTES (Row Level Security)
--
-- Regra única: uma pessoa só enxerga/edita linhas cujo org_id bate com
-- o org_id do seu próprio perfil. Isso roda dentro do banco, então
-- protege os dados mesmo que haja algum bug no app.
-- ============================================================

alter table organizacoes         enable row level security;
alter table perfis               enable row level security;
alter table metodos              enable row level security;
alter table produtos             enable row level security;
alter table historico_impressoes enable row level security;

-- perfis: cada pessoa só vê e atualiza a própria linha.
-- (criar um perfil novo é feito por você, manualmente, com privilégio de
-- administrador no painel — não existe política de "insert" aqui de propósito,
-- para o app nunca conseguir criar contas sozinho.)
drop policy if exists "ver proprio perfil" on perfis;
create policy "ver proprio perfil" on perfis
  for select using (id = auth.uid());

drop policy if exists "editar proprio perfil" on perfis;
create policy "editar proprio perfil" on perfis
  for update using (id = auth.uid());

-- organizacoes: pessoa só vê e atualiza o restaurante ao qual pertence.
-- (criar um restaurante novo também é feito por você, manualmente — sem
-- política de "insert" de propósito.)
drop policy if exists "ver propria organizacao" on organizacoes;
create policy "ver propria organizacao" on organizacoes
  for select using (
    id = (select org_id from perfis where id = auth.uid())
  );

drop policy if exists "editar propria organizacao" on organizacoes;
create policy "editar propria organizacao" on organizacoes
  for update using (
    id = (select org_id from perfis where id = auth.uid())
  );

-- metodos: acesso completo, mas só dentro do próprio restaurante.
create policy "acesso metodos da propria org" on metodos
  for all using (
    org_id = (select org_id from perfis where id = auth.uid())
  )
  with check (
    org_id = (select org_id from perfis where id = auth.uid())
  );

-- produtos: acesso completo, mas só dentro do próprio restaurante.
create policy "acesso produtos da propria org" on produtos
  for all using (
    org_id = (select org_id from perfis where id = auth.uid())
  )
  with check (
    org_id = (select org_id from perfis where id = auth.uid())
  );

-- historico_impressoes: mesma regra.
create policy "acesso historico da propria org" on historico_impressoes
  for all using (
    org_id = (select org_id from perfis where id = auth.uid())
  )
  with check (
    org_id = (select org_id from perfis where id = auth.uid())
  );

-- ============================================================
-- Fim do schema.
-- ============================================================
