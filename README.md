# CCLE-vis

## Visualise the CCLE data from DepMap

Before running the first time, first download the data and built the database:

```bash
R --vanilla < create_db.R
```

Then start the server

```bash
R -e "shiny::runApp('./')"
```

## Requirements

The following R packages are required:

```
tidyverse
RSQLite
```

