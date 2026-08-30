/* ============================================================
   SAES FOOD LAB — CLIENTE SUPABASE E AUTENTICAÇÃO
   Compartilhado por: index.html (Etiquetas) e temperatura.html

   Painel do Supabase → seu projeto → Configurações → API:
   - Project URL
   - anon / publishable key
   Nenhum dos dois é secreto: são feitos para ficar no código do app.
   Quem protege os dados de cada restaurante é a regra RLS no banco.

   Sem tela de "criar conta": as contas são criadas manualmente
   pelo dono do negócio, direto no painel do Supabase.

   A sessão fica no localStorage do navegador, então qualquer página
   do mesmo endereço (etiquetas, temperatura) já entra logada.

   CONTRATO DE DOM — a página que mostrar a tela de login precisa ter
   os elementos: tela-login, app-root, login-form, esqueci-form,
   nova-senha-form, login-email, login-senha, reset-email, nova-senha,
   e as áreas de mensagem login-msg, reset-msg, nova-senha-msg.
   Páginas sem login (temperatura.html) usam exigirSessao() do org.js.

   GANCHOS — a página define, se quiser:
   window.aoEntrarNoApp  → roda depois do login, com ORG_ID já preenchido
   window.aoSair         → roda antes do logout, para limpar a memória
   ============================================================ */

const SUPABASE_URL = "https://aqcczkevyycvsvjvhrdx.supabase.co";
const SUPABASE_ANON_KEY = "sb_publishable_b92iL0z7pryXIuZ1NeLz4A_6MKgXIc_";
const sb = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

/* ---------- telas ---------- */
function mostrarTelaLogin(){ document.getElementById('tela-login').classList.add('open'); document.getElementById('app-root').style.display='none'; }
function mostrarApp(){ document.getElementById('tela-login').classList.remove('open'); document.getElementById('app-root').style.display='flex'; }
function mostrarLoginForm(){ document.getElementById('login-form').style.display=''; document.getElementById('esqueci-form').style.display='none'; document.getElementById('nova-senha-form').style.display='none'; }
function mostrarEsqueciSenha(){ document.getElementById('login-form').style.display='none'; document.getElementById('esqueci-form').style.display=''; document.getElementById('nova-senha-form').style.display='none'; }
function mostrarNovaSenha(){ document.getElementById('login-form').style.display='none'; document.getElementById('esqueci-form').style.display='none'; document.getElementById('nova-senha-form').style.display=''; }
function loginMsg(id,texto,tipo){ const el=document.getElementById(id); el.textContent=texto; el.className='login-msg'+(tipo?' '+tipo:''); }

/* ---------- entrar, recuperar senha, sair ---------- */
async function fazerLogin(){
  const email = document.getElementById('login-email').value.trim();
  const senha = document.getElementById('login-senha').value;
  if(!email||!senha){ loginMsg('login-msg','Preencha email e senha.','err'); return; }
  loginMsg('login-msg','Entrando...','');
  const {data,error} = await sb.auth.signInWithPassword({email,password:senha});
  if(error){ loginMsg('login-msg','Não foi possível entrar. Confira email e senha.','err'); return; }
  await entrarNoApp(data.session);
}
async function enviarResetSenha(){
  const email = document.getElementById('reset-email').value.trim();
  if(!email){ loginMsg('reset-msg','Informe seu email.','err'); return; }
  loginMsg('reset-msg','Enviando...','');
  const {error} = await sb.auth.resetPasswordForEmail(email,{redirectTo:window.location.href.split('#')[0].split('?')[0]});
  if(error){ loginMsg('reset-msg','Não foi possível enviar. Confira o email.','err'); return; }
  loginMsg('reset-msg','Se esse email existir na nossa base, enviamos um link. Confira sua caixa de entrada.','ok');
}
async function salvarNovaSenha(){
  const senha = document.getElementById('nova-senha').value;
  if(!senha||senha.length<6){ loginMsg('nova-senha-msg','A senha precisa ter pelo menos 6 caracteres.','err'); return; }
  loginMsg('nova-senha-msg','Salvando...','');
  const {error} = await sb.auth.updateUser({password:senha});
  if(error){ loginMsg('nova-senha-msg','Não foi possível salvar. Peça um novo link em "Esqueci minha senha".','err'); return; }
  try{ history.replaceState(null,'',window.location.pathname); }catch(e){}
  if(typeof toast === 'function') toast('Senha atualizada.');
  const {data:{session}} = await sb.auth.getSession();
  await entrarNoApp(session);
}
async function fazerLogout(){
  if(!confirm('Sair da conta?')) return;
  await sb.auth.signOut();
  limparContextoOrg();
  if(typeof window.aoSair === 'function') window.aoSair();
  document.getElementById('login-email').value=''; document.getElementById('login-senha').value='';
  mostrarLoginForm(); mostrarTelaLogin();
}

/* ---------- ciclo de entrada ---------- */
async function entrarNoApp(session){
  if(!session){ mostrarLoginForm(); mostrarTelaLogin(); return; }
  const ctx = await carregarContextoOrg(session);
  if(!ctx.ok){
    loginMsg('login-msg','Sua conta ainda não está vinculada a nenhum restaurante. Fale com o suporte.','err');
    await sb.auth.signOut(); mostrarLoginForm(); mostrarTelaLogin(); return;
  }
  if(typeof window.aoEntrarNoApp === 'function') await window.aoEntrarNoApp();
  mostrarApp();
}
function isRecoveryUrl(){
  const h = window.location.hash||""; const q = window.location.search||"";
  return h.includes('type=recovery') || q.includes('type=recovery');
}
async function initAuth(){
  let modoRecuperacao = isRecoveryUrl();
  sb.auth.onAuthStateChange((event) => {
    if(event === 'PASSWORD_RECOVERY'){ modoRecuperacao = true; mostrarNovaSenha(); mostrarTelaLogin(); }
  });
  const {data:{session}} = await sb.auth.getSession();
  if(modoRecuperacao){ mostrarNovaSenha(); mostrarTelaLogin(); return; }
  await entrarNoApp(session);
}
