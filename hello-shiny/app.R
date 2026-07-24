library(shiny)

ui <- fluidPage(
  titlePanel("Hello from rpackit"),
  sidebarLayout(
    sidebarPanel(
      sliderInput("bins", "Histogram bins", min = 5, max = 50, value = 20)
    ),
    mainPanel(plotOutput("histogram"))
  )
)

server <- function(input, output, session) {
  output$histogram <- renderPlot({
    hist(
      faithful$eruptions,
      breaks = input$bins,
      col = "#2563eb",
      border = "white",
      main = "Old Faithful eruption duration",
      xlab = "Minutes"
    )
  })
}

shinyApp(ui, server)
