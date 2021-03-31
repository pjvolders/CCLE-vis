#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(tidyverse)

con <- DBI::dbConnect(RSQLite::SQLite(), dbname = "CCLE_expression.sqlite")

exp_dat <- tbl(con, "expression")
all_genes <- exp_dat %>% distinct(gene) %>% collect() %>% pull(gene)

sample_info <- read_csv("sample_info.csv", 
                        col_types = cols(
                            depmap_public_comments = col_character()
                        ))

get_expression_table <- function(cell_lines, genes){
    cell_line_name = sample_info %>%
        filter(cell_line_name %in% cell_lines) %>%
        select(DepMap_ID, cell_line_name)
    
    
    exp_dat %>%
        filter(DepMap_ID %in% local(cell_line_name$DepMap_ID) && gene %in% genes) %>%
        collect() %>%
        inner_join(cell_line_name) %>%
        select(cell_line_name, gene, expression) %>%
        spread(gene, expression)
}

# Define UI for application that draws a histogram
ui <- fluidPage(

    # Application title
    titlePanel("CCLE data browser"),

    # Sidebar with a slider input for number of bins 
    sidebarLayout(
        sidebarPanel(
            selectizeInput("cell_line", "Cell line(s)", choices=NULL ,
                           multiple = TRUE),
            selectizeInput("gene", "Gene(s)", choices=NULL,
                           multiple = TRUE),
            selectizeInput("scale_hm", "Scale heatmap by", 
                           choices=c("row", "column", "none"),
                           multiple = FALSE),
            downloadButton("downloadData", "Download csv"),
            helpText("Kindy provided by PJ just because I ",
                     "want to be part of the CRISPRi gang")
        ),

        mainPanel(
            dataTableOutput('table'),
            plotOutput("heatmap")
        )
    )
)

server <- function(input, output, session) {
    updateSelectizeInput(session, 'gene', choices = all_genes, server = TRUE)
    updateSelectizeInput(session, 'cell_line', 
                         choices = sample_info$cell_line_name, server = TRUE)
    
    output$table <- renderDataTable({
        get_expression_table(cell_lines = local(input$cell_line), 
                             genes = local(input$gene))
    })
    
    output$heatmap <- renderPlot({
        exp_dat_df <-
            get_expression_table(cell_lines = local(input$cell_line), 
                                 genes = local(input$gene))
        
        exp_dat_matrix = as.matrix(exp_dat_df[,input$gene])
        row.names(exp_dat_matrix) = exp_dat_df$cell_line_name
        
        heatmap(t(exp_dat_matrix), scale = input$scale_hm)
    })
    
    output$downloadData <- downloadHandler(
        filename = function() {
            paste("data-", Sys.Date(), ".csv", sep="")
        },
        content = function(file) {
            get_expression_table(cell_lines = local(input$cell_line), 
                                 genes = local(input$gene)) %>%
                write_csv(file)
        }
    )
    
}

# Run the application 
shinyApp(ui = ui, server = server)
