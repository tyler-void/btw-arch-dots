# markdown-resume on msi-server

**https://resume.tyler-void.dev**: a self-hosted copy of the Markdown resume editor
(github.com/tyler-void/markdown-resume, a fork of junian/markdown-resume, Nuxt 4).

It is a static site. Resumes are edited and stored in the visitor's browser and never reach
the server, so there is nothing to back up here. The CV itself lives in the private repo
github.com/tyler-void/resume.

| | |
|---|---|
| Stack | `/srv/markdown-resume` on msi-server (these three files) |
| Container | `markdown-resume`: nginx-unprivileged, read-only root, all capabilities dropped, 128 MB cap |
| Network | joins `forgejo_forgejo` (external, created by the Forgejo stack). **No host port** |
| Public route | Cloudflare tunnel `db8f8f61…` (the Forgejo one): `resume.tyler-void.dev → http://markdown-resume:8080` |
| DNS | `resume.tyler-void.dev` CNAME `db8f8f61-e2cf-483c-b944-12fae5e03dc6.cfargotunnel.com`, proxied |

The image clones the fork and runs `nuxt generate` with `NUXT_PUBLIC_SITE_URL` and
`NUXT_APP_BASE_URL=/` baked in. The commit it was built from is in
`/etc/markdown-resume-commit` inside the image.

## Deploy or update

From this repo, on a machine on the tailnet:

```sh
rsync -rlt servers/msi-server/markdown-resume/ msi-server:/srv/markdown-resume/
ssh msi-server 'cd /srv/markdown-resume && docker compose build && docker compose up -d'
```

To pick up new commits from the fork, the clone layer has to be rebuilt:

```sh
gh repo sync tyler-void/markdown-resume        # pull junian's changes into the fork first
ssh msi-server 'cd /srv/markdown-resume && docker compose build --no-cache && docker compose up -d'
```

Check it from the tunnel's side (the container has no port on the host):

```sh
ssh msi-server 'docker run --rm --network forgejo_forgejo busybox:stable wget -qSO /dev/null http://markdown-resume:8080/'
```

## Caching

- `/assets/*` is Nuxt's hashed output, so it is cached forever.
- `sw*.js`, `workbox-*.js` and `manifest.webmanifest` are `no-cache`. The site is a PWA: a cached
  service worker would keep serving the old version.

## Undo

```sh
ssh msi-server 'cd /srv/markdown-resume && docker compose down --rmi local'
```

Then remove the `resume.tyler-void.dev` route from the tunnel and delete the DNS record.
The tunnel config from before this stack existed is in
`~/Documents/System/backups/2026-10-29-resume/tunnel-config-before.json` on gloriousarch.
