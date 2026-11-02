FROM node:22-alpine
WORKDIR /usr/src/app
ENV NODE_ENV=production
COPY --chown=node:node package.json server.js ./
USER node
EXPOSE 8005
CMD ["node", "server.js"]
