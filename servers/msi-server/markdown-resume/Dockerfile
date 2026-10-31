# markdown-resume: build github.com/tyler-void/markdown-resume (Nuxt 4, `nuxt generate`)
# and serve the result as static files. The site URL and base path are baked in at build time.
FROM node:24-alpine AS build
RUN apk add --no-cache git
ENV COREPACK_ENABLE_DOWNLOAD_PROMPT=0 NUXT_TELEMETRY_DISABLED=1 CI=1
RUN corepack enable

ARG REPO=https://github.com/tyler-void/markdown-resume.git
ARG REF=master
ARG SITE_URL=https://resume.tyler-void.dev
WORKDIR /src
RUN git clone --depth 1 --branch "$REF" "$REPO" . && git rev-parse --short HEAD > /built-from

# pnpm comes from package.json's packageManager field, via corepack.
ENV NUXT_PUBLIC_SITE_URL=$SITE_URL NUXT_APP_BASE_URL=/
RUN pnpm install --frozen-lockfile && pnpm run release

FROM nginxinc/nginx-unprivileged:stable-alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /src/.output/public /usr/share/nginx/html
COPY --from=build /built-from /etc/markdown-resume-commit
