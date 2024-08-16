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

RUN apk add --no-cache libc6-compat

COPY package.json pnpm-lock.yaml* ./

RUN corepack enable pnpm \
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
#  finally, build the source code into an application, which will store into the .next  folder  in  same location
RUN pnpm run build

# removing things that won't need to be in final build
RUN rm -rf src/ \
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
           .prettierignore

# production image - working, but size too big?
FROM builder AS runner
WORKDIR /app

ENV NODE_ENV production
ENV NEXT_TELEMETRY_DISABLED 1

# Switch to non-root user
RUN adduser -D yournextstore

RUN chown -R yournextstore ./.next

USER yournextstore

EXPOSE 3000

ENV PORT 3000

CMD [ "pnpm","start" ]