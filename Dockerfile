# FROM  alpine:3.19 as base
# Some sections copied from https://github.com/vercel/next.js/blob/canary/examples/with-docker/Dockerfile
ARG STRIPE_SECRET_KEY
ARG NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY
ARG STRIPE_CURRENCY
ARG NEXT_PUBLIC_URL



FROM node:22-alpine3.19 as base

RUN apk update && apk upgrade



FROM base AS dependencies
WORKDIR /app

# Installs  latest node, pnpm
# RUN apk add --update npm nodejs

# Install dependencies based on the preferred package manager
COPY package.json yarn.lock* package-lock.json* pnpm-lock.yaml* ./
RUN \
  if [ -f yarn.lock ]; then yarn --frozen-lockfile; \
  elif [ -f package-lock.json ]; then npm ci; \
  elif [ -f pnpm-lock.yaml ]; then corepack enable pnpm && pnpm i --frozen-lockfile; \
  else echo "Lockfile not found." && exit 1; \
  fi



# TODO: Review what's  being  copied
FROM base AS builder
WORKDIR /app

COPY --from=dependencies /app/node_modules ./node_modules
COPY . .

RUN pwd

RUN ls -al

ARG STRIPE_SECRET_KEY
ENV STRIPE_SECRET_KEY $STRIPE_SECRET_KEY

ARG NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY
ENV NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY $NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY

ARG STRIPE_CURRENCY
ENV STRIPE_CURRENCY $STRIPE_CURRENCY

ARG NEXT_PUBLIC_URL
ENV NEXT_PUBLIC_URL $NEXT_PUBLIC_URL

RUN corepack enable pnpm && pnpm run build

# RUN npm install -g pnpm

# RUN pnpm install --prod true \
# pnpm build


# Production image
FROM base AS runner
WORKDIR /app

ARG STRIPE_SECRET_KEY
ENV STRIPE_SECRET_KEY $STRIPE_SECRET_KEY

ARG NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY
ENV NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY $NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY

ARG STRIPE_CURRENCY
ENV STRIPE_CURRENCY $STRIPE_CURRENCY

ARG NEXT_PUBLIC_URL
ENV NEXT_PUBLIC_URL $NEXT_PUBLIC_URL

ENV NODE_ENV production
ENV NEXT_TELEMETRY_DISABLED 1

RUN corepack enable pnpm

# Run container with non-root credentials
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs


# Set the correct permission for prerender cache
RUN mkdir .next

COPY --from=builder /app/.next ./.next

RUN chown nextjs:nodejs .next


# TODO might have to change to COPY . . since it needs NextJS to run
COPY --from=dependencies /app/node_modules ./node_modules
COPY --from=builder /app/public ./public
COPY --from=builder /app/package.json ./
# COPY --from=builder /usr/local/bin/pnpm /usr/local/bin/pnpm


# Automatically leverage output traces to reduce image size
# https://nextjs.org/docs/advanced-features/output-file-tracing
# COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
# COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs

EXPOSE 3000

ENV PORT=3000

CMD [ "pnpm", "start" ]
