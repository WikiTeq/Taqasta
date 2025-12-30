FROM node:22.13

WORKDIR "/e2e"

COPY package.json /e2e/
COPY package-lock.json /e2e/

RUN npm ci
RUN npx playwright install chromium --with-deps

ENV TAQASTA_E2E_IN_DOCKER=true

# The command gets run via `docker compose exec e2e npx playwright test` since
# we want to wait for the wiki to finish starting up. The command here just
# keeps the container running forever until it is manually taken down.
CMD tail -f /dev/null
