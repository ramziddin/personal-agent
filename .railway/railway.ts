import {
  defineRailway,
  github,
  preserve,
  project,
  service,
  volume,
} from "railway/iac";

export default defineRailway(() => {
  const agent = service("personal-agent", {
    source: github("ramziddin/personal-agent", { branch: "main" }),
    env: {
      GLM_API_KEY: preserve(),
      TELEGRAM_BOT_TOKEN: preserve(),
      TELEGRAM_ALLOWED_USERS: preserve(),
      TELEGRAM_HOME_CHANNEL: preserve(),
      TELEGRAM_HOME_CHANNEL_NAME: "Personal DM",
      HERMES_HUMAN_DELAY_MODE: "natural",
    },
    replicas: {
      "europe-west4": 1,
    },
    volumeMounts: {
      "/opt/data": volume("hermes-data"),
    },
  });

  return project("personal-agent", {
    resources: [agent],
  });
});
