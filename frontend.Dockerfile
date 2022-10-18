FROM node:16-alpine AS deps
RUN apk add --no-cache rsync
WORKDIR /workspace-install
COPY yarn.lock .yarnrc.yml ./
COPY .yarn/ ./.yarn/
RUN --mount=type=bind,target=/docker-context \
    rsync -amv --delete \
          --exclude='node_modules' \
          --exclude='*/node_modules' \
          --include='package.json' \
          --include='schema.prisma' \
          --include='*/' --exclude='*' \
          /docker-context/ /workspace-install/;
# @see https://www.prisma.io/docs/reference/api-reference/environment-variables-reference#cli-binary-targets
ENV PRISMA_CLI_BINARY_TARGETS=linux-musl
RUN --mount=type=cache,target=/root/.yarn3-cache,id=yarn3-cache \
    YARN_CACHE_FOLDER=/root/.yarn3-cache \
    yarn install --immutable --inline-builds


FROM node:16-alpine AS builder
ENV NODE_ENV=production
ENV NEXTJS_IGNORE_ESLINT=1
ENV NEXTJS_IGNORE_TYPECHECK=0
WORKDIR /app
COPY . .
COPY --from=deps /workspace-install ./
RUN yarn build
RUN --mount=type=cache,target=/root/.yarn3-cache,id=yarn3-cache \
    SKIP_POSTINSTALL=1 \
    YARN_CACHE_FOLDER=/root/.yarn3-cache
    # yarn workspaces @njs/frontend nextjs-app --production

FROM node:16-alpine AS runner
RUN addgroup --system --gid 1001 nodejs && adduser --system --uid 1001 nextjs
COPY --from=builder /app/packages/frontend/next.config.js \
                    # /app/packages/frontend/next-i18next.config.js \
                    /app/packages/frontend/package.json \
                    ./packages/frontend/
COPY --from=builder /app/packages/frontend/public ./packages/frontend/public
COPY --from=builder --chown=nextjs:nodejs /app/packages/frontend/.next ./packages/frontend/.next
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json
EXPOSE 3000
ENV NEXT_TELEMETRY_DISABLED 1
CMD ["./node_modules/.bin/next", "start", "packages/frontend/", "-p", "3000"]
