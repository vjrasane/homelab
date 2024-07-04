FROM node:20-bookworm as base

RUN npx -y playwright@1.44.1 install --with-deps

WORKDIR /var/app
 
FROM base as build

COPY package.json package-lock.json ./

RUN npm install

COPY tsconfig.json index.ts ./

RUN npx tsc

FROM base 

ARG PUID

COPY package.json package-lock.json ./

RUN npm install --omit=dev

COPY --from=build /var/app/index.js ./

ENV HEADLESS true

USER ${PUID}

CMD ["node", "."]


