/* ============================================================
   SAES FOOD LAB — ATUALIZAÇÃO AUTOMÁTICA
   Compartilhado por: index.html, temperatura.html e menu.html

   O problema: celular e tablet de cozinha deixam o app aberto por
   dias. Ao voltar para ele, o navegador "descongela" a aba da
   memória SEM baixar a página de novo — e mostra a versão antiga.
   Foi assim que a Temperatura e depois o campo Categoria "sumiram".

   A solução: sempre que o app volta a ficar visível (e a cada 5
   minutos com ele aberto), pergunta ao servidor a assinatura dos
   arquivos (ETag). Se mudou desde que a página foi carregada,
   recarrega sozinho.

   Nunca recarrega no meio de um trabalho: com um formulário aberto
   ou uma rodada de temperatura em andamento, espera a próxima vez.
   ============================================================ */
(function(){
  const pagina = location.pathname.split('/').pop() || 'index.html';
  let assinaturaInicial = null;

  function arquivosDaPagina(){
    const proprios = [...document.querySelectorAll('link[rel="stylesheet"][href^="shared/"], script[src^="shared/"]')]
      .map(el => el.getAttribute('href') || el.getAttribute('src'));
    return [pagina, ...proprios];
  }

  async function assinaturaNoServidor(){
    try{
      const partes = await Promise.all(arquivosDaPagina().map(async arq => {
        const r = await fetch(arq, {method:'HEAD', cache:'no-store'});
        if(!r.ok) return null;
        return r.headers.get('ETag') || r.headers.get('Last-Modified');
      }));
      if(partes.some(p => !p)) return null;   // servidor sem assinatura: não arrisca
      return partes.join('|');
    }catch(e){ return null; }                 // sem internet: tenta na próxima
  }

  function ocupado(){
    if(document.querySelector('.overlay.open')) return true;          // formulário aberto
    if(typeof RD !== 'undefined' && RD) return true;                   // rodada de temperatura
    return false;
  }

  async function verificar(){
    const atual = await assinaturaNoServidor();
    if(!atual) return;
    if(assinaturaInicial === null){ assinaturaInicial = atual; return; }
    if(atual !== assinaturaInicial && !ocupado()) location.reload();
  }

  verificar();
  document.addEventListener('visibilitychange', () => {
    if(document.visibilityState === 'visible') verificar();
  });
  // pageshow cobre a aba restaurada do cache de navegação (voltar/avançar)
  window.addEventListener('pageshow', e => { if(e.persisted) verificar(); });
  setInterval(() => { if(document.visibilityState === 'visible') verificar(); }, 5 * 60 * 1000);
})();
