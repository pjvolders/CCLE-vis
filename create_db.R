library(dplyr)
library(tidyverse)

if(!file.exists("CCLE_expression.csv")){
  download.file("https://ndownloader.figshare.com/files/26261476", 
                "CCLE_expression.csv")
}

if(!file.exists("sample_info.csv")){
  download.file("https://ndownloader.figshare.com/files/26261569", 
                "sample_info.csv")
}

exp_dat <- read_csv("CCLE_expression.csv")

exp_dat.clean = exp_dat %>%
  rename(DepMap_ID = X1) %>%
  gather("gene", "expression", -DepMap_ID)

con <- DBI::dbConnect(RSQLite::SQLite(), dbname = "CCLE_expression.sqlite")


copy_to(con, exp_dat.clean, "expression",
        temporary = FALSE, 
        indexes = list(
          c("DepMap_ID", "gene"),
          "gene"
        ),
        overwrite = TRUE
)
