-- ============================================================
-- SAES FOOD LAB — Etiquetas de Validade
-- Schema inicial do banco (Supabase / Postgres)
--
-- Como usar: Supabase → seu projeto → SQL Editor → New query →
-- colar este arquivo inteiro → Run.
--
-- É seguro rodar em um banco vazio (novo projeto). Não rode duas
-- vezes sem antes apagar as tabelas — vai dar erro de "já existe".
-- ============================================================

-- ---------- organizacoes (restaurantes) ----------
-- Um restaurante = onde os dados moram. Cada cliente é uma linha aqui.
create table organizacoes (
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
create table perfis (
  id         uuid primary key references auth.users(id) on delete cascade,
  org_id     uuid not null references organizacoes(id) on delete cascade,
  nome       text,
  papel      text not null default 'dono',
  created_at timestamptz not null default now()
);

-- ---------- produtos cadastrados ----------
create table produtos (
  id             uuid primary key default gen_random_uuid(),
  org_id         uuid not null references organizacoes(id) on delete cascade,
  unidade_id     uuid, -- reservado para múltiplas unidades (não usado ainda)
  nome           text not null,
  categoria      text not null,
  temp           text,
  dias           integer,
  modo           text,
  sif            text,
  fabricante     text,
  marca          text,
  equipamento_id uuid,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);

-- ---------- histórico de etiquetas impressas ----------
create table historico_impressoes (
  id          uuid primary key default gen_random_uuid(),
  org_id      uuid not null references organizacoes(id) on delete cascade,
  unidade_id  uuid, -- reservado para múltiplas unidades (não usado ainda)
  produto     text not null,
  responsavel text,
  preparo     timestamptz,
  validade    timestamptz,
  modo        text,
  sif         text,
  lote        text,
  qtd         integer not null default 1,
  created_at  timestamptz not null default now()
);

-- índices para as consultas mais comuns (listar produtos/histórico de um restaurante)
create index produtos_org_id_idx on produtos (org_id);
create index historico_impressoes_org_id_idx on historico_impressoes (org_id);
create index perfis_org_id_idx on perfis (org_id);

-- ============================================================
-- ISOLAMENTO ENTRE CLIENTES (Row Level Security)
--
-- Regra única: uma pessoa só enxerga/edita linhas cujo org_id bate com
-- o org_id do seu próprio perfil. Isso roda dentro do banco, então
-- protege os dados mesmo que haja algum bug no app.
-- ============================================================

alter table organizacoes         enable row level security;
alter table perfis               enable row level security;
alter table produtos             enable row level security;
alter table historico_impressoes enable row level security;

-- perfis: cada pessoa só vê e atualiza a própria linha.
-- (criar um perfil novo é feito por você, manualmente, com privilégio de
-- administrador no painel — não existe política de "insert" aqui de propósito,
-- para o app nunca conseguir criar contas sozinho.)
create policy "ver proprio perfil" on perfis
  for select using (id = auth.uid());

create policy "editar proprio perfil" on perfis
  for update using (id = auth.uid());

-- organizacoes: pessoa só vê e atualiza o restaurante ao qual pertence.
-- (criar um restaurante novo também é feito por você, manualmente — sem
-- política de "insert" de propósito.)
create policy "ver propria organizacao" on organizacoes
  for select using (
    id = (select org_id from perfis where id = auth.uid())
  );

create policy "editar propria organizacao" on organizacoes
  for update using (
    id = (select org_id from perfis where id = auth.uid())
  );

-- produtos: acesso completo (ver, criar, editar, apagar), mas só dentro
-- do próprio restaurante.
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
-- Fim do schema inicial.
-- Próximo passo: criar o primeiro restaurante + primeira pessoa
-- (veja o README.md, seção "Criar um novo restaurante (onboarding)").
-- ============================================================
