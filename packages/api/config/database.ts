export default ({ env }) => ({
  connection: {
    client: "mysql",
    connection: {
      host: env("DB_HOST", "0.0.0.0"),
      port: env.int("MYSQLDB_DOCKER_PORT", 3306),
      user: env("DB_USER", "strapi"),
      password: env("DB_PASSWORD", "strapi"),
      database: env("DB_DATABASE", "strapi"),
      charset: env("DB_CHARSET", "utf8mb4"),
    },
    useNullAsDefault: true,
  },
});
