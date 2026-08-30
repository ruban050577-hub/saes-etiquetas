/* ============================================================
   SAES FOOD LAB — CONTEXTO DE ORGANIZAÇÃO (tenant)
   Compartilhado por: index.html (Etiquetas) e temperatura.html

   Uma pessoa pertence a UM restaurante. Toda tabela de dados
   carrega org_id, e o isolamento real é feito pelo RLS no banco.
   Estas variáveis são globais de propósito: o app usa scripts
   clássicos (não módulos), e o HTML chama funções por onclick.
   ============================================================ */

let ORG_ID = null;
let USER_ID = null;

/* Lê o perfil da pessoa logada e preenche ORG_ID / USER_ID.
   Devolve {ok:true} ou {ok:false, motivo:'...'} — quem chama decide
   o que fazer com a falha (mostrar mensagem, deslogar, redirecionar). */
async function carregarContextoOrg(session){
  if(!session) return {ok:false, motivo:'sem-sessao'};
  USER_ID = session.user.id;
  const {data:perfil,error} = await sb.from('perfis').select('org_id,nome').eq('id',USER_ID).single();
  if(error || !perfil) return {ok:false, motivo:'sem-perfil'};
  ORG_ID = perfil.org_id;
  return {ok:true, perfil};
}

function limparContextoOrg(){ ORG_ID = null; USER_ID = null; }

/* Para páginas protegidas que NÃO têm tela de login própria
   (temperatura.html). Se não houver sessão válida, manda para o
   login do etiquetas, que é a porta de entrada única do produto. */
async function exigirSessao(paginaDeLogin){
  const {data:{session}} = await sb.auth.getSession();
  const ctx = await carregarContextoOrg(session);
  if(!ctx.ok){ window.location.href = paginaDeLogin || 'index.html'; return null; }
  return session;
}
