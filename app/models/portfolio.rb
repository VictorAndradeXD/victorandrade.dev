# Metadados do portfólio que NÃO passam por tradução: links, URLs e nomes de
# tecnologia. Todo o texto corrido vive em config/locales/portfolio.*.yml e é
# lido por I18n, com estas chaves servindo de ponte entre os dois.
#
# Fica num PORO, e não no banco, porque é conteúdo de uma pessoa só que muda
# junto com o currículo — versionar no git vale mais do que um CRUD que ninguém
# vai usar.
module Portfolio
  # Idiomas do site público. A ordem é a ordem dos botões no cabeçalho.
  LOCALES = %w[pt-BR en].freeze

  LINKS = {
    email:    "victordev2000@gmail.com",
    github:   "https://github.com/VictorAndradeXD",
    linkedin: "https://www.linkedin.com/in/victor-andrade22"
  }.freeze

  # Currículo em PDF: o botão só aparece se o arquivo existir em public/, para
  # não deixar um link quebrado no ar enquanto ele não é colocado lá.
  RESUME_PATH = "/joao-victor-andrade.pdf".freeze

  # Três projetos com profundidade, em vez de seis rasos: é o que as
  # referências de portfólio bem-sucedido têm em comum. O `id` casa com a
  # chave em portfolio.projects.<id> nos locales.
  PROJECTS = [
    {
      id:    :konverta,
      stack: ["TypeScript", "NestJS", "Prisma", "Postgres", "Redis", "BullMQ", "React", "Auth0", "Docker", "OpenAI"],
      live:  { label: "konvertaoficial.com", url: "https://konvertaoficial.com" },
      code:  nil
    },
    {
      id:    :feirinha,
      stack: ["Java 21", "Spring Boot 4", "PostgreSQL", "Flyway", "JWT", "Asaas", "Docker", "Angular 21"],
      live:  { label: "feirinhaverdethe.com.br", url: "https://feirinhaverdethe.com.br" },
      code:  nil
    },
    {
      id:    :denfis,
      stack: ["Ruby on Rails 8", "Hotwire", "PostgreSQL", "Tailwind", "Argon2id", "Docker"],
      live:  nil,
      code:  { label: "github.com/VictorAndradeXD/victorandrade.dev",
               url: "https://github.com/VictorAndradeXD/victorandrade.dev" }
    }
  ].freeze

  # Nomes de tecnologia não se traduzem; só o rótulo do grupo, que vem de
  # portfolio.stack.groups.<chave>.
  STACK = {
    backend:  ["Java", "Spring Boot", "Ruby on Rails", "Node.js / NestJS", "Python", "REST APIs"],
    frontend: ["TypeScript", "React", "Angular", "Next.js", "Vue.js", "Hotwire", "Tailwind"],
    data:     ["PostgreSQL", "MySQL", "Redis", "Prisma", "Flyway", "BullMQ"],
    cloud:    ["AWS (EC2, RDS, IAM, VPC, S3)", "Docker", "GitHub Actions", "Linux", "CI/CD", "Grafana", "Prometheus"],
    ai:       ["LLM integration", "Prompt engineering", "OpenAI API", "Model evaluation", "Claude Code"],
    testing:  ["JUnit 5", "Testcontainers", "RSpec", "Minitest", "REST Assured", "Playwright", "Gatling"]
  }.freeze
end
