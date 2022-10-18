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


FROM node:16-alpine AS runner
RUN addgroup --system --gid 1001 nodejs && adduser --system --uid 1001 strapi
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
    # yarn workspaces @njs/api strapi-app --production
EXPOSE 1337
CMD ["yarn", "workspace", "@njs/api", "run", "start"]