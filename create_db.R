library(dplyr)
library(tidyverse)

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
