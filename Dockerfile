# sets up base image and set environment variable
FROM node:22-alpine3.19 as base


# Installs dependencies
FROM base as dependencies
WORKDIR /app

ARG NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY
ENV ARG NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY $NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY
ARG STRIPE_SECRET_KEY
ENV STRIPE_SECRET_KEY $STRIPE_SECRET_KEY
ARG NEXT_PUBLIC_URL
ENV NEXT_PUBLIC_URL $NEXT_PUBLIC_URL
ARG STRIPE_CURRENCY
ENV STRIPE_CURRENCY $STRIPE_CURRENCY


COPY package.json pnpm-lock.yaml* ./

RUN apk add --no-cache libc6-compat && \
    corepack enable pnpm \
    && pnpm install --frozen-lockfile
        

# builds the source code
FROM dependencies as builder

WORKDIR /app

ARG NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY
ENV ARG NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY $NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY
ARG STRIPE_SECRET_KEY
ENV STRIPE_SECRET_KEY $STRIPE_SECRET_KEY
ARG NEXT_PUBLIC_URL
ENV NEXT_PUBLIC_URL $NEXT_PUBLIC_URL
ARG STRIPE_CURRENCY
ENV STRIPE_CURRENCY $STRIPE_CURRENCY

# copies  the rest of the code, ignoring the ones listed in .dockerignore
COPY . .

# build app, then removing things that won't need to be in final build
RUN pnpm run build && \
    rm -rf src/ \
           yns.inlang/ \
           vitest.config.ts \
           tsconfig.json \
           tailwind.config.ts \
           commitlint.config.ts \
           prettier.config.js \
           postcss.config.cjs \
           next-fix.d.ts \
           next-env.d.ts \
           i18n.d.ts \
           .husky \
           .lintstagedrc.js \
           components.json \
           global.d.ts \
           mdx-components.tsx \
           .eslintrc.json \
           .npmrc \
           .prettierignore && \
    pnpm prune --prod



FROM base AS runner
WORKDIR /app

COPY package.json pnpm-lock.yaml* ./

RUN apk add --no-cache libc6-compat && \
    corepack enable pnpm

ENV NODE_ENV production
ENV NEXT_TELEMETRY_DISABLED 1

ARG NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY
ENV ARG NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY $NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY
ARG STRIPE_SECRET_KEY
ENV STRIPE_SECRET_KEY $STRIPE_SECRET_KEY
ARG NEXT_PUBLIC_URL
ENV NEXT_PUBLIC_URL $NEXT_PUBLIC_URL
ARG STRIPE_CURRENCY
ENV STRIPE_CURRENCY $STRIPE_CURRENCY

COPY --from=builder /app/ .

EXPOSE 3000

ENV PORT 3000

CMD [ "pnpm","start" ]