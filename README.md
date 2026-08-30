# Etiquetas de Validade — Saes Food Lab

App de impressão de etiquetas de validade para cozinha de restaurante.
Login por email/senha, dados no Supabase, cada restaurante isolado dos
demais. Ver `desenho-backend-etiquetas.md` (na pasta de decisões) para o
histórico completo das decisões de produto.

## Estrutura deste projeto

- `index.html` — o app inteiro (não precisa de instalação nem de build).
- `supabase/schema.sql` — script que cria as tabelas e as regras de
  segurança no Supabase. Roda uma vez só, no início.

## 1. Ligar o app ao seu projeto Supabase (uma vez só)

1. Rode o `supabase/schema.sql`: no painel do Supabase, abra seu projeto →
   **SQL Editor** → **New query** → cole o conteúdo do arquivo → **Run**.
2. Pegue os dois valores do seu projeto: painel do Supabase → **Project
   Settings** → **API**:
   - **Project URL**
   - **anon public key** (a chave pública — não é a `service_role`, essa
     nunca deve ir para o app)
3. Abra `index.html` num editor de texto e troque, perto do topo do
   `<script>`:
   ```js
   const SUPABASE_URL = "COLE_AQUI_A_PROJECT_URL";
   const SUPABASE_ANON_KEY = "COLE_AQUI_A_ANON_KEY";
   ```
   pelos valores reais. Salve o arquivo.

## 2. Criar um novo restaurante (onboarding manual)

Sem tela de cadastro — cada restaurante novo é criado por você, à mão, em
três passos rápidos no painel do Supabase. Leva menos de dois minutos.

**Passo 1 — criar a pessoa (login):**
Painel do Supabase → **Authentication** → **Users** → **Add user**.
Preencha o email do cliente e uma senha provisória qualquer (ele vai trocar
no primeiro acesso). Depois de criado, copie o **UID** desse usuário (um
código tipo `a1b2c3d4-...`) — vai precisar dele no passo 3.

**Passo 2 — criar o restaurante:**
Painel do Supabase → **Table Editor** → tabela `organizacoes` → **Insert
row**. Preencha `nome` (obrigatório) e, se quiser, `cnpj`. Depois de salvar,
copie o `id` gerado para essa linha.

**Passo 3 — ligar a pessoa ao restaurante:**
Painel do Supabase → **Table Editor** → tabela `perfis` → **Insert row**.
- `id` → cole o UID do usuário (passo 1)
- `org_id` → cole o id do restaurante (passo 2)
- `nome` → nome da pessoa (opcional)
- `papel` → pode deixar `dono`

Pronto. Passe para o cliente: o link do app + o email cadastrado, e peça
para ele clicar em **"Esqueci minha senha"** na tela de login para definir
a senha dele mesmo (evita você ter que passar a senha provisória por
mensagem).

> Alternativa aos passos 2 e 3: em vez de usar o Table Editor, dá para
> rodar isso direto no SQL Editor:
> ```sql
> insert into organizacoes (nome) values ('Nome do Restaurante')
>   returning id;
> -- copie o id retornado e use abaixo
> insert into perfis (id, org_id, nome, papel)
>   values ('UID_DO_USUARIO', 'ID_DO_RESTAURANTE', 'Nome da pessoa', 'dono');
> ```

## 3. Testar localmente

Não abra o `index.html` clicando duas vezes nele (o link de redefinição de
senha por email não funciona bem em arquivo local `file://`). Sirva por um
servidor simples, por exemplo, dentro da pasta do projeto:

```bash
npx serve .
```

Isso abre o app em algo como `http://localhost:3000`. Se preferir, qualquer
outro servidor estático local funciona (Python `http.server`, extensão
"Live Server" do VS Code, etc.).

## 4. Publicar (quando estiver pronto para uso real)

O comentário no código já previa GitHub Pages como destino. Quando chegar
essa hora, é só publicar o conteúdo desta pasta lá — é um site 100%
estático, sem servidor próprio.

## Pendências que ficam fora do backend (ver documento de desenho)

- Testar impressão real na impressora Tomate MDK-006.
- Atualizar a tabela de métodos de conservação para o Art. 44 completo da
  CVS-3/2026.
- Revisar textos para nunca prometerem "conformidade" — o app é
  ferramenta, a responsabilidade legal é do responsável técnico/dono do
  estabelecimento.
- Tela de administrador, tela de segunda pessoa por restaurante, papéis
  diferentes de acesso, múltiplas unidades — tudo isso é próxima etapa,
  fechado como nova decisão antes de virar código.
