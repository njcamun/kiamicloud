# KiamiCloud

> **Minha Cloud. Meu mundo. Sem limites.**

Plataforma cloud africana moderna — alternativa leve e acessível a soluções como Google Drive, Dropbox e OneDrive.

[**🌐 Aceder à Web App**](https://kiamicloud.web.app) | [**📁 Repositório GitHub**](https://github.com/njcamun/kiamicloud)

## Arquitetura (MVP)

```
Flutter (Android, Web, Windows)
        ↓
Firebase Authentication (apenas identidade)
        ↓
Cloudflare Workers (API, regras, segurança)
        ↓
Cloudflare D1 (metadados)
        ↓
Cloudflare R2 (ficheiros privados)
```

## Estrutura do repositório

| Pasta | Responsabilidade |
|-------|------------------|
| `apps/` | Clientes Flutter (mobile, web, desktop) |
| `workers/` | API Cloudflare Workers |
| `database/` | Migrações e esquema D1 |
| `storage/` | Convenções R2 e documentação de storage |
| `branding/` | Identidade visual e design tokens |
| `docs/` | Documentação técnica e de produto |
| `progress/` | Memória contínua do projeto |
| `scripts/` | Automação e utilitários |

## MVP — Configurações oficiais

- Firebase plano gratuito
- Upload máximo: **50 MB** por ficheiro
- Todos os tipos de ficheiro (inicial)
- Upload/download manuais
- Mobile first, idioma **português**
- Armazenamento privado por utilizador
- Sem partilha pública no MVP

## Planos

| Plano | Armazenamento | Transferência/ficheiro | Preço (Kz/mês) |
|-------|---------------|------------------------|----------------|
| Básico | 20 GB | 15 MB | Gratuito |
| Básico+ | 20 GB | 75 MB | 1.500 |
| Plus | 40 GB | 150 MB | 2.550 (tabela 3.000) |
| Start | 80 GB | 150 MB | 5.100 (tabela 6.000) |
| Premium | 160 GB | 150 MB | 10.200 (tabela 12.000) |
| Pro | 320 GB | 150 MB | 20.400 (tabela 24.000) |
| Ultra | 500 GB | 150 MB | 40.800 (tabela 48.000) |

## Desenvolvimento por fases

Consulte `progress/progresso_kiamicloud.txt` para o estado atual e `docs/ROADMAP.md` para o roadmap completo.

## Segurança

- Nunca commitar credenciais
- Bucket R2 sempre privado
- URLs temporárias para download
- Toda interação com R2 via Workers

## Licença

Proprietário — KiamiCloud © 2026
