# Dashboard TV

Exibe um painel web em tela cheia numa TV via iframe, servido por nginx no Docker. Inclui autenticação por senha (HTTP Basic Auth), restrição por IP de rede local, auto-refresh, anti-idle e overlay com a URL de acesso.

## Estrutura

```
dashboard-tv/
├── docker-compose.yml   # Serviço nginx
├── nginx.conf           # Configuração do servidor (allowlist de IPs + Basic Auth)
├── .htpasswd            # Credenciais de acesso (gerado localmente, não vai ao Git)
├── .gitignore           # Ignora .htpasswd, PDFs e arquivos de editor
├── show_ip.ps1          # Exibe a URL local para digitar na TV
└── html/
    └── index.html       # Página principal com iframe do dashboard
```

## Pré-requisitos

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (Windows)
- PowerShell 5+

---

## Configuração inicial

### 1. Defina a URL do dashboard

Abra [html/index.html](html/index.html) e substitua `__SET_URL_HERE__` pela URL do seu painel (ex: Google Sheets publicado, Looker Studio, Grafana):

```html
<iframe src="https://seu-painel.exemplo.com" ...>
```

> Se o painel exigir login (ex: Google restrito ao domínio da empresa), faça login com a conta da TV no browser antes de subir o serviço.

### 2. Gere o arquivo de senha (.htpasswd)

O `.htpasswd` armazena as credenciais de acesso ao dashboard. Ele **não vai ao GitHub** (está no `.gitignore`) e deve ser gerado localmente em cada máquina onde o projeto for executado.

Execute o comando abaixo, substituindo `seu-usuario` e `sua-senha`:

```bash
docker run --rm httpd:alpine htpasswd -nbB seu-usuario sua-senha > .htpasswd
```

Exemplo:

```bash
docker run --rm httpd:alpine htpasswd -nbB dashboard minhasenha > .htpasswd
```

> O hash gerado usa bcrypt (`-B`), seguro contra ataques de força bruta.

### 3. Ajuste a faixa de IP da sua rede (se necessário)

O nginx permite acesso apenas a IPs da rede local. Verifique sua faixa com `ipconfig` e edite [nginx.conf](nginx.conf):

```nginx
allow 192.168.1.0/24;   # ajuste para a sua sub-rede
```

As faixas `172.16.0.0/12` e `192.168.65.0/24` já estão inclusas para o Docker Desktop no Windows.

---

## Uso

### Subir o serviço

```bash
docker compose up -d
```

### Descobrir a URL para digitar na TV

```powershell
.\show_ip.ps1
```

Saída esperada:

```
==================================
  Digite na TV:
  http://192.168.1.118:8080
==================================
```

### Parar o serviço

```bash
docker compose down
```

### Ver logs

```bash
docker compose logs -f
```

---

## Replicação em outra máquina

Passos para subir o projeto em um novo computador (ex: notebook do trabalho):

1. Clonar o repositório:
   ```bash
   git clone https://github.com/seu-usuario/dashboard-tv.git
   cd dashboard-tv
   ```

2. Gerar o `.htpasswd` localmente (use o mesmo usuário e senha do ambiente original):
   ```bash
   docker run --rm httpd:alpine htpasswd -nbB seu-usuario sua-senha > .htpasswd
   ```

3. Confirmar que a URL do dashboard está configurada em `html/index.html`.

4. Subir o serviço:
   ```bash
   docker compose up -d
   ```

5. Descobrir o IP local:
   ```powershell
   .\show_ip.ps1
   ```

6. Apontar a TV para a URL exibida.

---

## Recursos do index.html

| Recurso | Comportamento |
|---|---|
| Auto-refresh | Recarrega a página a cada 150 s |
| Anti-idle (título) | Atualiza o `<title>` a cada 10 s para evitar suspensão |
| Anti-idle (scroll) | Scroll mínimo no iframe a cada 30 s |
| Anti-idle (visibilidade) | Recarrega se a aba ficou oculta por mais de 10 min |
| Wake Lock API | Solicita ao SO que mantenha a tela ligada |
| Overlay de IP | Exibe a URL de acesso no canto inferior direito por 10 s |

---

## Segurança

### Autenticação (HTTP Basic Auth)

Todo acesso à porta 8080 exige usuário e senha. As credenciais ficam no arquivo `.htpasswd`, montado como volume somente-leitura no container. O arquivo nunca é versionado no Git.

> Em HTTP (sem TLS), a senha trafega em Base64. Para redes corporativas, é recomendável adicionar um certificado local com `mkcert` ou usar um Cloudflare Tunnel com domínio próprio para obter HTTPS.

### Restrição por IP

O nginx bloqueia qualquer IP fora das faixas configuradas, retornando 403. Acesso liberado por padrão:

| Faixa | Uso |
|---|---|
| `127.0.0.1` / `::1` | Loopback (localhost) |
| `192.168.1.0/24` | Rede local Wi-Fi/Ethernet (ajuste conforme sua rede) |
| `192.168.0.0/24` | Rede local alternativa |
| `10.0.0.0/24` | Rede corporativa (ajuste conforme necessário) |
| `172.16.0.0/12` | Bridge Docker padrão |
| `192.168.65.0/24` | Docker Desktop no Windows (WSL2) |

### Headers de segurança

O nginx envia os seguintes headers em todas as respostas:

| Header | Valor |
|---|---|
| `X-Frame-Options` | `SAMEORIGIN` |
| `X-Content-Type-Options` | `nosniff` |
| `Referrer-Policy` | `no-referrer` |
| `Content-Security-Policy` | `default-src 'self'; frame-src *; script-src 'self' 'unsafe-inline'` |
| `Cache-Control` | `no-store, no-cache, must-revalidate` |
