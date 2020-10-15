#!/usr/bin/env Rscript

# Load packages
# Couldn't get renv to work right
#require("renv", lib="~/R/libs/4.0")
# Gah, just manually install these packages
require('RSQLite')
require('jsonlite')
require('tidyverse')
require('janitor')

args <- commandArgs(trailingOnly = TRUE)

dbname <- args[1]
output <- args[2]

# 'Connect' to database
con <- dbConnect(
  drv=RSQLite::SQLite(),
  dbname=dbname
)

# Extract main table
d <- dbGetQuery(
  conn=con,
  statement='SELECT * FROM labjs'
)

# Close connection
dbDisconnect(
  conn=con
)

# Discard connection
rm(con)

###Extract metadata

d.meta <- map_dfr(d$metadata, fromJSON) %>%
  dplyr::rename(
    observation=id
  )

d <- d %>%
  bind_cols(d.meta) %>%
  select(
    -metadata # Remove metadata column
  )

# Remove temporary data frame
rm(d.meta)

###Shorten the random ids

count_unique <- function(x) {
  return(length(unique(x)))
}

information_preserved <- function(x, length) {
  return(
    count_unique(str_sub(x, end=i)) ==
    count_unique(x)
  )
}

# Figure out the length of the random ids needed
# to preserve the information therein. (five characters
# should usually be enougth, but better safe)
for (i in 5:36) {
  if (
    information_preserved(d$session, i) &&
    information_preserved(d$observation, i)
  ) {
    break()
  }
}

d <- d %>%
  dplyr::mutate(
    session=str_sub(session, end=i),
    observation=str_sub(observation, end=i)
  )

rm(i, count_unique, information_preserved)


###Prepare to extract JSON data

parseJSON <- function(input) {
  return(input %>%
    fromJSON(flatten=T) %>% {
    # Coerce lists
    if (class(.) == 'list') {
      discard(., is.null) %>%
      as_tibble()
    } else {
      .
    } } %>%
    # Sanitize names
    janitor::clean_names() %>%
    # Use only strings for now, and re-encode types later
    mutate_all(as.character)
  )
}


###Extract complete data sets

d.full <- d %>%
  dplyr::filter(payload == 'full')

if (nrow(d.full) > 0) {
  d.full %>%
    group_by(observation, id) %>%
    do(
      { map_dfr(.$data, parseJSON) } %>%
      bind_rows()
    ) %>%
    ungroup() %>%
    select(-id) -> d.full
} else {
  # If there are no full datasets, start from an entirely empty df
  # in order to avoid introducing unwanted columns into the following
  # merge steps.
  d.full <- tibble()
  d.full$observation = c()
}


d %>%
  dplyr::filter(payload %in% c('incremental', 'latest')) %>%
  group_by(observation, id) %>%
  do(
    { map_dfr(.$data, parseJSON) } %>%
    bind_rows()
  ) %>%
  ungroup() %>%
  select(-id) -> d.incremental


###Merge data sets

# For analysis, we'll use the full data sets where available, and incremental data when it is the the only information we have for a user.

d.output <- d.full %>%
  bind_rows(
    d.incremental %>% filter(!(observation %in% d.full$observation))
  ) %>%
  type_convert()

###Postprocessing

# It would be nice if some columns were completed so that all cells contain the same value, even if only a subset is filled

d.output %>%
  group_by(observation) %>%
  fill(matches('code'), .direction='down') %>%
  fill(matches('code'), .direction='up') %>%
  ungroup() -> d.output

# Remove sensitive data?

# d.output <- d.output %>%
 #  select(
  #   -matches('Email')
  # )

# Remove invalid columns

# d.output %>%
#   select_if(function(col) class(col) != 'list') -> d.output


###Export data

write_tsv(d.output, output)
