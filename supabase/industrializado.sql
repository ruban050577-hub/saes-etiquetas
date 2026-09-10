-- ============================================================
-- SAES FOOD LAB — Etiquetas
-- Categoria "Industrializado — retirado da embalagem"
--
-- Base legal: RDC 216/2004, item 4.8.6 (ANVISA).
-- Produto industrializado que sai da embalagem original do
-- fabricante e vai para recipiente de uso interno conta como
-- "retirada da embalagem original". Vale o prazo após aberto
-- declarado pelo fabricante, e nunca além da validade original.
--
-- Como usar: Supabase → SQL Editor → New query → colar → Run.
-- ADITIVO e IDEMPOTENTE. Nenhum DROP de tabela.
--
-- Lembrete da regra do projeto: tabela nova nasce sem RLS e exige
-- enable + política explícita. Aqui não há tabela nova — só uma
-- coluna em `produtos`, que já tem RLS por org_id.
-- ============================================================

-- ---------- 1. a coluna ----------
-- null = preparado internamente (todo o comportamento atual).
-- Nenhum produto existente muda: todos ficam com null.
alter table produtos add column if not exists categoria text;

alter table produtos drop constraint if exists produtos_categoria_valida;
alter table produtos add constraint produtos_categoria_valida
  check (categoria is null or categoria in ('industrializado_fracionado'));

comment on column produtos.categoria is
  'null = preparado internamente (CVS-3/2026). industrializado_fracionado = retirado da embalagem original do fabricante (RDC 216/2004 item 4.8.6): prazo vem do rotulo do fabricante, nao de tabela da norma.';


-- ---------- 2. os dois métodos da categoria ----------
-- Prazo 0 de propósito: não existe tabela da norma para produto de
-- fabricante. Cada rótulo declara o seu, e o app exige que o prazo
-- seja digitado no cadastro do produto.
-- Semeados em todas as organizações que ainda não os têm.
insert into metodos (org_id, nome, familia, horas)
select o.id, m.nome, m.familia, m.horas
  from organizacoes o
 cross join (values
   ('Industrializado aberto — refrigerado', 'Resfriado', 0),
   ('Industrializado aberto — ambiente',    'Ambiente',  0)
 ) as m(nome, familia, horas)
 where not exists (
   select 1 from metodos x where x.org_id = o.id and x.nome = m.nome
 );


-- ---------- conferência ----------
select
  (select count(*) from information_schema.columns
    where table_name='produtos' and column_name='categoria')            as coluna_criada,
  (select count(*) from produtos where categoria is not null)           as produtos_na_categoria_nova,
  (select count(*) from produtos)                                       as produtos_no_total,
  (select count(*) from metodos where nome like 'Industrializado aberto%') as metodos_criados,
  (select count(*) from organizacoes)                                   as organizacoes;
