# sets up base image and set environment variable
FROM node:22-alpine3.19 as base
# ARG NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY
# ENV ARG NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY $NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY
# ARG STRIPE_SECRET_KEY
# ENV STRIPE_SECRET_KEY $STRIPE_SECRET_KEY
# ARG NEXT_PUBLIC_URL
# ENV NEXT_PUBLIC_URL $NEXT_PUBLIC_URL
# ARG STRIPE_CURRENCY
# ENV STRIPE_CURRENCY $STRIPE_CURRENCY



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

# installs husky because the  pnpm install require it
# COPY ./.husky ./.husky

RUN corepack enable pnpm \
    && pnpm install --frozen-lockfile
        

# builds the source code
FROM dependencies as builder

WORKDIR /app

# ARG NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY
# ENV ARG NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY $NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY
# ARG STRIPE_SECRET_KEY
# ENV STRIPE_SECRET_KEY $STRIPE_SECRET_KEY
# ARG NEXT_PUBLIC_URL
# ENV NEXT_PUBLIC_URL $NEXT_PUBLIC_URL
# ARG STRIPE_CURRENCY
# ENV STRIPE_CURRENCY $STRIPE_CURRENCY

#   reinstall dependencies  without devDependencies
# RUN apk add --no-cache libc6-compat

# COPY package.json pnpm-lock.yaml* ./

# RUN corepack enable pnpm \
    # && pnpm install --prod --frozen-lockfile

# then copies  the rest of the code, ignoring the ones listed in .dockerignore
COPY . .
#  finally, build the source code into an application, which will store into the .next  folder  in  same location
RUN pnpm run build


# production image
FROM builder AS runner
WORKDIR /app

ENV NODE_ENV production
ENV NEXT_TELEMETRY_DISABLED 1

EXPOSE 3000

ENV PORT 3000

CMD [ "pnpm","start" ]